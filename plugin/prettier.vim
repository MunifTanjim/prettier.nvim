if exists('g:loaded_prettier')
  finish
endif
let g:loaded_prettier = 1

function! s:LSPMethods(...)
  let methods = ["textDocument/formatting", "textDocument/rangeFormatting"]
  return join(methods, "\n")
endfunction

function! s:Format(...)
  if a:0 == 1 && a:1 ==# "textDocument/rangeFormatting"
    lua require("prettier").format("textDocument/rangeFormatting")
  else
    lua require("prettier").format("textDocument/formatting")
  endif
endfunction

command! -nargs=? -range=% -complete=custom,s:LSPMethods Prettier :call <SID>Format(<f-args>)

nnoremap <silent> <Plug>(prettier-format) :Prettier textDocument/formatting<CR>
xnoremap <silent> <Plug>(prettier-format) :Prettier textDocument/rangeFormatting<CR>
