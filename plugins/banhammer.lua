local function is_user_whitelisted(id)
  local hash = 'whitelist:user#id'..id
  local white = redis:get(hash) or false
  return white
end

local function is_chat_whitelisted(id)
  local hash = 'whitelist:chat#id'..id
  local white = redis:get(hash) or false
  return white
end

local function kick_user(user_id, chat_id, receiver)
  local chat = 'chat#id'..chat_id
  local user = 'user#id'..user_id
  if not is_mod(user_id, chat_id) then
    chat_del_user(chat, user, ok_cb, true)
    return true
  else
    send_large_msg(receiver, str2emoji(':no_entry_sign:')..' I won\'t kick myself, admins or mods.')
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
    send_large_msg(receiver, str2emoji(':no_entry_sign:')..' I won\'t kick myself, admins or mods.')
    return false
  end
end

local function kick_by_reply(extra, success, result)
  if extra.is_chan then
    kick_chan_user(result.from.peer_id, result.to.peer_id, extra.receiver)
  else
    kick_user(result.from.peer_id, result.to.peer_id, extra.receiver)
  end
end

local function ban_user(user_id, chat_id, receiver)
  if not is_mod(user_id, chat_id) then
    -- Save to redis
    local hash = 'banned:'..chat_id..':'..user_id
    redis:set(hash, true)
    -- Kick from chat
    kick_user(user_id, chat_id, receiver)
    return true
  else
    send_large_msg(receiver, str2emoji(':no_entry_sign:')..' I won\'t ban myself, admins or mods.')
    return false
  end
end

local function ban_chan_user(user_id, chat_id, receiver)
  if not is_mod(user_id, chat_id) then
    -- Save to redis
    local hash = 'banned:'..chat_id..':'..user_id
    redis:set(hash, true)
    -- Kick from chat
    kick_chan_user(user_id, chat_id, receiver)
    return true
  else
    send_large_msg(receiver, str2emoji(':no_entry_sign:')..' I won\'t ban myself, admins or mods.')
    return false
  end
end

local function ban_by_reply(extra, success, result)
  if extra.is_chan then
    send_large_msg(extra.receiver, str2emoji(':exclamation:')..' User '..result.from.peer_id..' banned!')
    ban_chan_user(result.from.peer_id, result.to.peer_id, extra.receiver)
  else
    send_large_msg(extra.receiver, str2emoji(':exclamation:')..' User '..result.from.peer_id..' banned!')
    ban_user(result.from.peer_id, result.to.peer_id, extra.receiver)
  end
end

local function unban_by_reply(extra, success, result)
  local hash = 'banned:'..result.to.peer_id..':'..result.from.peer_id
  if redis:get(hash) then
    redis:del(hash)
    if is_chan_msg(result) then
      channel_unblock(get_receiver(result), get_receiver(result.from))
    end
    send_large_msg(extra.receiver, str2emoji(':information_source:')..' User '..result.from.peer_id..' unbanned!')
  else
    send_large_msg(extra.receiver, str2emoji(':information_source:')..' There is no ban for user '..result.from.peer_id..'!')
  end
end

local function superban_user(user_id, chat_id, receiver)
  if not is_mod(user_id, chat_id) then
    -- Save to redis
    local hash = 'superbanned:'..user_id
    redis:set(hash, true)
    -- Kick from chat
    kick_user(user_id, chat_id, receiver)
    return true
  else
    send_large_msg(receiver, str2emoji(':no_entry_sign:')..' I won\'t superban myself, admins or mods.')
    return false
  end
end

local function superban_chan_user(user_id, chat_id, receiver)
  if not is_mod(user_id, chat_id) then
    -- Save to redis
    local hash = 'superbanned:'..user_id
    redis:set(hash, true)
    -- Kick from chat
    kick_chan_user(user_id, chat_id, receiver)
    return true
  else
    send_large_msg(receiver, str2emoji(':no_entry_sign:')..' I won\'t superban myself, admins or mods.')
    return false
  end
end

local function superban_by_reply(extra, success, result)
  send_large_msg(extra.receiver, str2emoji(':exclamation:')..' User '..result.from.peer_id..' superbanned!')
  if extra.is_chan then
    superban_chan_user(result.from.peer_id, result.to.peer_id, extra.receiver)
  else
    superban_user(result.from.peer_id, result.to.peer_id, extra.receiver)
  end
end

local function blocklist_user(user_id, chat_id, receiver)
  if not is_mod(user_id, chat_id) then
    -- Save to redis
    local hash = 'blocklist:'..user_id
    redis:set(hash, true)
    -- Kick from chat
    kick_user(user_id, chat_id, receiver)
    return true
  else
    send_large_msg(receiver, str2emoji(':no_entry_sign:')..' I won\'t blocklist myself, admins or mods.')
    return false
  end
end

local function blocklist_chan_user(user_id, chat_id, receiver)
  if not is_mod(user_id, chat_id) then
    -- Save to redis
    local hash = 'blocklist:'..user_id
    redis:set(hash, true)
    -- Kick from chat
    kick_chan_user(user_id, chat_id, receiver)
    return true
  else
    send_large_msg(receiver, str2emoji(':no_entry_sign:')..' I won\'t blocklist myself, admins or mods.')
    return false
  end
end

local function blocklist_by_reply(extra, success, result)
  send_large_msg(extra.receiver, str2emoji(':exclamation:')..' User '..result.from.peer_id..' blocklisted!')
  if extra.is_chan then
    blocklist_chan_user(result.from.peer_id, result.to.peer_id, extra.receiver)
  else
    blocklist_user(result.from.peer_id, result.to.peer_id, extra.receiver)
  end
end

local function is_banned(user_id, chat_id)
  local hash = 'banned:'..chat_id..':'..user_id
  local banned = redis:get(hash)
  return banned or false
end

local function is_super_banned(user_id)
  local hash = 'superbanned:'..user_id
  local superbanned = redis:get(hash)
  return superbanned or false
end

local function is_super_banned2(user_id, chat_id)
  local hash = 'superbanned:'..user_id
  local hashexc = 'superbanexc:'..chat_id
  local superbanned = redis:get(hash)
  local superbanexc = redis:get(hashexc)
  return superbanned and not superbanexc
end

local function is_blocklisted(user_id, chat_id)
  local hash = 'blocklist:'..user_id
  local hash2 = 'blocklistok:'..chat_id
  local blocklisted = redis:get(hash)
  local is_chat_blocklist_ok = redis:get(hash2)
  return blocklisted and is_chat_blocklist_ok
end

local function check_ban_all(chat, users, is_chan)
  for _, user in ipairs(users) do
    print('Checking invited user '..user_id)
    local user_id = user.id
    local superbanned = is_super_banned2(user_id, chat)
    local banned = is_banned(user_id, chat)
    local blocklisted = is_blocklisted(user_id, chat)
    if superbanned or banned or blocklisted then
      print('User is banned!')
      if not is_chan_msg(msg) then
        kick_user(user_id, chat, "chat#id" .. chat)
      else
        kick_chan_user(user_id, chat, "channel#id" .. chat)
      end
    end
  end
end

local function pre_process(msg)

  -- SERVICE MESSAGE
  if msg.action and msg.action.type then
    local action = msg.action.type
    -- Check if banned user joins chat
    if action == 'chat_add_user' then
      check_ban_all(msg.to.id, users, is_chan_msg(msg))
    elseif action == 'chat_add_user_link' then
      local user_id = msg.from.id
      print('Checking invited user '..user_id)
      local superbanned = is_super_banned2(user_id, msg.to.id)
      local banned = is_banned(user_id, msg.to.id)
      local blocklisted = is_blocklisted(user_id, msg.to.id)
      if superbanned or banned or blocklisted then
        print('User is banned!')
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
    local superbanned = is_super_banned2(user_id, msg.to.id)
    local banned = is_banned(user_id, chat_id)
    local blocklisted = is_blocklisted(user_id, msg.to.id)
    if superbanned or blocklisted or banned then
      print('Banned user talking!')
      if not is_chan_msg(msg) then
        kick_user(user_id, chat_id, get_receiver(msg))
      else
        kick_chan_user(user_id, chat_id, get_receiver(msg))
      end
      if not is_mod(user_id, chat_id) then
        msg.text = ''
      end
    end
  end

  -- WHITELIST
  local hash = 'whitelist:enabled'
  local whitelist = redis:get(hash)
  local issudo = is_sudo(msg)

  -- Allow all sudo users even if whitelist is allowed
  if whitelist and not issudo then
    print('Whitelist enabled and not sudo')
    -- Check if user or chat is whitelisted
    local allowed = is_user_whitelisted(msg.from.id)

    if not allowed then
      print('User '..msg.from.id..' not whitelisted')
      if msg.to.type == 'chat' then
        allowed = is_chat_whitelisted(msg.to.id)
        if not allowed then
          print ('Chat '..msg.to.id..' not whitelisted')
          msg = nil
        else
          print ('Chat '..msg.to.id..' whitelisted :)')
        end
      end
    end
  end

  return msg
end

--This function is called after resolving a username
local function resolved_username(cb_extra, success, result)
  local get_cmd = cb_extra.get_cmd
  local receiver = cb_extra.receiver
  local chat_id = cb_extra.chat_id
  local member = cb_extra.member
  local is_chan = cb_extra.is_chan
  local text = str2emoji(':exclamation:')..' User @'..member..' does not exist.'

  if success == 1 then
    if result.username then member = result.username end
    member_id = result.peer_id
    if get_cmd == 'kick' then
      if not is_chan then
        return kick_user(member_id, chat_id, receiver)
      else
        return kick_chan_user(member_id, chat_id, receiver)
      end
    elseif get_cmd == 'ban user' then
      if not is_chan then
        if ban_user(member_id, chat_id, receiver) then
          return send_large_msg(receiver, str2emoji(':exclamation:')..' User @'..member..' ['..member_id..'] banned')
        else
          return nil
        end
      else
        if ban_chan_user(member_id, chat_id, receiver) then
          return send_large_msg(receiver, str2emoji(':exclamation:')..' User @'..member..' ['..member_id..'] banned!')
        else
          return nil
        end
      end
    elseif get_cmd == 'ban delete' then
      local hash = 'banned:'..chat_id..':'..member_id
      if redis:get(hash) then
        redis:del(hash)
        if is_chan then
          channel_unblock(receiver, 'user#id'..member_id)
        end
        return send_large_msg(receiver, str2emoji(':information_source:')..' User @'.. member .. ' ['..member_id .. '] unbanned')
      else
        return send_large_msg(receiver, str2emoji(':information_source:')..' There is no ban for @' .. member .. ' ['..member_id .. '] here.')
      end
    elseif get_cmd == 'superban user' then
      if not is_chan then
        if superban_user(member_id, chat_id, receiver) then
          return send_large_msg(receiver, str2emoji(':exclamation:')..' User @'..member..' ['..member_id..'] globally banned!')
        else
          return nil
        end
      else
        if superban_chan_user(member_id, chat_id, receiver) then
          return send_large_msg(receiver, str2emoji(':exclamation:')..' User @'..member..' ['..member_id..'] globally banned!')
        else
          return nil
        end
      end
    elseif get_cmd == 'superban delete' then
      local hash = 'superbanned:' .. member_id
      if redis:get(hash) then
        redis:del(hash)
        return send_large_msg(receiver, str2emoji(':information_source:')..' User @'..member .. ' [' ..member_id .. '] unbanned')
      else
        return send_large_msg(receiver, str2emoji(':information_source:')..' There is no global ban for @'..member .. '[' .. member_id .. ']')
      end
    elseif get_cmd == 'blocklist user' then
      if not is_chan then
        if blocklist_user(member_id, chat_id, receiver) then
          return send_large_msg(receiver, str2emoji(':exclamation:')..' User @'..member..' ['..member_id..'] banned on blocklist adhering groups!')
        else
          return nil
        end
      else
        if blocklist_chan_user(member_id, chat_id, receiver) then
          return send_large_msg(receiver, str2emoji(':exclamation:')..' User @'..member..' ['..member_id..'] banned on blocklist adhering groups!')
        else
          return nil
        end
      end
    elseif get_cmd == 'blocklist delete' then
      local hash = 'blocklist:' .. member_id
      if redis:get(hash) then
        redis:del(hash)
        return send_large_msg(receiver, str2emoji(':information_source:')..' User @'..member .. ' [' ..member_id .. '] removed from the blocklist')
      else
        return send_large_msg(receiver, str2emoji(':information_source:')..' User @'..member .. ' [' .. member_id .. '] is not blocklisted')
      end
    elseif get_cmd == 'whitelist user' then
      local hash = 'whitelist:user#id'..member_id
      redis:set(hash, true)
      return send_large_msg(receiver, str2emoji(':information_source:')..' User @'..member..' ['..member_id..'] whitelisted')
    elseif get_cmd == 'whitelist delete user' then
      local hash = 'whitelist:user#id'..member_id
      redis:del(hash)
      return send_large_msg(receiver, str2emoji(':information_source:')..' User @'..member..' ['..member_id..'] removed from whitelist')
    end
    -- end
  end
  return send_large_msg(receiver, text)
end

local function run(msg, matches)
  local receiver = get_receiver(msg)
-- KickMe!!!!
  if matches[1] == 'kickme' then
    if is_chat_msg(msg) then
      if is_chan_msg(msg) then
        channel_kick('channel#id'..msg.to.id, 'user#id'..msg.from.id, ok_cb, true)
      else
        chat_del_user('chat#id'..msg.to.id, 'user#id'..msg.from.id, ok_cb, true)
      end
    end
  end

-- After this, only moderators can use this plugin
  if not is_momod(msg) then
    return nil
  end


  if matches[4] then
    get_cmd = matches[1]..' '..matches[2]..' '..matches[3]
  elseif matches[3] then
    get_cmd = matches[1]..' '..matches[2]
  else
    get_cmd = matches[1]
  end

--Unban via reply
  if matches[1] == 'unban' then
    if msg.reply_id then
      get_message(msg.reply_id, unban_by_reply, {receiver=get_receiver(msg)})
      return nil
    end
  end

--!ban command block
  if matches[1] == 'ban' then
    --Ban via reply
    if msg.reply_id then
      get_message(msg.reply_id, ban_by_reply, {is_chan=is_chan_msg(msg),receiver=get_receiver(msg)})
      return nil
    end

  --Ban/Unban via userid/username
    local user_id = matches[3]
    local chat_id = msg.to.id
    if is_chat_msg(msg) then
      if matches[2] == 'user' then
        if string.match(matches[3], '^%d+$') then
          if not is_chan_msg(msg) then
            if ban_user(user_id, chat_id, receiver) then
              send_large_msg(receiver, str2emoji(':exclamation:')..' User '..user_id..' banned!')
            end
          else
            if ban_chan_user(user_id, chat_id, receiver) then
              send_large_msg(receiver, str2emoji(':exclamation:')..' User '..user_id..' banned!')
            end
          end
        else
          local member = string.gsub(matches[3], '@', '')
          resolve_username(member, resolved_username, {get_cmd=get_cmd, receiver=receiver, chat_id=chat_id, member=member, is_chan=is_chan_msg(msg)})
        end
      end
      if matches[2] == 'delete' then
        local hash
        if string.match(matches[3], '^%d+$') then
          local hash = 'banned:'..chat_id..':'..user_id
          if redis:get(hash) then
            redis:del(hash)
            if is_chan_msg(msg) then
              channel_unblock(receiver, 'user#id'..user_id)
            end
            return str2emoji(':information_source:')..' User '..user_id..' unbanned'
          else
            return str2emoji(':information_source:')..' There is no ban for '..user_id..' here.'
          end
        else
          local member = string.gsub(matches[3], '@', '')
          return resolve_username(member, resolved_username, {get_cmd=get_cmd, receiver=receiver, chat_id=chat_id, member=member, is_chan=is_chan_msg(msg)})
        end
      end
    else
      return str2emoji(':no_entry_sign:')..' This isn\'t a chat group'
    end
  end

--!superban command block
  if matches[1] == 'superban' then
    local user_id = matches[3]
    local chat_id = msg.to.id

  --Enable/Disable superban in chat
    if is_chat_msg(msg) then
      if matches[2] == 'disable' then
        local hash = 'superbanexc:'..msg.to.id
        redis:set(hash, true)
        return str2emoji(':information_source:')..' Superbans are not applied anymore on group '..string.gsub(msg.to.print_name, '_', ' ')..' ['..msg.to.id..'].'
      end

      if matches[2] == 'enable' then
        local hash = 'superbanexc:'..msg.to.id
        redis:del(hash)
        return str2emoji(':information_source:')..' Superbans are now enforced on group '..string.gsub(msg.to.print_name, '_', ' ')..' ['..msg.to.id..'].'
      end
    end

--Only admin can superban
    if not is_admin(msg) then
      return nil
    end
--Superban via reply
    if msg.reply_id then
      get_message(msg.reply_id, superban_by_reply, {is_chan=is_chan_msg(msg),receiver=get_receiver(msg)})
      return nil
    end
--Superban/SuperUnban via userid/username
    if matches[2] == 'user' then
      if string.match(matches[3], '^%d+$') then
        if superban_user(user_id, chat_id, receiver) then
          send_large_msg(receiver, str2emoji(':exclamation:')..' User '..user_id..' globally banned!')
        end
      else
        local member = string.gsub(matches[3], '@', '')
        resolve_username(member, resolved_username, {get_cmd=get_cmd, receiver=receiver, chat_id=chat_id, member=member, is_chan=is_chan_msg(msg)})
      end
    end
    if matches[2] == 'delete' then
      if user_id:match('^%d+$') then
        local hash = 'superbanned:'..user_id
        redis:del(hash)
        return str2emoji(':information_source:')..' User '..user_id..' unbanned'
      else
        local member = matches[3]:gsub('@', '')
        resolve_username(member, resolved_username, {get_cmd=get_cmd, receiver=receiver, chat_id=chat_id, member=member, is_chan=is_chan_msg(msg)})
      end
    end
  end

  --!Blocklist command block
  if matches[1] == 'blocklist' and is_blocklistadm(msg) then
    --Blocklist via reply
    if msg.reply_id then
      return get_message(msg.reply_id, blocklist_by_reply, {is_chan=is_chan_msg(msg),receiver=get_receiver(msg)})
    end

    local user_id = matches[3]
    local chat_id = msg.to.id
    --Blocklist/UnBlocklist via userid/username
    if matches[2] == 'user' then
      if string.match(matches[3], '^%d+$') then
        if blocklist_user(user_id, chat_id, receiver) then
          send_large_msg(receiver, str2emoji(':exclamation:')..' User '..user_id..' banned on blocklist adhering groups!')
        end
      else
        local member = string.gsub(matches[3], '@', '')
        resolve_username(member, resolved_username, {get_cmd=get_cmd, receiver=receiver, chat_id=chat_id, member=member, is_chan=is_chan_msg(msg)})
      end
    end
    if matches[2] == 'delete' then
      if user_id:match('^%d+$') then
        local hash = 'blocklist:'..user_id
        redis:del(hash)
        return str2emoji(':information_source:')..' User '..user_id..' removed from the blocklist'
      else
        local member = matches[3]:gsub('@', '')
        resolve_username(member, resolved_username, {get_cmd=get_cmd, receiver=receiver, chat_id=chat_id, member=member, is_chan=is_chan_msg(msg)})
      end
    end

    --Enable/Disable Blocklist in chat
    if matches[2] == 'enable' then
      local hash = 'blocklistok:'..msg.to.id
      redis:set(hash, true)
      return str2emoji(':information_source:')..' Chat '..msg.to.print_name..' ['..msg.to.id..'] is now subscripted to the blocklist'
    end
    if matches[2] == 'disable' then
      local hash = 'blocklistok:'..msg.to.id
      redis:del(hash)
      return str2emoji(':information_source:')..' Chat '..msg.to.print_name..' ['..msg.to.id..'] is now unsubscripted from the blocklist'
    end
  end

--!kick command block
  if matches[1] == 'kick' then
    --Kick via reply
    if msg.reply_id then
      get_message(msg.reply_id, kick_by_reply, {is_chan=is_chan_msg(msg),receiver=get_receiver(msg)})
      return nil
    end

    --Kick via userid/username
    if is_chat_msg(msg) then
      if string.match(matches[2], '^%d+$') then
        if not is_chan_msg(msg) then
          kick_user(matches[2], msg.to.id, receiver)
        else
          kick_chan_user(matches[2], msg.to.id, receiver)
        end
      else
        local member = string.gsub(matches[2], '@', '')
        resolve_username(member, resolved_username, {get_cmd=get_cmd, receiver=receiver, chat_id=msg.to.id, member=member, is_chan=is_chan_msg(msg)})
      end
    else
      return str2emoji(':no_entry_sign:')..' This isn\'t a chat group'
    end
  end

--!whitelist command block
  if matches[1] == 'whitelist' then
    --Enable/Disable whitelist in chat
    if matches[2] == 'enable' and is_sudo(msg) then
      local hash = 'whitelist:enabled'
      redis:set(hash, true)
      return str2emoji(':information_source:')..' Enabled whitelist'
    end

    if matches[2] == 'disable' and is_sudo(msg) then
      local hash = 'whitelist:enabled'
      redis:del(hash)
      return str2emoji(':information_source:')..' Disabled whitelist'
    end
    --Add/Remove user/chat to whitelist
    if matches[2] == 'user' then
      if string.match(matches[3], '^%d+$') then
        local hash = 'whitelist:user#id'..matches[3]
        redis:set(hash, true)
        return 'User '..matches[3]..' whitelisted'
      else
        local member = string.gsub(matches[3], '@', '')
        resolve_username(member, resolved_username, {get_cmd=get_cmd, receiver=receiver, chat_id=msg.to.id, member=member, is_chan=is_chan_msg(msg)})
      end
    end

    if matches[2] == 'chat' then
      if not is_chat_msg(msg) then
        return str2emoji(':no_entry_sign:')..' This isn\'t a chat group'
      end
      local hash = 'whitelist:chat#id'..msg.to.id
      redis:set(hash, true)
      return str2emoji(':information_source:')..' Chat '..msg.to.print_name..' ['..msg.to.id..'] whitelisted'
    end

    if matches[2] == 'delete' and matches[3] == 'user' then
      if string.match(matches[4], '^%d+$') then
        local hash = 'whitelist:user#id'..matches[4]
        redis:del(hash)
        return str2emoji(':information_source:')..' User '..matches[4]..' removed from whitelist'
      else
        local member = string.gsub(matches[4], '@', '')
        resolve_username(member, resolved_username, {get_cmd=get_cmd, receiver=receiver, chat_id=msg.to.id, member=member, is_chan=is_chan_msg(msg)})
      end
    end

    if matches[2] == 'delete' and matches[3] == 'chat' then
      if not is_chat_msg(msg) then
        return str2emoji(':no_entry_sign:')..' This isn\'t a chat group'
      end
      local hash = 'whitelist:chat#id'..msg.to.id
      redis:del(hash)
      return str2emoji(':information_source:')..' Chat '..msg.to.print_name..' ['..msg.to.id..'] removed from whitelist'
    end

    --Enable/Disable modonly
    if matches[2] == 'modonly' and matches[3] == 'enable' and is_momod(msg) then
      local hash = 'whitelist:modonly:'..msg.to.id
      redis:set(hash, true)
      return str2emoji(':information_source:')..' Only moderators on chat '..string.gsub(msg.to.print_name, '_', ' ')..' ['..msg.to.id..'] can now issue commands.'
    end

    if matches[2] == 'modonly' and matches[3] == 'disable' and is_momod(msg) then
      local hash = 'whitelist:modonly:'..msg.to.id
      redis:del(hash)
      return str2emoji(':information_source:')..' Now everyone on chat '..string.gsub(msg.to.print_name, '_', ' ')..' ['..msg.to.id..'] can issue commands.'
    end

  end
end

return {
  description = 'Plugin to manage bans, kicks and white/black lists.',
  usage = {
    user = {
      '!kickme : Exit from group',
    },
    moderator = {
      '!whitelist <enable>/<disable> : Enable or disable whitelist mode',
      '!whitelist user <user_id> : Allow user to use the bot when whitelist mode is enabled',
      '!whitelist user <username> : Allow user to use the bot when whitelist mode is enabled',
      '!whitelist chat : Allow everybody on current chat to use the bot when whitelist mode is enabled',
      '!whitelist delete user <user_id> : Remove user from whitelist',
      '!whitelist delete chat : Remove chat from whitelist',
      '!whitelist modonly <enable>/<disable> : Enable or disable usage limit',
      '!ban user <user_id> : Kick user from chat and kicks it if joins chat again',
      '!ban user <username> : Kick user from chat and kicks it if joins chat again',
      '!ban delete <user_id> : Unban user',
      '!ban delete <username> : Unban user',
      '!superban <enable>/<disable> : Enable or disable global bans on the current group',
      '!kick <user_id> : Kick user from chat group by id',
      '!kick <username> : Kick user from chat group by username',
      '#ban (by reply) : Kick user from chat and kicks it if joins chat again',
      '#unban (by reply) : Unban user',
      '#kick (by reply) : Kick user from chat group'
    },
    admin = {
      '!superban user <user_id> : Kick user from all chat and kicks it if joins again',
      '!superban user <username> : Kick user from all chat and kicks it if joins again',
      '!superban delete <user_id> : Unban user',
      '!superban delete <username> : Unban user',
      '#superban (by reply) : Kick user from all chat and kicks it if joins again',
      '!blocklist user <user_id> : Kick user from all blocklist adhering chatrooms and kicks it if joins again',
      '!blocklist user <username> : Kick user from all blocklist adhering chatrooms and kicks it if joins again',
      '!blocklist delete <user_id> : Remove user from the blocklists',
      '!blocklist delete <username> : Remove user from the blocklists',
      '!blocklist enable/disable : Permit usage of the blocklists on the group',
      '#blocklist (by reply) : Kick user from all blocklist adhering chatrooms and kicks it if joins again'
    },
  },
  patterns = {
    '^!(whitelist) (enable)$',
    '^!(whitelist) (disable)$',
    '^!(whitelist) (modonly) (enable)$',
    '^!(whitelist) (modonly) (disable)$',
    '^!(whitelist) (user) (.*)$',
    '^!(whitelist) (chat)$',
    '^!(whitelist) (delete) (user) (.*)$',
    '^!(whitelist) (delete) (chat)$',
    '^#(ban)$',
    '^#(kick)$',
    '^#(superban)$',
    '^#(blocklist)$',
    '^#(unban)$',
    '^!(ban) (user) (.*)$',
    '^!(ban) (delete) (.*)$',
    '^!(superban) (enable)$',
    '^!(superban) (disable)$',
    '^!(superban) (user) (.*)$',
    '^!(superban) (delete) (.*)$',
    '^!(blocklist) (user) (.*)$',
    '^!(blocklist) (delete) (.*)$',
    '^!(blocklist) (enable)$',
    '^!(blocklist) (disable)$',
    '^!(kick) (.*)$',
    '^!(kickme)$',
    '^!!tgservice (.+)$',
  },
  run = run,
  pre_process = pre_process
}
