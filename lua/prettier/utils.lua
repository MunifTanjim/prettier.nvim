local cache = require("prettier.cache")
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

---@param _cwd string
---@param scope '"global"'|'"local"'
---@return string|false bin_dir
local function _get_bin_dir(_cwd, scope)
  local cmd = "npm bin"
  if scope == "global" then
    cmd = cmd .. " --global"
  end

  local result = vim.fn.systemlist(cmd)
  if vim.fn.isdirectory(result[1]) == 1 then
    return result[1]
  end

  return false
end

---@type fun(cwd: string, scope: '"global"'|'"local"'): string|false
local get_bin_dir = cache.wrap(_get_bin_dir, function(cwd, scope)
  return scope .. "::" .. cwd
end)

---@param name string
---@param scope '"global"'|'"local"'
---@return string|false bin
local function _get_bin_path(cwd, name, scope)
  local bin_dir = get_bin_dir(cwd, scope)
  if not bin_dir then
    return false
  end

  local bin = path_join(bin_dir, name)
  if vim.fn.executable(bin) == 1 then
    return bin
  end

  if scope == "global" and vim.fn.executable(name) == 1 then
    return vim.fn.exepath(name)
  end

  return false
end

---@type fun(cwd: string, name: string, scope: '"global"'|'"local"'): string|false
local get_bin_path = cache.wrap(_get_bin_path, function(cwd, name, scope)
  return scope .. "::" .. name .. "::" .. cwd
end)

---@param name string
---@param preference? '"global"'|'"local"'|'"prefer-local"'
---@return string|false
function M.resolve_bin(name, preference)
  local cwd = vim.fn.getcwd()

  preference = preference or "prefer-local"

  if preference == "global" then
    return get_bin_path(cwd, name, "global")
  end

  local bin = get_bin_path(cwd, name, "local")

  if bin or preference == "local" then
    return bin
  end

  return get_bin_path(cwd, name, "global")
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

function M.list_to_map(list)
  local map = {}
  for _, key in ipairs(list) do
    map[key] = true
  end
  return map
end

return M
