local Config = require("lspsettings.config")
local JsonLoader = require("lspsettings.loader")
local Schemas = require("lspsettings.schemas")

local M = {}

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

    local servers = loader:list_configured_servers()

    for _, server_name in ipairs(servers) do
        local settings = loader:load(server_name)
        config.on_init(server_name, settings)
    end

    vim.api.nvim_create_autocmd("BufWritePost", {
        pattern = "*.json",
        callback = function(event_data)
            local full_path = event_data.match
            local relative_path = event_data.file
            local fname = vim.fs.basename(relative_path)

            for _, path in ipairs(config.paths) do
                local file_path = vim.fs.joinpath(path, fname)
                if string.match(full_path, file_path .. "$") then
                    local server_name = fname:sub(1, -6)
                    local settings = loader:load(server_name)
                    config.on_update(server_name, settings)
                    break
                end
            end
        end
    })

    local schemas = Schemas.load()
    schemas:apply()
end

return M
