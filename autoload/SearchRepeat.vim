" SearchRepeat.vim: Repeat the last type of search via n/N.
"
" DEPENDENCIES:
"   - ingo/err.vim autoload script
"   - ingo/escape/command.vim autoload script
"   - ingo/msg.vim autoload script
"
" Copyright: (C) 2008-2022 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
let s:save_cpo = &cpo
set cpo&vim

"- configuration ---------------------------------------------------------------

" Need to repeat this here, as other custom search plugins may be sourced before
" plugin/SearchRepeat.vim.
if ! exists('g:SearchRepeat_MappingPrefixNext')
    let g:SearchRepeat_MappingPrefixNext = 'gn'
endif
if ! exists('g:SearchRepeat_MappingPrefixPrev')
    let g:SearchRepeat_MappingPrefixPrev = 'gN'
endif


"- functions -------------------------------------------------------------------

" Note: When typed, [*#nN] open the fold at the search result, but inside a mapping or
" :normal this must be done explicitly via 'zv'.
" The tricky thing here is that folds must only be opened when the jump
" succeeded. The 'n' command doesn't abort the mapping chain, so we have to
" explicitly check for a successful jump in a custom function.
function! SearchRepeat#RepeatSearch( isOpposite, ... )
    let l:isReverse = ((a:0 || g:SearchRepeat_IsAlwaysForwardWith_n) && v:version >= 702 ?
    \   (v:searchforward && a:isOpposite || ! v:searchforward && ! a:isOpposite) :
    \   a:isOpposite
    \)

    let l:save_errmsg = v:errmsg
    let v:errmsg = ''
    execute 'normal!' (v:count ? v:count : '') . (l:isReverse ? 'N' : 'n')
    if empty(v:errmsg)
	let v:errmsg = l:save_errmsg
	execute 'normal! zv' . (a:0 ? a:1 : '')
    endif
endfunction


let s:lastSearch = ["\<Plug>(SearchRepeat_n)", "\<Plug>(SearchRepeat_N)", 2, {}]
let s:lastSearchIdentifier = ''
let s:lastSearchPattern = ''

function! s:ConsiderChangeInLastSearchPattern()
    if @/ !=# s:lastSearchPattern
	call SearchRepeat#ResetToStandardSearch(s:lastSearch[3])
    endif
endfunction
function! SearchRepeat#UpdateLastSearchPattern()
    let s:lastSearchPattern = @/
endfunction
function! SearchRepeat#OnUpdateOfLastSearchPattern()
    call s:ConsiderChangeInLastSearchPattern()
    call SearchRepeat#UpdateLastSearchPattern()
endfunction

function! SearchRepeat#StandardCommand( keys )
    " Store the [count] of the last search command. Other plugins that enhance
    " the standard search (SearchAsQuickJumpNext) are interested in it.
    let g:lastSearchCount = v:count

    call SearchRepeat#ResetToStandardSearch(s:lastSearch[3])

    return a:keys
endfunction

function! SearchRepeat#ResetToStandardSearch( ... )
    if get((a:0 ? a:1 : {}), 'isResetToStandardSearch', g:SearchRepeat_IsResetToStandardSearch)
	call SearchRepeat#Set("\<Plug>(SearchRepeat_n)", "\<Plug>(SearchRepeat_N)", 2)
    endif
endfunction
function! SearchRepeat#Set( mapping, oppositeMapping, howToHandleCount, ... )
"******************************************************************************
"* PURPOSE:
"   Set a particular search type for repeating with n / N.
"* ASSUMPTIONS / PRECONDITIONS:
"   None.
"* EFFECTS / POSTCONDITIONS:
"   Changes the active custom search used by n / N.
"* INPUTS:
"   a:mapping   Mapping to (forward) search for the next match.
"   a:oppositeMapping   Mapping to (backward) search for the previous match.
"   a:howToHandleCount  Tells the repeater how the search command handles a
"			[count] before n / N:
"	0: Doesn't handle count, single invocation only.
"	1: Doesn't handle count itself, invoke search command multiple times.
"	2: Handles count itself, pass it through.
"   a:options.hlsearch  Flag whether to re-enable 'hlsearch' during repetition
"			(default 1) (which is not done automatically because the
"			repeated mapping is executed from within a function, and
"			not via feedkeys()). Set to 0 if your search mapping has
"			nothing to do with the built-in search functionality.
"   a:options.keys      Appends arbitrary (mapped) key sequences (via
"			feedkeys()) after executing the search mapping.
"   a:options.isResetToStandardSearch   Flag whether to reset to standard search
"					whenever the current search pattern
"					changes. Overrides the global
"					g:SearchRepeat_IsResetToStandardSearch
"					configuration, making the custom search
"					immune to its current value.
"* RETURN VALUES:
"   None.
"******************************************************************************
    let s:lastSearch = [a:mapping, a:oppositeMapping, a:howToHandleCount, (a:0 ? a:1 : {})]
    call SearchRepeat#UpdateLastSearchPattern()
    if has_key(s:registrations, a:mapping)
	let s:lastSearchIdentifier = s:registrations[a:mapping][2]
    elseif has_key(s:reverseRegistrations, a:mapping) && has_key(s:registrations, s:reverseRegistrations[a:mapping])
	let s:lastSearchIdentifier = s:registrations[s:reverseRegistrations[a:mapping]][2]
    else
	let s:lastSearchIdentifier = '???'
	if &verbose > 0
	    call ingo#msg#WarningMsg(printf('SearchRepeat: No registration found for %s', a:mapping))
	endif
    endif
endfunction
function! SearchRepeat#Execute( isOpposite, mapping, oppositeMapping, howToHandleCount, ... )
"******************************************************************************
"* PURPOSE:
"   Execute a custom search defined by a:mapping / a:oppositeMapping, and enable
"   repeating with n / N.
"* ASSUMPTIONS / PRECONDITIONS:
"   a:mapping / a:oppositeMapping exist and perform a (custom) search.
"* EFFECTS / POSTCONDITIONS:
"   Sets the passed search as the active one.
"* INPUTS:
"   a:isOpposite    Flag whether the a:oppositeMapping should be triggered.
"   See SearchRepeat#Set() for the remaining arguments.
"* RETURN VALUES:
"   1 if successful search, 0 if an error occurred. The error message can then
"   be obtained from ingo#err#Get().
"******************************************************************************
    if a:isOpposite && ! g:SearchRepeat_IsAlwaysForwardWith_n
	call SearchRepeat#Set(a:oppositeMapping, a:mapping, a:howToHandleCount, (a:0 ? a:1 : {}))
    else
	call SearchRepeat#Set(a:mapping, a:oppositeMapping, a:howToHandleCount, (a:0 ? a:1 : {}))
    endif
    return SearchRepeat#Repeat(g:SearchRepeat_IsAlwaysForwardWith_n ? a:isOpposite : 0)
endfunction
function! SearchRepeat#Repeat( isOpposite )
    call s:ConsiderChangeInLastSearchPattern()

    let l:searchCommand = s:lastSearch[ a:isOpposite ]

    if v:count > 0
	if s:lastSearch[2] == 0
	    " Doesn't handle count, single invocation only.
	elseif s:lastSearch[2] == 1
	    " Doesn't handle count itself, invoke search command multiple times.
	    let l:searchCommand = repeat(l:searchCommand, v:count)
	elseif s:lastSearch[2] == 2
	    " Handles count itself, pass it through.
	    let l:searchCommand = v:count . l:searchCommand
	else
	    throw 'ASSERT: Invalid value for howToHandleCount!'
	endif
    endif

    try
	execute 'normal'  l:searchCommand

	" Note: Via :normal, 'hlsearch' isn't turned on, but we also cannot use
	" feedkeys(), which would break macro playback. Thus, we use feedkeys() to
	" turn on 'hlsearch' (via a <silent> mapping, so it isn't echoed), unless
	" the current search type explicitly opts out of this.
	" Note: Only turn on 'hlsearch' if no Vim error occurred (like "E486:
	" Pattern not found"); otherwise, the <Plug>(SearchRepeat_hlsearch)
	" mapping (though <silent>) would clear a long error message which
	" causes the Hit-Enter prompt. In case of a search error, there's
	" nothing to highlight, anyway.
	if get(s:lastSearch[3], 'hlsearch', 1)
	    call feedkeys("\<Plug>(SearchRepeat_hlsearch)")
	endif

	" Apart from the 'hlsearch' flag, arbitrary (mapped) key sequences can
	" be appended via the 'keys' configuration. This could e.g. be used to
	" implement the opposite of 'hlsearch', turning off search highlighting,
	" by nnoremap <silent> <Plug>(SearchHighlightingOff) :nohlsearch<CR>, then
	" setting 'keys' to "\<Plug>(SearchHighlightingOff)".
	let l:keys = get(s:lastSearch[3], 'keys', '')
	if ! empty(l:keys)
	    call feedkeys(l:keys)
	endif
    catch /^Vim\%((\a\+)\)\=:/
	call ingo#err#SetVimException()
	return 0
    endtry
    return 1
endfunction


"- integration point for search type ------------------------------------------

function! SearchRepeat#LastSearchDescription()
    return s:lastSearchIdentifier
endfunction


"- registration and context help ----------------------------------------------

let s:registrations = {"\<Plug>(SearchRepeat_n)": ['/', '', 'Standard search', '', '']}
let s:reverseRegistrations = {"\<Plug>(SearchRepeat_N)": "\<Plug>(SearchRepeat_n)"}
function! SearchRepeat#Register( mappingNext, mappingPrev, mappingToActivate, suffixToReactivate, identifier, description, relatedCommands )
"******************************************************************************
"* PURPOSE:
"   Register a custom search for repetition with n / N by this plugin.
"* ASSUMPTIONS / PRECONDITIONS:
"   None.
"* EFFECTS / POSTCONDITIONS:
"   Registers the custom search.
"* INPUTS:
"   See SearchRepeat#Define().
"* RETURN VALUES:
"   None.
"******************************************************************************
    let s:registrations[ a:mappingNext ] = [
    \   a:mappingToActivate,
    \   a:suffixToReactivate,
    \   a:identifier,
    \   a:description,
    \   a:relatedCommands
    \]
    let s:reverseRegistrations[ a:mappingPrev ] = a:mappingNext
endfunction

function! SearchRepeat#Define( mappingNext, mappingPrev, mappingToActivate, suffixToReactivate, identifier, description, relatedCommands, howToHandleCount, ... )
"******************************************************************************
"* PURPOSE:
"   Define a repeatable custom search.
"* ASSUMPTIONS / PRECONDITIONS:
"   None.
"* EFFECTS / POSTCONDITIONS:
"   Defines mappings of the plugin's mapping prefix + the a:suffixToReactivate,
"   and registers the custom search.
"* INPUTS:
"   a:mappingNext   Mapping to (forward) search for the next match.
"   a:mappingPrev   Mapping to (backward) search for the previous match.
"   a:mappingToActivate Any mapping(s) (or none) provided by the custom search
"			plugin that activate the search.
"   a:suffixToReactivate    Keys after "gn" that reactivate the custom search.
"   a:identifier        Short textual representation of the custom search type.
"   a:description       A short sentence that describes the custom search.
"   a:relatedCommands   Any (Ex) commands that activate or configure the custom
"			search. Like a:mappingToActivate, but for longer stuff.
"   a:howToHandleCount  Number; see SearchRepeat#Set().
"   a:options           Optional Dictionary of configuration options; see
"			SearchRepeat#Set().
"* RETURN VALUES:
"   None.
"******************************************************************************
    execute printf('call SearchRepeat#Register("\%s", "\%s", a:mappingToActivate, a:suffixToReactivate, a:identifier, a:description, a:relatedCommands)', a:mappingNext, a:mappingPrev)
    let l:optionsArgument = (a:0 ? ', ' . string(a:1) : '')
    execute printf('nnoremap <silent> %s%s :<C-u>if ! SearchRepeat#Execute(0, "\%s", "\%s", %s%s)<Bar>echoerr ingo#err#Get()<Bar>endif<CR>', g:SearchRepeat_MappingPrefixNext, a:suffixToReactivate, a:mappingNext, a:mappingPrev, a:howToHandleCount, l:optionsArgument)
    execute printf('nnoremap <silent> %s%s :<C-u>if ! SearchRepeat#Execute(1, "\%s", "\%s", %s%s)<Bar>echoerr ingo#err#Get()<Bar>endif<CR>', g:SearchRepeat_MappingPrefixPrev, a:suffixToReactivate, a:mappingNext, a:mappingPrev, a:howToHandleCount, l:optionsArgument)
endfunction


function! s:SortByReactivation(i1, i2)
    let s1 = a:i1[1][1]
    let s2 = a:i2[1][1]
    if s1 ==# s2
	return 0
    elseif s1 ==? s2
	" If only differ in case, choose lowercase before uppercase.
	return s1 < s2 ? 1 : -1
    else
	" ASCII-ascending while ignoring case.
	return tolower(s1) > tolower(s2) ? 1 : -1
    endif
endfunction
function! s:FixedTabWidth( precedingTextWidth, precedingText, text )
    return repeat("\t", (a:precedingTextWidth - len(a:precedingText) - 1) / 8 + 1) . a:text
endfunction
function! SearchRepeat#Help()
    let l:isShort = (&columns <= 80)
    let [l:spacer, l:width, l:optional] = (l:isShort ? ["\t", 8, ''] : ["\t\t", 16, "\t\t\t\t\trelated commands"])

    echohl Title
    echo "activation" . l:spacer . "identifier\tdescription" . l:optional
    echohl None

    for [l:mapping, l:info] in sort(items(s:registrations), 's:SortByReactivation')
	if l:mapping == s:lastSearch[0]
	    echohl ModeMsg
	endif

	let l:mappingToReactivate = (empty(l:info[1]) ? '' : g:SearchRepeat_MappingPrefixNext . l:info[1])

	echo ingo#escape#command#mapunescape(l:mappingToReactivate) . "\t" .
	\   l:info[0] .
	\   s:FixedTabWidth(l:width, l:info[0], l:info[2]) .
	\   s:FixedTabWidth(16, l:info[2], l:info[3]) .
	\   (empty(l:info[4]) || empty(l:optional) ? '' : s:FixedTabWidth(48, l:info[3], l:info[4]))
	echohl None
    endfor
endfunction


function! SearchRepeat#ToggleResetToStandard()
    let g:SearchRepeat_IsResetToStandardSearch = ! g:SearchRepeat_IsResetToStandardSearch
    echomsg (g:SearchRepeat_IsResetToStandardSearch ?
    \   'Changes in search pattern will reset to default search' :
    \   'Current custom search will persist when search pattern changes'
    \)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
