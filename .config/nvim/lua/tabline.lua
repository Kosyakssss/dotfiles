vim.cmd([[function! TablineGotoBuffer(minwid, clicks, button, modifiers) abort
  call v:lua._goto_buffer(a:minwid)
endfunction]])
vim.cmd([[function! TablineScrollLeft(minwid, clicks, button, modifiers) abort
  call v:lua._scroll_tabline(-5)
endfunction]])
vim.cmd([[function! TablineScrollRight(minwid, clicks, button, modifiers) abort
  call v:lua._scroll_tabline(5)
endfunction]])

function _G._goto_buffer(bufnr)
    if vim.api.nvim_buf_is_valid(bufnr) then
        vim.api.nvim_set_current_buf(bufnr)
    end
end

local first_visible = 1

function _G._scroll_tabline(step)
    first_visible = math.max(1, first_visible + step)
    vim.cmd("redrawtabline")
end

local function update_visibility()
    local count = #vim.fn.getbufinfo({ buflisted = 1 })
    vim.o.showtabline = count > 1 and 2 or 0
end

vim.api.nvim_create_autocmd({ "BufAdd", "BufDelete", "BufWipeout", "BufEnter", "TabEnter" }, {
    group = vim.api.nvim_create_augroup("tabline_visibility", {}),
    callback = function() vim.schedule(update_visibility) end,
})

function _G._tabline()
    local current = vim.api.nvim_get_current_buf()
    local infos = vim.fn.getbufinfo({ buflisted = 1 })
    if #infos < 2 then
        return ""
    end
    local width = vim.o.columns
    local labels = {}
    local widths = {}
    local current_index = 1
    for index, info in ipairs(infos) do
        local name = vim.fn.fnamemodify(info.name, ":t"):gsub("%%", "%%%%")
        if name == "" then
            name = "[No Name]"
        end
        if info.changed == 1 then
            name = name .. "[+]"
        end
        labels[index] = " " .. name .. " "
        widths[index] = vim.fn.strdisplaywidth(labels[index])
        if info.bufnr == current then
            current_index = index
        end
    end
    if first_visible > current_index then
        first_visible = current_index
    end
    local last = first_visible - 1
    while true do
        local used = 0
        if first_visible > 1 then
            used = 2
        end
        last = first_visible - 1
        for index = first_visible, #infos do
            local reserve = index < #infos and 2 or 0
            if used + widths[index] + reserve > width then
                break
            end
            used = used + widths[index]
            last = index
        end
        if last >= current_index or first_visible >= current_index then
            break
        end
        first_visible = first_visible + 1
    end
    if last < first_visible then
        last = first_visible
    end
    local parts = {}
    if first_visible > 1 then
        parts[#parts + 1] = "%@TablineScrollLeft@%#TabLine#< %*%X"
    end
    for index = first_visible, last do
        local hl = infos[index].bufnr == current and "%#TabLineSel#" or "%#TabLine#"
        parts[#parts + 1] = "%" .. infos[index].bufnr .. "@TablineGotoBuffer@" .. hl .. labels[index] .. "%*%X"
    end
    if last < #infos then
        parts[#parts + 1] = "%@TablineScrollRight@%#TabLine#> %*%X"
    end
    return table.concat(parts) .. "%#TabLineFill#"
end

vim.o.tabline = "%!v:lua._tabline()"
