# Mpv Filenavigator  
File navigator for mpv media player. Currently only works on linux, relies on standard output of test and pwd. Edit the settings variable in the lua file to change defaults and to add favorite paths.

#### Keybinds  
- __navigator (f)__ show directory. ctrl+i/j/k/l call the same function so this is not very nececcary to use/remember
- __nav-up nav-down (up/down)__ cursor up/down
- __nav-back nav-forward (left, right)__ directory back/forward, incase of file append to playlist
- __nav-undo (Backspace)__ undo last playlist append(just removes last entry in playlist)
- __nav-open (Enter)__ open directory or file with mpv, same as `mpv /path/to/dir-or-file`, replaces playlist
- __nav-favorites (g)__ cycle between favorite directories, edit settings to setup

On default dynamic keys are active which means that other binds than navigator(f) will only be active after activating the script with navigator keybind. Can be changed in lua settings variable. Keybinds can be changed in input.conf with `KEY script-binding keybind-name` ex. `K scipt-binding nav-favorites`.
  
![alt text](https://giant.gfycat.com/DisfiguredBlindAmethystinepython.gif "Screenshot")

####My other scripts
- [unseen-playlistmaker](https://github.com/donmaiq/unseen-playlistmaker)
- [playlistmanager](https://github.com/donmaiq/Mpv-Playlistmanager)
- [nextfile](https://github.com/donmaiq/mpv-nextfile)
