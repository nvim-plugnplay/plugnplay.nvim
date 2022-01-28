local helpers = {}

---Repeats a value `x` times
---@param value string The value to repeat
---@param x  number How many times to repeat the value
function helpers.rep(value, x)
    if x == 1 then
        return value
    end

    return value, helpers.rep(value, x - 1)
end

---Checks if the neovim version is newer than a specified version
---@param major number The minimum major version
---@param minor  number The minimum minor version
---@param patch  number The minimum patch version
function helpers.is_minimum_version(major, minor, patch)
    local version = vim.version()

    return major <= version.major and minor <= version.minor and patch <= version.patch
end

return helpers
