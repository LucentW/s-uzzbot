SUDO_USER_ID = 12345
_G.IS_TEST_ENVIRONMENT = true
_G.postpone = function() end

-- Return a fake message.
--   isRoot: whether it comes from an admin
function test_craft_message(text, isRoot)
	local _peer_id
	local _username
	if isRoot then
		_peer_id = SUDO_USER_ID
		_username = "root"
	else
		_peer_id = 100
		_username = "johndoe"
	end
	return {
	  date = 1/0, -- a date infinitely in the future
	  flags = 257,
	  from = {
	    access_hash = -1.11111111111111+18,
	    bot = false,
	    first_name = "John",
	    flags = 196609,
	    id = "$010000000be6840443e616f4ce4780c0",
	    peer_id = _peer_id,
	    peer_type = "user",
	    phone = "11111111111",
	    print_name = "John Doe",
	    username = _username
	  },
	  id = "020000006466ef0024923a00000000000000000000000000",
	  out = false,
	  service = false,
	  temp_id = 2,
	  text = text,
	  to = {
	    flags = 65537,
	    id = "$020000006466ef000000000000000000",
	    members_num = 100,
	    peer_id = 15689316,
	    peer_type = "chat",
	    print_name = "Group name here",
	    title = "Group name here"
	  },
	  unread = true
	}
end

-- Make the bot see a new message.
--   isRoot: whether the message comes from an admin
--   doNotAcknowledge: whether we must check that the message was not dropped, eg. during preprocessing or because it is invalid
function test_receive_message(text, isRoot, doNotAcknowledge)
	local msg = test_craft_message(text, isRoot)
	local was_message_received = on_msg_receive(msg)
	if not doNotAcknowledge then
		assert.is_true(was_message_received)
	end
	return msg -- can be useful later
end

-- Load the given list of plugins.
function test_load_plugins(plugins)
	_G._config.enabled_plugins = plugins
	local plugins_loaded_correctly = load_plugins()
end

describe("Bot", function()
	it("initializes", function()
		_G._config = {
		  disabled_channels = {},
		  enabled_plugins = {},
		  moderation = {
		    data = "data/moderation.json"
		  },
		  sudo_users = {0, SUDO_USER_ID}
		}
		require("bot/bot")
		_G.loglevel = LOGLEVEL_WARN
		local initialized_correctly = on_binlog_replay_end()
		assert.is_true(initialized_correctly)
	end)
	it("loads ping", function()
		test_load_plugins({"ping"})
	end)
	it("responds to pings", function()
		-- Create a stub in advance
		_G.send_msg = spy.new(function(destination, text) end)

		test_load_plugins({"ping"})
		test_receive_message("!ping")
		assert.spy(_G.send_msg).was.called()
	end)
end)

describe("Antiflood", function()
	it("Can be enabled", function()
		test_load_plugins({"anti-flood", "ping"})
		local msg = test_receive_message("!antiflood enable", true)
		assert.is_true(is_antiflood_enabled(msg))
	end)
end)

-- Typical message:
-- {
--   date = 1503346812,
--   flags = 257,
--   from = {
--     access_hash = -1.11111111111111+18,
--     bot = false,
--     first_name = "User",
--     flags = 196609,
--     id = "$010000000be6840443e616f4ce4780c0",
--     peer_id = 75818507,
--     peer_type = "user",
--     phone = "11111111111",
--     print_name = "User",
--     username = "username"
--   },
--   id = "020000006466ef0024923a00000000000000000000000000",
--   out = false,
--   service = false,
--   temp_id = 2,
--   text = "test",
--   to = {
--     flags = 65537,
--     id = "$020000006466ef000000000000000000",
--     members_num = 100,
--     peer_id = 15689316,
--     peer_type = "chat",
--     print_name = "Group name here",
--     title = "Group name here"
--   },
--   unread = true
-- }