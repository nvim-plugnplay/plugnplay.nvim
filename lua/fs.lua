local fs = {}

function fs.read_or_create(location, default)
    -- TODO: Move to libuv in the future
    local file = io.open(location, "r")
    local content = file and file:read("*a")

    if not file then
        file = io.open(location, "w+")
        content = vim.trim(default)
        file:write(content)
    end

    file:close()

    return content
end

return fs
