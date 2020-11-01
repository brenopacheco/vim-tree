
syn match root   '^[./]\S\+'
syn match dir    '.\+\/$'
syn match source '\S\+\.\S\+$'
syn match pipe   '\S\+|$'
syn match socket '\S\+=$'

hi def link root      EndOfBuffer
hi def link dir       EndOfBuffer
hi def link source    Type
hi def link pipe      LineNr
hi def link socket    SpecialKey


