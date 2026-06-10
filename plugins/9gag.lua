do

  local FEED_URL = "https://9gag.com/hot.rss"

  local function get_9GAG()
    local b, c = https.request(FEED_URL)
    if c ~= 200 or not b then return nil, nil end

    local items = {}
    for item in b:gmatch("<item>(.-)</item>") do
      local title = item:match("<title><!%[CDATA%[(.-)%]%]></title>")
                 or item:match("<title>(.-)</title>")
      local img   = item:match('src="(https://[^"]+%.jpg)"')
                 or item:match('src="(https://[^"]+%.gif)"')
                 or item:match('src="(https://[^"]+%.png)"')
      if img then
        table.insert(items, {img = img, title = title or ""})
      end
    end

    if #items == 0 then return nil, nil end
    local pick = items[math.random(#items)]
    return pick.img, pick.title
  end

  local function send_title(cb_extra, success, result)
    if success then
      send_msg(cb_extra[1], cb_extra[2], ok_cb, false)
    end
  end

  local function run(msg, matches)
    local receiver = get_receiver(msg)
    local url, title = get_9GAG()
    if not url then
      return "Could not fetch from 9GAG."
    end
    send_photo_from_url(receiver, url, send_title, {receiver, title})
    return false
  end

  return {
    description = "9GAG for Telegram",
    usage = "!9gag: Send random image from 9gag",
    patterns = {"^!9gag$"},
    run = run
  }

end
