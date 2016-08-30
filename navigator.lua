function os.capture(cmd, raw)
  local f = assert(io.popen(cmd, 'r'))
  local s = assert(f:read('*a'))
  f:close()
  return string.sub(s, 0, -2)
end

dir = nil
cursor = 0
path = nil
length=0
defaultpath = "/"
function handler()
  if not path then
    if mp.get_property('path') then
      path = string.sub(mp.get_property("path"), 1, string.len(mp.get_property("path"))-string.len(mp.get_property("filename")))
    else path = defaultpath end
    dir,length = scandirectory(path)
  end
  local output = path.."\n\n"
  local b = cursor - 5
  if b > 1 then output=output.."...\n" end
  if b<0 then b=0 end
  for a=b,b+10,1 do
    if a==length then break end
    if a == cursor then
      output = output.."> "..dir[a].." <\n"
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
  end
  handler()
end

function navup()
  if cursor~=0 then
    cursor = cursor-1
  end
  handler()
end

function childdir()
  local item = dir[cursor]
  if item then
    local isfolder = os.capture('if test -d '..string.gsub(path..item, "%s+", "\\ ")..'; then echo "true"; fi')
    if isfolder=="true" then
      changepath(path..dir[cursor].."/")
    else
      mp.commandv("loadfile", path..item, "replace")
    end
  end
end

function opendir()
  local item = dir[cursor]
  if item then
    mp.commandv("loadfile", path..item, "replace")
  end
end

function changepath(args)
  path = args
  dir,length = scandirectory(path)
  cursor=0
  handler()
end

function parentdir()
  local parent = os.capture('cd '..string.gsub(path, "%s+", "\\ ")..'; cd .. ; pwd').."/"
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
          directory[i] = dirx
          i=i+1
      end
  else
      print("error: could not scan for files")
  end
  return directory, i
end


mp.add_key_binding("CTRL+f", "scandirectory", handler)
mp.add_key_binding("CTRL+k", "navdown", navdown)
mp.add_key_binding("CTRL+i", "navup", navup)
mp.add_key_binding("CTRL+o", "opendir", opendir)
mp.add_key_binding("CTRL+l", "childdir", childdir)
mp.add_key_binding("CTRL+j", "parentdir", parentdir)
