if exists('b:did_filetype')
    finish
endif
let b:did_filetype = 1

setlocal foldmethod=indent

let b:undo_ftplugin = 'setl fdm<'
