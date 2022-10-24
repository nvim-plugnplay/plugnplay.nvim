local fs = {}

-- Get the system separator, '/' for *nix and '\\' for Windows
fs.system_separator = package.config:sub(1, 1)

-- Neovim pack path, refer to ':h packages'
local nvim_pack_path = table.concat({ vim.fn.stdpath("data"), "site", "pack" }, fs.system_separator)

local pnp_pack_path = table.concat({ nvim_pack_path, "pnp" }, fs.system_separator)

-- NOTE: start isn't a first-class citizen here, will be probably removed later
fs.pnp_paths = {
   cache = table.concat({ vim.fn.stdpath("cache"), "pnp" }, fs.system_separator),
   opt = table.concat({ pnp_pack_path, "opt" }, fs.system_separator),
   start = table.concat({ pnp_pack_path, "start" }, fs.system_separator),
}

function fs.make_pnp_dirs()
   for _, path in pairs(fs.pnp_paths) do
      if vim.fn.isdirectory(path) == 0 then vim.fn.mkdir(path, "p") end
   end
end

function fs.file_exists(location)
   local fd = vim.loop.fs_open(location, "r", 438)
   if fd then
      vim.loop.fs_close(fd)
      return true
   end
   return false
end

function fs.write_file(location, mode, contents)
   -- 644 sets read and write permissions for the owner, and it sets read-only
   -- mode for the group and others
   vim.loop.fs_open(location, mode, tonumber("644", 8), function(err, file)
      if not err then
         local file_pipe = vim.loop.new_pipe(false)
         vim.loop.pipe_open(file_pipe, file)
         vim.loop.write(file_pipe, contents)
         vim.loop.fs_close(file)
      end
   end)
end

---Reads or creates from a file
---@param location string The location of the file
---@param default string The contents to write to the file if it doesn't exist
function fs.read_or_create(location, default)
   local content
   if fs.file_exists(location) then
      local file = vim.loop.fs_open(location, "r", 438)
      local stat = vim.loop.fs_fstat(file)
      content = vim.loop.fs_read(file, stat.size, 0)
      vim.loop.fs_close(file)
   else
      content = vim.trim(default)
      fs.write_file(location, "w+", content)
   end

   return content
end

return fs
-- vim: sw=3:ts=3:sts=3
