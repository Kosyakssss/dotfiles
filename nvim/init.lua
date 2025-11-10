--General settings

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = 'yes:1'
vim.opt.scrolloff = 8
vim.opt.wrap = true
vim.opt.linebreak = true
vim.opt.breakindent = true
vim.opt.showbreak = '↪ '
vim.opt.cursorline = true

vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.smarttab = true

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv('HOME') .. '/.config/nvim/undodir'
vim.opt.undofile = true
vim.opt.clipboard = 'unnamed'

vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.winborder = 'rounded'
vim.opt.pumborder = 'rounded'
vim.opt.termguicolors = true

vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlights text when yanking',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

vim.api.nvim_create_autocmd('BufEnter', {
  pattern = vim.fn.expand('~') .. '/dotfiles/nvim/init.lua',
  callback = function()
    vim.diagnostic.enable(false)
  end,
})

vim.cmd(
  "set langmap=ФИСВУАПРШОЛДЬТЩЗЙКЫЕГМЦЧНЯЖ;ABCDEFGHIJKLMNOPQRSTUVWXYZ:,фисвуапршолдьтщзйкыегмцчня;abcdefghijklmnopqrstuvwxyz")

--Plugins

vim.pack.add({
  { src = 'https://github.com/mason-org/mason.nvim' },
  { src = 'https://github.com/mason-org/mason-lspconfig.nvim' },
  { src = 'https://github.com/kdheepak/lazygit.nvim' },
  { src = 'https://github.com/catppuccin/nvim' },
  { src = 'https://github.com/kepano/flexoki-neovim' },
  { src = 'https://github.com/nvim-lua/plenary.nvim' },
  { src = 'https://github.com/MunifTanjim/nui.nvim' },
  { src = 'https://github.com/nvim-tree/nvim-web-devicons' },
  { src = 'https://github.com/nvim-mini/mini.pick' },
  { src = 'https://github.com/nvim-mini/mini.pairs' },
  { src = 'https://github.com/nvim-mini/mini.surround' },
  { src = 'https://github.com/nvim-mini/mini.completion' },
  { src = 'https://github.com/nvim-mini/mini.comment' },
  { src = 'https://github.com/nvim-mini/mini.statusline' },
  { src = 'https://github.com/nvim-mini/mini.starter' },
  { src = 'https://github.com/nvim-mini/mini.files' },
  { src = 'https://github.com/nvim-neo-tree/neo-tree.nvim' },
})

require('catppuccin').setup({
  flavour = 'auto',
  background = {
    light = 'latte',
    dark = 'mocha',
  },
})
vim.cmd.colorscheme 'flexoki'

require('mason').setup()
require('mini.pick').setup({
  options = {
    content_from_bottom = true,
    use_cache = true,
  },
})
require('mini.pairs').setup()
require('mini.surround').setup()
require('mini.completion').setup()
require('mini.comment').setup()
require('mini.statusline').setup()
require('mini.files').setup()

local starter = require('mini.starter')

starter.setup({
  items = {
    starter.sections.recent_files(5, true, false),
  },
  footer = '',
})

--LSP

require('mason-lspconfig').setup({
  ensure_installed = {
    'lua_ls',
    'marksman',
    'tsgo',
    'cssls',
    'html',
    'tailwindcss',
  }
})

vim.lsp.config('lua_ls', {
  cmd = { 'lua-language-server' },
  filetypes = { 'lua' },
  root_markers = { 'init.lua', '.luarc.json', '.git' },
})

vim.lsp.config('marksman', {
  cmd = { 'marksman' },
  filetypes = { 'md', 'markdown' },
  root_markers = {},
  fallback = true,
})

vim.lsp.config('tsgo', {
  cmd = { 'tsgo', 'lsp', '--stdio' },
  filetypes = { 'typescript', 'typescriptreact', 'javascript', 'javascriptreact' },
  root_markers = { 'package.json', 'tsconfig.json', 'jsconfig.json', '.git' },
})

vim.lsp.config('html', {
  cmd = { 'html-lsp', '--stdio' },
  filetypes = { 'html' },
  root_markers = { 'package.json', '.git' },
  fallback = true,
})

vim.lsp.config('cssls', {
  cmd = { 'css-lsp', '--stdio' },
  filetypes = { 'css', 'scss', 'less' },
  root_markers = { 'package.json', '.git' },
  fallback = true,
})

vim.lsp.config('tailwindcss', {
  cmd = { 'tailwindcss-language-server', '--stdio' },
  filetypes = { 'html', 'css', 'javascript', 'typescript', 'javascriptreact', 'typescriptreact' },
  root_markers = { 'tailwind.config.js', 'tailwind.config.ts', 'tailwind.config.mjs', 'package.json', '.git' },
})

--Diagnostics

vim.diagnostic.config({
  virtual_text = true,
  virtual_lines = false,
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
})

--Keymap

vim.g.mapleader = ' '
vim.keymap.set('i', 'jk', '<Esc>')
vim.keymap.set('n', '<Esc><Esc>', ':noh<CR>')
vim.keymap.set('n', '<leader>w', ':write<CR>')
vim.keymap.set('n', '<leader>q', ':quit<CR>')
vim.keymap.set('n', '<leader>e', ':lua MiniFiles.open()<CR>')
-- vim.keymap.set('n', '<leader>e', ':Neotree toggle<CR>')
vim.keymap.set('n', '<leader>f', ':Pick files<CR>')
vim.keymap.set('n', '<leader>/', ':Pick grep_live<CR>')
vim.keymap.set('n', '<leader>b', ':Pick buffers<CR>')
vim.keymap.set('n', '<leader>g', ':LazyGit<CR>')

--LSP keymap

vim.keymap.set('n', 'gd', vim.lsp.buf.definition)
vim.keymap.set('n', 'gr', vim.lsp.buf.references)
vim.keymap.set('n', 'K', vim.lsp.buf.hover)
vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action)
vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename)
vim.keymap.set('n', '<leader>lf', vim.lsp.buf.format)

--Diagnostics keymap

vim.keymap.set('n', '[d', vim.diagnostic.goto_prev)
vim.keymap.set('n', ']d', vim.diagnostic.goto_next)
vim.keymap.set('n', '<leader>d', vim.diagnostic.open_float)

--Keymap (Russian)

vim.keymap.set('n', '<leader>ц', ':write<CR>')
vim.keymap.set('n', '<leader>й', ':quit<CR>')
vim.keymap.set('n', '<leader>у', ':lua MiniFiles.open()<CR>')
-- vim.keymap.set('n', '<leader>у', ':Neotree toggle<CR>')
vim.keymap.set('n', '<leader>а', ':Pick files<CR>')
vim.keymap.set('n', '<leader>и', ':Pick buffers<CR>')
vim.keymap.set('n', '<leader>п', ':LazyGit<CR>')

--LSP keymap (Russian)
vim.keymap.set('n', 'пв', vim.lsp.buf.definition)
vim.keymap.set('n', 'пк', vim.lsp.buf.references)
vim.keymap.set('n', 'Л', vim.lsp.buf.hover)
vim.keymap.set('n', '<leader>сф', vim.lsp.buf.code_action)
vim.keymap.set('n', '<leader>кт', vim.lsp.buf.rename)
vim.keymap.set('n', '<leader>да', vim.lsp.buf.format)

--Diagnostics keymap (Russian)
vim.keymap.set('n', 'хв', vim.diagnostic.goto_prev)
vim.keymap.set('n', 'ъв', vim.diagnostic.goto_next)
vim.keymap.set('n', '<leader>в', vim.diagnostic.open_float)
