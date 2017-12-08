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


" The user might have remapped the [g]* commands (e.g. by using the
" SearchHighlighting plugin). We preserve these mappings (assuming they're
" remappable <Plug>-mappings).
" Note: Must check for existing mapping to avoid recursive mapping after script
" reload.
if empty(maparg('<SID>(SearchRepeat_Star)', 'n'))
    execute 'nmap <silent> <SID>(SearchRepeat_Star) ' . (empty(maparg('*', 'n')) ? '*' : maparg('*', 'n'))
endif
if empty(maparg('<SID>(SearchRepeat_GStar)', 'n'))
    execute 'nmap <silent> <SID>(SearchRepeat_GStar) ' . (empty(maparg('*', 'n')) ? 'g*' : maparg('g*', 'n'))
endif
if empty(maparg('<SID>(SearchRepeat_Star)', 'x'))
    execute 'xmap <silent> <SID>(SearchRepeat_Star) ' . (empty(maparg('*', 'x')) ? '*' : maparg('*', 'x'))
endif



" Capture changes in the search pattern.

" In the standard search, the two directions never swap (it's always n/N, never
" N/n), because the search direction is determined by the use of the / or ?
" commands, and handled internally in Vim.
nnoremap <expr> /  SearchRepeat#StandardCommand('/')
nnoremap <expr> ?  SearchRepeat#StandardCommand('?')

" Note: Reusing the s:SearchCommand() function to set the repeat; the storing of
" [count] doesn't matter here.
noremap  <expr> <SID>(SetRepeat)  SearchRepeat#StandardCommand('')
noremap! <expr> <SID>(SetRepeat)  SearchRepeat#StandardCommand('')
nnoremap <silent> <script>  *  <SID>(SearchRepeat_Star)<SID>(SetRepeat)
nnoremap <silent> <script> g* <SID>(SearchRepeat_GStar)<SID>(SetRepeat)
xnoremap <silent> <script>  *  <SID>(SearchRepeat_Star)<SID>(SetRepeat)



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
