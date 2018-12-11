suckless.vim
================================================================================

Tiling window management that sucks less - see <https://dwm.suckless.org/>. <br>
This plugin emulates [wmii†][1] / [dwm][2] / [i3][3] / [awesome][4] in Vim and Neovim.

  [1]: https://code.google.com/archive/p/wmii/
  [2]: https://dwm.suckless.org/
  [3]: https://i3wm.org/
  [4]: https://awesomewm.org/

Instructions
--------------------------------------------------------------------------------

For the window management, all shortcuts use the <kbd>Alt</kbd> (Meta) key by default:

          Alt+[sdf]  ⇒ tiling mode selection: [s]tacked, [d]ivided, [f]ullscreen
          Alt+[hjkl] ⇒ select adjacent window
    Shift+Alt+[hjkl] ⇒ move current window
     Ctrl+Alt+[hjkl] ⇒ resize current window
          Alt+o      ⇒ create new window
          Alt+c      ⇒ collapse window
          Alt+w      ⇒ close window

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

The default keyboard mappings for tab and window management can be customized through two global variables:

```vim
let g:suckless_map_windows = {
\           '<M-[sdf]>'  :   'SetTilingMode("[sdf]")'    ,
\           '<M-[hjkl]>' :    'SelectWindow("[hjkl]")'   ,
\           '<M-[HJKL]>' :      'MoveWindow("[hjkl]")'   ,
\         '<M-C-[hjkl]>' :    'ResizeWindow("[hjkl]")'   ,
\           '<M-[oO]>'   :    'CreateWindow("[sv]")'     ,
\           '<M-c>'      :  'CollapseWindow()'           ,
\           '<M-w>'      :     'CloseWindow()'           ,
\}
let g:suckless_map_tabs = {
\       '<M-[123456789]>':       'SelectTab([123456789])',
\  '<Leader>[123456789]' :       'SelectTab([123456789])',
\ '<Leader>t[123456789]' : 'MoveWindowToTab([123456789])',
\ '<Leader>T[123456789]' : 'CopyWindowToTab([123456789])',
\}
```

If you want to match [i3][3]’s mapping, I’d recommend [modifying your i3 configuration][5] to use `hjkl` in i3 — but you could also tweak your Vim mappings to match i3’s default mappings (which use `jkl;` instead of `hjkl`):

  [5]: https://github.com/fabi1cazenave/dotFiles/blob/master/config/i3/config

```vim
let g:suckless_map_windows = {
\           '<M-[sdf]>'  :   'SetTilingMode("[sdf]")'    ,
\           '<M-[jkl;]>' :    'SelectWindow("[hjkl]")'   ,
\           '<M-[JKL:]>' :      'MoveWindow("[hjkl]")'   ,
\         '<M-C-[jkl;]>' :    'ResizeWindow("[hjkl]")'   ,
\           '<M-[oO]>'   :    'CreateWindow("[sv]")'     ,
\           '<M-c>'      :  'CollapseWindow()'           ,
\           '<M-w>'      :     'CloseWindow()'           ,
\}
```

If  the <kbd>Alt</kbd> key is not a good option for you, you can do the following to use the `<Leader>` key instead:

```vim
let g:suckless_map_windows = {
\    '<Leader>[sdf]'     :   'SetTilingMode("[sdf]")'    ,
\    '<Leader>[hjkl]'    :    'SelectWindow("[hjkl]")'   ,
\    '<Leader>[HJKL]'    :      'MoveWindow("[hjkl]")'   ,
\ '<Leader><C-[hjkl]>'   :    'ResizeWindow("[hjkl]")'   ,
\    '<Leader>[oO]'      :    'CreateWindow("[sv]")'     ,
\    '<Leader>c'         :  'CollapseWindow()'           ,
\    '<Leader>w'         :     'CloseWindow()'           ,
\}
let g:suckless_map_tabs = {
\  '<Leader>[123456789]' :       'SelectTab([123456789])',
\ '<Leader>t[123456789]' : 'MoveWindowToTab([123456789])',
\ '<Leader>T[123456789]' : 'CopyWindowToTab([123456789])',
\}
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

