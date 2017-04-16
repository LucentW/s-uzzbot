local function run(msg, matches)
  if matches[1] == 'migrated_to' and msg.from.id ~= 0 then
    if not msg.service then
      return "Are you trying to troll me?"
    end
    local data = load_data(_config.moderation.data, true)
    data[tostring(msg.action.channel_id)] = data[tostring(msg.to.id)]
    save_data(_config.moderation.data, data, true)
    return send_large_msg('channel#id'..msg.action.channel_id, "Moderation data migrated successfully.")
  end
  if msg.to.type == 'chat' and is_momod then
    return chat_upgrade('chat#id'..msg.to.id, ok_cb, false)
  end
end

return {
  description = 'Upgrades group to supergroup (only if bot is group founder).',
  usage = {
    moderator = {
      "!tosuper : Upgrade group to supergroup",
    },
  },
  patterns = {
    "^!tosuper$",
    "^!!tgservice (.+)$"
  },
  run = run
}
