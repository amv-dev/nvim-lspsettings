--- @class Schemas
Schemas = {
    schemas = {}
}
Schemas.__index = Schemas

--- @return Schemas
function Schemas:new()
    local o = {
        schemas = {},
    }

    setmetatable(o, self)

    return o
end

--- @return string
function Schemas.default_path()
    local cache = vim.fn.stdpath('cache')
    return vim.fs.joinpath(cache, "lspsettings", "schemas.lua")
end

--- @param path string?
--- @param force boolean?
function Schemas.load(path, force)
    path = path or Schemas.default_path()
    force = force or false

    if vim.fn.filereadable(path) == 0 or force then
        local schemas = Schemas:new()
        schemas:scan()
        return schemas
    end

    local f = loadfile(path)

    if not f then
        return Schemas.load(path, true)
    end

    local schemas = Schemas:new()
    schemas.schemas = f()
    return schemas
end

--- Saves JSONLS schemas list into a `lua`-file
--- @param path string?
function Schemas:save(path)
    path = path or Schemas.default_path()

    vim.fn.mkdir(vim.fs.dirname(path), "p")

    local lines = vim.fn.split(vim.inspect(self.schemas), "\n")
    lines[1] = "return {"
    vim.fn.writefile(lines, path)
end

--- Scans `./schemas` directory and forms list of available schemas.
function Schemas:scan()
    local extensions = { "json", "json5", "jsonc" }
    local init_lua_path = debug.getinfo(1).source:sub(2)
    local lspsettings_path = vim.fs.dirname(init_lua_path)
    local lua_path = vim.fs.dirname(lspsettings_path)
    local plugin_path = vim.fs.dirname(lua_path)
    local schemas_path = vim.fs.joinpath(plugin_path, "schemas")

    local files = vim.fs.dir(schemas_path, {
        depth  = 1,
        follow = false,
    })

    for name, type in files do
        if type == "file" and name:sub(-5) == ".json" then
            local server_name = name:sub(1, -6)
            local file_path = vim.fs.abspath(vim.fs.joinpath(schemas_path, name))
            local matches = vim.fn.map(extensions, function(_, ext) return server_name .. "." .. ext end)

            self.schemas[server_name] = {
                fileMatch = matches,
                url = "/" .. file_path,
            }
        end
    end
end

--- Applies given schemas list to `jsonls`
function Schemas:apply()
    local config = require("lspsettings").config
    local extensions = config:extensions()

    vim.lsp.config('jsonls', {
        filetypes = extensions,
        settings = {
            json = { schemas = vim.tbl_values(self.schemas) },
        },
    })
end

return Schemas
