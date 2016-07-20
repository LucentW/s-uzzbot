local function search_kickass(query)
  local url = 'http://kickasstorrentcr.com/json.php?q='..string.gsub(query, " ", "+")
  local b,c = http.request(url)
  local data = json:decode(b)

  local text = 'Results: '..data.total_results..'\n\n'
  local results = math.min(#data.list, 5)
  for i=1,results do
    local torrent = data.list[i]
    local link = torrent.torrentLink
    link = link:gsub('%?title=.+','')
    text = text..torrent.title
    ..'\n'..'Seeds: '..torrent.seeds
    ..' '..'Leeches: '..torrent.leechs
    ..'\n'..link
    --..'\n magnet:?xt=urn:btih:'..torrent.hash
    ..'\n\n'
  end
  return text
end

local function run(msg, matches)
  if is_admin(msg) then
    local query = matches[1]
    return search_kickass(query)
  else
    return "This command is restricted to admins only."
  end
end

return {
  description = "Search Torrents",
  usage = "!torrent <search term>: Search for torrent",
  patterns = {
    "^!torrent (.+)$"
  },
  hide = true,
  run = run
}
