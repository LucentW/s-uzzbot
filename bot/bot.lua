local _VERSION_NUM = _VERSION:match('(%d%.%d)$')

package.path = package.path .. ';.luarocks/share/lua/'.._VERSION_NUM..'/?.lua'
..';.luarocks/share/lua/'.._VERSION_NUM..'/?/init.lua'
package.cpath = package.cpath .. ';.luarocks/lib/lua/'.._VERSION_NUM..'/?.so'

require("./bot/utils")
require("./bot/emoji")

VERSION = '0.3'

-- Let's leave space for backwards-compatible new levels
LOGLEVEL_DEBUG = 0
LOGLEVEL_INFO = 10
LOGLEVEL_WARN = 20
LOGLEVEL_ERROR = 30
if (not loglevel) then loglevel = LOGLEVEL_INFO end
function log(level, message)
  if (level >= loglevel) then print(message) end
end

-- This function is called when tg receives a msg
-- Returns false if the message was ignored, true otherwise
function on_msg_receive (msg)
  if not started then
    log(LOGLEVEL_DEBUG, "not started")
    return
  end

  msg = backward_msg_format(msg)

  local receiver = get_receiver(msg)

  local chat_id = msg.to.id
  local hashchat = 'whitelist:modonly:'..chat_id
  local whitelistmod = redis:get(hashchat) or false

  -- vardump(msg)
  msg = pre_process_service_msg(msg)

  if msg_valid(msg) then
    msg = pre_process_msg(msg)
    if msg then
      if not whitelistmod or (whitelistmod and is_momod(msg)) then
        match_plugins(msg)
      else
        print('Message ignored -- '..chat_id..' has modonly wl enabled')
      end

-- Commented out since it is a cosmetic feature.
-- Also breaks UX on groups since on standard mode it marks the message
-- as read for everybody.
--    mark_read(receiver, ok_cb, false)

  if not (not whitelistmod or (whitelistmod and is_momod(msg))) then
    log(LOGLEVEL_INFO, 'Message ignored -- '..chat_id..' has modonly wl enabled')
    return false
  end

  match_plugins(msg)
  return true
end

function ok_cb(extra, success, result)
end

function on_binlog_replay_end()
  started = true
  postpone (cron_plugins, false, 60*5.0)

  -- See plugins/isup.lua as an example for cron

  -- You can optionally pass a pre-existing configuration. Used in tests.
  if (not _config) then
    _config = load_config()
  end

  -- load plugins
  plugins = {}
  return load_plugins()
end

function msg_valid(msg)
  -- Don't process outgoing messages
  if msg.out then
    log(LOGLEVEL_INFO, '\27[36mNot valid: msg from us\27[39m')
    return false
  end

  -- Before bot was started
  if msg.date < now then
    log(LOGLEVEL_INFO, '\27[36mNot valid: old msg\27[39m')
    return false
  end

  if msg.unread == 0 then
    log(LOGLEVEL_INFO, '\27[36mNot valid: read\27[39m')
    return false
  end

  if not msg.to.id then
    log(LOGLEVEL_INFO, '\27[36mNot valid: To id not provided\27[39m')
    return false
  end

  if not msg.from.id then
    log(LOGLEVEL_INFO, '\27[36mNot valid: From id not provided\27[39m')
    return false
  end

  if msg.from.id == our_id then
    log(LOGLEVEL_INFO, '\27[36mNot valid: Msg from our id\27[39m')
    return false
  end

  if msg.to.type == 'encr_chat' then
    log(LOGLEVEL_INFO, '\27[36mNot valid: Encrypted chat\27[39m')
    return false
  end

  if msg.from.id == 777000 then
    log(LOGLEVEL_INFO, '\27[36mNot valid: Telegram message\27[39m')
    return false
  end

  return true
end

--
function pre_process_service_msg(msg)
  if msg.service then
    local action = msg.action or {type=""}
    -- Double ! to discriminate of normal actions
    msg.text = "!!tgservice " .. action.type

    -- wipe the data to allow the bot to read service messages
    if msg.out then
      msg.out = false
    end
    if msg.from.id == our_id then
      msg.from.id = 0
    end
  end
  return msg
end

-- Apply plugin.pre_process function
function pre_process_msg(msg)
  for name,plugin in pairs(plugins) do
    if plugin.pre_process and msg then
      log(LOGLEVEL_INFO, 'Preprocess ' .. name)
      msg = plugin.pre_process(msg)
    end
  end

  return msg
end

-- Go over enabled plugins patterns.
function match_plugins(msg)
  for name, plugin in pairs(plugins) do
    match_plugin(plugin, name, msg)
  end
end

-- Check if plugin is on _config.disabled_plugin_on_chat table
local function is_plugin_disabled_on_chat(plugin_name, receiver)
  local disabled_chats = _config.disabled_plugin_on_chat
  -- Table exists and chat has disabled plugins
  if disabled_chats and disabled_chats[receiver] then
    -- Checks if plugin is disabled on this chat
    for disabled_plugin,disabled in pairs(disabled_chats[receiver]) do
      if disabled_plugin == plugin_name and disabled then
        if plugins[disabled_plugin].hidden then
          log(LOGLEVEL_INFO, 'Plugin '..disabled_plugin..' is disabled on this chat')
        else
          local warning = 'Plugin '..disabled_plugin..' is disabled on this chat'
          log(LOGLEVEL_INFO, warning)
          send_msg(receiver, warning, ok_cb, false)
        end
        return true
      end
    end
  end
  return false
end

-- Check if nsfw is disabled on _config.disabled_nsfw_on_chat table
local function is_nsfw_disabled_on_chat(receiver)
  local disabled_chats = _config.disabled_nsfw_on_chat
  -- Table exists and chat has disabled plugins
  if disabled_chats and disabled_chats[receiver] then
    return disabled_chats[receiver] or false
  end
  return false
end

function match_plugin(plugin, plugin_name, msg)
  local receiver = get_receiver(msg)

  -- Go over patterns. If one matches it's enough.
  -- https://stackoverflow.com/a/12929685
  for k, pattern in pairs(plugin.patterns) do
    local matches = match_pattern(pattern, msg.text)
    if matches then
      log(LOGLEVEL_INFO, "msg matches: " .. pattern)

      if not is_sudo(msg) then
        if is_plugin_disabled_on_chat(plugin_name, receiver) then
          goto continue
        end
        if plugin.nsfw and is_nsfw_disabled_on_chat(receiver) then
          goto continue
        end
      end

      -- Function exists
      if plugin.run then
        -- If plugin is for privileged users only
        if not warns_user_not_allowed(plugin, msg) then
          local result = plugin.run(msg, matches)
          if result then
            send_large_msg(receiver, result)
          end
        end
      end
      -- One patterns matches
      goto continue
    end
    ::continue::
  end
end

-- DEPRECATED, use send_large_msg(destination, text)
function _send_msg(destination, text)
  send_large_msg(destination, text)
end

-- Save the content of _config to config.lua
function save_config( )
  serialize_to_file(_config, './data/config.lua')
  log(LOGLEVEL_INFO, 'saved config into ./data/config.lua')
end

-- Returns the config from config.lua file.
-- If file doesn't exist, create it.
function load_config( )
  local f = io.open('./data/config.lua', "r")
  -- If config.lua doesn't exist
  if not f then
    log(LOGLEVEL_INFO, "Created new config file: data/config.lua")
    create_config()
  else
    f:close()
  end
  local config = loadfile ("./data/config.lua")()
  for v,user in pairs(config.sudo_users) do
    log(LOGLEVEL_INFO, "Allowed user: " .. user)
  end
  return config
end

-- Create a basic config.json file and saves it.
function create_config( )
  -- A simple config with basic plugins and ourselves as privileged user
  config = {
    enabled_plugins = {
      "groupmanager",
      "help",
      "location",
      "plugins",
      "stats",
      "time",
      "version",
      "media_handler",
      "moderation",
      "sudo",
      "9gag",
      "xkcd",
      "wiki",
      "danbooru",
      "imdb",
      "boobs",
      "banhammer",
      "meme",
      "weather",
      "pokedex",
      "rss",
      "roll",
      "join",
      "eur",
      "isup",
      "music",
      "hello",
      "invite_sudo",
      "id",
      "antispam",
      "delmsg",
      "anti-flood",
      "expand",
      "tex",
      "webshot",
      "translate",
      "mute",
      "kitty",
      "ud",
      "leave",
      "why"
    },
    sudo_users = {our_id},
    disabled_channels = {},
    moderation = {data = 'data/moderation.json'}
  }
  serialize_to_file(config, './data/config.lua')
  log(LOGLEVEL_INFO, 'Saved clean configuration into ./data/config.lua')
  log(LOGLEVEL_INFO, 'Make sure to edit sudo_users and add your ID.')
end

function on_our_id (id)
  our_id = id
end

function on_user_update (user, what)
  --vardump (user)
end

function on_chat_update (chat, what)
  --vardump (chat)
end

function on_channel_update (channel, what)
  --vardump (channel)
end

function on_secret_chat_update (schat, what)
  --vardump (schat)
end

function on_get_difference_end ()
end

-- Enable plugins in config.json
-- Returns true if all the plugins were loaded correctly, false otherwise
function load_plugins()
  local success = true
  for k, v in pairs(_config.enabled_plugins) do
    log(LOGLEVEL_INFO, "Loading plugin " .. v)

    local ok, err = pcall(function()
        local t = assert(loadfile("plugins/"..v..'.lua'))()
        plugins[v] = t
      end)

    if not ok then
      success = false
      log(LOGLEVEL_WARN, '\27[31mError loading plugin '..v..'\27[39m')
      log(LOGLEVEL_WARN, '\27[31m'..err..'\27[39m')
    end
  end

  return success
end

-- custom add
function load_data(filename)

  local f = io.open(filename)
  if not f then
    return {}
  end
  local s = f:read('*all')
  f:close()
  local data = JSON.decode(s)

  return data

end

function save_data(filename, data)

  local s = JSON.encode(data)
  local f = io.open(filename, 'w')
  f:write(s)
  f:close()

end

-- Call and postpone execution for cron plugins
function cron_plugins()

  for name, plugin in pairs(plugins) do
    -- Only plugins with cron function
    if plugin.cron ~= nil then
      plugin.cron()
    end
  end

  -- Called again in 5 mins
  postpone (cron_plugins, false, 5*60.0)
end


-- Start and load values
our_id = 0
now = os.time()
math.randomseed(now)
started = false
