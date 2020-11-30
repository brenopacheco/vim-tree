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

""
" Opens up a vim-tree in [directory] with a vertical split
" @default directory=`getcwd()`
command -complete=dir -nargs=? VTree vsp | call tree#open(<f-args>)

""
" Opens up vim-tree in a git project's root directory.
" The tree opens expanded and unfolded
" @default directory=`getcwd()`
command GTree call tree#open_root(<f-args>)

""
" Ignored patterns. Even toggling hidden won't show 
" files with these patterns
if !exists('g:vimtree_ignore')
	let g:vimtree_ignore = [ '.git', '.svn' ]
endif

""
" Let vim-tree handle directories like Netrw
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
    au BufEnter,VimEnter * call s:handledir(expand('<amatch>'))
  augroup END
endif

function s:handledir(dir) abort
	if a:dir == '' || !isdirectory(a:dir)
		return
	endif
	call tree#open(a:dir)
endfunction
