--- Used for loading LSP settings from each JSON configuration file
--- Automatically merges all the plain configs into a single nested table
--- @class JsonLoader
JsonLoader = {
    --- @type Config?
    config = nil,
}

JsonLoader.__index = JsonLoader

--- Create new instance of `JsonLoader`
--- @param config Config
--- @return JsonLoader
function JsonLoader:new(config)
    local o = {
        config = config,
    }

    setmetatable(o, self)

    return o
end

--- Parses `key` and sets `value` with this key into `target` table as a nested value
--- @param key string
--- @param value any
--- @param target table
local function set_key(key, value, target)
    local index = key:find('%.')
    if index == nil then
        -- final level
        target[key] = value
        return
    end

    local head = key:sub(1, index - 1)
    local tail = key:sub(index + 1)

    if type(target[head]) ~= "table" then
        target[head] = {}
    end

    set_key(tail, value, target[head])
end

--- Converts plain table with key separated by dots to nested table
---
---@param plain table plain settings table
---@return table
local function to_nested(plain)
    local res = {}

    for key, value in pairs(plain) do
        set_key(key, value, res)
    end

    return res
end

--- Lists servers which have it's configuration files
--- @return string[]
function JsonLoader:list_configured_servers()
    local result = {}

    for _, dir in ipairs(self.config.paths) do
        for name, type in vim.fs.dir(dir, { follow = true }) do
            if type == "file" and name:sub(-5) == ".json" then
                local server_name = name:sub(1, -6)
                result[server_name] = true
            end
        end
    end

    return vim.tbl_keys(result)
end

--- Lists all available server configs in order they must be merged
--- @param server_name string
--- @return string[]
function JsonLoader:list_server_configs(server_name)
    local result = {}
    local paths = self.config.paths
    for _, dir_path in ipairs(paths) do
        local extensions = { ".json" }

        if self.config.json5 then
            table.insert(extensions, ".json5")
            table.insert(extensions, ".jsonc")
        end

        for _, extension in ipairs(extensions) do
            local file_path = vim.fs.joinpath(dir_path, server_name .. extension)
            if vim.fn.filereadable(file_path) == 1 then
                table.insert(result, file_path)
                break
            end
        end
    end

    return result
end

--- Loads settings for particular LSP `server_name` from all the paths and merges together
--- @param server_name string
--- @return table
function JsonLoader:load(server_name)
    local decode = vim.json.decode
    if self.config.json5 then
        decode = require("lspsettings.json5").decode
    end

    local settings = {}

    -- reading each config
    for _, path in ipairs(self:list_server_configs(server_name)) do
        local jsoned = table.concat(vim.fn.readfile(path), "\n")
        if jsoned ~= "" then
            local opts = { luanil = { object = true, array = true } }
            local success, data = pcall(decode, jsoned, opts)

            if success then
                settings = vim.tbl_extend("force", settings, data)
            else
                vim.notify("Unable to load LSP settings at `" .. path .. "`: invalid JSON", vim.log.levels.WARN)
            end
        end
    end

    -- converting plain table into nested
    local nested = to_nested(settings)

    return nested
end

return JsonLoader
