local Config = require("lspsettings.config")
local JsonLoader = require("lspsettings.loader")
local Schemas = require("lspsettings.schemas")

local M = {}

--- Cache JSONLS schemas list into a LUA-script for better performance
M.build = function()
    local schemas = Schemas:new()
    schemas:scan()
    schemas:save()
end

--- Setup to read from a settings file.
---@param opts lspsettings.types.config
M.setup = function(opts)
    local config = Config:new(opts)

    local loader = JsonLoader:new(config)

    -- Load configuration for each configurated LSP
    local servers = loader:list_configured_servers()
    for _, server_name in ipairs(servers) do
        local settings = loader:load(server_name)
        config.on_settings(server_name, settings)
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
            for _, path in ipairs(config.paths) do
                local file_path = vim.fs.joinpath(path, fname)

                -- Escape dot characters and produce correct pattern
                local file_path_pattern = string.gsub(file_path, "%.", "%%.") .. "$"

                if string.match(full_path, file_path_pattern) then
                    -- Path found. Reloading settings...
                    local settings = loader:load(server_name)
                    config.on_settings(server_name, settings)
                    break
                end
            end
        end
    })

    -- Configure LSP schemas for JSONLS
    local schemas = Schemas.load()
    schemas:apply()
end

return M
