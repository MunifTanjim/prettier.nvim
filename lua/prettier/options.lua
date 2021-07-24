local function tbl_flatten(tbl, result, prefix, depth)
  result = result or {}
  prefix = prefix or ""
  depth = type(depth) == "number" and depth or 1
  for k, v in pairs(tbl) do
    if type(v) == "table" and not vim.tbl_islist(v) and depth < 42 then
      tbl_flatten(v, result, prefix .. k .. ".", depth + 1)
    else
      result[prefix .. k] = v
    end
  end
  return result
end

local bins = { "prettier", "prettierd" }
local args_by_bin = {
  prettier = { "--stdin-filepath", "$FILENAME" },
  prettierd = { "$FILENAME" },
}
local disable_rule_comment_locations = { "same_line", "separate_line" }

local default_options = {
  _initialized = false,
  bin = "prettier",
  args = args_by_bin["prettier"],
  filetypes = {
    "css",
    "graphql",
    "html",
    "javascript",
    "javascriptreact",
    "json",
    "less",
    "markdown",
    "scss",
    "typescript",
    "typescriptreact",
    "yaml",
  },
}

local function get_validate_argmap(tbl, key)
  local argmap = {
    ["bin"] = {
      tbl["bin"],
      function(val)
        return val == nil or vim.tbl_contains(bins, val)
      end,
      table.concat(bins, ", "),
    },
    ["filetypes"] = {
      tbl["filetypes"],
      "table",
      true,
    },
  }

  if type(key) == "string" then
    return {
      [key] = argmap[key],
    }
  end

  return argmap
end

local function validate_options(user_options)
  vim.validate(get_validate_argmap(user_options))
end

local options = vim.deepcopy(tbl_flatten(default_options))

local M = {}

function M.setup(user_options)
  if options._initialized then
    return
  end

  user_options = tbl_flatten(user_options)

  validate_options(user_options)

  options = vim.tbl_deep_extend("force", options, user_options)
  options.args = options.bin and args_by_bin[options.bin]

  options._initialized = true
end

function M.get(key)
  if type(key) == "string" then
    return vim.deepcopy(options[key])
  end

  return vim.deepcopy(options)
end

function M.set(key, value)
  local is_internal = vim.startswith(key, "_")

  local argmap = get_validate_argmap({ [key] = value }, key)

  if not is_internal and argmap[key] == nil then
    return error(string.format("invalid key: %s", key))
  end

  vim.validate(argmap)

  options[key] = vim.deepcopy(value)
end

function M.reset()
  options = vim.deepcopy(default_options)
end

return M
