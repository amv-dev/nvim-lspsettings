---@class lspsettings.types.config
---@field paths string|string[]?
---@field on_settings fun(server_name: string, settings: table): nil?

---@class lspsettings.default_config
---@field paths string|string[]
---@field on_settings fun(server_name: string, settings: table): nil

--- @class lspsettings.open_settings_args
--- @field server_name string?
--- @field path string?
