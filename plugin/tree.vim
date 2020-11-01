if exists('g:vim_tree_loaded')
  finish
endif
let g:vim_tree_loaded = 1

command -nargs=* Tree call tree#open(<q-args>)
