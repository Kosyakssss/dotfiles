-- written for nvim 0.12
-- General keymap
vim.cmd(
    "set langmap=ФИСВУАПРШОЛДЬТЩЗЙКЫЕГМЦЧНЯЖ;ABCDEFGHIJKLMNOPQRSTUVWXYZ:,фисвуапршолдьтщзйкыегмцчня;abcdefghijklmnopqrstuvwxyz")

vim.g.mapleader = ' '
vim.keymap.set('i', 'jk', '<Esc>')
vim.keymap.set('n', 'j', 'gj')
vim.keymap.set('n', 'k', 'gk')
vim.keymap.set('n', '<Esc><Esc>', ':noh<CR>')
vim.keymap.set('n', '<leader>w', ':write<CR>')
vim.keymap.set('n', '<leader>q', ':quit<CR>')
vim.keymap.set('n', '<Space>y', '"+y')
vim.keymap.set('v', '<Space>y', '"+y')
vim.keymap.set('n', '<Space>o', ':!open % <CR><esc>')
vim.keymap.set('n', '<Tab>', ':bnext<CR>')
vim.keymap.set('n', '<S-Tab>', ':bprevious<CR>')
vim.keymap.set('n', '<leader>dd', ':bd<CR>')
--(Russian)
vim.keymap.set('n', '<leader>ц', ':write<CR>')
vim.keymap.set('n', '<leader>й', ':quit<CR>')
vim.keymap.set('n', '<Space>н', '"+y')
vim.keymap.set('v', '<Space>н', '"+y')
vim.keymap.set('n', '<Space>щ', ':!open % <CR><esc>')
vim.keymap.set('n', '<leader>вв', ':bd<CR>')


-- General settings
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = 'yes:1'
vim.opt.scrolloff = 8
vim.opt.wrap = true
vim.opt.linebreak = true
vim.opt.breakindent = true
vim.opt.showbreak = '↪ '
vim.opt.cursorline = true

vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.smarttab = true

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv('HOME') .. '/.config/nvim/undodir'
vim.opt.undofile = true

vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.winborder = 'rounded'
vim.opt.pumborder = 'rounded'
vim.opt.termguicolors = true

vim.api.nvim_create_autocmd('BufEnter', {
    pattern = vim.fn.expand('~') .. '/dotfiles/nvim/init.lua',
    callback = function()
        vim.diagnostic.enable(false)
    end,
})

vim.pack.add({
    { src = 'https://github.com/nvim-lua/plenary.nvim' },
    { src = 'https://github.com/nvim-mini/mini.pairs' },
    { src = 'https://github.com/nvim-mini/mini.surround' },
    { src = 'https://github.com/nvim-mini/mini.completion' },
    { src = 'https://github.com/nvim-mini/mini.comment' },
})

require('mini.pairs').setup()
require('mini.surround').setup()
require('mini.completion').setup()
require('mini.comment').setup()


-- Theming and looks
vim.api.nvim_create_autocmd('TextYankPost', {
    desc = 'Highlights text when yanking',
    group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
    callback = function()
        vim.highlight.on_yank()
    end,
})

vim.pack.add({
    { src = 'https://github.com/MunifTanjim/nui.nvim' },
    { src = 'https://github.com/nvim-tree/nvim-web-devicons' },
    { src = 'https://github.com/nvim-mini/mini.statusline' },
    { src = 'https://github.com/nvim-mini/mini.starter' },
    { src = 'https://github.com/catppuccin/nvim' },
    { src = 'https://github.com/kepano/flexoki-neovim' },
})

require('mini.statusline').setup()
local starter = require('mini.starter')
starter.setup({
    items = {
        starter.sections.recent_files(5, true, false),
    },
    footer = '',
})

require('catppuccin').setup({
    flavour = 'auto',
    background = {
        light = 'latte',
        dark = 'mocha',
    },
})

vim.cmd.colorscheme 'flexoki'


-- File sidebar
vim.pack.add({
    { src = 'https://github.com/nvim-mini/mini.files' },
})
require('mini.files').setup()

vim.keymap.set('n', '<leader>e', ':lua MiniFiles.open()<CR>')
--(Russian)
vim.keymap.set('n', '<leader>у', ':lua MiniFiles.open()<CR>')


-- Search stuff
vim.pack.add({
    { src = 'https://github.com/nvim-mini/mini.pick' },
})

require('mini.pick').setup({
    options = {
        content_from_bottom = true,
        use_cache = true,
    },
})

vim.keymap.set('n', '<leader>/', ':Pick grep_live<CR>')
vim.keymap.set('n', '<leader>f', ':Pick files<CR>')
vim.keymap.set('n', '<leader>b', ':Pick buffers<CR>')
--(Russian)
vim.keymap.set('n', '<leader>а', ':Pick files<CR>')
vim.keymap.set('n', '<leader>и', ':Pick buffers<CR>')


-- LSP
vim.pack.add({
    { src = 'https://github.com/neovim/nvim-lspconfig' },
    { src = 'https://github.com/mason-org/mason.nvim' },
    { src = 'https://github.com/mason-org/mason-lspconfig.nvim' },
})

require('mason').setup()
local mason_lspconfig = require('mason-lspconfig')

local capabilities = vim.lsp.protocol.make_client_capabilities()

require('mason-lspconfig').setup({
    ensure_installed = {
        'lua_ls',
        'marksman',
        'html',
        'cssls',
        'tailwindcss',
        'ts_ls',
    },

    handlers = {
        function(server_name)
            require('lspconfig')[server_name].setup({
                capabilities = capabilities,
            })
        end,

        ['lua_ls'] = function()
            require('lspconfig').lua_ls.setup({
                capabilities = capabilities,
                settings = {
                    Lua = {
                        diagnostics = {
                            globals = { 'vim' },
                        },
                    },
                },
            })
        end,
    },
})

vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('UserLspConfig', {}),
    callback = function(ev)
        vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'
    end,
})

vim.keymap.set('n', 'gd', vim.lsp.buf.definition)
vim.keymap.set('n', 'gr', vim.lsp.buf.references)
vim.keymap.set('n', 'K', vim.lsp.buf.hover)
vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action)
vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename)
vim.keymap.set('n', '<leader>lf', vim.lsp.buf.format)
--(Russian)
vim.keymap.set('n', 'пв', vim.lsp.buf.definition)
vim.keymap.set('n', 'пк', vim.lsp.buf.references)
vim.keymap.set('n', 'Л', vim.lsp.buf.hover)
vim.keymap.set('n', '<leader>сф', vim.lsp.buf.code_action)
vim.keymap.set('n', '<leader>кт', vim.lsp.buf.rename)
vim.keymap.set('n', '<leader>да', vim.lsp.buf.format)


--Diagnostics
vim.diagnostic.config({
    virtual_text = true,
    virtual_lines = false,
    signs = true,
    underline = true,
    update_in_insert = false,
    severity_sort = true,
})

vim.keymap.set('n', '[d', vim.diagnostic.goto_prev)
vim.keymap.set('n', ']d', vim.diagnostic.goto_next)
vim.keymap.set('n', '<leader>d', vim.diagnostic.open_float)
--(Russian)
vim.keymap.set('n', 'хв', vim.diagnostic.goto_prev)
vim.keymap.set('n', 'ъв', vim.diagnostic.goto_next)
vim.keymap.set('n', '<leader>в', vim.diagnostic.open_float)


-- Git
vim.pack.add({
    { src = 'https://github.com/kdheepak/lazygit.nvim' },
})

vim.keymap.set('n', '<leader>g', ':LazyGit<CR>')
--(Russian)
vim.keymap.set('n', '<leader>п', ':LazyGit<CR>')


-- AI
vim.pack.add({
    { src = 'https://github.com/sourcegraph/amp.nvim' },
})
require('amp').setup({ auto_start = true, log_level = "info" })
