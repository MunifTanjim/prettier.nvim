local u = require("prettier.utils")

local bins = { "prettier", "prettierd" }

local top_level_cli_options = {
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

local default_options = {
  _initialized = false,
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
  ["null-ls.condition"] = function()
    return u.config_exists({
      check_package_json = true,
    })
  end,
  cli_options = {
    config_precedence = "prefer-file",
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
    ["cli_options"] = {
      tbl["filetypes"],
      "table",
      true,
    },
    ["null-ls.condition"] = {
      tbl["null-ls.condition"],
      "function",
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

local function should_flatten(key, value, depth)
  local skip_key = {
    cli_options = true,
  }
  return not skip_key[key] and not vim.tbl_islist(value) and depth < 7
end

local options = vim.deepcopy(u.tbl_flatten(default_options, should_flatten))

local M = {}

function M.setup(user_options)
  if options._initialized then
    return
  end

  user_options = u.tbl_flatten(user_options or {}, should_flatten)

  validate_options(user_options)

  options = vim.tbl_deep_extend("force", options, user_options) --[[@as table]]

  for _, option_name in ipairs(top_level_cli_options) do
    if options[option_name] then
      -- @todo: log deprecation notice
      options.cli_options[option_name] = options[option_name]
      options[option_name] = nil
    end
  end

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
