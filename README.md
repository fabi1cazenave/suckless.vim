suckless.vim
================================================================================

Tiling window management that sucks less - see <http://wmii.suckless.org/>. <br>
This emulates wmii / i3 in Vim and Neovim as much as possible.


Instructions
--------------------------------------------------------------------------------

For the window management, all shortcuts use the <kbd>Alt</kbd> (Meta) key by default:

          Alt+[sdf]  ⇒ tiling mode selection: [s]tacked, [d]ivided, [f]ullscreen
          Alt+[hjkl] ⇒ select adjacent window
    Shift+Alt+[hjkl] ⇒ move current window
     Ctrl+Alt+[hjkl] ⇒ resize current window

               Alt+o ⇒ create new window
               Alt+c ⇒ collapse window
               Alt+w ⇒ close window

Vim tabs are used as “views”:

         Alt+[123456789] ⇒ select tab [1..9]
     <Leader>[123456789] ⇒ select tab [1..9]
    <Leader>t[123456789] ⇒ move current window to tab [1..9]
    <Leader>T[123456789] ⇒ copy current window to tab [1..9]


Meta/Alt caveats
--------------------------------------------------------------------------------

By default, this plugin relies on the <kbd>Alt</kbd> key. This works fine with Neovim but unfortunately, there are some caveats with Vim:

* either Vim modifies the 8th bit of the current character, i.e. <kbd>Alt</kbd><kbd>j</kbd> outputs an `ê` — that’s what gVim does;
* or an <kbd>Esc</kbd> is sent along with the key, i.e. <kbd>Alt</kbd><kbd>j</kbd> becomes <kbd>Esc</kbd><kbd>j</kbd> — that’s what happens with most terminal emulators.


*suckless.vim* should handle this properly, but in case your <kbd>Alt</kbd> shortcuts are not detected you can define the `g:MetaSendsEscape` variable explicitly:

```vim
let g:MetaSendsEscape = 0  " use this if Alt-j outputs an 'ê' on your terminal Vim
let g:MetaSendsEscape = 1  " use this if Alt shortcuts don't work on gVim / MacVim
```

On MacOSX, the <kbd>Alt</kbd> key might not be enabled in your terminal by default. On MacVim, you’ll have to set the ``macmeta`` pref to enable Option keys as "Meta" (MacVim ≥ 7.3 required); and if you want to keep *one* Option key, [this patch](https://gist.github.com/666875) can help.


Customization
--------------------------------------------------------------------------------

### Keyboard Mappings

The default keyboard mappings for tab and window management can be disabled by setting a variable. The following functions are exported and can be mapped as you wish:

```vim
let g:suckless_map_windows = 0 " disables the default mappings below:
"        Alt+[sdf]  ⇒  SetTilingMode("[sdf]")  # [s]tacked, [d]ivided, [f]ullscreen
"        Alt+[hjkl] ⇒   WindowSelect("[hjkl]")
"  Shift+Alt+[hjkl] ⇒     WindowMove("[hjkl]")
"   Ctrl+Alt+[hjkl] ⇒   WindowResize("[hjkl]")
"        Alt+[oO]   ⇒   WindowCreate("[sv]")   # horizontal [s]plit, [v]ertical split
"        Alt+c      ⇒ WindowCollapse()
"        Alt+w      ⇒    WindowClose()

let g:suckless_map_tabs = 0 " disables the default mappings below:
"        Alt+[123456789] ⇒ TabSelect(n)
"    <Leader>[123456789] ⇒ TabSelect(n)
"   <Leader>t[123456789] ⇒ MoveWindowToTab(n)
"   <Leader>T[123456789] ⇒ CopyWindowToTab(n)
```

You can use the plugin’s `nmap` and `tmap` functions to handle <kbd>Alt</kbd> shortcuts easily:

```vim
call suckless#nmap('<M-[hjkl]>' , ':call WindowSelect("[hjkl]")<CR>')
```

is equivalent to:

```vim
if g:MetaSendsEscape
  nmap <silent> <Esc>h :call WindowSelect("h")<CR>
  nmap <silent> <Esc>j :call WindowSelect("j")<CR>
  nmap <silent> <Esc>k :call WindowSelect("k")<CR>
  nmap <silent> <Esc>l :call WindowSelect("l")<CR>
else
  nmap <silent> <M-h>  :call WindowSelect("h")<CR>
  nmap <silent> <M-j>  :call WindowSelect("j")<CR>
  nmap <silent> <M-k>  :call WindowSelect("k")<CR>
  nmap <silent> <M-l>  :call WindowSelect("l")<CR>
endif
```

If  the <kbd>Alt</kbd> key is not a good option for you, you can do the following to use the `<Leader>` key instead:

```vim
let g:suckless_map_windows = 0
call suckless#nmap(    '<Leader>[sdf]'   , ':call   SetTilingMode("[sdf]")    <CR>')
call suckless#nmap(    '<Leader>[hjkl]'  , ':call    WindowSelect("[hjkl]")   <CR>')
call suckless#nmap(    '<Leader>[HJKL]'  , ':call      WindowMove("[hjkl]")   <CR>')
call suckless#nmap( '<Leader><C-[hjkl]>' , ':call    WindowResize("[hjkl]")   <CR>')
call suckless#nmap(    '<Leader>[oO]'    , ':call    WindowCreate("[sv]")     <CR>')
call suckless#nmap(    '<Leader>c'       , ':call  WindowCollapse()           <CR>')
call suckless#nmap(    '<Leader>w'       , ':call     WindowClose()           <CR>')

let g:suckless_map_tabs = 0
call suckless#nmap( '<Leader>[123456789]', ':call       TabSelect([123456789])<CR>')
call suckless#nmap('<Leader>t[123456789]', ':call MoveWindowToTab([123456789])<CR>')
call suckless#nmap('<Leader>T[123456789]', ':call CopyWindowToTab([123456789])<CR>')
```

### Tab Line & Label

To leave tabs unchanged (both in the terminal and in the GUI), use:

```vim
let g:suckless_tabline = 0
let g:suckless_guitablabel = 0
```

### Advanced Settings

The default settings below can be fine-tuned:

```vim
" window resizing
let g:suckless_min_width = 24      " minimum window width
let g:suckless_inc_width = 12      " width increment
let g:suckless_inc_height = 6      " height increment
" wrap-around modes for window selection
let g:suckless_wrap_around_jk = 1  " wrap in current column (wmii-like)
let g:suckless_wrap_around_hl = 1  " wrap in current tab    (wmii-like)
```


Feedback
--------------------------------------------------------------------------------

Bug reports, suggestions and pull requests are welcome.

