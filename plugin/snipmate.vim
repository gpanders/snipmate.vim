" File:          snipmate.vim
" Author:        Michael Sanders
" Version:       0.84
" Description:   snipmate.vim implements some of TextMate's snippets features in
"                Vim. A snippet is a piece of often-typed text that you can
"                insert into your document using a trigger word followed by a "<Tab>".
"
"                For more help see snipmate.txt; you can do this by using:
"                :helptags ~/.vim/doc
"                :h snipmate.txt

if exists('g:loaded_snips') || &compatible || v:version < 700
    finish
endif
let g:loaded_snips = 1
if !exists('g:snips_author') | let g:snips_author = 'Me' | endif

augroup snipmate
    autocmd!
    autocmd BufRead,BufNewFile *.snippets\= set filetype=snippet
    autocmd FileType * if &filetype !=# 'help' | call snipmate#util#GetSnippets(g:snippets_dir, &filetype) | endif
augroup END

inoremap <silent> <Tab> <C-R>=snipmate#snips#TriggerSnippet()<CR>
snoremap <silent> <Tab> <Esc>i<right><C-R>=snipmate#snips#TriggerSnippet()<CR>
inoremap <silent> <S-Tab> <C-R>=snipmate#snips#BackwardsSnippet()<CR>
snoremap <silent> <S-Tab> <Esc>i<right><C-R>=snipmate#snips#BackwardsSnippet()<CR>
inoremap <silent> <C-R><Tab> <C-R>=snipmate#snips#ShowAvailableSnips()<CR>

" The default mappings for these are annoying & sometimes break snipmate.
" You can change them back if you want, I've put them here for convenience.
snoremap <BS> b<BS>
snoremap <Right> <Esc>a
snoremap <Left> <Esc>bi
snoremap ' b<BS>'
snoremap ` b<BS>`
snoremap % b<BS>%
snoremap U b<BS>U
snoremap ^ b<BS>^
snoremap \ b<BS>\
snoremap <C-X> b<BS><C-X>

let g:snipmate_did_ft = {}
let g:snipmate_snippets = {}
let g:snipmate_multi_snips = {}

if !exists('g:snippets_dir')
    let g:snippets_dir = join(globpath(&runtimepath, 'snippets/', 0, 1), ',')
endif

command! -nargs=? SnipMateReset if !empty('<args>') | call snipmate#util#ResetSnippets('<args>') | else | call snipmate#util#ResetAllSnippets() | endif
command! -nargs=? SnipMateReload if !empty('<args>') | call snipmate#util#ReloadSnippets('<args>') | else | call snipmate#util#ReloadAllSnippets() | endif

call snipmate#util#GetSnippets(g:snippets_dir, '_') " Get global snippets
