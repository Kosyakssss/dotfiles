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
opt.numberwidth = 2
opt.wrap = true
opt.linebreak = true
opt.breakindent = true
opt.cursorline = true
opt.scrolloff = 4
opt.inccommand = "nosplit"
opt.winborder = "rounded"
opt.hlsearch = true
opt.guicursor = "n-v-c-sm:block-Cursor,i-ci-ve:ver25-Cursor,r-cr-o:hor20-Cursor"
opt.clipboard = 'unnamedplus'

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
    virtual_text = true,
    signs = true,
    underline = true,
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
        winopts = { height = 0.4, width = 0.35 },
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
    'https://github.com/nvim-tree/nvim-web-devicons',
    'https://github.com/akinsho/bufferline.nvim',
    'https://github.com/nvim-treesitter/nvim-treesitter',
    'https://github.com/neovim/nvim-lspconfig',
    'https://github.com/mason-org/mason.nvim',
    'https://github.com/mason-org/mason-lspconfig.nvim',
    { src = 'https://github.com/Saghen/blink.cmp', version = 'v1.*' },
    'https://github.com/echasnovski/mini.pairs',
    'https://github.com/nvim-lualine/lualine.nvim',
    'https://github.com/nvim-mini/mini.surround',
})


-- ╔══════════════════════════════════════════════════════════════════╗
-- ║  Plugin Setup                                                    ║
-- ╚══════════════════════════════════════════════════════════════════╝

-- ── Theme ────────────────────────────────────────────────────────
vim.cmd.colorscheme "flexoki"

local function is_writing_file()
    return vim.tbl_contains({ "asciidoc", "gitcommit", "markdown", "rst", "text" }, vim.bo.filetype)
end

local function words_or_location()
    if is_writing_file() then
        return vim.fn.wordcount().words .. " words"
    end

    return string.format("%3d:%-2d", vim.fn.line("."), vim.fn.charcol("."))
end


require('lualine').setup {
    options = {
        theme = "auto",
    },
    sections = {
        lualine_a = {'mode'},
        lualine_b = {'diagnostics'},
        lualine_c = {'filename'},
        lualine_x = {'filetype'},
        lualine_y = {'progress'},
        lualine_z = { words_or_location }
    },
    inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = {'filename'},
        lualine_x = {'location'},
        lualine_y = {},
        lualine_z = {}
    },
}


-- ── Bufferline ───────────────────────────────────────────────────
require("bufferline").setup{
    options = {
        always_show_bufferline = false,
    }
}


-- ── Fzf ──────────────────────────────────────────────────────────
require("fzf-lua").setup {
    file_ignore_patterns = { "%.obsidian/" },
    defaults = {
        file_icons = true,
    },
    files = {
        fd_opts = "--type f --hidden --exclude .obsidian --exclude .DS_Store --exclude Library",
    },
    grep = {
        rg_opts = "--column --line-number --no-heading --color=always --smart-case --glob '!.obsidian/' --glob '!.DS_Store' --glob '!Library/'",
    },
}


-- ── LSP ──────────────────────────────────────────────────────────
require('nvim-treesitter').setup{}
require("mason").setup({
    ui = { border = "rounded" },
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
        documentation = { auto_show = true },
    },
    sources = {
        default = { 'lsp', 'path', 'buffer' },
    },
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

map("n", "<leader>f", ":FzfLua files<CR>", {desc = "Find"})
map("n", "<leader>/", ":FzfLua live_grep<CR>", {desc = "Grep"})
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



-- ── LSP command palette ──────────────────────────────────────────
map("n", "<leader>p", function()
    local items = {}
    local actions = {
        { name = "Code Action",      fn = vim.lsp.buf.code_action },
        { name = "Rename",           fn = vim.lsp.buf.rename },
        { name = "Format",           fn = function() vim.lsp.buf.format({ async = true }) end },
        { name = "Hover",            fn = vim.lsp.buf.hover },
        { name = "Signature Help",   fn = vim.lsp.buf.signature_help },
        { name = "Type Definition",  fn = vim.lsp.buf.type_definition },
        { name = "Implementation",   fn = vim.lsp.buf.implementation },
        { name = "Workspace Symbol", fn = vim.lsp.buf.workspace_symbol },
    }
    for _, a in ipairs(actions) do
        table.insert(items, { label = a.name, fn = a.fn })
    end
    -- Server-advertised workspace commands
    for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
        local cmds = (client.server_capabilities or {}).executeCommandProvider or {}
        for _, cmd in ipairs(cmds.commands or {}) do
            local c, cl = cmd, client
            table.insert(items, { label = cmd .. " [" .. cl.name .. "]", fn = function() cl:exec_cmd({ command = c }) end })
        end
    end
    require("fzf-lua").fzf_exec(
        vim.tbl_map(function(item) return item.label end, items),
        {
            prompt = "LSP Command> ",
            actions = {
                ["default"] = function(selected)
                    for _, item in ipairs(items) do
                        if item.label == selected[1] then
                            item.fn()
                            return
                        end
                    end
                end,
            },
        }
    )
end, { desc = "LSP command palette" })


-- ── Trim trailing whitespace ─────────────────────────────────────
vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = "*",
    callback = function()
        local pos = vim.api.nvim_win_get_cursor(0)
        vim.cmd([[%s/\s\+$//e]])
        vim.api.nvim_win_set_cursor(0, pos)
    end,
})
