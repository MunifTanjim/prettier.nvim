local ok, null_ls = pcall(require, "null-ls")

local cli = require("prettier.cli")
local options = require("prettier.options")
local utils = require("prettier.utils")

local M = {
  _generator_initialized = false,
  _generator = nil,
}

local function noop() end

local function create_generator(opts)
  local bin = opts.bin
  local cli_options = opts.cli_options or {}
  local null_ls_options = opts["null-ls"] or {}

  local command = utils.resolve_bin(bin, opts.bin_preference)

  if not command then
    return
  end

  local format_cli_args = cli.get_base_args(bin)
  local range_format_cli_args = cli.get_base_args(bin)
  if cli.args.supports_options(bin) then
    for _, arg in ipairs(cli.args.from_options(cli_options)) do
      table.insert(format_cli_args, arg)
    end

    --[[
      @note GitHub Issue: https://github.com/prettier/prettier/issues/13354
            `--config-precedence=prefer-file` is problematic with cli options
            for range formatting.
    --]]
    if cli_options.config_precedence ~= "prefer-file" then
      range_format_cli_args = vim.deepcopy(format_cli_args)
    end
  end

  return null_ls.formatter({
    command = command,
    args = function(params)
      if params.lsp_method == "textDocument/formatting" then
        return vim.deepcopy(format_cli_args)
      end

      local args = vim.deepcopy(range_format_cli_args)

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
    runtime_condition = null_ls_options["runtime_condition"],
    timeout = null_ls_options["timeout"],
  })
end

local function create_formatter(opts)
  if not ok then
    return noop
  end

  local generator = create_generator({
    bin = opts.bin,
    bin_preference = opts.bin_preference,
    cli_options = opts.cli_options,
    ["null-ls"] = opts["null-ls"],
  })

  if not generator then
    return noop
  end

  local u = require("null-ls.utils")

  local function format(original_params)
    local method = original_params.range and "textDocument/rangeFormatting" or "textDocument/formatting"
    local bufnr = original_params.bufnr

    local temp_bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(temp_bufnr, "eol", vim.api.nvim_buf_get_option(bufnr, "eol"))
    vim.api.nvim_buf_set_option(temp_bufnr, "fileformat", vim.api.nvim_buf_get_option(bufnr, "fileformat"))
    vim.api.nvim_buf_set_lines(temp_bufnr, 0, -1, false, vim.api.nvim_buf_get_lines(bufnr, 0, -1, false))

    local function callback()
      local edits = require("null-ls.diff").compute_diff(
        u.buf.content(bufnr),
        u.buf.content(temp_bufnr),
        u.get_line_ending(bufnr)
      )

      vim.schedule(function()
        vim.api.nvim_buf_delete(temp_bufnr, { force = true })
      end)

      local is_actual_edit = not (edits.newText == "" and edits.rangeLength == 0)

      if is_actual_edit then
        vim.lsp.util.apply_text_edits({ edits }, bufnr, require("null-ls.client").get_offset_encoding())
      end
    end

    require("null-ls.generators").run(
      { generator },
      u.make_params(original_params, require("null-ls.methods").map[method]),
      {
        sequential = true,
        postprocess = function(edit, params)
          edit.row = edit.row or 1
          edit.col = edit.col or 1
          edit.end_row = edit.end_row or #params.content + 1
          edit.end_col = edit.end_col or 1

          edit.range = u.range.to_lsp(edit)
          edit.newText = edit.text
        end,
        after_each = function(edits)
          vim.lsp.util.apply_text_edits(edits, temp_bufnr, require("null-ls.client").get_offset_encoding())
        end,
      },
      callback
    )
  end

  local filetypes = opts.filetypes and utils.list_to_map(opts.filetypes)

  return function(method)
    local bufnr = vim.api.nvim_get_current_buf()

    if filetypes and not filetypes[vim.api.nvim_buf_get_option(bufnr, "filetype")] then
      return
    end

    local params = {
      bufnr = bufnr,
      method = method,
    }

    if method == "textDocument/rangeFormatting" then
      params.range = vim.lsp.util.make_given_range_params().range
    end

    format(params)
  end
end

function M.setup()
  M.format = create_formatter({
    bin = options.get("bin"),
    cli_options = options.get("cli_options"),
    ["null-ls"] = {
      runtime_condition = options.get("null-ls.runtime_condition"),
      timeout = options.get("null-ls.timeout"),
    },
  })

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

  if vim.tbl_count(options.get("filetypes")) == 0 then
    return
  end

  local generator = create_generator({
    bin = options.get("bin"),
    cli_options = options.get("cli_options"),
    ["null-ls"] = {
      runtime_condition = options.get("null-ls.runtime_condition"),
      timeout = options.get("null-ls.timeout"),
    },
  })

  if not generator then
    return
  end

  null_ls.register({
    filetypes = options.get("filetypes"),
    generator = generator,
    method = { null_ls.methods.FORMATTING, null_ls.methods.RANGE_FORMATTING },
    name = name,
  })
end

return M
