" SearchRepeat.vim: Repeat the last type of search via n/N. 
"
" Copyright: (C) 2008-2009 by Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'. 
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS 
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

let s:lastSearch = ["\<Plug>SearchRepeat_n", "\<Plug>SearchRepeat_N", 2, {}]
let s:lastSearchDescription = ''

function! SearchRepeat#Set( mapping, oppositeMapping, howToHandleCount, ... )
    let s:lastSearch = [a:mapping, a:oppositeMapping, a:howToHandleCount, (a:0 ? a:1 : {})]
    let s:lastSearchDescription = s:registrations[a:mapping][2]
endfunction
function! SearchRepeat#Execute( mapping, oppositeMapping, howToHandleCount, ... )
    call SearchRepeat#Set(a:mapping, a:oppositeMapping, a:howToHandleCount, (a:0 ? a:1 : {}))
    call SearchRepeat#Repeat(0)
endfunction
function! SearchRepeat#Repeat( isOpposite )
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

    try
	execute 'normal'  l:searchCommand 

	" Note: Via :normal, 'hlsearch' isn't turned on, but we also cannot use
	" feedkeys(), which would break macro playback. Thus, we use feedkeys() to
	" turn on 'hlsearch' (via a <silent> mapping, so it isn't echoed), unless
	" the current search type explicitly opts out of this. 
	" Note: Only turn on 'hlsearch' if no Vim error occurred (like "E486:
	" Pattern not found"); otherwise, the <Plug>SearchRepeat_hlsearch
	" mapping (though <silent>) would clear a long error message which
	" causes the Hit-Enter prompt. In case of a search error, there's
	" nothing to highlight, anyway. 
	if get(s:lastSearch[3], 'hlsearch', 1)
	    call feedkeys("\<Plug>SearchRepeat_hlsearch")
	endif

	" Apart from the 'hlsearch' flag, arbitrary (mapped) key sequences can
	" be appended via the 'keys' configuration. This could e.g. be used to
	" implement the opposite of 'hlsearch', turning off search highlighting,
	" by nnoremap <silent> <Plug>SearchHighlightingOff :nohlsearch<CR>, then
	" setting 'keys' to "\<Plug>SearchHighlightingOff". 
	let l:keys = get(s:lastSearch[3], 'keys', '')
	if ! empty(l:keys)
	    call feedkeys(l:keys)
	endif
    catch /^Vim\%((\a\+)\)\=:E/
	echohl ErrorMsg
	" v:exception contains what is normally in v:errmsg, but with extra
	" exception source info prepended, which we cut away. 
	let v:errmsg = substitute(v:exception, '^Vim\%((\a\+)\)\=:', '', '')
	echomsg v:errmsg
	echohl None
    endtry
    "call feedkeys( l:searchCommand )
endfunction



"- integration point for search type ------------------------------------------
function! SearchRepeat#LastSearchDescription()
    return s:lastSearchDescription
endfunction

"- registration and context help ----------------------------------------------
let s:registrations = {}
function! SearchRepeat#Register( mapping, keysToActivate, keysToReactivate, description, helptext, relatedCommands )
    let s:registrations[ a:mapping ] = [ a:keysToActivate, a:keysToReactivate, a:description, a:helptext, a:relatedCommands ]
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
    echohl Title
    echo "activation\tdescription\thelptext\t\t\t\t\trelated commands"
    echohl None

    for [l:mapping, l:info] in sort( items(s:registrations), 's:SortByReactivation' )
	if l:mapping == s:lastSearch[0]
	    echohl ModeMsg
	endif

	" Strip off the /.../ or ?...? indicator for the search direction; it
	" just adds visual clutter to the list. 
	let l:description = substitute(l:info[2], '^\([/?]\)\(.*\)\1$', '\2', '')

	echo l:info[1] . "\t" . l:info[0] . "\t" . l:description. s:FixedTabWidth(16, l:description, l:info[3]) . (empty(l:info[4]) ? '' : s:FixedTabWidth(48, l:info[3], l:info[4]))
	echohl None
    endfor
endfunction

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
