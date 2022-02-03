local toa_exec = {}
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

local function action_remove(action)
    print("removed " .. action.name)
end

local function action_install(action)
    local install_action
    if type(config.plugins[action.name]) == "string" then
        install_action = require("plugnplay.utils").get_install_action(config.plugins[action.name])
    else
        install_action = require("plugnplay.utils").get_install_action(config.plugins[action.name].url)
    end
    dump(install_action)
end

function toa_exec.execute(table_of_act)
    print(vim.inspect(table_of_act))
    for _, action in ipairs(table_of_act) do
        if action.action == "remove" then
            action_remove(action)
        elseif action.action == "install" then
            action_install(action)
        end
    end
end

function toa_exec.test()
    toa_exec.execute(toa)
end

return toa_exec
