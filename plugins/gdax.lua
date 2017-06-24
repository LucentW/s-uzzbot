do

  function get_gdax(id)
    local res,code = https.request("https://api.gdax.com/products/"..id.."/stats")
    if code ~= 200 then return "HTTP ERROR" end
    local data = json:decode(res)
    local stats = "Stats for "..id.."\n\n"
    stats = stats.."Open: "..data.open.."\n"
    stats = stats.."High: "..data.high.."\n"
    stats = stats.."Low: "..data.low.."\n\n"
    stats = stats.."Volume: "..data.volume.."\n"
    stats = stats.."Last: "..data.last.."\n\n"
    stats = stats.."Volume (30 days): "..data.volume_30day
    return stats
  end

  function run(msg, matches)
    if matches[1] == "eth" then
      return get_gdax("ETH-EUR")
    end
    if matches[1] == "btc" then
      return get_gdax("BTC-EUR")
    end
    if matches[1] == "ltc" then
      return get_gdax("LTC-EUR")
    end

    return get_gdax(matches[1])
  end

  return {
    description = "Sends latest infos from GDAX",
    usage = {"!gdax (product): Fetch latest infos from GDAX exchange (ex. BTC-EUR)"},
    patterns = {
      "^!(eth)$",
      "^!(btc)$",
      "^!(ltc)$",
      "^!gdax (.*)",
    },
    run = run
  }

end
