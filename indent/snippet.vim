if exists('b:did_indent')
    finish
endif
let b:did_indent = 1

setlocal noexpandtab

let b:undo_indent = 'setl et<'
