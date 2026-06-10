do

  local function get_stat(stats, name)
    for _, s in ipairs(stats) do
      if s.stat.name == name then return s.base_stat end
    end
    return 0
  end

  local function callback(extra)
    send_msg(extra.receiver, extra.text, ok_cb, false)
  end

  local function send_pokemon(query, receiver)
    local url = "https://pokeapi.co/api/v2/pokemon/" .. query .. "/"
    local b, c = https.request(url)
    if c ~= 200 or not b then
      return 'No pokémon found.'
    end

    local pokemon = json:decode(b)
    if pokemon == nil then
      return 'No pokémon found.'
    end

    -- height in decimetres, weight in hectograms
    local height = tonumber(pokemon.height) / 10
    local weight = tonumber(pokemon.weight) / 10

    local text = 'Pokédex ID: ' .. pokemon.id
    ..'\nName: ' .. pokemon.name
    ..'\nWeight: ' .. weight .. ' kg'
    ..'\nHeight: ' .. height .. ' m'
    ..'\nSpeed: ' .. get_stat(pokemon.stats, 'speed')

    if pokemon.sprites and pokemon.sprites.front_default then
      local extra = { receiver = receiver, text = text }
      send_photo_from_url(receiver, pokemon.sprites.front_default, callback, extra)
    end

    return text
  end

  local function run(msg, matches)
    local receiver = get_receiver(msg)
    local query = URL.escape(string.lower(matches[1]))
    return send_pokemon(query, receiver)
  end

  return {
    description = "Pokedex searcher for Telegram",
    usage = "!pokedex [Name/ID]: Search the pokédex for Name/ID and get info of the pokémon!",
    patterns = {
      "^!pokedex (.*)$",
      "^!pokemon (.+)$"
    },
    run = run
  }

end
