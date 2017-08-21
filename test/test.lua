describe("Bot", function()
	it("initializes", function()
		_G.postpone = function() end
		_G._config = {
		  disabled_channels = {},
		  enabled_plugins = {
		  },
		  moderation = {
		    data = "data/moderation.json"
		  },
		  sudo_users = {
		    0
		  }
		}
		require("bot/bot")
		_G.loglevel = LOGLEVEL_WARN
		local initialized_correctly = on_binlog_replay_end()
		assert.is_true(initialized_correctly)
	end)
	it("loads ping", function()
		_config.enabled_plugins = {"ping"}
		local plugins_loaded_correctly = load_plugins()
		assert.is_true(plugins_loaded_correctly)
	end)
	it("responds to pings", function()
		-- Create a stub in advance
		_G.send_msg = spy.new(function(destination, text) end)

		local was_message_received = on_msg_receive({
		  date = 1/0, -- a date infinitely in the future
		  flags = 257,
		  from = {
		    access_hash = -1.11111111111111+18,
		    bot = false,
		    first_name = "TARS",
		    flags = 196609,
		    id = "$010000000be6840443e616f4ce4780c0",
		    peer_id = 75818507,
		    peer_type = "user",
		    phone = "11111111111",
		    print_name = "TARS",
		    username = "rTARS"
		  },
		  id = "020000006466ef0024923a00000000000000000000000000",
		  out = false,
		  service = false,
		  temp_id = 2,
		  text = "!ping",
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
		})
		assert.is_true(was_message_received)
		assert.spy(_G.send_msg).was.called()
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