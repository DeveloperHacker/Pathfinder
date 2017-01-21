
local ReverseIterator = {}

function ReverseIterator:new(steps)
    local object = {
        index = 0,
        steps = steps
    }
    self.__index = self
    return setmetatable(object, self)
end

function ReverseIterator:next()
    assert(self:hasNext())
    self.index = self.index + 1
    return self.steps[self.index]
end

function ReverseIterator:back()
    assert(self:hasBack())
    self.index = self.index - 1
    return self.steps[self.index]
end

function ReverseIterator:hasNext()
    return self.index < #(self.steps)
end

function ReverseIterator:hasBack()
    return self.index > 0
end

local Way = {}

function Way:new(start, finish)
    local object = {
        steps = {},
        start = start,
        finish = finish
    }
    self.__index = self
    return setmetatable(object, self)
end

function Way:get(index)
    return self.steps[index]
end

function Way:length()
    return #(self.steps)
end

function Way:append(step)
    self.steps[self:length() + 1] = step
end

function Way:toString()
    local result = {}
    for i, direct in pairs(self.steps) do
        result[#result + 1] = Direct.toString(direct)
    end
    return table.concat(result, ", ")
end

function Way:reverse()
    local length = self:length()
    for i = 1, math.floor(length / 2) do
        self.steps[i], self.steps[length - i + 1] = self.steps[length - i + 1], self.steps[i]
    end
    self.start, self.finish = self.finish, self.start
end

function Way:toString()
    local result = {}
    for i = 1, self:length() do
        result[#result + 1] = self.steps[i]:toString():sub(1, 1)
    end
    return table.concat(result, "")
end

function Way:iterator()
    return ReverseIterator:new(self.steps)
end

return Way
