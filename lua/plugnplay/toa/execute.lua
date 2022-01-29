local toa_exec = {}
-- local toa = require"plugnplay.toa.generate".generate()
local toa = {
    {
        action = "install",
        name = "startup-nvim",
    },
    {
        action = "remove",
        name = "neorg",
    },
}

local function action_remove(action)
    print("removed " .. action.name)
end

local function action_install(action)
    print("installed " .. action.name)
end

function toa_exec.execute(table_of_act)
    print("table_of_act:")
    dump(table_of_act)
    for _, action in ipairs(table_of_act) do
        if action.action == "remove" then
            action_remove(action)
        elseif action.action == "install" then
            action_install(action)
        end
    end
end

toa_exec.execute(toa)

return toa_exec
