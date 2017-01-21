local Vector = dofile("math/vector.lua")
local Direct = dofile("structs/direct.lua")
local Queue = dofile("std/queue.lua")
local Way = dofile("structs/way.lua")
local Loader = dofile("structs/loader.lua")

local Robot = {}

function Robot.load(config)
    local color = config.color
    local lightColor = config.lightColor
    local position = config.position
    local direct = config.direct
    local name = config.name
    return Robot:init(color, lightColor, position, direct, name)
end

function Robot:init(color, lightColor, position, direct, name)
    local object = {
        robot = require("robot"),
        position = position,
        direct = direct,
        name = name
    } 
    object.robot.setLightColor(lightColor)
    require("component").colors.setColor(color)
    self.__index = self
    return setmetatable(object, self)
end

function Robot:forward()
    local result = self.robot.forward()
    if (result) then
        self.position = self.position + self.direct
    end
    return result
end

function Robot:back()
    local result = self.robot.back()
    if (result) then
        self.position = self.position - self.direct
    end
    return result
end

function Robot:up()
    local result = self.robot.up()
    if (result) then
        self.position = self.position + Direct.Up
    end
    return result
end

function Robot:down()
    local result = self.robot.down()
    if (result) then
        self.position = self.position + Direct.Down
    end
    return result
end

function Robot:suck()
    return self.robot.suck()
end

function Robot:suckDown()
    return self.robot.suckDown()
end

function Robot:dropDown()
    return self.robot.dropDown()
end

function Robot:turnLeft()
    local result = self.robot.turnLeft()
    if (result) then
        self.direct = self.direct:left()
    end
    return result
end

function Robot:turnRight()
    local result = self.robot.turnRight()
    if (result) then
        self.direct = self.direct:right()
    end
    return result
end

function Robot:turnAround()
    local result = self.robot.turnAround()
    if (result) then
        self.direct = self.direct:back()
    end
    return result
end

function Robot:turn(direct)
    if (direct:equals(self.direct)) then 
        return true
    elseif (direct:equals(self.direct:left())) then  
        return self:turnLeft()
    elseif (direct:equals(self.direct:right())) then  
        return self:turnRight()
    elseif (direct:equals(self.direct:back())) then 
        return self:turnAround()
    else
        return false
    end
end

function Robot:go(way, map, regenerate, changeDesire)
    local removed = Queue:new()
    local it = way:iterator()
    local fine = 0
    while (it:hasNext()) do
        local direct = it:next()
        local result
        if (direct:equals(Direct.Up)) then
            result = not self.robot.detectUp() and self:up()
        elseif (direct:equals(Direct.Down)) then
            result = not self.robot.detectDown() and self:down()
        else
            result = self:turn(direct) and not self.robot.detect() and self:forward()
        end
        if (not result) then
            self:suck()
            local obstacle = self.position + direct
            if (way.finish:equals(obstacle)) then
                break
            end
            local block = map:remove(obstacle)
            removed:push({obstacle, block})
            if (regenerate) then
                way = regenerate(self, way, map)
            else
                way = map:findWay(self.position, way.finish, self.direct)
            end
            it = way:iterator()
            if (removed:length() > 2) then
                local pair = removed:pull()
                map:restore(table.unpack(pair))
            end
            fine = fine + 2
            if (fine > 6) then
                break
            end
        else
            if (changeDesire and it:hasNext()) then
                way, it = changeDesire(self, way, it, map)
            end
        end
        fine = (fine > 0) and (fine - 1) or fine
    end
    local it = removed:iterator()
    while (it:hasNext()) do
        map:restore(table.unpack(it:next()))
    end
    return self.position:equals(way.finish)
end

function Robot:optimal(map, base, coins, positions)
    positions[self.name] = self.position
    local min = nil
    local minWay = nil
    for _, pair in pairs(coins) do
        local coin = pair[1]
        local time = os.time() - pair[2]
        local way = map:findWay(self.position, coin, self.direct)
        local length = way:length() * time
        if (not min or min > length) then
            min = length
            minWay = way
        end
    end
    return minWay or map:findWay(self.position, base, self.direct)
end

return Robot
