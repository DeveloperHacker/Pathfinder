
local Queue = dofile("std/queue.lua")
local Vector = dofile("math/vector.lua")
local event = require("event")
local logger = dofile("structs/logger.lua")

local Message = {}

function Message:new(name, from, args)
    local object = {
        name = name, 
        from = from, 
        args = args
    }
    self.__index = self
    return setmetatable(object, self)
end

function Message.valueOf(text)
    local args = split(text, " ")
    local name = args[1]
    if (name == "time") then
        if (#args ~= 3) then return nil end
        local remainig = tonumber(args[2])
        local total = tonumber(args[3])
        if (not total or not remainig) then return nil end
        return Message:new(name, "server", {remainig = remainig, total = total})
    elseif (name == "gamestart") then
        if (#args ~= 1) then return nil end
        return Message:new(name, "server", {})
    elseif (name == "gamestop") then
        if (#args ~= 1) then return nil end
        return Message:new(name, "server", {})
    elseif (name == "setcoin") then
        if (#args ~= 4) then return nil end
        local x = tonumber(args[2])
        local z = tonumber(args[3])
        local y = tonumber(args[4])
        if (not x or not y or not z) then return nil end
        return Message:new(name, "server", {position = Vector:new(x, y, z)})
    elseif (name == "unsetcoin") then
        if (#args ~= 4) then return nil end
        local x = tonumber(args[2])
        local z = tonumber(args[3])
        local y = tonumber(args[4])
        if (not x or not y or not z) then return nil end
        return Message:new(name, "server", {position = Vector:new(x, y, z)})   
    elseif (name == "sync") then
        if (#args ~= 5) then return nil end
        local from = args[2]
        local x = tonumber(args[3])
        local y = tonumber(args[4])
        local z = tonumber(args[5])
        if (not from or not x or not y or not z or not control or (control ~= x + y + z)) then return nil end
        return Message:new(name, from, {position = Vector:new(x, y, z)})
    else
        return nil
    end
end    

local Transmitter = {}

function Transmitter:new(serverPort, robotPort)
    local object = {
        modem = require("component").modem,
        serverPort = serverPort,
        robotPort = robotPort,
        messages = Queue:new()
    }
    object.modem.open(serverPort)
    object.modem.open(robotPort)
    event.listen("modem_message", self:listener())
    self.__index = self
    return setmetatable(object, self)
end

function Transmitter:sync(robotName, robotPositions, start, stop, coins)
    transmitter:sendSync(robotName, robotPositions[robotName])
    local messages = self.messages
    self.messages = Queue:new()
    local change = false
    for _, message in pairs(messages) do
        local name = message.name
        if (name == "sync") then
            robotPositions[message.from] = message.args.position
        elseif (name == "gamestart") then
            start = true
        elseif (name == "gamestop") then
            stop = true
        elseif (name == "setcoin") then
            local coin = message.args.position
            coins[coin:toString()] = coin
            change = true
        elseif (name == "unsetcoin") then
            local coin = message.args.position
            coins[coin:toString()] = nil
            change = true
        end
    end
    return robotPositions, start, stop, coins, change
end

function Transmitter:sendSync(robotName, position)
    self.modem.broadcast(self.robotPort, string.format("sync %s %d %d %d", robotName, position.x, position.y, position.z))
end

function Transmitter:listener()
    return function (event, rec_addr, from, port, distance, text)
        if (port == self.serverPort or port == self.serverPort) then
            local message = Message:valueOf(text)
            if (message == nil) then
                logger.info(string.format("Message \"%s\" have wrong format", text))
            end
            logger.message(text)
            self.messages:push(message)
        end
        event.listen("modem_message", self:listener())
    end
end

return Transmitter
