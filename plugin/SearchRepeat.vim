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

let s:lastSearch = ["\<Plug>SearchRepeat_n", "\<Plug>SearchRepeat_N"]

function! s:SearchSet( mapping, oppositeMapping )
    let s:lastSearch = [a:mapping, a:oppositeMapping]
endfunction

function! s:SearchWith( mapping, oppositeMapping )
    execute 'normal ' . a:mapping
    let s:lastSearch = [a:mapping, a:oppositeMapping]
endfunction

function! s:SearchRepeat( isOpposite )
    execute 'normal ' . s:lastSearch[ a:isOpposite ]
endfunction



" The mappings cannot be executed with ':normal!', so that the <Plug> mappings
" apply. The [nN] commands must be executed without remapping, or we end up in
" endless recursion. Thus, define noremapping mappings for [nN]. 
nnoremap <Plug>SearchRepeat_n n
nnoremap <Plug>SearchRepeat_N N

" n/N now repeat the last type of search. 
nnoremap <silent> n :<C-U>call <SID>SearchRepeat(0)<CR>
nnoremap <silent> N :<C-U>call <SID>SearchRepeat(1)<CR>

" Capture changes in the search pattern. 
nnoremap <silent> /  :<C-U>call <SID>SearchSet("\<Plug>SearchRepeat_n", "\<Plug>SearchRepeat_N")<CR>/
nnoremap <silent> ?  :<C-U>call <SID>SearchSet("\<Plug>SearchRepeat_n", "\<Plug>SearchRepeat_N")<CR>?
nmap <silent>  *     :<C-U>call <SID>SearchSet("\<Plug>SearchRepeat_n", "\<Plug>SearchRepeat_N")<CR><Plug>SearchHighlightingStar
nmap <silent> g*     :<C-U>call <SID>SearchSet("\<Plug>SearchRepeat_n", "\<Plug>SearchRepeat_N")<CR><Plug>SearchHighlightingGStar
vmap <silent>  *     :<C-U>call <SID>SearchSet("\<Plug>SearchRepeat_n", "\<Plug>SearchRepeat_N")<CR>gv<Plug>SearchHighlightingStar

nnoremap <silent> gn :<C-U>call <SID>SearchWith("\<Plug>MarkSearchAnyNext", "\<Plug>MarkSearchAnyPrev")<CR>
nnoremap <silent> gN :<C-U>call <SID>SearchWith("\<Plug>MarkSearchAnyPrev", "\<Plug>MarkSearchAnyNext")<CR>
nnoremap <silent> gm :<C-U>call <SID>SearchWith("\<Plug>MarkSearchCurrentNext", "\<Plug>MarkSearchCurrentPrev")<CR>
nnoremap <silent> gM :<C-U>call <SID>SearchWith("\<Plug>MarkSearchCurrentPrev", "\<Plug>MarkSearchCurrentNext")<CR>

" vim: set sts=4 sw=4 noexpandtab ff=unix fdm=syntax :

