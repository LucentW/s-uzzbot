function print(...) --just to put a \n at the end :D
  local ar = {...}
  for _, v in ipairs(ar) do
    if (type(v) == "string") then
      io.write(v)
      io.write(" ")
    elseif (type(v) == "number" or type(v) == "boolean") then
      io.write(tostring(v))
      io.write(" ")
    else
      io.write(type(v))
      io.write(" ")
    end
  end
  io.write("\n")
end

methodsPath = "Madeline_lua_shim/methods.lua"

function loadBot()
  started = false
  crons = {}
  lastCron = os.time()
  print("Loading the bot...")
  loadfile("Madeline_lua_shim/shim.lua")()
  if not  io.open("bot/bot.lua") then
    loadfile("bot/_bot.lua")()
  else
    loadfile("bot/bot.lua")()
  end
  print("Bot loaded!")
end

--Loading initial values
started = false
crons = {}
lastCron = os.time()
if os.execute("mediainfo -h") then
  useMediaInfo = true
  mediainfo = loadfile("Madeline_lua_shim/mediainfo.lua")()
end
if not started then
  print("Starting...")
  loadBot()
end
