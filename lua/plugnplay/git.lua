local git = {}

local log = require("plugnplay.external.log")
local async = require("plugnplay.external.async")

--- Executes a git command and gets the output
--- @param opts table
function git.exec(opts)
    local exec_cmd = async:new({
        cmd = "git " .. opts.cmd,
        cwd = opts.cwd,
        on_stdout = function(_, data)
            opts.success(data)
        end,
        on_stderr = function(err, data)
            opts.err(err, data)
        end
    })
    log.debug("Executing 'git " .. opts.cmd .. "' ...")
    exec_cmd:start()
end

return git
