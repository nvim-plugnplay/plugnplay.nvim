<img src="res/plugnplay.svg" width=315>
# plugnplay.nvim
### The the ultimative neovim plugin ecosystem

## ✨Features 
- Install plugins easily
- Configuration in a `.json` file
- Sane defaults for plugins
- Automatically set up plugins by only giving a repo adress

## Planed Features
- Detect "dead" plugins automatically


## 📦Installation

Put the following code in your config to bootstrap plugnplay:
```lua
local plugnplay_path = vim.fn.stdpath("data") .. "/site/pack/plugnplay/opt/plugnplay.nvim"

if vim.fn.empty(vim.fn.glob(plugnplay_path)) > 0 then
  vim.notify("Bootstrapping plugnplay.nvim, please wait ...")
  vim.fn.system({
    "git",
    "clone",
    "https://github.com/nvim-plugnplay/plugnplay.nvim",
    plugnplay_path,
  })
end

-- Load plugnplay
vim.cmd([[ packadd plugnplay.nvim ]])
local plugnplay = require("plugnplay")
```

## Configuration
You configure plugins in the `cfg.json` file.
The structure of a config is like this:

```jsonc
{
    "plugnplay": {
        // Configuration for plugnplay goes here
    },
    
    // Plugins we want to auto-configure
    "auto-config": [
        "neorg",
        "something-else"
    ],

    // Similar to "auto-config" except we actually need to supply our own configuration
    "plugins": {
        {
            "meta": {
                "version": "0.1.0",
                "authors": ["Shift"],
                "description": "Config powered with plugnplay.nvim",
            },
            "options": {
                "pnp-version": "0.1.0", // Last compatible pnp version
                // here goes some pnp config
            },
            "dependencies": {
                "neorg": {
                    "github": "nvim-neorg/neorg",
                    "branch": "unstable",
                    "config": "config.neorg",
                },
                "mappy": {
                    "path": "~/.code/lua/mappy",
                    "config": "general.maps",
                }
            }
        }
    },

    // For entries that are not present in our database
    "custom": {
        "something": "a/url", // The value can be simply a string
        "something": { // Or it can be a table
            "url": "a/url", // The URL value must be supplied
            "configuration": { // A configuration table is optional
                "key": "value"
            }
        }
    }
}
```

## For plugin developers
You should create a `plugin.json` file in your repositories.
See <link to correct lines in specs.norg> for more info.
