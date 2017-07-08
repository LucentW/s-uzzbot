local MAX_WARN = 3

local function ban_user(user_id, chat_id)
  local chat = 'chat#id'..chat_id
  local user = 'user#id'..user_id
  local hash =  'banned:'..chat_id..':'..user_id
  redis:set(hash, true)
  chat_del_user(chat, user, function (data, success, result)
    if success ~= 1 then
      local text = str2emoji(":exclamation:")..' I can\'t kick '..data.user..' but should be kicked'
	    snoop_msg('I am unable to kick user '..user_id..' from group '..chat_id..'.')
      send_msg(data.chat, text, ok_cb, nil)
    end
  end, {chat=chat, user=user})
end

local function ban_chan_user(user_id, chat_id)
  local chat = 'channel#id'..chat_id
  local user = 'user#id'..user_id
  local hash =  'banned:'..chat_id..':'..user_id
  redis:set(hash, true)
  channel_kick(chat, user, function (data, success, result)
    if success ~= 1 then
      local text = str2emoji(":exclamation:")..' I can\'t kick '..data.user..' but should be kicked'
	    snoop_msg('I am unable to kick user '..user_id..' from group '..chat_id..'.')
      send_msg(data.chat, text, ok_cb, nil)
    end
  end, {chat=chat, user=user})
end

local function warn_reply(extra, success, result)
  local hash = 'warn:'..result.to.peer_id..':'..result.from.peer_id
  local hashmax = 'maxwarn:'..result.to.peer_id
  local counter = redis:get(hash)+1 or 1
  local locmax_warn = redis:get(hashmax) or MAX_WARN
  redis:set(hash, counter)
  if counter >= tonumber(locmax_warn) then
    redis:del(hash)
    send_large_msg(extra, str2emoji(':exclamation:')..' User ID '..result.from.peer_id..' has been warned '..counter..' times. Banned.')
	  if is_chan_msg(result) then
	    return ban_chan_user(result.to.peer_id, result.from.peer_id)
	  else
	    return ban_user(result.to.peer_id, result.from.peer_id)
    end
  end
  send_large_msg(extra, str2emoji(':information_source:')..' User ID '..result.from.peer_id..' now has '..counter..' warn(s).')
end

local function rstwarn_reply(extra, success, result)
  local hash = 'warn:'..result.to.peer_id..':'..result.from.peer_id
  local reply
  if redis:get(hash) then
    redis:del(hash)
    reply = str2emoji(':information_source:')..' User ID '..result.from.peer_id..' has no more warns.'
  else
    reply = str2emoji(':information_source:')..' User ID '..result.from.peer_id..' had no warns.'
  end
  send_large_msg(extra, reply)
end

local function status_reply(extra, success, result)
  local hash = 'warn:'..result.to.peer_id..':'..result.from.peer_id
  local counter = redis:get(hash) or 0
  send_large_msg(extra, str2emoji(':information_source:')..' User ID '..result.from.peer_id..' has currently '..counter..' warn(s).')
end

local function run (msg, matches)
  if matches[1] ~= nil then
    return
  end
  if not is_chat_msg(msg) then
    return str2emoji(":exclamation:")..' Warn works only on groups'
  end
  if is_momod(msg) then
    local chat = msg.to.id

	  if matches[2] then
		  if matches[1] == 'setwarn' then
		    if matches[2] > 1 then
		      local hashmax = 'maxwarn:'..chat
          redis:set(hashmax, matches[2])
		      return str2emoji(':information_source:')..' Maximum warns now set at '..matches[2]..' warn(s).'
			  else
          return str2emoji(':no_entry_sign:')..' Instead of setting warns at 1, you should use #ban or !ban user.'
        end
      end

		  if matches[2] == 'status' then
		    if matches[3] then
          local hash = 'warn:'..chat..':'..matches[3]
          local counter = redis:get(hash) or 0
          return str2emoji(':information_source:')..' User ID '..matches[3]..' has currently '..counter..' warn(s).'
        end

		    local hashmax = 'maxwarn:'..chat
        local locmax_warn = redis:get(hashmax) or MAX_WARN
		    return str2emoji(':information_source:')..' Warn current parameters:\n'..str2emoji(":no_entry_sign:")..' Ban set at '..locmax_warn..' warn(s).'
		  end

		  hash = 'warn:'..chat..':'..matches[2]
	    if matches[1] == 'warn' then
        local hashmax = 'maxwarn:'..chat
        local counter = redis:get(hash)+1 or 1
        local locmax_warn = redis:get(hashmax) or MAX_WARN
        redis:set(hash, counter)
        if counter >= tonumber(locmax_warn) then
          redis:del(hash)
          if is_chan_msg(result) then
	            ban_chan_user(result.to.peer_id, result.from.peer_id)
	        else
	          ban_user(result.to.peer_id, result.from.peer_id)
	        end
          return str2emoji(':exclamation:')..' User ID '..result.from.peer_id..' has been warned '..counter..' times. Banned.'
        end
        return str2emoji(':information_source:')..' User ID '..result.from.peer_id..' now has '..counter..' warn(s).'
		  end

		  if matches[1] == 'resetwarn' then
		    local reply
		    if redis:get(hash) then
          redis:del(hash)
          reply = str2emoji(':information_source:')..' User ID '..result.from.peer_id..' has no more warns.'
        else
          reply = str2emoji(':information_source:')..' User ID '..result.from.peer_id..' had no warns.'
        end
			  return reply
		  end
	  end

    if matches[1] == 'warn' then
      if msg.reply_id then
        get_message(msg.reply_id, warn_reply, get_receiver(msg))
	      return nil
	    end
	  end

	  if matches[1] == 'resetwarn' then
	    if msg.reply_id then
	      get_message(msg.reply_id, rstwarn_reply, get_receiver(msg))
	      return nil
	    end
	  end

		if matches[1] == 'status' then
	    if msg.reply_id then
	      get_message(msg.reply_id, status_reply, get_receiver(msg))
	      return nil
	    end
	  end
  else
    return str2emoji(":no_entry_sign:")..' You are not a moderator on this channel'
  end

  return nil
end

return {
  description = 'Plugin to keep a warning list on the group.',
  usage = {
      moderator = {
          "!setwarn <number> : Set how many warns are needed to trip the automatic ban"
          "!warn <user_id> : Adds a warn point to user_id",
		      "!warn status : Returns the plugin's settings",
		      "!warn status <user_id> : Returns how many warns user_id got",
		      "!resetwarn <user_id> : Reset user_id's warn points to 0",
		      "#warn (by reply) : Adds a warn point",
		      "#resetwarn (by reply) : Reset warn points to 0",
		      "#status (by reply) : Returns how many warns the user got"
      },
  },
  patterns = {
      '^!(setwarn) (%d+)$',
	    '^!(warn) (status)$',
	    '^!(warn) (status) (%d+)$',
	    '^!(warn) (%d+)$',
	    '^!(resetwarn) (%d+)$',
	    '^#(warn)$',
	    '^#(resetwarn)$',
	    '^#(status)$'
  },
  run = run,
  pre_process = pre_process
}
