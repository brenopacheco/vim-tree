" TODO: foldexpr
" get cursor file
" get cursor dir
" go up/down

if exists('g:vim_tree_loaded')
  finish
end
let g:vim_tree_loaded = 1

let s:dir   = ''
let s:level = 1
let s:cmd   = ''

let s:maps = {
      \ 'l': 'tree#expand()',
      \ 'h': 'tree#contract()',
      \ '+': 'tree#up()',
      \ '-': 'tree#down()',
      \ 'q': 'tree#close()',
      \ }

function tree#open() abort
  let s:dir = execute('pwd')[1:-1]
  call s:open()
endfunction

function tree#close() abort
  call s:close()
endfunction

function tree#up() abort
  call s:close()
  let cur_dir = execute('pwd')[1:-1]
  exec 'cd ' . s:dir
  cd ../
  let s:dir = execute('pwd')[1:-1]
  exec 'cd ' . cur_dir
  call s:open()
endfunction

function tree#down() abort
endfunction

function tree#expand() abort
  echo "expand"
  call s:close()
  let s:level = s:level + 1
  call s:open()
endfunction

function tree#contract() abort
  echo "contract"
  call s:close()
  let s:level = s:level > 1 ? s:level - 1 : 1
  call s:open()
endfunction

function s:open() abort
  echo "open"
  call s:updatecmd()
  exec 'term ' . s:cmd
  set ft=vimtree
  for key  in keys(s:maps)
    exec 'silent map '     .key . ' :call ' . s:maps[key] . '<CR>'
    exec 'silent noremap ' .key . ' :call ' . s:maps[key] . '<CR>'
    exec 'silent nnoremap '.key . ' :call ' . s:maps[key] . '<CR>'
    exec 'silent map <buffer> '     .key . ' :call ' . s:maps[key] . '<CR>'
    exec 'silent noremap <buffer> ' .key . ' :call ' . s:maps[key] . '<CR>'
    exec 'silent nnoremap <buffer> '.key . ' :call ' . s:maps[key] . '<CR>'
  endfor
endfunction

function s:close() abort
  echo "close"
  bd!
endfunction

" function s:cursor() abort
" endfunction

function s:updatecmd() abort
  let s:cmd = 'tree -C -L ' . s:level . ' ' . s:dir
endfunction
