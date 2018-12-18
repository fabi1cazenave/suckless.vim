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
    " highlighting
    let line .= (i+1 == tabpagenr()) ? '%#TabLineSel#' : '%#TabLine#'
    " set the tab page number (for mouse clicks)
    let line .= '%' . (i+1) . 'T'
    " tab number + active buffer name
    let line .= SucklessTabLabel(i+1)
  endfor

  " after the last tab fill with TabLineFill and reset tab page nr
  let line .= '%#TabLineFill#%T'

  " right-align the 'X' label to close the current tab page
  if tabpagenr('$') > 1
    let line .= '%=%#TabLine#%999X X'
  endif

  return line
endfunction "}}}
if (!exists('g:suckless_tabline') || g:suckless_tabline)
  set tabline=%!SucklessTabLine()
endif

" SucklessTabLabel: GUI tabs
function! SucklessTabLabel(...) "{{{
  let space = a:0 ? '' : ' '
  let tabnr = a:0 ? a:1 : v:lnum
  let buflist = tabpagebuflist(tabnr)

  " [num] + modified since the last save?
  let label = ' [' . tabnr
  for bufnr in buflist
    if getbufvar(bufnr, '&modified')
      let label .= '*'
      break
    endif
  endfor
  let label .= ']' . space

  " buffer name
  let buf = buflist[tabpagewinnr(tabnr) - 1]
  let name = bufname(buf)
  if name =~ '^term://.*:'
    " display the process name (XXX fails if there's a space in the path)
    let label .= fnamemodify(name, ':s/^term:.*://:s/\s.*//:t:r')
  else
    " display the file name
    let label .= fnamemodify(name, ':t')
  endif

  return label . (getbufvar(buf, '&modified') ? ' + ' : ' ')
endfunction "}}}
if (!exists('g:suckless_guitablabel') || g:suckless_guitablabel)
  set guitablabel=%!SucklessTabLabel()
endif

" SelectTab: select tab by view number or by direction
function! SelectTab(dir_or_viewnr, ...) "{{{
  if type(a:dir_or_viewnr) == 0
    if a:dir_or_viewnr >= 9 || a:dir_or_viewnr > tabpagenr('$')
      tablast
    else
      exe "tabnext " . a:dir_or_viewnr
    endif
  elseif a:dir_or_viewnr == 'h'
    tabprev
  elseif a:dir_or_viewnr == 'l'
    tabnext
  endif
endfunction "}}}

" MoveTab: move tab to the left or right
function! MoveTab(direction, ...) "{{{
  let tabnr = tabpagenr()
  if a:direction == 'h' && tabnr > 1
    exe "tabmove " . (tabnr - 2)
  elseif a:direction == 'l' && tabnr < tabpagenr('$')
    exe "tabmove " . (tabnr + 1)
  endif
  if a:0 | startinsert | endif
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
  let viewnr = a:viewnr < 9 ? a:viewnr : tabpagenr('$')
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

function! MoveWindowToTab(viewnr, ...)
  call s:MoveToTab(a:viewnr, 0)
  if a:0 | startinsert | endif
endfunction

function! CopyWindowToTab(viewnr, ...)
  call s:MoveToTab(a:viewnr, 1)
  if a:0 | startinsert | endif
endfunction

function! CreateTab(...)
  tabnew
endfunction
"}}}

"|    Window Tiles: selection, movement, resizing                           {{{
"|-----------------------------------------------------------------------------

function! GetTilingMode(mode) "{{{
  if !exists("t:windowMode")
    let t:windowMode = a:mode
  endif
endfunction "}}}

function! SetTilingMode(mode, ...) "{{{
  " apply new window mode
  if a:mode == 'f'        " [f]ullscreen mode
    let t:windowSizes = winrestcmd()
    wincmd |              "   maximize current window vertically and horizontally
    wincmd _
    set eadirection=both
  elseif a:mode == 'd'    " [d]ivided mode
    let w:maximized = 0
    set eadirection=both  "   hack: create a new window and delete it
    wincmd n              "   to force windows to get the same height
    wincmd c
  elseif a:mode == 's'    " [s]tacked mode
    let w:maximized = 1
    wincmd _              "   maximize current window vertically
    set eadirection=hor
  endif

  " when getting back from fullscreen mode, restore all minimum widths
  if t:windowMode == 'f' && a:mode != 'f'
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
        if a:mode == 'd'
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
  if a:0 | startinsert | endif
endfunction "}}}

function! SelectWindow(direction, ...) "{{{
  let w:maximized = 0

  " issue the corresponding 'wincmd'
  let winnr = winnr()
  exe "wincmd " . a:direction

  " wrap around if needed
  if winnr() == winnr
    " vertical wrapping {{{
    if "jk" =~ a:direction
      " wrap around in current column
      if g:suckless_wrap_around_jk == 1
        let tmpnr = -1
        while tmpnr != winnr()
          let tmpnr = winnr()
          if a:direction == "j"
            wincmd k
          elseif a:direction == "k"
            wincmd j
          endif
        endwhile
      " select next/previous window
      elseif g:suckless_wrap_around_jk == 2
        if a:direction == "j"
          wincmd w
        elseif a:direction == "k"
          wincmd W
        endif
      endif
    endif "}}}
    " horizontal wrapping {{{
    if "hl" =~ a:direction
      " wrap around in current window
      if g:suckless_wrap_around_hl == 1
        let tmpnr = -1
        while tmpnr != winnr()
          let tmpnr = winnr()
          if a:direction == "h"
            wincmd l
          elseif a:direction == "l"
            wincmd h
          endif
        endwhile
      " select next/previous tab
      elseif g:suckless_wrap_around_hl == 2
        if a:direction == "h"
          if tabpagenr() > 1
            tabprev
            wincmd b
          endif
        elseif a:direction == "l"
          if tabpagenr() < tabpagenr('$')
            tabnext
            wincmd t
          endif
        endif
      endif
    endif "}}}
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
  if "hl" =~ a:direction && winwidth(0) < g:suckless_min_width
    exe "set winwidth=" . g:suckless_min_width
  endif
endfunction "}}}

function! MoveWindow(direction, ...) "{{{
  let winnr = winnr()
  let bufnr = bufnr("%")

  if a:direction == "j"        " move window to the previous row
    wincmd j
    if winnr() != winnr
      wincmd k
      wincmd x
      stopinsert
      wincmd j
    endif

  elseif a:direction == "k"    " move window to the next row
    wincmd k
    stopinsert
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
      stopinsert
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
  if a:0 | startinsert | endif
endfunction "}}}

function! ResizeWindow(direction, ...) "{{{

  function! HasAdjacentWindow(direction) "{{{
    " test if there's another window in the given direction
    let winnr = winnr()
    exe 'wincmd ' . a:direction
    let rv = (winnr() != winnr)
    if rv
      stopinsert " (just in case the adjacent window was in auto-insert)
      wincmd p   " get back to the original window
    endif
    return rv
  endfunction "}}}

  if 'jk' =~ a:direction
    let t:windowMode = 'D'
    let cmd = xor(HasAdjacentWindow('j'), 'j' == a:direction) ? '-' : '+'
    exe g:suckless_inc_height . ' wincmd ' . cmd
  elseif 'hl' =~ a:direction
    let cmd = xor(HasAdjacentWindow('l'), 'l' == a:direction) ? '<' : '>'
    exe g:suckless_inc_width . ' wincmd ' . cmd
  endif

  if a:0 | startinsert | endif
endfunction "}}}

function! CreateWindow(direction, ...) "{{{
  wincmd n
  if t:windowMode == "S"
    wincmd _
  endif
  if (a:direction == "v")
    call MoveWindow("l")
    stopinsert
  endif
endfunction "}}}

function! CollapseWindow(...) "{{{
  if t:windowMode == "D"
    resize 0
  endif
endfunction "}}}

function! CloseWindow(...) "{{{
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

" Preferences: g:MetaSendsEscape
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
" }}}

" Preferences: g:suckless_mappgins
if !exists('g:suckless_mappings') || type(g:suckless_mappings) != 4 "{{{
  let g:suckless_mappings = {
    \       '<M-[sdf]>'      :   'SetTilingMode("[sdf]")'    ,
    \       '<M-[hjkl]>'     :    'SelectWindow("[hjkl]")'   ,
    \       '<M-[HJKL]>'     :      'MoveWindow("[hjkl]")'   ,
    \     '<M-C-[hjkl]>'     :    'ResizeWindow("[hjkl]")'   ,
    \       '<M-[oO]>'       :    'CreateWindow("[sv]")'     ,
    \       '<M-w>'          :     'CloseWindow()'           ,
    \  '<Leader>[123456789]' :       'SelectTab([123456789])',
    \ '<Leader>t[123456789]' : 'MoveWindowToTab([123456789])',
    \ '<Leader>T[123456789]' : 'CopyWindowToTab([123456789])',
    \}
endif
" Warning, using <Alt-key> shortcuts is very handy but it can be tricky:
"  * may conflict with dwm/wmii - set the <Mod> key to <win> for your wm
"  * may conflict with gVim     - disable the menu to avoid this (:set go-=m)
"  * may raise problems in your terminal emulator (e.g. <M-s> on rxvt)
"  * Shift+Alt+number would be neat but depends on the keyboard layout
"}}}

" mapping helper {{{
let s:map_term = exists('g:suckless_tmap') && g:suckless_tmap
      \ && (has('nvim') || has('terminal'))

function! s:map(shortcut, action)
  let mapterm = s:map_term && a:shortcut =~ 'M-'

  function! EscapeMeta(shortcut) "{{{
    let l:shortcut = a:shortcut
    if g:MetaSendsEscape && a:shortcut =~ 'M-'
      let l:shortcut = '<Esc>' . substitute(l:shortcut, 'M-', '><', '')
      let l:shortcut = substitute(l:shortcut, '<>', '', '')
      if l:shortcut =~ '<.>$'
        let l = len(l:shortcut)
        let l:shortcut = l:shortcut[0:l-4] . l:shortcut[l-2]
      endif
    endif
    return l:shortcut
  endfunction "}}}

  function! ExpandMappings(shortcut, action) "{{{
    let mappings = []
    let regex = '\[.*\]'
    if a:shortcut =~ regex
      let r_shortcut = matchstr(a:shortcut, regex)[1:-2]
      let r_action   = matchstr(a:action,   regex)[1:-2]
      if len(r_shortcut) == len(r_action)
        for i in range(len(r_shortcut))
          let action   = substitute(a:action,   regex, r_action[i],   '')
          let shortcut = substitute(a:shortcut, regex, 
                \ escape(r_shortcut[i], '~&*'), '')
          call add(mappings, [ shortcut, action ])
        endfor
      endif
    else
      call add(mappings, [ a:shortcut, a:action ])
    endif
    return mappings
  endfunction "}}}

  for [shortcut, action] in ExpandMappings(a:shortcut, a:action)
    let map = 'map <silent> ' . EscapeMeta(shortcut)
    exe 'n' . map . ' :call ' . action . '<CR>'
    if mapterm " stay in insert mode when moving / resizing windows
      " pass a boolean '1' argument to mean we were in insert mode
      let action = substitute(action, ')$', ',1)', '')
      exe 't' . map . ' <C-\><C-n>:call ' . action . '<CR>'
    endif
  endfor
endfunction

for [ shortcut, action ] in items(g:suckless_mappings)
  call s:map(shortcut, action)
endfor
"}}}

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

if has('autocmd')
  " 'Divided' mode by default - each tab has its own window mode
  autocmd! TabEnter * call GetTilingMode('d')
  " Resize all windows when Vim is resized.
  autocmd! VimResized * call AutoResizeAllTabs()
  " developer candy: apply all changes immediately
  autocmd! BufWritePost suckless.vim source %
endif
call GetTilingMode('d')

" vim: set fdm=marker fmr={{{,}}} fdl=0:
