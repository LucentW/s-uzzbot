local MAX_WARN = 3
local ACTION_WARN = 'ban'

local function ban_user(chat_id, user_id)
  local chat = 'chat#id'..chat_id
  local user = 'user#id'..user_id
  local hash =  'banned:'..chat_id..':'..user_id
  redis:set(hash, true)
  chat_del_user(chat, user, function (data, success, result)
    if not success then
      local text = str2emoji(":exclamation:")..' I can\'t kick '..data.user..' but should be kicked'
	    snoop_msg('I am unable to kick user '..user_id..' from group '..chat_id..'.')
      send_msg(data.chat, text, ok_cb, nil)
    end
  end, {chat=chat, user=user})
end

local function kick_user(chat_id, user_id)
  local chat = 'chat#id'..chat_id
  local user = 'user#id'..user_id
  print(chat, user)
  chat_del_user(chat, user, function (data, success, result)
    if not success then
      local text = str2emoji(":exclamation:")..' I can\'t kick '..data.user..' but should be kicked'
	    snoop_msg('I am unable to kick user '..user_id..' from group '..chat_id..'.')
      send_msg(data.chat, text, ok_cb, nil)
    end
  end, {chat=chat, user=user})
end

local function ban_chan_user(chat_id, user_id)
  local chat = 'channel#id'..chat_id
  local user = 'user#id'..user_id
  local hash =  'banned:'..chat_id..':'..user_id
  redis:set(hash, true)
  channel_kick(chat, user, function (data, success, result)
    if not success then
      local text = str2emoji(":exclamation:")..' I can\'t ban '..data.user..' but should be banned'
	    snoop_msg('I am unable to ban user '..user_id..' from supergroup '..chat_id..'.')
      send_msg(data.chat, text, ok_cb, nil)
    end
  end, {chat=chat, user=user})
end

local function kick_chan_user(chat_id, user_id)
  local chat = 'channel#id'..chat_id
  local user = 'user#id'..user_id
  print(chat, user)
  channel_kick(chat, user, function (data, success, result)
    if not success then
      local text = str2emoji(":exclamation:")..' I can\'t kick '..data.user..' but should be kicked'
	    snoop_msg('I am unable to kick user '..user_id..' from supergroup '..chat_id..'.')
      send_msg(data.chat, text, ok_cb, nil)
    end
  end, {chat=chat, user=user})
  channel_unblock(chat, user, function (data, success, result)
    if not success then
      local text = str2emoji(":exclamation:")..' I can\'t unban '..data.user
	    snoop_msg('I am unable to unban user '..user_id..' from supergroup '..chat_id..'.')
      send_msg(data.chat, text, ok_cb, nil)
    end
  end, {chat=chat, user=user})
end

local function warn_reply(extra, success, result)
  if not success then return end
  if is_mod(result.from.peer_id, result.to.peer_id) then
    send_large_msg(extra, str2emoji(':no_entry_sign:')..' I won\'t warn myself, admins or mods.')
    return
  end
  local hash = 'warn:'..result.to.peer_id..':'..result.from.peer_id
  local hashmax = 'maxwarn:'..result.to.peer_id
  local counter = tonumber(redis:get(hash) or 0)+1
  local locmax_warn = tonumber(redis:get(hashmax)) or MAX_WARN
  local action = redis:get('actionwarn:'..result.to.peer_id) or ACTION_WARN
  redis:set(hash, counter)
  if counter >= tonumber(locmax_warn) then
    redis:del(hash)
    send_large_msg(extra, str2emoji(':exclamation:')..' User ID '..result.from.peer_id..' has been warned '..counter..' times. Banned.')
	  if is_chan_msg(result) then
      if action == 'ban' then
	      return ban_chan_user(result.to.peer_id, result.from.peer_id)
      elseif action == 'kick' then
        return kick_chan_user(result.to.peer_id, result.from.peer_id)
      end
	  else
      if action == 'ban' then
	      return ban_user(result.to.peer_id, result.from.peer_id)
      elseif action == 'kick' then
        return kick_user(result.to.peer_id, result.from.peer_id)
      end
    end
  end
  send_large_msg(extra, str2emoji(':information_source:')..' User ID '..result.from.peer_id..' now has '..counter..' warn(s).')
end

local function rstwarn_reply(extra, success, result)
  if not success then return end
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
  if not success then return end
  local hash = 'warn:'..result.to.peer_id..':'..result.from.peer_id
  local counter = tonumber(redis:get(hash) or 0)
  send_large_msg(extra, str2emoji(':information_source:')..' User ID '..result.from.peer_id..' has currently '..counter..' warn(s).')
end

local function run (msg, matches)
  if not matches[1] then
    return
  end
  if not is_chat_msg(msg) then
    return str2emoji(":exclamation:")..' Warn works only on groups'
  end

  --works only for mods
  if is_momod(msg) then
    local chat = msg.to.id

	  if matches[2] then
      --Set maximum warns
		  if matches[1] == 'setwarn' then
		    if tonumber(matches[2]) > 1 then
		      local hashmax = 'maxwarn:'..chat
          redis:set(hashmax, matches[2])
		      return str2emoji(':information_source:')..' Maximum warns now set at '..matches[2]..' warn(s).'
			  else
          return str2emoji(':no_entry_sign:')..' Instead of setting warns at 1, you should use #ban or !ban user.'
        end
      end

      --Set the penalty
      if matches[1] == 'setwarnaction' then
        local hash = 'actionwarn:' .. chat
        if matches[2] == 'kick' then
          redis:set(hash, 'kick')
          return str2emoji(':information_source:') .. ' The penalty is now kick'
        elseif matches[2] == 'ban' then
          redis:set(hash, 'ban')
          return str2emoji(':information_source:') .. ' The penalty is now ban'
        end
      end

      --Warn status
		  if matches[2] == 'info' then
        local u = false
        --Warn status user
		    if matches[3] then
          if not matches[3]:match("^%d+$") then
            u = matches[3] or ""
            resolve_username(matches[3], function(extra, success, result)
              if not success then
                matches[3] = false
              else
                if result.peer_type == "user" then
                  matches[3] = result.peer_id
                else
                  matches[3] = false
                end
              end
            end, false)
            if not matches[3] then
              return str2emoji(':exclamation:') .. " User " .. u .. "not found."
            end
          end
          local hash = 'warn:'..chat..':'..matches[3]
          local counter = redis:get(hash) or 0
          if u then
            return str2emoji(':information_source:')..' User '..u..' ['..matches[3]..'] has currently '..counter..' warn(s).'
          else
            return str2emoji(':information_source:')..' User ID '..matches[3]..' has currently '..counter..' warn(s).'
          end
        end

        --Warn status chat
		    local hashmax = 'maxwarn:'..chat
        local locmax_warn = redis:get(hashmax) or MAX_WARN
		    return str2emoji(':information_source:')..' Warn current parameters:\n'..str2emoji(":no_entry_sign:")..' Ban set at '..locmax_warn..' warn(s).'
		  end

      --Get the id from a username
      local u = false
      if not matches[2]:match("^%d+$") then
        u = matches[2] or ""
        resolve_username(matches[2], function(extra, success, result)
          if not success then
            matches[2] = false
          else
            if result.peer_type == "user" then
              matches[2] = result.peer_id
            else
              matches[2] = false
            end
          end
        end, false)
        if not matches[2] then
          return str2emoji(':exclamation:') .. " User " .. u .. "not found."
        end
      end

      --Warining script
		  local hash = 'warn:'..chat..':'..matches[2]
	    if matches[1] == 'warn' then
        if is_mod(matches[2], msg.to.id) then
          return str2emoji(':no_entry_sign:')..' I won\'t warn myself, admins or mods.'
        end
        local hashmax = 'maxwarn:'..chat
        local counter = math.ceil(tonumber(redis:get(hash)) or 0)+1
        local locmax_warn = redis:get(hashmax) or MAX_WARN
        local action = redis:get('actionwarn:'..chat) or ACTION_WARN
        redis:set(hash, counter)
        if counter >= tonumber(locmax_warn) then
          redis:del(hash) --Reset waring for the user
          if is_chan_msg(msg) then
            if action == 'ban' then
              ban_chan_user(msg.to.id, matches[2])
            elseif action == 'kick' then
              kick_chan_user(msg.to.id, matches[2])
            end
	        else
            if action == 'ban' then
              ban_user(msg.to.id, matches[2])
            elseif action == 'kick' then
              kick_user(msg.to.id, matches[2])
            end
	        end
          if u then
            return str2emoji(':exclamation:')..' User '..u..' ['..matches[2]..'] has been warned '..counter..' times. Banned.'
          else
            return str2emoji(':exclamation:')..' User ID '..matches[2]..' has been warned '..counter..' times. Banned.'
          end
        end
        if u then
          return str2emoji(':information_source:')..' User ' .. u .. ' ['..matches[2]..'] now has '..counter..' warn(s).'
        else
          return str2emoji(':information_source:')..' User ID '..matches[2]..' now has '..counter..' warn(s).'
        end
		  end

      --Reset warning
		  if matches[1] == 'resetwarn' then
		    local reply
		    if redis:get(hash) then
          redis:del(hash)
          if u then
            reply = str2emoji(':information_source:')..' User '..u..' ['..matches[2]..'] has no more warns.'
          else
            reply = str2emoji(':information_source:')..' User ID '..matches[2]..' has no more warns.'
          end
        else
          if u then

          else
            reply = str2emoji(':information_source:')..' User '..u..' ['..matches[2]..'] had no warns.'
          end
        end
			  return reply
		  end
	  end

    --Reply commands
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

		if matches[1] == 'warninfo' then
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
          "!setwarn <number> : Set how many warns are needed to trip the automatic ban",
          "!warn <user_id/username> : Adds a warn point to user_id",
		      "!warn info : Returns the plugin's settings",
		      "!warn info <user_id/username> : Returns how many warns user_id got",
		      "!resetwarn <user_id/username> : Reset user_id's warn points to 0",
          "!setwarnaction <kick/ban : Set the penalty to kick or ban",
		      "#warn (by reply) : Adds a warn point",
		      "#resetwarn (by reply) : Reset warn points to 0",
		      "#warninfo (by reply) : Returns how many warns the user got"
      },
  },
  patterns = {
      '^!(setwarn) (%d+)$',
	    '^!(warn) (info)$',
	    '^!(warn) (info) (%d+)$',
      '^!(warn) (info) @?(%a[%w_]+)$',
	    '^!(warn) (%d+)$',
      '^!(warn) @?(%a[%w_]+)$',
	    '^!(resetwarn) (%d+)$',
      '^!(resetwarn) @?(%a[%w_]+)$',
      '^!(setwarnaction) (ban)$',
      '^!(setwarnaction) (kick)$',
	    '^#(warn)$',
	    '^#(resetwarn)$',
	    '^#(warninfo)$'
  },
  run = run,
  pre_process = pre_process
}
