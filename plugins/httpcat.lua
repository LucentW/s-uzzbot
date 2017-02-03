local function run(msg, matches)
  local receiver = get_receiver(msg)
  local res, code = https.request("https://http.cat/" .. matches[1])
  if code == 404 then
    send_msg(receiver, "Oops where is the cat?!!", ok_cb, nil)
    send_photo_from_url_callback({receiver = receiver, url = "https://http.cat/404"})
    return nil
  end
  if code ~= 200 then
    return "There was an error downloading the image"
  else
    local file = io.open("tmp.jpg", "w+")
    file:write(res)
    file:close()
    send_photo(receiver, "tmp.jpg", rmtmp_cb, {file_path="tmp.jpg"})
  end
end
return{
  patterns = {
    "^!httpcat (%d+)$"
  },
  run = run,
  usage = {
    "!httpcat <status_code>: gives an image from http.cat"
  }
}