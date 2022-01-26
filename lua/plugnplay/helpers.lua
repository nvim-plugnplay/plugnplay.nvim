local helpers = {}

function helpers.rep(value, x)
    if x == 1 then
        return value
    end

    return value, helpers.rep(value, x - 1)
end

function helpers.is_minimum_version(major, minor, patch)
    local version = vim.version()

    return major <= version.major and minor <= version.minor and patch <= version.patch
end

return helpers
