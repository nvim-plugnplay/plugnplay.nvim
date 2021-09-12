local plugman = {}

function plugman.startup(config_location)
    local location = config_location or vim.fn.stdpath("config") .. "/plugins.json"

    local json = require("external.json")

    -- TODO: Move to libuv in the future
    local file = io.open(location, "r")
    local content = file and (file:read("*a") or "") or ""

    if not file then
        file = io.open(location, "w+")

        content = [[
{
    "plugman": {
        "url": "vhyrro/generic-neovim-plugin-manager"
    }
}
        ]]

        file:write(content)
    end

    vim.notify(vim.inspect(json.decode(content)))

    file:close()
end

return plugman
