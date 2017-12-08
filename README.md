SEARCH REPEAT   
===============================================================================
_by Ingo Karkat_

DESCRIPTION
------------------------------------------------------------------------------

Jumping to the next / previous search match is such a common command in Vim
that the n / N keys quickly become deeply ingrained in muscle memory. So
when one has defined a custom search (e.g. aided by the SearchSpecial.vim
([vimscript #4948](http://www.vim.org/scripts/script.php?script_id=4948)) plugin), one is tempted to use n / N to repeat those,
too, but the keys will just continue to perform the default search. An
intelligent overloading of n / N is also desirable because these
single-key commands allow for quick single-stroke repeat, and there aren't
many other keys left for mapping custom searches to.

This plugin overloads the n and N commands so that custom searches (i.e.
anything except the default search via /, ?, [g]\*, [g]#) can be repeated.
Activation of a custom search makes that search the new type of search to be
repeated, until the search type is changed again. The default search is
included in that via the `/` and ? commands, too.

It can also make n always move forward and N always move backward (for
both built-in and custom searches), regardless of the current search
direction.

### SEE ALSO

- The SearchSpecial.vim ([vimscript #4948](http://www.vim.org/scripts/script.php?script_id=4948)) plugin provides generic functions
  for special search modes. Check out its plugin page for a full list of
  custom searches powered by it.

The following custom searches integrate with this plugin:

- SearchAsQuickJump.vim ([vimscript #5619](http://www.vim.org/scripts/script.php?script_id=5619)):
  Quick search without affecting 'hlsearch', search pattern and history.
- SearchInRange.vim ([vimscript #4997](http://www.vim.org/scripts/script.php?script_id=4997)):
  Limit search to range when jumping to the next search result.

### RELATED WORKS

- If you just want to change the n/N direction behavior, you can use the
  following (source: http://article.gmane.org/gmane.editors.vim.devel/37715):
 <!-- -->

    noremap <expr> n 'Nn'[v:searchforward]
    noremap <expr> N 'nN'[v:searchforward]

USAGE
------------------------------------------------------------------------------

    n / N               Repeat the last used type of search.

    gn                      List all registered search types, keys to
                            (re-)activate, and optional related search commands
                            that activate or configure that type.
                            The currently active search type is highlighted.

    Some custom searches provide dedicated :Search... commands that also activate
    the search repeat. Apart from that, you usually select and execute a custom
    search type via its gn... integration mapping.
    To change the search type back to plain normal search (without changing the
    search pattern), just type '/<Enter>'.

    <Leader>tgn             Toggle whether a change in the current search pattern
                            resets searching with n/N to standard search, or the
                            current search type is kept.
                            (g:SearchRepeat_IsResetToStandardSearch).

### EXAMPLE

Let's define a simple custom search that positions the current search result
in the middle of the window (using zz). These mappings just delegate to the
default n command, open a fold (zv, because that's not done automatically
from a mapping), and then append the zz command:

    nnoremap <silent> <Plug>(SearchAtCenterOfWindowNext) :<C-u>execute 'normal!' v:count1 . 'nzvzz'<CR>
    nnoremap <silent> <Plug>(SearchAtCenterOfWindowPrev) :<C-u>execute 'normal!' v:count1 . 'Nzvzz'<CR>

Then, integrate these into SearchRepeat, using gnzz and gnzZ to activate them:

    call SearchRepeat#Define(
    \   '<Plug>(SearchAtCenterOfWindowNext)', '<Plug>(SearchAtCenterOfWindowPrev)',
    \   '', 'zz', 'win-center', 'Search, position at center of window', '',
    \   2
    \)

The gn command will now show the newly added custom search in addition to
the built-in standard search:
```
activation      identifier      description
        /       Standard search
gnzz            win-center      Search, position at center of window
```

To activate, search for /something, then press gnzz. From now on, the n /
N commands will also center the match (and the gnzz search type is
highlighted in the gn list), until you reset the search type with another
/search.

INSTALLATION
------------------------------------------------------------------------------

The code is hosted in a Git repo at
    https://github.com/inkarkat/vim-SearchRepeat
You can use your favorite plugin manager, or "git clone" into a directory used
for Vim packages. Releases are on the "stable" branch, the latest unstable
development snapshot on "master".

This script is also packaged as a vimball. If you have the "gunzip"
decompressor in your PATH, simply edit the \*.vmb.gz package in Vim; otherwise,
decompress the archive first, e.g. using WinZip. Inside Vim, install by
sourcing the vimball or via the :UseVimball command.

    vim SearchRepeat*.vmb.gz
    :so %

To uninstall, use the :RmVimball command.

### DEPENDENCIES

- Requires Vim 7.0 or higher.
- Requires the ingo-library.vim plugin ([vimscript #4433](http://www.vim.org/scripts/script.php?script_id=4433)), version 1.025 or
  higher.

CONFIGURATION
------------------------------------------------------------------------------

For a permanent configuration, put the following commands into your vimrc:

By default, when a backwards search (e.g. ?foo?) is configured, the n
command jumps backwards, too, so the search direction affects the behavior of
n / N. Some prefer to have n / N behave consistently, regardless of
the current search direction, i.e. have n always move forward and N always
move backward. This can be achieved for both built-in and custom searches by
setting:

    let g:SearchRepeat_IsAlwaysForwardWith_n = 1

Note: This requires Vim 7.2 or later.

Whenever the current search pattern (quote/) changes, searches with n/N are
reset to the standard search; it is assumed that a custom search was bound to
a particular search pattern, and once the pattern changes the scope of the
custom search has ended. To disable that, use:

    let g:SearchRepeat_IsResetToStandardSearch = 0

After that, you have to explicitly switch back to standard search with gn/ /
gn? (provided by SearchStandardSearch.vim).

To change the default mapping prefixes for forward / backward search, use:

    let g:SearchRepeat_MappingPrefixNext = 'gn'
    let g:SearchRepeat_MappingPrefixPrev = 'gN'

This will affect all SearchRepeat integrations done by custom searches, and by
default also the gn list of all registered search types, and the toggling of
reset to standard search mapping. To change the latter ones separately, use:

    nmap <Leader>gn <Plug>(SearchRepeatHelp)
    nmap <Leader>tgn <Plug>(SearchRepeatToggleResetToStandard)

INTEGRATION
------------------------------------------------------------------------------

To set the current search type (in a custom search mapping):

    :call SearchRepeat#Set("\<Plug>MyCustomSearchMapping", "\<Plug>MyCustomOppositeSearchMapping", 2)

To set the current search type (in a custom search mapping) and execute the
(first with 0, opposite with 1 as first argument) search mapping:

    if ! SearchRepeat#Execute(0, "\<Plug>MyCustomSearchMapping", "\<Plug>MyCustomOppositeSearchMapping", 2)
        echoerr ingo#err#Get()
    endif

The third argument specifies how the mappings deal with an optional [count]
that is passed to the n / N commands:
    0: Doesn't handle count, single invocation only. No count is prepended to
       the search mapping, which is invoked only once. (But the count itself
       is still available through v:count.)
    1: Doesn't handle count itself, invoke search mapping multiple times.
    2: Handles count itself, prepend count before search mapping.

An optional fourth argument supplies additional configuration in a dictionary;
see the SearchRepeat#Set() function for details.

But normally, you'd define the (optional) SearchRepeat integration via the
single SearchRepeat#Define() convenience function, at the end of your custom
search plugin:

    try
        call SearchRepeat#Define(...)
    catch /^Vim\%((\a\+)\)\=:E117/      " catch error E117: Unknown function
    endtry

Look up the function definition for details on the arguments.

The repeated search type may be affected by changes to the last search pattern
(quote/; via g:SearchRepeat\_IsResetToStandardSearch). Other plugins or
customizations that change register / may notify SearchRepeat about this by
firing a User event:

    let @/ = "new pattern"
    silent doautocmd User LastSearchPatternChanged

This is purely optional; the effects of that are only noticeable if the
current search type is indicated in the 'titlestring' or 'statusline', for
example. Even without the event, SearchRepeat will recognize and evaluate the
patter change on the next navigation with n / N, anyway.

CONTRIBUTING
------------------------------------------------------------------------------

Report any bugs, send patches, or suggest features via the issue tracker at
https://github.com/inkarkat/vim-SearchRepeat/issues or email (address below).

HISTORY
------------------------------------------------------------------------------

##### 2.00    08-Dec-2017
- CHG: Split g:SearchRepeat\_MappingPrefix into two
  g:SearchRepeat\_MappingPrefixNext and g:SearchRepeat\_MappingPrefixPrev. With
  this, custom searches only need to register a single suffix for forward /
  backward searches. This both frees up keys (which I'm running out of with my
  many custom searches), and enables non-alphabetic suffixes
  (SearchForExpr.vim is now using gn= instead of gne / gnE).
- CHG: Simplify SearchRepeat#Define() API: Get rid of duplicate suffixes,
  descriptions, helptexts, related commands for next / prev mappings. Instead,
  forward / backward search is now handled by separate gn / gN mapping
  prefixes.
- CHG: Mapping registration only stores the "Next" mapping, and the gn help
  command only lists those (to reduce clutter and duplication). The "Prev"
  mapping is now stored in s:reverseRegistrations.
- Remember the contents of @/ and reset to standard search when it changed
  (e.g. by \* / g\*, or plugins like my SearchAlternatives.vim).
- Make this configurable via g:SearchRepeat\_IsResetToStandardSearch and enable
  toggling via new <Leader>tgn mapping.
- ENH: Omit related commands and condense activation commands column in search
  type list when in small-width Vim, to avoid line breaks that make the layout
  hard to read.
- ENH: Support "isResetToStandardSearch" option flag that overrides the
  g:SearchRepeat\_IsResetToStandardSearch configuration value for certain
  integrations.
- Rename "description" to "identifier" and "helptext" to "description" in gn
  help and function arguments.
- ENH: Other plugins and customizations can emit a User
  LastSearchPatternChanged event to notify SearchRepeat of changes to @/.
  __You need to update to ingo-library ([vimscript #4433](http://www.vim.org/scripts/script.php?script_id=4433)) version 1.025!__

##### 1.11    29-Apr-2016
- FIX: v:searchforward requires Vim 7.2; don't support the
  g:SearchRepeat\_IsAlwaysForwardWith\_n configuration in older versions.

##### 1.10    31-May-2014
- CHG: Add isOpposite flag to SearchRepeat#Execute() and remove the swapping
  of a:mappingNext and a:mappingPrev in the opposite mapping definition.
- ENH: Add g:SearchRepeat\_IsAlwaysForwardWith\_n configuration to consistently
  always move forward / backward with n / N, regardless of whether the current
  search mode goes into the opposite direction.
- FIX: SearchRepeat#Execute() needs to return status of SearchRepeat#Repeat()
  to have clients :echoerr any error.

##### 1.00    26-May-2014
- First published version.

##### 0.01    27-Jun-2008
- Started development.

------------------------------------------------------------------------------
Copyright: (C) 2008-2017 Ingo Karkat -
The [VIM LICENSE](http://vimdoc.sourceforge.net/htmldoc/uganda.html#license) applies to this plugin.

Maintainer:     Ingo Karkat <ingo@karkat.de>
