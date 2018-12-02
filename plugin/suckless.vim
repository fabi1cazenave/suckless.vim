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
let g:SucklessMinWidth = 24       " minimum window width
let g:SucklessIncWidth = 12       " width increment
let g:SucklessIncHeight = 6       " height increment

" Preferences: wrap-around modes for window selection
let g:SucklessWrapAroundJK = 1    " 0 = no wrap
                                  " 1 = wrap in current column (wmii-like)
                                  " 2 = wrap in current tab    (dwm-like)
let g:SucklessWrapAroundHL = 1    " 0 = no wrap
                                  " 1 = wrap in current tab    (wmii-like)
                                  " 2 = wrap in all tabs

" Notes about the Alt key... {{{
" Neovim users, you can ignore this paragraph. Enjoy!
" Vim users, I'm afraid that <Alt>-shortcuts are tricky with Vim:
"
"  * with xterm, gVim and MacVim, the Alt key sets the 8th bit
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
" }}}
if has('nvim')
  let g:MetaSendsEscape = 0
elseif !exists('g:MetaSendsEscape')
  let g:MetaSendsEscape = !has('gui_running')
endif

"|    Tabs / views: organize windows in tabs                                {{{
"|-----------------------------------------------------------------------------

set tabline=%!SucklessTabLine()
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

set guitablabel=%{SucklessTabLabel()}
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

" MoveToTab: move/copy current window to another tab
function! MoveToTab(viewnr, copy) "{{{
  " get the current buffer ref
  let bufnr = bufnr("%")

  " remove current window if 'copy' isn't set
  if a:copy == 0
    wincmd c
  endif

  " get a window in the requested Tab
  if a:viewnr > tabpagenr('$')
    " the requested Tab doesn't exist, create it
    tablast
    tabnew
  else
    " select the requested Tab an add a window with the current buffer
    exe "tabn " . a:viewnr
    wincmd l
    " TODO: if the buffer is already displayed in this Tab, select its window
    " TODO: if this tab is in 'stacked' or 'fullscreen' mode, expand window
    " TODO: if there's already an empty window, reuse it
    wincmd n
  endif

  " display the current buffer
  exe "b" . bufnr
endfunction "}}}

"}}}

"|    Window tiles: selection, movement, resizing                           {{{
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
        if winwidth(0) < g:SucklessMinWidth
          exe "set winwidth=" . g:SucklessMinWidth
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
      if g:SucklessWrapAroundJK == 1
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
      elseif g:SucklessWrapAroundJK == 2
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
      if g:SucklessWrapAroundHL == 1
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
      elseif g:SucklessWrapAroundHL == 2
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
  if "hl" =~ a:cmd && winwidth(0) < g:SucklessMinWidth
    exe "set winwidth=" . g:SucklessMinWidth
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
      exe g:SucklessIncHeight . "wincmd +"
    else
      exe g:SucklessIncHeight . "wincmd -"
    endif

  elseif a:direction == "k"
    wincmd j
    if winnr() != winnr
      wincmd p
      exe g:SucklessIncHeight . "wincmd -"
    else
      exe g:SucklessIncHeight . "wincmd +"
    endif

  elseif a:direction == "h"
    wincmd l
    if winnr() != winnr
      wincmd p
      exe g:SucklessIncHeight . "wincmd <"
    else
      exe g:SucklessIncHeight . "wincmd >"
    endif

  elseif a:direction == "l"
    wincmd l
    if winnr() != winnr
      wincmd p
      exe g:SucklessIncHeight . "wincmd >"
    else
      exe g:SucklessIncHeight . "wincmd <"
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

"|    keyboard mappings, Tab management                                     {{{
"|-----------------------------------------------------------------------------

" Alt+[0..9]: select Tab [1..10] {{{
if g:MetaSendsEscape
  nnoremap <silent> <Esc>1 :tabn  1<CR>
  nnoremap <silent> <Esc>2 :tabn  2<CR>
  nnoremap <silent> <Esc>3 :tabn  3<CR>
  nnoremap <silent> <Esc>4 :tabn  4<CR>
  nnoremap <silent> <Esc>5 :tabn  5<CR>
  nnoremap <silent> <Esc>6 :tabn  6<CR>
  nnoremap <silent> <Esc>7 :tabn  7<CR>
  nnoremap <silent> <Esc>8 :tabn  8<CR>
  nnoremap <silent> <Esc>9 :tabn  9<CR>
  nnoremap <silent> <Esc>0 :tabn 10<CR>
else
  nnoremap <silent>  <M-1> :tabn  1<CR>
  nnoremap <silent>  <M-2> :tabn  2<CR>
  nnoremap <silent>  <M-3> :tabn  3<CR>
  nnoremap <silent>  <M-4> :tabn  4<CR>
  nnoremap <silent>  <M-5> :tabn  5<CR>
  nnoremap <silent>  <M-6> :tabn  6<CR>
  nnoremap <silent>  <M-7> :tabn  7<CR>
  nnoremap <silent>  <M-8> :tabn  8<CR>
  nnoremap <silent>  <M-9> :tabn  9<CR>
  nnoremap <silent>  <M-0> :tabn 10<CR>
endif
"}}}

" <Leader>[1..0]: select Tab [1..10] {{{
nnoremap <silent> <Leader>1 :tabn  1<CR>
nnoremap <silent> <Leader>2 :tabn  2<CR>
nnoremap <silent> <Leader>3 :tabn  3<CR>
nnoremap <silent> <Leader>4 :tabn  4<CR>
nnoremap <silent> <Leader>5 :tabn  5<CR>
nnoremap <silent> <Leader>6 :tabn  6<CR>
nnoremap <silent> <Leader>7 :tabn  7<CR>
nnoremap <silent> <Leader>8 :tabn  8<CR>
nnoremap <silent> <Leader>9 :tabn  9<CR>
nnoremap <silent> <Leader>0 :tabn 10<CR>
"}}}

" <Leader>t[1..0]: move current window to Tab [1..10] {{{
nnoremap <silent> <Leader>t1 :call MoveToTab( 1,0)<CR>
nnoremap <silent> <Leader>t2 :call MoveToTab( 2,0)<CR>
nnoremap <silent> <Leader>t3 :call MoveToTab( 3,0)<CR>
nnoremap <silent> <Leader>t4 :call MoveToTab( 4,0)<CR>
nnoremap <silent> <Leader>t5 :call MoveToTab( 5,0)<CR>
nnoremap <silent> <Leader>t6 :call MoveToTab( 6,0)<CR>
nnoremap <silent> <Leader>t7 :call MoveToTab( 7,0)<CR>
nnoremap <silent> <Leader>t8 :call MoveToTab( 8,0)<CR>
nnoremap <silent> <Leader>t9 :call MoveToTab( 9,0)<CR>
nnoremap <silent> <Leader>t0 :call MoveToTab(10,0)<CR>
"}}}

" <Leader>T[1..0]: copy current window to Tab [1..10] {{{
nnoremap <silent> <Leader>T1 :call MoveToTab( 1,1)<CR>
nnoremap <silent> <Leader>T2 :call MoveToTab( 2,1)<CR>
nnoremap <silent> <Leader>T3 :call MoveToTab( 3,1)<CR>
nnoremap <silent> <Leader>T4 :call MoveToTab( 4,1)<CR>
nnoremap <silent> <Leader>T5 :call MoveToTab( 5,1)<CR>
nnoremap <silent> <Leader>T6 :call MoveToTab( 6,1)<CR>
nnoremap <silent> <Leader>T7 :call MoveToTab( 7,1)<CR>
nnoremap <silent> <Leader>T8 :call MoveToTab( 8,1)<CR>
nnoremap <silent> <Leader>T9 :call MoveToTab( 9,1)<CR>
nnoremap <silent> <Leader>T0 :call MoveToTab(10,1)<CR>
"}}}

"}}}

"|    keyboard mappings, Window management                                  {{{
"|-----------------------------------------------------------------------------

" Alt+[sdf]: Window mode selection {{{
if g:MetaSendsEscape
  nnoremap <silent> <Esc>s :call SetTilingMode("S")<CR>
  nnoremap <silent> <Esc>d :call SetTilingMode("D")<CR>
  nnoremap <silent> <Esc>f :call SetTilingMode("F")<CR>
else
  nnoremap <silent>  <M-s> :call SetTilingMode("S")<CR>
  nnoremap <silent>  <M-d> :call SetTilingMode("D")<CR>
  nnoremap <silent>  <M-f> :call SetTilingMode("F")<CR>
endif
"}}}

" Alt+[hjkl]: select window {{{
if g:MetaSendsEscape
  nnoremap <silent> <Esc>h :call WindowCmd("h")<CR>
  nnoremap <silent> <Esc>j :call WindowCmd("j")<CR>
  nnoremap <silent> <Esc>k :call WindowCmd("k")<CR>
  nnoremap <silent> <Esc>l :call WindowCmd("l")<CR>
else
  nnoremap <silent>  <M-h> :call WindowCmd("h")<CR>
  nnoremap <silent>  <M-j> :call WindowCmd("j")<CR>
  nnoremap <silent>  <M-k> :call WindowCmd("k")<CR>
  nnoremap <silent>  <M-l> :call WindowCmd("l")<CR>
endif
"}}}

" Alt+[HJKL]: move current window {{{
if g:MetaSendsEscape
  nnoremap <silent>  <Esc>H :call WindowMove("h")<CR>
  nnoremap <silent>  <Esc>J :call WindowMove("j")<CR>
  nnoremap <silent>  <Esc>K :call WindowMove("k")<CR>
  nnoremap <silent>  <Esc>L :call WindowMove("l")<CR>
else
  nnoremap <silent> <S-M-h> :call WindowMove("h")<CR>
  nnoremap <silent> <S-M-j> :call WindowMove("j")<CR>
  nnoremap <silent> <S-M-k> :call WindowMove("k")<CR>
  nnoremap <silent> <S-M-l> :call WindowMove("l")<CR>
endif
"}}}

" Ctrl+Alt+[hjkl]: resize current window {{{
if g:MetaSendsEscape
  nnoremap <silent> <Esc><C-h> :call WindowResize("h")<CR>
  nnoremap <silent> <Esc><C-j> :call WindowResize("j")<CR>
  nnoremap <silent> <Esc><C-k> :call WindowResize("k")<CR>
  nnoremap <silent> <Esc><C-l> :call WindowResize("l")<CR>
else
  nnoremap <silent>    <C-M-h> :call WindowResize("h")<CR>
  nnoremap <silent>    <C-M-j> :call WindowResize("j")<CR>
  nnoremap <silent>    <C-M-k> :call WindowResize("k")<CR>
  nnoremap <silent>    <C-M-l> :call WindowResize("l")<CR>
endif
"}}}

"}}}

"|    Alt+[ocw]: create/collapse/close window                               {{{
"|-----------------------------------------------------------------------------

" Alt+[oO]: new horizontal/vertical window {{{
" Note: Alt+O is disabled because it messes the arrow key behavior on my box
if g:MetaSendsEscape
  nnoremap <silent>  <Esc>o :call WindowCreate("s")<CR>
  "nnoremap <silent>  <Esc>O :call WindowCreate("v")<CR>
else
  nnoremap <silent>   <M-o> :call WindowCreate("s")<CR>
  "nnoremap <silent> <S-M-o> :call WindowCreate("v")<CR>
endif
"}}}

" Alt+c: collapse current window {{{
if g:MetaSendsEscape
  nnoremap <silent> <Esc>c :call WindowCollapse()<CR>
else
  nnoremap <silent>  <M-c> :call WindowCollapse()<CR>
endif
"}}}

" Alt+w: close current window {{{
if g:MetaSendsEscape
  nnoremap <silent> <Esc>w :call WindowClose()<CR>
else
  nnoremap <silent>  <M-w> :call WindowClose()<CR>
endif
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
