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
        if self:lookahead() ~= nil then
            -- Let's move back again after checking for EOF so we
            -- will avoid errors when checking around EOF again
            self:lookbehind()
            while self:lookahead():match("%s") do
                self:skip()
            end
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

local json = {}

function json.decode(source)
    local source_without_comments

    scanner:initialize_new(source)

    local function skip_comment()
        if scanner:lookahead() == "/" and scanner:lookahead(2) == "/" then
            while scanner:lookahead() and scanner:lookahead() ~= "\n" do
                scanner:skip()
            end
        end
    end

    local function skip_multiline_comment()
        if scanner:lookahead() == "/" and scanner:lookahead(2) == "*" then
            while scanner:lookahead() do
                if scanner:lookahead() == "*" and scanner:lookahead(2) == "/" then
                    scanner:skip() -- skip '*'
                    scanner:skip() -- skip '/'
                    return
                end
                scanner:skip()
            end
        end
    end

    do -- Perform preprocessing to skip comments from json file
        -- local preprocessed_source = ""

        while scanner:lookahead() do
            -- Skip one-line comments
            skip_comment()

            -- Skip multi-line comments (does not allow nested comments!)
            skip_multiline_comment()

            scanner:advance()
        end

        source_without_comments = scanner:mark_end()
        scanner:initialize_new(source_without_comments)
        scanner:end_session()
    end

    return vim.json.decode(source_without_comments)
end

function json.encode(source)
    return vim.json.encode(source)
end

local function test_decode()
    return json.decode([[
{
    // Test number 1
    "test 1": "something cool", // Test number 2
    "test2": 30.2
    // Test number 3
    /*
        This is a multi-line
        comment, everyone gotta love me!
    */
}
    ]])
end

local function test_encode()
    return json.encode({
        -- Test number 1
        ["test 1"] = "something cool", -- Test number 2
        ["test2"] = 30.2,
        -- Test number 3
        --[[
            This is a multi-line
            comment, everyone gotta love me!
        ]]
    })
end

-- vim.notify(vim.inspect(test_decode()))
-- vim.notify(vim.inspect(test_encode()))

return json
