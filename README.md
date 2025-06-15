# nvim-lspsettings

This plugin allowes you to customize LSP settings in `neovim` for each your project and globally in JSON format similar to VSCode.

## What this plugin offers you
1. Global LSP configuration
2. Customize configuration for LSPs for each your project similar to VSCode and `COC` / `coc-settings.json`
3. Autocompletion with description for most popular LSPs settings.
4. Compatibility with `VSCode` settings format.
5. Easy & flexible configuration

## Requirements
* [Neovim v0.11.2 or higher](https://github.com/neovim/neovim/releases)
* [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig/)
* `jsonls` (optional, for settings autocompletion)

## Installation (Lazy nvim)

```lua
{
    "amv-dev/nvim-lspsettings",
    dependencies = {
        "neovim/nvim-lspconfig",
    },
    opts = {},
    event = "BufRead",
}
```

## Default plugin configuration options
```lua
{
    -- Paths where JSON cofiguration will be searched
    -- Order matters. All the settings will be merged from top to bottom.
    paths = {
        vim.fn.stdpath('config') .. "/lspsettings"),
        -- compatibility with `nlsp-settings` plugin
        vim.fn.stdpath('config') .. "/nlsp-settings"),
        -- compatibility with `vscode`
        ".vscode",
        -- compatibility with `nlsp-settings` plugin
        ".nlsp-settings",
        ".vim",
    },

    -- This function will fire on LSP start or on settings file change
    on_settings = function(server_name, settings)
        if vim.deep_equal(vim.lsp.config[server_name].settings, settings) then
            -- Nothing changed, just quit
            return
        end

        vim.lsp.config(server_name, { settings = settings })

        local servers = vim.lsp.get_clients({ name = server_name })

        if #servers == 0 then return end

        -- restart server if it's already running
        vim.cmd.LspRestart(server_name)
    end,
}
```

## Configuration with custom callback 
Here is an example with custom `on_settings` callback, which calls default `on_settings` first and then shows notification.
```lua
{
    on_settings = function(server_name, settings)
        local Config = require('lspsettings.config')
        Config.on_settings(server_name, settings) -- default callback

        vim.notify("Settings changed")
    end,
}
```
Of course, you can totally rewrite `on_settings` on your own without calling default implementation.

## LSP Settings example

`.vim/rust_analyzer.json`
```json
{
    "rust-analyzer.checkOnSave": true,
    "rust-analyzer.check.features": ["my-feature"]
}
```

## Commands

### LspSettings
Takes 0, 1 or 2 arguments

If no arguments provided, then opens local settings file for LSP for the current buffer

Each argument may be server name, path from config or path index from config. Example:
```
LspSettings rust_analyzer # opens local settings for `rust_analyzer`
LspSettings 0 rust_analyzer # opens global settings for `rust_analyzer`
LspSettings 0 # opens global settings for current buffer server
LspSettings global # same
LspSettings # opens local settings for current buffer server
```

# Other information
This plugin is heavily inspired by [tamago324/nlsp-settings.nvim](https://github.com/tamago324/nlsp-settings.nvim) work. Unfortunately, it seems like it is no longer maintained.

I experienced several problems I want to fix:
1. Plugin does not work out of the box with neovim v0.11 .
2. Schemas for LSP settings options are not properly generated.
3. IMHO plugin is overcomplicated and hard to maintain for others due to lot of comments on japanese.

# TODO
* [ ] Neovim docs
* [x] Neovim commands
