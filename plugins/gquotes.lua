local quotes_file = './data/gquotes.lua'
local quotes_table

function read_quotes_file()
    local f = io.open(quotes_file, "r+")

    if f == nil then
        print ('Created a new quotes file on '..quotes_file)
        serialize_to_file({}, quotes_file)
    else
        print ('Quotes loaded: '..quotes_file)
        f:close()
    end
    return loadfile (quotes_file)()
end

function save_quote(msg)
    local to_id = tostring(1)

    if msg.text:sub(11):isempty() then
        return "Usage: !gaddquote quote"
    end

    if quotes_table == nil then
        quotes_table = {}
    end

    if quotes_table[to_id] == nil then
        print ('New gquote key to_id: '..to_id)
        quotes_table[to_id] = {}
    end
	-- Empty user name check
	if not msg.from.username then
	from_username = "" .. msg.from.print_name
	else
	from_username = ('@' .. msg.from.username)
	end
	currdate=os.date("%c")
	texttosend=msg.text:sub(11).. '\n\nFrom ' .. from_username .. ' \nDate: ' .. currdate
    local quotes = quotes_table[to_id]
    quotes[#quotes+1] = texttosend

    serialize_to_file(quotes_table, quotes_file)

    return "done!"
end

function save_quoteanon(msg)
    local to_id = tostring(1)

    if msg.text:sub(11):isempty() then
        return "Usage: !gaddquoteanon quote"
    end

    if quotes_table == nil then
        quotes_table = {}
    end

    if quotes_table[to_id] == nil then
        print ('New gquote key to_id: '..to_id)
        quotes_table[to_id] = {}
    end
		currdate=os.date("%c")
	texttosend=msg.text:sub(16).. '\n\nAnonymous user' .. ' \nDate: ' .. currdate
    local quotes = quotes_table[to_id]
    quotes[#quotes+1] = texttosend

    serialize_to_file(quotes_table, quotes_file)

    return "done!"
end

function get_quote(msg)
    local to_id = tostring(1)
    local quotes_phrases

    quotes_table = read_quotes_file()
    quotes_phrases = quotes_table[to_id]

    return quotes_phrases[math.random(1,#quotes_phrases)]
end

function run(msg, matches)
    if string.match(msg.text, "!gquote$") then
        return get_quote(msg)
	elseif string.match(msg.text, "!gaddquoteanon (.+)$") then
	        quotes_table = read_quotes_file()
        return save_quoteanon(msg)
    elseif string.match(msg.text, "!gaddquote (.+)$") then
        quotes_table = read_quotes_file()
        return save_quote(msg)
    end
end

return {
    description = "Save global quote",
    description = "Global Quote plugin, you can create and retrieve global random quotes",
    usage = {
        "!gaddquote [msg]",
		"!gaddquoteanon [msg] (for anonymous quotes)",
        "!gquote",
    },
    patterns = {
		"^!gaddquoteanon (.+)$",
        "^!gaddquote (.+)$",
        "^!gquote$",
    },
    run = run
}
