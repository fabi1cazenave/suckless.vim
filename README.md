Tiling window management that sucks less - see <http://wmii.suckless.org/>.
This emulates wmii in Vim as much as possible. A dwm emulation might come next.


Instructions
--------------------------------------------------------------------------------

For the window management, all shortcuts use the <kbd>Alt</kbd> (Meta) key by default:

         Alt+[sdf]  ⇒ tiling mode selection: [s]tacked, [d]ivided, [f]ullscreen
         Alt+[hjkl] ⇒ select adjacent window
         Alt+[HJKL] ⇒ move current window
    Ctrl+Alt+[hjkl] ⇒ resize current window

              Alt+o ⇒ create new window
              Alt+c ⇒ collapse window
              Alt+w ⇒ close window

Vim tabs are used as “views”:

         Alt+[1234567890] ⇒ select tab [1..10]
     <Leader>[1234567890] ⇒ select tab [1..10]
    <Leader>t[1234567890] ⇒ move current window to tab [1..10]
    <Leader>T[1234567890] ⇒ copy current window to tab [1..10]


Install details
--------------------------------------------------------------------------------

Copy the script into your ``$HOME/.vim/plugin`` directory so that it will be sourced on startup.


Meta/Alt tricks
--------------------------------------------------------------------------------

This plugin relies quite heavily on the <kbd>Alt</kbd> key. Unfortunately,
defining <kbd>Alt</kbd> shortcuts in Vim can be tricky… Here’s a quick help if
your <kbd>Alt</kbd> shortcuts don’t work as expected.

On Windows and GNU/Linux the <kbd>Alt</kbd> key can either:
- modify the 8th bit of the current character, i.e. <kbd>Alt</kbd><kbd>j</kbd> outputs a `ê`
  — that’s what gVim does, and that’s xterm’s default behaviour;
- send an <kbd>Esc</kbd> along with the key, i.e. <kbd>Alt</kbd><kbd>j</kbd> outputs <kbd>Esc</kbd><kbd>j</kbd>
  — this is sometimes referred to as an “8-bit clean” behavior, and that’s the
  default behavior of all modern terminal emulators.

Suckless.vim assumes that the <kbd>Alt</kbd> key modifies the 8th bit in GUI mode
and sends sends escape in CLI mode, but you can override this setting by setting
the `g:MetaSendsEscape` variable accordingly.

On MacOSX, the <kbd>Alt</kbd> key might not be enabled in your terminal by
default. On MacVim, you’ll have to set the ``macmeta`` pref to enable Option
keys as "Meta" (MacVim ≥ 7.3 required); and if you want to keep *one* Option key,
[this patch](https://gist.github.com/666875) can help.

If you’re not pleased with <kbd>Alt-\*</kbd> shortcuts, you’ll have to define your own shortcuts directly in the ``suckless.vim`` file. :-/


Feedback
--------------------------------------------------------------------------------

Bug reports, suggestions and pull requests are welcome.

