local plugnplay = require("plugnplay")
local fs = require("plugnplay.fs")
local json = require("plugnplay.json")
local lockfile_contents = fs.read_or_create(plugnplay.config.plugnplay.lockfile, "{}")
local plugins = json.decode(lockfile_contents)
local log = require("plugnplay.external.log")

-- TODO: implement `wants`?
-- TODO: implement `after`
local function pnp_load(plugin)
    local plug_conf = plugins[plugin]
    vim.cmd("packadd " .. plugin)
    if plug_conf.configuration == vim.NIL then
        return
    end
    if plug_conf.configuration.Module then
        require(plug_conf.configuration.Module)
    end
    if plug_conf.configuration.Chunk then
        local success, err = pcall(loadstring, plug_conf.configuration.Chunk)
        if not success then
            log.error("Error running config for " .. plugin .. ": " .. err)
        end
    end
end

local function lazy_load_event(plugin, event)
    vim.validate({ event = { event, "string" } })
    vim.api.nvim_create_autocmd(event, {
        pattern = "*",
        callback = function()
            pnp_load(plugin)
        end,
        once = true,
    })
end

local function lazy_load(plugin, config)
    if config.lazy_load == vim.NIL then
        return
    end
    local lazy_loading = config.lazy_load
    if lazy_loading.event ~= vim.NIL then
        lazy_load_event(plugin, lazy_loading.event)
    end
end

for plugin, config in pairs(plugins) do
    lazy_load(plugin, config)
end
