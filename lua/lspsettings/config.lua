--- @class Config
Config = {
    paths = {
        vim.fs.joinpath(vim.fn.stdpath('config'), "lspsettings"),
        -- compatibility with `nlsp-settings` plugin
        vim.fs.joinpath(vim.fn.stdpath('config'), "nlsp-settings"),
        -- compatibility with `vscode`
        ".vscode",
        -- compatibility with `nlsp-settings` plugin
        ".nlsp-settings",
        ".vim",
    },
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

Config.__index = Config

--- Creates default config
--- If `opts` provided, then extends default config with given options
--- @param opts lspsettings.types.config?
--- @return Config
function Config:new(opts)
    local o = {}

    setmetatable(o, self)

    if opts then o:extend(opts) end

    return o
end

--- Extend config with given values
--- @param opts lspsettings.types.config
--- @return nil
function Config:extend(opts)
    opts = opts or {}

    for key, value in pairs(opts) do
        self[key] = value
    end

    if type(self.paths) == "string" then
        self.paths = { self.paths }
    end
end

return Config
