-- WARNING!
-- This plugin is not tested nor used by the official instance.
-- Keep in mind that getting data from external HTTP APIs might slow down
-- the processing of the messages themselves and deadlock the entire bot.
--
-- You've been warned.

local API_KEY = 'FILL_WITH_YOUR_API_KEY'
local TTL_CACHE = 21600 -- 6 hours

-- API_EP
local API_EP = 'https://api.iata.ovh/getUserInfo/?api='..API_KEY..'&user_id='

local function kick_user(user_id, chat_id, receiver)
  local chat = 'chat#id'..chat_id
  local user = 'user#id'..user_id
  if not is_mod(user_id, chat_id) then
    chat_del_user(chat, user, ok_cb, true)
    return true
  else
    send_large_msg(receiver, str2emoji(":no_entry_sign:").." I won't kick myself, admins or mods.")
    return false
  end
end

local function kick_chan_user(user_id, chat_id, receiver)
  local chat = 'channel#id'..chat_id
  local user = 'user#id'..user_id
  if not is_mod(user_id, chat_id) then
    channel_kick(chat, user, ok_cb, true)
    return true
  else
    send_large_msg(receiver, str2emoji(":no_entry_sign:").." I won't kick myself, admins or mods.")
    return false
  end
end

local function is_bl(user_id, defcon)
  local hash = 'iata:'..user_id

  local cachedStatus = redis:get(hash)
  local cachedDefcon
  if cachedStatus ~= nil then
    if cachedStatus == true then
      cachedDefcon = redis:get(hash..':defcon')
      if cachedDefcon >= defcon then
        return cachedDefcon..' - '..redis:get(hash..':reason')
      else
        return false
      end
    else
      return false
    end
  end

  local data = http.request(API_EP..user_id)
  local jsonBody = json:decode(data)

  if jsonBody["result"]["status"] == true then
    redis:setex(hash, TTL_CACHE, true)
    redis:setex(hash..':defcon', TTL_CACHE, jsonBody["result"]["info"]["codice"])
    redis:setex(hash..':reason', TTL_CACHE, jsonBody["result"]["info"]["motivazione"])
    if jsonBody["result"]["info"]["codice"] >= defcon then
      return jsonBody["result"]["info"]["codice"]..' - '..jsonBody["result"]["info"]["motivazione"]
    else
      return false
    end
  else
    redis:setex(hash, TTL_CACHE, false)
    return false
  end
end

local function pre_process(msg)

  local hash = 'iata:defcon:'..msg.to.id
  local defcon = redis:get(hash)
  if defcon > 0 then
    -- SERVICE MESSAGE
    if msg.action and msg.action.type then
      local action = msg.action.type
      -- Check if banned user joins chat
      if action == 'chat_add_user' or action == 'chat_add_user_link' then
        local user_id
        if msg.action.link_issuer then
          user_id = msg.from.id
        else
          user_id = msg.action.user.id
        end
        print('IATA blacklist check: '..user_id)
        local bl_stat = is_bl(user_id, defcon)
        if bl_stat then
          print('User is blacklisted!')
          if not is_chan_msg(msg) then
            kick_user(user_id, msg.to.id, get_receiver(msg))
          else
            kick_chan_user(user_id, msg.to.id, get_receiver(msg))
          end
        end
      end
      -- No further checks
      return msg
    end

    -- BANNED USER TALKING
    if is_chat_msg(msg) then
      local user_id = msg.from.id
      local chat_id = msg.to.id
      local bl_stat = is_bl(user_id, defcon)
      if bl_stat then
        print('User is blacklisted!')
        if not is_chan_msg(msg) then
          kick_user(user_id, msg.to.id, get_receiver(msg))
        else
          kick_chan_user(user_id, msg.to.id, get_receiver(msg))
        end
        if not is_mod(user_id, chat_id) then
          msg.text = ''
        end
      end
    end
  end
end

local function run(msg, matches)
  if matches[0] == "whyiata" then
    local text
    local bld = is_bl(msg.from.id, 0)
    if bld then
      text = str2emoji(':exclamation:')..' ID '..msg.from.id..' is blacklisted.\n'
      text = text..'Defcon + reason: '..bld
    else
      text = str2emoji(':information_source:')..' ID '..msg.from.id..' is not blacklisted.'
    end
    return text
  end
  if is_momod(msg) then
    if matches[0] == "enable" then
      redis:set('iata:defcon:'..msg.to.id, 3)
      return str2emoji(':information_source:')..' IATA blacklist enabled on group '..gsub(msg.to.print_name, '_', ' ')..' ['..msg.to.id..'].'
    end
    if matches[0] == "disable" then
      redis:del('iata:defcon:'..msg.to.id)
      return str2emoji(':information_source:')..' IATA blacklist disabled on group '..gsub(msg.to.print_name, '_', ' ')..' ['..msg.to.id..'].'
    end
    if matches[0] == "min" then
      if matches[1] > 0 and matches[1] < 6 then
        redis:set('iata:defcon:'..msg.to.id, matches[1])
        return str2emoji(':information_source:')..' IATA blacklist defcon set at '..matches[1]..' on group '..gsub(msg.to.print_name, '_', ' ')..' ['..msg.to.id..'].'
      end
      return str2emoji(':information_source:')..' Defcon value should be from 1 to 5.'
    end
  else
    return str2emoji(':exclamation:')..' You are not a moderator.'
  end
end

return {
  description = "Plugin to implement IATA blacklist APIs.",
  usage = {
    user = {
      "!whyiata : Get your own status on the IATA BL",
    },
    moderator = {
      "!iata <enable>/<disable> : Enable or disable IATA blacklist on the group",
      "!iata min <value> : Autoban IDs with defcon >= value (default 3)",
      -- "!iata <addwhite>/<delwhite> <user_id> : Allow user to avoid being autobanned",
    },
  },
  patterns = {
    "^!(whyiata)$",
    "^!iata (enable)$",
    "^!iata (disable)$",
    "^!iata (min) (%d+)$",
    -- "^!iata (addwhite) (%d+)$",
    -- "^!iata (delwhite) (%d+)$"
  },
  run = run,
  pre_process = pre_process,
}
