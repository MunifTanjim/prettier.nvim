local find_git_ancestor = require("lspconfig.util").find_git_ancestor
local find_package_json_ancestor = require("lspconfig.util").find_package_json_ancestor
local path_join = require("lspconfig.util").path.join
local options = require("prettier.options")

local M = {}

local function get_working_directory()
  local startpath = vim.fn.getcwd()
  return find_git_ancestor(startpath) or find_package_json_ancestor(startpath)
end

function M.config_file_exists()
  local project_root = get_working_directory()

  if project_root then
    return vim.tbl_count(
      vim.fn.glob(".prettierrc*", true, true)
    ) > 0
  end

  return false
end

---@param cmd string
---@return nill|string
function M.resolve_bin(cmd)
  local project_root = get_working_directory()

  if project_root then
    local local_bin = path_join(project_root, "/node_modules/.bin" ,cmd)
    if vim.fn.executable(local_bin) == 1 then
      return local_bin
    end
  end

  if vim.fn.executable(cmd) == 1 then
    return cmd
  end

  return nil
end

return M
