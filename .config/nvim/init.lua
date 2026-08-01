-- ╔══════════════════════════════════════════════════════════════════╗
-- ║  Basics                                                          ║
-- ╚══════════════════════════════════════════════════════════════════╝

local opt = vim.opt
opt.signcolumn = "yes:1"
opt.termguicolors = true
opt.ignorecase = true
opt.swapfile = false
opt.autoindent = true
opt.expandtab = true
opt.tabstop = 4
opt.softtabstop = 4
opt.shiftwidth = 4
opt.shiftround = true
opt.number = true
opt.relativenumber = true
opt.numberwidth = 3
opt.wrap = true
opt.linebreak = true
opt.breakindent = true
opt.cursorline = true
opt.cursorlineopt = "both"
opt.scrolloff = 4
opt.inccommand = "nosplit"
opt.winborder = "single"
opt.hlsearch = true
opt.guicursor = "n-v-c-sm:block-Cursor,i-ci-ve:ver25-Cursor,r-cr-o:hor20-Cursor"
opt.clipboard = 'unnamedplus'
opt.mousescroll = "ver:1,hor:1"
opt.statuscolumn = "%s%=%{v:virtnum > 0 ? '' : (v:relnum ? v:relnum : v:lnum)} "
opt.laststatus = 2
opt.showtabline = 0
opt.fixendofline = true

-- ── Mutable state ──────────────────────────────────────────
local state_dir = vim.fn.stdpath("state")
local undo_dir = state_dir .. "/undo"
local spell_dir = state_dir .. "/spell"

opt.undofile = true
opt.undodir = undo_dir
vim.fn.mkdir(undo_dir, "p")

-- ── On-demand formatting ──────────────────────────────────────────
vim.api.nvim_create_user_command("Fmt", function()
    local path = vim.api.nvim_buf_get_name(0)
    if path == "" or vim.bo.buftype ~= "" then
        vim.notify("Fmt requires a file-backed buffer", vim.log.levels.WARN)
        return
    end

    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local input = table.concat(lines, "\n")
    if vim.bo.endofline then input = input .. "\n" end

    local config = vim.fn.expand("~/.config/dprint/dprint.json")
    local result = vim.system(
        { "dprint", "fmt", "--stdin", path, "--config", config },
        { text = true, stdin = input }
    ):wait()
    if result.code ~= 0 then
        local message = vim.trim(result.stderr ~= "" and result.stderr or result.stdout)
        vim.notify(message ~= "" and message or "dprint failed", vim.log.levels.ERROR)
        return
    end

    local output_has_eol = result.stdout:sub(-1) == "\n"
    local output = output_has_eol and result.stdout:sub(1, -2) or result.stdout
    local formatted = output == "" and {} or vim.split(output, "\n", { plain = true })
    local view = vim.fn.winsaveview()
    vim.api.nvim_buf_set_lines(0, 0, -1, false, formatted)
    vim.bo.endofline = output_has_eol
    vim.fn.winrestview(view)
end, { desc = "Format the current buffer with dprint" })

-- User commands must start with an uppercase letter, so transparently expand :fmt.
vim.cmd([[cnoreabbrev <expr> fmt getcmdtype() ==# ':' && getcmdline() ==# 'fmt' ? 'Fmt' : 'fmt']])


-- ── Inlay hints ──────────────────────────────────────────────────
vim.lsp.inlay_hint.enable(true)


-- ── Diagnostics ──────────────────────────────────────────────────
vim.diagnostic.config({
    virtual_text = false,
    signs = true,
    underline = true,
    severity_sort = true,
})

vim.api.nvim_create_autocmd('TextYankPost', {
  group = vim.api.nvim_create_augroup('highlight_yank', {}),
  desc = 'Highlight selection on yank',
  pattern = '*',
  callback = function()
    vim.highlight.on_yank { higroup = 'IncSearch', timeout = 180 }
  end,
})

-- ── Spell ────────────────────────────────────────────────────────
opt.spell = true
opt.spelllang = { "en_us", "ru" }
opt.spellcapcheck = ""
opt.spellfile = spell_dir .. "/words.utf-8.add"

vim.fn.mkdir(spell_dir, "p")

-- Tree-sitter parses most raw Markdown URLs as plain inline text, so an
-- @nospell query cannot target them. Mark URL byte ranges directly instead.
local url_nospell_namespace = vim.api.nvim_create_namespace("url_nospell")
local url_nospell_pending = {}

local function mark_urls_nospell(buf)
    if not vim.api.nvim_buf_is_valid(buf) then return end

    vim.api.nvim_buf_clear_namespace(buf, url_nospell_namespace, 0, -1)

    for row, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
        local offset = 1
        while offset <= #line do
            local scheme_start, scheme_end = line:find("%a[%w+.-]*://%S+", offset)
            local www_start, www_end = line:find("www%.%S+", offset)
            local url_start, url_end

            if scheme_start and (not www_start or scheme_start <= www_start) then
                url_start, url_end = scheme_start, scheme_end
            else
                url_start, url_end = www_start, www_end
            end

            if not url_start then break end

            vim.api.nvim_buf_set_extmark(buf, url_nospell_namespace, row - 1, url_start - 1, {
                end_row = row - 1,
                end_col = url_end,
                spell = false,
            })
            offset = url_end + 1
        end
    end
end

local function schedule_url_nospell(buf)
    if url_nospell_pending[buf] then return end
    url_nospell_pending[buf] = true
    vim.schedule(function()
        url_nospell_pending[buf] = nil
        if vim.api.nvim_buf_is_valid(buf) then mark_urls_nospell(buf) end
    end)
end

local url_nospell_group = vim.api.nvim_create_augroup("url_nospell", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
    group = url_nospell_group,
    pattern = { "markdown", "text" },
    callback = function(args) schedule_url_nospell(args.buf) end,
})
vim.api.nvim_create_autocmd({ "BufEnter", "TextChanged", "TextChangedI" }, {
    group = url_nospell_group,
    callback = function(args)
        if vim.tbl_contains({ "markdown", "text" }, vim.bo[args.buf].filetype) then
            schedule_url_nospell(args.buf)
        end
    end,
})

vim.keymap.set("n", "z=", function()
    local bad = vim.fn.spellbadword()
    local word = bad[1]
    if word == "" then
        vim.notify("No misspelled word under cursor")
        return
    end

    local suggestions = vim.fn.spellsuggest(word, 20)
    if #suggestions == 0 then
        vim.notify("No suggestions for: " .. word)
        return
    end

    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    local line = vim.api.nvim_get_current_line()
    local word_start = line:find(vim.pesc(word), col + 1 - #word, true) or (col + 1)
    local word_end = word_start + #word - 1

    require("fzf-lua").fzf_exec(suggestions, {
        prompt = "Spell fix ❯ ",
        actions = {
            ["default"] = function(sel)
                if sel and sel[1] then
                    vim.api.nvim_buf_set_text(
                        0,
                        row - 1, word_start - 1,
                        row - 1, word_end,
                        { sel[1] }
                    )
                end
            end,
        },
    })
end, { desc = "Spell suggestions" })


-- ╔══════════════════════════════════════════════════════════════════╗
-- ║  Plugins                                                         ║
-- ╚══════════════════════════════════════════════════════════════════╝

vim.pack.add({
    'https://github.com/nvim-lua/plenary.nvim',
    'https://github.com/mikavilpas/yazi.nvim',
    'https://github.com/ibhagwan/fzf-lua',
    'https://github.com/nvim-treesitter/nvim-treesitter',
    'https://github.com/neovim/nvim-lspconfig',
    'https://github.com/mason-org/mason.nvim',
    'https://github.com/mason-org/mason-lspconfig.nvim',
    { src = 'https://github.com/Saghen/blink.cmp', version = 'v1.*' },
    'https://github.com/echasnovski/mini.pairs',
    'https://github.com/nvim-mini/mini.surround',
})


-- ╔══════════════════════════════════════════════════════════════════╗
-- ║  Plugin Setup                                                    ║
-- ╚══════════════════════════════════════════════════════════════════╝

-- ── Theme ────────────────────────────────────────────────────────
vim.cmd.colorscheme "stargazing-grey-fruit-dark"

local function is_writing_file(buf)
    return vim.tbl_contains({ "asciidoc", "gitcommit", "markdown", "rst", "text" }, vim.bo[buf or 0].filetype)
end

-- ── Native statusline and bufferline ─────────────────────────────
local mode_styles = {
    n = { "NOR", "StargazingModeNormal" },
    i = { "INS", "StargazingModeInsert" },
    R = { "REP", "StargazingModeInsert" },
    v = { "SEL", "StargazingModeSelect" },
    V = { "SEL", "StargazingModeSelect" },
    ["\22"] = { "SEL", "StargazingModeSelect" },
    s = { "SEL", "StargazingModeSelect" },
    S = { "SEL", "StargazingModeSelect" },
    ["\19"] = { "SEL", "StargazingModeSelect" },
    c = { "CMD", "StargazingModeNormal" },
    t = { "TER", "StargazingModeNormal" },
}

local function status_filename(buf)
    local name = vim.api.nvim_buf_get_name(buf)
    name = name == "" and "[scratch]" or vim.fn.fnamemodify(name, ":t")
    return name:gsub("%%", "%%%%")
end

local function statusline_buffer()
    local win = tonumber(vim.g.statusline_winid)
    if win and vim.api.nvim_win_is_valid(win) then return vim.api.nvim_win_get_buf(win) end
    return vim.api.nvim_get_current_buf()
end

function _G.stargazing_statusline()
    local buf = statusline_buffer()
    local mode = vim.api.nvim_get_mode().mode:sub(1, 1)
    local style = mode_styles[mode] or mode_styles.n
    local modified = vim.bo[buf].modified and " [+]" or ""
    local diagnostics = {}
    local levels = {
        { vim.diagnostic.severity.ERROR, "E", "DiagnosticError" },
        { vim.diagnostic.severity.WARN, "W", "DiagnosticWarn" },
        { vim.diagnostic.severity.INFO, "I", "DiagnosticInfo" },
        { vim.diagnostic.severity.HINT, "H", "DiagnosticHint" },
    }
    for _, level in ipairs(levels) do
        local count = #vim.diagnostic.get(buf, { severity = level[1] })
        if count > 0 then
            diagnostics[#diagnostics + 1] = string.format("%%#%s#%s:%d%%#StatusLine#", level[3], level[2], count)
        end
    end
    local right
    if is_writing_file(buf) then
        right = vim.fn.wordcount().words .. " words"
    else
        right = string.format("%d:%d %d", vim.fn.line("."), vim.fn.charcol("."), vim.fn.line("$"))
    end
    local diag = #diagnostics > 0 and (" " .. table.concat(diagnostics, " ")) or ""
    return string.format("%%#%s# %s %%#StatusLine# %s%s%s%%= %s ",
        style[2], style[1], status_filename(buf), modified, diag, right)
end

function _G.stargazing_inactive_statusline()
    return "%#StatusLineNC# " .. status_filename(statusline_buffer()) .. " %="
end

vim.opt.statusline = "%!v:lua.stargazing_statusline()"
vim.opt_local.statusline = "%!v:lua.stargazing_statusline()"
vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter" }, {
    callback = function() vim.wo.statusline = "%!v:lua.stargazing_statusline()" end,
})
vim.api.nvim_create_autocmd("WinLeave", {
    callback = function() vim.wo.statusline = "%!v:lua.stargazing_inactive_statusline()" end,
})

function _G.stargazing_select_buffer(minwid)
    if vim.api.nvim_buf_is_valid(minwid) then vim.api.nvim_set_current_buf(minwid) end
end

function _G.stargazing_tabline()
    local buffers = vim.fn.getbufinfo({ buflisted = 1 })
    local current = vim.api.nvim_get_current_buf()
    local parts = { "%#TabLineFill#" }
    for _, info in ipairs(buffers) do
        local group = info.bufnr == current and "TabLineSel" or "TabLine"
        local changed = info.changed == 1 and " [+]" or ""
        parts[#parts + 1] = string.format("%%%d@v:lua.stargazing_select_buffer@%%#%s# %s%s %%X",
            info.bufnr, group, status_filename(info.bufnr), changed)
    end
    parts[#parts + 1] = "%#TabLineFill#%="
    return table.concat(parts)
end

vim.opt.tabline = "%!v:lua.stargazing_tabline()"
local function update_tabline_visibility()
    vim.opt.showtabline = #vim.fn.getbufinfo({ buflisted = 1 }) > 1 and 2 or 0
end
vim.api.nvim_create_autocmd({ "BufAdd", "BufDelete", "BufEnter" }, {
    callback = function() vim.schedule(update_tabline_visibility) end,
})
update_tabline_visibility()

-- ── Fzf ──────────────────────────────────────────────────────────
local function picker_root()
    local buffer_path = vim.api.nvim_buf_get_name(0)
    local start = buffer_path ~= "" and vim.fs.dirname(buffer_path) or vim.uv.cwd()
    local roots = {}
    for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
        if client.config.root_dir then roots[#roots + 1] = client.config.root_dir end
        for _, folder in ipairs(client.workspace_folders or {}) do
            local path = vim.uri_to_fname(folder.uri)
            if buffer_path == "" or vim.startswith(buffer_path, path .. "/") then roots[#roots + 1] = path end
        end
    end
    table.sort(roots, function(a, b) return #a > #b end)
    if roots[1] then return roots[1] end
    local marker = vim.fs.find(".git", { path = start, upward = true })[1]
    return marker and vim.fs.dirname(marker) or start
end

local function nvim_ignore_args()
    local path = vim.fn.stdpath("config") .. "/ignore"
    if vim.fn.filereadable(path) == 1 then
        return "--ignore-file " .. vim.fn.shellescape(path)
    end
    return ""
end

local fzf = require("fzf-lua")
fzf.setup {
    winopts = {
        fullscreen = true,
        border = "single",
        backdrop = 100,
        title = false,
        title_flags = false,
        preview = {
            layout = "horizontal",
            horizontal = "right:50%",
            border = "single",
            title = false,
            wrap = true,
            scrollbar = false,
            winopts = { cursorline = false, number = false, relativenumber = false, signcolumn = "no", wrap = true },
        },
    },
    defaults = { file_icons = false, git_icons = false, color_icons = false },
    fzf_opts = {
        ["--pointer"] = ">",
        ["--marker"] = ">",
        ["--info"] = "right",
        ["--separator"] = "─",
        ["--scrollbar"] = "",
        ["--no-bold"] = true,
    },
    fzf_colors = {
        ["fg"] = { "fg", "Normal" }, ["bg"] = { "bg", "Normal" },
        ["hl"] = { "fg", "Normal" }, ["fg+"] = { "fg", "Normal" },
        ["bg+"] = { "bg", "PmenuSel" }, ["hl+"] = { "fg", "Normal" },
        ["info"] = { "fg", "Comment" }, ["prompt"] = { "fg", "Normal" },
        ["pointer"] = { "fg", "Normal" }, ["marker"] = { "fg", "Normal" },
        ["spinner"] = { "fg", "Normal" }, ["header"] = { "fg", "Comment" },
        ["border"] = { "fg", "FloatBorder" },
    },
    files = {
        cwd_prompt = false,
        hidden = true,
        prompt = "",
        winopts = { title = false },
    },
}

local function find_files()
    local root = picker_root()
    local ignore = nvim_ignore_args()
    fzf.files({
        cwd = root,
        prompt = "",
        hidden = true,
        winopts = { title = false },
        fd_opts = "--type f --type l --follow --hidden --color=never " .. ignore,
    })
end

local function live_grep()
    local root = picker_root()
    local ignore = nvim_ignore_args()
    fzf.live_grep({
        cwd = root,
        prompt = "",
        rg_opts = "--column --line-number --no-heading --color=always --smart-case --follow --hidden " .. ignore,
    })
end


-- ── LSP ──────────────────────────────────────────────────────────
require('nvim-treesitter').setup{}
require("mason").setup({
    ui = { border = "single" },
})
require("mason-lspconfig").setup({
    automatic_enable = true,
    ensure_installed = {
        "lua_ls",
        "markdown_oxide",
        "rust_analyzer",
        "ts_ls",
        "html",
        "cssls",
    },
})


-- ── Completion ───────────────────────────────────────────────────
require('blink.cmp').setup({
    keymap = { preset = 'default' },
    completion = {
        menu = {
            border = "single",
            draw = { columns = { { "label", "label_description", gap = 1 }, { "kind" } } },
        },
        documentation = { auto_show = true, window = { border = "single" } },
    },
    signature = { window = { border = "single" } },
    sources = {
        default = { 'lsp', 'path', 'buffer' },
    },
})


-- ── File manager ─────────────────────────────────────────────────
require("yazi").setup({
    floating_window_scaling_factor = 1,
    yazi_floating_window_border = "single",
})


-- ── Autopairs & surround ─────────────────────────────────────────
require('mini.pairs').setup()
require('mini.surround').setup()


-- ╔══════════════════════════════════════════════════════════════════╗
-- ║  Keymaps                                                         ║
-- ╚══════════════════════════════════════════════════════════════════╝

local russian = "ёйцукенгшщзхъфывапролджэячсмитьбю"
local english = "`qwertyuiop[]asdfghjkl;'zxcvbnm,."
local russian_upper = "ЁЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЖЭЯЧСМИТЬБЮ"
local english_upper = "~QWERTYUIOP{}ASDFGHJKL:\"ZXCVBNM<>"

local function set_russian_langmap()
    local special = { [";"] = true, [","] = true, ['"'] = true, ["|"] = true, ["\\"] = true }
    local mappings = {}

    local function add_mapping(source, target)
        if special[source] then source = "\\" .. source end
        if special[target] then target = "\\" .. target end
        table.insert(mappings, source .. target)
    end

    local function add_layout(from, to)
        for index = 0, vim.fn.strchars(from) - 1 do
            local source = vim.fn.strcharpart(from, index, 1)
            local target = vim.fn.strcharpart(to, index, 1)
            add_mapping(source, target)
        end
    end

    add_layout(russian, english)
    add_layout(russian_upper, english_upper)
    vim.opt.langmap = table.concat(mappings, ",")
    vim.opt.langremap = false
end

set_russian_langmap()

local russian_keys = {}
for index = 0, vim.fn.strchars(english) - 1 do
    russian_keys[vim.fn.strcharpart(english, index, 1)] = vim.fn.strcharpart(russian, index, 1)
    russian_keys[vim.fn.strcharpart(english_upper, index, 1)] = vim.fn.strcharpart(russian_upper, index, 1)
end

local function russian_keymap(lhs)
    local translated = {}
    local index = 1

    while index <= #lhs do
        if lhs:sub(index, index) == "<" then
            local close = lhs:find(">", index, true)
            if close then
                table.insert(translated, lhs:sub(index, close))
                index = close + 1
            else
                table.insert(translated, russian_keys["<"] or "<")
                index = index + 1
            end
        else
            local key = lhs:sub(index, index)
            table.insert(translated, russian_keys[key] or key)
            index = index + 1
        end
    end

    return table.concat(translated)
end

local function map(mode, lhs, rhs, opts)
    vim.keymap.set(mode, lhs, rhs, opts)

    -- Keep the Insert-mode escape chord Latin-only.
    if lhs == "jk" and (mode == "i" or vim.tbl_contains(mode, "i")) then return end

    local russian_lhs = russian_keymap(lhs)
    if russian_lhs ~= lhs then
        vim.keymap.set(mode, russian_lhs, rhs, opts)
    end
end

vim.g.mapleader = " "

map("n", "<C-г>", "<C-u>", { desc = "Scroll up (Russian layout)" })
map("n", "<C-в>", "<C-d>", { desc = "Scroll down (Russian layout)" })

map("n", "<leader>w", ":write<CR>", {desc = "Write"})
map("n", "<leader>q", ":quit<CR>", {desc = "Quit"})
map("i", "jk", "<Esc>", {desc = "Esc"})
map("n", "<Esc><Esc>", ":noh<CR>", {desc = "noh"})

map("n", "<leader>y", ":Yazi<CR>", {desc = "Yazi"})
map("n", "<leader>.", ":Yazi cwd<CR>", {desc = "Yazi"})

map("n", "<leader>f", find_files, {desc = "Find"})
map("n", "<leader>/", live_grep, {desc = "Grep"})
map("n", "<leader>b", ":FzfLua buffers<CR>", {desc = "Buffers"})
map("n", "<leader>s", ":FzfLua lsp_document_symbols<CR>", {desc = "Symbols"})
map("n", "<leader>r", ":FzfLua lsp_references<CR>", {desc = "References"})
map("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })

map("n", "<Tab>", ":bnext<CR>", { desc = "Next buffer" })
map("n", "<S-Tab>", ":bprevious<CR>", { desc = "Previous buffer" })
map("n", "<leader>d", ":bdelete<CR>", { desc = "Close buffer" })


-- ── Motion ───────────────────────────────────────────────────────
map({"n", "v"}, "j", "mode() ==# 'V' ? 'j' : (v:count == 0 ? 'gj' : 'j')", { expr = true, desc = "Down (wrap-aware)" })
map({"n", "v"}, "k", "mode() ==# 'V' ? 'k' : (v:count == 0 ? 'gk' : 'k')", { expr = true, desc = "Up (wrap-aware)" })


-- ── Templates ────────────────────────────────────────────────────
local templates_dir = vim.fn.expand("~/Notes/Templates")

map("n", "<leader>t", function()
    require("fzf-lua").files({
        prompt = "Template ❯ ",
        cwd = templates_dir,
        file_icons = false,
        actions = {
            ["default"] = function(selected)
                if not selected or not selected[1] then return end
                local lines = vim.fn.readfile(templates_dir .. "/" .. selected[1])
                local row = vim.api.nvim_win_get_cursor(0)[1]
                vim.api.nvim_buf_set_lines(0, row-1, row-1, false, lines)
            end,
        },
    })
end, { desc = "Insert template above" })


-- ── Insert helpers ───────────────────────────────────────────────
map("i", ",date", function() return vim.fn.strftime("%Y-%m-%d") end, { expr = true, desc = "Insert date" })
map("i", ",time", function() return vim.fn.strftime("%H:%M") end, { expr = true, desc = "Insert time" })



-- ── Diagnostics picker ───────────────────────────────────────────
map("n", "<leader>P", ":FzfLua diagnostics_workspace<CR>", { desc = "Diagnostics" })



-- ── Generated key tree and LSP commands ──────────────────────────
local keytree = require("stargazing.keytree")

map("n", "<leader>p", function()
    local commands = {}
    for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
        local provider = (client.server_capabilities or {}).executeCommandProvider or {}
        for _, command in ipairs(provider.commands or {}) do
            local attached_client = client
            local command_name = command
            commands[#commands + 1] = {
                label = command_name .. " [" .. attached_client.name .. "]",
                run = function() attached_client:exec_cmd({ command = command_name }) end,
            }
        end
    end
    if #commands == 0 then
        vim.notify("No LSP workspace commands are available", vim.log.levels.INFO)
        return
    end
    table.sort(commands, function(a, b) return a.label < b.label end)
    local by_label = {}
    local labels = {}
    for _, command in ipairs(commands) do
        labels[#labels + 1] = command.label
        by_label[command.label] = command
    end
    require("fzf-lua").fzf_exec(
        labels,
        {
            prompt = "",
            winopts = { title = false, preview = { hidden = true } },
            actions = {
                ["default"] = function(selected)
                    local command = selected and by_label[selected[1]]
                    if command then command.run() end
                end,
            },
        }
    )
end, { desc = "LSP workspace commands" })

map("n", "<leader>?", keytree.pick, { desc = "Command palette" })
keytree.setup()


-- ── Indent guides ────────────────────────────────────────────────
local indent_namespace = vim.api.nvim_create_namespace("stargazing_indent_guides")
local indent_pending = {}

local function refresh_indent_guides(buf)
    if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].buftype ~= "" then return end
    vim.api.nvim_buf_clear_namespace(buf, indent_namespace, 0, -1)
    local width = vim.bo[buf].shiftwidth > 0 and vim.bo[buf].shiftwidth or vim.bo[buf].tabstop
    if width < 1 then return end
    for row, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
        local leading = line:match("^( +)")
        if leading then
            for col = width, #leading - 1, width do
                vim.api.nvim_buf_set_extmark(buf, indent_namespace, row - 1, col, {
                    virt_text = { { "╎", "IndentGuide" } },
                    virt_text_pos = "overlay",
                    hl_mode = "combine",
                    priority = 1,
                })
            end
        end
    end
end

local function schedule_indent_guides(buf)
    if indent_pending[buf] then return end
    indent_pending[buf] = true
    vim.defer_fn(function()
        indent_pending[buf] = nil
        refresh_indent_guides(buf)
    end, 80)
end

vim.api.nvim_create_autocmd({ "BufEnter", "TextChanged", "TextChangedI", "BufWritePost" }, {
    callback = function(args) schedule_indent_guides(args.buf) end,
})

-- ── Helix-style save cleanup ─────────────────────────────────────
local function cleanup_buffer(buf)
    if vim.bo[buf].buftype ~= "" or not vim.bo[buf].modifiable then return end
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local changed = false
    for index, line in ipairs(lines) do
        local clean = line:gsub("%s+$", "")
        if clean ~= line then
            lines[index] = clean
            changed = true
        end
    end
    while #lines > 1 and lines[#lines] == "" do
        table.remove(lines)
        changed = true
    end
    if changed then
        local view = buf == vim.api.nvim_get_current_buf() and vim.fn.winsaveview() or nil
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
        if view then vim.fn.winrestview(view) end
    end
end

vim.api.nvim_create_autocmd("BufWritePre", {
    callback = function(args) cleanup_buffer(args.buf) end,
})

vim.api.nvim_create_autocmd("FocusLost", {
    callback = function()
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            if vim.api.nvim_buf_is_loaded(buf)
                and vim.bo[buf].modified
                and vim.bo[buf].buftype == ""
                and vim.api.nvim_buf_get_name(buf) ~= "" then
                vim.api.nvim_buf_call(buf, function() vim.cmd("silent update") end)
            end
        end
    end,
})
