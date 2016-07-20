-- Invite other user to the chat group.
-- Use !invite name User_name or !invite id id_number
-- The User_name is the print_name (there are no spaces but _)

do

  function invite_resolve(extra, success, result)
    local text
    if not extra.is_chan then
      chat_add_user(extra.receiver, 'user#id'..result.peer_id, ok_cb, false)
    else
      channel_invite(extra.receiver, 'user#id'..result.peer_id, ok_cb, false)
    end
    send_large_msg(extra.receiver, "Add: "..result.peer_id.." to "..extra.receiver)
  end

  local function run(msg, matches)
    if is_sudo(msg) then
      local user = matches[2]

      -- User submitted a user name
      if matches[1] == "name" then
        if is_chat_msg(msg) then
          return resolve_username(string.gsub(user, "@", ""), invite_resolve, {receiver=get_receiver(msg), is_chan=is_chan_msg(msg)})
        else
          return 'This isn\'t a chat group!'
        end
      end

      -- User submitted an id
      if matches[1] == "id" then
        user = 'user#id'..user
        local chat
        if is_chat_msg(msg) then
          if not is_chan_msg(msg) then
            chat = 'chat#id'..msg.to.id
            chat_add_user(chat, user, ok_cb, false)
          else
            chat = 'channel#id'..msg.to.id
            channel_invite_user(chat, user, ok_cb, false)
          end
          return "Add: "..user.." to "..chat
        else
          return 'This isn\'t a chat group!'
        end
      end
    else
      return 'This command is limited to sudo only.'
    end
  end

  return {
    description = "Invite other user to the chat group",
    usage = {
      "!invite name [user_name]",
      "!invite id [user_id]" },
    patterns = {
      "^!invite (name) (.*)$",
      "^!invite (id) (%d+)$"
    },
    run = run,
    hide = true,
    moderation = true
  }

end
