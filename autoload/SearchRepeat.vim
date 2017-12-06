" SearchRepeat.vim: Repeat the last type of search via n/N.
"
" DEPENDENCIES:
"   - ingo/err.vim autoload script
"   - ingo/escape/command.vim autoload script
"   - ingo/msg.vim autoload script
"
" Copyright: (C) 2008-2017 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"   2.00.020	05-Dec-2017	Rename arguments: description -> identifier and
"				helptext -> description.
"   2.00.019	28-Nov-2017	ENH: Support "isResetToStandardSearch" option
"				flag that overrides the
"				g:SearchRepeat_IsResetToStandardSearch
"				configuration value for certain integrations.
"				Refactoring: Move s:SearchCommand() to
"				SearchRepeat#StandardCommand().
"   2.00.018	27-Nov-2017	ENH: Omit related commands and condense
"				activation commands column in search type list
"				when in small-width Vim, to avoid line breaks
"				that make the layout hard to read.
"   2.00.017	22-Nov-2017	Refactoring: Extract
"				SearchRepeat#ResetToStandardSearch().
"				Remember the contents of @/ in
"				s:lastSearchPattern and reset to standard search
"				when it changed (e.g. by * / g*, or plugins like
"				my SearchAlternatives.vim).
"				Reset to standard search is now configurable via
"				g:SearchRepeat_IsResetToStandardSearch.
"				Add SearchRepeat#ToggleResetToStandard().
"   2.00.016	29-Apr-2016	CHG: Simplify SearchRepeat#Define() API: Get rid
"				of duplicate suffixes, descriptions, helptexts,
"				related commands for next / prev mappings.
"				Instead, forward / backward search is now
"				handled by separate gn / gN mapping prefixes.
"				CHG: Mapping registration only stores the "Next"
"				mapping, and the gn help command only lists
"				those (to reduce clutter and duplication). The
"				"Prev" mapping is now stored in
"				s:reverseRegistrations.
"				Use ingo#escape#command#mapunescape() when
"				listing a:suffixToReactivate.
"   1.11.015	30-Oct-2014	FIX: v:searchforward requires Vim 7.2; don't
"				support the g:SearchRepeat_IsAlwaysForwardWith_n
"				configuration in older versions.
"   1.10.014	27-May-2014	CHG: Add isOpposite flag to
"				SearchRepeat#Execute() and remove the swapping
"				of a:mappingNext and a:mappingPrev in the
"				opposite mapping definition.
"				Move SearchRepeat#RepeatSearch() to autoload
"				script, and make it honor the
"				g:SearchRepeat_IsAlwaysForwardWith_n
"				configuration.
"				FIX: SearchRepeat#Execute() needs to return
"				status of SearchRepeat#Repeat() to have clients
"				:echoerr any error.
"   1.00.013	26-May-2014	Avoid "E716: Key not present in Dictionary"
"				error when a search mapping hasn't been
"				registered. Only issue a warning message when
"				'verbose' is > 0.
"				Handle empty a:suffixToReactivate.
"				Copy registration of the <Plug>(SearchRepeat_n)
"				from SearchDefaultSearch.vim (without the custom
"				gn/, gn? reactivation mappings). The built-in /,
"				? searches should be registered all the time,
"				not just when the special gn/ and gn? mappings
"				of that plugin are defined.
"   1.00.012	24-May-2014	CHG: SearchRepeat#Register() now only takes the
"				mapping suffix to reactivate, it prepends the
"				new g:SearchRepeat_MappingPrefix itself.
"				Add SearchRepeat#Define() which simplifies the
"				boilerplate code of SearchRepeat#Register() and
"				the repeat reactivation mappings for next and
"				previous matches into a single function call.
"				Adapt <Plug>-mapping naming.
"	011	27-Apr-2014	Also handle :echoerr from repeated searches.
"	010	08-Mar-2013	Use ingo#err#SetVimException() instead of
"				returning the error message; this avoids the
"				temporary global variable in the mapping.
"	009	12-May-2012	Just :echomsg'ing the error doesn't abort a
"				mapping sequence, e.g. when "n" is contained in
"				a macro, but it should. Therefore, returning the
"				errmsg from SearchRepeat#Repeat(), and using
"				:echoerr to print the error directly from the
"				mapping instead.
"	008	17-Aug-2009	Added 'description' configuration for use in
"				ingostatusline.vim. This is a shorter, more
"				identifier-like representation than the
"				helptext; the same as SearchSpecial.vim's
"				'predicateDescription' framed by the /.../ or
"				?...? indicator for the search direction.
"				Factored out s:FixedTabWidth().
"				Moved "related commands" one shiftwidth to the
"				right to make room for the current largest
"				description + helptext. This formatting also
"				nicely prints on 80-column Vim, with the
"				optional related commands column moving to a
"				second line.
"				Added SearchRepeat#LastSearchDescription() as an
"				integration point for ingostatusline.vim.
"	007	03-Jul-2009	Added 'keys' configuration for
"				SearchWithoutHighlighting.vim.
"	006	06-May-2009	Added a:relatedCommands to
"				SearchRepeat#Register().
"	005	06-Feb-2009	BF: Forgot s:lastSearch[3] initialization in one
"				place.
"	004	04-Feb-2009	BF: Only turn on 'hlsearch' if no Vim error
"				occurred to avoid clearing of long error message
"				with Hit-Enter.
"	003	02-Feb-2009	Fixed broken macro playback of n and N
"				repetition mappings by using :normal for the
"				mapping, and explicitly setting 'hlsearch' via
"				feedkeys(). As this setting isn't implicit in
"				the repeated commands, clients can opt out of
"				it.
"				BF: Sorting twice was wrong, but luckily showed
"				the correct results. Must simply sort
"				ASCII-ascending *while ignoring case*.
"	002	07-Aug-2008	BF: Need to sort twice.
"	001	05-Aug-2008	Split off autoload functions from plugin script.
"				file creation
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
"   a:options           Optional configuration:
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
    let s:lastSearchPattern = @/
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
    if a:isOpposite && ! g:SearchRepeat_IsAlwaysForwardWith_n
	call SearchRepeat#Set(a:oppositeMapping, a:mapping, a:howToHandleCount, (a:0 ? a:1 : {}))
    else
	call SearchRepeat#Set(a:mapping, a:oppositeMapping, a:howToHandleCount, (a:0 ? a:1 : {}))
    endif
    return SearchRepeat#Repeat(g:SearchRepeat_IsAlwaysForwardWith_n ? a:isOpposite : 0)
endfunction
function! SearchRepeat#Repeat( isOpposite )
    if @/ !=# s:lastSearchPattern
	call SearchRepeat#ResetToStandardSearch(s:lastSearch[3])
    endif

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
    let s:registrations[ a:mappingNext ] = [
    \   a:mappingToActivate,
    \   a:suffixToReactivate,
    \   a:identifier,
    \   a:description,
    \   a:relatedCommands
    \]
    let s:reverseRegistrations[ a:mappingPrev ] = a:mappingNext
endfunction

function! SearchRepeat#Define( mappingNext, mappingPrev, mappingToActivate, suffixToReactivate, identifier, description, relatedCommands, howToHandleCountAndOptions )
"******************************************************************************
"* PURPOSE:
"   Define a repeatable custom search.
"* ASSUMPTIONS / PRECONDITIONS:
"	? List of any external variable, control, or other element whose state affects this procedure.
"* EFFECTS / POSTCONDITIONS:
"	? List of the procedure's effect on each external variable, control, or other element.
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
"   a:howToHandleCountAndOptions    See SearchRepeat#Set(); at least specify
"				    a:howToHandleCount. If you also want to
"				    specify a:options, you need to pass both as
"				    a single string; e.g. "2, {'hlsearch': 0}".
"* RETURN VALUES:
"	? Explanation of the value returned.
"******************************************************************************
    execute printf('call SearchRepeat#Register("\%s", "\%s", a:mappingToActivate, a:suffixToReactivate, a:identifier, a:description, a:relatedCommands)', a:mappingNext, a:mappingPrev)
    execute printf('nnoremap <silent> %s%s :<C-u>if ! SearchRepeat#Execute(0, "\%s", "\%s", %s)<Bar>echoerr ingo#err#Get()<Bar>endif<CR>', g:SearchRepeat_MappingPrefixNext, a:suffixToReactivate, a:mappingNext, a:mappingPrev, a:howToHandleCountAndOptions)
    execute printf('nnoremap <silent> %s%s :<C-u>if ! SearchRepeat#Execute(1, "\%s", "\%s", %s)<Bar>echoerr ingo#err#Get()<Bar>endif<CR>', g:SearchRepeat_MappingPrefixPrev, a:suffixToReactivate, a:mappingNext, a:mappingPrev, a:howToHandleCountAndOptions)
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
