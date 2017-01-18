
local Robot = dofile("structs/robot.lua")
local Map = dofile("structs/map.lua")
local Way = dofile("structs/way.lua")
local Transmitter = dofile("structs/transmitter.lua")
local logger = dofile("structs/logger.lua")
local Stream = dofile("std/stream.lua")

local function main()
    local computer = require("computer")
    print(string.format("memory:    %6d / %6d", computer.freeMemory(), computer.totalMemory()))
    local transmitter = Transmitter:new(12345, 200)
    transmitter:init()
    local config = dofile("config.lua")
    local robot = Robot:load(config.robot)
    local map = Map:load(config.map)
    local robotNames = config.main.robotNames
    local home = robot.position
    local base = config.main.base
    local baseDirect = config.main.baseDirect
    local roundTime = config.main.roundTime
    local averageStepTime = config.main.averageStepTime
    local robotPositions = {}
    local start = false
    local stop = false
    local coins = {}
    logger.info("init")
    robotPositions, start, stop, coins, change = transmitter:sync(robot, robotPositions, start, stop, coins, true)
    logger.info("ready")
    while (not start) do
        robotPositions, start, stop, coins, change = transmitter:sync(robot, robotPositions, start, stop, coins)
        os.sleep(2)
    end
    local startTime = os.clock()
    logger.info("start")
    local homepath = Way:new()
    while ((homepath:length() * 2 * averageStepTime) < (roundTime - os.clock() - startTime)) do
        local robotCoins = map:subCoins(coins, robotPositions)
        local checkpoints = robotCoins[robot.name]
        if (#checkpoints > 0) then
            table.insert(checkpoints, 1, robot.position)
            local traversal = map:findCheckpointTraversal(checkpoints)
            local it = traversal:iterator()
            while (it:hasNext()) do
                local way = it:next()
                local complite = robot:go(way, map)
                robotPositions, start, stop, coins, change = transmitter:sync(robot, robotPositions, start, stop, coins)
                if (change) then break end
                if (not complite and it:hasNext()) then
                    
                end
            end
        else
            local way = map:findWay(robot.position, base, robot.direct)
            robot:go(way, map)
            robot:turn(baseDirect)
            robotPositions, start, stop, coins, change = transmitter:sync(robot, robotPositions, start, stop, coins, true)
        end
        homepath = map:findWay(robot.position, home, robot.direct)
    end
    logger.info("home")
    robot:go(homepath, map)
    logger.info("stop")
    return 0
end

print(string.format("The program ended with the code %s", main()))
