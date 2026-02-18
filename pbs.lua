#!/usr/bin/lua
-- # pbs.lua 2026-02-17
-- # AUR URL package data and comment scraper
-- # Dependencies: lua-http lua-dkjson
-- # luacheck pbs.lua

local http_request = require "http.request"
local dkjson = require "dkjson"
												-- # Get terminal width
local function get_term_width()

	local handle = io.popen("tput cols")
	local result = handle:read("*a")
	handle:close()
	return tonumber(result) or 80
end
												-- # Decode non alphabetic characters
local function decode_entities(text)

	local entities = {
			["&quot;"] = '"',
			["&apos;"] = "'",
			["&lt;"]   = "<",
			["&gt;"]   = ">",
			["&amp;"]  = "&",
			["&nbsp;"] = " "
	}
												-- # Replace with appropriate characters
	return text:gsub("&%a+;", entities)
end
												-- # Text wrapper
local function wrap(text, width, indent)

	indent = indent or ""
	local res = {}
	local line = indent

	for word in text:gmatch("%S+") do
		if	#line + #word + 1 > width then
			table.insert(res, line)
			line = indent .. word
		    else
			line = line == indent and line .. word or line .. " " .. word
		end
	end

	table.insert(res, line)
	return table.concat(res, "\n")
end

local function get_aur_data(package_name)

	local rpc_url = "https://aur.archlinux.org/rpc/?v=5&type=info&arg=" .. package_name
	local web_url = "https://aur.archlinux.org/packages/" .. package_name

	local cols = get_term_width()
	local blue = "\27[1;34m"
	local bold = "\27[1m"
	local reset = "\27[0m"

												-- # Fetch RPC Data
	local req = http_request.new_from_uri(rpc_url)
	local _, stream = req:go()
	local body = stream:get_body_as_string()
	local rpc_res = dkjson.decode(body)

	if	not rpc_res.results or #rpc_res.results == 0 then
		print("Error: Package '" .. package_name .. "' not found.")
		return
	end

	local pkg = rpc_res.results[1]
	local metadata = {
			{"Name:", pkg.Name},
			{"Version:", pkg.Version},
			{"Description:", pkg.Description or "N/A"},
			{"Votes:", tostring(pkg.NumVotes or 0)},
			{"Maintainer:", pkg.Maintainer or "None"},
			{"Project URL:", pkg.URL or "N/A"},
			{"AUR URL:", web_url}
	}

												-- # Print Header
	print("\n  " .. bold .. blue .. "AUR Package Information:" .. reset)
	print("  " .. string.rep("=", math.min(cols - 2, 80)))

												-- # Print long descriptions with wrapping
	for	_, item in ipairs(metadata) do
		local label, value = item[1], item[2]
												-- # remove indentation from the first line for alignment
		if	#label + #value + 17 > cols then
			print(string.format("  %-15s %s", label, wrap(value, cols - 2, string.rep(" ", 17)):sub(18)))
		    else
			print(string.format("  %-15s %s", label, value))
		end
	end
												-- # Fetch Comments
	print("  " .. string.rep("=", math.min(cols - 2, 80)))

	local w_req = http_request.new_from_uri(web_url)
	local _, w_stream = w_req:go()
	local html = w_stream:get_body_as_string()

	print("\n--- Recent Comments for " .. package_name .. " ---")
												-- # Extract comment header and body
												-- # Strip tags, collapse spaces/newlines into one
												-- # Decode HTML ie: '&quot;'
	local count = 0
	for	header, content in html:gmatch('class="comment%-header">(.-)</h4>.-class="article%-content">(.-)</div>') do

		if	count >= 5 then break end
			local user = decode_entities(header:gsub("<[^>]+>", ""):gsub("%s+", " "):match("^%s*(.-)%s*$"))
			local body_text = decode_entities(content:gsub("<[^>]+>", ""):gsub("%s+", " "):match("^%s*(.-)%s*$"))

			print(blue .. user .. reset)
			print(wrap(body_text, math.min(cols - 2, 120), "  "))
			print(string.rep("-", math.min(cols - 2, 120)))

			count = count + 1
		end
	end
												-- # Manage CLI argument
if	arg[1] then
	get_aur_data(arg[1])
    else
	print("Usage: pbs.lua <package_name>")
end
