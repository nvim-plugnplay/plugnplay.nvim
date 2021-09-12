local fs = {}

function fs.file_exists(location)
    local fd = vim.loop.fs_open(location, "r", 438)
    if fd then
        vim.loop.fs_close(fd)
        return true
    end
    return false
end

function fs.read_or_create(location, default)
    local content
    if fs.file_exists(location) then
        local file = vim.loop.fs_open(location, "r", 438)
        local stat = vim.loop.fs_fstat(file)
        content = vim.loop.fs_read(file, stat.size, 0)
        vim.loop.fs_close(file)
    else
        content = vim.trim(default)
        -- 644 sets read and write permissions for the owner, and it sets read-only
        -- mode for the group and others
        vim.loop.fs_open(location, "w+", tonumber("644", 8), function(err, file)
            if not err then
                local file_pipe = vim.loop.new_pipe(false)
                vim.loop.pipe_open(file_pipe, file)
                vim.loop.write(file_pipe, content)
                vim.loop.fs_close(file)
            end
        end)
    end

    return content
end

return fs
