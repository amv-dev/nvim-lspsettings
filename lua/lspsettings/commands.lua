--- LspSettings command
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
        if arg == "global" then index = 1 end
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

--- Autocompletion for `LspSettings` arguments
---@diagnostic disable-next-line: unused-local
local function lsp_settings_cmp(_ArgLead, _CmdLine, _CursorPos)
    local M = require("lspsettings")

    local variants = {
        "global",
    }

    local client = vim.lsp.get_clients({ bufnr = 0 })[1]
    if client then
        table.insert(variants, client.name)
    end

    for i, _ in ipairs(M.config.paths) do
        table.insert(variants, tostring(i))
    end

    -- FIXME: need to find a correct way to list all configured LSPs
    for server_name in pairs(vim.lsp._enabled_configs) do
        table.insert(variants, server_name)
    end

    return variants
end

local function define()
    vim.api.nvim_create_user_command(
        "LspSettings",
        lsp_settings,
        {
            nargs = '*',
            desc = "Open LSP settings file",
            complete = lsp_settings_cmp,
        }
    )
end

return {
    define = define,
}
