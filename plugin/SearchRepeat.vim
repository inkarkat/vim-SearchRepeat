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
" CONFIGURATION:
"   To set the current search type (in a custom search mapping):
"	:call SearchRepeatSet("\<Plug>MyCustomSearchMapping", "\<Plug>MyCustomOppositeSearchMapping", n)
"
"   To set the current search type (in a custom search mapping) and execute the
"   (first, not the opposite) search mapping:
"	:call SearchRepeatExecute("\<Plug>MyCustomSearchMapping", "\<Plug>MyCustomOppositeSearchMapping", n)
"
"   The third argument n specifies how the mappings deal with an optional
"   [count] that is passed to the 'n' / 'N' commands:
"	0 Doesn't handle count, single invocation only. 
" 	1 Doesn't handle count itself, invoke search command multiple times. 
" 	2 Handles count itself, pass it through. 
"
" LIMITATIONS:
" ASSUMPTIONS:
" KNOWN PROBLEMS:
" TODO:
"
" Copyright: (C) 2008 by Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'. 
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS 
"	004	22-Jul-2008	Changed s:registrations to dictionary to avoid
"				duplicates when re-registering (e.g. when
"				reloading plugin). 
"	003	19-Jul-2008	ENH: Added basic help and registration via
"				'gn' mapping and SearchRepeatRegister(). 
"	002	30-Jun-2008	ENH: Handling optional [count] for searches. 
"	001	27-Jun-2008	file creation

" Avoid installing twice or when in unsupported VIM version. 
if exists('g:loaded_SearchRepeat') || (v:version < 700)
    finish
endif
let g:loaded_SearchRepeat = 1

let s:lastSearch = ["\<Plug>SearchRepeat_n", "\<Plug>SearchRepeat_N", 2]

function! SearchRepeatSet( mapping, oppositeMapping, howToHandleCount )
    let s:lastSearch = [a:mapping, a:oppositeMapping, a:howToHandleCount]
endfunction

function! SearchRepeatExecute( mapping, oppositeMapping, howToHandleCount )
    let s:lastSearch = [a:mapping, a:oppositeMapping, a:howToHandleCount]
    call s:SearchRepeat(0)
endfunction

function! s:SearchRepeat( isOpposite )
    let l:searchCommand = s:lastSearch[ a:isOpposite ]

    if v:count > 0
	if s:lastSearch[2] == 0
	    " Doesn't handle count, single invocation only. 
	elseif s:lastSearch[2] == 1
	    " Doesn't handle count itself, invoke search command multiple times. 
	    let l:searchCommand = repeat( l:searchCommand, v:count )
	elseif s:lastSearch[2] == 2
	    " Handles count itself, pass it through. 
	    let l:searchCommand = v:count . l:searchCommand
	else
	    throw 'ASSERT: Invalid value for howToHandleCount!'
	endif
    endif

    " Note: Via :normal, hlsearch isn't turned on, and the 'E486: Pattern not
    " found' causes an exception. feedkeys() fixes both problems. 
    "execute 'normal'  l:searchCommand 
    call feedkeys( l:searchCommand )
endfunction



" Note: The mappings cannot be executed with ':normal!', so that the <Plug>
" mappings apply. The [nN] commands must be executed without remapping, or we
" end up in endless recursion. Thus, define noremapping mappings for [nN]. 
" Note: When typed, [*#nN] open the fold at the search result, but inside a mapping or
" :normal this must be done explicitly via 'zv'. 
nnoremap <Plug>SearchRepeat_n nzv
nnoremap <Plug>SearchRepeat_N Nzv

" n/N now repeat the last type of search. 
nnoremap <silent> n :<C-U>call <SID>SearchRepeat(0)<CR>
nnoremap <silent> N :<C-U>call <SID>SearchRepeat(1)<CR>

" Capture changes in the search pattern. 
" Note: Use feedkeys('/','n')<CR> instead of a simple <CR>/ because the latter
" doesn't immediately draw the search command-line, only when a pattern is
" typed. 
nnoremap <silent> /  :<C-U>call SearchRepeatSet("\<Plug>SearchRepeat_n", "\<Plug>SearchRepeat_N", 2)<bar>call feedkeys('/','n')<CR>
nnoremap <silent> ?  :<C-U>call SearchRepeatSet("\<Plug>SearchRepeat_n", "\<Plug>SearchRepeat_N", 2)<bar>call feedkeys('?','n')<CR>
nmap <silent>  *     <Plug>SearchHighlightingStar:<C-U>call SearchRepeatSet("\<Plug>SearchRepeat_n", "\<Plug>SearchRepeat_N", 2)<CR>
nmap <silent> g*     <Plug>SearchHighlightingGStar:<C-U>call SearchRepeatSet("\<Plug>SearchRepeat_n", "\<Plug>SearchRepeat_N", 2)<CR>
vmap <silent>  *     <Plug>SearchHighlightingStar:<C-U>call SearchRepeatSet("\<Plug>SearchRepeat_n", "\<Plug>SearchRepeat_N", 2)<CR>



"- registration and context help ----------------------------------------------
let s:registrations = {}
function! SearchRepeatRegister( mapping, keysToActivate, keysToReactivate, helptext )
    let s:registrations[ a:mapping ] = [ a:keysToActivate, a:keysToReactivate, a:helptext ]
endfunction

function! s:SortByReactivation(i1, i2)
    if a:i1[1][1] ==# a:i2[1][1]
	return 0
    elseif a:i1[1][1] ==? a:i2[1][1]
	" If only differ in case, choose lowercase before uppercase. 
	return a:i1[1][1] < a:i2[1][1] ? 1 : -1
    else
	" ASCII-ascending. 
	return a:i1[1][1] > a:i2[1][1] ? 1 : -1
    endif
endfunction
function! s:SearchRepeatHelp()
    for [l:mapping, l:info] in sort( items(s:registrations), 's:SortByReactivation' )
	if l:mapping == s:lastSearch[0]
	    echohl ModeMsg
	endif
	echo l:info[1] . "\t" . l:info[0] . "\t" . l:info[2]
	echohl NONE
    endfor
endfunction
nnoremap <Plug>SearchRepeatHelp :<C-U>call <SID>SearchRepeatHelp()<CR>
if ! hasmapto('<Plug>SearchRepeatHelp', 'n')
    nmap <silent> gn <Plug>SearchRepeatHelp
endif

" vim: set sts=4 sw=4 noexpandtab ff=unix fdm=syntax :

