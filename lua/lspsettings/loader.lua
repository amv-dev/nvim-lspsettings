--- Used for loading LSP settings from each JSON configuration file
--- Automatically merges all the plain configs into a single nested table
--- @class JsonLoader
JsonLoader = {
    --- @type Config?
    config = nil,
}

JsonLoader.__index = JsonLoader

--- @param config Config
--- @return JsonLoader
function JsonLoader:new(config)
    local o = {
        config = config,
    }

    setmetatable(o, self)

    return o
end

--- @param key string
--- @param value any
--- @param target table
local function set_key(key, value, target)
    local index = key:find('[\\.]')
    if index == nil then
        -- final level
        target[key] = value
        return
    end

    local head = key:sub(1, index - 1)
    local tail = key:sub(index + 1)

    target[head] = target[head] or {}

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

--- Lists all available server config in order they must be merged
--- @param server_name string
--- @return string[]
function JsonLoader:list_server_configs(server_name)
    local result = {}
    local paths = self.config.paths
    for _, path in ipairs(paths) do
        path = vim.fs.joinpath(path, server_name .. ".json")
        if vim.fn.filereadable(path) == 1 then
            table.insert(result, path)
        end
    end

    return result
end

--- @param server_name string
--- @return table
function JsonLoader:load(server_name)
    local datas = {}

    -- reading each config
    for _, path in ipairs(self:list_server_configs(server_name)) do
        local jsoned = table.concat(vim.fn.readfile(path))
        local success, data = pcall(vim.json.decode, jsoned)

        if success then
            table.insert(datas, data)
        else
            vim.notify("Unable to load LSP settings at `" .. path .. "`: " .. vim.inspect(data), vim.log.levels.WARN)
        end
    end

    -- merging all the configs into a single plain table
    local settings = vim.tbl_extend("force", {}, {}, unpack(datas))

    -- converting plain table into nested
    local nested = to_nested(settings)

    return nested
end

return JsonLoader
