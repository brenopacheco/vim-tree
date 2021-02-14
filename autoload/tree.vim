" File: autoload/tree.vim
" Author: brenopacheco
" Description: wrapper for tree command
" Last Modified: 2020-11-02

""
" @section Todo, todo
" 1. add folding to documentation 
" 2. add option to shrink tree-width (for using as a drawer)
" 3. modify code to allow user to spawn multiple trees
" 4. use regex instead of glob for grepping (tree does not have that option)
" -> an alternative to using tree directly is to pipe "fd" into tree
" -> "fd" doesn't decorate dirs/pipes/sockets, so an -x print... needed
" 5. add rm operation
" 6. add mkdir operation
" 7. do not remove tree when it's out of sight. allow going back
" 8. add command to open as a "project" tree
"    -> when in a git repo, opening tree from any file will set the root
"       to git's root
"    -> tree will be expanded until the file from which the tree was open


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
let s:dir      = ''
let s:level    = 1
let s:cmd      = 'tree'
let s:options = '-F --dirsfirst'
let s:bufname =  "___vimtree___"
let s:hidden  = 1
let s:cd      = 1
let s:oldbuf  = 0

" ==============================================================================
" API

""
" @section Functions, functions
" Available functions for working with vim-tree and binding mappings

""
" @public
" Opens vim-tree in [optional] directory.
" If second argument is given, use it as start expand level
" @default dir=`getcwd()`
function! tree#open(...) abort
    let s:oldbuf = bufnr()
    if a:0 > 0
        if !isdirectory(a:1)
            echohl WarningMsg | echo 'Invalid directory.' | echohl NONE
            return
        endif
        let dirpath = system('realpath ' . a:1)
        let s:dir = substitute(dirpath, '\n', '', 'g')
        if a:0 > 1
            let s:level = a:2
        endif
    else
        let s:dir = getcwd()
    endif
    if !&hidden && &modified
        echohl WarningMsg | echo 'There are unsaved changes.' | echohl NONE
        return
    endif
    if isdirectory(s:dir)
        call s:open()
    endif
endfunction


""
" @public
" Opens tree in git's root directory, expanded
function! tree#open_root() abort
    let root_dir = system('git rev-parse --show-toplevel 2>/dev/null')
    if v:shell_error != 0
        echohl WarningMsg | echo 'Not a git repository.' | echohl NONE
        return
    endif
    let root_dir = substitute(root_dir, '\n', '', '')
    let depth = str2nr(system('fd . -t d ' . root_dir 
        \ . ' | sed "s#' . root_dir . '/##"'
        \ . ' | awk -F"/" "NF > max {max = NF} END {print max}"'))
    call tree#open(root_dir, depth+1)
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
    let s:level = 1
    call s:reopen()
    echo "Tree level: " . s:level
endfunction

""
" @public
" Go down into directory under cursor.
function! tree#down() abort
    let  s:dir = s:pathdir()
    call s:reopen()
    echo "Tree level: " . s:level
endfunction

""
" @public
" Expand tree, increasing -L level in tree command.
function! tree#expand() abort
    let s:level = s:level + 1
    call s:reopen()
    echo "Tree level: " . s:level
endfunction

""
" @public
" Contract tree, decreasing -L level in tree command.
function! tree#contract() abort
    let s:level = s:level > 1 ? s:level - 1 : 1
    call s:reopen()
    echo "Tree level: " . s:level
endfunction

""
" @public
" Edit file under cursor, closing vim-tree.
function! tree#edit() abort
    let path = tree#path()
    exec 'e ' . path
    call s:close()
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
function! tree#touch() abort
    let dir = s:pathdir() . '/'
    let fn = input('Filename: ' . dir)
    call system('touch ' . dir . fn)
    call s:reopen()
endfunction

""
" @public
" Create (mkdir) new directory under path under cursor.
function! tree#mkdir() abort
    let dir = s:pathdir() . '/'
    let fn = input('Dirname: ' . dir)
    call system('mkdir ' . dir . fn)
    call s:reopen()
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
    call s:reopen()
endfunction

""
" @public
" Delete file/directory under cursor
function! tree#delete() abort
    let dir = s:pathdir() . '/'
    let path = tree#path()
    let prompt = 'Remove ' . (isdirectory(path) ? 'directory ' : 'file ' ) 
        \ . path. ' (y/n)?: '
    let fn = input({'prompt': prompt, 'completion': 'custom,tree#yes_no'})
    if fn == 'yes' || fn == 'y'
        echo " -> removing " . path
        echo system('rm -r ' . path)
    else
        echo ' -> cancelled.'
    endif
    call s:reopen()
endfunction

function tree#yes_no(A,L,P)
    return join(['n', 'y'], "\n")
endfunction

""
" @public
" Reopen tree
function! tree#refresh() abort
    call s:reopen()
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
    call s:reopen()
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
" Grep pattern and populate quickfix
function! tree#grep() abort
    call setqflist([])
    exec 'g/' . input("vimgrep /") . 
        \'/caddexpr expand("%") . ":" . line(".") . ":" . tree#path()'
    copen
    set conceallevel=2 concealcursor=nc
    syntax match qfFileName /^[^/]*/ transparent conceal
    wincmd p
    cfirst
endfunction

""
" @public
" Return filename for file/directory under cursor
function! tree#filename() abort
    return matchstr(tree#path(), "\[^/\]\\+\[/\]\\?$")
endfunction

""
" @public
" Apply filter on tree. Uses glob
function! tree#filter() abort
    let pattern = input("glob/")
    let old_opts = s:options
    let s:options = s:options . ' --matchdirs --prune -P "' . pattern . '"'
    call s:reopen()
    let s:options = old_opts
endfunction


""
" @public
" Shows help for mappings
function! tree#help() abort
    for key in keys(g:vimtree_mappings)
        echo ' ' . key . "\t" . g:vimtree_mappings[key].desc
    endfor
endfunction

""
" @public
" Returns the path for file/directory under cursor.
function! tree#path(...) abort
    let line = line('.')
    if a:0 > 0
        let line = a:1
    endif
    let path = ''
    let col = len(getline(line))
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
    return s:dir == '/' ? 
        \ '/' . path : 
        \ s:dir . '/' . path
endfunction

""
" @public
" Function used for defining fold level with `fold-expr`
function! tree#foldlevel(lnum)
    if a:lnum == 1
        return 0
    endif
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
    return (strwidth(matchstr(line, '.*── ')) - 4) / 4
endfunction

""
" @public
" Function used to define fold text using `foldtext`
function! tree#foldtext()
    let line = getline(v:foldstart)
    let lines = v:foldend-v:foldstart
    let length = 69 - strwidth(line) - len(lines)
    return line . repeat(' ', length) . lines . ' #lines'
endfunction

""
" @public
" Returns root directory being used by vim-tree
function! tree#dir() abort
    return s:dir
endfunction

""
" @public
" Toggle showing hidden files
function! tree#hidden() abort
    let s:hidden = !s:hidden
    call s:reopen()
endfunction

""
" @public
" Reopen tree. Used for custom commands
function! tree#reopen() abort
    call s:reopen()
endfunction

" ==============================================================================
" Auxiliary

function! s:open() abort
    call bufadd(s:bufname)
    exec 'noautocmd e ' . s:bufname
    setlocal modifiable
    call append(0, s:results())
    call setpos('.', [0, s:line, s:col, 0])
    for key in keys(g:vimtree_mappings)
        exec 'noremap <silent><buffer><nowait> ' 
            \ . key . ' :call ' . g:vimtree_mappings[key].cmd . '<CR>'
    endfor
    set ft=vimtree
    setlocal nomodifiable 
endfunction



""
" @private
" Closes ___vimtree___ buffer. Try to restore the last buffer into window.
function! s:close() abort
    if bufexists(bufname(s:oldbuf))
        silent exec s:oldbuf . 'b'
    elseif bufname() == '___vimtree___'
        enew
    endif
    silent! bw! ___vimtree___
endfunction


function! s:reopen() abort
    let pos = getpos('.')
    let s:line = pos[1]
    let s:col = pos[2]
    call s:open()
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

function! s:results()
    let cmd = s:cmd . ' ' . s:options 
        \ . ' -L ' . s:level . ' ' . s:dir
    let ignore = ''
    let root      = systemlist('git rev-parse --show-toplevel')[0]
    if v:shell_error == 0
        let gitignore = root . '/.gitignore'
        let filters   = system("grep -hvE '^$|^#' " . gitignore . " | sed 's:/$::' | tr '\n' '\|'")
        let ignore = substitute(filters, '\n', '', 'g')
    endif
    if len(g:vimtree_ignore) > 0
        for pattern in g:vimtree_ignore
            let ignore = ignore . pattern . '|'
        endfor
    endif
    let cmd = cmd . ' -I "' . ignore . '"'
    if s:hidden == 0
        let cmd = cmd . ' -a'
    endif
    return systemlist(cmd)
endfunction

augroup vimtree
    au!
    au Filetype vimtree set foldmethod=expr
    au Filetype vimtree set foldexpr=tree#foldlevel(v:lnum)
    au Filetype vimtree set foldtext=tree#foldtext()
    au Filetype vimtree setlocal fillchars=fold:\ 
    au Filetype vimtree setlocal bufhidden=wipe nowrap 
        \ nobuflisted buftype=nofile noswapfile
    au BufEnter vimtree set nolist
    au BufEnter vimtree set fillchars+=fold:\ 
    au BufEnter vimtree set buftype=vimtree
augroup END
