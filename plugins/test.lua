local function reply(cb_extra, success, result)
  send_large_msg(cb_extra, serpent.block(result, {comment=false}))
end
local function run(msg, matches)
  if not is_sudo(msg) then return nil end
  if msg.reply_id then
    get_message(msg.reply_id, reply, get_receiver(msg))
  end
  
  text = serpent.block(msg, {comment=false})
  send_large_msg(get_receiver(msg), text)
end
return{
  patterns = {"test"},
  run = run
  }