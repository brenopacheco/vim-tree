" File: autoload/tree.vim
" Author: brenopacheco
" Description: wrapper for tree command
" Last Modified: 2020-11-02

""
" @section Introduction, intro
" This is a very basic "tree" command wrapper, with similar functionality
" to Netrw. By calling @command(Tree) the results of the tree
" command show in the buffer, from where you can expand/contract
" the tree, go down into a specific directory or open/create/rename
" a file. Some mappings are probided by default.

" ==============================================================================
" Variables

let s:line     = 0
let s:col      = 0
let s:dir      = getcwd()
let s:level    = 1
let s:cmd      = 'tree'
let s:options = '-F --dirsfirst'

" ==============================================================================
" Mappings

""
" @section Configuration, config
" The plugin is not yet very configurable, unfortunately.
" You can define what keys will be mapped whenever a vim-tree buffer
" is created using the @setting(g:vimtree_mappings)

""
" Mappings for vim-tree buffer.
" Default: @setting(s:default_mappings)
let g:vimtree_mappings =
   \ [
   \   { 'key': '?', 'cmd': 'tree#help()',     'desc': 'show help' },
   \   { 'key': 'l', 'cmd': 'tree#expand()',   'desc': 'expand'    },
   \   { 'key': 'h', 'cmd': 'tree#contract()', 'desc': 'contract'  },
   \   { 'key': '-', 'cmd': 'tree#up()',       'desc': 'go up'     },
   \   { 'key': '+', 'cmd': 'tree#down()',     'desc': 'go down'   },
   \   { 'key': 'q', 'cmd': 'tree#close()',    'desc': 'close'     },
   \   { 'key': 'e', 'cmd': 'tree#edit()',     'desc': 'edit'      },
   \   { 'key': 'v', 'cmd': 'tree#vsplit()',   'desc': 'vsplit'    },
   \   { 'key': 's', 'cmd': 'tree#split()',    'desc': 'split'     },
   \   { 'key': 't', 'cmd': 'tree#tabedit()',  'desc': 'tabnew'    },
   \   { 'key': 'i', 'cmd': 'tree#insert()',   'desc': 'insert'    },
   \   { 'key': 'r', 'cmd': 'tree#rename()',   'desc': 'rename'    },
   \   { 'key': ']', 'cmd': 'tree#next()',     'desc': 'next fold' },
   \   { 'key': '[', 'cmd': 'tree#prev()',     'desc': 'prev fold' }
   \ ]

" ==============================================================================
" API

""
" @section Functions, functions
" Available functions for working with vim-tree and binding mappings

""
" @public
" Opens vim-tree in [optional]
" @default dir=`getcwd()`
function! tree#open(...) abort
  if a:0 > 0
    let s:dir = a:0
  else
    let s:dir = getcwd()
  endif
  if !&hidden && &modified
    echohl WarningMsg | echo 'There are unsaved changes.' | echohl NONE
    return
  endif
  call s:open()
endfunction

""
" @public
" Closes vim-tree
function! tree#close() abort
  call s:close()
endfunction

""
" @public
" Goes up one directory from root.
function! tree#up() abort
  let s:dir = system('dirname ' . s:dir)
  let s:dir = substitute(s:dir, '\n', '', 'g')
  call s:close()
  call s:open()
endfunction

""
" @public
" Go down into directory under cursor.
function! tree#down() abort
  let  s:dir = s:pathdir()
  call s:close()
  call s:open()
endfunction

""
" @public
" Expand tree, increasing -L level in tree command.
function! tree#expand() abort
  call s:close()
  let s:level = s:level + 1
  call s:open()
endfunction

""
" @public
" Contract tree, decreasing -L level in tree command.
function! tree#contract() abort
  call s:close()
  let s:level = s:level > 1 ? s:level - 1 : 1
  call s:open()
endfunction

""
" @public
" Edit file under cursor, closing vim-tree.
function! tree#edit() abort
  let path = tree#path()
  call s:close()
  exec 'e ' . path
endfunction

""
" @public
" Edit file under cursor in a vertical split.
function! tree#vsplit() abort
  let path = tree#path()
  exec 'vsp ' . path
endfunction

""
" @public
" Edit file under cursor in a horizontal split.
function! tree#split() abort
  let path = tree#path()
  exec 'sp ' . path
endfunction

""
" @public
" Edit file under cursor in a new tab.
function! tree#tabedit() abort
  let path = tree#path()
  exec 'tabnew ' . path
endfunction

""
" @public
" Create (touch) new file in the directory under cursor.
function! tree#insert() abort
  let dir = s:pathdir() . '/'
  let fn = input('Filename: ' . dir)
  call system('touch ' . dir . fn)
  call s:close()
  call s:open()
endfunction

""
" @public
" Rename file under cursor
function! tree#rename() abort
  let dir = s:pathdir() . '/'
  let path = tree#path()
  let prompt = 'Rename: ' . path . ' -> '
  let fn = input({'prompt': prompt, 'default': path})
  call system('mv ' . path . ' ' . fn)
  call s:close()
  call s:open()
endfunction

""
" @public
" Jump to next fold
function! tree#next() abort
  norm zj
endfunction

""
" @public
" Jump to previous fold
function! tree#prev() abort
  norm kzkj
endfunction

""
" @public
" Shows help for mappings
function! tree#help() abort
  for mapping in g:vimtree_mappings
    echo ' ' . mapping.key . "\t" . mapping.desc
  endfor
endfunction

""
" @public
" Returns the path for file/directory under cursor.
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
  return s:dir . '/' . path
endfunction

""
" @public
" Function used for defining fold level with `fold-expr`
function! tree#foldlevel(lnum)
    if a:lnum == 1
      return 0
    endif
    " let w0 = tree#foldwidth(a:lnum)
    " let w1 = tree#foldwidth(a:lnum+1)
    let w0 = s:foldwidth(a:lnum)
    let w1 = s:foldwidth(a:lnum+1)
    let diff = w1 - w0
    if diff > 0
      return "a" . diff
    elseif diff < 0
      return "s" . -diff
    else 
      return "="
    endif
endfunction

""
" @public
" function! tree#foldwidth(lnum)
function! s:foldwidth(lnum)
	let line = getline(a:lnum)
	let filtered = substitute(line, '[│ ├└]', ' ', 'g')
    return (match(filtered, '─') + 3) / 4
endfunction

""
" @public
" Function used to define fold text using `foldtext`
function! tree#foldtext()
  let line = getline(v:foldstart)
  let lines = v:foldend-v:foldstart + 1
  let text = line . "\t" . '# '.lines.' lines'
  return text
endfunction

""
" @public
" Returns root directory being used by vim-tree
function! tree#dir() abort
  return s:dir
endfunction

" ==============================================================================
" Auxiliary

function! s:open() abort
  let treecmd = s:cmd . ' ' . s:options 
        \ . ' -L ' . s:level . ' ' . s:dir
  let buffer = bufadd('__vimtree___')
  exec 'norm ' . buffer . 'b'
  call append(0, systemlist(treecmd))
  call setpos('.', [0, s:line, s:col, 0])
  for mapping  in g:vimtree_mappings
    exec 'noremap <silent><buffer><nowait> ' 
          \ . mapping.key . ' :call ' . mapping.cmd . '<CR>'
  endfor
  set ft=vimtree
endfunction

function! s:close() abort
  let pos = getpos('.')
  let s:line = pos[1]
  let s:col = pos[2]
  bd!
endfunction

function s:pathdir() abort
  let path = tree#path()
  let dir = ''
  if match(path, '/$') == -1
    let dir = system('dirname ' . path)
  else
    let dir = substitute(path, '/$', '', '')
  endif
  let dir = substitute(dir, '\n', '', 'g')
  return dir
endfunction

augroup vimtree
  au!
  au Filetype vimtree set foldmethod=expr
  au Filetype vimtree set foldexpr=tree#foldlevel(v:lnum)
  au Filetype vimtree set foldtext=tree#foldtext()
  au Filetype vimtree setlocal fillchars=fold:\ 
  au Filetype vimtree setlocal bufhidden=wipe nowrap foldcolumn=0 readonly buflisted
  " au Filetype vimtree au CursorMoved <buffer> :echo tree#info()
augroup END
