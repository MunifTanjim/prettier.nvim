local mod = {}

local supported_bin = {
  prettier = true,
  prettierd = false,
}

---@param bin string
---@return boolean is_supported
function mod.is_supported(bin)
  return supported_bin[bin] or false
end

---@return string arg
function mod.to_arg(option_name, option_value)
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

---@return string[] args
function mod.to_args(options)
  local args = {}

  for option_name, option_value in pairs(options) do
    local arg = mod.to_arg(option_name, option_value)
    table.insert(args, arg)
  end

  return args
end

return mod
