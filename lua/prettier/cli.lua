local cli_args = {}

local cli = {
  args = cli_args,
}

local base_args_by_bin = {
  prettier = { "--stdin-filepath", "$FILENAME" },
  prettierd = { "$FILENAME" },
}

---@param bin string
---@return string[] base_args
function cli.get_base_args(bin)
  return vim.deepcopy(base_args_by_bin[bin])
end

local supported_bin = {
  prettier = true,
  prettierd = true,
}

---@param bin string
---@return boolean is_supported
function cli_args.supports_options(bin)
  return supported_bin[bin] or false
end

---@param option_name string
---@param option_value boolean|number|string
---@return string arg
function cli_args.from_option(option_name, option_value)
  local is_boolean = type(option_value) == "boolean"

  local arg_name = string.gsub(option_name, "_", "-")

  if is_boolean and not option_value then
    arg_name = "no-" .. arg_name
  end

  if is_boolean then
    return "--" .. arg_name
  end

  return "--" .. arg_name .. "=" .. option_value
end

---@param options table<string, boolean|number|string>
---@return string[] args
function cli_args.from_options(options)
  local args = {}

  for option_name, option_value in pairs(options) do
    local arg = cli_args.from_option(option_name, option_value)
    table.insert(args, arg)
  end

  return args
end

return cli
