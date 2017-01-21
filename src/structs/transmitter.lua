
local Queue = dofile("std/queue.lua")
local Vector = dofile("math/vector.lua")
local Stream = dofile("std/stream.lua")
local event = require("event")
local logger = dofile("structs/logger.lua")
local serialization = require("serialization")

local SyncData = {}

function SyncData:new(data)
    local object = {
        data = data
    }
    self.__index = self
    return setmetatable(object, self)
end

function SyncData:latch()
    local data = {}
    for name, value in pairs(self.data) do
        data[name] = value
    end
    return data
end

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

function Message.valueOf(args)
    local name = args[1]
    if (name == "time") then
        if (#args ~= 3) then return nil end
        local remainig = tonumber(args[2])
        local total = tonumber(args[3])
        if (not total or not remainig) then return nil end
        return Message:new(name, "server", {remainig = remainig, total = total, clock = os.clock()})
    elseif (name == "gamestart") then
        if (#args ~= 1) then return nil end
        return Message:new(name, "server", {})
    elseif (name == "gamestop") then
        if (#args ~= 1) then return nil end
        return Message:new(name, "server", {})
    elseif (name == "setcoin") then
        if (#args ~= 4) then return nil end
        local x = tonumber(args[2])
        local z = tonumber(args[3]) + 1
        local y = tonumber(args[4])
        if (not x or not y or not z) then return nil end
        return Message:new(name, "server", {position = Vector:new(x, y, z)})
    elseif (name == "unsetcoin") then
        if (#args ~= 4) then return nil end
        local x = tonumber(args[2])
        local z = tonumber(args[3]) + 1
        local y = tonumber(args[4])
        if (not x or not y or not z) then return nil end
        return Message:new(name, "server", {position = Vector:new(x, y, z)})   
    elseif (name == "sync") then
        if (#args ~= 5 and #args ~= 8) then return nil end
        local from = args[2]
        if (not from) then return nil end
        local x = tonumber(args[3])
        local y = tonumber(args[4])
        local z = tonumber(args[5])
        if (not x or not y or not z) then return nil end
        local position = Vector:new(x, y, z)
        local x = tonumber(args[6])
        local y = tonumber(args[7])
        local z = tonumber(args[8])
        local coin = nil 
        if (x and y and z) then 
            coin = Vector:new(x, y, z)
        end
        return Message:new(name, from, {position = position, coin = coin})
    else
        return nil
    end
end    

local Transmitter = {}

function Transmitter.load(config)
    local syncs = {}
    for _, name in pairs(config.names) do syncs[name] = false end
    local data = {
        ["coins"] = {},
        ["positions"] = {},
        ["syncs"] = syncs,
        ["start"] = false,
        ["stop"] = false,
        ["remainig"] = 1/0
    }
    return Transmitter:new(config.server, config.robot, data):init()
end

function Transmitter:new(server, robot, data)
    local object = {
        modem = require("component").modem,
        server = server,
        robot = robot,
        sync = SyncData:new(data)
    }
    self.__index = self
    return setmetatable(object, self)
end

function Transmitter:send(args)
    self.modem.broadcast(self.robot, table.unpack(args))
    logger.outputMessage(table.concat(args, ", "))
end

function Transmitter:update(message)
    local name = message.name
    if (name == "sync") then
        self.sync.data.positions[message.from] = message.args.position
        self.sync.data.syncs[message.from] = true
        local coin = message.args.coin
        if (coin) then
            self.sync.data.coins[coin:toString()] = nil
        end
    elseif (name == "gamestart") then
        self.sync.data.start = true
    elseif (name == "gamestop") then
        self.sync.data.stop = true
    elseif (name == "setcoin") then
        local coin = message.args.position
        self.sync.data.coins[coin:toString()] = {coin, os.clock()}
    elseif (name == "unsetcoin") then
        local coin = message.args.position
        self.sync.data.coins[coin:toString()] = nil
    elseif (name == "time") then
        self.sync.data.remainig = message.args.remainig - (os.clock() - message.args.clock)
    end
end

function Transmitter:init()
    self.modem.open(self.server)
    self.modem.open(self.robot)
    event.listen("modem_message", function (...)
        local recv = {...}
        local port = recv[4]
        local args = {}
        for i, arg in pairs(recv) do
            if (i > 5) then 
                args[#args + 1] = arg
            end
        end
        local text = table.concat(args, ", ")
        if (port == self.robot or port == self.server) then
            local message = Message.valueOf(args)
            if (not message) then
                logger.errorMessage(string.format("Message \"%s\" have wrong format", text))
            else
                if (message.from == "server") then
                    logger.inputServerMessage(text)
                else
                    logger.inputRobotMessage(text)
                end
                self:update(message)
            end
        end
    end)
    return self
end

return Transmitter
