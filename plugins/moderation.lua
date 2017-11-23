do

  local function check_member(cb_extra, success, result)
    local receiver = cb_extra.receiver
    local data = cb_extra.data
    local msg = cb_extra.msg

    local members

    if not cb_extra.is_chan then
      members = result.members
    else
      members = result
    end

    for k,v in pairs(members) do
      local member_id = v.peer_id
      if member_id ~= our_id then
        local username = v.username
        data[tostring(msg.to.id)] = {
          moderators = {[tostring(member_id)] = username},
          settings = {
            set_name = string.gsub(msg.to.print_name, '_', ' '),
            lock_name = 'no',
            lock_photo = 'no',
            lock_member = 'no',
            lock_bots = 'no'
          }
        }
        save_data(_config.moderation.data, data)
        return send_large_msg(receiver, 'You have been promoted as moderator for this group.')
      end
    end
  end

  local function automodadd(msg)
    local data = load_data(_config.moderation.data)
    if msg.action.type == 'chat_created' then
      receiver = get_receiver(msg)
      chat_info(receiver, check_member,{receiver=receiver, data=data, msg = msg})
    else
      if data[tostring(msg.to.id)] then
        return 'Group is already added.'
      end
      if msg.from.username then
        username = msg.from.username
      else
        username = msg.from.print_name
      end
      -- create data array in moderation.json
      data[tostring(msg.to.id)] = {
        moderators ={[tostring(msg.from.id)] = username},
        settings = {
          set_name = string.gsub(msg.to.print_name, '_', ' '),
          lock_name = 'no',
          lock_photo = 'no',
          lock_member = 'no',
          lock_bots = 'no'
        }
      }
      save_data(_config.moderation.data, data)
      return 'Group has been added, and @'..username..' has been promoted as moderator for this group.'
    end
  end

  local function modadd(msg)
    -- superuser and admins only (because sudo are always has privilege)
    -- if not is_admin(msg) then
    -- return "You're not admin"
    -- end
    local data = load_data(_config.moderation.data)
    if data[tostring(msg.to.id)] then
      return 'Group is already added.'
    end
    -- create data array in moderation.json
    data[tostring(msg.to.id)] = {
      moderators ={},
      settings = {
        set_name = string.gsub(msg.to.print_name, '_', ' '),
        lock_name = 'no',
        lock_photo = 'no',
        lock_member = 'no',
        lock_bots = 'no'
      }
    }
    save_data(_config.moderation.data, data)

    return 'Group has been added.'
  end

  local function modrem(msg)
    -- superuser and admins only (because sudo are always has privilege)
    if not is_admin(msg) then
      return "You're not admin"
    end
    local data = load_data(_config.moderation.data)
    local receiver = get_receiver(msg)
    if not data[tostring(msg.to.id)] then
      return 'Group is not added.'
    end

    data[tostring(msg.to.id)] = nil
    save_data(_config.moderation.data, data)

    return 'Group has been removed'
  end

  local function promote(receiver, member_username, member_id)
    local data = load_data(_config.moderation.data)
    local group = string.gsub(receiver, 'chat#id', '')
    group = string.gsub(group, 'channel#id', '')
    if not data[group] then
      return send_large_msg(receiver, 'Group is not added.')
    end
    if data[group]['moderators'][tostring(member_id)] then
      return send_large_msg(receiver, member_username..' is already a moderator.')
    end
    data[group]['moderators'][tostring(member_id)] = member_username
    save_data(_config.moderation.data, data)
    return send_large_msg(receiver, '@'..member_username..' has been promoted.')
  end

  local function demote(receiver, member_username, member_id)
    local data = load_data(_config.moderation.data)
    local group = string.gsub(receiver, 'chat#id', '')
    group = string.gsub(group, 'channel#id', '')
    if not data[group] then
      return send_large_msg(receiver, 'Group is not added.')
    end
    if not data[group]['moderators'][tostring(member_id)] then
      return send_large_msg(receiver, member_username..' is not a moderator.')
    end
    data[group]['moderators'][tostring(member_id)] = nil
    save_data(_config.moderation.data, data)
    return send_large_msg(receiver, '@'..member_username..' has been demoted.')
  end

  local function promote_reply(extra, success, result)
    if result.from.username then
      promote(extra, result.from.username, result.from.peer_id)
    else
      promote(extra, result.from.first_name, result.from.peer_id)
    end
  end

  local function demote_reply(extra, success, result)
    if result.from.username then
      demote(extra, result.from.username, result.from.peer_id)
    else
      demote(extra, result.from.first_name, result.from.peer_id)
    end
  end

  local function admin_promote(receiver, member_username, member_id)
    local data = load_data(_config.moderation.data)
    if not data['admins'] then
      data['admins'] = {}
      save_data(_config.moderation.data, data)
    end

    if data['admins'][tostring(member_id)] then
      return send_large_msg(receiver, member_username..' is already as admin.')
    end

    data['admins'][tostring(member_id)] = member_username
    save_data(_config.moderation.data, data)
    return send_large_msg(receiver, '@'..member_username..' has been promoted as admin.')
  end

  local function admin_demote(receiver, member_username, member_id)
    local data = load_data(_config.moderation.data)
    if not data['admins'] then
      data['admins'] = {}
      save_data(_config.moderation.data, data)
    end

    if not data['admins'][tostring(member_id)] then
      return send_large_msg(receiver, member_username..' is not an admin.')
    end

    data['admins'][tostring(member_id)] = nil
    save_data(_config.moderation.data, data)

    return send_large_msg(receiver, 'Admin '..member_username..' has been demoted.')
  end

  local function blocklistadm_promote(receiver, member_username, member_id)
    local data = load_data(_config.moderation.data)
    if not data['blocklist'] then
      data['blocklist'] = {}
      save_data(_config.moderation.data, data)
    end

    if data['blocklist'][tostring(member_id)] then
      return send_large_msg(receiver, member_username..' is already a blocklist admin.')
    end

    data['blocklist'][tostring(member_id)] = member_username
    save_data(_config.moderation.data, data)
    return send_large_msg(receiver, '@'..member_username..' has been promoted as blocklist admin.')
  end

  local function blocklistadm_demote(receiver, member_username, member_id)
    local data = load_data(_config.moderation.data)
    if not data['blocklist'] then
      data['blocklist'] = {}
      save_data(_config.moderation.data, data)
    end

    if not data['blocklist'][tostring(member_id)] then
      return send_large_msg(receiver, member_username..' is not a blacklist admin.')
    end

    data['blocklist'][tostring(member_id)] = nil
    save_data(_config.moderation.data, data)

    return send_large_msg(receiver, 'Blocklist admin '..member_username..' has been demoted.')
  end

  local function syncmods(cb_extra, success, result)
    local receiver = cb_extra

    local data = load_data(_config.moderation.data)
    local group = string.gsub(receiver, 'chat#id', '')
    group = string.gsub(group, 'channel#id', '')
    if not data[group] then
      return send_large_msg(receiver, 'Group is not added.')
    end
    data[group]['moderators'] = {}

    for _,cur_user in pairs(result) do
      if cur_user.peer_id ~= our_id then
        data[group]['moderators'][tostring(cur_user.peer_id)] = cur_user.username
      end
    end
    save_data(_config.moderation.data, data)

    send_large_msg(receiver, "Moderators synced successfully.")
  end

  local function resolved_username(cb_extra, success, result)
    local mod_cmd = cb_extra.mod_cmd
    local receiver = cb_extra.receiver
    local member = cb_extra.member
    local text = 'User @'..member..' does not exist.'

    local members
    if not cb_extra.is_chan then
      members = result.members
    else
      members = result
    end

    if success then
      member_username = result.username
      member_id = result.peer_id
      if mod_cmd == 'promote' then
        return promote(receiver, member_username, member_id)
      elseif mod_cmd == 'demote' then
        return demote(receiver, member_username, member_id)
      elseif mod_cmd == 'adminprom' then
        return admin_promote(receiver, member_username, member_id)
      elseif mod_cmd == 'admindem' then
        return admin_demote(receiver, member_username, member_id)
      elseif mod_cmd == 'blocklistprom' then
        return blocklistadm_promote(receiver, member_username, member_id)
      elseif mod_cmd == 'blocklistdem' then
        return blocklistadm_demote(receiver, member_username, member_id)
      end
    end
    send_large_msg(receiver, text)
  end

  local function username_id(cb_extra, success, result)
    local mod_cmd = cb_extra.mod_cmd
    local receiver = cb_extra.receiver
    local member = cb_extra.member
    local text = 'No user @'..member..' in this group.'

    local members
    if not cb_extra.is_chan then
      members = result.members
    else
      members = result
    end

    for k,v in pairs(members) do
      vusername = v.username
      if vusername == member then
        member_username = member
        member_id = v.peer_id
        if mod_cmd == 'promote' then
          return promote(receiver, member_username, member_id)
        elseif mod_cmd == 'demote' then
          return demote(receiver, member_username, member_id)
        elseif mod_cmd == 'adminprom' then
          return admin_promote(receiver, member_username, member_id)
        elseif mod_cmd == 'admindem' then
          return admin_demote(receiver, member_username, member_id)
        elseif mod_cmd == 'blocklistprom' then
          return blocklistadm_promote(receiver, member_username, member_id)
        elseif mod_cmd == 'blocklistdem' then
          return blocklistadm_demote(receiver, member_username, member_id)
        end
      end
    end
    send_large_msg(receiver, text)
  end

  local function modlist(msg)
    local data = load_data(_config.moderation.data)
    if not data[tostring(msg.to.id)] then
      return 'Group is not added.'
    end
    -- determine if table is empty
    if next(data[tostring(msg.to.id)]['moderators']) == nil then --fix way
      return 'No moderator in this group.'
    end
    local message = 'List of moderators for ' .. string.gsub(msg.to.print_name, '_', ' ') .. ':\n'
    for k,v in pairs(data[tostring(msg.to.id)]['moderators']) do
      message = message .. '- '..v..' [' ..k.. '] \n'
    end

    return message
  end

  local function admin_list(msg)
    local data = load_data(_config.moderation.data)
    if not data['admins'] then
      data['admins'] = {}
      save_data(_config.moderation.data, data)
    end
    if next(data['admins']) == nil then --fix way
      return 'No admin available.'
    end
    local message = 'List for Bot admins:\n'
    for k,v in pairs(data['admins']) do
      message = message .. '- ' .. v ..' ['..k..'] \n'
    end
    return message
  end

  local function blocklistadm_list(msg)
    local data = load_data(_config.moderation.data)
    if not data['blocklist'] then
      data['blocklist'] = {}
      save_data(_config.moderation.data, data)
    end
    if next(data['blocklist']) == nil then --fix way
      return 'No blocklist admin available.'
    end
    local message = 'List for blocklist admins:\n'
    for k,v in pairs(data['blocklist']) do
      message = message .. '- ' .. v ..' ['..k..'] \n'
    end
    return message
  end

  function run(msg, matches)
    if matches[1] == 'debug' then
      return debugs(msg)
    end
    if not is_chat_msg(msg) then
      return "Only works on group"
    end
    local mod_cmd = matches[1]
    local receiver = get_receiver(msg)
    if matches[1] == 'modadd' then
      return modadd(msg)
    end
    if matches[1] == 'modrem' then
      return modrem(msg)
    end
    if matches[1] == 'modsync' then
      if is_chan_msg(msg) then
        local data = load_data(_config.moderation.data)
        local receiver = get_receiver(msg)

        if not data[tostring(msg.to.id)] then
          modadd(msg)
        end

        return channel_get_admins(receiver, syncmods, receiver)
      else
        return "Works only on supergroups!"
      end
    end
    if matches[1] == 'promote' then -- and matches[2] then
      if not is_momod(msg) then
        return "Only moderator can promote"
      end
      if msg.reply_id then
        get_message(msg.reply_id, promote_reply, get_receiver(msg))
        return nil
      end

      if matches[2] then
        local member = string.gsub(matches[2], "@", "")
        resolve_username(member, resolved_username, {mod_cmd=mod_cmd, receiver=receiver, member=member, is_chan=is_chan_msg(msg)})
        --if not is_chan_msg(msg) then
        -- chat_info(receiver, username_id, {mod_cmd= mod_cmd, receiver=receiver, member=member, is_chan_msg(msg)})
        --else
        -- channel_get_users(receiver, username_id, {mod_cmd= mod_cmd, receiver=receiver, member=member, is_chan=is_chan_msg(msg)})
        --end
      end
    end
    if matches[1] == 'demote' then -- and matches[2] then
      if not is_momod(msg) then
        return "Only moderator can demote"
      end
      if msg.reply_id then
        get_message(msg.reply_id, demote_reply, get_receiver(msg))
        return nil
      end

      if matches[2] then
        if string.gsub(matches[2], "@", "") == msg.from.username then
          return "You can't demote yourself"
        end
        local member = string.gsub(matches[2], "@", "")
        resolve_username(member, resolved_username, {mod_cmd=mod_cmd, receiver=receiver, member=member, is_chan=is_chan_msg(msg)})
        -- if not is_chan_msg(msg) then
        -- chat_info(receiver, username_id, {mod_cmd= mod_cmd, receiver=receiver, member=member, is_chan_msg(msg)})
        --else
        -- channel_get_users(receiver, username_id, {mod_cmd= mod_cmd, receiver=receiver, member=member, is_chan=is_chan_msg(msg)})
        --end
      end
    end
    if matches[1] == 'modlist' then
      return modlist(msg)
    end
    if matches[1] == 'adminprom' then
      if not is_sudo(msg) then
        return "Only sudo can promote user as admin"
      end
      local member = string.gsub(matches[2], "@", "")
      resolve_username(member, resolved_username, {mod_cmd=mod_cmd, receiver=receiver, member=member, is_chan=is_chan_msg(msg)})
      --if not is_chan_msg(msg) then
      -- chat_info(receiver, username_id, {mod_cmd= mod_cmd, receiver=receiver, member=member, is_chan_msg(msg)})
      --else
      -- channel_get_users(receiver, username_id, {mod_cmd= mod_cmd, receiver=receiver, member=member, is_chan=is_chan_msg(msg)})
      --end
    end
    if matches[1] == 'admindem' then
      if not is_sudo(msg) then
        return "Only sudo can promote user as admin"
      end
      local member = string.gsub(matches[2], "@", "")
      resolve_username(member, resolved_username, {mod_cmd=mod_cmd, receiver=receiver, member=member, is_chan=is_chan_msg(msg)})
      --if not is_chan_msg(msg) then
      -- chat_info(receiver, username_id, {mod_cmd= mod_cmd, receiver=receiver, member=member, is_chan_msg(msg)})
      --else
      -- channel_get_users(receiver, username_id, {mod_cmd= mod_cmd, receiver=receiver, member=member, is_chan=is_chan_msg(msg)})
      --end
    end
    if matches[1] == 'blocklistprom' then
      if not is_sudo(msg) then
        return "Only sudo can promote user as admin"
      end
      local member = string.gsub(matches[2], "@", "")
      resolve_username(member, resolved_username, {mod_cmd=mod_cmd, receiver=receiver, member=member, is_chan=is_chan_msg(msg)})
      --if not is_chan_msg(msg) then
      -- chat_info(receiver, username_id, {mod_cmd= mod_cmd, receiver=receiver, member=member, is_chan_msg(msg)})
      --else
      -- channel_get_users(receiver, username_id, {mod_cmd= mod_cmd, receiver=receiver, member=member, is_chan=is_chan_msg(msg)})
      --end
    end
    if matches[1] == 'blocklistdem' then
      if not is_sudo(msg) then
        return "Only sudo can promote user as admin"
      end
      local member = string.gsub(matches[2], "@", "")
      resolve_username(member, resolved_username, {mod_cmd=mod_cmd, receiver=receiver, member=member, is_chan=is_chan_msg(msg)})
      --if not is_chan_msg(msg) then
      -- chat_info(receiver, username_id, {mod_cmd= mod_cmd, receiver=receiver, member=member, is_chan_msg(msg)})
      --else
      -- channel_get_users(receiver, username_id, {mod_cmd= mod_cmd, receiver=receiver, member=member, is_chan=is_chan_msg(msg)})
      --end
    end
    if matches[1] == 'adminlist' then
      if not is_admin(msg) then
        return 'Admin only!'
      end
      return admin_list(msg)
    end
    if matches[1] == 'blockadmlist' then
      if not is_admin(msg) then
        return 'Admin only!'
      end
      return blocklistadm_list(msg)
    end
    if matches[1] == 'chat_add_user' then
      for _, user in ipairs(msg.action.users) do
        if user.id == our_id then
          return automodadd(msg)
        end
      end
    end
    if matches[1] == 'chat_created' and msg.from.id == 0 then
      return automodadd(msg)
    end
  end

  return {
    description = "Moderation plugin",
    usage = {
      moderator = {
        "!promote <username> : Promote user as moderator",
        "!demote <username> : Demote user from moderator",
        "#promote (by reply) : Promote user as moderator",
        "#demote (by reply) : Demote user from moderator",
        "!modlist : List of moderators",
        "!modsync : Sync moderators with supergroup admins",
      },
      admin = {
        "!modadd : Add group to moderation list",
        "!modrem : Remove group from moderation list",
      },
      sudo = {
        "!adminprom <username> : Promote user as admin (must be done from a group)",
        "!admindem <username> : Demote user from admin (must be done from a group)",
        "!blocklistprom <username> : Promote user as blocklist admin (must be done from a group)",
        "!blocklistdem <username> : Demote user from blocklist admin (must be done from a group)",
      },
    },
    patterns = {
      "^!(modadd)$",
      "^!(modrem)$",
      "^#(promote)$",
      "^#(demote)$",
      "^!(promote) (.*)$",
      "^!(demote) (.*)$",
      "^!(modlist)$",
      "^!(modsync)$",
      "^!(adminprom) (.*)$", -- sudoers only
      "^!(admindem) (.*)$", -- sudoers only
      "^!(blocklistprom) (.*)$", -- sudoers only
      "^!(blocklistdem) (.*)$", -- sudoers only
      "^!(adminlist)$",
      "^!(blockadmlist)$",
      "^!!tgservice (chat_add_user)$",
      "^!!tgservice (chat_created)$",
    },
    run = run,
  }

end
