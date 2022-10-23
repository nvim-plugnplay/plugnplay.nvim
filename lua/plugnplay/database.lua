local database = {}

local fs = require("plugnplay.fs")
local log = require("plugnplay.external.log")
local jobs = require("plugnplay.external.jobs")

function database.fetch()
   local fetch_opts = {
      cwd = fs.pnp_paths.cache,
      on_exit = function(code, _)
         -- NOTE: we aren't using 'on_stdout' nor 'on_stderr' functions here because cURL and Wget
         -- sends progress messages to stderr, causing an annoying behavior to us so we are
         -- checking the exit_code instead
         if code == 0 then
            log.info("Successfully retrieved plugins database\nSaved database into '" .. fs.pnp_paths.cache .. "'.")
         else
            log.error("Error while retrieving plugins database.")
         end
      end,
   }
   -- Check if we should use wget or curl, depending on availability
   if vim.fn.executable("wget") == 1 then
      fetch_opts.cmd = "wget"
      log.debug("Using wget to fetch plugins database ...")
   elseif vim.fn.executable("curl") == 1 then
      fetch_opts.cmd = "curl -fSs -o database.json"
      log.debug("Using curl to fetch plugins database ...")
   end

   fetch_opts.cmd = table.concat({
      fetch_opts.cmd,
      "https://raw.githubusercontent.com/nvim-plugnplay/database/main/database.json",
   }, " ")

   log.info("Fetching plugnplay plugins database, please wait ...")
   local fetcher = jobs:new(fetch_opts)
   log.debug("Fetcher command: '" .. fetch_opts.cmd .. "'")

   fetcher:start()
end

return database
