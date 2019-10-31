" Processes a single-snippet file; optionally add the name of the parent
" directory for a snippet with multiple matches.
function! s:ProcessFile(file, ft, ...)
    let keyword = fnamemodify(a:file, ':t:r')
    if keyword  ==# ''
        return
    endif
    try
        let text = join(readfile(a:file), "\n")
    catch /E484/
        echom "Error in snipmate.vim: couldn't read file: " . a:file
    endtry
    return a:0 ? s:MakeSnip(a:ft, a:1, text, keyword)
                \  : s:MakeSnip(a:ft, keyword, text)
endfunction

" Define "aliasft" snippets for the filetype "realft".
function! s:DefineSnips(dir, aliasft, realft)
    for path in globpath(a:dir, a:aliasft . '/', 0, 1) + globpath(a:dir, a:aliasft . '-*/', 0, 1)
        call s:ExtractSnips(path, a:realft)
    endfor
    for path in globpath(a:dir, a:aliasft . '.snippets', 0, 1) + globpath(a:dir, a:aliasft . '-*.snippets', 0, 1)
        call s:ExtractSnipsFile(path, a:realft)
    endfor
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

function! s:ExtractSnipsFile(file, ft)
    if !filereadable(a:file)
        return
    endif
    let text = readfile(a:file)
    let inSnip = 0
    let blank = 0
    for line in text + ["\n"]
        if inSnip && line[0] ==# "\t"
            if blank
                let content .= repeat("\n", blank)
                let blank = 0
            endif
            let content .= strpart(line, 1) . "\n"
            continue
        elseif inSnip && line ==# ''
            let blank += 1
            continue
        elseif inSnip
            call s:MakeSnip(a:ft, trigger, content[:-2], name)
            let inSnip = 0
            let blank = 0
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

function! s:MakeSnip(scope, trigger, content, ...)
    let multisnip = a:0 && a:1 !=# ''
    let var = multisnip ? 'g:snipmate_multi_snips' : 'g:snipmate_snippets'
    if !has_key({var}, a:scope)
        let {var}[a:scope] = {}
    endif
    if !has_key({var}[a:scope], a:trigger)
        let {var}[a:scope][a:trigger] = multisnip ? [[a:1, a:content]] : a:content
    elseif multisnip
        let {var}[a:scope][a:trigger] += [[a:1, a:content]]
    else
        echom 'Warning in snipmate.vim: Snippet ' . a:trigger . ' is already defined.'
                    \ .' See :h multi_snip for help on snippets with multiple matches.'
    endif
endfunction

function! snipmate#util#GetSnippets(dir, filetypes)
    for ft in split(a:filetypes, '\.')
        if has_key(g:snipmate_did_ft, ft)
            continue
        endif
        call s:DefineSnips(a:dir, ft, ft)
        if ft ==# 'objc' || ft ==# 'cpp' || ft ==# 'cs'
            call s:DefineSnips(a:dir, 'c', ft)
        elseif ft ==# 'xhtml'
            call s:DefineSnips(a:dir, 'html', 'xhtml')
        endif
        let g:snipmate_did_ft[ft] = 1
    endfor
endfunction

" Reload snippets for all filetypes.
function! snipmate#util#ReloadAllSnippets()
    for ft in keys(g:snipmate_did_ft)
        call snipmate#util#ReloadSnippets(ft)
    endfor
endfunction

" Reload snippets for filetype.
function! snipmate#util#ReloadSnippets(ft)
    let ft = a:ft ==# '' ? '_' : a:ft
    call snipmate#util#ResetSnippets(ft)
    call snipmate#util#GetSnippets(g:snippets_dir, ft)
endfunction

" Reset snippets for all filetypes.
function! snipmate#util#ResetAllSnippets()
    let g:snipmate_snippets = {}
    let g:snipmate_multi_snips = {}
    let g:snipmate_did_ft = {}
endfunction

" Reset snippets for filetype.
function! snipmate#util#ResetSnippets(ft)
    let ft = a:ft ==# '' ? '_' : a:ft
    for dict in [g:snipmate_snippets, g:snipmate_multi_snips, g:snipmate_did_ft]
        if has_key(dict, ft)
            unlet dict[ft]
        endif
    endfor
endfunction

