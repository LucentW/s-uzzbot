do

function run(msg, matches)
  return str2emoji(':information_source:')..' s-uzzbot/telegram-bot '.. VERSION .. [[ 
This software and its plugins are under the GNU GPL v2 license.]]
end

return {
  description = "Shows bot version", 
  usage = "!version: Shows bot version",
  patterns = {
    "^!version$",
  }, 
  run = run 
}

end
