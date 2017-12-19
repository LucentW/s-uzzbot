do
    
  local ltn12 = require("ltn12")
  local https = require("ssl.https")
  
  -- Base search URL
  local BASE_URL = 'https://my-free-mp3.net/api/search.php?callback=placeholder'
  local DL_URL = 'https://streams.my-free-mp3.net/'
  
  -- Provide encoded id for download link
  local function encodeForLink(input)
    local map = {'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'J', 'K', 'M', 'N', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'j', 'k', 'm', 'n', 'p', 'q', 'r', 's', 't', 'u', 'v', 'x', 'y', 'z', '1', '2', '3'}
    local encoded = ""
    local maplength = #map
    
    if input == 0 then
      return map[1]
    end
    
    if input < 0 then
      input = input * -1
      encoded = encoded..'-'
    end
    
    local val
    
    while input > 0 do
        val = input % maplength
        input = math.floor(input / maplength)
        encoded = encoded..map[val + 1]
    end
    
    return encoded
  end
  
  local function convert_to_time(seconds)
    local mm = math.floor(seconds / 60)
    local ss = seconds % 60

    return string.format("%02d:%02d", mm, ss)
  end

  local function getTheBamba(q)
    local request = "q="..string.gsub(q, " ", "+").."&sort=2&count=10&performer_only=0"
    print(request)
    
    local sink = {}
    
    local ignoreme, code, headers, status = https.request {
        url = BASE_URL,
        method = "POST",
        source = ltn12.source.string(request),
        sink = ltn12.sink.table(sink),
        headers = {
            ["Content-type"] = "application/x-www-form-urlencoded",
            ["Content-Length"] = string.len(request),
            ["User-Agent"] = "Mozilla/5.0 (X11; Linux x86_64; rv:58.0) Gecko/20100101 Firefox/58.0",
            ["Host"] = "my-free-mp3.net",
            ["Referer"] = "https://my-free-mp3.net/",
            ["DNT"] = "1",
            ["X-Requested-With"] = "XMLHttpRequest",
            ["Cookie"] = "musicLang=en"
        }
    }
    
    if code ~= 200 then
      return "Oops! Network errors! Try again later."
    end
    
    local root = table.concat(sink)
    root = root:sub(13)
    root = root:sub(1, -3)
    
    local parsed = json:decode(root)
    
    local tracks = parsed["response"]
    table.remove(tracks, 1)
    local output = ''

    -- If no tracks found
    if #tracks < 1 then
      return 'No tracks found :( Try with other keywords may help.'
    end

    for i, track in pairs(tracks) do
      -- Track artist
      local artist = track["artist"]

      -- Track title
      local title = track["title"]

      -- Track time
      local time = convert_to_time(track["duration"])
      -- local time = track["duration"]
      
      -- DL link
      local dllink = DL_URL..encodeForLink(track["owner_id"])..":"..encodeForLink(track["aid"])
      
      -- Size
      local size, sizeok = https.request(dllink .. "?getBytes")
      local realSize
      
      -- Bitrate
      local bitrate
      
      if sizeok ~= 200 then
        realSize = "ERR"
        bitrate = "ERR"
      else
        realSize = string.format("%.3f", size / 1048576).." MB"
        bitrate = "~"..string.format("%.0f", ((size * 8) / 1000) / track["duration"]).." kbit/s"
      end

      -- Generate an awesome, well formated output
      output = output .. i .. '. ' .. artist .. ' - ' .. title .. '\n'
      .. '🕚 ' .. time .. ' | ' .. ' 🎧 ' .. bitrate .. ' | ' .. ' 📎 ' .. realSize .. '\n'
      .. '💾 : ' .. dllink .. '\n\n'
    end

    return output
  end

  local function run(msg, matches)
    return getTheBamba(matches[1])
  end

  return {
    description = 'Search and get music from My-Free-MP3',
    usage = '!music [track name or artist and track name]: Search and get the music',
    patterns = {
      '^!music (.*)$'
    },
    run = run
  }

end
