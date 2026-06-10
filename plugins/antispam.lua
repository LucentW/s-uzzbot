local SPAM_PATTERNS = {
  "[Tt][Ee][Ll][Ee][Gg][Rr][Aa][Mm]%.[Mm][Ee]/%S+",
  "[Tt][Ll][Gg][Rr][Mm]%.[Mm][Ee]/%S+",
  "[Aa][Dd][Ff]%.[Ll][Yy]/%S+",
  "[Ss][Hh]%.[Ss][Tt]/%S+",
  "[Tt]%.[Mm][Ee]/%S+",
  "[Tt][Ee][Ll][Ee][Gg][Rr][Aa][Mm]%.[Dd][Oo][Gg]/%S+",
  "[Cc][Hh][Aa][Tt]%.[Ww][Hh][Aa][Tt][Ss][Aa][Pp][Pp]%.[Cc][Oo][Mm]/%S+"
}

local function is_spam(text)
  if text == nil then return false end
  for _, v in ipairs(SPAM_PATTERNS) do
    if text:match(v) ~= nil then return true end
  end
  return false
end

local function get_linked_chat_id(msg)
  if msg.to and msg.to.linked_chat then
    return msg.to.linked_chat.peer_id
  end
  return nil
end

local function is_chan_fwd(msg)
  if msg.fwd_from == nil or msg.fwd_from.peer_type ~= "channel" then
    return false
  end
  local linked = get_linked_chat_id(msg)
  if linked and msg.fwd_from.peer_id == linked then
    return false  -- forward from the group's own linked channel is OK
  end
  return true
end

local function is_chan_quote(msg)
  if msg.reply_to_peer == nil or msg.reply_to_peer.peer_type ~= "channel" then
    return false
  end
  local linked = get_linked_chat_id(msg)
  if linked and msg.reply_to_peer.peer_id == linked then
    return false  -- quote from the linked channel is OK
  end
  return true
end

local function has_spam_buttons(msg)
  if msg.reply_markup == nil then return false end
  for _, row in ipairs(msg.reply_markup) do
    for _, btn in ipairs(row) do
      if btn.type == "url" and is_spam(btn.url) then
        return true
      end
    end
  end
  return false
end

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

    local function addexcept_reply(extra, success, result)
      local hash = 'anti-spam:exception:'..result.to.peer_id..':'..result.from.peer_id
      redis:set(hash, true)
      send_large_msg(extra, str2emoji(':information_source:')..' User ID '..result.from.peer_id..' is now exempt from antispam checks.')
    end

    local function delexcept_reply(extra, success, result)
      local hash = 'anti-spam:exception:'..result.to.peer_id..':'..result.from.peer_id
      local reply
      if redis:get(hash) then
        redis:del(hash)
        reply = str2emoji(':information_source:')..' User ID '..result.from.peer_id..' is now subject to antispam checks.'
      else
        reply = str2emoji(':information_source:')..' User ID '..result.from.peer_id..' is not exempt from antispam checks.'
      end
      send_large_msg(extra, reply)
    end

    local function run (msg, matches)
      if matches[1] ~= nil then
        if not is_chat_msg(msg) then
          return str2emoji(":exclamation:")..' Anti-spam works only on groups'
        else
          if is_momod(msg) then
            local chat = msg.to.id
            local hash = 'anti-spam:enabled:'..chat
            if matches[1] == 'addspamexcept' then
              if msg.reply_id then
                get_message(msg.reply_id, addexcept_reply, get_receiver(msg))
                return nil
              end
            end
            if matches[1] == 'delspamexcept' then
              if msg.reply_id then
                get_message(msg.reply_id, delexcept_reply, get_receiver(msg))
                return nil
              end
            end
            if matches[1] == 'enable' then
              if matches[2] == 'fwd' then
                redis:set(hash..':fwd', true)
                return str2emoji(':information_source:')..' Kick on forward enabled on chat'
              end
              redis:set(hash, true)
              return str2emoji(':information_source:')..' Anti-spam enabled on chat'
            end
            if matches[1] == 'disable' then
              if matches[2] == 'fwd' then
                redis:del(hash..':fwd')
                return str2emoji(':information_source:')..' Kick on forward disabled on chat'
              end
              redis:del(hash)
              return str2emoji(':information_source:')..' Anti-spam disabled on chat'
            end
            if matches[2] then
              hash = 'anti-spam:exception:'..chat..':'..matches[2]
              if matches[1] == 'addexcept' then
                redis:set(hash, true)
                return str2emoji(':information_source:')..' User ID '..matches[2]..' is now exempt from antispam checks.'
              end
              if matches[1] == 'delexcept' then
                if redis:get(hash) then
                  redis:del(hash)
                  return str2emoji(':information_source:')..' User ID '..matches[2]..' is now subject to antispam checks.'
                else
                  return str2emoji(':information_source:')..' User ID '..matches[2]..' is not exempt from antispam checks.'
                end
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

      local hash_enable = 'anti-spam:enabled:'..msg.to.id
      local enabled = redis:get(hash_enable)

      if enabled then
        print('Anti-spam enabled')
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

        local spam_reason = nil
        if is_spam(real_text)       then spam_reason = 'spam text' end
        if has_spam_buttons(msg)    then spam_reason = (spam_reason and spam_reason..'+' or '') .. 'spam button url' end

        local hash_enable_fwd = hash_enable..':fwd'
        local enabled_fwd = redis:get(hash_enable_fwd)
        if enabled_fwd then
          if is_chan_fwd(msg)   then spam_reason = (spam_reason and spam_reason..'+' or '') .. 'channel fwd' end
          if is_chan_quote(msg) then spam_reason = (spam_reason and spam_reason..'+' or '') .. 'channel quote' end
        end

        if msg.from.type == 'user' and spam_reason ~= nil then
          local receiver = get_receiver(msg)
          local user = msg.from.id
          local display = msg.from.username ~= nil
            and ('@'..msg.from.username..' ['..user..']')
            or (string.gsub(msg.from.print_name, '_', ' ')..' ['..user..']')
          local text = str2emoji(":exclamation:")..' User '..display..' is spamming ('..spam_reason..')'
          local chat = msg.to.id
          local hash_exception = 'anti-spam:exception:'..msg.to.id..':'..msg.from.id

          if not is_chat_msg(msg) then
            print("Spam not in a chat group!")
          elseif user == tostring(our_id) then
            print('I won\'t kick myself')
          elseif is_momod(msg) then
            print('I won\'t kick a mod/admin/sudo!')
          elseif redis:get(hash_exception) then
            print('User is exempt from antispam checks!')
          else
            send_msg(receiver, text, ok_cb, nil)
            snoop_msg('User '..display..' has been found spamming ('..spam_reason..').\nGroup: '..msg.to.print_name..' ['..msg.to.id..']\nText: '..real_text)
            if not is_chan_msg(msg) then
              kick_user(user, chat)
            else
              delete_msg(msg.id, ok_cb, nil)
              kick_chan_user(user, chat)
            end
            return nil
          end
        end
      end

      return msg
    end

    return {
      description = 'Plugin to kick spammers from group.',
      usage = {
        moderator = {
          "!antispam <enable>/<disable> : Enable or disable spam checking",
          "!antispam <enable>/<disable> fwd : Enable or disable kicking who forwards from channels",
          "!antispam <addexcept>/<delexcept> <user_id> : Add user to antispam exceptions",
          "#addspamexcept (by reply) : Add user to antispam exceptions",
          "#delspamexcept (by reply) : Delete user from antispam exceptions"
        },
      },
      patterns = {
        '^!antispam (enable) (fwd)$',
        '^!antispam (enable)$',
        '^!antispam (disable) (fwd)$',
        '^!antispam (disable)$',
        '^!antispam (addexcept) (%d+)$',
        '^!antispam (delexcept) (%d+)$',
        '^#(addspamexcept)$',
        '^#(delspamexcept)$'
      },
      run = run,
      pre_process = pre_process
    }