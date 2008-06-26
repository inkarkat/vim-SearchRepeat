" SearchRepeat.vim: Repeat the last type of search via n/N. 
"
" DESCRIPTION:
" USAGE:
" INSTALLATION:
" DEPENDENCIES:
" CONFIGURATION:
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

nnoremap <Plug>SearchRepeat_n n
nnoremap <Plug>SearchRepeat_N N

let s:lastSearch = ["\<Plug>SearchRepeat_n", "\<Plug>SearchRepeat_N"]

function! s:SearchWith( mapping, oppositeMapping )
    execute 'normal ' . a:mapping
    let s:lastSearch = [a:mapping, a:oppositeMapping]
endfunction

function! s:SearchRepeat( isOpposite )
    execute 'normal ' . s:lastSearch[ a:isOpposite ]
endfunctio

nnoremap <silent> n :<C-U>call <SID>SearchRepeat(0)<CR>
nnoremap <silent> N :<C-U>call <SID>SearchRepeat(1)<CR>

nmap <silent> gn :<C-U>call <SID>SearchWith("\<Plug>MarkSearchAnyNext", "\<Plug>MarkSearchAnyPrev")<CR>
nmap <silent> gN :<C-U>call <SID>SearchWith("\<Plug>MarkSearchAnyPrev", "\<Plug>MarkSearchAnyNext")<CR>
nmap <silent> gm :<C-U>call <SID>SearchWith("\<Plug>MarkSearchCurrentNext", "\<Plug>MarkSearchCurrentPrev")<CR>
nmap <silent> gM :<C-U>call <SID>SearchWith("\<Plug>MarkSearchCurrentPrev", "\<Plug>MarkSearchCurrentNext")<CR>

" vim: set sts=4 sw=4 noexpandtab ff=unix fdm=syntax :

