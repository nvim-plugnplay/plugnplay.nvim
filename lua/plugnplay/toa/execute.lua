local toa_exec = {}
local log = require("plugnplay.external.log")
local pnp_git = require("plugnplay.git")
local fs = require("plugnplay.fs")
local utils = require("plugnplay.utils")
-- local toa = require"plugnplay.toa.generate".generate()
local toa = {
    {
        action = "install",
        name = "startup-nvim",
    },
    {
        action = "install",
        name = "better-escape",
    },
    {
        action = "remove",
        name = "neorg",
    },
}

local config = require("plugnplay").config

local function get_install_action(action)
    local install_action
    if type(config.plugins[action.name]) == "string" then
        install_action = require("plugnplay.utils").get_install_action(config.plugins[action.name])
    else
        install_action = require("plugnplay.utils").get_install_action(config.plugins[action.name].url)
    end
    return install_action
end

local function action_remove(action)
    print("removed " .. action.name)
end

---Git clones a plugin
---@param url string Url to the plugin repository
local function git_install(url)
    pnp_git.exec({
        cmd = "clone " .. url,
        cwd = fs.pnp_paths.opt,
        success = function(data)
            if data then
                print(vim.inspect(data))
            end
        end,
        err = function(error, data)
            print(vim.inspect(error))
            print(vim.inspect(data))
        end,
    })
end

---Create a symlink for a local plugin
---@param url string The absolute path of the plugin directory
local function symlink(url, name)
    local path = fs.pnp_paths.opt .. fs.system_separator .. utils.directory_name(url)
    if utils.is_windows then
        vim.loop.fs_symlink(url, path)
    else
        vim.loop.fs_symlink(url, path)
    end
end

---Install a plugin specified with `action`
---@param action table Install action
local function action_install(action)
    local install_action = get_install_action(action)
    if install_action.action == "local" then
        symlink(install_action.url, action.name)
    elseif install_action.action == "git_clone" then
        git_install(install_action.url)
    else
        log.error("Unknown install action")
    end
end

function toa_exec.execute(table_of_act)
    for _, action in ipairs(table_of_act) do
        if action.action == "remove" then
            action_remove(action)
        elseif action.action == "install" then
            action_install(action)
        end
    end
    require("plugnplay").compile()
end

function toa_exec.test()
    toa_exec.execute(toa)
end

return toa_exec
