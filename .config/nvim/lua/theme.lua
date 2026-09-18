local M = {}

local flexoki = {
    dark = {
        bg2 = "#1C1B1A", ye = "#D0A215", gr = "#879A39",
        bl = "#4385BE", or_ = "#DA702C", ma = "#CE5D97",
        pu = "#8B7EC8", cy = "#3AA99F", re = "#D14D41",
    },
    light = {
        bg2 = "#F2F0E5", ye = "#AD8301", gr = "#66800B",
        bl = "#205EA6", or_ = "#BC5215", ma = "#A02F6F",
        pu = "#5E409D", cy = "#24837B", re = "#AF3029",
    },
}

local mode_colors = {
    NOR = "bl", INS = "or_", VIS = "ma", SEL = "ma",
    CMD = "pu", TER = "cy", REP = "re",
}

function M.apply()
    local palette = flexoki[vim.o.background] or flexoki.dark
    vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
    vim.api.nvim_set_hl(0, "StatusLine", { bg = "none" })
    vim.api.nvim_set_hl(0, "StatusLineNC", { bg = "none" })
    vim.api.nvim_set_hl(0, "TabLine", { bg = "none" })
    vim.api.nvim_set_hl(0, "TabLineFill", { bg = "none" })
    vim.api.nvim_set_hl(0, "TabLineSel", { bold = true, bg = palette.bg2, fg = palette.ye })
    for mode, key in pairs(mode_colors) do
        vim.api.nvim_set_hl(0, "StlMode" .. mode, { fg = palette[key], bold = true })
    end
    vim.api.nvim_set_hl(0, "StlVcsClean", { fg = palette.gr })
    vim.api.nvim_set_hl(0, "StlVcsDirty", { fg = palette.ye })
end

return M
