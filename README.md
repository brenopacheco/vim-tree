## vim-tree

This is a very basic "tree" command wrapper, with similar functionality to
Netrw. By calling :Tree the results of the tree command show in the buffer,
from where you can expand/contract the tree, go down into a specific directory
or open/create/rename a file. 

```vim
    :Tree [directory]
```

![vim-tree](./picture.png)

It also supports folds, so you can expand the tree and fold all (zM), opening
up only the branches of interest (zo / zO). 

You can open up help by pressing "?"

![vim-tree](./help.png)

Some mappings are probided by default. You can define which keys you want
to map by overriding the g:vimtree_mappings variable.

```vim
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
```
