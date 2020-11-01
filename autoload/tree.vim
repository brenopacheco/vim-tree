" TODO: go down has to be fixed (use realpath)
" TODO: foldexpr not working
" TODO: edit,split,etc,etc
" TODO: next, prev
" TODO: link help to mappings

let s:dir      = getcwd()
let s:level    = 1
let s:cmd      = 'tree'
let s:options = '-F -C --dirsfirst'
let s:regex    = '[^ │─├└]'
let s:maps     = {
      \ '?': 'tree#help()',
      \ 'l': 'tree#expand()',
      \ 'h': 'tree#contract()',
      \ '-': 'tree#up()',
      \ '+': 'tree#down()',
      \ 'q': 'tree#close()',
      \ 'e': 'tree#edit()',
      \ 'v': 'tree#vsplit()',
      \ 's': 'tree#split()',
      \ 't': 'tree#tabedit()',
      \ 'i': 'tree#insert()',
      \ 'c': 'tree#change()',
      \ ']': 'tree#next()',
      \ '[': 'tree#prev()',
      \ }

function! tree#open(dir) abort
  if !empty(a:dir)
    let s:dir = a:dir
  endif
  if !&hidden && &modified
    echohl WarningMsg | echo 'There are unsaved changes.' | echohl NONE
    return
  endif
  call s:open()
endfunction

function tree#close() abort
  call s:close()
endfunction

function tree#up() abort
  let s:dir = system('dirname ' . s:dir)
  call s:close()
  call s:open()
endfunction

function tree#down() abort
  let path = tree#path()
  let s:dir = system('dirname ' . path . '_')
  call s:close()
  call s:open()
endfunction

function tree#expand() abort
  call s:close()
  let s:level = s:level + 1
  call s:open()
endfunction

function tree#contract() abort
  call s:close()
  let s:level = s:level > 1 ? s:level - 1 : 1
  call s:open()
endfunction

function tree#edit() abort
endfunction

function tree#vsplit() abort
endfunction

function tree#split() abort
endfunction

function tree#tabedit() abort
endfunction

function tree#insert() abort
endfunction

function tree#change() abort
endfunction

function tree#next() abort
endfunction

function tree#prev() abort
endfunction

function! tree#help() abort
  echo ' ?   help'
  echo ' l   expand'
  echo ' h   contract'
  echo ' -   up'
  echo ' +   down'
  echo ' q   close'
  echo ' e   edit'
  echo ' v   vsplit'
  echo ' s   split'
  echo ' t   tabedit'
  echo ' i   insert'
  echo ' c   change'
  echo ' ]   next'
  echo ' [   prev'
endfunction


function s:open() abort
  let treecmd = s:cmd . ' ' . s:options 
        \ . ' -L ' . s:level . ' ' . s:dir
  call termopen(treecmd, {'on_exit': {j,d,e -> s:check()}})
  set ft=vimtree
  set foldmethod=expr
  set foldexpr=tree#foldlevel(v:lnum)
  setlocal bufhidden=wipe nowrap foldcolumn=0
  autocmd CursorMoved <buffer> call s:cursormoved()
  for key  in keys(s:maps)
    exec 'noremap <silent><buffer><nowait> ' 
          \ .key . ' :call ' . s:maps[key] . '<CR>'
  endfor
endfunction

function s:close() abort
  bd!
endfunction

function! tree#foldlevel(lnum)
  let line = getline(a:lnum)
  return line =~ '/$'
        \ ? '>'.(strwidth(matchstr(line, '.\{-}\ze'.s:regex)) / 4)
        \ : '='
endfunction

function! tree#path() abort
  let path = ''
  let line = line('.')
  let scol = col('.')
  let col = len(getline('.'))
  call setpos('.', [0, line, col, 0])
  while line > 1
    let c = match(getline(line), ' \zs'.s:regex)
    if c < col
      let part = matchstr(getline(line)[c:], '.*')
      " Handle symlinks.
      let part = substitute(part, ' ->.*', '', '')
      let path = escape(part, '"') . path
      let col = c
    endif
    let line -= 1
  endwhile
  call setpos('.', [0, line('.'), scol, 0])
  return path
endfunction

function! s:cursormoved() abort
  echo tree#path()
endfunction


function! s:check() abort
  if empty(getline(1))
    call s:close()
    call s:open()
  endif
endfunction
