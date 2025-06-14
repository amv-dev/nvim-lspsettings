--- @param args vim.api.keyset.create_user_command.command_args
local function lsp_settings(args)
    local M = require("lspsettings")

    --- @param arg string
    --- @param target lspsettings.open_settings_args
    local function parse_argument(arg, target)
        if vim.lsp.config[arg] then
            target.server_name = arg
            return
        end

        local index = tonumber(arg)
        if arg == "global" then index = 0 end
        if index then
            if M.config.paths[index] then
                target.path = M.config.paths[index]
                return
            end
        end

        target.path = arg
    end

    --- @type lspsettings.open_settings_args
    local osf_args = {}
    for _, arg in ipairs(args.fargs) do
        parse_argument(arg, osf_args)
    end

    M.open_settings_file(osf_args)
end

local function install()
    vim.api.nvim_create_user_command(
        "LspSettings",
        lsp_settings,
        {
            nargs = '*',
            desc = "Open LSP settings file",
        }
    )
end

return {
    install = install,
}
