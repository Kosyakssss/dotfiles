vim.g.mapleader = " "

-- Options
local o = vim.opt
o.number, o.relativenumber = true, true
o.signcolumn = "yes:1"
o.cursorline = true
o.scrolloff = 4
o.ignorecase, o.smartcase = true, true
o.expandtab, o.tabstop, o.shiftwidth, o.shiftround = true, 4, 4, true
o.linebreak, o.breakindent = true, true
o.list = true
o.listchars = { leadmultispace = "╎   ", tab = "  " }
o.clipboard = "unnamedplus"
o.swapfile = false
o.undofile = true
o.laststatus = 3
o.winborder = "bold"
o.mousescroll = "ver:1,hor:1"
o.autocomplete = true
o.completeopt = { "menu", "menuone", "noselect", "popup" }
o.statusline = " %f %m%=%l:%c  %L "

o.langmap = "ёйцукенгшщзхъфывапролджэячсмитьбю;`qwertyuiop[]asdfghjkl\\;'zxcvbnm\\,.,"
  .. "ЁЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЖЭЯЧСМИТЬБЮ;~QWERTYUIOP{}ASDFGHJKL:\\\"ZXCVBNM<>"

-- Built-ins
require("vim._core.ui2").enable()
vim.cmd.packadd("nvim.undotree")

-- Plugins (vim.pack, built in)
vim.pack.add({
  "https://github.com/kepano/flexoki-neovim",
  "https://github.com/ibhagwan/fzf-lua",
})
vim.cmd.colorscheme("flexoki")
require("fzf-lua").setup({
  defaults = { file_icons = false },
  files = { hidden = true },
})

-- Autocmds
local au = function(ev, fn) vim.api.nvim_create_autocmd(ev, { callback = fn }) end

au("TextYankPost", function() vim.hl.on_yank({ timeout = 180 }) end)

au("FocusLost", function() vim.cmd("silent! wall") end)

au("BufWritePre", function(a) -- trim trailing whitespace + trailing blank lines
  if vim.bo[a.buf].buftype ~= "" then return end
  local view = vim.fn.winsaveview()
  vim.cmd([[silent! keeppatterns %s/\s\+$//e]])
  vim.cmd([[silent! keeppatterns %s/\n\+\%$//e]])
  vim.fn.winrestview(view)
end)

-- Yazi as a file picker
local function yazi(dir)
  local tmp = vim.fn.tempname()
  vim.cmd.tabnew()
  local buf = vim.api.nvim_get_current_buf()
  vim.fn.jobstart({ "yazi", dir, "--chooser-file", tmp }, {
    term = true,
    on_exit = vim.schedule_wrap(function()
      vim.cmd.bdelete({ buf, bang = true })
      local f = io.open(tmp)
      if not f then return end
      local path = f:read("*l"); f:close(); os.remove(tmp)
      if path and path ~= "" then vim.cmd.edit(vim.fn.fnameescape(path)) end
    end),
  })
  vim.cmd.startinsert()
end
local function file_dir()
  local d = vim.fn.expand("%:p:h")
  return d ~= "" and d or vim.uv.cwd()
end

-- Keys
local map = vim.keymap.set
map("i", "jk", "<Esc>")
map("n", "<Esc>", "<cmd>noh<CR>")
map("n", "<leader>w", "<cmd>write<CR>")
map("n", "<leader>q", "<cmd>quit<CR>")
map("n", "<leader>f", "<cmd>FzfLua files<CR>")
map("n", "<leader>F", function() require("fzf-lua").files({ cwd = file_dir() }) end)
map("n", "<leader>/", "<cmd>FzfLua live_grep<CR>")
map("n", "<leader>b", "<cmd>FzfLua buffers<CR>")
map("n", "<leader>y", function() yazi(vim.uv.cwd()) end)
map("n", "<leader>.", function() yazi(file_dir()) end)
map("n", "<leader>u", "<cmd>Undotree<CR>")
map("n", "<Tab>", "<cmd>bnext<CR>")
map("n", "<S-Tab>", "<cmd>bprevious<CR>")
map("n", "<leader><Tab>", "<cmd>bdelete<CR>")
map({ "n", "v" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true })
map({ "n", "v" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true })
for _, k in ipairs({ "h", "j", "k", "l" }) do map("n", "<C-" .. k .. ">", "<C-w>" .. k) end
