# prettier.nvim

Prettier plugin for Neovim's built-in LSP client.

## Requirements

- [Neovim 0.5.0](https://github.com/neovim/neovim/releases/tag/v0.5.0)
- [`neovim/nvim-lspconfig`](https://github.com/neovim/nvim-lspconfig)
- [`jose-elias-alvarez/null-ls`](https://github.com/jose-elias-alvarez/null-ls.nvim)

## Installation

Install the plugins with your preferred plugin manager. For example, with [`vim-plug`](https://github.com/junegunn/vim-plug):

```vim
Plug 'neovim/nvim-lspconfig'
Plug 'jose-elias-alvarez/null-ls.nvim'
Plug 'MunifTanjim/prettier.nvim'
```

## Setup

`prettier.nvim` needs to be initialized with the `require("prettier").setup()` function.

For example:

```lua
local null_ls = require("null-ls")
local prettier = require("prettier")

null_ls.setup({
  on_attach = function(client, bufnr)
    if client.resolved_capabilities.document_formatting then
      vim.cmd("nnoremap <silent><buffer> <Leader>f :lua vim.lsp.buf.formatting()<CR>")
      -- format on save
      vim.cmd("autocmd BufWritePost <buffer> lua vim.lsp.buf.formatting()")
    end

    if client.resolved_capabilities.document_range_formatting then
      vim.cmd("xnoremap <silent><buffer> <Leader>f :lua vim.lsp.buf.range_formatting({})<CR>")
    end
  end,
})

prettier.setup({
  bin = 'prettier', -- or `prettierd`
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

  -- prettier format options
  arrow_parens = "always",
  bracket_spacing = true,
  embedded_language_formatting = "auto",
  end_of_line = "lf",
  html_whitespace_sensitivity = "css",
  jsx_bracket_same_line = false,
  jsx_single_quote = false,
  print_width = 80,
  prose_wrap = "preserve",
  quote_props = "as-needed",
  semi = true,
  single_quote = false,
  tab_width = 2,
  trailing_comma = "es5",
  use_tabs = false,
  vue_indent_script_and_style = false,
})
```

## License

Licensed under the MIT License. Check the [LICENSE](./LICENSE) file for details.
