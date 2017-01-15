
local Deque = dofile("std/deque.lua")

local Stack = {}

function Stack:new()
    local object = {
        _deque = Deque:new()
    }
    self.__index = self
    return setmetatable(object, self)
end

function Stack:push(value)
    return self._deque:leftPush(value)
end

function Stack:pull()
    return self._deque:leftPull(value)
end

function Stack:element()
    return self._deque:left()
end

function Stack:isEmpty()
    return self._deque:isEmpty()
end

function Stack:length()
    return self._deque:length()
end

function Stack:iterator()
    return self._deque:iterator()
end

function Stack:reverseIterator()
    return self._deque:reverseIterator()
end

return Stack
