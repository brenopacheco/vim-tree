if exists('g:loaded_vimtree')
  finish
endif
let g:loaded_vimtree = 1

""
" @section Commands, commands
" There is a single command, @command(Tree)

""
" Opens up vim-tree in [directory]
" @default directory=getcwd()
command -nargs=? Tree call tree#open(<f-args>)
