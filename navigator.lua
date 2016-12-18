--
-- Mpv Filenavigator
-- Author: donmaiq
-- Contributors: SteveJobzniak
-- URL: https://github.com/donmaiq/mpv-filenavigator
--
local settings = {
  defaultpath = "/", --fallback if no file is open
  forcedefault = false, --force navigation to start from defaultpath instead of currently playing file
  --favorites in format { 'Path to directory, notice trailing /' }
  favorites =  {
    '/media/HDD2/music/music/',
    '/media/HDD/users/anon/Downloads/',
    '/home/anon/',
  },
  --ignore paths, value anything that returns true for if statement
  --you can ignore children without ignoring the parent
  ignorePath = {
    --general linux system paths (some are used by macOS too):
    ['/bin']='1',['/boot']='1',['/cdrom']='1',['/dev']='1',['/etc']='1',['/lib']='1',['/lib32']='1',['/lib64']='1',
    ['/srv']='1',['/sys']='1',['/snap']='1',['/root']='1',['/sbin']='1',['/proc']='1',['/opt']='1',['/usr']='1',['/run']='1',
    --useless macOS system paths:
    ['/cores']='1',['/installer.failurerequests']='1',['/net']='1',['/private']='1',['/tmp']='1',['/var']='1'
  },
  --ignore folders and files that match patterns, make sure you use ^and$ to catch the whole str, value '' specifically
  --read about patterns at https://www.lua.org/pil/20.2.html or http://lua-users.org/wiki/PatternsTutorial
  ignorePat = {
    ['^initrd%..*$']='',  --hide folders starting with initrd.
    ['^vmlinuz.*$']='',
    ['^lost%+found$']='',
    ['^.*%.log$']='', --ignore extension .log
  },

  navigator_mainkey = "f",     --the key to bring up navigator's menu (will be auto-bound by the script, but you can set this to nil here to use input.conf instead!)
  navigator_menu_favkey = "g", --cannot be nil; this key will always be bound when the menu is open, and is the key you use to cycle your favorites list!
  dynamic_binds = true,        --navigation keybinds override arrowkeys and enter when activating navigation menu, false means keys are always actíve
  menu_timeout = true,         --menu timeouts and closes itself after osd_dur seconds, else will be toggled by keybind
  osd_dur = 5,                 --osd duration before the navigator closes, if timeout is set to true
  osd_items_per_screen = 10,   --how many menu items to show per screen
  navigator_font_size = 40,    --the font size to use for the OSD while the navigator is open
  normal_font_size = mp.get_property("osd-font-size") --the OSD font size to return to when the navigator closes (get the osd-font-size property for default)
}

function os.capture(cmd, raw)
  local f = assert(io.popen(cmd, 'r'))
  local s = assert(f:read('*a'))
  f:close()
  return string.sub(s, 0, -2)
end

dir = nil
path = nil
cursor = 0
length = 0
--osd handler that displays your navigation and information
function handler(arg)
  add_keybinds()
  timer:kill()
  if not path then
    if mp.get_property('path') and not settings.forcedefault then
      --determine path from currently playing file...
      local workingdir = mp.get_property("working-directory")
      local playfilename = mp.get_property("filename") --just the filename, without path
      local playpath = mp.get_property("path") --can be relative or absolute depending on what args mpv was given
      local firstchar = string.sub(playpath, 1, 1)
      --first we need to remove the filename (may give us empty path if mpv was started in same dir as file)
      path = string.sub(playpath, 1, string.len(playpath)-string.len(playfilename))
      if (firstchar ~= "/") then --the path of the playing file wasn't absolute, so we need to add mpv's working dir to it
        path = workingdir.."/"..path
      end
      --now resolve that path (to resolve things like "/home/anon/Movies/../Movies/foo.mkv")
      path = resolvedir(path)
      --lastly, check if the folder exists, and if not then fall back to the current mpv working dir
      if (not isfolder(path)) then
        path = workingdir
      end
    else path = settings.defaultpath end
    dir,length = scandirectory(path)
  end
  local output = path.."\n\n"
  local b = cursor - math.floor(settings.osd_items_per_screen / 2)
  if b > 0 then output=output.."...\n" end
  if b<0 then b=0 end
  for a=b,(b+settings.osd_items_per_screen),1 do
    if a==length then break end
    if a == cursor then
      output = output.."> "..dir[a].." <"
      if arg == "added" then output = output.." + added to playlist\n"
      elseif arg == "removed" then output = output.." - removed previous addition\n" else output=output.."\n" end
    else
      output = output..dir[a].."\n"
    end
    if a == (b+settings.osd_items_per_screen) then
      output=output.."..."
    end
  end
  mp.set_property("osd-font-size", settings.navigator_font_size)
  if not settings.menu_timeout then
    mp.osd_message(output, 100000)
  else
    mp.osd_message(output, settings.osd_dur)
    timer:resume()
  end
end

function navdown()
  if cursor~=length-1 then
    cursor = cursor+1
  else
    cursor = 0
  end
  handler()
end

function navup()
  if cursor~=0 then
    cursor = cursor-1
  else
    cursor = length-1
  end
  handler()
end

--moves into selected directory, or appends to playlist incase of file
function childdir()
  local item = dir[cursor]
  if item then
    if isfolder(path..item) then
      changepath(path..dir[cursor].."/")
    else
      mp.commandv("loadfile", path..item, "append-play")
      handler("added")
    end
  end
end

--undo playlist file append
function undo()
  mp.commandv("playlist-remove", tonumber(mp.get_property('playlist-count'))-1)
  handler("removed")
end

--close OSD and restore regular font size, and remove bindings
function clearosd()
  mp.osd_message("", 0.2)
  mp.set_property("osd-font-size", settings.normal_font_size)
  remove_keybinds()
end

--replace current playlist with directory or file
--if directory, mpv will recursively queue all items found in the directory and its subfolders
function opendir()
  local item = dir[cursor]
  if item then
    clearosd()
    mp.commandv("loadfile", path..item, "replace")
  end
end

--changes the directory to the path in argument
function changepath(args)
  path = args
  dir,length = scandirectory(path)
  cursor=0
  handler()
end

--move up to the parent directory
function parentdir()
  local parent = os.capture('cd '..string.gsub(path, "(%s)", "\\%1")..'; cd .. ; pwd').."/"
  if (string.sub(parent, -2) == "//") then
    parent = string.sub(parent, 1, -2) --negative 2 removes the last character
  end
  changepath(parent)
end

--resolves relative paths such as "/home/foo/../foo/Music" (to "/home/foo/Music") if the folder exists!
function resolvedir(dir)
  safedir = string.gsub(dir, "(%s)", "\\%1")
  local resolved = os.capture('test -d '..safedir..' && cd '..safedir..' && pwd').."/"
  if (string.sub(resolved, -2) == "//") then
    resolved = string.sub(resolved, 1, -2) --negative 2 removes the last character
  end
  return resolved
end

--true if path exists and is a folder, otherwise false
function isfolder(dir)
  return os.execute('test -d '..string.gsub(dir, "(%s)", "\\%1"))
end

function scandirectory(arg)
  local directory = {}
  local search = string.gsub(arg, "(%s)", "\\%1")

  local popen=nil
  local i = 0
  --get basenames by globbing all files, but avoid glob asterisk if dir was empty
  popen = io.popen('basename '..search..'/* | sed "s/^\\*$//"')
  if popen then
    for dirx in popen:lines() do
      local matched = false
      for match, replace in pairs(settings.ignorePat) do
        if dirx:gsub(match, replace) == '' then matched = true end
      end
      if not settings.ignorePath[path..dirx] and not matched then
        directory[i] = dirx
        i=i+1
      end
    end
  else
    print("error: could not scan for files")
  end
  return directory, i
end

favcursor = 1
function cyclefavorite()
  local firstpath = settings.favorites[1]
  if not firstpath then return end
  local favpath = nil
  local favlen = 0
  for key, fav in pairs(settings.favorites) do
    favlen = favlen + 1
    if key == favcursor then favpath = fav end
  end
  if favpath then
    changepath(favpath)
    favcursor = favcursor + 1
  else
    changepath(firstpath)
    favcursor = 2
  end
end

function add_keybinds()
  mp.add_forced_key_binding("DOWN", "nav-down", navdown, "repeatable")
  mp.add_forced_key_binding("UP", "nav-up", navup, "repeatable")
  mp.add_forced_key_binding("ENTER", "nav-open", opendir)
  mp.add_forced_key_binding("BS", "nav-undo", undo)
  mp.add_forced_key_binding("RIGHT", "nav-forward", childdir)
  mp.add_forced_key_binding("LEFT", "nav-back", parentdir)
  mp.add_forced_key_binding(settings.navigator_menu_favkey, "nav-favorites", cyclefavorite)
end

function remove_keybinds()
  if settings.dynamic_binds then
    mp.remove_key_binding('nav-down')
    mp.remove_key_binding('nav-up')
    mp.remove_key_binding('nav-open')
    mp.remove_key_binding('nav-undo')
    mp.remove_key_binding('nav-forward')
    mp.remove_key_binding('nav-back')
    mp.remove_key_binding("nav-favorites")
  end
end
timer = mp.add_periodic_timer(settings.osd_dur, clearosd)
timer:kill()
if not settings.dynamic_binds then
  add_keybinds()
end

active=false
function activate()
  if settings.menu_timeout then
    handler()
  else
    if active then
      clearosd()
      active=false
    else
      handler()
      active=true
    end
  end
end

if (settings.navigator_mainkey ~= nil) then
  --override defaults and input.conf
  mp.add_forced_key_binding(settings.navigator_mainkey, "navigator", activate)
else
  --just register the binding but no key, so that the user can bind it themselves
  --via input.conf, as follows: Alt+x script-binding navigator
  mp.add_key_binding(nil, "navigator", activate)
end
