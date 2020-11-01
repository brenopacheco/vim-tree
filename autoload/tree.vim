" TODO: syntax highlight
" TODO: go down has to be fixed (use realpath)
" TODO: edit,split,etc,etc
" TODO: next, prev
" TODO: link help to mappings
"


let s:line     = 0
let s:col      = 0
let s:dir      = getcwd()
let s:level    = 1
let s:cmd      = 'tree'
let s:options = '-F --dirsfirst'
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

function! tree#close() abort
  call s:close()
endfunction

function! tree#up() abort
  let s:dir = system('dirname ' . s:dir)
  call s:close()
  call s:open()
endfunction

function! tree#down() abort
  let path = tree#path()
  let s:dir = system('dirname ' . path . '_')
  call s:close()
  call s:open()
endfunction

function! tree#expand() abort
  call s:close()
  let s:level = s:level + 1
  call s:open()
endfunction

function! tree#contract() abort
  call s:close()
  let s:level = s:level > 1 ? s:level - 1 : 1
  call s:open()
endfunction

function! tree#edit() abort
endfunction

function! tree#vsplit() abort
endfunction

function! tree#split() abort
endfunction

function! tree#tabedit() abort
endfunction

function! tree#insert() abort
endfunction

function! tree#change() abort
endfunction

function! tree#next() abort
endfunction

function! tree#prev() abort
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


function! tree#path() abort
  let path = ''
  let line = line('.')
  let scol = col('.')
  let col = len(getline('.'))
  call setpos('.', [0, line, col, 0])
  while line > 1
    let c = match(getline(line), ' \zs[^ │─├└]')
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

function! tree#foldlevel(lnum)
    if a:lnum == 1
      return 0
    endif
    let w0 = tree#foldwidth(a:lnum)
    let w1 = tree#foldwidth(a:lnum+1)
    let diff = w1 - w0
    if diff > 0
      return "a" . diff
    elseif diff < 0
      return "s" . -diff
    else 
      return "="
    endif
endfunction

function! tree#foldwidth(lnum)
	let line = getline(a:lnum)
	let filtered = substitute(line, '[│ ├└]', ' ', 'g')
    return (match(filtered, '─') + 3) / 4
endfunction

function! tree#foldtext()
  let line = getline(v:foldstart)
  let sub = substitute(line, '/\*\|\*/\|{{{\d\=', '', 'g')
  let lines = v:foldend-v:foldstart + 1
  let text = line . ' # '.lines.' lines'
  return text
endfunction

function! tree#info() abort
  let info = 
        \ 'path:   ' . tree#path()
        \ . "\t" . 'tlevel: ' . tree#foldlevel(line('.'))
        \ . "\t" . 'level:  ' . foldlevel(line('.'))
        \ . "\t" . 'width:  ' . tree#foldwidth(line('.'))
  return info
endfunction


function! s:open() abort
  let treecmd = s:cmd . ' ' . s:options 
        \ . ' -L ' . s:level . ' ' . s:dir
  let buffer = bufadd('__vimtree___')
  exec 'norm ' . buffer . 'b'
  call append(0, systemlist(treecmd))
  call setpos('.', [0, s:line, s:col, 0])
  for key  in keys(s:maps)
    exec 'noremap <silent><buffer><nowait> ' 
          \ .key . ' :call ' . s:maps[key] . '<CR>'
  endfor
  set ft=vimtree
endfunction

function! s:close() abort
  let pos = getpos('.')
  let line = pos[1]
  let col = pos[2]
  bd!
endfunction

augroup vimtree
  au!
  au Filetype vimtree set foldmethod=expr
  au Filetype vimtree set foldexpr=tree#foldlevel(v:lnum)
  au Filetype vimtree set foldtext=tree#foldtext()
  au Filetype vimtree setlocal fillchars=fold:\ 
  au Filetype vimtree setlocal bufhidden=wipe nowrap foldcolumn=0
  au Filetype vimtree au CursorMoved <buffer> :echo tree#info()
augroup END

