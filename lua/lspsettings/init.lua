local Config = require("lspsettings.config")
local JsonLoader = require("lspsettings.loader")
local Schemas = require("lspsettings.schemas")

local M = {}

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

    local patterns = vim.fn.map(
        config.paths,
        function(_, path)
            return vim.fs.joinpath(path, "*.json")
        end
    )

    vim.api.nvim_create_autocmd("BufWrite", {
        pattern = patterns,
        callback = function(event_data)
            local file = event_data.file
            local fname = vim.fs.basename(file)
            local server_name = fname:sub(1, -6)
            local settings = loader:load(server_name)
            config.on_update(server_name, settings)
        end
    })

    local schemas = Schemas:new()
    schemas:load()
    schemas:apply()
end

return M
