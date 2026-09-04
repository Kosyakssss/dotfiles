local M = {}

local flexoki = {
    light = {
        tx = "#100F0F", tx_2 = "#6F6E69", tx_3 = "#B7B5AC",
        ui_3 = "#CECDC3", ui_2 = "#DAD8CE", ui = "#E6E4D9",
        bg_2 = "#F2F0E5", bg = "#FFFCF0",
        re = "#AF3029", or_ = "#BC5215", ye = "#AD8301", gr = "#66800B",
        cy = "#24837B", bl = "#205EA6", pu = "#5E409D", ma = "#A02F6F",
        cursor = "#100F0F", cursor_text = "#FFFCF0",
        selection = "#DAD8CE", selection_text = "#100F0F",
        terminal = {
            "#100F0F", "#AF3029", "#66800B", "#AD8301",
            "#205EA6", "#A02F6F", "#24837B", "#CECDC3",
            "#6F6E69", "#D14D41", "#879A39", "#D0A215",
            "#4385BE", "#CE5D97", "#3AA99F", "#FFFCF0",
        },
    },
    dark = {
        tx = "#CECDC3", tx_2 = "#878580", tx_3 = "#575653",
        ui_3 = "#403E3C", ui_2 = "#343331", ui = "#282726",
        bg_2 = "#1C1B1A", bg = "#100F0F",
        re = "#D14D41", or_ = "#DA702C", ye = "#D0A215", gr = "#879A39",
        cy = "#3AA99F", bl = "#4385BE", pu = "#8B7EC8", ma = "#CE5D97",
        cursor = "#CECDC3", cursor_text = "#100F0F",
        selection = "#343331", selection_text = "#CECDC3",
        terminal = {
            "#100F0F", "#D14D41", "#879A39", "#D0A215",
            "#4385BE", "#CE5D97", "#3AA99F", "#CECDC3",
            "#575653", "#D14D41", "#879A39", "#D0A215",
            "#4385BE", "#CE5D97", "#3AA99F", "#FFFCF0",
        },
    },
}

local function color(group, attribute, fallback)
    local value = vim.api.nvim_get_hl(0, { name = group, link = false })[attribute]
    return value and string.format("#%06X", value) or fallback
end

local function default_palette()
    local tx = color("Normal", "fg", vim.o.background == "light" and "#000000" or "#FFFFFF")
    local bg = color("Normal", "bg", vim.o.background == "light" and "#FFFFFF" or "#000000")
    local bg_2 = color("CursorLine", "bg", bg)
    local ui = color("PmenuSel", "bg", bg_2)
    return {
        tx = tx,
        tx_2 = color("Comment", "fg", tx),
        tx_3 = color("LineNr", "fg", tx),
        ui_3 = color("WinSeparator", "fg", tx),
        ui_2 = color("Visual", "bg", ui),
        ui = ui,
        bg_2 = bg_2,
        bg = bg,
        re = color("DiagnosticError", "fg", color("ErrorMsg", "fg", tx)),
        or_ = color("DiagnosticWarn", "fg", color("WarningMsg", "fg", tx)),
        ye = color("Constant", "fg", tx),
        gr = color("Statement", "fg", tx),
        cy = color("String", "fg", tx),
        bl = color("Directory", "fg", tx),
        pu = color("Type", "fg", tx),
        ma = color("PreProc", "fg", tx),
        cursor = color("Cursor", "bg", tx),
        cursor_text = color("Cursor", "fg", bg),
        selection = color("Visual", "bg", ui),
        selection_text = color("Visual", "fg", tx),
    }
end

function M.apply()
    local c = vim.g.colors_name == "flexoki"
        and flexoki[vim.o.background]
        or default_palette()

    local function hl(group, opts)
        vim.api.nvim_set_hl(0, group, opts)
    end

    local function link(group, target)
        hl(group, { link = target })
    end

    if c.terminal then
        for index, color in ipairs(c.terminal) do
            vim.g["terminal_color_" .. (index - 1)] = color
        end
    end

    -- Editor UI. These roles follow the custom palette where Neovim has
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
    hl("Cursor", { fg = c.cursor_text, bg = c.cursor })
    hl("lCursor", { fg = c.cursor_text, bg = c.cursor })
    hl("CursorIM", { fg = c.bg, bg = c.or_ })
    hl("Visual", { fg = c.selection_text, bg = c.selection })
    hl("VisualNOS", { fg = c.selection_text, bg = c.selection })
    hl("Search", { fg = c.bg, bg = c.ye })
    hl("IncSearch", { fg = c.bg, bg = c.or_ })
    hl("CurSearch", { fg = c.bg, bg = c.or_ })
    hl("Substitute", { fg = c.bg, bg = c.ma })
    hl("MatchParen", { fg = c.tx, bg = c.ui, bold = true })
    hl("ColorColumn", { bg = c.bg_2 })
    hl("NonText", { fg = c.bg_2 })
    hl("EndOfBuffer", { fg = c.bg })
    hl("Whitespace", { fg = c.bg_2 })
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
    hl("CustomModeNormal", { fg = c.bg, bg = c.bl })
    hl("CustomModeInsert", { fg = c.bg, bg = c.or_ })
    hl("CustomModeSelect", { fg = c.bg, bg = c.ma })
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

    hl("DiagnosticError", { fg = c.re, bold = true })
    hl("DiagnosticWarn", { fg = c.or_, bold = true })
    hl("DiagnosticInfo", { fg = c.ye, bold = true })
    hl("DiagnosticHint", { fg = c.bl, bold = true })
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

    -- Tree-sitter captures translated into custom syntax roles.
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
    hl("@markup.strong", { fg = c.or_, bold = true })
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

    local group = vim.api.nvim_create_augroup("theme_background", { clear = true })
    vim.api.nvim_create_autocmd("OptionSet", {
        group = group,
        pattern = "background",
        callback = function()
            local colorscheme = vim.g.colors_name
            vim.defer_fn(function()
                if colorscheme == "default" then vim.cmd.colorscheme("default") end
                M.apply()
            end, 10)
        end,
    })
end

return M
