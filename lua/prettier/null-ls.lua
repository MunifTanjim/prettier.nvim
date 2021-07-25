local ok, null_ls = pcall(require, "null-ls")

local options = require("prettier.options")
local utils = require("prettier.utils")

local M = {
  _generator_initialized = false,
  _generator = nil,
}

local function get_generator()
  if not ok then
    return
  end

  if M._generator_initialized then
    return M._generator
  end

  M._generator_initialized = true

  if vim.tbl_count(options.get("filetypes")) == 0 then
    return
  end

  local command = utils.resolve_bin(options.get("bin"))

  if not command then
    return
  end

  M._generator = null_ls.formatter({
    command = command,
    args = function(params)
      local args = options.get("_args")

      if params.lsp_method == "textDocument/formatting" then
        return args
      end

      local content, range = params.content, params.range

      local row, col = range.row, range.col
      local range_start = row == 1 and 0
        or vim.fn.strchars(table.concat({ unpack(content, 1, row - 1) }, "\n") .. "\n", true)
      range_start = range_start + vim.fn.strchars(vim.fn.strcharpart(unpack(content, row, row), 0, col), true)

      local end_row, end_col = range.end_row, range.end_col
      local range_end = end_row == 1 and 0
        or vim.fn.strchars(table.concat({ unpack(content, 1, end_row - 1) }, "\n") .. "\n", true)
      range_end = range_end + vim.fn.strchars(vim.fn.strcharpart(unpack(content, end_row, end_row), 0, end_col), true)

      table.insert(args, "--range-start=" .. range_start)
      table.insert(args, "--range-end=" .. range_end)

      return args
    end,
    to_stdin = true,
  })

  return M._generator
end

function M.setup()
  if not ok then
    return
  end

  local name = "prettier"

  if null_ls.is_registered(name) then
    return
  end

  if not utils.prettier_enabled() then
    return
  end

  local generator = get_generator()

  if not generator then
    return
  end

  null_ls.register({
    filetypes = options.get("filetypes"),
    generator = generator,
    method = { null_ls.methods.formatting, null_ls.methods.range_formatting },
    name = name,
  })
end

return M
