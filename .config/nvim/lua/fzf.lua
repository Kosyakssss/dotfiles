vim.pack.add({ 'https://github.com/ibhagwan/fzf-lua' })

require("fzf-lua").setup({
    defaults = { file_icons = false, git_icons = true },
    files = {
        hidden = true,
        fd_opts = "--type f --type l --follow --hidden --color=never",
    },
    grep = {
        rg_opts = "--column --line-number --no-heading --color=always --smart-case --follow --hidden",
    },
    keymap = {
        builtin = {
            true,
            ["<C-u>"] = "preview-half-page-up",
            ["<C-d>"] = "preview-half-page-down",
            ["<C-t>"] = "toggle-preview",
        },
    },
    actions = {
        files = {
            true,
            ["ctrl-t"] = false,
            ["ctrl-x"] = require("fzf-lua.actions").file_tabedit,
        },
    },
})
