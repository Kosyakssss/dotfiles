local M = {}

function M.open(start_dir)
    local tmp = vim.fn.tempname()
    vim.cmd("tabnew")
    local term_buf = vim.api.nvim_get_current_buf()
    vim.fn.jobstart({ "yazi", start_dir, "--chooser-file", tmp }, {
        term = true,
        on_exit = function()
            vim.schedule(function()
                if vim.api.nvim_buf_is_valid(term_buf) then
                    vim.cmd("bdelete! " .. term_buf)
                end
                local file = io.open(tmp, "r")
                if file then
                    local path = file:read("*l")
                    file:close()
                    os.remove(tmp)
                    if path and path ~= "" then
                        vim.cmd("edit " .. vim.fn.fnameescape(path))
                    end
                end
            end)
        end,
    })
    vim.cmd("startinsert")
end

function M.open_cwd()
    M.open(vim.uv.cwd())
end

function M.open_file_dir()
    local dir = vim.fn.expand("%:p:h")
    M.open(dir ~= "" and dir or vim.uv.cwd())
end

return M
