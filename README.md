# prettier.nvim

Prettier plugin for Neovim's built-in LSP client.

## Requirements

- [Neovim 0.5.0](https://github.com/neovim/neovim/releases/tag/v0.5.0)
- [`neovim/nvim-lspconfig`](https://github.com/neovim/nvim-lspconfig)
- [`jose-elias-alvarez/null-ls`](https://github.com/jose-elias-alvarez/null-ls.nvim)

## Installation

Install the plugins with your preferred plugin manager. For example:

**With [`vim-plug`](https://github.com/junegunn/vim-plug)**

```vim
Plug 'neovim/nvim-lspconfig'
Plug 'jose-elias-alvarez/null-ls.nvim'
Plug 'MunifTanjim/prettier.nvim'
```

**With [`packer.nvim`](https://github.com/wbthomason/packer.nvim)**

```lua
use('neovim/nvim-lspconfig')
use('jose-elias-alvarez/null-ls.nvim')
use('MunifTanjim/prettier.nvim')
```

## Setup

> **Warning**
>
> Prettier won't be automatically installed by this plugin.
> You need to have it installed either globally or locally for the project.

### Setting up `null-ls`

For Latest Neovim:

```lua
local null_ls = require("null-ls")

local group = vim.api.nvim_create_augroup("lsp_format_on_save", { clear = false })
local event = "BufWritePre" -- or "BufWritePost"
local async = event == "BufWritePost"

null_ls.setup({
  on_attach = function(client, bufnr)
    if client.supports_method("textDocument/formatting") then
      vim.keymap.set("n", "<Leader>f", function()
        vim.lsp.buf.format({ bufnr = vim.api.nvim_get_current_buf() })
      end, { buffer = bufnr, desc = "[lsp] format" })

      -- format on save
      vim.api.nvim_clear_autocmds({ buffer = bufnr, group = group })
      vim.api.nvim_create_autocmd(event, {
        buffer = bufnr,
        group = group,
        callback = function()
          vim.lsp.buf.format({ bufnr = bufnr, async = async })
        end,
        desc = "[lsp] format on save",
      })
    end

    if client.supports_method("textDocument/rangeFormatting") then
      vim.keymap.set("x", "<Leader>f", function()
        vim.lsp.buf.format({ bufnr = vim.api.nvim_get_current_buf() })
      end, { buffer = bufnr, desc = "[lsp] format" })
    end
  end,
})
```

<details>
<summary>For Older Neovim:</summary>

```lua
local null_ls = require("null-ls")

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
```

</details>

### Setting Up `prettier.nvim`

`prettier.nvim` needs to be initialized with the `require("prettier").setup()` function.
All the settings are optional.

```lua
local prettier = require("prettier")

prettier.setup({
  bin = 'prettier', -- or `'prettierd'` (v0.23.3+)
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
})
```

> **Note**
>
> It's highly recommended that you use this plugin with [`prettierd`](https://github.com/fsouza/prettierd).

You can also supply some options to `null-ls`:

```lua
prettier.setup({
  ["null-ls"] = {
    condition = function()
      return prettier.config_exists({
        -- if `false`, skips checking `package.json` for `"prettier"` key
        check_package_json = true,
      })
    end,
    runtime_condition = function(params)
      -- return false to skip running prettier
      return true
    end,
    timeout = 5000,
  }
})
```

You can set [Prettier's options](https://prettier.io/docs/en/options.html) too.
They are passed to the `prettier` CLI.

```lua
prettier.setup({
  cli_options = {
    arrow_parens = "always",
    bracket_spacing = true,
    bracket_same_line = false,
    embedded_language_formatting = "auto",
    end_of_line = "lf",
    html_whitespace_sensitivity = "css",
    -- jsx_bracket_same_line = false,
    jsx_single_quote = false,
    print_width = 80,
    prose_wrap = "preserve",
    quote_props = "as-needed",
    semi = true,
    single_attribute_per_line = false,
    single_quote = false,
    tab_width = 2,
    trailing_comma = "es5",
    use_tabs = false,
    vue_indent_script_and_style = false,
  },
})
```

By default these options are only used if prettier config file is not found.
If you want to change that behavior, you can use the following option:

```lua
prettier.setup({
  cli_options = {
    -- https://prettier.io/docs/en/cli.html#--config-precedence
    config_precedence = "prefer-file", -- or "cli-override" or "file-override"
  },
})
```

_**Note**:_

- _You can only use `prettier.nvim` with `vim.lsp.*` methods if prettier config file is present in your project directory._
- _Supported version of `prettierd` is `0.23.3+`._

## Setup without LSP

If you don't want to do LSP setup, and just use Prettier:

**Keybindings**

```vim
" formatting in normal mode
nmap <Leader>f <Plug>(prettier-format)

" range_formatting in visual mode
xmap <Leader>f <Plug>(prettier-format)
```

**Commands**

`:Prettier` command will format the current buffer.

## License

Licensed under the MIT License. Check the [LICENSE](./LICENSE) file for details.
