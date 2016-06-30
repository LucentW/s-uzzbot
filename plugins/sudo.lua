function run_sh(msg)
  name = get_name(msg)
  text = ''
  -- if config.sh_enabled == false then
  -- text = '!sh command is disabled'
  -- else
  -- if is_sudo(msg) then
  -- bash = msg.text:sub(4,-1)
  -- text = run_bash(bash)
  -- else
  -- text = name .. ' you have no power here!'
  -- end
  -- end
  if is_sudo(msg) then
    bash = msg.text:sub(4,-1)
    text = run_bash(bash)
  else
    text = name .. ' you have no power here!'
  end
  return text
end

function run_bash(str)
  local cmd = io.popen(str)
  local result = cmd:read('*all')
  cmd:close()
  return result
end

function on_getting_dialogs(cb_extra,success,result)
  local response = ""
  local count_groups = 0
  local count_supergroups = 0
  local count_users = 0
  if success then
    local dialogs={}
    for i, v in pairs(result) do
      if v.peer.peer_type == "channel" then
        response = response..'\n'..str2emoji(":busts_in_silhouette:")..' '..string.gsub(v.peer.print_name, '_', ' ')..': '..v.peer.peer_id
        count_supergroups = count_supergroups + 1
      end
      if v.peer.peer_type == "chat" then
        response = response..'\n'..str2emoji(":biohazard:")..' '..string.gsub(v.peer.print_name, '_', ' ')..': '..v.peer.peer_id
        count_groups = count_groups + 1
      end
      if v.peer.peer_type == "user" then
        response = response..'\n'..str2emoji(":bust_in_silhouette:")..' '..string.gsub(v.peer.print_name, '_', ' ')..': '..v.peer.peer_id
        count_users = count_users + 1
      end
    end
    send_large_msg(cb_extra, response)

    response = "Stats for this session:\n"..str2emoji(":busts_in_silhouette:").." supergroups: "..count_supergroups
    response = response.."\n"..str2emoji(":biohazard:").." groups: "..count_groups
    response = response.."\n"..str2emoji(":bust_in_silhouette:").." users: "..count_users
    response = response.."\n\n"..str2emoji(":heavy_plus_sign:").." total: "..count_supergroups+count_groups+count_users

    send_large_msg(cb_extra, response)
  end
end

function run(msg, matches)
  if not is_sudo(msg) then
    return "You aren't allowed!"
  end
  local receiver = get_receiver(msg)
  if string.match(msg.text, '!sh') then
    text = run_sh(msg)
    send_msg(receiver, text, ok_cb, false)
    return
  end

  if string.match(msg.text, '!cpu') then
    text = run_bash('uname -snr') .. ' ' .. run_bash('whoami')
    text = text .. '\n' .. run_bash('top -b |head -2')
    send_msg(receiver, text, ok_cb, false)
    return
  end

  if matches[1]=="Get dialogs" then
    get_dialog_list(on_getting_dialogs, get_receiver(msg))
    return
  end
end

return {
  description = "shows cpuinfo",
  usage = "!cpu",
  hide = true,
  patterns = {"^!cpu", "^!sh","^Get dialogs$"},
  run = run
}
