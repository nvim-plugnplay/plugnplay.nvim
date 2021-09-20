-- TODO: Error checking

local scanner = {
    initialize_new = function(self, source)
        self.source = source
    end,

    end_session = function(self)
        self.position = 0
        self.buffer = ""
        self.source = ""
    end,

    position = 0,
    buffer = "",
    source = "",

    current = function(self)
        if self.position == 0 then
            return nil
        end
        return self.source:sub(self.position, self.position)
    end,

    lookahead = function(self, count)
        count = count or 1

        if self.position + count > self.source:len() then
            return nil
        end

        return self.source:sub(self.position + count, self.position + count)
    end,

    lookbehind = function(self, count)
        count = count or 1

        if self.position - count < 0 then
            return nil
        end

        return self.source:sub(self.position - count, self.position - count)
    end,

    backtrack = function(self, amount)
        self.position = self.position - amount
    end,

    advance = function(self)
        self.buffer = self.buffer .. self.source:sub(self.position + 1, self.position + 1)
        self.position = self.position + 1
    end,

    skip = function(self)
        self.position = self.position + 1
    end,

    skip_whitespace = function(self)
        while self:lookahead():match("%s") do
            self:skip()
        end
    end,

    mark_end = function(self)
        if self.buffer:len() ~= 0 then
            local ret = self.buffer
            self.buffer = ""
            return ret
        end
    end,

    halt = function(self, mark_end, continue_till_end)
        if mark_end then
            self:mark_end()
        end

        if continue_till_end then
            self.buffer = self.source:sub(self.position + 1)
            self:mark_end()
        end

        self.position = self.source:len() + 1
    end,
}

local log = require("plugman.external.log")
local json = {}

function json.decode(source)
    scanner:initialize_new(source)

    do -- Perform preprocessing
        local preprocessed_source = ""

        while scanner:lookahead() do
            if scanner:lookahead() == "/" and scanner:lookahead(2) == "/" then
                while scanner:lookahead() and scanner:lookahead() ~= "\n" do
                    scanner:skip()
                end
            end

            scanner:advance()
        end

        scanner:initialize_new(scanner:mark_end())
        scanner:end_session()
    end

    local function decode_error(message)

    end

    local function parse_pair()
        if scanner:lookahead() ~= "\"" then
            log.error("Syntax stuff yada yada")
            return
        end

        scanner:skip()

        while scanner:lookahead() ~= "\"" and scanner:current() ~= "\\" do
            scanner:advance()
        end

        scanner:skip()

        local key = scanner:mark_end()
        log.warn(key)
    end

    local function parse_object()
        if scanner:lookahead() == "{" then
            log.error("Error")
            return
        end

        scanner:skip()
        scanner:skip_whitespace()

        return parse_pair()
    end

    return parse_object()
end

function test()
    json.decode([[
    {
        // Test number 1
        "test 1": "something cool", // Test number 2
        "test2": 30.2
        // Test number 3
    }
    ]])
end

return json
