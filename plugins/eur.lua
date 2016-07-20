do
  -- TODO: More currencies

  -- See http://webrates.truefx.com/rates/connect.html
  local function getEURUSD(usd, eur)
    local url = 'http://webrates.truefx.com/rates/connect.html?c=EUR/USD&f=csv&s=n'
    local res,code = http.request(url)
    local rates = res:split(", ")
    local symbol = rates[1]
    local timestamp = rates[2]
    local sell = rates[3]..rates[4]
    local buy = rates[5]..rates[6]
    local text = symbol..'\n'..'Buy: '..buy..'\n'..'Sell: '..sell
    if usd then
      local eur = tonumber(usd) / tonumber(buy)
      text = text.."\n "..usd.."USD = "..eur.."EUR"
    end
    if eur then
      local usd = tonumber(eur) * tonumber(sell)
      text = text.."\n "..eur.."EUR = "..usd.."USD"
    end
    return text
  end

  local function run(msg, matches)
    if matches[1] == "!eurusd" then
      return getEURUSD(nil)
    end
    if matches[2] == "USD" then
      return getEURUSD(matches[1], nil)
    end
    if matches[2] == "EUR" then
      return getEURUSD(nil, matches[1])
    end
  end

  return {
    description = "Real-time EURUSD market price",
    usage = {
      "!eurusd [value EUR/USD]",
    },
    patterns = {
      "^!eurusd$",
      "^!eurusd (%d+[%d%.]*) (.*)$",
    },
    run = run
  }

end
