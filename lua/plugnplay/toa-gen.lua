local plugnplay = require("plugnplay")
local fs = require("plugnplay.fs")
local json = require("plugnplay.json")
local toa = {}

function toa.generate()
    local table_of_actions = {}
    local location = table.concat({ vim.fn.stdpath("config"), "cfg.jsonc" }, fs.system_separator)
    local file = vim.loop.fs_open(location, "r", 438)
    local stat = vim.loop.fs_fstat(file)
    local config_content = vim.loop.fs_read(file, stat.size, 0)
    vim.loop.fs_close(file)
    file = nil
    stat = nil
    file = vim.loop.fs_open(plugnplay.config.plugnplay.lockfile, "r", 438)
    stat = vim.loop.fs_fstat(file)
    local lockfile_content = vim.loop.fs_read(file, stat.size, 0)
    vim.loop.fs_close(file)
    local config_plugins = json.decode(config_content).plugins
    local lockfile_plugins = json.decode(lockfile_content)
    for name, config in pairs(config_plugins) do
        if not vim.tbl_contains(vim.tbl_keys(lockfile_plugins), name) then
            table.insert(table_of_actions, { action = "install", name = name })
        end
        -- if config ~= lockfile_plugins[name] and type(config) == "table" then
        --     print("config")
        --     print(vim.inspect(config))
        --     print("lockfile_plugins[name]:")
        --     print(vim.inspect(lockfile_plugins[name]))
        -- end
    end
    for name, config in pairs(lockfile_plugins) do
        if not vim.tbl_contains(vim.tbl_keys(config_plugins), name) then
            table.insert(table_of_actions, { action = "remove", name = name })
        end
    end
    return table_of_actions
end

function toa.convert_to_code(action) end

return toa
