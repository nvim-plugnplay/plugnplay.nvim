local toa = {}

function toa.generate_toa(desired, actual)
    local function compare(val1, val2)
        if val1 and not val2 then
            return {
                "pull",
                type(val1) == "string" and val1 or val1.url,
            }
        end
    end
end

function toa.convert_to_code(action) end

return toa
