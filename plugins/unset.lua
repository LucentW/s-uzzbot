local function get_variables_hash(msg)
  if msg.to.type == 'chat' then
    return 'chat:'..msg.to.id..':variables'
  end
  if msg.to.type == 'channel' then
    return 'channel:'..msg.to.id..':variables'
  end
  if msg.to.type == 'user' then
    return 'user:'..msg.from.id..':variables'
  end
end

local function del_value(msg, name)
  if (not name) then
    return "Usage: !unset value_name"
  end
  
  local hash = get_variables_hash(msg)
  
  if hash and redis:hget(hash, name) then
    redis:hdel(hash, name)
    return "Deleted " ..name
  else
    return "There is no " .. name .. " variable set. Use \"!get\" to list variables"
  end
end

local function run(msg, matches)
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