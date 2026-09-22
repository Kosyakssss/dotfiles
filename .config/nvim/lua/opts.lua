vim.opt.signcolumn = "yes:1"
vim.opt.termguicolors = true
vim.opt.ignorecase = true
vim.opt.swapfile = false
vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.shiftround = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.list = true
vim.opt.listchars = { leadmultispace = "╎   ", tab = "  " }
vim.opt.linebreak = true
vim.opt.breakindent = true
vim.opt.cursorline = true
vim.opt.scrolloff = 4
vim.opt.mousescroll = "ver:1,hor:1"
vim.opt.winborder = "bold"
vim.opt.clipboard = 'unnamedplus'
vim.opt.completeopt = { "menu", "menuone", "noselect", "popup" }
vim.opt.laststatus = 3
vim.opt.showtabline = 0

local undo_dir = vim.fn.stdpath("state") .. "/undo"
vim.opt.undofile = true
vim.opt.undodir = undo_dir
vim.fn.mkdir(undo_dir, "p")
