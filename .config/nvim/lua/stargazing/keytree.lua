-- Compile Neovim's shipped action index into a trie, then merge the mappings
-- resolved by the running instance. This mirrors Helix's Pending(KeyTrieNode)
-- model without parsing or imposing a structure on the user's Lua config.
local M = {}

local state = {
    builtin = {},
    groups = {},
    roots = {},
    path = {},
    mode = nil,
    generation = 0,
    win = nil,
    buf = nil,
    refresh_pending = false,
    intercepts = {},
    setup = false,
}

local mode_queries = {
    n = { "n" },
    v = { "v", "x", "s" },
    o = { "o" },
    i = { "i" },
    c = { "c" },
    t = { "t" },
}

local excluded_prefixes = {
    n = { ["<Esc>"] = true, ["/"] = true, ["?"] = true, ["'"] = true, ["`"] = true },
    v = { ["<Esc>"] = true, ["/"] = true, ["?"] = true, ["'"] = true, ["`"] = true },
    o = { ["<Esc>"] = true, ["'"] = true, ["`"] = true },
    i = { ["<Esc>"] = true },
    c = { ["<Esc>"] = true },
    t = { ["<Esc>"] = true },
}

local function node()
    return { children = {}, action = nil, label = nil }
end

local function trim(value)
    return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function canonical_mode(mode)
    mode = mode or vim.api.nvim_get_mode().mode
    local first = mode:sub(1, 1)
    if first == "v" or first == "V" or first == "\22" or first == "s" or first == "S" or first == "\19" then
        return "v"
    end
    if first == "R" then return "i" end
    if first == "n" then return "n" end
    if first == "o" then return "o" end
    if first == "i" then return "i" end
    if first == "c" then return "c" end
    if first == "t" then return "t" end
    return "n"
end

local function display_key(key)
    local names = {
        ["<Space>"] = "space",
        ["<Tab>"] = "tab",
        ["<S-Tab>"] = "S-tab",
        ["<CR>"] = "ret",
        ["<NL>"] = "ret",
        ["<Esc>"] = "esc",
        ["<BS>"] = "backspace",
        ["<Del>"] = "del",
        ["<Up>"] = "up",
        ["<Down>"] = "down",
        ["<Left>"] = "left",
        ["<Right>"] = "right",
    }
    if names[key] then return names[key] end
    local control = key:match("^<C%-(.+)>$")
    if control then return "C-" .. control:lower() end
    local shifted = key:match("^<S%-(.+)>$")
    if shifted then return "S-" .. shifted:lower() end
    local alt = key:match("^<A%-(.+)>$") or key:match("^<M%-(.+)>$")
    if alt then return "A-" .. alt end
    return key
end

local function display_path(tokens)
    local parts = {}
    for _, token in ipairs(tokens) do parts[#parts + 1] = display_key(token) end
    return table.concat(parts, " ")
end

local function token_to_lhs(token)
    return token
end

local function path_to_lhs(tokens)
    local parts = {}
    for _, token in ipairs(tokens) do parts[#parts + 1] = token_to_lhs(token) end
    return table.concat(parts)
end

local function scan_notation(value)
    local tokens = {}
    local index = 1
    while index <= #value do
        local byte = value:byte(index)
        if byte == 32 then
            index = index + 1
        elseif value:sub(index, index) == "<" then
            local close = value:find(">", index, true)
            if not close then
                tokens[#tokens + 1] = "<"
                index = index + 1
            else
                tokens[#tokens + 1] = value:sub(index, close)
                index = close + 1
            end
        else
            local remaining = value:sub(index)
            local control = remaining:match("^CTRL%-(%S+)")
            if control then
                if control:sub(1, 1) == "<" and control:sub(-1) == ">" then
                    control = control:sub(2, -2)
                end
                tokens[#tokens + 1] = "<C-" .. control .. ">"
                index = index + #remaining:match("^CTRL%-%S+")
            else
                local character = vim.fn.strcharpart(value:sub(index), 0, 1)
                tokens[#tokens + 1] = character
                index = index + #character
            end
        end
    end
    return tokens
end

local function typed_tokens(value)
    if value == "" then return {} end
    return scan_notation(vim.fn.keytrans(value))
end

local function documented_tokens(value)
    value = trim(value)
    while value:sub(1, 4) == '["x]' do value = trim(value:sub(5)) end
    value = value:gsub("^{count}", "")
    if value:match("^N[^%a]") then value = value:sub(2) end
    if value:find(" to ", 1, true) or value:find(" - ", 1, true) then return {}, true end
    local placeholder = value:find("{", 1, true)
    local incomplete = placeholder ~= nil
    if placeholder then value = value:sub(1, placeholder - 1) end
    value = trim(value)
    if value == "" then return {}, incomplete end
    return scan_notation(value), incomplete
end

local function insert(root, tokens, action, label)
    if #tokens == 0 then return nil end
    local current = root
    for _, token in ipairs(tokens) do
        if not current.children[token] then current.children[token] = node() end
        current = current.children[token]
    end
    if action then current.action = action end
    if label and label ~= "" and not current.label then current.label = label end
    return current
end

local function merge_nodes(base, delta)
    if delta.action then base.action = delta.action end
    if delta.label then base.label = delta.label end
    for key, child in pairs(delta.children) do
        if base.children[key] then
            merge_nodes(base.children[key], child)
        else
            base.children[key] = vim.deepcopy(child)
        end
    end
end

local function split_tab_fields(line)
    local fields = {}
    for field in (line .. "\t"):gmatch("(.-)\t") do
        local trimmed_field = trim(field)
        if trimmed_field ~= "" then fields[#fields + 1] = trimmed_field end
    end
    return fields
end

local function load_builtin_catalog()
    local roots = { n = node(), v = node(), o = node(), i = node(), c = node(), t = node(), objects = node() }
    local path = vim.env.VIMRUNTIME .. "/doc/index.txt"
    local file = io.open(path, "r")
    if not file then return roots end

    local mode
    for line in file:lines() do
        if line:find("%*insert%-index%*") then mode = "i"
        elseif line:find("%*normal%-index%*") then mode = "n"
        elseif line:find("%*objects%*") then mode = "objects"
        elseif line:match("^2%.[2345]") then mode = "n"
        elseif line:find("%*operator%-pending%-index%*") then mode = "o"
        elseif line:find("%*visual%-index%*") then mode = "v"
        elseif line:find("%*ex%-edit%-index%*") then mode = "c"
        elseif line:find("%*terminal%-mode%-index%*") then mode = "t"
        elseif line:find("%*ex%-cmd%-index%*") then mode = nil
        end

        if mode and line:sub(1, 1) == "|" then
            local fields = split_tab_fields(line)
            local tag = fields[1] and fields[1]:match("^|(.-)|$")
            local notation = fields[2]
            local description = fields[3]
            if tag and notation then
                description = description and description:gsub("^[12][,%d]*%s+", "") or nil
                local tokens, incomplete = documented_tokens(notation)
                if #tokens > 0 then
                    local action
                    if not incomplete and description and not description:match("^not used") then
                        action = {
                            id = "builtin:" .. mode .. ":" .. tag,
                            desc = description,
                            lhs = path_to_lhs(tokens),
                            source = "builtin",
                            executable = true,
                        }
                    end
                    insert(roots[mode], tokens, action, description)
                end
            end
        end
    end
    file:close()

    -- Neovim documents Visual mode as a delta: most Normal-mode commands are
    -- inherited and only the commands with different behavior are listed.
    local visual_delta = roots.v
    roots.v = vim.deepcopy(roots.n)
    merge_nodes(roots.v, roots.objects)
    merge_nodes(roots.v, visual_delta)
    merge_nodes(roots.o, roots.objects)
    roots.objects = nil

    local labels = {
        n = {
            ["g"] = "Goto",
            ["z"] = "View",
            ["Z"] = "Quit",
            ["["] = "Previous",
            ["]"] = "Next",
            ["<C-W>"] = "Window",
        },
        i = { ["<C-X>"] = "Completion", ["<C-G>"] = "Insert" },
    }
    for catalog_mode, mode_labels in pairs(labels) do
        for lhs, label in pairs(mode_labels) do
            local target = insert(roots[catalog_mode], scan_notation(lhs), nil, label)
            if target then target.label = label end
        end
    end
    return roots
end

local function mapping_description(mapping)
    if mapping.desc and mapping.desc ~= "" then return mapping.desc end
    if mapping.rhs and mapping.rhs ~= "" then
        local rhs = mapping.rhs
            :gsub("^<Cmd>", "")
            :gsub("^:", "")
            :gsub("<CR>$", "")
        if #rhs > 60 then rhs = rhs:sub(1, 57) .. "..." end
        return rhs
    end
    if mapping.callback then return "Lua callback" end
    return "Mapping"
end

local function mapping_id(mode, mapping)
    return table.concat({
        "mapping",
        mode,
        mapping_description(mapping),
        mapping.rhs or "",
        tostring(mapping.callback or ""),
    }, ":")
end

local function add_mapping(root, mode, mapping, tokens)
    if not mapping.lhs or mapping.lhs == "" then return end
    tokens = tokens or typed_tokens(vim.keycode(mapping.lhs))
    if #tokens == 0 then return end
    local target = insert(root, tokens)
    -- A real mapping replaces the native action at this exact prefix. Longer
    -- real mappings are added afterwards, in path-length order.
    target.children = {}
    target.action = {
        id = mapping_id(mode, mapping),
        desc = mapping_description(mapping),
        lhs = mapping.lhs,
        source = mapping.buffer == 1 and "buffer" or "mapping",
        executable = true,
        mapping = mapping,
    }
end

local function add_mappings(root, mode, mappings)
    local prepared = {}
    for _, mapping in ipairs(mappings) do
        if mapping.lhs
            and mapping.lhs ~= ""
            and not mapping.lhs:find("<Plug>", 1, true)
            and not mapping.lhs:find("<SNR>", 1, true)
            and mapping.desc ~= "[keytree prefix]" then
            local tokens = typed_tokens(vim.keycode(mapping.lhs))
            if #tokens > 0 then prepared[#prepared + 1] = { mapping = mapping, tokens = tokens } end
        end
    end
    table.sort(prepared, function(a, b) return #a.tokens < #b.tokens end)
    for _, item in ipairs(prepared) do add_mapping(root, mode, item.mapping, item.tokens) end
end

local function apply_groups(mode, root)
    for lhs, label in pairs(state.groups[mode] or {}) do
        local target = insert(root, typed_tokens(vim.keycode(lhs)), nil, label)
        if target then target.label = label end
    end
end

local function rebuild(mode)
    mode = canonical_mode(mode)
    local root = vim.deepcopy(state.builtin[mode] or node())
    local seen = {}
    local global_mappings = {}
    local buffer_mappings = {}
    for _, query_mode in ipairs(mode_queries[mode] or { mode }) do
        if not seen[query_mode] then
            seen[query_mode] = true
            for _, mapping in ipairs(vim.api.nvim_get_keymap(query_mode)) do
                global_mappings[#global_mappings + 1] = mapping
            end
            if vim.api.nvim_buf_is_valid(0) then
                for _, mapping in ipairs(vim.api.nvim_buf_get_keymap(0, query_mode)) do
                    mapping.buffer = 1
                    buffer_mappings[#buffer_mappings + 1] = mapping
                end
            end
        end
    end
    add_mappings(root, mode, global_mappings)
    add_mappings(root, mode, buffer_mappings)
    apply_groups(mode, root)
    state.roots[mode] = root
    return root
end

local function current_root(mode, force)
    mode = canonical_mode(mode)
    if force or not state.roots[mode] then
        return rebuild(mode)
    end
    return state.roots[mode]
end

local function close_window()
    if state.win and vim.api.nvim_win_is_valid(state.win) then
        vim.api.nvim_win_close(state.win, true)
    end
    state.win = nil
    state.buf = nil
end

local function child_description(child)
    if child.action then return child.action.desc end
    if child.label and child.label ~= "" then return child.label end
    if next(child.children) then return "More commands" end
    return "Command"
end

local function node_rows(current)
    local grouped = {}
    for key, child in pairs(current.children) do
        local description = child_description(child)
        grouped[description] = grouped[description] or {}
        grouped[description][#grouped[description] + 1] = display_key(key)
    end
    local rows = {}
    for description, keys in pairs(grouped) do
        table.sort(keys)
        rows[#rows + 1] = { keys = table.concat(keys, ", "), description = description }
    end
    table.sort(rows, function(a, b) return a.keys:lower() < b.keys:lower() end)
    return rows
end

local function render(current, path, generation)
    if generation ~= state.generation then return end
    local rows = node_rows(current)
    if #rows == 0 then
        close_window()
        return
    end

    local max_rows = math.max(1, vim.o.lines - 4)
    local clipped = #rows > max_rows
    while #rows > max_rows do table.remove(rows) end
    if clipped then rows[#rows] = { keys = "…", description = "More commands" } end

    local key_width = 0
    for _, row in ipairs(rows) do key_width = math.max(key_width, vim.fn.strdisplaywidth(row.keys)) end
    local lines = {}
    local content_width = 0
    for _, row in ipairs(rows) do
        local line = string.format(" %s%s  %s ", row.keys, string.rep(" ", key_width - vim.fn.strdisplaywidth(row.keys)), row.description)
        lines[#lines + 1] = line
        content_width = math.max(content_width, vim.fn.strdisplaywidth(line))
    end

    local width = math.min(content_width, math.max(20, vim.o.columns - 4))
    for index, line in ipairs(lines) do
        if vim.fn.strdisplaywidth(line) > width then
            lines[index] = vim.fn.strcharpart(line, 0, math.max(1, width - 1)) .. "…"
        end
    end

    if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
        state.buf = vim.api.nvim_create_buf(false, true)
        vim.bo[state.buf].bufhidden = "wipe"
        vim.bo[state.buf].filetype = "stargazing-keytree"
    end
    vim.bo[state.buf].modifiable = true
    vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
    vim.bo[state.buf].modifiable = false

    local title = current.label or display_path(path)
    local config = {
        relative = "editor",
        row = math.max(0, vim.o.lines - #lines - 4),
        col = math.max(0, vim.o.columns - width - 2),
        width = width,
        height = #lines,
        style = "minimal",
        border = "single",
        focusable = false,
        noautocmd = true,
        title = " " .. title .. " ",
        title_pos = "left",
        zindex = 60,
    }
    if state.win and vim.api.nvim_win_is_valid(state.win) then
        local update = vim.deepcopy(config)
        update.noautocmd = nil
        vim.api.nvim_win_set_config(state.win, update)
    else
        state.win = vim.api.nvim_open_win(state.buf, false, config)
    end
    vim.wo[state.win].winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder,FloatTitle:FloatTitle"
    vim.wo[state.win].wrap = false
end

local function reset(schedule_close)
    state.path = {}
    state.mode = nil
    state.generation = state.generation + 1
    if schedule_close then
        local generation = state.generation
        vim.schedule(function()
            if generation == state.generation then close_window() end
        end)
    end
end

local function lookup(root, path)
    local current = root
    for _, token in ipairs(path) do
        current = current.children[token]
        if not current then return nil end
    end
    return current
end

local function execute_path(path, action)
    reset(true)
    vim.schedule(function()
        if action and action.mapping then
            local mapping = action.mapping
            if mapping.callback then
                local result = mapping.callback()
                if mapping.expr == 1 and type(result) == "string" and result ~= "" then
                    vim.api.nvim_feedkeys(vim.keycode(result), mapping.noremap == 0 and "m" or "n", false)
                end
            elseif mapping.rhs and mapping.rhs ~= "" and mapping.rhs ~= "<Nop>" then
                vim.api.nvim_feedkeys(
                    vim.keycode(mapping.rhs),
                    mapping.noremap == 0 and "m" or "n",
                    false
                )
            end
            return
        end
        vim.api.nvim_feedkeys(vim.keycode(path_to_lhs(path)), "n", false)
    end)
end

local function dispatch_prefix(mode, first)
    mode = canonical_mode(mode)
    local root = current_root(mode)
    local path = { first }
    local current = lookup(root, path)
    if not current or not next(current.children) then
        execute_path(path, current and current.action or nil)
        return
    end

    state.mode = mode
    state.path = vim.deepcopy(path)
    while current and next(current.children) do
        state.generation = state.generation + 1
        render(current, path, state.generation)
        vim.cmd.redraw()

        local ok, typed = pcall(vim.fn.getcharstr)
        if not ok or typed == "" then
            reset(true)
            return
        end
        local incoming = typed_tokens(typed)
        if #incoming == 0 or incoming[1] == "<Esc>" then
            reset(true)
            return
        end
        for _, token in ipairs(incoming) do
            path[#path + 1] = token
            current = current.children[token]
            if not current then
                execute_path(path, nil)
                return
            end
        end
        state.path = vim.deepcopy(path)
    end
    execute_path(path, current and current.action or nil)
end

local function install_intercepts(mode, root)
    local bufnr = vim.api.nvim_get_current_buf()
    state.intercepts[bufnr] = state.intercepts[bufnr] or {}
    state.intercepts[bufnr][mode] = state.intercepts[bufnr][mode] or {}
    local installed = state.intercepts[bufnr][mode]
    for first, child in pairs(root.children) do
        if next(child.children) and not (excluded_prefixes[mode] or {})[first] then
            local lhs = token_to_lhs(first)
            local existing = vim.fn.maparg(lhs, mode, false, true)
            if not installed[lhs]
                or type(existing) ~= "table"
                or existing.desc ~= "[keytree prefix]" then
                vim.keymap.set(mode, lhs, function() dispatch_prefix(mode, first) end, {
                    buffer = bufnr,
                    desc = "[keytree prefix]",
                    nowait = true,
                    silent = true,
                })
                installed[lhs] = true
            end
        end
    end
end

local function flatten(root)
    local by_action = {}
    local function visit(current, path)
        if current.action and current.action.executable then
            local action = current.action
            local item = by_action[action.id]
            if not item then
                item = { description = action.desc, bindings = {}, lhs = path_to_lhs(path), source = action.source }
                by_action[action.id] = item
            end
            item.bindings[#item.bindings + 1] = display_path(path)
        end
        for key, child in pairs(current.children) do
            local next_path = vim.deepcopy(path)
            next_path[#next_path + 1] = key
            visit(child, next_path)
        end
    end
    visit(root, {})

    local items = {}
    for _, item in pairs(by_action) do
        table.sort(item.bindings)
        items[#items + 1] = item
    end
    table.sort(items, function(a, b)
        if a.description == b.description then return a.bindings[1] < b.bindings[1] end
        return a.description:lower() < b.description:lower()
    end)
    return items
end

function M.register_group(mode, lhs, label)
    mode = canonical_mode(mode)
    state.groups[mode] = state.groups[mode] or {}
    state.groups[mode][lhs] = label
    state.roots[mode] = nil
end

function M.refresh(mode)
    reset(true)
    if mode then
        local root = rebuild(mode)
        install_intercepts(canonical_mode(mode), root)
        return root
    end
    state.roots = {}
    local current_mode = canonical_mode()
    local root = rebuild(current_mode)
    install_intercepts(current_mode, root)
    return root
end

function M.snapshot(mode)
    mode = canonical_mode(mode)
    local root = current_root(mode, true)
    return { mode = mode, root = root, actions = flatten(root) }
end

function M.pick()
    reset(true)
    local mode = canonical_mode()
    local items = flatten(current_root(mode, true))
    if #items == 0 then
        vim.notify("No commands are available in this mode", vim.log.levels.INFO)
        return
    end

    local binding_width = 0
    for _, item in ipairs(items) do
        binding_width = math.max(binding_width, math.min(30, vim.fn.strdisplaywidth(table.concat(item.bindings, " "))))
    end
    local choices = {}
    local selected_by_line = {}
    for _, item in ipairs(items) do
        local bindings = table.concat(item.bindings, " ")
        if vim.fn.strdisplaywidth(bindings) > 30 then bindings = vim.fn.strcharpart(bindings, 0, 29) .. "…" end
        local line = bindings
            .. string.rep(" ", binding_width - vim.fn.strdisplaywidth(bindings))
            .. "  "
            .. item.description
        choices[#choices + 1] = line
        selected_by_line[line] = item
    end

    require("fzf-lua").fzf_exec(choices, {
        prompt = "",
        winopts = { title = false, preview = { hidden = true } },
        actions = {
            ["default"] = function(selected)
                local item = selected and selected_by_line[selected[1]]
                if not item then return end
                vim.schedule(function()
                    vim.api.nvim_feedkeys(vim.keycode(item.lhs), "m", false)
                end)
            end,
        },
    })
end

function M.setup()
    if state.setup then return end
    state.setup = true
    state.builtin = load_builtin_catalog()
    M.register_group("n", "<leader>", "Space")
    M.register_group("v", "<leader>", "Space")
    local initial_mode = canonical_mode()
    local initial_root = rebuild(initial_mode)
    install_intercepts(initial_mode, initial_root)

    local function schedule_refresh()
        if state.refresh_pending then return end
        state.refresh_pending = true
        vim.schedule(function()
            state.refresh_pending = false
            M.refresh()
        end)
    end

    local group = vim.api.nvim_create_augroup("stargazing_keytree", { clear = true })
    vim.api.nvim_create_autocmd({ "VimEnter", "BufEnter", "FileType", "LspAttach" }, {
        group = group,
        callback = function(event)
            if event.buf and vim.api.nvim_buf_is_valid(event.buf)
                and vim.bo[event.buf].filetype == "stargazing-keytree" then
                return
            end
            schedule_refresh()
        end,
    })
    vim.api.nvim_create_autocmd({ "ModeChanged", "CmdlineEnter", "VimResized" }, {
        group = group,
        callback = function() reset(true) end,
    })
    vim.api.nvim_create_user_command("KeyTreeRefresh", function() M.refresh() end, {
        desc = "Refresh the generated key-action tree",
    })
end

return M
