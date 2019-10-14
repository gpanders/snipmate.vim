if exists('b:current_syntax')
    finish
endif

if !exists('g:snipmate_nested_syntax')
    let g:snipmate_nested_syntax = 1
endif

let filetype = expand('%:t:r')
if g:snipmate_nested_syntax && filetype !=# '_'
    silent! exe 'syn include @snippetHighlight' . filetype . ' syntax/' . filetype . '.vim'
    unlet! b:current_syntax

    exe 'syn region snippetHighlight' . filetype . ' start="^\t" end="^$" keepend contains=placeHolder,tabStop,snipCommand,@snippetHighlight' . filetype
endif

syn match snipComment '^#.*'
syn match placeHolder '\${\d\+\(:.\{-}\)\=}' contains=snipCommand
syn match tabStop '\$\d\+'
syn match snipCommand '[^\\]`.\{-}`'
syn match snippet '^snippet.*' transparent contains=multiSnipText,snipKeyword
syn match multiSnipText '\S\+ \zs.*' contained
syn match snipKeyword '^snippet'me=s+8 contained
syn match snipError "^[^#s\t].*$"

hi link snipComment   Comment
hi link multiSnipText String
hi link snipKeyword   Keyword
hi link snipComment   Comment
hi link placeHolder   Special
hi link tabStop       Special
hi link snipCommand   String
hi link snipError     Error

let b:current_syntax = 'snippet'
