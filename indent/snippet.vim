if exists('b:did_indent')
    finish
endif
let b:did_indent = 1

setlocal noexpandtab
setlocal shiftwidth=8
setlocal softtabstop=8

let b:undo_indent = 'setl et<'
