local modes = {
    n = { "NOR", "StlModeNOR" },
    i = { "INS", "StlModeINS" },
    v = { "VIS", "StlModeVIS" },
    V = { "VIS", "StlModeVIS" },
    ["\22"] = { "VIS", "StlModeVIS" },
    c = { "CMD", "StlModeCMD" },
    t = { "TER", "StlModeTER" },
    R = { "REP", "StlModeREP" },
    s = { "SEL", "StlModeSEL" },
    S = { "SEL", "StlModeSEL" },
    ["\19"] = { "SEL", "StlModeSEL" },
}

local wordy = { markdown = true, text = true, gitcommit = true, typst = true }

local jj_template =
[[if(current_working_copy, "change=" ++ change_id.shortest(8) ++ "\n" ++ diff.summary() ++ "\n", "") ++ if(bookmarks, "bookmark=" ++ bookmarks.join(",") ++ "\n", "")]]

local count_order = { "untracked", "added", "modified", "deleted", "moved", "unmerged" }
local count_signs = { untracked = "?", added = "+", modified = "~", deleted = "-", moved = ">", unmerged = "x" }
local jj_codes = { A = "added", C = "added", M = "modified", D = "deleted", R = "moved" }
local git_codes = { ["?"] = "untracked", A = "added", D = "deleted", U = "unmerged", M = "modified", R = "modified", C =
"modified", m = "modified" }

local function new_counts()
    return { untracked = 0, added = 0, modified = 0, deleted = 0, moved = 0, unmerged = 0 }
end

local function bump(counts, codes, code)
    local field = codes[code]
    if field then
        counts[field] = counts[field] + 1
    end
end

local function format_diff_counts(counts)
    local parts = {}
    for _, key in ipairs(count_order) do
        if counts[key] > 0 then
            parts[#parts + 1] = count_signs[key] .. counts[key]
        end
    end
    if #parts == 0 then return nil end
    return table.concat(parts, " ")
end

local function buf_cwd(buf)
    local name = vim.api.nvim_buf_get_name(buf)
    return name ~= "" and vim.fn.fnamemodify(name, ":p:h") or vim.uv.cwd()
end

local function run(cmd, dir)
    local ok, result = pcall(vim.system, cmd, { cwd = dir, text = true })
    if not ok then return nil end
    local completed = result:wait()
    if completed.code ~= 0 then return nil end
    return completed.stdout or ""
end

local function update_jj(buf, dir)
    local stdout = run({
        "jj", "log", "--no-pager", "--color", "never",
        "-r", "latest(ancestors(@) & bookmarks(), 1) | @",
        "--no-graph", "-T", jj_template,
    }, dir)
    if stdout == nil then return false end
    local fields = {}
    local counts = new_counts()
    for line in stdout:gmatch("[^\n]+") do
        local key, value = line:match("^([^=]+)=(.*)$")
        if key then
            fields[key] = value
        else
            bump(counts, jj_codes, line:sub(1, 1))
        end
    end
    if fields.change then
        vim.b[buf].vcs_revision = (fields.bookmark and "(" .. fields.bookmark .. ") " or "") .. fields.change
    else
        vim.b[buf].vcs_revision = nil
    end
    vim.b[buf].vcs_diff = format_diff_counts(counts)
    return true
end

local function update_git(buf, dir)
    local stdout = run({
        "git", "--no-optional-locks", "-c", "core.quotepath=false", "-c", "color.status=false",
        "status", "--untracked-files=normal", "--branch", "--porcelain=2",
    }, dir)
    if stdout == nil then return false end
    local working = new_counts()
    local staging = new_counts()
    local branch = nil
    for line in stdout:gmatch("[^\n]+") do
        local head = line:match("^# branch.head (.+)$")
        if head then
            branch = head
        elseif line:sub(1, 2) == "? " then
            working.untracked = working.untracked + 1
        elseif line:sub(1, 1) == "1" or line:sub(1, 1) == "2" or line:sub(1, 1) == "u" then
            bump(staging, git_codes, line:sub(3, 3))
            bump(working, git_codes, line:sub(4, 4))
        end
    end
    if branch and branch ~= "(detached)" then
        vim.b[buf].vcs_revision = "(" .. branch .. ")"
    else
        vim.b[buf].vcs_revision = nil
    end
    local working_status = format_diff_counts(working)
    local staging_status = format_diff_counts(staging)
    if working_status and staging_status then
        vim.b[buf].vcs_diff = working_status .. " | " .. staging_status
    else
        vim.b[buf].vcs_diff = working_status or staging_status
    end
    return true
end

local function update_vcs(buf)
    if not vim.api.nvim_buf_is_valid(buf) then return end
    local dir = buf_cwd(buf)
    if vim.fs.root(buf, ".jj") ~= nil then
        if update_jj(buf, dir) then return end
    end
    if vim.fs.root(buf, ".git") ~= nil then
        if update_git(buf, dir) then return end
    end
    vim.b[buf].vcs_revision = nil
    vim.b[buf].vcs_diff = nil
end

vim.api.nvim_create_autocmd({ "BufEnter", "FocusGained", "BufWritePost" }, {
    group = vim.api.nvim_create_augroup("vcs_statusline", {}),
    callback = function(args)
        update_vcs(args.buf)
        vim.cmd("redrawstatus!")
    end,
})

vim.api.nvim_create_autocmd("DiagnosticChanged", {
    group = vim.api.nvim_create_augroup("diagnostic_statusline", {}),
    callback = function()
        vim.cmd("redrawstatus!")
    end,
})

function _G._statusline()
    local mode = modes[vim.fn.mode()] or { vim.fn.mode():upper(), "StlModeNOR" }
    local name = vim.fn.expand("%:t")
    if name == "" then
        name = "[scratch]"
    end
    if vim.bo.modified then
        name = name .. " [+]"
    end
    local left_parts = { "%#" .. mode[2] .. "#" .. mode[1] .. "%*" }
    left_parts[#left_parts + 1] = name
    local vcs_parts = {}
    local revision = vim.b.vcs_revision
    if revision then
        vcs_parts[#vcs_parts + 1] = revision
    end
    local diff = vim.b.vcs_diff
    if diff then
        vcs_parts[#vcs_parts + 1] = diff
    end
    if #vcs_parts > 0 then
        local group = diff and "StlVcsDirty" or "StlVcsClean"
        left_parts[#left_parts + 1] = "%#" .. group .. "#" .. table.concat(vcs_parts, " ") .. "%*"
    end
    local counts = vim.diagnostic.count(0) or {}
    local right_parts = {}
    if (counts[1] or 0) > 0 then
        right_parts[#right_parts + 1] = "%#DiagnosticError#E" .. counts[1] .. "%*"
    end
    if (counts[2] or 0) > 0 then
        right_parts[#right_parts + 1] = "%#DiagnosticWarn#W" .. counts[2] .. "%*"
    end
    if (counts[3] or 0) > 0 then
        right_parts[#right_parts + 1] = "%#DiagnosticInfo#I" .. counts[3] .. "%*"
    end
    if (counts[4] or 0) > 0 then
        right_parts[#right_parts + 1] = "%#DiagnosticHint#H" .. counts[4] .. "%*"
    end
    if wordy[vim.bo.filetype] then
        right_parts[#right_parts + 1] = vim.fn.wordcount().words .. " words"
    else
        right_parts[#right_parts + 1] = "%l:%c"
        right_parts[#right_parts + 1] = "%L"
    end
    return " " .. table.concat(left_parts, " | ") .. "%=" .. table.concat(right_parts, " | ") .. " "
end

vim.o.statusline = "%!v:lua._statusline()"
