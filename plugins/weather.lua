do

local BASE_URL = "http://api.openweathermap.org/data/2.5/weather"
local API_KEY = ""

local function get_weather(location)
  print("Finding weather in ", location)
  local url = BASE_URL
  url = url.."?q="..string.gsub(location, " ", "+")
  url = url.."&units=metric"
  url = url.."&appid="..API_KEY

  local b, c, h = http.request(url)
  if c ~= 200 then return nil end

  local weather = json:decode(b)
  local city = weather.name
  local country = weather.sys.country
  local temp = 'The temperature in '..city
    ..' (' ..country..')'
    ..' is '..weather.main.temp..'°C'
  local conditions = 'Current conditions are: '
    .. weather.weather[1].description
  
  if weather.weather[1].main == 'Clear' then
    conditions = conditions .. ' ☀'
  elseif weather.weather[1].main == 'Clouds' then
    conditions = conditions .. ' ☁☁'
  elseif weather.weather[1].main == 'Rain' then
    conditions = conditions .. ' ☔'
  elseif weather.weather[1].main == 'Thunderstorm' then
    conditions = conditions .. ' ☔☔☔☔'
  end

  return temp .. '\n' .. conditions
end

local function run(msg, matches)
  local city = 'Venezia'

  if matches[1] ~= '!weather' then 
    city = matches[1]
  end
  local text = get_weather(city)
  if not text then
    text = 'Can\'t get weather from that city.'
  end
  return text
end

return {
  description = "weather in that city (Venezia is default)", 
  usage = "!weather (city)",
  patterns = {
    "^!weather$",
    "^!weather (.*)$"
  }, 
  run = run 
}

end
