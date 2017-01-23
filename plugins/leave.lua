local function run(msg, matches)
  if is_admin(msg) then
    if matches[1] == msg.text or not matches[2] then
      if is_chat_msg(msg) then
        if not is_chan_msg(msg) then
          chat_del_user(get_receiver(msg), "user#id"..our_id, ok_cb, nil)
          snoop_msg("Leaving chat " .. msg.to.id)
          return nil
        else
          leave_channel(get_receiver(msg), ok_cb, nil)
          snoop_msg("Leaving channel " .. msg.to.id)
          return nil
        end
      end
    end
    if matches[1] == "channel" then
      leave_channel("channel#id"..matches[2], ok_cb, nil)
      snoop_msg("Leaving channel " .. matches[2])
      return nil
    end
    if matches[1] == "chat" then
      chat_del_user("chat#id"..matches[2], "user#id"..our_id, ok_cb, nil)
      snoop_msg("Leaving chat " .. matches[2])
      return nil
    end
  end
end
return {
  patterns = {
    "^!leave$",
    "^!leave (channel) (%d+)$",
    "^!leave (chat) (%d+)$"
  },
  usage = {
    admin = {
      "!leave : bot will leave current chat/channel",
      "!leave channel <id> : bot will leave the channel with id <id> (supergroup or broadcast channel)",
      "!leave chat <id> : bot will leave the chat with id <id> (normal group)"      
      }
    },
  run = run
  }