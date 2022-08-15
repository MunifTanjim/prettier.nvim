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

local bin_support_prettier_cli_options = {
  prettier = true,
  prettierd = false,
}

local prettier_cli_options = {
  "config_precedence",

  "arrow_parens",
  "bracket_spacing",
  "bracket_same_line",
  "embedded_language_formatting",
  "end_of_line",
  "html_whitespace_sensitivity",
  "jsx_bracket_same_line",
  "jsx_single_quote",
  "print_width",
  "prose_wrap",
  "quote_props",
  "semi",
  "single_attribute_per_line",
  "single_quote",
  "tab_width",
  "trailing_comma",
  "use_tabs",
  "vue_indent_script_and_style",
}

local default_prettier_cli_options = {
  config_precedence = "prefer-file",
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
    ["null-ls.runtime_condition"] = {
      tbl["null-ls.runtime_condition"],
      "function",
      true,
    },
    ["null-ls.timeout"] = {
      tbl["null-ls.timeout"],
      "number",
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

local function to_prettier_arg(option_name, option_value)
  local is_boolean = type(option_value) == "boolean"

  local arg_name = string.gsub(option_name, "_", "-")

  if is_boolean and not option_value then
    arg_name = "no-" .. arg_name
  end

  if is_boolean then
    return "--" .. arg_name
  else
    return "--" .. arg_name .. "=" .. option_value
  end
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

  local args = {}

  if bin_support_prettier_cli_options[options.bin] then
    for _, option_name in ipairs(prettier_cli_options) do
      local option_value = options[option_name]
      if option_value == nil then
        option_value = default_prettier_cli_options[option_name]
      end

      if option_value ~= nil then
        local arg = to_prettier_arg(option_name, option_value)
        table.insert(args, arg)
      end
    end
  end

  for _, arg in ipairs(args_by_bin[options.bin]) do
    table.insert(args, arg)
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
