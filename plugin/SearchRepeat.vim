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
"	:call SearchRepeat#Set("\<Plug>MyCustomSearchMapping", "\<Plug>MyCustomOppositeSearchMapping", n)
"
"   To set the current search type (in a custom search mapping) and execute the
"   (first, not the opposite) search mapping:
"	:call SearchRepeat#Execute("\<Plug>MyCustomSearchMapping", "\<Plug>MyCustomOppositeSearchMapping", n)
"
"   The third argument n specifies how the mappings deal with an optional
"   [count] that is passed to the 'n' / 'N' commands:
"	0 Doesn't handle count, single invocation only. 
" 	1 Doesn't handle count itself, invoke search command multiple times. 
" 	2 Handles count itself, pass it through. 
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
" Copyright: (C) 2008 by Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'. 
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS 
"	005	05-Aug-2008	Split off autoload functions from plugin script. 
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

" Note: The mappings cannot be executed with ':normal!', so that the <Plug>
" mappings apply. The [nN] commands must be executed without remapping, or we
" end up in endless recursion. Thus, define noremapping mappings for [nN]. 
" Note: When typed, [*#nN] open the fold at the search result, but inside a mapping or
" :normal this must be done explicitly via 'zv'. 
nnoremap <Plug>SearchRepeat_n nzv
nnoremap <Plug>SearchRepeat_N Nzv

" n/N			Repeat the last type of search. 
nnoremap <silent> n :<C-U>call SearchRepeat#Repeat(0)<CR>
nnoremap <silent> N :<C-U>call SearchRepeat#Repeat(1)<CR>

" Capture changes in the search pattern. 
" Note: Use feedkeys('/','n')<CR> instead of a simple <CR>/ because the latter
" doesn't immediately draw the search command-line, only when a pattern is
" typed. 
nnoremap <silent> /  :<C-U>call SearchRepeat#Set("\<Plug>SearchRepeat_n", "\<Plug>SearchRepeat_N", 2)<Bar>call feedkeys('/','n')<CR>
nnoremap <silent> ?  :<C-U>call SearchRepeat#Set("\<Plug>SearchRepeat_n", "\<Plug>SearchRepeat_N", 2)<Bar>call feedkeys('?','n')<CR>
nmap <silent>  *     <Plug>SearchHighlightingStar:<C-U>call SearchRepeat#Set("\<Plug>SearchRepeat_n", "\<Plug>SearchRepeat_N", 2)<CR>
nmap <silent> g*     <Plug>SearchHighlightingGStar:<C-U>call SearchRepeat#Set("\<Plug>SearchRepeat_n", "\<Plug>SearchRepeat_N", 2)<CR>
vmap <silent>  *     <Plug>SearchHighlightingStar:<C-U>call SearchRepeat#Set("\<Plug>SearchRepeat_n", "\<Plug>SearchRepeat_N", 2)<CR>



" gn			Show all registered search types, keys to (re-)activate,
"			and the currently active search type. 
nnoremap <Plug>SearchRepeatHelp :<C-U>call SearchRepeat#Help()<CR>
if ! hasmapto('<Plug>SearchRepeatHelp', 'n')
    nmap <silent> gn <Plug>SearchRepeatHelp
endif

" vim: set sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
