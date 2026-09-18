local M = {}

local layouts = {
    { "ёйцукенгшщзхъфывапролджэячсмитьбю", "`qwertyuiop[]asdfghjkl;'zxcvbnm,." },
    { "ЁЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЖЭЯЧСМИТЬБЮ", "~QWERTYUIOP{}ASDFGHJKL:\"ZXCVBNM<>" },
}
local special = { [";"] = true, [","] = true, ['"'] = true, ["|"] = true, ["\\"] = true }

local langmap_parts = {}
local russian_keys = {}
for _, layout in ipairs(layouts) do
    for index = 0, vim.fn.strchars(layout[1]) - 1 do
        local from = vim.fn.strcharpart(layout[1], index, 1)
        local to = vim.fn.strcharpart(layout[2], index, 1)
        russian_keys[to] = from
        if special[from] then from = "\\" .. from end
        if special[to] then to = "\\" .. to end
        langmap_parts[#langmap_parts + 1] = from .. to
    end
end
vim.opt.langmap = table.concat(langmap_parts, ",")

local function russian_keymap(lhs)
    local translated = {}
    local index = 1
    while index <= #lhs do
        if lhs:sub(index, index) == "<" then
            local close = lhs:find(">", index, true)
            if close then
                table.insert(translated, lhs:sub(index, close))
                index = close + 1
            else
                table.insert(translated, russian_keys["<"] or "<")
                index = index + 1
            end
        else
            local key = lhs:sub(index, index)
            table.insert(translated, russian_keys[key] or key)
            index = index + 1
        end
    end
    return table.concat(translated)
end

function M.map(mode, lhs, rhs, opts)
    vim.keymap.set(mode, lhs, rhs, opts)
    if lhs == "jk" then return end
    local russian_lhs = russian_keymap(lhs)
    if russian_lhs ~= lhs then
        vim.keymap.set(mode, russian_lhs, rhs, opts)
    end
end

return M
