# Mpv Filenavigator  
File navigator for mpv media player. Should work on linux, macos and windows. Relies on default unix commands cd, pwd, sort, test and ls. Edit the settings variable in the lua file to change defaults and to add favorite paths.

#### Keybinds  
- __navigator (Alt+f)__ Activate script. When using dynamic keys this will need to be invoked to register keybindings.
- __navup navdown (up/down)__ cursor up/down
- __navback navforward (left, right)__ directory back/forward, incase of file append to playlist
- __navopen (Enter)__ open directory or file with mpv, same as `mpv /path/to/dir-or-file`, replaces playlist
- __navfavorites (f)__ cycle between favorite directories, edit settings to setup
- __navclose (ESC)__ Close navigator if it's open

On default dynamic keys are active which means that other binds than navigator(Alt+f) will only be active after activating the script with navigator keybind and until the osd timeouts. Dynamic keybindings will only override keys while they are active. Dynamic setting toggle can be changed in lua settings variable. The navigator start keybind can be changed in input.conf with `KEY script-binding navigator`. The dynamic keybinds should be set from the lua settings.

![alt text](https://giant.gfycat.com/DisfiguredBlindAmethystinepython.gif "Screenshot")

#### My other mpv scripts
- [collection of scripts](https://github.com/donmaiq/mpv-scripts)
