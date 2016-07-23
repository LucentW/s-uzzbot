local function user_print_name(user)
  if user.print_name then
    return user.print_name
  end
  local text = ''
  if user.first_name then
    text = user.last_name..' '
  end
  if user.lastname then
    text = text..user.last_name
  end
  return text
end

local function returnids(cb_extra, success, result)
  local receiver = cb_extra.receiver
  local chat_id = result.peer_id
  local chatname = result.print_name

  local text = str2emoji(":busts_in_silhouette:")..' IDs for chat '..chatname
  ..' ('..chat_id..')\n'
  ..'There are '..result.members_num..' members'
  ..'\n---------\n'
  i = 0
  for k,v in pairs(result.members) do
    i = i+1
    text = text .. i .. ". " .. string.gsub(v.print_name, "_", " ") .. " (" .. v.peer_id .. ")\n"
  end
  send_large_msg(receiver, text)
end

local function returnidschan(cb_extra, success, result)
  local receiver = cb_extra.receiver
  local chat_id = cb_extra.peer_id
  local chatname = cb_extra.print_name

  local text = str2emoji(":busts_in_silhouette:")..' IDs for chat '..chatname
  ..' ('..string.gsub(chat_id, "channel#id", "")..')\n'
  ..'\n---------\n'
  i = 0
  for k,v in pairs(result) do
    i = i+1
    if v.print_name ~= nil then
      text = text .. i .. ". " .. string.gsub(v.print_name, "_", " ") .. " (" .. v.peer_id .. ")\n"
    else
      text = text .. i .. ". " .. "?" .. " (" .. v.peer_id .. ")\n"
    end
  end
  send_large_msg(receiver, text)
end

local function username_id(cb_extra, success, result)
  local receiver = cb_extra.receiver
  local qusername = cb_extra.qusername
  local is_chan = cb_extra.is_chan
  local text = str2emoji(":no_entry_sign:")..' User @'..qusername..' does not exist!'

  if success then
    if result.peer_type == 'channel' then
      text = str2emoji(":id:")..' ID for group/channel\n'..str2emoji(":busts_in_silhouette:")..' @'..qusername..' : '..result.peer_id
    else
      text = str2emoji(":id:")..' ID for user\n'..str2emoji(":bust_in_silhouette:")..' @'..qusername..' : '..result.peer_id
    end
  end
  send_large_msg(receiver, text)
end

local function id_by_reply(cb_extra, success, result)
  local username
  if result.from.username then
    username = '@'..result.from.username
  else
    username = result.from.print_name
  end
  send_large_msg(cb_extra, str2emoji(":id:")..' ID for user\n'..str2emoji(":bust_in_silhouette:")..' '..username..' : '..result.from.peer_id)
end

local function run(msg, matches)
  local receiver = get_receiver(msg)
  if matches[1] == "!id" then
    local text = str2emoji(":bust_in_silhouette:")..' Name: '.. string.gsub(user_print_name(msg.from),'_', ' ')
    text = text..'\n'..str2emoji(":id:")..' ID: ' .. msg.from.id
    if is_chat_msg(msg) then
      text = text .. "\n"..str2emoji(":busts_in_silhouette:").." You are in group " .. string.gsub(user_print_name(msg.to), '_', ' ')
      text = text .. " (ID: " .. msg.to.id .. ")"
    end
    return text
  elseif matches[1] == "#id" then
    if msg.reply_id then
      get_message(msg.reply_id, id_by_reply, get_receiver(msg))
      return nil
    end
    return nil
  elseif matches[1] == "chat" then
    -- !ids? (chat) (%d+)
    if matches[2] then
      local group = string.gsub(matches[2], 'chat#id', '')
      group = string.gsub(group, 'channel#id', '')
      if is_mod(msg.from.id, group) then
        local chat = matches[2]

        if string.starts(chat, "chat#id") then
          return chat_info(chat, returnids, {receiver=receiver})
        end
        if string.starts(chat, "channel#id") then
          return channel_get_users(chat, returnidschan, {peer_id=matches[2], print_name="", receiver=receiver})
        end
        return str2emoji(":no_entry_sign:").." Invalid ID."
      else
        return str2emoji(":no_entry_sign:").." You cannot lookup the IDs from that group."
      end
    else
      if not is_chat_msg(msg) then
        return str2emoji(":no_entry_sign:").." You are not in a group."
      end

      local chat = get_receiver(msg)
      if not is_chan_msg(msg) then
        chat_info(chat, returnids, {receiver=receiver})
      else
        channel_get_users(chat, returnidschan, {peer_id=msg.to.id, print_name=string.gsub(user_print_name(msg.to), '_', ' '), receiver=receiver})
      end
    end
  else
    local qusername = string.gsub(matches[1], "@", "")
    local chat = get_receiver(msg)
    resolve_username(qusername, username_id, {receiver=receiver, qusername=qusername, is_chan=is_chan_msg(msg)})
  end
end

return {
  description = "Know your id or the id of a chat members.",
  usage = {
    "!id: Return your ID and the chat id if you are in one.",
    "!ids chat: Return the IDs of the current chat members.",
    "!ids chat chat#id<chat_id>: Return the IDs of the <chat_id> members.",
    "!ids chat channel#id<channel_id>: Return the IDs of the <channel_id> (supergroup) members.",
    "!id <username> : Return the id from username given."
  },
  patterns = {
    "^!id$",
    "^#id$",
    "^!ids? (chat) (.*)$",
    "^!ids? (chat)$",
    "^!id (.*)$"
  },
  run = run
}
