local utils = {}

---Gets the install method and the url to install based on the plugin url
--- At the moment types are `local` and `git_clone`
---@param url string The url of the plugin
---@return table #Table with `action` and `url` fields
function utils.get_install_action(url)
   local ret = {}
   if url:sub(1, 1) == "~" then url = vim.fn.expand("~") .. url:sub(2, -1) end
   if vim.fn.isdirectory(url) == 1 then
      ret.action = "local"
      ret.url = url
   elseif url:sub(1, 4) == "http" then
      ret.action = "git_clone"
      ret.url = url
   elseif url:match("^[%w-_.]+%/[%w-_.]+$") then
      ret.action = "git_clone"
      ret.url = "https://github.com/" .. url
   end
   return ret
end

utils.is_windows = jit ~= nil and jit.os == "Windows" or package.config:sub(1, 1) == "\\"

function utils.directory_name(url)
   local fs = require("plugnplay.fs")
   if url:sub(-1, -1) == fs.system_separator then url = url:sub(1, -2) end
   return vim.fn.fnamemodify(url, ":t")
end

--- Parses a command with multiple options
---@param command string E.g. NvimTree{Open,Close}
---@return table Commands
function utils.parse_command(command)
   local commands = {}
   if not command:find("{") then return { command } end
   local options = vim.fn.split(command:match("{([%a,]+)}"), ",")
   for _, option in ipairs(options) do
      table.insert(commands, command:gsub("{([%a,]+)}", "") .. option)
   end
   return commands
end

return utils
