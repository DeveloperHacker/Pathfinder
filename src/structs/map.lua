
local Vector = dofile("math/vector.lua")
local Loader = dofile("structs/loader.lua")
local Queue = dofile("std/queue.lua")
local Stack = dofile("std/stack.lua")
local Direct = dofile("structs/direct.lua")
local Way = dofile("structs/way.lua")
local Graph = dofile("math/graph.lua")

local Block = {}

function Block:new(value, direct, navigation)
    local object = {
        value = value,
        direct = direct,
        navigation = navigation
    }
    self.__index = self
    return setmetatable(object, self)
end

local Map = {}

local inf = 1/0

function Map:init(position, size, blocks, rootOfWaves)
    local object = {
        position = position,
        size = size,
        blocks = blocks,
        rootOfWaves = rootOfWaves,
        changed = true
    }
    self.__index = self
    return setmetatable(object, self)
end

function Map.load(config)
    local position = config.position
    local size = config.size
    local blocks = {}
    assert(#(config.blocks) == size.x * size.y * size.z)
    for i = 1, #(config.blocks) do
        if (config.blocks[i] == 0) then
            blocks[i] = Block:new(inf, Vector.zero(), Vector.zero())
        elseif (config.blocks[i] == 1) then
            blocks[i] = nil
        else
            error(string.format("Undefound map token %s", config.blocks[i]))
        end
    end
    return Map:init(position, size, blocks, nil)
end

function Map:repair()
    for _, block in pairs(self.blocks) do
        block.value = inf
        block.direct = Vector.zero()
        block.navigation = Vector.zero()
    end
    self.rootOfWaves = nil
    self.changed = true
end

function Map:index(point)
    point = point - self.position
    return Map.index3D(point.x, point.y, point.z, self.size.x, self.size.y)
end

function Map.index2D(x, y, w)
    return y * w + x + 1
end

function Map.index3D(x, y, z, w, h)
    return (z * h + y) * w + x + 1    
end

function Map:get(point)
    if (not self:contains(point)) then return nil end
    return self.blocks[self:index(point)]
end

function Map:_set(point, value, direct, navigation)
    if (not self:contains(point)) then return false end
    local block = self.blocks[self:index(point)]
    block.value = value
    block.direct = direct
    block.navigation = navigation
    return true
end

function Map:remove(point)
    if (not self:contains(point)) then return nil end
    local index = self:index(point)
    local block = self.blocks[index]
    self.blocks[index] = nil
    self.changed = true
    return block
end

function Map:restore(point, block)
    if (not self:contains(point)) then return false end
    self.blocks[self:index(point)] = block
    self.changed = true
    return true
end

function Map:contains(point)
    return (self.position.x <= point.x) and (point.x < (self.position.x + self.size.x)) and
           (self.position.y <= point.y) and (point.y < (self.position.y + self.size.y)) and
           (self.position.z <= point.z) and (point.z < (self.position.z + self.size.z))
end

function Map:waveization(root, direct)
    self:repair()
    self.rootOfWaves = root
    self:_set(root, 0, direct, Vector.zero())
    local queue = Queue:new()
    queue:push(root)
    local around = {Direct.North, Direct.South, Direct.West, Direct.East, Direct.Up, Direct.Down}
    while (not queue:isEmpty()) do
        local current = queue:pull()
        local currentBlock = self:get(current)
        for i = 1, #around do
            local navigation = around[i]
            local path = current + navigation
            local fine = currentBlock.value + 1
            if (navigation.z == 0) then
                fine = fine + (currentBlock.direct - navigation):sabs() / 2
            end
            local block = self:get(path)
            if (block and fine < block.value) then
                local direct = navigation.z == 0 and navigation or currentBlock.direct
                self:_set(path, fine, direct, navigation)
                if (not queue:contains(path)) then
                    queue:push(path)
                end
            end
        end
    end
end

function Map:findWay(start, finish, direct)
    if (not self:get(start)) then return nil end
    if (not self:get(finish)) then return nil end
    if ((start - finish):sabs() == 0) then return Way:new(start, finish) end
    if self.changed or not self.rootOfWaves:equals(start) then
        self:waveization(start, direct) 
    end
    if (self:get(finish) == inf) then
        return nil
    end
    local current = finish
    local way = Way:new(finish, start)
    while (not current:equals(start)) do
        local navigation = self:get(current).navigation
        way:append(navigation)
        current = current - navigation
    end
    way:reverse()
    return way
end

function Map:findCheckpointTraversal(checkpoints)
    local ways = {}
    local graph = {}
    local numCheckpoints = #checkpoints
    for i = 1, numCheckpoints do
        ways[i] = {}
        graph[i] = {}
    end
    for i = 1, numCheckpoints do
        for j = 1, numCheckpoints do
            if (i == j) then
                graph[i][j] = inf
            else 
                local way = self:findWay(checkpoints[j], checkpoints[i], Vector.zero())
                local length = way:length()
                ways[i][j] = way
                graph[i][j] = length
            end
        end
    end
    local V, links = Graph.mfae(graph)
    local transitions = Graph.forbidden(links)
    assert(#transitions == 1)
    local transition = transitions[1]
    while (transition:right() ~= 1) do
    	transition:rightPush(transition:leftPull())
    end
    local prev = transition:right()
    local traversal = Queue:new()
    local it = transition:iterator()
    while (it:hasNext()) do
        local cur = it:next()
    	traversal:push(ways[prev][cur])
        prev = cur
    end
    return traversal
end

function Map:subCoins(coins, postions, name)
    local robotCoins = {}
    local robotNumCoins = {}
    local numCoins = 0
    for _, _ in pairs(coins) do
        numCoins = numCoins + 1
    end
    for name, _ in pairs(postions) do
        robotCoins[name] = coins
        robotNumCoins[name] = numCoins
    end
    return robotCoins[name], robotNumCoins[name]
end

function Map:estiminateDisatence(start, finish, timesFine, appendFine)
    local direct = finish - start
    return (math.abs(direct.x) + math.abs(direct.y) + math.abs(direct.z)) * timesFine + appendFine
end

return Map
