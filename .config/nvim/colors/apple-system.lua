vim.cmd.highlight("clear")

if vim.fn.exists("syntax_on") == 1 then
    vim.cmd.syntax("reset")
end

vim.g.colors_name = "apple-system"

local light = vim.o.background == "light"

local c = light and {
    bg = "#ffffff",
    bg_alt = "#f0f0f0",
    bg_float = "#f7f7f7",
    bg_line = "#f3f6fa",
    fg = "#454545",
    fg_dim = "#606060",
    fg_muted = "#808080",
    border = "#d6d6d6",
    selection = "#b3d7ff",
    selection_fg = "#1f1f1f",
    cursor = "#98989d",
    black = "#1a1a1a",
    red = "#d12f1b",
    green = "#008000",
    yellow = "#b57614",
    blue = "#007acc",
    purple = "#af00db",
    cyan = "#267f99",
    white = "#ffffff",
    bright_black = "#767676",
    bright_red = "#cd3131",
    bright_green = "#098658",
    bright_yellow = "#b57614",
    bright_blue = "#0000ff",
    bright_purple = "#795e26",
    bright_cyan = "#267f99",
    bright_white = "#ffffff",
    string = "#a31515",
    string_escape = "#ee0000",
    number = "#098658",
    comment = "#008000",
    keyword = "#0000ff",
    control = "#af00db",
    fn = "#795e26",
    type = "#267f99",
    variable = "#001080",
    property = "#001080",
    constant = "#0000ff",
} or {
    bg = "#1e1e1e",
    bg_alt = "#252526",
    bg_float = "#252526",
    bg_line = "#282828",
    fg = "#d4d4d4",
    fg_dim = "#c6c6c6",
    fg_muted = "#8c8c8c",
    border = "#3a3a3a",
    selection = "#264f78",
    selection_fg = "#ffffff",
    cursor = "#98989d",
    black = "#1a1a1a",
    red = "#f14c4c",
    green = "#6a9955",
    yellow = "#d7ba7d",
    blue = "#007acc",
    purple = "#c586c0",
    cyan = "#4ec9b0",
    white = "#d4d4d4",
    bright_black = "#858585",
    bright_red = "#f14c4c",
    bright_green = "#6a9955",
    bright_yellow = "#cca700",
    bright_blue = "#569cd6",
    bright_purple = "#c586c0",
    bright_cyan = "#4ec9b0",
    bright_white = "#ffffff",
    string = "#ce9178",
    string_escape = "#d7ba7d",
    number = "#b5cea8",
    comment = "#6a9955",
    keyword = "#569cd6",
    control = "#c586c0",
    fn = "#dcdcaa",
    type = "#4ec9b0",
    variable = "#9cdcfe",
    property = "#9cdcfe",
    constant = "#4fc1ff",
}

local function hl(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
end

for i, color in ipairs({
    c.black,
    c.red,
    c.green,
    c.yellow,
    c.blue,
    c.purple,
    c.cyan,
    c.white,
    c.bright_black,
    c.bright_red,
    c.bright_green,
    c.bright_yellow,
    c.bright_blue,
    c.bright_purple,
    c.bright_cyan,
    c.bright_white,
}) do
    vim.g["terminal_color_" .. (i - 1)] = color
end

hl("Normal", { fg = c.fg, bg = c.bg })
hl("NormalNC", { fg = c.fg_dim, bg = c.bg })
hl("NormalFloat", { fg = c.fg, bg = c.bg_float })
hl("FloatBorder", { fg = c.border, bg = c.bg_float })
hl("FloatTitle", { fg = c.fg, bg = c.bg_float, bold = true })
hl("WinSeparator", { fg = c.border, bg = c.bg })
hl("SignColumn", { fg = c.fg_muted, bg = c.bg })
hl("FoldColumn", { fg = c.fg_muted, bg = c.bg })
hl("LineNr", { fg = light and "#b0b0b0" or "#858585", bg = c.bg })
hl("CursorLine", { bg = c.bg_line })
hl("CursorLineNr", { fg = c.blue, bg = c.bg_line, bold = true })
hl("Cursor", { fg = c.bg, bg = c.cursor })
hl("lCursor", { fg = c.bg, bg = c.cursor })
hl("Visual", { fg = c.selection_fg, bg = c.selection })
hl("Search", { fg = c.black, bg = light and "#ffea9e" or "#613214" })
hl("IncSearch", { fg = c.black, bg = "#ffcc00", bold = true })
hl("CurSearch", { fg = c.black, bg = "#ffcc00", bold = true })
hl("MatchParen", { fg = c.bright_blue, bg = c.bg_alt, bold = true })
hl("ColorColumn", { bg = c.bg_alt })
hl("NonText", { fg = c.fg_muted })
hl("EndOfBuffer", { fg = c.bg })
hl("Whitespace", { fg = c.border })
hl("SpecialKey", { fg = c.fg_muted })
hl("Directory", { fg = c.bright_blue })
hl("Title", { fg = c.fg, bold = true })
hl("Question", { fg = c.blue })
hl("MoreMsg", { fg = c.green })
hl("WarningMsg", { fg = c.bright_yellow })
hl("ErrorMsg", { fg = c.bright_red })

hl("StatusLine", { fg = c.fg, bg = c.bg_alt })
hl("StatusLineNC", { fg = c.fg_muted, bg = c.bg_alt })
hl("TabLine", { fg = c.fg_muted, bg = c.bg_alt })
hl("TabLineSel", { fg = c.fg, bg = c.bg, bold = true })
hl("TabLineFill", { bg = c.bg_alt })

hl("Pmenu", { fg = c.fg, bg = c.bg_float })
hl("PmenuSel", { fg = c.selection_fg, bg = c.selection })
hl("PmenuKind", { fg = c.purple, bg = c.bg_float })
hl("PmenuExtra", { fg = c.fg_muted, bg = c.bg_float })
hl("PmenuSbar", { bg = c.bg_alt })
hl("PmenuThumb", { bg = c.fg_muted })

hl("Comment", { fg = c.comment, italic = true })
hl("Constant", { fg = c.constant })
hl("String", { fg = c.string })
hl("Character", { fg = c.string })
hl("Number", { fg = c.number })
hl("Boolean", { fg = c.constant })
hl("Float", { fg = c.number })
hl("Identifier", { fg = c.variable })
hl("Function", { fg = c.fn })
hl("Statement", { fg = c.keyword })
hl("Conditional", { fg = c.control })
hl("Repeat", { fg = c.control })
hl("Label", { fg = c.keyword })
hl("Operator", { fg = c.fg_dim })
hl("Keyword", { fg = c.keyword })
hl("Exception", { fg = c.control })
hl("PreProc", { fg = c.keyword })
hl("Include", { fg = c.keyword })
hl("Define", { fg = c.keyword })
hl("Macro", { fg = c.keyword })
hl("Type", { fg = c.type })
hl("StorageClass", { fg = c.keyword })
hl("Structure", { fg = c.type })
hl("Typedef", { fg = c.type })
hl("Special", { fg = c.string_escape })
hl("SpecialChar", { fg = c.string_escape })
hl("Tag", { fg = c.keyword })
hl("Delimiter", { fg = c.fg_dim })
hl("Debug", { fg = c.red })
hl("Underlined", { fg = c.bright_blue, underline = true })
hl("Ignore", { fg = c.fg_muted })
hl("Error", { fg = c.bright_red })
hl("Todo", { fg = c.blue, bg = c.bg_alt, bold = true })

hl("SpellCap", {})

hl("DiagnosticError", { fg = c.bright_red })
hl("DiagnosticWarn", { fg = c.bright_yellow })
hl("DiagnosticInfo", { fg = c.bright_blue })
hl("DiagnosticHint", { fg = c.bright_cyan })
hl("DiagnosticOk", { fg = c.bright_green })
hl("DiagnosticUnderlineError", { sp = c.bright_red, undercurl = true })
hl("DiagnosticUnderlineWarn", { sp = c.bright_yellow, undercurl = true })
hl("DiagnosticUnderlineInfo", { sp = c.bright_blue, undercurl = true })
hl("DiagnosticUnderlineHint", { sp = c.bright_cyan, undercurl = true })
hl("LspInlayHint", { fg = c.fg_muted, bg = c.bg_alt })

hl("DiffAdd", { fg = c.bright_green, bg = c.bg_alt })
hl("DiffChange", { fg = c.bright_yellow, bg = c.bg_alt })
hl("DiffDelete", { fg = c.bright_red, bg = c.bg_alt })
hl("DiffText", { fg = c.bright_blue, bg = c.bg_alt })
hl("Added", { fg = c.bright_green })
hl("Changed", { fg = c.bright_yellow })
hl("Removed", { fg = c.bright_red })

hl("@variable", { fg = c.variable })
hl("@variable.builtin", { fg = c.keyword })
hl("@constant", { fg = c.constant })
hl("@constant.builtin", { fg = c.constant })
hl("@string", { fg = c.string })
hl("@string.escape", { fg = c.string_escape })
hl("@character", { fg = c.string })
hl("@number", { fg = c.number })
hl("@boolean", { fg = c.constant })
hl("@function", { fg = c.fn })
hl("@function.builtin", { fg = c.fn })
hl("@function.macro", { fg = c.keyword })
hl("@method", { fg = c.fn })
hl("@keyword", { fg = c.keyword })
hl("@keyword.function", { fg = c.keyword })
hl("@keyword.operator", { fg = c.keyword })
hl("@operator", { fg = c.fg_dim })
hl("@type", { fg = c.type })
hl("@type.builtin", { fg = c.type })
hl("@property", { fg = c.property })
hl("@field", { fg = c.property })
hl("@parameter", { fg = c.variable })
hl("@punctuation", { fg = c.fg_dim })
hl("@punctuation.bracket", { fg = c.fg_dim })
hl("@comment", { fg = c.comment, italic = true })
hl("@tag", { fg = c.keyword })
hl("@tag.attribute", { fg = c.property })
hl("@tag.delimiter", { fg = c.fg_dim })
hl("@markup.heading", { fg = c.keyword, bold = true })
hl("@markup.link", { fg = c.bright_blue, underline = true })
hl("@markup.raw", { fg = c.string })

hl("BufferLineFill", { bg = c.bg_alt })
hl("BufferLineBackground", { fg = c.fg_muted, bg = c.bg_alt })
hl("BufferLineBufferSelected", { fg = c.fg, bg = c.bg, bold = true })
hl("BufferLineSeparator", { fg = c.bg_alt, bg = c.bg_alt })
hl("BufferLineSeparatorSelected", { fg = c.bg, bg = c.bg })
hl("BufferLineModified", { fg = c.bright_yellow, bg = c.bg_alt })
hl("BufferLineModifiedSelected", { fg = c.bright_yellow, bg = c.bg })

hl("FzfLuaNormal", { fg = c.fg, bg = c.bg_float })
hl("FzfLuaBorder", { fg = c.border, bg = c.bg_float })
hl("FzfLuaTitle", { fg = c.fg, bg = c.bg_float, bold = true })
hl("FzfLuaCursor", { fg = c.selection_fg, bg = c.selection })
hl("FzfLuaCursorLine", { bg = c.bg_line })
hl("FzfLuaSearch", { fg = c.black, bg = c.bright_yellow })
hl("FzfLuaHeaderText", { fg = c.fg_muted })
hl("FzfLuaPath", { fg = c.cyan })
hl("FzfLuaDirPart", { fg = c.fg_muted })
hl("FzfLuaFilePart", { fg = c.fg })

hl("WhichKey", { fg = c.bright_blue })
hl("WhichKeyGroup", { fg = c.purple })
hl("WhichKeyDesc", { fg = c.fg })
hl("WhichKeySeparator", { fg = c.fg_muted })
hl("WhichKeyFloat", { bg = c.bg_float })
