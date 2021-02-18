if exists('g:loaded_vimtree')
  finish
endif
let g:loaded_vimtree = 1

""
" @section Configuration, config
" The plugin is not yet very configurable, unfortunately.
" You can define what keys will be mapped whenever a vim-tree buffer
" is created using the @setting(g:vimtree_mappings)

""
" Mappings for vim-tree buffer.
" Default: @setting(s:default_mappings)
let g:vimtree_mappings =
    \ {
    \   '?':  { 'cmd': 'tree#help()',     'desc': 'show help'    },
    \   '+':  { 'cmd': 'tree#expand()',   'desc': 'expand'       },
    \   '-':  { 'cmd': 'tree#contract()', 'desc': 'contract'     },
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
    \   'zh': { 'cmd': 'tree#hidden()',   'desc': 'prev fold'    }
    \ }

""
" Wether or not to display hidden files by default
" Default: @setting(s:default_hidden)
if !exists('g:vimtree_hidden')
	let g:vimtree_hidden = 0
endif

""
" Ignored patterns. Even toggling hidden won't show 
" files with these patterns
" Default: @setting(s:default_hidden)
if !exists('g:vimtree_ignore')
	let g:vimtree_ignore = [ '.git', '.svn' ]
endif

""
" Let vim-tree handle directories like Netrw
" Default: @setting(s:default_handledirs)
if !exists('g:vimtree_handledirs')
  let g:vimtree_handledirs = 1
endif


""
" @section Commands, commands
" There is a single command @command(Tree)

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

""
" @Setting g:vimtree_handledirs
" If set to true (1) by the user, opening a directory using :e <dir>
" will cause vim-tree to open it instead of Netrw
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
