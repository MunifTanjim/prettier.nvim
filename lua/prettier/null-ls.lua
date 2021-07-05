local ok, null_ls = pcall(require, "null-ls")

local options = require("prettier.options")
local utils = require("prettier.utils")

local function get_args(common_args, is_range_formatting)
  if not is_range_formatting then
    return vim.deepcopy(common_args)
  end

  return function(params)
    local args = vim.deepcopy(common_args)

    local content, range = params.content, params.range

    local row, col = range.row, range.col
    local range_start = row == 1 and 0 or vim.fn.strchars(table.concat({ unpack(content, 1, row - 1) }, "\n") .. "\n", true)
    range_start = range_start + vim.fn.strchars(vim.fn.strcharpart(unpack(content, row, row), 0, col), true)

    local end_row, end_col = range.end_row, range.end_col
    local range_end = end_row == 1 and 0 or vim.fn.strchars(table.concat({ unpack(content, 1, end_row - 1) }, "\n") .. "\n", true)
    range_end = range_end + vim.fn.strchars(vim.fn.strcharpart(unpack(content, end_row, end_row), 0, end_col), true)

    table.insert(args, "--range-start")
    table.insert(args, range_start)
    table.insert(args, "--range-end")
    table.insert(args, range_end)

    return args
  end
end

local function prettier_enabled()
  return utils.config_file_exists()
end

local M = {}

function M.setup()
  if not ok then
    return
  end

  local name = "prettier"

  if null_ls.is_registered(name) then
    return
  end

  local sources = {}

  local function add_source(method, generator)
    table.insert(sources, { method = method, generator = generator })
  end

  if not prettier_enabled() then
    return
  end

  local prettier_bin = options.get("bin")

  local command = utils.resolve_bin(prettier_bin)

  if not command then
    return
  end

  local filetypes = options.get("filetypes")

  if vim.tbl_count(filetypes) == 0 then
    return
  end

  local prettier_opts = {
    command = command,
    args = options.get("args"),
    to_stdin = true,
  }

  local function make_prettier_opts(method)
    local opts = vim.deepcopy(prettier_opts)
    opts.args = get_args(opts.args, method == null_ls.methods.RANGE_FORMATTING)
    return opts
  end

  add_source(
    null_ls.methods.FORMATTING,
    null_ls.formatter(make_prettier_opts(null_ls.methods.FORMATTING))
  )

  add_source(
    null_ls.methods.RANGE_FORMATTING,
    null_ls.formatter(make_prettier_opts(null_ls.methods.RANGE_FORMATTING))
  )

  if vim.tbl_count(sources) > 0 then
    null_ls.register({
      filetypes = filetypes,
      name = name,
      sources = sources,
    })
  end
end

return M
