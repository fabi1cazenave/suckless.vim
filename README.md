Tiling window management that sucks less - see <http://wmii.suckless.org/>.
This emulates wmii in Vim as much as possible. A dwm emulation might come next.


Instructions
--------------------------------------------------------------------------------

For the window management, all shortcuts use the <kbd>Alt</kbd> (Meta) key by default:

         Alt+[sdf]  => tiling mode selection: [s]tacked, [d]ivided, [f]ullscreen
         Alt+[hjkl] => select adjacent window
         Alt+[HJKL] => move current window
    Ctrl+Alt+[hjkl] => resize current window

Vim tabs are used as “views”:

         Alt+[1234567890] => select tab [1..10]
     <Leader>[1234567890] => select tab [1..10]
    <Leader>t[1234567890] => move current window to tab [1..10]
    <Leader>T[1234567890] => copy current window to tab [1..10]


Install details
--------------------------------------------------------------------------------

Copy the script into your ``$HOME/.vim/plugin`` directory so that it will be sourced on startup.


Meta/Alt tricks
--------------------------------------------------------------------------------

Warning, using the <kbd>Alt</kbd> key in these shortcuts implies that:

1. you’re not using <kbd>Alt</kbd> as main modifier in your tiling window manager  
   — in which case, I’d suggest to use the <kbd>Super</kbd> (win) key for your WM instead;
2. the <kbd>Alt</kbd> key is enabled in your Vim session:
    - if your <kbd>Alt</kbd> key sends <kbd>Esc</kbd> instead of setting the 8th bit,
      please uncomment the related shortcuts in the ``suckless.vim`` script;
    - if you’re running gVim, a quick and dirty way to free <kbd>Alt-\*</kbd>
      shortcuts is to disable all menus:  ``set guioptions-=m``;
    - if you’re runing MacVim, you’ll have to set the ``macmeta`` pref to enable
      Option keys as "Meta" (MacVim ≥ 7.3 required); and if you want to keep
      *one* Option key, [this patch](https://gist.github.com/666875) will help.

If you’re not pleased with <kbd>Alt-\*</kbd> shortcuts, you’ll have to define your own shortcuts directly in the ``suckless.vim`` file. :-/


Feedback
--------------------------------------------------------------------------------

This is my very first Vim plugin, so there should be a bunch of mistakes… feel free to submit corrections, enhancements and suggestions.

