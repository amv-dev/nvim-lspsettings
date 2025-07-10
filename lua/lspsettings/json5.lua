---@diagnostic disable: lowercase-global

--- @param str string Stringified JSON5 data
--- @param opts table<string,any> Options similar to `vim.json.decode`. Not used for now
---@diagnostic disable-next-line: unused-local
local function decode(str, opts)
    local function tokenize(input)
        local tokens = {}
        local i = 1
        local len = #input

        local function skip_whitespace()
            while i <= len do
                local c = input:sub(i, i)
                if c:match("[%s\n\r\t]") then
                    i = i + 1
                elseif c == "/" and input:sub(i + 1, i + 1) == "/" then
                    i = i + 2
                    while i <= len and input:sub(i, i) ~= "\n" do
                        i = i + 1
                    end
                elseif c == "/" and input:sub(i + 1, i + 1) == "*" then
                    i = i + 2
                    while i <= len - 1 and not (input:sub(i, i + 1) == "*/") do
                        i = i + 1
                    end
                    i = i + 2
                else
                    break
                end
            end
        end

        local function read_line(quote)
            i = i + 1
            local output = ""
            while i <= len do
                local c = input:sub(i, i)
                if c == "\\" then
                    local nextc = input:sub(i + 1, i + 1)
                    if nextc == "n" then
                        output = output .. "\n"
                    elseif nextc == "t" then
                        output = output .. "\t"
                    elseif nextc == "r" then
                        output = output .. "\r"
                    elseif nextc == quote then
                        output = output .. quote
                    else
                        output = output .. nextc
                    end
                    i = i + 2
                elseif c == quote then
                    i = i + 1
                    break
                else
                    output = output .. c
                    i = i + 1
                end
            end
            return { type = "string", value = output }
        end

        local function read_number()
            local start = i
            while i <= len and input:sub(i, i):match("[%+%-%.%deE]") do
                i = i + 1
            end
            local num_str = input:sub(start, i - 1)
            if num_str == "NaN" then
                return { type = "number", value = 0 / 0 }
            elseif num_str == "Infinity" or num_str == "+Infinity" then
                return { type = "number", value = math.huge }
            elseif num_str == "-Infinity" then
                return { type = "number", value = -math.huge }
            else
                return { type = "number", value = tonumber(num_str) }
            end
        end

        local function read_identifier()
            local start = i
            while i <= len and input:sub(i, i):match("[%w%$_]") do
                i = i + 1
            end
            local word = input:sub(start, i - 1)
            if word == "true" then
                return { type = "boolean", value = true }
            elseif word == "false" then
                return { type = "boolean", value = false }
            elseif word == "null" then
                return { type = "null", value = nil }
            elseif word == "NaN" or word == "Infinity" or word == "-Infinity" then
                i = start
                return read_number()
            else
                return { type = "identifier", value = word }
            end
        end

        while i <= len do
            skip_whitespace()
            local c = input:sub(i, i)
            if c == "" then
                break
            elseif c == "{" or c == "}" or c == "[" or c == "]" or c == ":" or c == "," then
                table.insert(tokens, { type = "symbol", value = c })
                i = i + 1
            elseif c == '"' or c == "'" then
                table.insert(tokens, read_line(c))
            elseif c:match("[%+%-%.%d]") then
                table.insert(tokens, read_number())
            elseif c:match("[%a$_]") then
                table.insert(tokens, read_identifier())
            else
                error("Unexpected character: " .. c)
            end
        end

        return tokens
    end

    local function parse(tokens)
        local pos = 1

        local function peek() return tokens[pos] end
        local function next_tok()
            local token = peek()
            pos = pos + 1
            return token
        end

        local function parse_value()
            local token = peek()
            if not token then error("Unexpected end") end
            if token.type == "string" or token.type == "number" or token.type == "boolean" or token.type == "null" then
                return next_tok().value
            elseif token.value == "{" then
                return parse_object()
            elseif token.value == "[" then
                return parse_array()
            elseif token.type == "identifier" then
                return next_tok().value
            else
                error("Unexpected token: " .. token.value)
            end
        end

        function parse_array()
            local result = {}
            assert(next_tok().value == "[")
            while peek() and peek().value ~= "]" do
                table.insert(result, parse_value())
                if peek().value == "," then next_tok() end
            end
            assert(next_tok().value == "]")
            return result
        end

        function parse_object()
            local result = {}
            assert(next_tok().value == "{")
            while peek() and peek().value ~= "}" do
                local key_token = next_tok()
                local key
                if key_token.type == "string" or key_token.type == "identifier" then
                    key = key_token.value
                else
                    error("Invalid object key")
                end
                assert(next_tok().value == ":")
                local val = parse_value()
                result[key] = val
                if peek().value == "," then next_tok() end
            end
            assert(next_tok().value == "}")
            return result
        end

        return parse_value()
    end

    local tokens = tokenize(str)

    return parse(tokens)
end


return {
    decode = decode,
}
