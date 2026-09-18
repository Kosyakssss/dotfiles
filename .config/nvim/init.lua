vim.g.mapleader = " "

require("vim._core.ui2").enable()
vim.cmd("packadd nvim.undotree")

require("opts")
require("languages")
require("autocmds")
require("keymap")
require("fzf")
require("statusline")
require("tabline")

vim.cmd.colorscheme("catppuccin")
vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
