local function kick_user(user_id, chat_id)
  local chat = 'chat#id'..chat_id
  local user = 'user#id'..user_id
  chat_del_user(chat, user, function (data, success, result)
      if not success then
        local text = str2emoji(":exclamation:")..' I can\'t kick '..data.user..' but should be kicked'
        snoop_msg('I am unable to kick user '..user_id..' from group '..chat_id..'.')
        send_msg(data.chat, text, ok_cb, nil)
      end
      end, {chat=chat, user=user})
  end

  local function kick_chan_user(user_id, chat_id)
    local chat = 'channel#id'..chat_id
    local user = 'user#id'..user_id
    channel_kick(chat, user, function (data, success, result)
        if not success then
          local text = str2emoji(":exclamation:")..' I can\'t kick '..data.user..' but should be kicked'
          snoop_msg('I am unable to kick user '..user_id..' from group '..chat_id..'.')
          send_msg(data.chat, text, ok_cb, nil)
        end
        end, {chat=chat, user=user})
    end
  end
  if matches[1] == 'delexcept' then
    if msg.reply_id then
      get_message(msg.reply_id, delexcept_reply, get_receiver(msg))
      return nil
    end
  end
  if matches[1] == 'enable' then
    redis:set(hash, 1)
    return str2emoji(':information_source:')..' Anti-flood enabled on chat'
  end
  if matches[1] == 'disable' then
    redis:del(hash)
    return str2emoji(':information_source:')..' Anti-flood disabled on chat'
  end
  if matches[1] == 'status' then
    local hash_enable = 'anti-flood:enabled:'..msg.to.id
    local enabled = redis:get(hash_enable)

    if enabled then
      local hash_maxmsg = 'anti-flood:maxmsg:'..msg.to.id
      local hash_timeframe = 'anti-flood:timeframe:'..msg.to.id

      -- Max number of messages per TIME_CHECK seconds
      local NUM_MSG_MAX = tonumber(redis:get(hash_maxmsg) or 5)
      local TIME_CHECK = tonumber(redis:get(hash_timeframe) or 5)

      return str2emoji(':information_source:')..' Anti-flood current parameters:\n'..str2emoji(":no_entry_sign:")..' Kick set at '..NUM_MSG_MAX..' messages over '..TIME_CHECK..' seconds.'
    else
      return str2emoji(':information_source:')..' Anti-flood is disabled on this chat.\n'..str2emoji(":point_right:")..' Enable it with !antiflood enable.'
    end
  end
  if matches[2] then
    local hash_maxmsg = 'anti-flood:maxmsg:'..msg.to.id
    local hash_timeframe = 'anti-flood:timeframe:'..msg.to.id

    local parameter_mt = tonumber(matches[2])
    if matches[1] == 'maxmsg' then
      if parameter_mt > 4 then
        redis:set(hash_maxmsg, parameter_mt)
        return str2emoji(':information_source:')..' Now the number of messages needed to trip the antiflood is '..matches[2]..'.'
      end
      return str2emoji(":exclamation:")..' The limit should be higher than 4.'
    end
    if matches[1] == 'timeframe' then
      if parameter_mt > 4 then
        redis:set(hash_timeframe, parameter_mt)
        return 'Now the timeframe in which the antiflood will take its samples is '..matches[2].. ' seconds.'
      end
      return str2emoji(":exclamation:")..' The time frame should be higher than 4.'
    end

    hash = 'anti-flood:exception:'..chat..':'..matches[2]
    if matches[1] == 'addexcept' then
      redis:set(hash, 1)
      return str2emoji(':information_source:')..' User ID '..matches[2]..' is now exempt from antiflood checks.'
    end
    if matches[1] == 'delexcept' then
      if redis:get(hash) then
        redis:del(hash)
        return str2emoji(':information_source:')..' User ID '..matches[2]..' is now subject to antiflood checks.'
      else
        return str2emoji(':information_source:')..' User ID '..matches[2]..' is not exempt from antiflood checks.'
      end
    end
  end
end

local function pre_process (msg)
  -- Ignore service msg
  if msg.service then
    log(LOGLEVEL_INFO, 'Service message')
    return msg
  end

  local hash_enable = 'anti-flood:enabled:'..msg.to.id
  local enabled = redis:get(hash_enable)

  if not enabled then return msg end
  log(LOGLEVEL_INFO, 'anti-flood enabled')

  -- Check flood
  if msg.from.type ~= 'user' then return msg end
  local hash_maxmsg = 'anti-flood:maxmsg:'..msg.to.id
  local hash_timeframe = 'anti-flood:timeframe:'..msg.to.id

  -- Max number of messages per TIME_CHECK seconds
  local NUM_MSG_MAX = tonumber(redis:get(hash_maxmsg) or 5)
  local TIME_CHECK = tonumber(redis:get(hash_timeframe) or 5)

  -- Increase the number of messages from the user on the chat
  local hash = 'anti-flood:'..msg.from.id..':'..msg.to.id..':msg-num'
  local hash_warned = 'anti-flood:'..msg.from.id..':'..msg.to.id..':msg-num'
  local msgs = tonumber(redis:get(hash) or 0)
  local warned = redis:get(hash_warned) or false

  msgs = msgs + 1
  redis:setex(hash, TIME_CHECK, msgs)
  if msgs <= NUM_MSG_MAX then return msg end

  local receiver = get_receiver(msg)
  local user = msg.from.id
  local text = str2emoji(":exclamation:")..' User '
  if msg.from.username ~= nil then
    text = text..' @'..msg.from.username..' ['..user..'] is flooding'
  else
    text = text..string.gsub(msg.from.print_name, '_', ' ')..' ['..user..'] is flooding'
  end
  local chat = msg.to.id
  local hash_exception = 'anti-flood:exception:'..msg.to.id..':'..msg.from.id

  if not is_chat_msg(msg) then
    log(LOGLEVEL_INFO, "Flood in not a chat group!")
    return msg
  elseif user == tostring(our_id) then
    log(LOGLEVEL_INFO, 'I won\'t kick myself')
    return msg
  elseif is_momod(msg) then
    log(LOGLEVEL_INFO, 'I won\'t kick a mod/admin/sudo!')
    return msg
  elseif redis:get(hash_exception) then
    log(LOGLEVEL_INFO, 'User is exempt from antiflood checks!')
    return msg
  end

  local real_text
  if msg.media ~= nil then
    if msg.media.caption ~= nil then
      real_text = msg.media.caption
    else
      real_text = "[media with no caption]"
    end
  else
    if msg.text ~= nil then
      real_text = msg.text
    end
  end

  -- Cooldown: avoid sending more than one message in TIME_CHECK seconds
  if not warned then
    if msg.from.username ~= nil then
      snoop_msg('User @'..msg.from.username..' ['..msg.from.id..'] has been found flooding.\nGroup: '..msg.to.print_name..' ['..msg.to.id..']\nText: '..real_text)
    else
      snoop_msg('User '..string.gsub(msg.from.print_name, '_', ' ')..' ['..msg.from.id..'] has been found flooding.\nGroup: '..msg.to.print_name..' ['..msg.to.id..']\nText: '..real_text)
    end
    send_msg(receiver, text, ok_cb, nil)
  end
  redis:setex(hash_warned, TIME_CHECK, 1)

  if not is_chan_msg(msg) then
    kick_user(user, chat)
  else
    kick_chan_user(user, chat)
  end
  return nil
end

-- Public function, used in test suite
function is_antiflood_enabled(msg)
  -- ugly cast to boolean
  return not not redis:get('anti-flood:enabled:'..msg.to.id)
end

return {
  description = 'Plugin to kick flooders from group.',
  usage = {
    moderator = {
      "!antiflood enable/disable : Enable or disable flood checking",
      "!antiflood addexcept/delexcept <user_id> : Add user to antiflood exceptions",
      "!antiflood status : Get current antiflood parameters",
      "!antiflood maxmsg <num_msg> : Set number of messages/time needed to trip the antiflood",
      "!antiflood timeframe <seconds> : Set the antiflood's sample time frame",
      "#addexcept (by reply) : Add user to antiflood exceptions",
      "#delexcept (by reply) : Delete user from antiflood exceptions"
    },
  },
  patterns = {
    '^!antiflood (enable)$',
    '^!antiflood (disable)$',
    '^!antiflood (addexcept) (%d+)$',
    '^!antiflood (delexcept) (%d+)$',
    '^!antiflood (maxmsg) (%d+)$',
    '^!antiflood (timeframe) (%d+)$',
    '^!antiflood (status)$',
    '^#(addexcept)$',
    '^#(delexcept)$'
  },
  run = run,
  pre_process = pre_process
}
