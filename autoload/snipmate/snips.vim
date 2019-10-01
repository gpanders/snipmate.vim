" Check if word under cursor is snippet trigger; if it isn't, try checking if
" the text after non-word characters is (e.g. check for "foo" in "bar.foo")
function! s:GetSnippet(word, scope)
    let word = a:word | let snippet = ''
    while snippet ==# ''
        if exists('g:snipmate_snippets["' . a:scope . '"]["' . escape(word, '\"') . '"]')
            let snippet = g:snipmate_snippets[a:scope][word]
        elseif exists('g:snipmate_multi_snips["' . a:scope . '"]["' . escape(word, '\"') . '"]')
            let snippet = s:ChooseSnippet(a:scope, word)
            if snippet ==# '' | break | endif
        else
            if match(word, '\W') == -1 | break | endif
            let word = substitute(word, '.\{-}\W', '', '')
        endif
    endw
    if word ==# '' && a:word !=# '.' && stridx(a:word, '.') != -1
        let [word, snippet] = s:GetSnippet('.', a:scope)
    endif
    return [word, snippet]
endfunction

function! s:ChooseSnippet(scope, trigger)
    let snippet = []
    let i = 1
    for snip in g:snipmate_multi_snips[a:scope][a:trigger]
        let snippet += [i . '. ' . snip[0]]
        let i += 1
    endfor
    if i == 2 | return g:snipmate_multi_snips[a:scope][a:trigger][0][1] | endif
    let num = inputlist(snippet) - 1
    return num == -1 ? '' : g:snipmate_multi_snips[a:scope][a:trigger][num][1]
endf

function! snipmate#snips#ShowAvailableSnips()
    let line  = getline('.')
    let col   = col('.')
    let word  = matchstr(getline('.'), '\S\+\%'.col.'c')
    let words = [word]
    if stridx(word, '.')
        let words += split(word, '\.', 1)
    endif
    let matchlen = 0
    let matches = []
    for scope in [bufnr('%')] + split(&filetype, '\.') + ['_']
        let triggers = has_key(g:snipmate_snippets, scope) ? keys(g:snipmate_snippets[scope]) : []
        if has_key(g:snipmate_multi_snips, scope)
            let triggers += keys(g:snipmate_multi_snips[scope])
        endif
        for trigger in triggers
            for word in words
                if word ==# ''
                    let matches += [trigger] " Show all matches if word is empty
                elseif trigger =~ '^'.word
                    let matches += [trigger]
                    let len = len(word)
                    if len > matchlen | let matchlen = len | endif
                endif
            endfor
        endfor
    endfor

    " This is to avoid a bug with Vim when using complete(col - matchlen, matches)
    " (Issue#46 on the Google Code snipMate issue tracker).
    call setline(line('.'), substitute(line, repeat('.', matchlen).'\%'.col.'c', '', ''))
    call complete(col, matches)
    return ''
endfunction

function! snipmate#snips#BackwardsSnippet()
    if exists('g:snipPos') | return snipmate#jumpTabStop(1) | endif

    if exists('g:SuperTabMappingForward')
        if g:SuperTabMappingBackward ==# '<S-Tab>'
            let SuperTabKey = "\<C-P>"
        elseif g:SuperTabMappingForward ==# '<S-Tab>'
            let SuperTabKey = "\<C-N>"
        endif
    endif
    if exists('SuperTabKey')
        call feedkeys(SuperTabKey)
        return ''
    endif
    return "\<S-Tab>"
endfunction

function! snipmate#snips#TriggerSnippet()
    if exists('g:SuperTabMappingForward')
        if g:SuperTabMappingForward ==# '<Tab>'
            let SuperTabKey = "\<C-N>"
        elseif g:SuperTabMappingBackward ==# '<Tab>'
            let SuperTabKey = "\<C-P>"
        endif
    endif

    if pumvisible() " Update snippet if completion is used, or deal with supertab
        if exists('SuperTabKey')
            call feedkeys(SuperTabKey) | return ''
        endif
        call feedkeys("\<Esc>a", 'n') " Close completion menu
        call feedkeys("\<Tab>") | return ''
    endif

    if exists('g:snipPos') | return snipmate#jumpTabStop(0) | endif

    let word = matchstr(getline('.'), '\S\+\%' . col('.') . 'c')
    for scope in [bufnr('%')] + split(&filetype, '\.') + ['_']
        let [trigger, snippet] = s:GetSnippet(word, scope)
        " If word is a trigger for a snippet, delete the trigger & expand
        " the snippet.
        if snippet !=# ''
            let col = col('.') - len(trigger)
            sil exe 's/\V' . escape(trigger, '/\.') . '\%#//'
            return snipmate#expandSnip(snippet, col)
        endif
    endfor

    if exists('SuperTabKey')
        call feedkeys(SuperTabKey)
        return ''
    endif
    return "\<Tab>"
endfunction

