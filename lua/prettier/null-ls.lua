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

function M.format(method)
  if not ok then
    return
  end

  method = method or "textDocument/formatting"

  local generator = get_generator()

  if not generator then
    return
  end

  if not M._format then
    local u = require("null-ls.utils")

    M._format = function(original_params)
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
          vim.lsp.util.apply_text_edits({ edits }, bufnr)
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
            vim.lsp.util.apply_text_edits(edits, temp_bufnr)
          end,
        },
        callback
      )
    end
  end

  local bufnr = vim.api.nvim_get_current_buf()

  local params = {
    bufnr = bufnr,
    method = method,
  }

  if method == "textDocument/rangeFormatting" then
    params.range = vim.lsp.util.make_given_range_params().range
  end

  M._format(params)
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
    method = { null_ls.methods.FORMATTING, null_ls.methods.RANGE_FORMATTING },
    name = name,
  })
end

return M
