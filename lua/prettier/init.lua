local options = require("prettier.options")
local null_ls = require("prettier.null-ls")
local utils = require("prettier.utils")

local M = {
  config_exists = utils.config_exists,
}

function M.setup(user_options)
  options.setup(user_options)
  null_ls.setup()
end

function M.format(method)
  null_ls.format(method)
end

return M
