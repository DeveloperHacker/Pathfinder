
local Deque = dofile("std/deque.lua")

local Queue = {}

function Queue:new()
    local object = {
        _deque = Deque:new()
    }
    self.__index = self
    return setmetatable(object, self)
end

function Queue:contains(value)
    return self._deque:contains(value)
end

function Queue:push(value)
    return self._deque:leftPush(value)
end

function Queue:pull()
    return self._deque:rightPull(value)
end

function Queue:element()
    return self._deque:right()
end

function Queue:isEmpty()
    return self._deque:isEmpty()
end

function Queue:toArray()
    return self._deque:toArray()
end

function Queue:length()
    return self._deque:length()
end

function Queue:iterator()
    return self._deque:iterator()
end

function Queue:reverseIterator()
    return self._deque:reverseIterator()
end

return Queue
