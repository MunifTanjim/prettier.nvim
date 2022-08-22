local find_git_ancestor = require("lspconfig.util").find_git_ancestor
local find_package_json_ancestor = require("lspconfig.util").find_package_json_ancestor
local path_join = require("lspconfig.util").path.join

local M = {}

local function get_working_directory()
  local startpath = vim.fn.getcwd()
  return find_git_ancestor(startpath) or find_package_json_ancestor(startpath)
end

---@return boolean
local function config_file_exists()
  local project_root = get_working_directory()

  if project_root then
    return vim.tbl_count(vim.fn.glob(".prettierrc*", true, true)) > 0
      or vim.tbl_count(vim.fn.glob("prettier.config.*", true, true)) > 0
  end

  return false
end

---@return boolean
function M.prettier_enabled()
  return config_file_exists()
end

---@param cmd string
---@return nil|string
function M.resolve_bin(cmd)
  local project_root = get_working_directory()

  if project_root then
    local local_bin = path_join(project_root, "/node_modules/.bin", cmd)
    if vim.fn.executable(local_bin) == 1 then
      return local_bin
    end
  end

  if vim.fn.executable(cmd) == 1 then
    return cmd
  end

  return nil
end

function M.tbl_flatten(tbl, should_flatten, result, prefix, depth)
  should_flatten = should_flatten or function(_, value)
    return not vim.tbl_islist(value) and depth < 42
  end

  result = result or {}
  prefix = prefix or ""
  depth = type(depth) == "number" and depth or 1
  for k, v in pairs(tbl) do
    local key = prefix .. k
    if type(v) == "table" and should_flatten(key, v, depth) then
      M.tbl_flatten(v, should_flatten, result, key .. ".", depth + 1)
    else
      result[key] = v
    end
  end
  return result
end

return M
