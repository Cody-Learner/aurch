#!/usr/bin/env lua
-- # pbs.lua 2026-04-10
-- # AUR URL package data and comment scraper
-- # Dependencies: lua

-- ======================================================================
-- EMBEDDED JSON DECODER (Miniature dkjson-style parser)
-- ======================================================================
local json = {}
function json.decode(s)
    local pos = 1
    local function skip_whitespace()
        pos = s:find("[^%s]", pos) or pos
    end
    local function parse_val()
        skip_whitespace()
        local char = s:sub(pos, pos)
        if char == '{' then
            local obj = {}
            pos = pos + 1
            skip_whitespace()
            if s:sub(pos, pos) == '}' then pos = pos + 1; return obj end
            while true do
                local key = parse_val()
                skip_whitespace()
                pos = pos + 1 -- skip ':'
                obj[key] = parse_val()
                skip_whitespace()
                local next_c = s:sub(pos, pos)
                pos = pos + 1
                if next_c == '}' then break end
            end
            return obj
        elseif char == '[' then
            local arr = {}
            pos = pos + 1
            skip_whitespace()
            if s:sub(pos, pos) == ']' then pos = pos + 1; return arr end
            while true do
                table.insert(arr, parse_val())
                skip_whitespace()
                local next_c = s:sub(pos, pos)
                pos = pos + 1
                if next_c == ']' then break end
            end
            return arr
        elseif char == '"' then
            local start = pos + 1
            local stop = s:find('"', start)
            local txt = s:sub(start, stop - 1)
            pos = stop + 1
            return txt
        elseif s:find('^[%d%-]', pos) then
            local _, end_p, num = s:find('^([%d%.%-]+)', pos)
            pos = end_p + 1
            return tonumber(num)
        elseif s:find('^true', pos) then pos = pos + 4; return true
        elseif s:find('^false', pos) then pos = pos + 5; return false
        elseif s:find('^null', pos) then pos = pos + 4; return nil
        end
    end
    return parse_val()
end

-- ======================================================================
-- UTILITY FUNCTIONS
-- ======================================================================

local function get_term_width()
    local handle = io.popen("tput cols")
    local result = handle:read("*a")
    handle:close()
    return tonumber(result) or 80
end

local function decode_entities(text)
    local entities = {
        ["&quot;"] = '"', ["&apos;"] = "'", ["&lt;"] = "<",
        ["&gt;"] = ">", ["&amp;"] = "&", ["&nbsp;"] = " "
    }
    return text:gsub("&%a+;", entities)
end

local function wrap(text, width, indent)
    indent = indent or ""
    local res = {}
    local line = indent
    for word in text:gmatch("%S+") do
        if #line + #word + 1 > width then
            table.insert(res, line)
            line = indent .. word
        else
            line = line == indent and line .. word or line .. " " .. word
        end
    end
    table.insert(res, line)
    return table.concat(res, "\n")
end

-- ======================================================================
-- NETWORK LOGIC (Using Curl)
-- ======================================================================

local function fetch_url(url)
    local handle = io.popen(string.format("curl -sL '%s'", url))
    local result = handle:read("*a")
    handle:close()
    return result
end

-- ======================================================================
-- AUR DATA SCRAPER
-- ======================================================================

local function get_aur_data(package_name)
    local rpc_url = "https://aur.archlinux.org/rpc/?v=5&type=info&arg=" .. package_name
    local web_url = "https://aur.archlinux.org/packages/" .. package_name

    local cols = get_term_width()
    local blue = "\27[1;34m"
    local bold = "\27[1m"
    local reset = "\27[0m"

    -- 1. Fetch RPC Data
    local body = fetch_url(rpc_url)
    if not body or body == "" then
        print("Error: Could not reach AUR.")
        return
    end
    
    local rpc_res = json.decode(body)

    if not rpc_res or not rpc_res.results or #rpc_res.results == 0 then
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

    print("\n  " .. bold .. blue .. "AUR Package Information:" .. reset)
    print("  " .. string.rep("=", math.min(cols - 2, 80)))

    for _, item in ipairs(metadata) do
        local label, value = item[1], item[2]
        if #label + #value + 17 > cols then
            print(string.format("  %-15s %s", label, wrap(value, cols - 2, string.rep(" ", 17)):sub(18)))
        else
            print(string.format("  %-15s %s", label, value))
        end
    end

    -- 2. Fetch Comments
    print("  " .. string.rep("=", math.min(cols - 2, 80)))
    local html = fetch_url(web_url)

    print("\n--- Recent Comments for " .. package_name .. " ---")
    local count = 0
    for header, content in html:gmatch('class="comment%-header">(.-)</h4>.-class="article%-content">(.-)</div>') do
        if count >= 5 then break end
        local user = decode_entities(header:gsub("<[^>]+>", ""):gsub("%s+", " "):match("^%s*(.-)%s*$"))
        local body_text = decode_entities(content:gsub("<[^>]+>", ""):gsub("%s+", " "):match("^%s*(.-)%s*$"))

        print(blue .. user .. reset)
        print(wrap(body_text, math.min(cols - 2, 120), "  "))
        print(string.rep("-", math.min(cols - 2, 120)))
        count = count + 1
    end
end

-- ======================================================================
-- EXECUTION
-- ======================================================================
if arg[1] then
    get_aur_data(arg[1])
else
    print("Usage: pbs.lua <package_name>")
end