vim.diagnostic.config({
    virtual_text = true,
    signs = true,
    underline = true,
    severity_sort = true,
})

vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('lsp_attach', {}),
    callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if client == nil then return end
        if client:supports_method('textDocument/completion') then
            vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = true })
        end
        if client:supports_method('textDocument/inlayHint') then
            vim.lsp.inlay_hint.enable(true, { bufnr = args.buf })
        end
    end,
})

vim.lsp.config('markdown_oxide', {
    cmd = { 'markdown-oxide' },
    filetypes = { 'markdown' },
    root_markers = { '.obsidian', '.moxide.toml', '.git' },
    capabilities = {
        workspace = {
            didChangeWatchedFiles = {
                dynamicRegistration = true,
            },
        },
    },
})
vim.lsp.config('typos', {
    cmd = { 'typos-lsp' },
    filetypes = { 'markdown', 'text', 'gitcommit' },
    root_markers = { '_typos.toml', '.obsidian', '.typos.toml', 'typos.toml', '.git' },
    init_options = { config = vim.fn.expand('~/.config/typos/typos.toml') },
})
vim.lsp.config('lua_ls', {
    cmd = { 'lua-language-server' },
    filetypes = { 'lua' },
    root_markers = { '.luarc.json', '.luarc.jsonc', '.git' },
    settings = {
        Lua = {
            runtime = { version = 'LuaJIT' },
            diagnostics = { globals = { 'vim' } },
            workspace = { library = { vim.env.VIMRUNTIME } },
        },
    },
})
vim.lsp.config('rust_analyzer', {
    cmd = { 'rust-analyzer' },
    filetypes = { 'rust' },
    root_markers = { 'Cargo.toml', 'Cargo.lock', '.git' },
})
vim.lsp.config('tinymist', {
    cmd = { 'tinymist' },
    filetypes = { 'typst' },
    root_markers = { '.git' },
})
vim.lsp.enable({ 'markdown_oxide', 'typos', 'lua_ls', 'rust_analyzer', 'tinymist' })

vim.api.nvim_create_autocmd("BufWritePre", {
    group = vim.api.nvim_create_augroup("lsp_format", {}),
    callback = function(args)
        for _, client in ipairs(vim.lsp.get_clients({ bufnr = args.buf })) do
            if client:supports_method("textDocument/formatting") then
                vim.lsp.buf.format({ bufnr = args.buf, async = false })
                break
            end
        end
    end,
})
