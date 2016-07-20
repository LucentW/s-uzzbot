local function run(msg, matches)
	local url = "https://query.yahooapis.com/v1/public/yql?q=select%20item.condition%20from%20weather.forecast%20where%20woeid%20in%20%28select%20woeid%20from%20geo.places%281%29%20where%20text%3D%22"..string.gsub(matches[1], " ", "%%20").."%22%29&format=json&env=store%3A%2F%2Fdatatables.org%2Falltableswithkeys"
	
	local res = http.request(url)
	  
	local jtab = JSON.decode(res)
	if jtab.query.count == 1 then
		data = jtab.query.results.channel.item.condition
		celsius = string.format("%.0f", (data.temp - 32) * 5/9)
		conditions = 'Current conditions are: '..data.text
		
		if string.match(data.text, 'Sunny') or string.match(data.text, 'Clear') then
          conditions = conditions .. ' ☀'
        elseif string.match(data.text, 'Cloudy') then
          conditions = conditions .. ' ☁☁'
        elseif string.match(data.text, 'Rain') then
          conditions = conditions .. ' ☔'
        elseif data.text == 'Thunderstorm' then
          conditions = conditions .. ' ☔☔☔☔'
        end
		
		return "The temperature in "..matches[1].." "
			.."is "..celsius.." °C/"
			..data.temp.." °F\n"..conditions
			
	else
		return 'Can\'t get weather from that city.'
	end
end

return {
  description = "weather in that city", 
  usage = "!weather (city)",
  patterns = {
    "^!weather (.*)$"
  }, 
  run = run 
}
