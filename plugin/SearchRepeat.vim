" SearchRepeat.vim: Repeat the last type of search via n/N.
"
" DEPENDENCIES:
"   - SearchRepeat.vim autoload script
"   - ingo/err.vim autoload script
"
" Copyright: (C) 2008-2017 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>

" Avoid installing twice or when in unsupported Vim version.
if exists('g:loaded_SearchRepeat') || (v:version < 700)
    finish
endif
let g:loaded_SearchRepeat = 1

"- configuration ---------------------------------------------------------------

if ! exists('g:SearchRepeat_MappingPrefixNext')
    let g:SearchRepeat_MappingPrefixNext = 'gn'
endif
if ! exists('g:SearchRepeat_MappingPrefixPrev')
    let g:SearchRepeat_MappingPrefixPrev = 'gN'
endif
if ! exists('g:SearchRepeat_IsAlwaysForwardWith_n')
    let g:SearchRepeat_IsAlwaysForwardWith_n = 0
endif
if ! exists('g:SearchRepeat_IsResetToStandardSearch')
    let g:SearchRepeat_IsResetToStandardSearch = 1
endif



"- mappings --------------------------------------------------------------------

" Note: The mappings cannot be executed with ':normal!', so that the <Plug>
" mappings apply. The [nN] commands must be executed without remapping, or we
" end up in endless recursion. Thus, define noremapping mappings for [nN].
nnoremap <silent> <Plug>(SearchRepeat_n) :<C-u>call SearchRepeat#RepeatSearch(0)<CR>
nnoremap <silent> <Plug>(SearchRepeat_N) :<C-u>call SearchRepeat#RepeatSearch(1)<CR>

" During repetition, 'hlsearch' must be explicitly turned on, but without
" echoing of the command. This is the <silent> mapping that does this inside
" SearchRepeat#Repeat().
nnoremap <silent> <Plug>(SearchRepeat_hlsearch) :<C-U>if &hlsearch<Bar>set hlsearch<Bar>endif<CR>
inoremap <silent> <Plug>(SearchRepeat_hlsearch) <C-\><C-O>:<C-U>if &hlsearch<Bar>set hlsearch<Bar>endif<CR>

nnoremap <silent> n :<C-u>if ! SearchRepeat#Repeat(0)<Bar>echoerr ingo#err#Get()<Bar>endif<CR>
nnoremap <silent> N :<C-u>if ! SearchRepeat#Repeat(1)<Bar>echoerr ingo#err#Get()<Bar>endif<CR>



" Capture changes in the search pattern.

" In the standard search, the two directions never swap (it's always n/N, never
" N/n), because the search direction is determined by the use of the / or ?
" commands, and handled internally in Vim.
nnoremap <expr> /  SearchRepeat#StandardCommand('/')
nnoremap <expr> ?  SearchRepeat#StandardCommand('?')



" Auxiliary mappings.

nnoremap <silent> <Plug>(SearchRepeatToggleResetToStandard) :<C-u>call SearchRepeat#ToggleResetToStandard()<CR>
if ! hasmapto('<Plug>(SearchRepeatToggleResetToStandard)', 'n')
    execute printf('nmap <Leader>t%s <Plug>(SearchRepeatToggleResetToStandard)', g:SearchRepeat_MappingPrefixNext)
endif

nnoremap <silent> <Plug>(SearchRepeatHelp) :<C-U>call SearchRepeat#Help()<CR>
if ! hasmapto('<Plug>(SearchRepeatHelp)', 'n')
    execute printf('nmap %s <Plug>(SearchRepeatHelp)', g:SearchRepeat_MappingPrefixNext)
endif


"- autocmds --------------------------------------------------------------------

augroup SearchRepeat
    autocmd! User LastSearchPatternChanged call SearchRepeat#OnUpdateOfLastSearchPattern()
augroup END

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
