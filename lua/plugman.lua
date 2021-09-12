local plugman = {}

function plugman.startup(location)
    local custom_location = location
        or (function()
            local source = string.sub(debug.getinfo(1, "S").source, 2)

            -- Path to the package root
            return vim.fn.fnamemodify(source, ":p:h:h:h:h")
        end)()

    print(vim.inspect(custom_location))
end

return plugman
