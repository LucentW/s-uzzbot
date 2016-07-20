local function run(msg, matches)
  if is_momod(msg) then
    if msg.reply_id then
      delete_msg(msg.reply_id, ok_cb, nil)
    end
  end
  delete_msg(msg.id, ok_cb, nil)
end

return {
  description = "Delete message by reply",
  usage = {
    moderator = {
      "#delmsg (by reply) : Deletes message (only on supergroups)",
    },
  },
  patterns = {
    "^#(delmsg)$",
  },
  run = run,
}
