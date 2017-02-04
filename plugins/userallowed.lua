local function run(msg, matches)
  
end
local function pre_process(msg)

end
return{
  run = run,
  pre_process = pre_process,
  patterns = {
    "^!(allow) (.*)$",
    "^!(disallow) (.*)$",
    "^#(allow)$",
    "^#(disallow)$",
  },
  usage = {
    admin = {
      "!allow <username/id> : Allow user to use the bot",
      "!disallow <username/id> : Disllow user to use the bot",
      "#allow <by reply> : Allow replyed user to use the bot",
      "#disallow <by reply> : Disallow replyed user to use the bot",
      }
  }