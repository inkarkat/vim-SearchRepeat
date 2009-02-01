" SearchRepeat.vim: Repeat the last type of search via n/N. 
"
" Copyright: (C) 2008 by Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'. 
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS 
"	002	07-Aug-2008	BF: Need to sort twice.
"	001	05-Aug-2008	Split off autoload functions from plugin script. 

let s:lastSearch = ["\<Plug>SearchRepeat_n", "\<Plug>SearchRepeat_N", 2]

function! SearchRepeat#Set( mapping, oppositeMapping, howToHandleCount )
    let s:lastSearch = [a:mapping, a:oppositeMapping, a:howToHandleCount]
endfunction

function! SearchRepeat#Execute( mapping, oppositeMapping, howToHandleCount )
    let s:lastSearch = [a:mapping, a:oppositeMapping, a:howToHandleCount]
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

    " Note: Via :normal, hlsearch isn't turned on, and the 'E486: Pattern not
    " found' causes an exception. feedkeys() fixes both problems. 
    "execute 'normal'  l:searchCommand 
    call feedkeys( l:searchCommand )
endfunction



"- registration and context help ----------------------------------------------
let s:registrations = {}
function! SearchRepeat#Register( mapping, keysToActivate, keysToReactivate, helptext )
    let s:registrations[ a:mapping ] = [ a:keysToActivate, a:keysToReactivate, a:helptext ]
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
	" ASCII-ascending. 
	return s1 > s2 ? 1 : -1
    endif
endfunction
function! SearchRepeat#Help()
    echohl Title
    echo "react.\tact.\tdescription"
    echohl NONE

    " Since our custom sort function treats both 'abcd' and 'aAbB' as sorted, we
    " need to sort twice. 
    for [l:mapping, l:info] in sort( sort( items(s:registrations), 's:SortByReactivation' ), 's:SortByReactivation')
	if l:mapping == s:lastSearch[0]
	    echohl ModeMsg
	endif
	echo l:info[1] . "\t" . l:info[0] . "\t" . l:info[2]
	echohl NONE
    endfor
endfunction

" vim: set sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
