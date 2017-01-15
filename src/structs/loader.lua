
local Loader = {}

local space = " "
local comma = ","
local semicolon = ";"
local quote = "\""
local backSlash = "\\"

local punctuations = {space, comma, semicolon}

local function contains(table, value)
    for k, v in pairs(table) do
        if (v == value) then 
            return true
        end
    end
    return false
end

function Loader.arguments(path)
    local reader = io.open(path, "r")
    if (not reader) then
        error(string.format("Arguments file \"%s\" not found", path))
    end
    local tokens = {}
    local token = {}
    local inStr = false
    for line in reader:lines() do
        if (not line) then 
            break 
        end
        local prevCh = nil
        for i = 1, #line do
            local ch = line:sub(i, i)
            if (ch == quote and prevCh ~= backSlash) then
                inStr = not inStr
            else
                if (not inStr and contains(punctuations, ch)) then
                    if (#token > 0) then 
                        tokens[#tokens + 1] = table.concat(token, "")
                    end
                    token = {}
                else
                    token[#token + 1] = ch
                end
            end
            prevCh = ch
        end
        if (not inStr and #token > 0) then 
            tokens[#tokens + 1] = table.concat(token, "")
            token = {}
        end
    end
    assert(#token == 0)
    return tokens
end

return Loader
