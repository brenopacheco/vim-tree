if exists('g:loaded_vimtree')
  finish
endif
let g:loaded_vimtree = 1

""
" @section Configuration, config
" The plugin is not yet very configurable, unfortunately.

""
" Mappings inside the vim-tree buffer.
let g:vimtree_mappings = get(g:, 'vimtree_mappings',
        \ {
        \   '?':  { 'cmd': 'tree#help()',     'desc': 'show help'    },
        \   '+':  { 'cmd': 'tree#expand()',   'desc': 'expand'       },
        \   '-':  { 'cmd': 'tree#collapse()', 'desc': 'collapse'     },
        \   'h':  { 'cmd': 'tree#up()',       'desc': 'go up'        },
        \   'l':  { 'cmd': 'tree#down()',     'desc': 'go down'      },
        \   'q':  { 'cmd': 'tree#close()',    'desc': 'close'        },
        \   'e':  { 'cmd': 'tree#edit()',     'desc': 'edit'         },
        \   'v':  { 'cmd': 'tree#vsplit()',   'desc': 'vsplit'       },
        \   's':  { 'cmd': 'tree#split()',    'desc': 'split'        },
        \   't':  { 'cmd': 'tree#tabedit()',  'desc': 'tabnew'       },
        \   'i':  { 'cmd': 'tree#touch()',    'desc': 'insert/touch' },
        \   'D':  { 'cmd': 'tree#delete()',   'desc': 'delete'       },
        \   'r':  { 'cmd': 'tree#rename()',   'desc': 'rename'       },
        \   'm':  { 'cmd': 'tree#mkdir()',    'desc': 'mkdir'        },
        \   'R':  { 'cmd': 'tree#refresh()',  'desc': 'refresh'      },
        \   '}':  { 'cmd': 'tree#next()',     'desc': 'next fold'    },
        \   '{':  { 'cmd': 'tree#prev()',     'desc': 'prev fold'    },
        \   '*':  { 'cmd': 'tree#grep()',     'desc': 'grep'         },
        \   'f':  { 'cmd': 'tree#filter()',   'desc': 'filter'       },
        \   'zh': { 'cmd': 'tree#hidden()',   'desc': 'toggle hidden'}
        \ })

""
" Display hidden files by default
"
" > default: 0
let g:vimtree_hidden = get(g:, 'vimtree_hidden', 0)

""
" Fold level to assign to the window when jumping up and down directories.
" Setting it to 0 will make all branches folded and 99 will make it unfolded.
"
" > default: -1 (do not assign fold level)
let g:vimtree_fold_level = get(g:, 'vimtree_fold_level',  -1)

""
" Ignored patterns. Even toggling hidden won't show 
" files with these patterns
"
" > default: [ '.git', '.svn' ]
let g:vimtree_ignore = get(g:, 'vimtree_ignore',  [ '.git', '.svn' ])

""
" Let vim-tree handle directories like Netrw
" If set to true (1) by the user, opening a directory using :e <dir>
" will cause vim-tree to open it instead of Netrw
"
" > default: 1
let g:vimtree_handledirs = get(g:, 'vimtree_handledirs',  1)

""
" @section Commands, commands

""
" Opens up vim-tree in [directory]
" @default directory=`getcwd()`
command -complete=dir -nargs=? Tree call tree#open(<f-args>)

""
" Opens up a vim-tree in [directory] with a vertical split
" @default directory=`getcwd()`
command -complete=dir -nargs=? VTree vsp | call tree#open(<f-args>)

""
" Opens up vim-tree in a git project's root directory.
" The tree opens expanded and unfolded
" @default directory=`getcwd()`
command GTree call tree#open_root()

if g:vimtree_handledirs
  augroup vimtree_handledirs
    autocmd VimEnter * silent! autocmd! FileExplorer
    au BufEnter,VimEnter * call s:handledir(expand('<amatch>'))
  augroup END
endif

function s:handledir(dir) abort
    if a:dir == '' || !isdirectory(a:dir)
        return
    endif
    call tree#open(a:dir)
endfunction
