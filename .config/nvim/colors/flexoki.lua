-- Flexoki for Neovim
-- https://stephango.com/flexoki

vim.cmd.highlight("clear")

if vim.fn.exists("syntax_on") == 1 then
    vim.cmd.syntax("reset")
end

vim.g.colors_name = "flexoki"

local p = {
    black = "#100F0F",
    paper = "#FFFCF0",

    base_50 = "#F2F0E5",
    base_100 = "#E6E4D9",
    base_150 = "#DAD8CE",
    base_200 = "#CECDC3",
    base_300 = "#B7B5AC",
    base_400 = "#9F9D96",
    base_500 = "#878580",
    base_600 = "#6F6E69",
    base_700 = "#575653",
    base_800 = "#403E3C",
    base_850 = "#343331",
    base_900 = "#282726",
    base_950 = "#1C1B1A",

    red_400 = "#D14D41",
    red_600 = "#AF3029",
    orange_400 = "#DA702C",
    orange_600 = "#BC5215",
    yellow_400 = "#D0A215",
    yellow_600 = "#AD8301",
    green_400 = "#879A39",
    green_600 = "#66800B",
    cyan_400 = "#3AA99F",
    cyan_600 = "#24837B",
    blue_400 = "#4385BE",
    blue_600 = "#205EA6",
    purple_400 = "#8B7EC8",
    purple_600 = "#5E409D",
    magenta_400 = "#CE5D97",
    magenta_600 = "#A02F6F",

    red_50 = "#FFE1D5",
    red_950 = "#261312",
    orange_50 = "#FFE7CE",
    orange_950 = "#27180E",
    yellow_50 = "#FAEEC6",
    yellow_950 = "#241E08",
    green_50 = "#EDEECF",
    green_950 = "#1A1E0C",
    cyan_50 = "#DDF1E4",
    cyan_950 = "#101F1D",
    blue_50 = "#E1ECEB",
    blue_950 = "#101A24",
    purple_50 = "#F0EAEC",
    purple_950 = "#1A1623",
    magenta_50 = "#FEE4E5",
    magenta_950 = "#24131D",
}

local light = vim.o.background == "light"

local c = light and {
    bg = p.paper,
    bg_alt = p.base_50,
    bg_float = p.base_50,
    bg_line = p.base_50,
    ui = p.base_100,
    ui_2 = p.base_150,
    ui_3 = p.base_200,
    fg = p.black,
    fg_dim = p.base_600,
    fg_muted = p.base_500,
    border = p.base_150,
    selection = p.base_200,
    selection_fg = p.black,
    cursor = p.black,
    red = p.red_600,
    orange = p.orange_600,
    yellow = p.yellow_600,
    green = p.green_600,
    cyan = p.cyan_600,
    blue = p.blue_600,
    purple = p.purple_600,
    magenta = p.magenta_600,
    red_soft = p.red_50,
    orange_soft = p.orange_50,
    yellow_soft = p.yellow_50,
    green_soft = p.green_50,
    cyan_soft = p.cyan_50,
    blue_soft = p.blue_50,
    purple_soft = p.purple_50,
    magenta_soft = p.magenta_50,
    terminal_black = p.black,
    terminal_white = p.paper,
} or {
    bg = p.black,
    bg_alt = p.base_950,
    bg_float = p.base_950,
    bg_line = p.base_950,
    ui = p.base_900,
    ui_2 = p.base_850,
    ui_3 = p.base_800,
    fg = p.base_200,
    fg_dim = p.base_500,
    fg_muted = p.base_600,
    border = p.base_850,
    selection = p.base_800,
    selection_fg = p.base_200,
    cursor = p.base_200,
    red = p.red_400,
    orange = p.orange_400,
    yellow = p.yellow_400,
    green = p.green_400,
    cyan = p.cyan_400,
    blue = p.blue_400,
    purple = p.purple_400,
    magenta = p.magenta_400,
    red_soft = p.red_950,
    orange_soft = p.orange_950,
    yellow_soft = p.yellow_950,
    green_soft = p.green_950,
    cyan_soft = p.cyan_950,
    blue_soft = p.blue_950,
    purple_soft = p.purple_950,
    magenta_soft = p.magenta_950,
    terminal_black = p.black,
    terminal_white = p.base_200,
}

local function hl(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
end

local function link(group, target)
    hl(group, { link = target })
end

for i, color in ipairs({
    c.terminal_black,
    c.red,
    c.green,
    c.yellow,
    c.blue,
    c.magenta,
    c.cyan,
    c.terminal_white,
    c.fg_muted,
    c.red,
    c.green,
    c.yellow,
    c.blue,
    c.magenta,
    c.cyan,
    light and p.black or p.paper,
}) do
    vim.g["terminal_color_" .. (i - 1)] = color
end

-- Editor UI
hl("Normal", { fg = c.fg, bg = c.bg })
hl("NormalNC", { fg = c.fg_dim, bg = c.bg })
hl("NormalFloat", { fg = c.fg, bg = c.bg_float })
hl("FloatBorder", { fg = c.border, bg = c.bg_float })
hl("FloatTitle", { fg = c.fg, bg = c.bg_float, bold = true })
hl("WinSeparator", { fg = c.border, bg = c.bg })
hl("SignColumn", { fg = c.fg_muted, bg = c.bg })
hl("FoldColumn", { fg = c.fg_muted, bg = c.bg })
hl("LineNr", { fg = c.ui_3, bg = c.bg })
hl("CursorLine", { bg = c.bg_line })
hl("CursorLineNr", { fg = c.fg, bg = c.bg_line, bold = true })
hl("Cursor", { fg = c.bg, bg = c.cursor })
hl("lCursor", { fg = c.bg, bg = c.cursor })
hl("Visual", { fg = c.selection_fg, bg = c.selection })
hl("VisualNOS", { fg = c.selection_fg, bg = c.selection })
hl("Search", { fg = p.black, bg = c.yellow })
hl("IncSearch", { fg = p.black, bg = light and p.yellow_400 or p.yellow_600, bold = true })
hl("CurSearch", { fg = p.black, bg = light and p.yellow_400 or p.yellow_600, bold = true })
hl("Substitute", { fg = p.black, bg = c.green, bold = true })
hl("MatchParen", { fg = c.blue, bg = c.ui, bold = true })
hl("ColorColumn", { bg = c.bg_alt })
hl("NonText", { fg = c.fg_muted })
hl("EndOfBuffer", { fg = c.bg })
hl("Whitespace", { fg = c.ui_3 })
hl("SpecialKey", { fg = c.fg_muted })
hl("Directory", { fg = c.blue })
hl("Title", { fg = c.fg, bold = true })
hl("Question", { fg = c.blue })
hl("MoreMsg", { fg = c.green })
hl("ModeMsg", { fg = c.fg_dim })
hl("WarningMsg", { fg = c.orange })
hl("ErrorMsg", { fg = c.red })

hl("StatusLine", { fg = c.fg, bg = c.bg_alt })
hl("StatusLineNC", { fg = c.fg_muted, bg = c.bg_alt })
hl("TabLine", { fg = c.fg_muted, bg = c.bg_alt })
hl("TabLineSel", { fg = c.fg, bg = c.bg, bold = true })
hl("TabLineFill", { bg = c.bg_alt })
hl("WinBar", { fg = c.fg, bg = c.bg })
hl("WinBarNC", { fg = c.fg_muted, bg = c.bg })

-- Menus and completion
hl("Pmenu", { fg = c.fg, bg = c.bg_float })
hl("PmenuSel", { fg = c.selection_fg, bg = c.selection })
hl("PmenuKind", { fg = c.purple, bg = c.bg_float })
hl("PmenuKindSel", { fg = c.purple, bg = c.selection })
hl("PmenuExtra", { fg = c.fg_muted, bg = c.bg_float })
hl("PmenuExtraSel", { fg = c.fg_muted, bg = c.selection })
hl("PmenuMatch", { fg = c.orange, bg = c.bg_float, bold = true })
hl("PmenuMatchSel", { fg = c.orange, bg = c.selection, bold = true })
hl("PmenuSbar", { bg = c.ui })
hl("PmenuThumb", { bg = c.fg_muted })

-- Vim syntax groups
hl("Comment", { fg = c.fg_muted, italic = true })
hl("Constant", { fg = c.yellow })
hl("String", { fg = c.cyan })
hl("Character", { fg = c.cyan })
hl("Number", { fg = c.purple })
hl("Boolean", { fg = c.yellow })
hl("Float", { fg = c.purple })
hl("Identifier", { fg = c.fg })
hl("Function", { fg = c.orange, bold = true })
hl("Statement", { fg = c.green })
hl("Conditional", { fg = c.green })
hl("Repeat", { fg = c.green })
hl("Label", { fg = c.magenta })
hl("Operator", { fg = c.red })
hl("Keyword", { fg = c.green })
hl("Exception", { fg = c.green })
hl("PreProc", { fg = c.magenta })
hl("Include", { fg = c.red })
hl("Define", { fg = c.magenta })
hl("Macro", { fg = c.blue })
hl("PreCondit", { fg = c.magenta })
hl("Type", { fg = c.yellow })
hl("StorageClass", { fg = c.blue })
hl("Structure", { fg = c.orange })
hl("Typedef", { fg = c.orange })
hl("Special", { fg = c.fg_dim })
hl("SpecialChar", { fg = c.magenta })
hl("SpecialComment", { fg = c.fg_dim, italic = true })
hl("Tag", { fg = c.blue })
hl("Delimiter", { fg = c.fg_dim })
hl("Debug", { fg = c.magenta })
hl("Underlined", { fg = c.blue, underline = true })
hl("Ignore", { fg = c.fg_muted })
hl("Error", { fg = c.red, bold = true })
hl("Todo", { fg = c.magenta, bg = c.bg_alt, bold = true })

-- Spell and diagnostics
hl("SpellBad", { sp = c.red, undercurl = true })
hl("SpellCap", { sp = c.yellow, undercurl = true })
hl("SpellLocal", { sp = c.green, undercurl = true })
hl("SpellRare", { sp = c.purple, undercurl = true })

hl("DiagnosticError", { fg = c.red })
hl("DiagnosticWarn", { fg = c.orange })
hl("DiagnosticInfo", { fg = c.blue })
hl("DiagnosticHint", { fg = c.cyan })
hl("DiagnosticOk", { fg = c.green })
hl("DiagnosticVirtualTextError", { fg = c.red, bg = c.red_soft })
hl("DiagnosticVirtualTextWarn", { fg = c.orange, bg = c.orange_soft })
hl("DiagnosticVirtualTextInfo", { fg = c.blue, bg = c.blue_soft })
hl("DiagnosticVirtualTextHint", { fg = c.cyan, bg = c.cyan_soft })
hl("DiagnosticVirtualTextOk", { fg = c.green, bg = c.green_soft })
hl("DiagnosticUnderlineError", { sp = c.red, undercurl = true })
hl("DiagnosticUnderlineWarn", { sp = c.orange, undercurl = true })
hl("DiagnosticUnderlineInfo", { sp = c.blue, undercurl = true })
hl("DiagnosticUnderlineHint", { sp = c.cyan, undercurl = true })
hl("DiagnosticUnderlineOk", { sp = c.green, undercurl = true })
hl("LspInlayHint", { fg = c.fg_muted, bg = c.bg_alt })
hl("LspReferenceText", { bg = c.ui })
hl("LspReferenceRead", { bg = c.ui })
hl("LspReferenceWrite", { bg = c.ui })

-- Diff and git signs
hl("DiffAdd", { fg = c.green, bg = c.green_soft })
hl("DiffChange", { fg = c.orange, bg = c.orange_soft })
hl("DiffDelete", { fg = c.red, bg = c.red_soft })
hl("DiffText", { fg = c.blue, bg = c.blue_soft, bold = true })
hl("Added", { fg = c.green })
hl("Changed", { fg = c.orange })
hl("Removed", { fg = c.red })

-- Treesitter captures: current Neovim names plus compatibility aliases.
hl("@variable", { fg = c.fg })
hl("@variable.builtin", { fg = c.magenta })
hl("@variable.parameter", { fg = c.fg })
hl("@variable.parameter.builtin", { fg = c.magenta })
hl("@variable.member", { fg = c.blue })
hl("@constant", { fg = c.fg })
hl("@constant.builtin", { fg = c.yellow })
hl("@constant.macro", { fg = c.blue })
hl("@module", { fg = c.red })
hl("@module.builtin", { fg = c.magenta })
hl("@label", { fg = c.magenta })
hl("@string", { fg = c.cyan })
hl("@string.documentation", { fg = c.cyan })
hl("@string.regexp", { fg = c.magenta })
hl("@string.escape", { fg = c.fg_dim })
hl("@string.special", { fg = c.magenta })
hl("@string.special.symbol", { fg = c.yellow })
hl("@string.special.url", { fg = c.blue, underline = true })
hl("@character", { fg = c.cyan })
hl("@character.special", { fg = c.magenta })
hl("@boolean", { fg = c.yellow })
hl("@number", { fg = c.purple })
hl("@number.float", { fg = c.purple })
hl("@type", { fg = c.yellow })
hl("@type.builtin", { fg = c.yellow })
hl("@type.definition", { fg = c.orange })
hl("@attribute", { fg = c.yellow })
hl("@property", { fg = c.blue })
hl("@function", { fg = c.orange, bold = true })
hl("@function.builtin", { fg = c.orange })
hl("@function.call", { fg = c.orange })
hl("@function.macro", { fg = c.blue })
hl("@function.method", { fg = c.green })
hl("@function.method.call", { fg = c.green })
hl("@constructor", { fg = c.orange })
hl("@operator", { fg = c.red })
hl("@keyword", { fg = c.green })
hl("@keyword.coroutine", { fg = c.green })
hl("@keyword.function", { fg = c.green })
hl("@keyword.operator", { fg = c.red })
hl("@keyword.import", { fg = c.red })
hl("@keyword.type", { fg = c.blue })
hl("@keyword.modifier", { fg = c.blue })
hl("@keyword.repeat", { fg = c.green })
hl("@keyword.return", { fg = c.green })
hl("@keyword.debug", { fg = c.magenta })
hl("@keyword.exception", { fg = c.green })
hl("@keyword.conditional", { fg = c.green })
hl("@keyword.directive", { fg = c.magenta })
hl("@keyword.directive.define", { fg = c.magenta })
hl("@punctuation.delimiter", { fg = c.fg_dim })
hl("@punctuation.bracket", { fg = c.fg_dim })
hl("@punctuation.special", { fg = c.fg_dim })
hl("@comment", { fg = c.fg_muted, italic = true })
hl("@comment.documentation", { fg = light and c.ui_3 or c.fg_muted, italic = true })
hl("@comment.error", { fg = c.red, bold = true })
hl("@comment.warning", { fg = c.orange, bold = true })
hl("@comment.todo", { fg = c.magenta, bold = true })
hl("@comment.note", { fg = c.blue, bold = true })
hl("@markup.strong", { bold = true })
hl("@markup.italic", { italic = true })
hl("@markup.strikethrough", { strikethrough = true })
hl("@markup.underline", { underline = true })
hl("@markup.heading", { fg = c.orange, bold = true })
hl("@markup.heading.1", { fg = c.red, bold = true })
hl("@markup.heading.2", { fg = c.orange, bold = true })
hl("@markup.heading.3", { fg = c.yellow, bold = true })
hl("@markup.heading.4", { fg = c.green, bold = true })
hl("@markup.heading.5", { fg = c.blue, bold = true })
hl("@markup.heading.6", { fg = c.purple, bold = true })
hl("@markup.quote", { fg = c.fg_dim, italic = true })
hl("@markup.math", { fg = c.purple })
hl("@markup.link", { fg = c.blue })
hl("@markup.link.label", { fg = c.green })
hl("@markup.link.url", { fg = c.blue, underline = true })
hl("@markup.raw", { fg = c.cyan })
hl("@markup.list", { fg = c.magenta })
hl("@markup.list.checked", { fg = c.green })
hl("@markup.list.unchecked", { fg = c.fg_muted })
hl("@diff.plus", { fg = c.green })
hl("@diff.minus", { fg = c.red })
hl("@diff.delta", { fg = c.orange })
hl("@tag", { fg = c.blue })
hl("@tag.attribute", { fg = c.yellow })
hl("@tag.delimiter", { fg = c.fg_dim })

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

-- Local plugins
hl("BufferLineFill", { bg = c.bg_alt })
hl("BufferLineBackground", { fg = c.fg_muted, bg = c.bg_alt })
hl("BufferLineBufferSelected", { fg = c.fg, bg = c.bg, bold = true })
hl("BufferLineSeparator", { fg = c.bg_alt, bg = c.bg_alt })
hl("BufferLineSeparatorSelected", { fg = c.bg, bg = c.bg })
hl("BufferLineModified", { fg = c.yellow, bg = c.bg_alt })
hl("BufferLineModifiedSelected", { fg = c.yellow, bg = c.bg })
hl("BufferLineDiagnostic", { fg = c.fg_muted, bg = c.bg_alt })
hl("BufferLineDiagnosticSelected", { fg = c.fg, bg = c.bg })

hl("FzfLuaNormal", { fg = c.fg, bg = c.bg_float })
hl("FzfLuaBorder", { fg = c.border, bg = c.bg_float })
hl("FzfLuaTitle", { fg = c.fg, bg = c.bg_float, bold = true })
hl("FzfLuaCursor", { fg = c.selection_fg, bg = c.selection })
hl("FzfLuaCursorLine", { bg = c.bg_line })
hl("FzfLuaSearch", { fg = p.black, bg = c.yellow })
hl("FzfLuaHeaderText", { fg = c.fg_muted })
hl("FzfLuaPath", { fg = c.cyan })
hl("FzfLuaDirPart", { fg = c.fg_muted })
hl("FzfLuaFilePart", { fg = c.fg })
hl("FzfLuaBufName", { fg = c.blue })
hl("FzfLuaBufNr", { fg = c.fg_muted })

hl("WhichKey", { fg = c.blue })
hl("WhichKeyGroup", { fg = c.magenta })
hl("WhichKeyDesc", { fg = c.fg })
hl("WhichKeySeparator", { fg = c.fg_muted })
hl("WhichKeyFloat", { bg = c.bg_float })
hl("WhichKeyBorder", { fg = c.border, bg = c.bg_float })
