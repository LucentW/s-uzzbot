do

  local function parsed_url(link)
    local parsed_link = URL.parse(link)
    local parsed_path = URL.parse_path(parsed_link.path)
    return parsed_path[2]
  end

  function run(msg, matches)
    if is_admin(msg) then
      local hash = parsed_url(matches[1])
      join = import_chat_link(hash,ok_cb,false)
      return "Joined (probably?)"
    else
      return "You are not an admin"
    end
  end

  return {
    description = "Invite bot into a group chat",
    usage = "!join [invite link]",
    patterns = {
      "^!join (.*)$"
    },
    run = run
  }

end
