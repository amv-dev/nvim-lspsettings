# nvim-lspsettings. What's this plugin about

This plugin allowes you to customize LSP settings in `neovim` for each your project and globally in JSON format similar to VSCode.

# What this plugin offers you
1. Global LSP configuration
2. Customize configuration for LSPs for each your project similar to VSCode and `COC` / `coc-settings.json`
2. Autocompletion with description for most popular LSPs settings.
3. Compatibility with `VSCode` settings format.

# Requirements
* [Neovim v0.11.2 or higher](https://github.com/neovim/neovim/releases)
* [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig/)
* `jsonls` (optional, for settings autocompletion)

# Installation (Lazy nvim)

```lua
{
    "amv-dev/nvim-lspsettings",
    dependencies = {
        "neovim/nvim-lspconfig",
    },
    build = function() require("lspsettings").build() end,
    opts = {},
    event = "BufRead",
}
```

# Default plugin configuration options
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

    -- If settings found for the server, this function will be fired at startup
    on_init = function(server_name, settings)
        vim.lsp.config(server_name, { settings = settings })
    end,

    -- If settings were changed, this function will be fired
    on_update = function(server_name, settings)
        vim.lsp.config(server_name, { settings = settings })

        local servers = vim.lsp.get_clients({ name = server_name })

        if #servers > 0 then
            vim.cmd.LspRestart(server_name)
        end
    end,
}
```

# Settings example
## .vim/rust_analyzer.json
```json
{
    "rust-analyzer.checkOnSave": true,
    "rust-analyzer.check.features": ["my-feature"]
}
```

# Etc
This plugin is heavily inspired by [tamago324/nlsp-settings.nvim](https://github.com/tamago324/nlsp-settings.nvim) work. Unfortunately, it seems like it is no longer maintained.

I experienced several problems I want to fix:
1. Plugin does not work out of the box with neovim v0.11 .
2. Schemas for LSP settings options are not properly generated.
3. IMHO plugin is overcomplicated and hard to maintain for others due to lot of comments on japanese.

# TODO
1. Neovim docs
2. Neovim commands
