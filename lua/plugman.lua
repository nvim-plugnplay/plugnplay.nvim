local fs = require("plugman.fs")
local log = require("plugman.external.log")
local json = require("plugman.external.json")

local plugman = {
    config = {
        plugman = {
            log = {},
            lockfile = vim.fn.stdpath("data") .. "/plugman.lock.json",
        },
    },
    lockfile = "",
}

function plugman.read_plugins(location)
    local content = fs.read_or_create(
        location,
        [[{
    "auto": {},
    "plugins-with-configs": {},
    "custom": {}
}]]
    )

    -- return json.decode(content)
end

function plugman.startup(config_location)
    local location = config_location or vim.fn.stdpath("config") .. "/plugins.json"

    local decoded_json = plugman.read_plugins(location)

    if #decoded_json.err > 0 then
        -- TODO: error message
        return
    end

    plugman.setup(decoded_json.data)
end

function plugman.setup(configuration)
    plugman.config = vim.tbl_deep_extend("force", plugman.config, configuration or {})

    log.new(plugman.config.plugman.log, true)

    -- Load the plugman lockfile
    plugman.lockfile = fs.read_or_create(plugman.config.plugman.lockfile, "{}")
end

function plugman.compile()
    local compiled = {}

    for k, v in pairs(plugman.config) do
        if k == "plugins" then
            for plugin, data in pairs(v) do
                if compiled[plugin] then
                    vim.notify(
                        vim.trim([[
[PLUGMAN] An error has occurred when parsing your plugins json file.
Error message: Duplicate plugin found.

In your "plugins" key you have two different plugins that have the same name:
"plugins": {
    "%s": { ... },
    ...
    <somewhere else in the json file>
    "%s": { ... }
}

Names must be unique, please remove one of the duplicate instances or rename the one of the instances
and give it a unique name. Only rename if the two plugins are different, otherwise you will simply be loading the same
plugin twice.
Execute :messages to see the full output.
                    ]]):format(plugin, plugin),
                        vim.log.levels.ERROR
                    )
                    return
                end

                if type(data) == "string" then
                    compiled[plugin] = {
                        url = data,
                        commit = "",
                        description = "",
                    }
                elseif type(data) == "table" then
                    if not data.url then
                        vim.notify(
                            vim.trim([[
[PLUGMAN] An error has occurred when parsing your plugins json file.
Error message: No URL key provided.

Take a look at your "plugins" key. In there you will see a plugin you called "%s".
This is great and all, but you haven't told plugman where to actually look for the plugin!
You need to provide a "url" key, like so:
"plugins": {
    "%s": {
        "url": "https://gitlab.com/some_nice_username/%s"
    }
}

Providing such a key will tell plugman to download the plugin from that address.

If your plugin comes from GitHub you can completely omit the "https://github.com/" bit and just do:
"plugins": {
    "%s": {
        "url": "some_nice_username/%s"
    }
}

TIP: If you're not gonna be doing any special configuration you can actually simply provide a JSON string
instead of a table!
Take a look:
"plugins": {
    "%s": "some_nice_username/%s"
}

So simple!

Additionally you can also provide a path to a local directory if you're doing plugin development!
If you start your "url" string with either "~" or "/" then plugman will consider it a local path instead.

Execute :messages to see the full output.
                        ]]):format(plugin, plugin, plugin, plugin, plugin, plugin, plugin),
                            vim.log.levels.ERROR
                        ) -- TODO: Make a function to duplicate these values
                        return
                    end

                    compiled[plugin] = data
                else
                    vim.notify(
                        vim.trim([[
[PLUGMAN] An error has occurred when parsing your plugins json file.
Error message: Wrong data type provided.

This error comes from your "plugins" key so that's where you wanna look.
What went wrong specifically? You provided plugman the wrong type of data!
The error occurred precisely on the line you've defined the "%s" plugin:
"plugins": {
    "%s": %s
}

You gave plugman a value of type %s, but plugman only expects tables or strings.

Execute :messages to see the full output.
                    ]]):format(plugin, plugin, data, type(data)),
                        vim.log.levels.ERROR
                    )
                    return
                end
            end
        end
    end

    fs.write_file(plugman.config.plugman.lockfile, "w+", json.beautify(json.encode(compiled)))
end

function plugman.update() end

return plugman
