if exists('g:vim-tree-loaded')
  finish
end
let g:vim-tree-loaded = 1

let s:level = 1
let s:cmd = 'tree -L ' . s:level

let g:maps = {
      \ '+': 'tree#up()',
      \ '-': 'tree#down()'
      \ }

function tree#open() abort
  call s:open()
endfunction

function tree#up() abort
  call s:close()
  let s:level = s:level + 1
  call s:open()
endfunction

function tree#down() abort
  call s:close()
  let s:level = s:level > 1 ? s:level - 1 : 1
  call s:open()
endfunction

function s:open() abort
  exec 'term s:cmd'
  set ft=vimtree
  for key  in keys(s:maps)
    echo 'nnoremap <buffer> ' . key . ' ' . s:maps[key] . '<CR>'
    exec 'nnoremap <buffer> ' . key . ' ' . s:maps[key] . '<CR>'
  endfor
endfunction

function s:close() abort
  norm a<CR>
endfunction
