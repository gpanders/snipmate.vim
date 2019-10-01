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
    autocmd FileType * if &filetype !=# 'help' | call GetSnippets(g:snippets_dir, &filetype) | endif
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
    let g:snippets_dir = substitute(globpath(&runtimepath, 'snippets/'), "\n", ',', 'g')
endif

function! s:MakeSnip(scope, trigger, content, ...)
    let multisnip = a:0 && a:1 !=# ''
    let var = multisnip ? 'g:snipmate_multi_snips' : 'g:snipmate_snippets'
    if !has_key({var}, a:scope) | let {var}[a:scope] = {} | endif
    if !has_key({var}[a:scope], a:trigger)
        let {var}[a:scope][a:trigger] = multisnip ? [[a:1, a:content]] : a:content
    elseif multisnip | let {var}[a:scope][a:trigger] += [[a:1, a:content]]
    else
        echom 'Warning in snipmate.vim: Snippet ' . a:trigger . ' is already defined.'
                    \ .' See :h multi_snip for help on snippets with multiple matches.'
    endif
endfunction

function! s:ExtractSnips(dir, ft)
    for path in split(globpath(a:dir, '*'), "\n")
        if isdirectory(path)
            let pathname = fnamemodify(path, ':t')
            for snipFile in split(globpath(path, '*.snippet'), "\n")
                call s:ProcessFile(snipFile, a:ft, pathname)
            endfor
        elseif fnamemodify(path, ':e') ==# 'snippet'
            call s:ProcessFile(path, a:ft)
        endif
    endfor
endfunction

" Processes a single-snippet file; optionally add the name of the parent
" directory for a snippet with multiple matches.
function! s:ProcessFile(file, ft, ...)
    let keyword = fnamemodify(a:file, ':t:r')
    if keyword  ==# '' | return | endif
    try
        let text = join(readfile(a:file), "\n")
    catch /E484/
        echom "Error in snipmate.vim: couldn't read file: " . a:file
    endtry
    return a:0 ? s:MakeSnip(a:ft, a:1, text, keyword)
                \  : s:MakeSnip(a:ft, keyword, text)
endfunction

function! s:ExtractSnipsFile(file, ft)
    if !filereadable(a:file) | return | endif
    let text = readfile(a:file)
    let inSnip = 0
    for line in text + ["\n"]
        if inSnip && (line[0] ==# "\t" || line ==# '')
            let content .= strpart(line, 1) . "\n"
            continue
        elseif inSnip
            call s:MakeSnip(a:ft, trigger, content[:-2], name)
            let inSnip = 0
        endif

        if line[:6] ==# 'snippet'
            let inSnip = 1
            let trigger = strpart(line, 8)
            let name = ''
            let space = stridx(trigger, ' ') + 1
            if space " Process multi snip
                let name = strpart(trigger, space)
                let trigger = strpart(trigger, 0, space - 1)
            endif
            let content = ''
        endif
    endfor
endfunction

" Reset snippets for filetype.
function! ResetSnippets(ft)
    let ft = a:ft ==# '' ? '_' : a:ft
    for dict in [g:snipmate_snippets, g:snipmate_multi_snips, g:snipmate_did_ft]
        if has_key(dict, ft)
            unlet dict[ft]
        endif
    endfor
endfunction

" Reset snippets for all filetypes.
function! ResetAllSnippets()
    let g:snipmate_snippets = {} | let g:snipmate_multi_snips = {} | let g:snipmate_did_ft = {}
endfunction

" Reload snippets for filetype.
function! ReloadSnippets(ft)
    let ft = a:ft ==# '' ? '_' : a:ft
    call snipmate#util#ResetSnippets(ft)
    call GetSnippets(g:snippets_dir, ft)
endfunction

" Reload snippets for all filetypes.
function! ReloadAllSnippets()
    for ft in keys(g:snipmate_did_ft)
        call snipmate#util#ReloadSnippets(ft)
    endfor
endfunction

function! GetSnippets(dir, filetypes)
    for ft in split(a:filetypes, '\.')
        if has_key(g:snipmate_did_ft, ft) | continue | endif
        call s:DefineSnips(a:dir, ft, ft)
        if ft ==# 'objc' || ft ==# 'cpp' || ft ==# 'cs'
            call s:DefineSnips(a:dir, 'c', ft)
        elseif ft ==# 'xhtml'
            call s:DefineSnips(a:dir, 'html', 'xhtml')
        endif
        let g:snipmate_did_ft[ft] = 1
    endfor
endfunction

" Define "aliasft" snippets for the filetype "realft".
function! s:DefineSnips(dir, aliasft, realft)
    for path in split(globpath(a:dir, a:aliasft . '/') . "\n".
                \ globpath(a:dir, a:aliasft . '-*/'), "\n")
        call s:ExtractSnips(path, a:realft)
    endfor
    for path in split(globpath(a:dir, a:aliasft . '.snippets') . "\n".
                \ globpath(a:dir, a:aliasft . '-*.snippets'), "\n")
        call s:ExtractSnipsFile(path, a:realft)
    endfor
endfunction

call GetSnippets(g:snippets_dir, '_') " Get global snippets
