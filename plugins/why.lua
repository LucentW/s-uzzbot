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

  local function why_real(user, receiver)
    local chat_id = string.gsub(receiver, "chat#id", "")
    chat_id = string.gsub(receiver, "channel#id", "")
    local banned = is_banned(user.peer_id, chat_id)
    local superbanned = is_super_banned(user.peer_id)

    local text = str2emoji(':information_source:').." User "
    if user.username ~= nil then
      text = text.."@"..user.username
    else
      text = text..user.print_name
    end

    text = text.." ["..user.peer_id.."]\n"
    if banned then
      text = text..str2emoji(":exclamation:").." Is currently banned from this group.\n"
      if superbanned then
        text = text..str2emoji(":no_entry_sign:").." This ID is also superbanned.\n\n"
        text = text..str2emoji(":point_right:").." You can let this user in by disabling the superban list with the !superban disable command"
        text = text.."and then by unbanning with !ban delete "..user.peer_id
      else
        text = text.."\n"..str2emoji(":point_right:").." You can unban the user with !ban delete "..user.peer_id
      end
    else
      if superbanned then
        text = text..str2emoji(":no_entry_sign:").." This ID is currently superbanned.\n\n"
        text = text..str2emoji(":point_right:").." You can let this user in by disabling the superban list with the !superban disable command."
      else
        text = text..str2emoji(":thumbsup:").." This ID is nor banned nor superbanned.\n"
      end
    end
    send_large_msg(receiver, text)

  end

  local function why_id(peer_id, chat_id)
    local banned = is_banned(peer_id, chat_id)
    local superbanned = is_super_banned(peer_id)

    local text = str2emoji(':information_source:').." User with ID "..peer_id.."\n"

    if banned then
      text = text..str2emoji(":exclamation:").." Is currently banned from this group.\n"
      if superbanned then
        text = text..str2emoji(":no_entry_sign:").." This ID is also superbanned.\n\n"
        text = text..str2emoji(":point_right:").." You can let this user in by disabling the superban list with the !superban disable command"
        text = text.."and then by unbanning with !ban delete "..peer_id
      else
        text = text.."\n"..str2emoji(":point_right:").." You can unban the user with !ban delete "..peer_id
      end
    else
      if superbanned then
        text = text..str2emoji(":no_entry_sign:").." Is currently superbanned.\n\n"
        text = text..str2emoji(":point_right:").." You can let this user in by disabling the superban list with the !superban disable command."
      else
        text = text..str2emoji(":thumbsup:").." This ID is nor banned nor superbanned.\n"
      end
    end

    return text

  end

  local function why(cb_extra, success, result)
    if result.from ~= nil then
      why_real(result.from, cb_extra.receiver)
    else
      why_real(result, cb_extra.receiver)
    end
  end

  local function run(msg, matches)
    local receiver = get_receiver(msg)
    if msg.reply_id then
      get_message(msg.reply_id, why, {receiver=receiver})
      return nil
    end
    if matches[1] == '#why' then
      return str2emoji(":point_right:").." You must reply to a message to get informations about that."
    end
    if matches[1]:match("^%d+$") then
      return why_id(matches[1], msg.to.id)
    else
      return resolve_username(matches[1]:gsub("@", ""), why, {receiver=receiver})
    end
  end

  return {
    description = "Get informations about a username/ID",
    usage = {
      "!why <username>/<user_id> : Returns informations about that user",
      "#why (by reply) : Returns informations about that user",
    },
    patterns = {
      "^!why (%d+)$",
      "^!why (@?%a%S+)$",
      "^#why$"
    },
    run = run
  }

