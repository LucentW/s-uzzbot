local function run(msg, matches)
	local receiver = get_receiver(msg)
	local url = 'http://thecatapi.com/api/images/get'
	local gif_url = 'http://thecatapi.com/api/images/get?type=gif'		
	if matches[1] == "gif" then
		print("GIF URL: "..gif_url)
		send_document_from_url(receiver, gif_url)
	else
		print("Bild URL: "..url)
		send_photo_from_url(receiver, url)
	end
end

return {
  description = "Sendet ein zufälliges Katzenbild", 
  usage = {"!gatto","!gatti","!cat","!cats","!k"},
  patterns = {"^!gatto$","^!gatti$","^!cat$","^!cats$","^/kitty (.*)$","^/katze (.*)$","^/cat (.*)$","^/kadse (.*)$",}, 
  run = run 
}