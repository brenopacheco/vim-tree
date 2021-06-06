" File: autoload/tree.vim
" Author: brenopacheco
" Description: wrapper for tree command
" Last Modified: 2020-11-02
scriptencoding

""
" @section Introduction, intro
" This is a very basic "tree" command wrapper, with similar functionality
" to Netrw. By calling @command(Tree) the results of the tree
" command is shown in the buffer. From there, you can expand/collapse
" the tree, go down into a specific directory or open/create/rename/delete
" a file or directory. You can grep for entries, toggle show hidden files.
" You can open the tree in the current buffer or in a split, in the current
" file's directory, in a specific directory or in the root directory of a git
" project. A command for opening tree as drawer is also given.
"
" Some mappings are probided by default.

" ==============================================================================
" Variables

let s:line     = 0
let s:col      = 0
let s:dir      = ''
let s:level    = 1
let s:cmd      = 'tree'
let s:options = '-F --dirsfirst'
let s:bufname =  '___vimtree___'
let s:hidden  = 1
let s:cd      = 1
let s:oldbufs = {}
let s:mappings = {}
let s:bufcount = 0

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
    if a:0 > 0
        if !isdirectory(a:1)
            echohl WarningMsg | echo 'Invalid directory.' | echohl NONE
            return v:false
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
        return v:false
    endif
    let s:hidden = !g:vimtree_hidden
    if isdirectory(s:dir)
        call s:open(v:false)
    endif
    silent let goto_line = tree#locate(expand('#'.bufnr('#').':p'))
    if goto_line ==# v:false
        call setpos('.', [0, goto_line, 1, 0])
    endif
    return v:true
endfunction


""
" @public
" Opens tree in git's root directory, expanded
function! tree#open_root() abort
    let root_dir = system('git rev-parse --show-toplevel 2>/dev/null')
    if v:shell_error != 0
        echohl WarningMsg | echo 'Not a git repository.' | echohl NONE
        return v:false
    endif
    let root_dir = substitute(root_dir, '\n', '', '')
    let depth = str2nr(system('fd . -t d ' . root_dir 
        \ . ' | sed "s#' . root_dir . '/##"'
        \ . ' | awk -F"/" "NF > max {max = NF} END {print max}"'))
    return tree#open(root_dir, depth+1)
endfunction

""
" @public
" Opens tree as sidebar pane.
fun! tree#open_sidebar() abort
    leftabove 30vsp
    setlocal winfixheight winfixwidth
    silent let open = tree#open_root() || tree#open()
    if !open
        close
        return v:false
    endif
    let mappings = deepcopy(g:vimtree_mappings)
    let mappings['e']['cmd'] = 'tree#editright()'
    call tree#reset_keys(mappings)
    augroup vimtree_sidebar
        au!
        au WinLeave <buffer> vertical resize 30
    augroup end
endf

""
" @public
" Closes vim-tree. Can only be called when inside a _vimtree_ buffer.
function! tree#close() abort
    call s:close(bufnr())
endfunction

""
" @public
" Goes up one directory from root.
function! tree#up() abort
    let s:dir = system('dirname ' . s:dir)
    let s:dir = substitute(s:dir, '\n', '', 'g')
    " let s:level = 1
    call tree#refresh()
    echo 'Tree level: ' . s:level
endfunction

""
" @public
" Go down into directory under cursor.
function! tree#down() abort
    let  s:dir = s:pathdir()
    call tree#refresh()
    echo 'Tree level: ' . s:level
endfunction

""
" @public
" Expand tree, increasing -L level in tree command.
function! tree#expand() abort
    let s:level = s:level + 1
    call tree#refresh()
    echo 'Tree level: ' . s:level
endfunction

""
" @public
" collapse tree, decreasing -L level in tree command.
function! tree#collapse() abort
    let s:level = s:level > 1 ? s:level - 1 : 1
    call tree#refresh()
    echo 'Tree level: ' . s:level
endfunction

""
" @public
" Edit file under cursor, closing vim-tree.
function! tree#edit() abort
    exec 'e ' . tree#path()
endfunction

""
" @public
" Edit file under cursor by replacing the window to the right with it.
function! tree#editright() abort
    let path = tree#path()
    exe "norm! \<c-w>w"
    if s:is_tree()
        vsp
    endif
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
function! tree#touch() abort
    let dir = s:pathdir() . '/'
    let fn = input('Filename: ' . dir)
    call system('touch ' . dir . fn)
    call tree#refresh()
endfunction

""
" @public
" Create (mkdir) new directory under path under cursor.
function! tree#mkdir() abort
    let dir = s:pathdir() . '/'
    let fn = input('Dirname: ' . dir)
    call system('mkdir ' . dir . fn)
    call tree#refresh()
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
    call tree#refresh()
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
    if fn ==? 'yes' || fn ==? 'y'
        echo ' -> removing ' . path
        echo system('rm -r ' . path)
    else
        echo ' -> cancelled.'
    endif
    call tree#refresh()
endfunction

function tree#yes_no(A,L,P)
    return join(['n', 'y'], "\n")
endfunction

""
" @public
" Refresh tree contents. Can only be used inside a _vimtree_ buffer.
function! tree#refresh() abort
    if !s:is_tree()
        echohl WarningMsg | echomsg 'Not a vimtree buffer' | echohl NONE
        return v:false
    endif
    call s:reopen(bufnr())
endfunction

""
" @public
" Jump to next fold
function! tree#next() abort
    norm! zj
endfunction

""
" @public
" Jump to previous fold
function! tree#prev() abort
    norm! kzkj
endfunction

""
" @public
" Apply vimgrep to the tree.
function! tree#grep() abort
    call setqflist([])
    exec 'g/' . input('vimgrep /') . 
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
" Apply a filter on tree. Uses glob pattern. Tree doesn't provide regex option
function! tree#glob() abort
    let pattern = input('glob/')
    let old_opts = s:options
    let s:options = s:options . ' --matchdirs --prune -P "' . pattern . '"'
    call tree#refresh()
    let s:options = old_opts
endfunction


""
" @public
" Shows help for mappings based on vimtree mappings
function! tree#help() abort
    for key in keys(s:mappings)
        let desc = s:mappings[key].desc
        let cmd = s:mappings[key].cmd
        echo printf('%-8s%-20s%30s', key, desc, cmd)
    endfor
endfunction

""
" @public
" Returns the path for file/directory under cursor. A line number
" may be given as argument.
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
            let part = matchstr(getline(line)[c :], '.*')
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
" Returns root directory being used by vim-tree
function! tree#dir() abort
    return s:dir
endfunction

""
" @public
" Toggle showing hidden files
function! tree#hidden() abort
    let s:hidden = !s:hidden
    call tree#refresh()
endfunction

""
" @public
" Return the line number in the current _vimtree_ buffer for a given path
" [optional] file path
fun! tree#locate(path)
    let old_pos = getpos('.')
    try
        call setpos('.', [0, 1, 1, 0])
        if bufname() !=# s:bufname
            throw 'Not a tree buffer.'
        endif
        let base_path = getline(1)
        let rel_path = substitute(a:path, '^' . base_path . '/', '', '')
        let leafs = split(rel_path, '\/')
        let level = 0
        let lnum = 1
        for leaf in leafs
            while v:true
                let lnum = search(leaf)
                if lnum == 0
                    throw 'Path not found.'
                endif
                let cur_level = s:foldwidth(lnum)
                if cur_level ==# level
                    break
                endif
            endwhile
            let level = level + 1
        endfor
        if tree#path(lnum) !=# a:path
            throw 'Path does not match.'
        endif
        return lnum
    catch /.*/
        call setpos('.', old_pos)
        echohl WarningMsg | echomsg v:exception | echohl NONE
        return v:false
    endtry
endf

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
        return 'a' . diff
    elseif diff < 0
        return 's' . -diff
    else 
        return '='
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

" ==============================================================================
" Auxiliary

""
" @private
" Creates a new _vimtree_ buffer
function! s:open(bufnr) abort
    let bufname = ''
    if a:bufnr
        let bufname = bufname(a:bufnr)
    else
        let bufname = s:new_buffer_name()
        echomsg bufname
        let s:oldbufs[bufname] = bufnr()
        call bufadd(bufname)
    endif
    exec 'noautocmd e ' . bufname
    setlocal modifiable
    1,$d
    call append(0, s:results())
    call setpos('.', [0, s:line, s:col, 0])
    if !s:is_tree()
        call tree#reset_keys(g:vimtree_mappings)
    endif
    set ft=vimtree
    setlocal nomodifiable 
    let b:vimtree = v:true
endfunction

fun! tree#reset_keys(mappings)
    for key in keys(s:mappings)
        silent! exec 'nunmap <buffer> ' . key
    endfor
    let s:mappings = a:mappings
    for key in keys(s:mappings)
        exec 'noremap <silent><buffer><nowait> ' 
            \ . key . ' :call ' . s:mappings[key].cmd . '<CR>'
    endfor
endf

""
" @private
" Closes _vimtree_ buffer. Try to restore the last buffer into window.
" Avoids closing last window in the tab.
function! s:close(bufnr) abort
    let oldbuf = s:oldbufs[bufname(a:bufnr)]
    if bufexists(oldbuf)
        exec oldbuf . 'b'
    elseif len(tabpagebuflist()) == 1
        enew
    else
        close
    endif
endfunction

""
" @private
" Reopens a vimtree buffer. Must be given the number of the buffer.
function! s:reopen(bufnr) abort
    let pos = getpos('.')
    let s:line = pos[1]
    let s:col = pos[2]
    call s:open(a:bufnr)
endfunction

""
" @private
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


""
" @private
" This is the meat of the plugin. s:results constructs the tree command
" and returns a list of results. We add the options and some filters based
" on .gitignore file on the root of the directory. Needs refactoring
function! s:results()
    let cmd    = s:cmd . ' ' . s:options . ' -L ' . s:level . ' ' . s:dir
    let ignore = ''
    let root   = systemlist('git rev-parse --show-toplevel')[0]
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

""
" @private
" Generates an unique hash
fun! s:new_buffer_name()
    let s:bufcount = s:bufcount + 1
    return s:bufname . s:bufcount
endf

""
" @private
" Returns v:true if current buffer is a _vimtree_buffer
fun! s:is_tree()
    return exists('b:vimtree')
endf

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
