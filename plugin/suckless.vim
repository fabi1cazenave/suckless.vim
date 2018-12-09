"|
"| File    : ~/.vim/plugin/suckless.vim
"| File    : ~/.config/nvim/plugin/suckless.vim
"| Source  : https://github.com/fabi1cazenave/suckless.vim
"| Author  : Fabien Cazenave
"| Licence : WTFPL
"|
"| Tiling window management that sucks less - see http://suckless.org/
"| This emulates wmii/i3 in Vim & Neovim as much as possible.
"|

" Preferences: window resizing
if !exists('g:suckless_min_width')
  let g:suckless_min_width = 24         " minimum window width
endif
if !exists('g:suckless_inc_width')
  let g:suckless_inc_width = 12         " width increment
endif
if !exists('g:suckless_inc_height')
  let g:suckless_inc_height = 6         " height increment
endif

" Preferences: wrap-around modes for window selection
if !exists('g:suckless_wrap_around_jk') " 0 = no wrap
  let g:suckless_wrap_around_jk = 1     " 1 = wrap in current column (wmii-like)
endif                                   " 2 = wrap in current tab    (dwm-like)
if !exists('g:suckless_wrap_around_hl') " 0 = no wrap
  let g:suckless_wrap_around_hl = 1     " 1 = wrap in current tab    (wmii-like)
endif                                   " 2 = wrap in all tabs

"|    Tabs / Views: organize windows in tabs                                {{{
"|-----------------------------------------------------------------------------

" SucklessTabLine: terminal tabs
function! SucklessTabLine() "{{{
  let line = ''
  for i in range(tabpagenr('$'))
    " select the highlighting
    if i+1 == tabpagenr()
      let line .= '%#TabLineSel#'
    else
      let line .= '%#TabLine#'
    endif

    " set the tab page number (for mouse clicks)
    let line .= '%' . (i+1) . 'T'
    let line .= ' [' . (i+1)

    " modified since the last save?
    let buflist = tabpagebuflist(i+1)
    for bufnr in buflist
      if getbufvar(bufnr, '&modified')
        let line .= '*'
        break
      endif
    endfor
    let line .= ']'

    " add the file name without path information
    let buf = buflist[tabpagewinnr(i+1) - 1]
    let name = bufname(buf)
    if getbufvar(buf, '&modified') == 1
      let name .= " +"
    endif
    let line .= fnamemodify(name, ':t') . ' '
  endfor

  " after the last tab fill with TabLineFill and reset tab page nr
  let line .= '%#TabLineFill#%T'

  " right-align the label to close the current tab page
  if tabpagenr('$') > 1
    let line .= '%=%#TabLine#%999X X'
  endif
  "echomsg 's:' . s
  return line
endfunction "}}}
if (!exists('g:suckless_tabline') || g:suckless_tabline)
  set tabline=%!SucklessTabLine()
endif

" SucklessTabLabel: GUI tabs
function! SucklessTabLabel() "{{{
  " see: http://blog.golden-ratio.net/2008/08/19/using-tabs-in-vim/

  " add the Tab number
  let label = '['.tabpagenr()

  " modified since the last save?
  let buflist = tabpagebuflist(v:lnum)
  for bufnr in buflist
    if getbufvar(bufnr, '&modified')
      let label .= '*'
      break
    endif
  endfor

  " count number of open windows in the Tab
  "let wincount = tabpagewinnr(v:lnum, '$')
  "if wincount > 1
    "let label .= ', '.wincount
  "endif
  let label .= '] '

  " add the file name without path information
  let name = bufname(buflist[tabpagewinnr(v:lnum) - 1])
  let label .= fnamemodify(name, ':t')
  if &modified == 1
    let label .= " +"
  endif

  return label
endfunction "}}}
if (!exists('g:suckless_guitablabel') || g:suckless_guitablabel)
  set guitablabel=%!SucklessTabLabel()
endif
 
" TabSelect:
function! TabSelect(viewnr) "{{{
  if a:viewnr >= 9 || a:viewnr > tabpagenr('$')
    tablast
  else
    exe 'tabnext ' . a:viewnr
  endif
endfunction "}}}

" MoveToTab: move/copy current window to another tab
function! s:MoveToTab(viewnr, copy) "{{{
  " get the current buffer ref
  let bufnr = bufnr("%")

  " remove current window if 'copy' isn't set
  if a:copy == 0
    wincmd c
  endif

  " get a window in the requested Tab
  let viewnr = a:viewnr < 9 ? a:viewnr : tabpagenr('$')
  if viewnr > tabpagenr('$')
    " the requested Tab doesn't exist, create it
    tablast
    tabnew
  else
    " select the requested Tab an add a window with the current buffer
    exe "tabnext " . viewnr
    wincmd l
    " TODO: if the buffer is already displayed in this Tab, select its window
    " TODO: if this tab is in 'stacked' or 'fullscreen' mode, expand window
    " TODO: if there's already an empty window, reuse it
    wincmd n
  endif

  " display the current buffer
  exe "b" . bufnr
endfunction "}}}
function! MoveWindowToTab(viewnr)
  call s:MoveToTab(a:viewnr, 0)
endfunction
function! CopyWindowToTab(viewnr)
  call s:MoveToTab(a:viewnr, 1)
endfunction
"}}}

"|    Window Tiles: selection, movement, resizing                           {{{
"|-----------------------------------------------------------------------------

function! GetTilingMode(mode) "{{{
  if !exists("t:windowMode")
    let t:windowMode = a:mode
  endif
endfunction "}}}

function! SetTilingMode(mode) "{{{
  " apply new window mode
  if a:mode == "F"        " Fullscreen mode
    let t:windowSizes = winrestcmd()
    wincmd |              "   maximize current window vertically and horizontally
    wincmd _
    set eadirection=both
  elseif a:mode == "D"    " Divided mode
    let w:maximized = 0
    set eadirection=both  "   hack: create a new window and delete it
    wincmd n              "   to force windows to get the same height
    wincmd c
  elseif a:mode == "S"    " Stacked mode
    let w:maximized = 1
    wincmd _              "   maximize current window vertically
    set eadirection=hor
  endif

  " when getting back from fullscreen mode, restore all minimum widths
  if t:windowMode == "F" && a:mode != "F"
    if exists("t:windowSizes")
      exe t:windowSizes
    else
      " store current window number
      let winnr = winnr()
      " check all columns
      wincmd t
      let tmpnr = 0
      while tmpnr != winnr()
        " restore min width if this column is collapsed
        if winwidth(0) < g:suckless_min_width
          exe "set winwidth=" . g:suckless_min_width
        endif
        " balance window heights in this column if switching to 'Divided' mode
        if a:mode == "D"
          wincmd n
          wincmd c
        endif
        " next column
        let tmpnr = winnr()
        wincmd l
      endwhile
      " select window #winnr
      exe winnr . "wincmd w"
    endif
  endif

  " store the new window mode in the current tab's global variables
  let t:windowMode = a:mode
endfunction "}}}

function! WindowCmd(cmd) "{{{
  let w:maximized = 0

  " issue the corresponding 'wincmd'
  let winnr = winnr()
  exe "wincmd " . a:cmd

  " wrap around if needed
  if winnr() == winnr
    " vertical wrapping {{{
    if "jk" =~ a:cmd
      " wrap around in current column
      if g:suckless_wrap_around_jk == 1
        let tmpnr = -1
        while tmpnr != winnr()
          let tmpnr = winnr()
          if a:cmd == "j"
            wincmd k
          elseif a:cmd == "k"
            wincmd j
          endif
        endwhile
      " select next/previous window
      elseif g:suckless_wrap_around_jk == 2
        if a:cmd == "j"
          wincmd w
        elseif a:cmd == "k"
          wincmd W
        endif
      endif
    endif "}}}
    " horizontal wrapping {{{
    if "hl" =~ a:cmd
      " wrap around in current window
      if g:suckless_wrap_around_hl == 1
        let tmpnr = -1
        while tmpnr != winnr()
          let tmpnr = winnr()
          if a:cmd == "h"
            wincmd l
          elseif a:cmd == "l"
            wincmd h
          endif
        endwhile
      " select next/previous tab
      elseif g:suckless_wrap_around_hl == 2
        if a:cmd == "h"
          if tabpagenr() > 1
            tabprev
            wincmd b
          endif
        elseif a:cmd == "l"
          if tabpagenr() < tabpagenr('$')
            tabnext
            wincmd t
          endif
        endif
      endif
    endif "}}}
  endif

  " if the window height is modified, switch to divided mode
  if "+-" =~ a:cmd
    let t:windowMode = "D"
  endif

  " resize window according to the current window mode
  if t:windowMode == "F"
    " 'Fullscreen' mode
    wincmd _   " maximize window height
    wincmd |   " maximize window width
  elseif winheight(0) <= 1
    " window is collapsed, this column must be in 'stacked' mode
    wincmd _   " maximize window height
    let w:maximized = 1
  endif

  " ensure the window width is greater or equal to the minimum
  if "hl" =~ a:cmd && winwidth(0) < g:suckless_min_width
    exe "set winwidth=" . g:suckless_min_width
  endif
endfunction "}}}

function! WindowMove(direction) "{{{
  let winnr = winnr()
  let bufnr = bufnr("%")

  if a:direction == "j"        " move window to the previous row
    wincmd j
    if winnr() != winnr
      "exe "normal <C-W><C-X>"
      wincmd k
      wincmd x
      wincmd j
    endif

  elseif a:direction == "k"    " move window to the next row
    wincmd k
    if winnr() != winnr
      wincmd x
    endif

  elseif "hl" =~ a:direction   " move window to the previous/next column
    exe "wincmd " . a:direction
    let newwinnr = winnr()
    if newwinnr == winnr
      " move window to a new column
      exe "wincmd " . toupper(a:direction)
      if t:windowMode == "S"
        wincmd p
        wincmd _
        wincmd p
      endif
    else
      " move window to an existing column
      wincmd p
      wincmd c
      if t:windowMode == "S"
        wincmd _
      endif
      exe (newwinnr - (a:direction == "l")) . "wincmd w"
      wincmd n
      if t:windowMode == "S"
        wincmd _
      endif
      exe "b" . bufnr
    endif

  endif
endfunction "}}}

function! WindowResize(direction) "{{{
  let winnr = winnr()

  if a:direction == "j"
    wincmd j
    if winnr() != winnr
      wincmd p
      exe g:suckless_inc_height . "wincmd +"
    else
      exe g:suckless_inc_height . "wincmd -"
    endif

  elseif a:direction == "k"
    wincmd j
    if winnr() != winnr
      wincmd p
      exe g:suckless_inc_height . "wincmd -"
    else
      exe g:suckless_inc_height . "wincmd +"
    endif

  elseif a:direction == "h"
    wincmd l
    if winnr() != winnr
      wincmd p
      exe g:suckless_inc_height . "wincmd <"
    else
      exe g:suckless_inc_height . "wincmd >"
    endif

  elseif a:direction == "l"
    wincmd l
    if winnr() != winnr
      wincmd p
      exe g:suckless_inc_height . "wincmd >"
    else
      exe g:suckless_inc_height . "wincmd <"
    endif

  endif
endfunction "}}}

function! WindowCreate(direction) "{{{
  wincmd n
  if t:windowMode == "S"
    wincmd _
  endif
  if (a:direction == "v")
    call WindowMove("l")
  endif
endfunction "}}}

function! WindowCollapse() "{{{
  if t:windowMode == "D"
    resize 0
  endif
endfunction "}}}

function! WindowClose() "{{{
  wincmd c
  if t:windowMode == "S"
    wincmd _
  endif
endfunction "}}}

"}}}

"|    Auto-Resize Windows                                                   {{{
"|-----------------------------------------------------------------------------

function! AutoResizeWindow() "{{{
  if w:maximized
    wincmd _
  endif
endfunction "}}}

" Cannot use this because `set eadirection=hor` does not work as expected
" function! AutoResizeAllWindows() "{{{
"   if t:windowMode == "S"
"     set eadirection=hor " XXX not working
"   else
"     set eadirection=both
"   endif
"   wincmd =
" endfunction "}}}

function! AutoResizeAllWindows() "{{{
  let winnr = winnr()
  wincmd =
  if t:windowMode == "S"
    windo call AutoResizeWindow()
  endif
  while winnr != winnr()
    wincmd w
  endwhile
endfunction "}}}

function! AutoResizeAllTabs() "{{{
  let tabnr = tabpagenr()
  tabdo call AutoResizeAllWindows()
  exe "tabnext " . tabnr
endfunction "}}}

"}}}

"|    Keyboard Mappings                                                     {{{
"|-----------------------------------------------------------------------------

" Notes about the Alt key... {{{
" Neovim users, you can ignore this paragraph. Enjoy!
" Vim users, I'm afraid that <Alt>-shortcuts are tricky with Vim:
"
"  * with gVim and MacVim, the Alt key sets the 8th bit
"    (e.g. Alt-j sends an "ê", and an "ê" is detected as Alt-j by Vim)
"    -- this is acceptable if you don't use any accented character;
"
"  * with most modern terminal emulators, the Alt key sends an <Esc>
"    (e.g. Alt-j sends <Esc>j, a.k.a. "8bit-clean" behavior)
"    -- this is acceptable if you don't mind the 'timeoutlen' after each <Esc>.
"
" When using Vim on MacOSX, you can set the `macmeta` option.
" When using gVim, here's a quick and dirty way to free all <Alt> shortcuts:
"     set guioptions-=m
"
" Vim users should set the "g:MetaSendsEscape" variable to specify the behavior.
" If unset, assume the terminal is 8-bit clean and gVim sets the 8th bit.
if has('nvim')
  let g:MetaSendsEscape = 0
elseif !exists('g:MetaSendsEscape')
  let g:MetaSendsEscape = !has('gui_running')
endif

function! s:map(shortcut, action)
  let l:shortcut = a:shortcut
  if g:MetaSendsEscape && a:shortcut =~ 'M-'
    let l:shortcut = '<Esc>' . substitute(l:shortcut, 'M-', '><', '')
    let l:shortcut = substitute(l:shortcut, '<>', '', '')
    if l:shortcut =~ '<.>$'
      let l = len(l:shortcut)
      let l:shortcut = l:shortcut[0:l-4] . l:shortcut[l-2]
    endif
  endif
  exe 'nnoremap <silent> ' . l:shortcut . ' :call ' . a:action . '<CR>'
endfunction
" }}}

if (!exists('g:suckless_map_tabs') || g:suckless_map_tabs)
  " Tab Management {{{

  " Alt+[1..9]: select Tab [1..9]
  call s:map('<M-1>', 'TabSelect(1)')
  call s:map('<M-2>', 'TabSelect(2)')
  call s:map('<M-3>', 'TabSelect(3)')
  call s:map('<M-4>', 'TabSelect(4)')
  call s:map('<M-5>', 'TabSelect(5)')
  call s:map('<M-6>', 'TabSelect(6)')
  call s:map('<M-7>', 'TabSelect(7)')
  call s:map('<M-8>', 'TabSelect(8)')
  call s:map('<M-9>', 'TabSelect(9)')

  " <Leader>[1..9]: select Tab [1..9]
  call s:map('<Leader>1', 'TabSelect(1)')
  call s:map('<Leader>2', 'TabSelect(2)')
  call s:map('<Leader>3', 'TabSelect(3)')
  call s:map('<Leader>4', 'TabSelect(4)')
  call s:map('<Leader>5', 'TabSelect(5)')
  call s:map('<Leader>6', 'TabSelect(6)')
  call s:map('<Leader>7', 'TabSelect(7)')
  call s:map('<Leader>8', 'TabSelect(8)')
  call s:map('<Leader>9', 'TabSelect(9)')

  " <Leader>t[1..9]: move current window to Tab [1..9]
  call s:map('<Leader>t1', 'MoveWindowToTab(1)')
  call s:map('<Leader>t2', 'MoveWindowToTab(2)')
  call s:map('<Leader>t3', 'MoveWindowToTab(3)')
  call s:map('<Leader>t4', 'MoveWindowToTab(4)')
  call s:map('<Leader>t5', 'MoveWindowToTab(5)')
  call s:map('<Leader>t6', 'MoveWindowToTab(6)')
  call s:map('<Leader>t7', 'MoveWindowToTab(7)')
  call s:map('<Leader>t8', 'MoveWindowToTab(8)')
  call s:map('<Leader>t9', 'MoveWindowToTab(9)')

  " <Leader>T[1..9]: copy current window to Tab [1..9]
  call s:map('<Leader>T1', 'CopyWindowToTab(1)')
  call s:map('<Leader>T2', 'CopyWindowToTab(2)')
  call s:map('<Leader>T3', 'CopyWindowToTab(3)')
  call s:map('<Leader>T4', 'CopyWindowToTab(4)')
  call s:map('<Leader>T5', 'CopyWindowToTab(5)')
  call s:map('<Leader>T6', 'CopyWindowToTab(6)')
  call s:map('<Leader>T7', 'CopyWindowToTab(7)')
  call s:map('<Leader>T8', 'CopyWindowToTab(8)')
  call s:map('<Leader>T9', 'CopyWindowToTab(9)')

  "}}}
endif

if (!exists('g:suckless_map_windows') || g:suckless_map_windows)
  " Window Management {{{

  " Alt+[SDF]: Window mode selection
  call s:map('<M-s>', 'SetTilingMode("S")')
  call s:map('<M-d>', 'SetTilingMode("D")')
  call s:map('<M-f>', 'SetTilingMode("F")')

  " Alt+[hjkl]: select window
  call s:map('<M-h>', 'WindowCmd("h")')
  call s:map('<M-j>', 'WindowCmd("j")')
  call s:map('<M-k>', 'WindowCmd("k")')
  call s:map('<M-l>', 'WindowCmd("l")')

  " Alt+[HJKL]: move current window
  call s:map('<M-H>', 'WindowMove("h")')
  call s:map('<M-J>', 'WindowMove("j")')
  call s:map('<M-K>', 'WindowMove("k")')
  call s:map('<M-L>', 'WindowMove("l")')

  " Ctrl+Alt+[hjkl]: resize current window
  call s:map('<M-C-h>', 'WindowResize("h")')
  call s:map('<M-C-j>', 'WindowResize("j")')
  call s:map('<M-C-k>', 'WindowResize("k")')
  call s:map('<M-C-l>', 'WindowResize("l")')

  " Alt+[oO]: new horizontal/vertical window
  call s:map('<M-o>', 'WindowCreate("s")')
  call s:map('<M-O>', 'WindowCreate("v")')

  " Alt+[cw]: collapse/close current window
  call s:map('<M-c>', 'WindowCollapse()')
  call s:map('<M-w>', 'WindowClose()')

  "}}}
endif

" Public API for user-defined mappings
function! suckless#nnoremap(shortcut, action)
  call s:map(a:shortcut, a:action)
endfunction
"}}}

"|    TODO (not working yet)                                                {{{
"|-----------------------------------------------------------------------------

" tiling modes {{{
" Two modes should be possible:
"  * wmii: use as many columns as you want
"  *  dwm: one master window + one column for all other windows
"
" The wmii-mode is working properly, though there are a few difference with wmii:
"  * no 'maximized' mode (*sigh*)
"  * there's one stacking mode per tab, whereas wmii has one stacking mode per column.
"
" The dwm-mode would need some work to become usable:
"  * the master area should be able to have more than one window (ex: help)
"  * a specific event handler should prevent to create another column
"  * a specific column next to the master area (on the left) would be required
"    for other plugins such as project.tar.gz, ctags, etc.
"
" I think the wmii-mode makes much more sense for Vim anyway. ;-)
" }}}

" preferences {{{
" Preferences: key mappings to handle windows and tabs
" Warning, using <Alt-key> shortcuts is very handy but it can be tricky:
"  * may conflict with dwm/wmii - set the <Mod> key to <win> for your wm
"  * may conflict with gVim     - disable the menu to avoid this
"  * may raise problems in your terminal emulator (e.g. <M-s> on rxvt)
"  * Shift+Alt+number only works on the US-Qwerty keyboard layout
let g:SucklessWinKeyMappings = 3  " 0 = none - define your own!
                                  " 1 = <Leader> + key(s)
                                  " 2 = <Alt-key>
                                  " 3 = both
let g:SucklessTabKeyMappings = 3  " 0 = none - define your own!
                                  " 1 = <Leader> + key(s)
                                  " 2 = <Alt-key>
                                  " 3 = both
let g:SucklessTilingEmulation = 1 " 0 = none - define your own!
                                  " 1 = wmii-style (preferred)
                                  " 2 = dwm-style (not working yet)
" }}}

" Master window (dwm mode) {{{
function! WindowMaster()
  " swap from/to master area
  " get the current buffer ref
  let bufnr1 = bufnr("%")
  let winnr1 = winnr()

  wincmd l
  let bufnr2 = bufnr("%")
  let winnr2 = winnr()

  "if bufnr("%") != bufnr1
  if winnr1 != winnr2
    " we were in the master area
    exe "b" . bufnr1
    wincmd h
    exe "b" . bufnr2
    "" get back (cancel action)
    "wincmd p
  else
    " we were in the secondary area
    wincmd h
    let bufnr2 = bufnr("%")
    exe "b" . bufnr1
    wincmd p
    exe "b" . bufnr2
    wincmd h
  endif
endfunction "}}}

" 'Project' sidebar {{{
function! Sidebar()
  if g:loaded_project == 1 && (!exists('g:proj_running') || bufwinnr(g:proj_running) == -1)
    Project   " call Project if hidden
  elseif bufwinnr(winnr()) < 0
    wincmd p  " we're in the Sidebar, get back to the buffer window
  else
    wincmd t  " we're in a buffer window, go to the Project Sidebar
  endif
endfunction "}}}

" }}}

if has("autocmd")
  " 'Divided' mode by default - each tab has its own window mode
  autocmd! TabEnter * call GetTilingMode("D")
  " Resize all windows when Vim is resized.
  autocmd! VimResized * call AutoResizeAllTabs()
  " developer candy: apply all changes immediately
  autocmd! BufWritePost suckless.vim source %
endif
call GetTilingMode("D")

" vim: set fdm=marker fmr={{{,}}} fdl=0:
