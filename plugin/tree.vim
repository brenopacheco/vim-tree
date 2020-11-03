if exists('g:loaded_vimtree')
  finish
endif
let g:loaded_vimtree = 1

""
" @section Commands, commands
" There is a single command @command(Tree)

""
" Opens up vim-tree in [directory]
" @default directory=`getcwd()`
command -complete=dir -nargs=? Tree call tree#open(<f-args>)


if !exists('g:vimtree_handledirs')
  let g:vimtree_handledirs = 1
endif

""
" @Setting g:vimtree_handledirs
" If set to true (1) by the user, opening a directory using :e <dir>
" will cause vim-tree to open it instead of Netrw
if g:vimtree_handledirs
  augroup vimtree_handledirs
    autocmd VimEnter * silent! autocmd! FileExplorer
    au BufEnter,VimEnter * call tree#open(expand('<amatch>'))
  augroup END
endif
