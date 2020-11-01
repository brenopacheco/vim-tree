if exists('g:loaded_vimtree')
  finish
endif
let g:loaded_vimtree = 1

command -nargs=* Tree call tree#open(<q-args>)
