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

local function get_value(msg, var_name)
  local hash = get_variables_hash(msg)
  if hash then
    local value = redis:hget(hash, var_name)
    if not value then
      return
    else
      return value
    end
  end
end

local function run(msg, matches)
  if matches[1] then
    return get_value(msg, matches[1])
  end
end

return {
  description = "Retrieves variables saved with !set",
  usage = "If the first word in the message is a valid variable added with !set, retrieve and return it.",
  patterns = {
    "[^ ]+"
  },
  run = run
}
