local function mute_reply(extra, success, result)
  local hash = 'mute:'..result.to.peer_id..':'..result.from.peer_id
  redis:set(hash, true)
  send_large_msg(extra, str2emoji(':information_source:')..' User ID '..result.from.peer_id..' is now muted.')
end

local function delmute_reply(extra, success, result)
  local hash = 'mute:'..result.to.peer_id..':'..result.from.peer_id
  local reply
  if redis:get(hash) then
    redis:del(hash)
    reply = str2emoji(':information_source:')..' User ID '..result.from.peer_id..' is not muted anymore.'
  else
    reply = str2emoji(':information_source:')..' User ID '..result.from.peer_id..' wasn\'t muted.'
  end
  send_large_msg(extra, reply)
end

local function resolved_username(extra, success, result)
  if success then
    local hash = 'mute:'..extra.chat_id..':'..result.peer_id
    if extra.get_cmd == 'user' then
      redis:set(hash, true)
      send_large_msg(extra.receiver, str2emoji(':information_source:')..' User ID '..result.peer_id..' is now muted.')
    end
    if extra.get_cmd == 'delete' then
      if redis:get(hash) then
        redis:del(hash)
        send_large_msg(extra.receiver, str2emoji(':information_source:')..' User ID '..result.peer_id..' is not muted anymore.')
      else
        send_large_msg(extra.receiver, str2emoji(':information_source:')..' User ID '..result.peer_id..' wasn\'t muted.')
      end
    end
  else
    send_large_msg(extra.receiver, str2emoji(':exclamation:')..' User ID @'..extra.member..' does not exist!')
  end
end

local function run (msg, matches)
  if matches[1] ~= nil then
    if not is_chan_msg(msg) then
      return str2emoji(":exclamation:")..' Mute works only on supergroups'
    else
      if is_momod(msg) then
        local chat = msg.to.id
        local hash = 'anti-spam:enabled:'..chat
        if matches[1] == 'mute' then
          if msg.reply_id then
            get_message(msg.reply_id, mute_reply, get_receiver(msg))
            return nil
          end
        end
        if matches[1] == 'unmute' then
          if msg.reply_id then
            get_message(msg.reply_id, delmute_reply, get_receiver(msg))
            return nil
          end
        end
        if matches[1] == 'all' then
          local hash = 'mute:'..msg.to.id..':all'
          redis:set(hash, true)
          return str2emoji(':information_source:')..' All users on group '..string.gsub(msg.to.print_name, '_', ' ')..' ['..msg.to.id..'] are now muted.'
        end
        if matches[1] == 'undo' then
          local hash = 'mute:'..msg.to.id..':all'
          redis:del(hash)
          return str2emoji(':information_source:')..' All users on group '..string.gsub(msg.to.print_name, '_', ' ')..' ['..msg.to.id..'] are not muted anymore.'
        end
        if matches[2] then
          if string.match(matches[2], '^%d+$') then
            local hash = 'mute:'..msg.to.id..':'..matches[2]
            if matches[1] == 'user' then
              redis:set(hash, true)
              return str2emoji(':information_source:')..' User ID '..matches[2]..' is now muted.'
            end
            if matches[1] == 'delete' then
              if redis:get(hash) then
                redis:del(hash)
                return str2emoji(':information_source:')..' User ID '..matches[2]..' is not muted anymore.'
              else
                return str2emoji(':information_source:')..' User ID '..matches[2]..' wasn\'t muted.'
              end
            end
          else
            local member = string.gsub(matches[2], '@', '')
            return resolve_username(member, resolved_username, {get_cmd=matches[1], receiver=get_receiver(msg), chat_id=msg.to.id, member=member})
          end
        end
      else
        return str2emoji(":no_entry_sign:")..' You are not a moderator on this channel'
      end
    end
  end

  return nil
end

local function pre_process(msg)
  -- Ignore service msg
  if msg.service then
    print('Service message')
    return msg
  end

  local hash_muted = 'mute:'..msg.to.id..':'..msg.from.id
  local hash_all_muted = 'mute:'..msg.to.id..':all'
  local muted = redis:get(hash_muted) or redis:get(hash_all_muted)

  if is_momod(msg) then
    return msg
  end

  if muted then
    delete_msg(msg.id, ok_cb, nil)
    return nil
  end

  return msg
end

return {
  description = 'Plugin to mute people on supergroups.',
  usage = {
    moderator = {
      "!mute user username/id : Mute an user on current supergroup",
      "!mute delete username/id : Unmute an user on current supergroup",
      "!mute all : Mute all users on current supergroup (except mods)",
      "!mute undo : Stop muting all users on current supergroup",
      "#mute (by reply) : Mute an user on current supergroup",
      "#unmute (by reply) : Unmute an user on current supergroup"
    },
  },
  patterns = {
    '^!mute (user) (.*)$',
    '^!mute (delete) (.*)$',
    '^!mute (all)$',
    '^!mute (undo)$',
    '^#(mute)$',
    '^#(unmute)$'
  },
  run = run,
  pre_process = pre_process
}
