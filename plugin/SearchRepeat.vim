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
"	:call SearchRepeatSet("\<Plug>MyCustomSearchMapping", "\<Plug>MyCustomOppositeSearchMapping")
"   To set the current search type (in a custom search mapping) and execute the
"   (first, not the opposite) search mapping:
"	:call SearchRepeatExecute("\<Plug>MyCustomSearchMapping", "\<Plug>MyCustomOppositeSearchMapping")
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
"	001	27-Jun-2008	file creation

" Avoid installing twice or when in unsupported VIM version. 
if exists('g:loaded_SearchRepeat') || (v:version < 700)
    finish
endif
let g:loaded_SearchRepeat = 1

let s:lastSearch = ["\<Plug>SearchRepeat_n", "\<Plug>SearchRepeat_N"]

function! SearchRepeatSet( mapping, oppositeMapping )
    let s:lastSearch = [a:mapping, a:oppositeMapping]
endfunction

function! SearchRepeatExecute( mapping, oppositeMapping )
    " Note: Via :normal, hlsearch isn't turned on, and the 'E486: Pattern not
    " found' causes an exception. feedkeys() fixes both problems. 
    "execute 'normal ' . a:mapping
    call feedkeys( a:mapping )
    let s:lastSearch = [a:mapping, a:oppositeMapping]
endfunction

function! s:SearchRepeat( isOpposite )
    call feedkeys( s:lastSearch[ a:isOpposite ] )
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
nnoremap <silent> /  :<C-U>call SearchRepeatSet("\<Plug>SearchRepeat_n", "\<Plug>SearchRepeat_N")<bar>call feedkeys('/','n')<CR>
nnoremap <silent> ?  :<C-U>call SearchRepeatSet("\<Plug>SearchRepeat_n", "\<Plug>SearchRepeat_N")<bar>call feedkeys('?','n')<CR>
nmap <silent>  *     <Plug>SearchHighlightingStar:<C-U>call SearchRepeatSet("\<Plug>SearchRepeat_n", "\<Plug>SearchRepeat_N")<CR>
nmap <silent> g*     <Plug>SearchHighlightingGStar:<C-U>call SearchRepeatSet("\<Plug>SearchRepeat_n", "\<Plug>SearchRepeat_N")<CR>
vmap <silent>  *     <Plug>SearchHighlightingStar:<C-U>call SearchRepeatSet("\<Plug>SearchRepeat_n", "\<Plug>SearchRepeat_N")<CR>

" vim: set sts=4 sw=4 noexpandtab ff=unix fdm=syntax :

