suckless
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
          Alt+[oO]   ⇒ create new window (horizontal/vertical split)
          Alt+w      ⇒ close window

Tabs are used as “views” and are controlled with the `<Leader>` key by default:

      <Leader>[123456789] ⇒ select tab [1..9]
     <Leader>t[123456789] ⇒ move current window to tab [1..9]
     <Leader>T[123456789] ⇒ copy current window to tab [1..9]


Keyboard Mappings
--------------------------------------------------------------------------------

The default keyboard mappings can be customized with a global variable:

```vim
let g:suckless_mappings = {
\        '<M-[sdf]>'      :   'SetTilingMode("[sdf]")'    ,
\        '<M-[hjkl]>'     :    'SelectWindow("[hjkl]")'   ,
\        '<M-[HJKL]>'     :      'MoveWindow("[hjkl]")'   ,
\      '<C-M-[hjkl]>'     :    'ResizeWindow("[hjkl]")'   ,
\        '<M-[oO]>'       :    'CreateWindow("[sv]")'     ,
\        '<M-w>'          :     'CloseWindow()'           ,
\   '<Leader>[123456789]' :       'SelectTab([123456789])',
\  '<Leader>t[123456789]' : 'MoveWindowToTab([123456789])',
\  '<Leader>T[123456789]' : 'CopyWindowToTab([123456789])',
\}
```

If you want to match [i3][3]’s mapping, I’d recommend [modifying your i3 configuration][5] to use `hjkl` in i3 — but you could also tweak your Vim mappings to match i3’s default mappings (which use `jkl;` instead of `hjkl`) and use <kbd>Alt</kbd> instead of `<Leader>` for tab-related commands:

  [5]: https://github.com/fabi1cazenave/dotFiles/blob/master/config/i3/config

```vim
let g:suckless_mappings = {
\        '<M-[sdf]>'      :   'SetTilingMode("[sdf]")'    ,
\        '<M-[jkl;]>'     :    'SelectWindow("[hjkl]")'   ,
\        '<M-[JKL:]>'     :      'MoveWindow("[hjkl]")'   ,
\      '<C-M-[jkl;]>'     :    'ResizeWindow("[hjkl]")'   ,
\        '<M-[oO]>'       :    'CreateWindow("[sv]")'     ,
\        '<M-w>'          :     'CloseWindow()'           ,
\        '<M-[123456789]>':       'SelectTab([123456789])',
\        '<M-[!@#$%^&*(]>': 'MoveWindowToTab([123456789])',
\      '<C-M-[123456789]>': 'CopyWindowToTab([123456789])',
\}
```

If  the <kbd>Alt</kbd> key is not a good option for you, you can do the following to use the `<Leader>` key instead:

```vim
let g:suckless_mappings = {
\   '<Leader>[sdf]'       :   'SetTilingMode("[sdf]")'    ,
\   '<Leader>[hjkl]'      :    'SelectWindow("[hjkl]")'   ,
\   '<Leader>[HJKL]'      :      'MoveWindow("[hjkl]")'   ,
\'<Leader><C-[hjkl]>'     :    'ResizeWindow("[hjkl]")'   ,
\   '<Leader>[oO]'        :    'CreateWindow("[sv]")'     ,
\   '<Leader>w'           :     'CloseWindow()'           ,
\   '<Leader>[123456789]' :       'SelectTab([123456789])',
\  '<Leader>t[123456789]' : 'MoveWindowToTab([123456789])',
\  '<Leader>T[123456789]' : 'CopyWindowToTab([123456789])',
\}
let mapleader = "\<Space>"  " best Leader key ever </my2¢>
```

Meta/Alt Caveats
--------------------------------------------------------------------------------

By default, this plugin relies on the <kbd>Alt</kbd> key. This works fine with Neovim but unfortunately, there are some caveats with Vim:

* either Vim modifies the 8th bit of the current character, i.e. <kbd>Alt</kbd><kbd>j</kbd> outputs an `ê` — that’s what gVim does;
* or an <kbd>Esc</kbd> is sent along with the key, i.e. <kbd>Alt</kbd><kbd>j</kbd> becomes <kbd>Esc</kbd><kbd>j</kbd> — that’s what happens with most terminal emulators.


*suckless* should handle this properly, but in case your <kbd>Alt</kbd> shortcuts are not detected you can define the `g:MetaSendsEscape` variable explicitly:

```vim
let g:MetaSendsEscape = 0  " use this if Alt-j outputs an 'ê' on your terminal Vim
let g:MetaSendsEscape = 1  " use this if Alt shortcuts don't work on gVim / MacVim
```

On MacOSX, the <kbd>Alt</kbd> key might not be enabled in your terminal by default. On MacVim, you’ll have to set the ``macmeta`` pref to enable Option keys as "Meta" (MacVim ≥ 7.3 required); and if you want to keep *one* Option key, [this patch](https://gist.github.com/666875) can help.

Settings
--------------------------------------------------------------------------------

### Terminal Windows

All <kbd>Alt</kbd>-* shortcuts can be used on terminal windows in insert mode if the following is set:

```vim
let g:suckless_tmap = 1
```

Requires Neovim or Vim 8 with `:terminal` support.

### New Splits

To be more consistent with most tiling window managers (wmii, i3, awesome…) these settings are recommended:

```vim
set splitbelow
set splitright
```

### Tab Line & Label

This plugin modifies the tab labels to show:

* the tab number between brackets, with a `*` sign if a buffer in this tab is modified;
* the current buffer name, with a trailing `+` sign if modified.

To leave tabs unchanged (in the terminal and in the GUI, respectively), use:

```vim
let g:suckless_tabline = 0
let g:suckless_guitablabel = 0
```

### Window Resizing

```vim
let g:suckless_min_width = 24      " minimum window width
let g:suckless_inc_width = 12      " width increment
let g:suckless_inc_height = 6      " height increment
```

### Wrap-Around Modes

```vim
let g:suckless_wrap_around_jk = 1  " wrap in current column (wmii-like)
let g:suckless_wrap_around_hl = 1  " wrap in current tab    (wmii-like)
```


Feedback
--------------------------------------------------------------------------------

Bug reports, suggestions and pull requests are welcome.

