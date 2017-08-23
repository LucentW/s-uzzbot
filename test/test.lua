SUDO_USER_ID = 12345
_G.IS_TEST_ENVIRONMENT = true
_G.postpone = function() end

-- Return a fake message.
--   is_root: whether it comes from an admin
function test_craft_message(text, is_root, custom_id, custom_username)
	local _peer_id
	local _username
	if is_root then
		_peer_id = SUDO_USER_ID
		_username = "root"
	else
		_peer_id = custom_id or 100
		_username = custom_username or "johndoe"
	end
	return {
	  date = 1/0, -- a date infinitely in the future
	  flags = 257,
	  from = {
	    access_hash = -1.11111111111111+18,
	    bot = false,
	    first_name = _username,
	    flags = 196609,
	    id = "$010000000be6840443e616f4ce4780c0",
	    peer_id = _peer_id,
	    peer_type = "user",
	    phone = "11111111111",
	    print_name = _username,
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
--   is_root: whether the message comes from an admin
--   doNotAcknowledge: whether we must check that the message was not dropped, eg. during preprocessing or because it is invalid
function test_receive_message(msg, doNotAcknowledge)
	local was_message_received = on_msg_receive(msg)
	if not doNotAcknowledge then
		assert.is_true(was_message_received)
	end
end

function test_receive_text(text, is_root, doNotAcknowledge)
	local msg = test_craft_message(text, is_root)
	test_receive_message(msg, doNotAcknowledge)
	return msg -- can be useful later
end

-- Load the given list of plugins.
function test_load_plugins(plugins)
	_G._config.enabled_plugins = plugins
	local plugins_loaded_correctly = load_plugins()
	assert.is_true(plugins_loaded_correctly)
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
		_G.send_msg = spy.new(function(destination, text) end)

		test_load_plugins({"ping"})
		test_receive_text("!ping")
		assert.spy(_G.send_msg).was.called()
	end)
end)

describe("Antiflood", function()
	local limit = 5
	it("Can be enabled and configured", function()
		test_load_plugins({"anti-flood", "echo"})
		local msg = test_receive_text("!antiflood enable", true)
		local msg = test_receive_text("!antiflood maxmsg " .. limit, true)
		assert.is_true(is_antiflood_enabled(msg))
	end)
	it("Blocks floods", function()
		local num_replies = 0
		local kicked = false
		_G.send_msg = function(destination, text)
			if text == "spam" then
				num_replies = num_replies + 1
			end
		end
		_G.chat_del_user = function(chat, user, cb)
			kicked = true
			cb(nil, true)
		end
		for i = 1, 100 do
			test_receive_text("!echo spam", false, true)
			if kicked then break end
		end
		assert.is_true(kicked)
		assert.are.equal(limit, num_replies)
	end)
	it("Doesn't block floods from root", function()
		local num_replies = 0
		local kicked = false
		_G.send_msg = function(destination, text)
			if text == "spam" then
				num_replies = num_replies + 1
			end
		end
		_G.chat_del_user = function(chat, user, cb)
			kicked = true
			cb(nil, true)
		end
		for i = 1, 100 do
			-- Note that in this case we do ask for acknowledgement (doNotAcknowledge is false).
			test_receive_text("!echo spam", true, false)
			if kicked then break end
		end
		assert.is_false(kicked)
		assert.are.equal(100, num_replies)
	end)
	it("Honours exceptions", function()
		test_receive_text("!antiflood addexcept 1234", true)

		local ham_replies = 0
		local spam_replies = 0
		_G.send_msg = function(destination, text)
			if text == "I'm ham!" then
				ham_replies = ham_replies + 1
			elseif text == "I'm spam!" then
				spam_replies = spam_replies + 1
			end
		end
		local ham_kicked = false
		local spam_kicked = false
		_G.chat_del_user = function(chat, user, cb)
			if user == "user#id1234" then
				ham_kicked = true
			elseif user == "user#id4321" then
				spam_kicked = true
			else
				error("Kicking unknown user: " .. user)
			end
			cb(nil, true)
		end

		-- Note: we'll use custom IDs, because the default user has supposedly been kicked for flooding
		local ham_msg = test_craft_message("!echo I'm ham!", false, 1234, "hamsender")
		local spam_msg = test_craft_message("!echo I'm spam!", false, 4321, "spamsender")

		for i = 1, 100 do
			if not spam_kicked then test_receive_message(spam_msg, true) end
			if not ham_kicked then test_receive_message(ham_msg) end -- Ask for acknowledgment
		end

		assert.is_false(ham_kicked)
		assert.is_true(spam_kicked)
		assert.are.equal(100, ham_replies)
		assert.are.equal(limit, spam_replies)
	end)
end)