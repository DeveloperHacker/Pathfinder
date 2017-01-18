
local Leaf = {}

function Leaf:new(value)
    local object = {
        value = value,
        left = nil,
        right = nil
    }
    self.__index = self
    return setmetatable(object, self)
end

local Iterator = {}

function Iterator:new(current, reverse)
    local object = {
        current = current,
        reverse = reverse
    }
    self.__index = self
    return setmetatable(object, self)
end

function Iterator:next()
    assert(self:hasNext())
    local value = self.current.value
    if (self.reverse) then
        self.current = self.current.left
    else
        self.current = self.current.right
    end
    return value
end

function Iterator:hasNext()
    return self.current ~= nil
end

local Deque = {}

function Deque:new()
    local object = {
        _head = nil,
        _tail = nil,
        _length = 0
    }
    self.__index = self
    return setmetatable(object, self)
end

function Deque:length()
    return self._length
end

function Deque:contains(value)
    local it = self:iterator()
    while (it:hasNext()) do
        if (it:next() == value) then
            return true
        end
    end
    return false
end

function Deque:leftPush(value)
    local leaf = Leaf:new(value)
    if (self:isEmpty()) then
        self._head = leaf
        self._tail = leaf
    else
        self._head.left = leaf
        leaf.right = self._head
        self._head = leaf
    end
    self._length = self._length + 1
end

function Deque:leftPull()
    if (self:isEmpty()) then
        error("Allow error: deque is empty")
    else
        local leaf = self._head
        self._head = self._head.right
        self._length = self._length - 1
        leaf.left = nil
        leaf.right = nil
        if (self._head) then self._head.left = nil end
        return leaf.value
    end
end

function Deque:rightPush(value)
    local leaf = Leaf:new(value)
    if (self:isEmpty()) then
        self._head = leaf
        self._tail = leaf
    else
        self._tail.right = leaf
        leaf.left = self._tail
        self._tail = leaf
    end
    self._length = self._length + 1
end

function Deque:rightPull()
    if (self:isEmpty()) then
        error("Allow error: deque is empty")
    else
        local leaf = self._tail
        self._tail = self._tail.left
        self._length = self._length - 1
        leaf.left = nil
        leaf.right = nil
        if (self._tail) then self._tail.right = nil end
        return leaf.value
    end
end

function Deque:left()
    if (self:isEmpty()) then
        error("Allow error: deque is empty")
    else
        return self._head.value
    end
end

function Deque:right()
    if (self:isEmpty()) then
        error("Allow error: deque is empty")
    else
        return self._tail.value
    end
end

function Deque:toArray()
    local result = {}
    local leaf = self._head
    while (leaf) do
        result[#result + 1] = leaf.value
        leaf = leaf.right
    end
    return result
end

function Deque:isEmpty()
    return self._length == 0
end

function Deque:iterator()
    return Iterator:new(self._head, false)
end

function Deque:reverseIterator()
    return Iterator:new(self._tail, true)
end

return Deque
