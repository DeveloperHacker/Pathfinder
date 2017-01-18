
local Queue = dofile("std/queue.lua")
local Vector = dofile("math/vector.lua")
local Stream = dofile("std/stream.lua")
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
    local args = {}
    for token in string.gmatch(text, "%S+") do
        args[#args + 1] = token
    end
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
        if (not from or not x or not y or not z) then return nil end
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
        dump = Queue:new()
    }
    object.modem.open(serverPort)
    object.modem.open(robotPort)
    self.__index = self
    return setmetatable(object, self)
end

function Transmitter:messages()
    local messages = self.dump
    self.dump = Queue:new()
    return messages
end

function Transmitter:sync(robot, robotPositions, start, stop, coins, fully)
    robotPositions[robot.name] = robot.position
    local robots = {}
    for name, point in pairs(robots) do
        robots[name] = false
    end
    local sync = false
    local change = fully or false
    while (not sync) do
        local position = robotPositions[robot.name]
        self:send(self.robotPort, string.format("sync %s %d %d %d", robot.name, position.x, position.y, position.z)) 
        local it = self:messages():iterator()
        while (it:hasNext()) do
            local message = it:next()
            local name = message.name
            if (name == "sync") then
                robotPositions[message.from] = message.args.position
                robots[message.from] = true
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
        sync = not change or Stream.valueOf(robots):all()
        os.sleep(sync and 1 or 2)
    end
    return robotPositions, start, stop, coins, change
end

function Transmitter:send(port, text)
    self.modem.broadcast(port, text)
    logger.outputMessage(text)
end

function Transmitter:init()
    event.listen("modem_message", function (event, rec_addr, from, port, distance, text)
        if (port == self.robotPort or port == self.serverPort) then
            local message = Message.valueOf(text)
            if (message == nil) then
                logger.errorMessage(string.format("Message \"%s\" have wrong format", text))
            else
                if (message.from == "server") then
                    logger.inputServerMessage(text)
                else
                    logger.inputRobotMessage(text)
                end
                self.dump:push(message)
            end
        end
    end)
end

return Transmitter
