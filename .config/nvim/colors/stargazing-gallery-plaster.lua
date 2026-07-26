-- Stargazing Gallery Plaster for Neovim
-- Syntax and UI roles mirror the Stargazing Helix themes.

vim.cmd.highlight("clear")

if vim.fn.exists("syntax_on") == 1 then
    vim.cmd.syntax("reset")
end

vim.g.colors_name = "stargazing-gallery-plaster"

local p = {
    tx = "#111110",
    tx_2 = "#6B6A68",
    tx_3 = "#AEADA9",
    ui_3 = "#C4C3BF",
    ui_2 = "#CFCDC9",
    ui = "#DAD8D4",
    bg_2 = "#E6E4DF",
    bg = "#F1EFEA",
    ink = "#111110",
    paper = "#F1EFEA",

    re_400 = "#D14D41",
    re_600 = "#AF3029",
    or_400 = "#DA702C",
    or_600 = "#BC5215",
    ye_400 = "#D0A215",
    ye_600 = "#AD8301",
    gr_400 = "#879A39",
    gr_600 = "#66800B",
    cy_400 = "#3AA99F",
    cy_600 = "#24837B",
    bl_400 = "#4385BE",
    bl_600 = "#205EA6",
    pu_400 = "#8B7EC8",
    pu_600 = "#5E409D",
    ma_400 = "#CE5D97",
    ma_600 = "#A02F6F",
}

local light = vim.o.background == "light"

local c = light and {
    tx = p.tx,
    tx_2 = p.tx_2,
    tx_3 = p.tx_3,
    ui_3 = p.ui_3,
    ui_2 = p.ui_2,
    ui = p.ui,
    bg_2 = p.bg_2,
    bg = p.bg,
    re = p.re_600,
    or_ = p.or_600,
    ye = p.ye_600,
    gr = p.gr_600,
    cy = p.cy_600,
    bl = p.bl_600,
    pu = p.pu_600,
    ma = p.ma_600,
} or {
    tx = p.ui_3,
    tx_2 = "#81807D",
    tx_3 = "#545452",
    ui_3 = "#3E3E3C",
    ui_2 = "#333331",
    ui = "#282826",
    bg_2 = "#1C1C1B",
    bg = p.ink,
    re = p.re_400,
    or_ = p.or_400,
    ye = p.ye_400,
    gr = p.gr_400,
    cy = p.cy_400,
    bl = p.bl_400,
    pu = p.pu_400,
    ma = p.ma_400,
}

local function hl(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
end

local function link(group, target)
    hl(group, { link = target })
end

for i, color in ipairs({
    c.bg,
    c.re,
    c.gr,
    c.ye,
    c.bl,
    c.ma,
    c.cy,
    c.tx,
    c.tx_2,
    c.re,
    c.gr,
    c.ye,
    c.bl,
    c.ma,
    c.cy,
    light and p.ink or p.paper,
}) do
    vim.g["terminal_color_" .. (i - 1)] = color
end

-- Editor UI. These roles follow the Helix theme one for one where Neovim has
-- an equivalent group.
hl("Normal", { fg = c.tx, bg = c.bg })
hl("NormalNC", { fg = c.tx, bg = c.bg })
hl("NormalFloat", { fg = c.tx, bg = c.bg_2 })
hl("FloatBorder", { fg = c.tx, bg = c.bg_2 })
hl("FloatTitle", { fg = c.tx, bg = c.bg_2 })
hl("WinSeparator", { fg = c.tx, bg = c.bg })
hl("SignColumn", { fg = c.tx_3, bg = c.bg })
hl("FoldColumn", { fg = c.tx_3, bg = c.bg })
hl("LineNr", { fg = c.tx_3, bg = c.bg })
hl("CursorLine", { bg = c.bg_2 })
hl("CursorLineNr", { fg = c.tx, bg = c.bg_2 })
hl("Cursor", { fg = c.bg, bg = c.tx })
hl("lCursor", { fg = c.bg, bg = c.tx })
hl("CursorIM", { fg = c.bg, bg = c.or_ })
hl("Visual", { fg = c.tx, bg = c.ui_2 })
hl("VisualNOS", { fg = c.tx, bg = c.ui_2 })
hl("Search", { fg = c.bg, bg = c.ye })
hl("IncSearch", { fg = c.bg, bg = c.or_ })
hl("CurSearch", { fg = c.bg, bg = c.or_ })
hl("Substitute", { fg = c.bg, bg = c.ma })
hl("MatchParen", { fg = c.tx, bg = c.ui })
hl("ColorColumn", { bg = c.bg_2 })
hl("NonText", { fg = c.bg_2 })
hl("EndOfBuffer", { fg = c.bg })
hl("Whitespace", { fg = c.bg_2 })
hl("IndentGuide", { fg = c.ui_2 })
hl("SpecialKey", { fg = c.bg_2 })
hl("Directory", { fg = c.bl })
hl("Title", { fg = c.or_ })
hl("Question", { fg = c.bl })
hl("MoreMsg", { fg = c.ye })
hl("ModeMsg", { fg = c.tx })
hl("WarningMsg", { fg = c.or_ })
hl("ErrorMsg", { fg = c.re })

hl("StatusLine", { fg = c.tx, bg = c.bg_2 })
hl("StatusLineNC", { fg = c.tx_2, bg = c.bg_2 })
hl("StargazingModeNormal", { fg = c.bg, bg = c.bl })
hl("StargazingModeInsert", { fg = c.bg, bg = c.or_ })
hl("StargazingModeSelect", { fg = c.bg, bg = c.ma })
hl("TabLine", { fg = c.tx_2, bg = c.bg_2 })
hl("TabLineSel", { fg = c.ye, bg = c.bg_2 })
hl("TabLineFill", { bg = c.bg_2 })
hl("WinBar", { fg = c.tx, bg = c.bg })
hl("WinBarNC", { fg = c.tx_2, bg = c.bg })

-- Menus and completion.
hl("Pmenu", { fg = c.tx, bg = c.bg })
hl("PmenuSel", { fg = c.tx, bg = c.ui })
hl("PmenuKind", { fg = c.pu, bg = c.bg })
hl("PmenuKindSel", { fg = c.pu, bg = c.ui })
hl("PmenuExtra", { fg = c.tx_2, bg = c.bg })
hl("PmenuExtraSel", { fg = c.tx_2, bg = c.ui })
hl("PmenuMatch", { fg = c.or_, bg = c.bg })
hl("PmenuMatchSel", { fg = c.or_, bg = c.ui })
hl("PmenuSbar", { bg = c.bg_2 })
hl("PmenuThumb", { bg = c.tx_2 })

-- Vim syntax groups.
hl("Comment", { fg = c.tx_3 })
hl("Constant", { fg = c.pu })
hl("String", { fg = c.cy })
hl("Character", { fg = c.cy })
hl("Number", { fg = c.pu })
hl("Boolean", { fg = c.ye })
hl("Float", { fg = c.pu })
hl("Identifier", { fg = c.tx })
hl("Function", { fg = c.or_ })
hl("Statement", { fg = c.gr })
hl("Conditional", { fg = c.gr })
hl("Repeat", { fg = c.gr })
hl("Label", { fg = c.ma })
hl("Operator", { fg = c.tx_2 })
hl("Keyword", { fg = c.gr })
hl("Exception", { fg = c.re })
hl("PreProc", { fg = c.ye })
hl("Include", { fg = c.ye })
hl("Define", { fg = c.gr })
hl("Macro", { fg = c.or_ })
hl("PreCondit", { fg = c.gr })
hl("Type", { fg = c.ye })
hl("StorageClass", { fg = c.bl })
hl("Structure", { fg = c.ye })
hl("Typedef", { fg = c.ye })
hl("Special", { fg = c.ye })
hl("SpecialChar", { fg = c.ye })
hl("SpecialComment", { fg = c.tx_3 })
hl("Tag", { fg = c.bl })
hl("Delimiter", { fg = c.tx_2 })
hl("Debug", { fg = c.or_ })
hl("Underlined", { fg = c.bl })
hl("Ignore", { fg = c.tx_3 })
hl("Error", { fg = c.re })
hl("Todo", { fg = c.ma, bg = c.bg_2 })

-- Spell and diagnostics. Helix uses curls without diagnostic background fills.
hl("SpellBad", { sp = c.re, undercurl = true })
hl("SpellCap", { sp = c.ye, undercurl = true })
hl("SpellLocal", { sp = c.gr, undercurl = true })
hl("SpellRare", { sp = c.pu, undercurl = true })
hl("DiagnosticError", { fg = c.re })
hl("DiagnosticWarn", { fg = c.or_ })
hl("DiagnosticInfo", { fg = c.bl })
hl("DiagnosticHint", { fg = c.bl })
hl("DiagnosticOk", { fg = c.gr })
hl("DiagnosticVirtualTextError", { fg = c.re })
hl("DiagnosticVirtualTextWarn", { fg = c.or_ })
hl("DiagnosticVirtualTextInfo", { fg = c.bl })
hl("DiagnosticVirtualTextHint", { fg = c.bl })
hl("DiagnosticVirtualTextOk", { fg = c.gr })
hl("DiagnosticUnderlineError", { sp = c.re, undercurl = true })
hl("DiagnosticUnderlineWarn", { sp = c.ye, undercurl = true })
hl("DiagnosticUnderlineInfo", { sp = c.bl, undercurl = true })
hl("DiagnosticUnderlineHint", { sp = c.bl, undercurl = true })
hl("DiagnosticUnderlineOk", { sp = c.gr, undercurl = true })
hl("DiagnosticDeprecated", { strikethrough = true })
hl("DiagnosticUnnecessary", { fg = c.tx_3 })
hl("LspInlayHint", { fg = c.tx_3, bg = c.bg })
hl("LspReferenceText", { bg = c.bg_2 })
hl("LspReferenceRead", { bg = c.bg_2 })
hl("LspReferenceWrite", { bg = c.bg_2 })

-- Diffs.
hl("DiffAdd", { fg = c.gr })
hl("DiffChange", { fg = c.ye })
hl("DiffDelete", { fg = c.re })
hl("DiffText", { fg = c.ye, bg = c.bg_2 })
hl("Added", { fg = c.gr })
hl("Changed", { fg = c.ye })
hl("Removed", { fg = c.re })

-- Tree-sitter captures translated from the Helix scopes.
hl("@variable", { fg = c.tx })
hl("@variable.builtin", { fg = c.ma })
hl("@variable.parameter", { fg = c.tx })
hl("@variable.parameter.builtin", { fg = c.ma })
hl("@variable.member", { fg = c.bl })
hl("@constant", { fg = c.pu })
hl("@constant.builtin", { fg = c.ye })
hl("@constant.macro", { fg = c.pu })
hl("@module", { fg = c.re })
hl("@module.builtin", { fg = c.re })
hl("@label", { fg = c.ma })
hl("@string", { fg = c.cy })
hl("@string.documentation", { fg = c.cy })
hl("@string.regexp", { fg = c.or_ })
hl("@string.escape", { fg = c.ye })
hl("@string.special", { fg = c.ye })
hl("@string.special.symbol", { fg = c.ye })
hl("@string.special.url", { fg = c.bl })
hl("@character", { fg = c.cy })
hl("@character.special", { fg = c.ye })
hl("@boolean", { fg = c.ye })
hl("@number", { fg = c.pu })
hl("@number.float", { fg = c.pu })
hl("@type", { fg = c.ye })
hl("@type.builtin", { fg = c.ye })
hl("@type.definition", { fg = c.ye })
hl("@attribute", { fg = c.ye })
hl("@property", { fg = c.bl })
hl("@function", { fg = c.or_ })
hl("@function.builtin", { fg = c.or_ })
hl("@function.call", { fg = c.or_ })
hl("@function.macro", { fg = c.or_ })
hl("@function.method", { fg = c.or_ })
hl("@function.method.call", { fg = c.or_ })
hl("@constructor", { fg = c.gr })
hl("@operator", { fg = c.tx_2 })
hl("@keyword", { fg = c.gr })
hl("@keyword.coroutine", { fg = c.gr })
hl("@keyword.function", { fg = c.gr })
hl("@keyword.operator", { fg = c.tx_2 })
hl("@keyword.import", { fg = c.ye })
hl("@keyword.type", { fg = c.bl })
hl("@keyword.modifier", { fg = c.bl })
hl("@keyword.repeat", { fg = c.gr })
hl("@keyword.return", { fg = c.gr })
hl("@keyword.debug", { fg = c.re })
hl("@keyword.exception", { fg = c.re })
hl("@keyword.conditional", { fg = c.gr })
hl("@keyword.directive", { fg = c.gr })
hl("@keyword.directive.define", { fg = c.gr })
hl("@punctuation.delimiter", { fg = c.tx_2 })
hl("@punctuation.bracket", { fg = c.tx_2 })
hl("@punctuation.special", { fg = c.tx_2 })
hl("@comment", { fg = c.tx_3 })
hl("@comment.documentation", { fg = c.tx_3 })
hl("@comment.error", { fg = c.re })
hl("@comment.warning", { fg = c.or_ })
hl("@comment.todo", { fg = c.ma })
hl("@comment.note", { fg = c.bl })
hl("@markup.strong", { fg = c.or_ })
hl("@markup.italic", { fg = c.or_, italic = true })
hl("@markup.strikethrough", { strikethrough = true })
hl("@markup.underline", { fg = c.or_ })
hl("@markup.heading", { fg = c.or_ })
hl("@markup.heading.1", { fg = c.or_ })
hl("@markup.heading.2", { fg = c.or_ })
hl("@markup.heading.3", { fg = c.or_ })
hl("@markup.heading.4", { fg = c.or_ })
hl("@markup.heading.5", { fg = c.or_ })
hl("@markup.heading.6", { fg = c.or_ })
hl("@markup.quote", { fg = c.ye })
hl("@markup.math", { fg = c.pu })
hl("@markup.link", { fg = c.ye })
hl("@markup.link.label", { fg = c.gr })
hl("@markup.link.url", { fg = c.bl })
hl("@markup.raw", { fg = c.bl })
hl("@markup.raw.block", { fg = c.or_ })
hl("@markup.list", { fg = c.ye })
hl("@markup.list.checked", { fg = c.gr })
hl("@markup.list.unchecked", { fg = c.tx_3 })
hl("@diff.plus", { fg = c.gr })
hl("@diff.minus", { fg = c.re })
hl("@diff.delta", { fg = c.ye })
hl("@tag", { fg = c.bl })
hl("@tag.attribute", { fg = c.ye })
hl("@tag.delimiter", { fg = c.tx_2 })

link("@field", "@variable.member")
link("@parameter", "@variable.parameter")
link("@namespace", "@module")
link("@method", "@function.method")
link("@method.call", "@function.method.call")
link("@text", "Normal")
link("@text.strong", "@markup.strong")
link("@text.emphasis", "@markup.italic")
link("@text.strike", "@markup.strikethrough")
link("@text.underline", "@markup.underline")
link("@text.title", "@markup.heading")
link("@text.uri", "@markup.link.url")
link("@text.literal", "@markup.raw")
link("@text.reference", "@markup.link")
link("@text.todo", "@comment.todo")
link("@text.note", "@comment.note")
link("@text.warning", "@comment.warning")
link("@text.danger", "@comment.error")

-- Local plugins.
hl("BufferLineFill", { bg = c.bg_2 })
hl("BufferLineBackground", { fg = c.tx_2, bg = c.bg_2 })
hl("BufferLineBufferSelected", { fg = c.ye, bg = c.bg_2 })
hl("BufferLineSeparator", { fg = c.bg_2, bg = c.bg_2 })
hl("BufferLineSeparatorSelected", { fg = c.bg_2, bg = c.bg_2 })
hl("BufferLineModified", { fg = c.ye, bg = c.bg_2 })
hl("BufferLineModifiedSelected", { fg = c.ye, bg = c.bg_2 })
hl("BufferLineDiagnostic", { fg = c.tx_2, bg = c.bg_2 })
hl("BufferLineDiagnosticSelected", { fg = c.tx, bg = c.bg_2 })

hl("FzfLuaNormal", { fg = c.tx, bg = c.bg })
hl("FzfLuaBorder", { fg = c.tx, bg = c.bg })
hl("FzfLuaTitle", { fg = c.tx, bg = c.bg })
hl("FzfLuaCursor", { fg = c.tx, bg = c.ui })
hl("FzfLuaCursorLine", { fg = c.tx, bg = c.ui })
hl("FzfLuaSearch", { fg = c.bg, bg = c.ye })
hl("FzfLuaHeaderText", { fg = c.tx_2 })
hl("FzfLuaPath", { fg = c.bl })
hl("FzfLuaDirPart", { fg = c.tx_2 })
hl("FzfLuaFilePart", { fg = c.tx })
hl("FzfLuaBufName", { fg = c.bl })
hl("FzfLuaBufNr", { fg = c.tx_2 })

hl("BlinkCmpMenu", { fg = c.tx, bg = c.bg })
hl("BlinkCmpMenuBorder", { fg = c.tx, bg = c.bg })
hl("BlinkCmpMenuSelection", { fg = c.tx, bg = c.ui })
hl("BlinkCmpKind", { fg = c.tx_2, bg = c.bg })
hl("BlinkCmpDoc", { fg = c.tx, bg = c.bg_2 })
hl("BlinkCmpDocBorder", { fg = c.tx, bg = c.bg_2 })
hl("BlinkCmpSignatureHelp", { fg = c.tx, bg = c.bg_2 })
hl("BlinkCmpSignatureHelpBorder", { fg = c.tx, bg = c.bg_2 })

hl("WhichKey", { fg = c.bl })
hl("WhichKeyGroup", { fg = c.ma })
hl("WhichKeyDesc", { fg = c.tx })
hl("WhichKeySeparator", { fg = c.tx_2 })
hl("WhichKeyFloat", { bg = c.bg_2 })
hl("WhichKeyBorder", { fg = c.tx, bg = c.bg_2 })

-- Plugin setup can create its own emphasis after the colorscheme loads. Strip
-- it now, after startup, and when plugin windows initialize.
local function remove_bold()
    if not (vim.g.colors_name or ""):match("^stargazing%-") then return end
    for group, attrs in pairs(vim.api.nvim_get_hl(0, {})) do
        if attrs.bold then
            attrs.default = nil
            attrs.bold = false
            if attrs.cterm then attrs.cterm.bold = false end
            vim.api.nvim_set_hl(0, group, attrs)
        end
    end
end

local function schedule_remove_bold()
    vim.schedule(remove_bold)
end

local style_group = vim.api.nvim_create_augroup("stargazing_no_bold", { clear = true })
vim.api.nvim_create_autocmd("ColorScheme", {
    group = style_group,
    pattern = "stargazing-*",
    callback = schedule_remove_bold,
})
vim.api.nvim_create_autocmd({ "VimEnter", "UIEnter", "BufWinEnter", "FileType" }, {
    group = style_group,
    callback = schedule_remove_bold,
})
vim.schedule(remove_bold)
vim.defer_fn(remove_bold, 50)
vim.defer_fn(remove_bold, 250)
