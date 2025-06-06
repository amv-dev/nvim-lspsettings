local Config = require("lspsettings.config")
local JsonLoader = require("lspsettings.loader")

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
end

return M
