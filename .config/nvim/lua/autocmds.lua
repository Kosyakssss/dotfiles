vim.api.nvim_create_autocmd("FocusLost", {
    group = vim.api.nvim_create_augroup("autosave", {}),
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

vim.api.nvim_create_autocmd('TextYankPost', {
    group = vim.api.nvim_create_augroup('highlight_yank', {}),
    pattern = '*',
    callback = function()
        vim.highlight.on_yank({ higroup = 'IncSearch', timeout = 180 })
    end,
})

vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("theme_overrides", {}),
    callback = function() require("theme").apply() end,
})

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
    group = vim.api.nvim_create_augroup("trim_on_save", {}),
    callback = function(args) cleanup_buffer(args.buf) end,
})
