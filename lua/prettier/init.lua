local options = require("prettier.options")
local null_ls = require("prettier.null-ls")

local M = {}

function M.setup(user_options)
  options.setup(user_options)
  null_ls.setup()
end

return M
