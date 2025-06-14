local Config = require("lspsettings.config")
local JsonLoader = require("lspsettings.loader")
local Schemas = require("lspsettings.schemas")
local commands = require('lspsettings.commands')

local M = {
    config = Config:new(),
}

--- Cache JSONLS schemas list into a LUA-script for better performance
M.build = function()
    local schemas = Schemas:new()
    schemas:scan()
    schemas:save()
end

--- Opens LSP settings file
--- @param args lspsettings.open_settings_args?
M.open_settings_file = function(args)
    --- @return string?
    local function get_current_server_name()
        local current_lsp = vim.lsp.get_clients({ bufnr = 0 })[1]
        if not current_lsp then
            return
        end

        return current_lsp.name
    end

    --- @param server_name string?
    --- @return string?
    local function parse_server_name(server_name)
        server_name = server_name or get_current_server_name()

        if not server_name then
            vim.notify("No current LSP attached", vim.log.levels.ERROR)
            return
        end

        if not vim.lsp.config[server_name] then
            vim.notify("LSP `" .. server_name .. "` is not configured", vim.log.levels.ERROR)
            return
        end

        return server_name
    end

    --- @param path string?
    --- @return string?
    local function parse_path(path)
        local paths = M.config.paths
        path = path or paths[#paths]
        for _, cfg_path in ipairs(M.config.paths) do
            if cfg_path == path then
                return path
            end
        end

        vim.notify("Invalid settings path", vim.log.levels.ERROR)
    end

    args = args or {}
    local server_name = parse_server_name(args.server_name)
    if not server_name then return end

    local path = parse_path(args.path)
    if not path then return end

    vim.fn.mkdir(path, "p")
    vim.cmd.edit(vim.fs.joinpath(path, server_name .. ".json"))
end

--- Setup to read from a settings file.
---@param opts lspsettings.types.config
M.setup = function(opts)
    M.config:extend(opts)

    local loader = JsonLoader:new(M.config)

    -- Load configuration for each configurated LSP
    local servers = loader:list_configured_servers()
    for _, server_name in ipairs(servers) do
        local settings = loader:load(server_name)
        M.config.on_settings(server_name, settings)
    end

    -- Bind callback to watch changes in configuration files
    vim.api.nvim_create_autocmd("BufWritePost", {
        pattern = "*.json",
        callback = function(event_data)
            local full_path = event_data.match
            local relative_path = event_data.file
            local fname = vim.fs.basename(relative_path)

            local server_name = fname:sub(1, -6)

            -- Check that this `server_name` really exists
            if not vim.lsp.config[server_name] then
                return
            end

            -- Check if file is really in config paths
            for _, path in ipairs(M.config.paths) do
                local file_path = vim.fs.joinpath(path, fname)

                -- Escape dot characters and produce correct pattern
                local file_path_pattern = string.gsub(file_path, "%.", "%%.") .. "$"

                if string.match(full_path, file_path_pattern) then
                    -- Path found. Reloading settings...
                    local settings = loader:load(server_name)
                    M.config.on_settings(server_name, settings)
                    break
                end
            end
        end
    })

    -- Configure LSP schemas for JSONLS
    local schemas = Schemas.load()
    schemas:apply()

    commands.install()
end

return M
