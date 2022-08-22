local options = require("prettier.options")
local null_ls = require("prettier.null-ls")

local M = {}

function M.setup(user_options)
  options.setup(user_options)
  vim.schedule(function()
    null_ls.setup()
  end)
end

function M.format(method)
  null_ls.format(method)
end

return M
