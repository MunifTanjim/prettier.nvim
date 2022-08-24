local options = require("prettier.options")
local null_ls = require("prettier.null-ls")

local M = {
  __ = {},
}

function M.setup(user_options)
  options.setup(user_options)
  vim.schedule(function()
    null_ls.setup()
  end)
end

function M.format(method)
  null_ls.format(method)
end

function M.create_formatter(opts)
  local command = opts.command

  M.__[command] = {
    _fn = function(method)
      if M.__[command].fn then
        return M.__[command].fn(method)
      end
    end,
    cmd = function(range)
      if range > 0 then
        M.__[command]._fn("textDocument/rangeFormatting")
      else
        M.__[command]._fn("textDocument/formatting")
      end
    end,
  }

  vim.schedule(function()
    local format = null_ls.create_formatter({
      bin = opts.bin,
      bin_preference = opts.bin_preference,
      cli_options = opts.cli_options,
      ["null-ls"] = opts["null-ls"],
    })

    M.__[command].fn = format

    vim.cmd(string.format([[command! -range=%% %s :lua require("prettier").__["%s"].cmd(<range>)]], command, command))
  end)

  return M.__[command]._fn
end

return M
