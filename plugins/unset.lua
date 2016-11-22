local function get_variables_hash(msg)
  if msg.to.type == 'chat' then
    return 'chat:'..msg.to.id..':variables'
  end
  if msg.to.type == 'channel' then
    return 'channel:'..msg.from.id..':variables'
  end
  if msg.to.type == 'user' then
    return 'user:'..msg.from.id..':variables'
  end
end 

local function del_value(msg, name)
  if (not name) then
    return "Usage: !unset var_name value"
  end
  
  local hash = get_variables_hash(msg)
  
  if hash then
    redis:hdel(hash, name)
    return "Ho cancellato " ..name.. "."
  else
    return "Che cazzo mi stai facendo fare? non posso cancellare " ..name
  end
end

local function run(msg, matches)
  -- local name = string.sub(matches[1], 1, 50)
  local text = del_value(msg, matches[2])
  return text
end

return {
  description = "Plugin for deleting values. get.lua plugin is necessary to retrieve them.", 
  usage = "!unset [value_name]: deletes the data with the value_name name.",
  patterns = {
    "^(!unset) (.+)$"
  }, 
  run = run 
}