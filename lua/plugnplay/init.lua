local fs = require("plugnplay.fs")
local log = require("plugnplay.external.log")
local json = require("plugnplay.json")
local helpers = require("plugnplay.helpers")

---@class plugnplay
local plugnplay = {}

--- Plugnplay global state
---@type table
_G.pnp_state = {
   ---@type table
   config = {
      --- Plugnplay configuration
      ---@type table
      plugnplay = {
         --- Logging level, can be: trace, debug, info, warn, error
         ---@type string
         log_level = "info",
         --- Lockfile location, defaults to user's neovim configuration path
         ---@type string
         lockfile = table.concat({ vim.fn.stdpath("config"), "pnp.lock.json" }, fs.system_separator),
      },
      --- Plugins declaration
      ---@type table
      plugins = {},
   },
   --- Plugnplay lockfile contents
   ---@type string
   lockfile_content = "{}",
}

function plugnplay.read_plugins(location)
   local content = fs.read_or_create(
      location,
      [[{
    // plugnplay configurations goes here
    "plugnplay": {},
    // your plugins goes here
    "plugins": {}
}]]
   )

   return json.decode(content)
end

--- Starts plugnplay and sets up your plugins. Calls `plugnplay.setup` under the hood!
---@param config_location string|nil Plugnplay configuration file location
function plugnplay.startup(config_location)
   -- Make required plugnplay directories, e.g. '~/.cache/nvim/pnp'
   fs.make_pnp_dirs()

   local location = config_location or table.concat({ vim.fn.stdpath("config"), "cfg.jsonc" }, fs.system_separator)

   local decoded_json = plugnplay.read_plugins(location)
   plugnplay.setup(decoded_json)
end

function plugnplay.setup(configuration)
   _G.pnp_state.config = vim.tbl_deep_extend("force", _G.pnp_state.config, configuration or {})

   log.new({ level = _G.pnp_state.config.plugnplay.log_level }, true)

   -- Load the plugnplay lockfile
   plugnplay.lockfile_content = fs.read_or_create(_G.pnp_state.config.plugnplay.lockfile, "{}")
end

--- Updates the lockfile
--- @return table
function plugnplay.compile()
   local compiled = {}

   for k, v in pairs(_G.pnp_state.config) do
      if k == "plugins" then
         for plugin, data in pairs(v) do
            if compiled[plugin] then
               vim.notify(
                  vim.trim([[
[plugnplay] An error has occurred when parsing your plugins json file.
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
               return {}
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
[plugnplay] An error has occurred when parsing your plugins json file.
Error message: No URL key provided.

Take a look at your "plugins" key. In there you will see a plugin you called "%s".
This is great and all, but you haven't told plugnplay where to actually look for the plugin!
You need to provide a "url" key, like so:
"plugins": {
    "%s": {
        "url": "https://gitlab.com/some_nice_username/%s"
    }
}

Providing such a key will tell plugnplay to download the plugin from that address.

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
If you start your "url" string with either "~" or "/" then plugnplay will consider it a local path instead.

Execute :messages to see the full output.
                        ]]):format(helpers.rep(plugin, 7)),
                     vim.log.levels.ERROR
                  )
                  return {}
               end

               compiled[plugin] = data
            else
               vim.notify(
                  vim.trim([[
[plugnplay] An error has occurred when parsing your plugins json file.
Error message: Wrong data type provided.

This error comes from your "plugins" key so that's where you wanna look.
What went wrong specifically? You provided plugnplay the wrong type of data!
The error occurred precisely on the line you've defined the "%s" plugin:
"plugins": {
    "%s": %s
}

You gave plugnplay a value of type %s, but plugnplay only expects tables or strings.

Execute :messages to see the full output.
                    ]]):format(plugin, plugin, data, type(data)),
                  vim.log.levels.ERROR
               )
               return {}
            end
         end
      end
   end

   local lockfile_content = json.encode(compiled)
   fs.write_file(_G.pnp_state.config.plugnplay.lockfile, "w+", json.beautify(lockfile_content))
   return compiled
end

function plugnplay.sync()
  plugnplay.compile()
end

return plugnplay
-- vim: sw=3:ts=3:sts=3
