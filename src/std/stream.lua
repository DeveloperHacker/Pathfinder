
local Stream = {}

function Stream.deepcopy(orig)
    if (type(orig) == 'table') then
        local copy = {}
        for key, value in pairs(orig) do
            copy[Stream.deepcopy(key)] = Stream.deepcopy(value)
        end
        setmetatable(copy, Stream.deepcopy(getmetatable(orig)))
        return copy
    else
        return orig
    end
end

-- default: function Stream.replicate(value, quantity, generator = nil)
function Stream.replicate(value, quantity, generator)
    if (not generator) then
        return Stream.generate(function (i, key) return i <= quantity end, function (i) return i, value end)
    else
        return Stream.generate(function (i, key) return i <= quantity end, function (i) return generator(i, value), value end)
    end
end

function Stream.generate(condition, generator)
    local result = {}
    local i = 1
    local key = nil
    while (condition(i, key)) do
        local value
        key, value = generator(i)
        result[key] = value
        i = i + 1
    end
    return Stream:new(result)
end

function Stream:new(list)
    local object = {
        instance = list
    }
    self.__index = self
    return setmetatable(object, self)
end

function Stream.valueOf(iterable)
    if (Stream.isStream(iterable)) then
        return iterable
    elseif (type(iterable) == "table") then
        return Stream:new(Stream.deepcopy(iterable))
    elseif (type(iterable) == "string") then
        local list = {}
        for i = 1, #iterable do
            list[#list + 1] = iterable:sub(i, i)
        end
        return Stream:new(Stream.deepcopy(iterable))
    end
    error(string.format("Expected iterable type of variable \"but %s\"", type(iterable)))
end

function Stream.isStream(iterable)
    for name, attribute in pairs(Stream) do
        if (iterable[name] ~= attribute) then
            return false
        end
    end
    return true
end

function Stream:length()
    local length = 0
    for key, value in pairs(self.instance) do
        length = length + 1
    end
    return length
end

function Stream:reduce(reducor)
    return self:indexedReduce(function (result, key, value) return reducor(result, value) end)
end

function Stream:indexedReduce(reducor)
    local result = nil
    for key, value in pairs(self.instance) do
        if (not result) then 
            result = value
        else
            result = reducor(result, key, value)
        end
    end 
    return result
end

function Stream:map(mapper)
    return self:indexedMap(function (key, value) return mapper(value) end)
end

function Stream:indexedMap(mapper)
    local result = {}
    for key, value in pairs(self.instance) do
        result[key] = mapper(key, value)    
    end
    return Stream:new(result)
end

function Stream:filter(filtrator)
    return self:indexedFilter(function (key, value) return filtrator(value) end)
end

function Stream:indexedFilter(filtrator)
    local result = {}    
    for key, value in pairs(self.instance) do
        if (filtrator(key, value)) then
            result[key] = value
        end
    end
    return Stream:new(result)
end

function Stream:forEach(executor)
    return self:indexedForEach(function (key, value) executor(value) end)
end

function Stream:indexedForEach(executor)
    for key, value in pairs(self.instance) do
        executor(key, value)
    end
end

function Stream:replace(key, value)
    self.instance[key] = value
    return self
end

function Stream:toLine(shape)
    local length = Stream.valueOf(shape):product()
    local result = {}
    for i = 1, length do
        local tmp = i
        local instance = Stream.deepcopy(self.instance)
        for j = 1, #shape do
            instance = instance[tmp % shape[j] + 1]
            tmp = math.floor(tmp / shape[j])
        end
        result[#result + 1] = instance
    end
    return Stream:new(result)
end

function Stream:toTable()
    return self.instance
end

function Stream:product()
    return self:reduce(function (result, value) return result * value end)
end

function Stream:sum()
    return self:reduce(function (result, value) return result + value end)
end

function Stream:min()
    local min = nil
    local minKey = nil
    for key, value in pairs(self.instance) do
        if (not min or min > value) then
            min = value
            minKey = key
        end
    end 
    return min, minKey
end

function Stream:max()
    local max = nil
    local maxKey = nil
    for key, value in pairs(self.instance) do
        if (not max or max < value) then
            max = value
            maxKey = key
        end
    end 
    return max, maxKey
end

return Stream
