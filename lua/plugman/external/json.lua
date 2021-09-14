--
-- json.lua
--
-- Copyright (c) 2020 rxi
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy of
-- this software and associated documentation files (the "Software"), to deal in
-- the Software without restriction, including without limitation the rights to
-- use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
-- of the Software, and to permit persons to whom the Software is furnished to do
-- so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.
--

local json = { _version = "0.1.2" }

-------------------------------------------------------------------------------
-- Decode
-------------------------------------------------------------------------------

local decode

local escape_char_map = {
    ["\\"] = "\\",
    ['"'] = '"',
    ["\b"] = "b",
    ["\f"] = "f",
    ["\n"] = "n",
    ["\r"] = "r",
    ["\t"] = "t",
}

local escape_char_map_inv = { ["/"] = "/" }
for k, v in pairs(escape_char_map) do
    escape_char_map_inv[v] = k
end

local function make_indent(n)
    return ("\t"):rep(n)
end

local function escape_char(c)
    return "\\" .. (escape_char_map[c] or string.format("u%04x", c:byte()))
end

local function decode_nil()
    return "null"
end

local function decode_table(val, stack)
    local res = {}
    local errors = {}
    stack = stack or {}

    -- Circular reference?
    if stack[val] then
        table.insert(errors, "found circular reference in " .. stack[val])
    end

    stack[val] = true
    -- Check whether to treat as a array or object
    local array = true
    local length = 0
    local nLen = 0
    for k, v in pairs(val) do
        if (type(k) ~= "number" or k <= 0) and not (k == "n" and type(v) == "number") then
            array = nil
            break -- Treat as object
        else
            if k > length then
                length = k
            end
            if k == "n" and type(v) == "number" then
                nLen = v
            end
        end
    end

    if array then
        if nLen > length then
            length = nLen
        end
        -- Encode
        for i = 1, length do
            table.insert(res, decode(val[i], stack).data)
        end
        stack[val] = nil
        return {
            data = "[" .. table.concat(res, ",") .. "]",
            err = errors,
        }
    else
        local line_number = 1
        -- Treat as an object
        for k, v in pairs(val) do
            if type(k) ~= "string" then
                table.insert(errors, string.format("invalid key type ('%s') found at line %d", type(k), line_number))
            end
            table.insert(res, decode(k, stack).data .. ":" .. decode(v, stack).data)

            line_number = line_number + 1
        end
        stack[val] = nil
        return {
            data = "{" .. table.concat(res, ",") .. "}",
            err = errors,
        }
    end
end

local function decode_string(val)
    return {
        data = '"' .. val:gsub('[%z\1-\31\\"]', escape_char) .. '"',
        err = {},
    }
end

local function decode_number(val)
    local errors = {}

    -- Check for NaN, -inf and inf
    if val ~= val or val <= -math.huge or val >= math.huge then
        table.insert(errors, "unexpected number value '" .. tostring(val) .. "'")
    end
    return {
        data = tostring(val),
        err = errors,
    }
end

local type_func_map = {
    ["nil"] = decode_nil,
    ["table"] = decode_table,
    ["string"] = decode_string,
    ["number"] = decode_number,
    ["boolean"] = tostring,
}

decode = function(val, stack)
    local t = type(val)
    local f = type_func_map[t]
    if f then
        local encoded_data = f(val, stack)
        if t == "boolean" then
            return {
                data = encoded_data,
                err = {},
            }
        else
            return {
                data = encoded_data.data,
                err = encoded_data.err,
            }
        end
    end

    return {
        data = "",
        err = { "unexpected type '" .. t .. "'" },
    }
end

function json.decode(val)
    return decode(val)
end

-------------------------------------------------------------------------------
-- Encode
-------------------------------------------------------------------------------

local parse

local function create_set(...)
    local res = {}
    for i = 1, select("#", ...) do
        res[select(i, ...)] = true
    end
    return res
end

local space_chars = create_set(" ", "\t", "\r", "\n")
local delim_chars = create_set(" ", "\t", "\r", "\n", "]", "}", ",")
local escape_chars = create_set("\\", "/", '"', "b", "f", "n", "r", "t", "u")
local literals = create_set("true", "false", "null")

local literal_map = {
    ["true"] = true,
    ["false"] = false,
    ["null"] = nil,
}

local function next_char(str, idx, set, negate)
    for i = idx, #str do
        if set[str:sub(i, i)] ~= negate then
            return i
        end
    end
    return #str + 1
end

local function decode_error(str, idx, msg)
    local line_count = 1
    local col_count = 1
    for i = 1, idx - 1 do
        col_count = col_count + 1
        if str:sub(i, i) == "\n" then
            line_count = line_count + 1
            col_count = 1
        end
    end
    return string.format("%s at line %d, col %d", msg, line_count, col_count)
end

local function codepoint_to_utf8(n)
    -- http://scripts.sil.org/cms/scripts/page.php?site_id=nrsi&id=iws-appendixa
    local f = math.floor
    if n <= 0x7f then
        return string.char(n)
    elseif n <= 0x7ff then
        return string.char(f(n / 64) + 192, n % 64 + 128)
    elseif n <= 0xffff then
        return string.char(f(n / 4096) + 224, f(n % 4096 / 64) + 128, n % 64 + 128)
    elseif n <= 0x10ffff then
        return string.char(f(n / 262144) + 240, f(n % 262144 / 4096) + 128, f(n % 4096 / 64) + 128, n % 64 + 128)
    end
    return string.format("invalid unicode codepoint '%x'", n)
end

local function parse_unicode_escape(s)
    local n1 = tonumber(s:sub(1, 4), 16)
    local n2 = tonumber(s:sub(7, 10), 16)
    -- Surrogate pair?
    if n2 then
        return codepoint_to_utf8((n1 - 0xd800) * 0x400 + (n2 - 0xdc00) + 0x10000)
    else
        return codepoint_to_utf8(n1)
    end
end

local function parse_string(str, i)
    local res = ""
    local j = i + 1
    local k = j
    local errors = {}

    while j <= #str do
        local x = str:byte(j)

        if x < 32 then
            table.insert(errors, decode_error(str, j, "control character in string"))
        elseif x == 92 then -- `\`: Escape
            res = res .. str:sub(k, j - 1)
            j = j + 1
            local c = str:sub(j, j)
            if c == "u" then
                local hex = str:match("^[dD][89aAbB]%x%x\\u%x%x%x%x", j + 1)
                    or str:match("^%x%x%x%x", j + 1)
                    or table.insert(errors, decode_error(str, j - 1, "invalid unicode escape in string"))
                res = res .. parse_unicode_escape(hex)
                j = j + #hex
            else
                if not escape_chars[c] then
                    table.insert(decode_error(str, j - 1, "invalid escape char '" .. c .. "' in string"))
                end
                res = res .. escape_char_map_inv[c]
            end
            k = j + 1
        elseif x == 34 then -- `"`: End of string
            res = res .. str:sub(k, j - 1)
            return {
                data = res,
                idx = j + 1,
                err = errors,
            }
        end

        j = j + 1
    end

    table.insert(errors, decode_error(str, i, "expected closing quote for string"))
    return {
        data = "",
        err = errors,
    }
end

local function parse_number(str, i)
    local x = next_char(str, i, delim_chars)
    local s = str:sub(i, x - 1)
    local n = tonumber(s)
    local errors = {}
    if not n then
        table.insert(errors, decode_error(str, i, "invalid number '" .. s .. "'"))
    end
    return {
        data = n,
        idx = x,
        err = errors,
    }
end

local function parse_literal(str, i)
    local errors = {}
    local x = next_char(str, i, delim_chars)
    local word = str:sub(i, x - 1)
    if not literals[word] then
        table.insert(errors, decode_error(str, i, "invalid literal '" .. word .. "'"))
    end
    return {
        data = literal_map[word],
        idx = x,
        err = errors,
    }
end

local function parse_array(str, i)
    local errors = {}
    local res = {}
    local n = 1
    i = i + 1
    while 1 do
        local x
        i = next_char(str, i, space_chars, true)
        -- Empty / end of array?
        if str:sub(i, i) == "]" then
            i = i + 1
            break
        end
        -- Read token
        x, i = parse(str, i)
        res[n] = x
        n = n + 1
        -- Next token
        i = next_char(str, i, space_chars, true)
        local chr = str:sub(i, i)
        i = i + 1
        if chr == "]" then
            break
        end
        if chr ~= "," then
            table.insert(errors, decode_error(str, i, "expected ']' or ','"))
        end
    end
    return {
        data = res,
        idx = i,
        err = errors,
    }
end

local function parse_object(str, i)
    local res = {}
    local errors = {}

    i = i + 1
    while 1 do
        local key, val
        i = next_char(str, i, space_chars, true)
        -- Empty / end of object?
        if str:sub(i, i) == "}" then
            i = i + 1
            break
        end
        -- Read key
        if str:sub(i, i) ~= '"' then
            table.insert(errors, decode_error(str, i, "expected string for key"))
        end
        local parsed_data = parse(str, i)
        key, i = parsed_data.data, parsed_data.idx
        -- Read ':' delimiter
        i = next_char(str, i, space_chars, true)
        if str:sub(i, i) ~= ":" then
            table.insert(errors, decode_error(str, i, "expected ':' after key"))
        end
        i = next_char(str, i + 1, space_chars, true)
        -- Read value
        parsed_data = parse(str, i)
        val, i = parsed_data.data, parsed_data.idx
        -- Set
        res[key] = val
        -- Next token
        i = next_char(str, i, space_chars, true)
        local chr = str:sub(i, i)
        i = i + 1
        if chr == "}" then
            break
        end
        if chr ~= "," then
            table.insert(errors, decode_error(str, i, "expected '}' or ','"))
        end
    end
    return {
        data = res,
        idx = i,
        err = errors,
    }
end

local char_func_map = {
    ['"'] = parse_string,
    ["0"] = parse_number,
    ["1"] = parse_number,
    ["2"] = parse_number,
    ["3"] = parse_number,
    ["4"] = parse_number,
    ["5"] = parse_number,
    ["6"] = parse_number,
    ["7"] = parse_number,
    ["8"] = parse_number,
    ["9"] = parse_number,
    ["-"] = parse_number,
    ["t"] = parse_literal,
    ["f"] = parse_literal,
    ["n"] = parse_literal,
    ["["] = parse_array,
    ["{"] = parse_object,
}

parse = function(str, idx)
    local chr = str:sub(idx, idx)
    local f = char_func_map[chr]
    if f then
        local decoded_data = f(str, idx)
        return {
            data = decoded_data.data,
            idx = decoded_data.idx,
            err = decoded_data.err,
        }
    end
    return {
        data = "",
        idx = 1,
        err = {
            decode_error(str, idx, "unexpected character '" .. chr .. "'")
        }
    }
end

function json.encode(str)
    if type(str) ~= "string" then
        return {
            data = "",
            err = { "expected argument of type string, got " .. type(str) }
        }
    end
    local res = parse(str, next_char(str, 1, space_chars, true))
    res.idx = next_char(str, res.idx, space_chars, true)
    if res.idx <= #str then
        decode_error(str, res.idx, "trailing garbage")
    end
    return { data = res.data, err = res.errors }
end

function json.beautify(str)
    local beauty_json = ""
    local indent_level = 0
    local is_start_line = false
    local has_next_element = false

    for i = 1, #str - 1 do
        local curr_c = str:sub(i, i)
        local next_c = str:sub(i + 1, i + 1)

        if curr_c == "{" then
            -- Empty object
            if next_c == "}" then
                beauty_json = beauty_json .. curr_c
            else
                beauty_json = beauty_json .. curr_c .. "\n"
                indent_level = indent_level + 1
                is_start_line = true
            end
        elseif curr_c == "}" then
            if next_c == "," then
                beauty_json = beauty_json .. curr_c
            elseif next_c == "}" then
                indent_level = indent_level - 1
                beauty_json = beauty_json .. curr_c .. "\n" .. make_indent(indent_level)
            else
                beauty_json = beauty_json .. "\n" .. curr_c .. "\n"
            end
            indent_level = indent_level - 1
            is_start_line = true
        elseif curr_c == "," then
            is_start_line = true
            if next_c == " " then
                has_next_element = true
            end
            beauty_json = beauty_json .. curr_c .. "\n"
        else
            if is_start_line then
                is_start_line = false
                if has_next_element then
                    curr_c = curr_c:gsub(" ", "")
                    has_next_element = false
                end
                beauty_json = beauty_json .. make_indent(indent_level) .. curr_c
            else
                if curr_c == "[" then
                    -- Empty array
                    if next_c == "]" then
                        beauty_json = beauty_json .. curr_c
                    else
                        is_start_line = true
                        indent_level = indent_level + 1
                        beauty_json = beauty_json .. curr_c .. "\n"
                    end
                elseif curr_c == "]" then
                    if next_c ~= "," then
                        indent_level = indent_level - 1
                        beauty_json = beauty_json .. "\n" .. make_indent(indent_level) .. curr_c .. "\n"
                    else
                        is_start_line = true
                        indent_level = indent_level - 1
                        beauty_json = beauty_json .. "\n" .. make_indent(indent_level) .. curr_c
                    end
                elseif curr_c == ":" and next_c ~= " " then
                    beauty_json = beauty_json .. curr_c .. " "
                elseif curr_c == '"' and next_c == "}" or curr_c:find("%w") and next_c == "}" then
                    indent_level = indent_level - 1
                    beauty_json = beauty_json .. curr_c .. "\n" .. make_indent(indent_level)
                else
                    beauty_json = beauty_json .. curr_c
                end
            end
        end
    end
    beauty_json = beauty_json .. str:sub(#str, #str)
    return beauty_json
end

return json
