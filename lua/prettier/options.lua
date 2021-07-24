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

local prettier_format_options = {
  "arrow_parens",
  "bracket_spacing",
  "embedded_language_formatting",
  "end_of_line",
  "html_whitespace_sensitivity",
  "jsx_bracket_same_line",
  "jsx_single_quote",
  "print_width",
  "prose_wrap",
  "quote_props",
  "semi",
  "single_quote",
  "tab_width",
  "trailing_comma",
  "use_tabs",
  "vue_indent_script_and_style",
}

local default_options = {
  _initialized = false,
  _args = args_by_bin["prettier"],
  bin = "prettier",
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

  local args = args_by_bin[options.bin]

  for _, option_name in pairs(prettier_format_options) do
    local option_value = options[option_name]

    if option_value ~= nil then
      local is_boolean = type(option_value) == "boolean"

      local arg_name = string.gsub(option_name, "_", "-")

      if is_boolean and not option_value then
        arg_name = "no-" .. arg_name
      end

      if is_boolean then
        table.insert(args, "--" .. arg_name)
      else
        table.insert(args, "--" .. arg_name .. "=" .. option_value)
      end
    end
  end

  options._args = args

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
