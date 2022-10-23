--- @class jobs
--- @diagnostic disable
local jobs = {}

--- Safely close child processes
--- @param handle uv_pipe_t
local function safe_close(handle)
    if handle and not handle:is_closing() then
        handle:close()
    end
end

--- Create a new jobs process
--- @param job_opts table The jobs job options
--- @return table
function jobs:new(job_opts)
    job_opts = job_opts or {}
    for opt, val in pairs(job_opts) do
        self[opt] = val
    end
    setmetatable(job_opts, self)
    self.__index = self

    return job_opts
end

--- Set the jobs job options
--- @return table
function jobs.options()
    local options = {}
    local args = vim.split(jobs.cmd, " ")

    jobs.stdin = vim.loop.new_pipe(false)
    jobs.stdout = vim.loop.new_pipe(false)
    jobs.stderr = vim.loop.new_pipe(false)

    -- Get the jobs job command, e.g. 'git'
    options.command = table.remove(args, 1)
    options.args = args
    options.stdio = { jobs.stdin, jobs.stdout, jobs.stderr }

    if jobs.cwd then
        options.cwd = jobs.cwd
    end

    if jobs.env then
        options.env = jobs.env
    end

    if jobs.detach then
        options.detach = jobs.detach
    end

    return options
end

--- Send data to stdin
--- @param data string
jobs.send = function(data)
    jobs.stdin:write(data)
    jobs.stdin:shutdown()
end

--- Shutdown stdio in jobs jobs
--- @param code number The exit code
--- @param signal number The exit signal
jobs.shutdown = function(code, signal)
    if jobs.on_exit then
        jobs.on_exit(code, signal)
    end
    if jobs.on_stdout then
        jobs.stdout:read_stop()
    end
    if jobs.on_stderr then
        jobs.stderr:read_stop()
    end
    jobs.stop()
end

--- Start a new jobs job
jobs.start = function()
    local opts = jobs.options()
    local cmd = opts.command
    opts.command = nil

    jobs.handle = vim.loop.spawn(cmd, opts, vim.schedule_wrap(jobs.shutdown))
    if jobs.on_stdout then
        vim.loop.read_start(jobs.stdout, vim.schedule_wrap(jobs.on_stdout))
    end
    if jobs.on_stderr then
        vim.loop.read_start(jobs.stderr, vim.schedule_wrap(jobs.on_stderr))
    end
end

--- Stop an jobs job
jobs.stop = function()
    safe_close(jobs.stdin)
    safe_close(jobs.stderr)
    safe_close(jobs.stdout)
    safe_close(jobs.handle)
end

return jobs
