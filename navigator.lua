local settings = {
    defaultpath = "/", --fallback if no file is open
    forcedefault = false, --force navigation to start from defaultpath instead of currently playing file
    --favorites in format { [index, starting from 1], 'Path to directory, notice trailing /' }
    favorites =  {
        [1] = '/media/HDD2/music/music/',
        [2] = '/media/HDD/users/anon/Downloads/',
        [3] = '/home/anon/',
    },
    --ignore paths, value anything that returns true for if statement
    ignorePath = {
      ['/bin']='1',['/boot']='1',['/cdrom']='1',['/dev']='1',['/etc']='1',['/lib']='1',['/lib32']='1',['/lib64']='1',
      ['/srv']='1',['/sys']='1',['/snap']='1',['/root']='1',['/sbin']='1',['/proc']='1',['/opt']='1',['/usr']='1',['/run']='1',
    },
    --ignore folders and files that match patterns, make sure you use ^and$ to catch the whole str, value '' specifically
    --read about patterns at https://www.lua.org/pil/20.2.html or http://lua-users.org/wiki/PatternsTutorial
    ignorePat = {
      ['^initrd%..*$']='',  --hide folders starting with initrd.
      ['^vmlinuz.*$']='',
      ['^lost%+found$']='',
      ['^.*%.log$']='', --ignore extension .log
    },
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
  if not path then
    if mp.get_property('path') and not settings.forcedefault then
      path = string.sub(mp.get_property("path"), 1, string.len(mp.get_property("path"))-string.len(mp.get_property("filename")))
    else path = settings.defaultpath end
    dir,length = scandirectory(path)
  end
  local output = path.."\n\n"
  local b = cursor - 5
  if b > 0 then output=output.."...\n" end
  if b<0 then b=0 end
  for a=b,b+10,1 do
    if a==length then break end
    if a == cursor then
      output = output.."> "..dir[a].." <"
      if arg then output = output.." + added to playlist\n" else output=output.."\n" end
    else
      output = output..dir[a].."\n"
    end
    if a == b+10 then
      output=output.."..."
    end
  end
  mp.osd_message(output, 5)
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
    local isfolder = os.capture('if test -d '..string.gsub(path..item, "%s+", "\\ ")..'; then echo "true"; fi')
    if isfolder=="true" then
      changepath(path..dir[cursor].."/")
    else
      mp.commandv("loadfile", path..item, "append-play")
      handler(true)
    end
  end
end

--replace current playlist with directory or file
function opendir()
  local item = dir[cursor]
  if item then
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
  local parent = os.capture('cd '..string.gsub(path, "%s+", "\\ ")..'; cd .. ; pwd').."/"
  if parent == "//" then parent = "/" end
  changepath(parent)
end

function scandirectory(arg)
  local directory = {}
  local search = string.gsub(arg, "%s+", "\\ ")..'*'
  
  local popen=nil
  local i = 0
  popen = io.popen('find '..search..' -maxdepth 0 -printf "%f\\n" 2>/dev/null')
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


mp.add_key_binding("CTRL+f", "scandirectory", handler)
mp.add_key_binding("CTRL+u", "favorites", cyclefavorite)
mp.add_key_binding("CTRL+k", "navdown", navdown)
mp.add_key_binding("CTRL+i", "navup", navup)
mp.add_key_binding("CTRL+o", "opendir", opendir)
mp.add_key_binding("CTRL+l", "childdir", childdir)
mp.add_key_binding("CTRL+j", "parentdir", parentdir)
