local function run(msg, matches)
  local receiver = get_receiver(msg)

  local url = 'http://thecatapi.com/api/images/get'
  local gif_url = 'http://thecatapi.com/api/images/get?type=gif'

  if matches[1] == "gif" then
    send_document_from_url(receiver, gif_url)
  else
    send_photo_from_url(receiver, url)
  end
end

return {
  description = 'Plugin to send cat images/GIFs.',
  usage = {
    "!kitty : Sends a cat picture",
    "!kitty gif : Sends a cat GIF",
  },
  patterns = {
    '^!kitty$',
    '^!kitty (gif)$',
  },
  run = run
}
