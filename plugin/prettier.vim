if exists('g:loaded_prettier')
  finish
endif
let g:loaded_prettier = 1

function! s:Format(...)
  if a:0 == 1 && a:1 > 0
    lua require("prettier").format("textDocument/rangeFormatting")
  else
    lua require("prettier").format("textDocument/formatting")
  endif
endfunction

command! -range=% Prettier :call <SID>Format(<range>)

nnoremap <silent> <Plug>(prettier-format) :Prettier textDocument/formatting<CR>
xnoremap <silent> <Plug>(prettier-format) :Prettier textDocument/rangeFormatting<CR>
