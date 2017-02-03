function getUrbanDictionary(text)
  local topic = string.match(text, "!ud (.+)") or string.match(text, "http://([A-Za-z0-9-_-]+).urbanup.com/") or string.match(text, "http://www.urbandictionary.com/define.php[?]term=([A-Za-z0-9-_-]+)")
  topic = url_encode(topic)
  b = http.request("http://api.urbandictionary.com/v0/define?term=" .. topic)
  res = json:decode(b)
  local definition = nil
  if #res.list > 0 then
    definition = res.list[1].word..": "..res.list[1].definition.."\n".. res.list[1].permalink
  else
    definition = nil
  end
  return definition
end

function url_encode(str)
  if (str) then
    str = string.gsub (str, "\n", "\r\n")
    str = string.gsub (str, "([^%w %-%_%.%~])",
      function (c) return string.format ("%%%02X", string.byte(c)) end)
    str = string.gsub (str, " ", "+")
  end
  return str
end

function run(msg, matches)
  local text = getUrbanDictionary(msg.text)
  if (text == nil) then
    return '"'..matches[1]..'" not found on Urban Dictionary.'
  else
    return text
  end
end

return {
  description = "Find an Urban Dictionary definition.",
  usage = {
    "!ud [term] : Returns the definition of term from Urban Dictionary"
  },
  patterns = {
    "^!ud (.*)$",
    "^http://([A-Za-z0-9-_-]+).urbanup.com/",
    "^http://www.urbandictionary.com/define.php[?]term=([A-Za-z0-9-_-]+)"
  },
  run = run
}
