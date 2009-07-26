" SearchRepeat.vim: Repeat the last type of search via n/N. 
"
" DESCRIPTION:
"   Overloads the 'n' and 'N' commands so that custom searches (other than the
"   default search via /, ?, [g]*, [g]#) can be repeated. A change of the
"   current search pattern or activation of a custom search makes that search
"   the new type of search to be repeated, until the search type is changed
"   again. 
"
" USAGE:
"   To change the search type back to plain normal search (without changing the
"   search pattern), just type '/<Return>'. 
"
" INSTALLATION:
" DEPENDENCIES:
"   - SearchRepeat.vim autoload script. 
"
" CONFIGURATION:
"   To set the current search type (in a custom search mapping):
"	:call SearchRepeat#Set("\<Plug>MyCustomSearchMapping", "\<Plug>MyCustomOppositeSearchMapping", n)
"
"   To set the current search type (in a custom search mapping) and execute the
"   (first, not the opposite) search mapping:
"	:call SearchRepeat#Execute("\<Plug>MyCustomSearchMapping", "\<Plug>MyCustomOppositeSearchMapping", n)
"
"   The third argument n specifies how the mappings deal with an optional
"   [count] that is passed to the 'n' / 'N' commands:
"	0 Doesn't handle count, single invocation only. 
"	  No count is prepended to the search mapping, which is invoked only
"	  once. (But the count itself is still available through v:count.) 
" 	1 Doesn't handle count itself, invoke search mapping multiple times. 
" 	2 Handles count itself, prepend count before search mapping. 
"
"   An optional fourth argument supplies additional configuration in a
"   dictionary; these key names are supported:
"	- 'hlsearch' (type Boolean, default 1)
"	  Flag whether to re-enable 'hlsearch' during repetition (which is not
"	  done automatically because the repeated mapping is executed from
"	  within a function, and not via feedkeys()). Set to 0 if your search
"	  mapping has nothing to do with the built-in search functionality. 
"
"   Note: When typed, [*#nN] open the fold at the search result, but inside a
"   mapping or :normal this must be done explicitly via 'zv'. This plugin does
"   nothing with folds when repeating searches; you have to deal with closed
"   folds yourself (e.g. when you search() to somewhere, do a ':normal! zv' to
"   open the fold at the match). 
"
" LIMITATIONS:
" ASSUMPTIONS:
" KNOWN PROBLEMS:
" TODO:
"
" Copyright: (C) 2008-2009 by Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'. 
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS 
"	013	27-Jul-2009	Added insert mode shadow mappings and <SID>NM
"				abstraction to allow execution of SearchRepeat
"				mappings from insert mode via <C-O>. 
"	012	14-Jul-2009	The / and ? mappings swallowed the optional
"				[count] that can be supplied to the built-ins;
"				now using a :map-expr to pass in the [count]. 
"				Now storing the [count] of the last search
"				command in g:lastSearchCount for consumption by
"				other plugins (SearchAsQuickJumpNext). 
"	011	13-Jun-2009	BF: [g]* mappings now remove arbitrary entries
"				from the command history; cannot reproduce the
"				adding to history. Removing the histdel() again. 
"	010	30-May-2009	Using nnoremap for SearchRepeat integration
"				(through <SID>SearchRepeat_Star, not <Plug>...
"				mappings); otherwise, the command would be
"				listed in FuzzyFinderMruCmd. 
"	009	28-Feb-2009	BF: [g]* mappings added ":call
"				SearchRepeat#Set(...) to command history. Now
"				deleting the added entry. 
"	008	03-Feb-2009	Removed hardcoded dependency to
"				SearchHighlighting.vim by checking (and keeping)
"				existing mappings of [g]* commands. 
"	007	02-Feb-2009	Fixed broken macro playback of n and N
"				repetition mappings by using :normal for the
"				mapping, and explicitly setting 'hlsearch' via
"				feedkeys(). As this setting isn't implicit in
"				the repeated commands, clients can opt out of
"				it. 
"	006	02-Jan-2009	Fixed broken macro playback of / and ? mappings
"				via feedkeys() trick. 
"	005	05-Aug-2008	Split off autoload functions from plugin script. 
"	004	22-Jul-2008	Changed s:registrations to dictionary to avoid
"				duplicates when re-registering (e.g. when
"				reloading plugin). 
"	003	19-Jul-2008	ENH: Added basic help and registration via
"				'gn' mapping and SearchRepeatRegister(). 
"	002	30-Jun-2008	ENH: Handling optional [count] for searches. 
"	001	27-Jun-2008	file creation

" Avoid installing twice or when in unsupported Vim version. 
if exists('g:loaded_SearchRepeat') || (v:version < 700)
    finish
endif
let g:loaded_SearchRepeat = 1

" Note: The mappings cannot be executed with ':normal!', so that the <Plug>
" mappings apply. The [nN] commands must be executed without remapping, or we
" end up in endless recursion. Thus, define noremapping mappings for [nN]. 
" Note: When typed, [*#nN] open the fold at the search result, but inside a mapping or
" :normal this must be done explicitly via 'zv'. 
nnoremap <Plug>SearchRepeat_n nzv
nnoremap <Plug>SearchRepeat_N Nzv

" During repetition, 'hlsearch' must be explicitly turned on, but without
" echoing of the command. This is the <silent> mapping that does this inside
" SearchRepeat#Repeat(). 
nnoremap <silent> <Plug>SearchRepeat_hlsearch :<C-U>if &hlsearch<Bar>set hlsearch<Bar>endif<CR>

" n/N			Repeat the last type of search. 
nnoremap <silent> n :<C-U>call SearchRepeat#Repeat(0)<CR>
nnoremap <silent> N :<C-U>call SearchRepeat#Repeat(1)<CR>


" The user might have remapped the [g]* commands (e.g. by using the
" SearchHighlighting plugin). We preserve these mappings (assuming they're
" 'noremap). 
" Note: Must check for existing mapping to avoid recursive mapping after script
" reload. 
if empty(maparg('<SID>SearchRepeat_Star', 'n'))
    execute 'nmap <silent> <SID>SearchRepeat_Star ' . (empty(maparg('*', 'n')) ? '*' : maparg('*', 'n'))
endif
if empty(maparg('<SID>SearchRepeat_GStar', 'n'))
    execute 'nmap <silent> <SID>SearchRepeat_GStar ' . (empty(maparg('*', 'n')) ? 'g*' : maparg('g*', 'n'))
endif
if empty(maparg('<SID>SearchRepeat_Star', 'v'))
    execute 'vmap <silent> <SID>SearchRepeat_Star ' . (empty(maparg('*', 'v')) ? '*' : maparg('*', 'v'))
endif



" Capture changes in the search pattern. 

" To include the optional [count] passed to / or ?, a :map-expr is used. 
function! s:SearchCommandWithCount( isBackward )
    " Store the [count] of the last search command. Other plugins that enhance
    " the standard search (SearchAsQuickJumpNext) are interested in it. 
    let g:lastSearchCount = v:count

    return (v:count ? v:count : '') . (a:isBackward ? '?' : '/')
endfunction
nnoremap <silent> <expr> <SID>SearchCommandWithCountForward <SID>SearchCommandWithCount(0)
nnoremap <silent> <expr> <SID>SearchCommandWithCountBackward <SID>SearchCommandWithCount(1)

" To support execution of the SearchRepeat command from within insert mode (via
" |i_CTRL-O|), two strategies are used: 
"
" Normal mode mappings are shadowed by insert mode mappings that re-enter normal
" mode, then invoke the normal mode mapping. 
inoremap <silent> <script> <SID>SearchCommandWithCountForward <C-\><C-O><SID>SearchCommandWithCountForward
inoremap <silent> <script> <SID>SearchCommandWithCountBackward <C-\><C-O><SID>SearchCommandWithCountBackward
" Normal mode mappings that consist of multiple Ex command lines (and where
" Ex commands cannot be concatenated via <Bar>) use <SID>NM instead of ':<C-U>';
" the insert mode variant of <SID>NM re-enter command mode for one ex command
" line. 
nnoremap <silent> <SID>NM :<C-U>
inoremap <silent> <SID>NM <C-\><C-O>:

" Note: A simple <CR>/ doesn't immediately draw the search command-line, only
" when a pattern is typed. A feedkeys('/','n')<CR> instead shows the search
" command-line, but breaks macro playback. What does work is a combination
" trick: Use <CR>/ at the end of the mapping, but also force a search
" command-line update via feedkeys(" \<BS>",'n'). The sent keys add and
" immediately erase a <Space> search pattern; during macro playback, these keys
" are queued as harmless (noremapped) normal mode commands which neutralize
" themselves after the macro execution finishes. 
" In the standard search, the two directions never swap (it's always n/N, never
" N/n), because the search direction is determined by the use of the / or ?
" commands, and handled internally in Vim. 
nnoremap <silent> <script> /  :<C-U>call SearchRepeat#Set("\<Plug>SearchRepeat_n", "\<Plug>SearchRepeat_N", 2)<Bar>call feedkeys(" \<lt>BS>", 'n')<CR><SID>SearchCommandWithCountForward
nnoremap <silent> <script> ?  :<C-U>call SearchRepeat#Set("\<Plug>SearchRepeat_n", "\<Plug>SearchRepeat_N", 2)<Bar>call feedkeys(" \<lt>BS>", 'n')<CR><SID>SearchCommandWithCountBackward
nnoremap <silent> <script>  *  <SID>SearchRepeat_Star<SID>NMcall SearchRepeat#Set("\<Plug>SearchRepeat_n", "\<Plug>SearchRepeat_N", 2)<CR>
nnoremap <silent> <script> g* <SID>SearchRepeat_GStar<SID>NMcall SearchRepeat#Set("\<Plug>SearchRepeat_n", "\<Plug>SearchRepeat_N", 2)<CR>
vnoremap <silent> <script>  *  <SID>SearchRepeat_Star<SID>NMcall SearchRepeat#Set("\<Plug>SearchRepeat_n", "\<Plug>SearchRepeat_N", 2)<CR>


" gn			Show all registered search types, keys to (re-)activate,
"			and the currently active search type. 
nnoremap <Plug>SearchRepeatHelp :<C-U>call SearchRepeat#Help()<CR>
if ! hasmapto('<Plug>SearchRepeatHelp', 'n')
    nmap <silent> gn <Plug>SearchRepeatHelp
endif

" vim: set sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
