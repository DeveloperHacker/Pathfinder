
local Robot = dofile("structs/robot.lua")
local Map = dofile("structs/map.lua")
local Transmitter = dofile("structs/transmitter.lua")
local logger = dofile("structs/logger.lua")
local Stream = dofile("std/stream.lua")

local function main()
    local transmitter = Transmitter:new(100, 200)

    local config = dofile("config.lua")
    local robot = Robot:load(config.robot)
    local map = Map:load(config.map)
    local robotNames = config.main.robotNames
    local home = robot.position
    local base = config.main.base
    local baseDirect = config.main.baseDirect
    -- local checkpoints = {
    --     home,
    --     Vector:new(391, 447, 55),
    --     Vector:new(390, 451, 56),
    --     Vector:new(392, 452, 57),
    --     Vector:new(390, 453, 55),
    --     Vector:new(395, 452, 56)
    -- }
    local robotPositions = {}
    local start = false
    local stop = false
    local coins = {}
    local robots = Stream.valueOf(robotNames):reformat(function (value) return value, false end):toTable()
    while (not Stream.valueOf(robots):all()) do
        robotPositions[robot.name] = robot.position
        robotPositions, start, stop, coins, change = transmitter:sync(robot.name, robotPositions, start, stop, coins)
        for name, position in pairs(robotPositions)
            robots[name] = true
        end
    end
    logger.info("ready")
    while (not start) do
        robotPositions[robot.name] = robot.position
        robotPositions, start, stop, coins, change = transmitter:sync(robot.name, robotPositions, start, stop, coins)
    end
    logger.info("start")
    while (not stop) do
        local robotCoins = map:subCoins(coins, robotPositions)
        local checkpoints = robotCoins[robot.name]
        if (#checkpoints > 0) then
            table.insert(checkpoints, 1, robot.position)
            local traversal = map:findCheckpointTraversal(checkpoints)
            local it = traversal:iterator()
            while (it:hasNext()) do
                local way = it:next()
                robot:go(way, map)
                robotPositions[robot.name] = robot.position
                robotPositions, start, stop, coins, change = transmitter:sync(robot.name, robotPositions, start, stop, coins)
                if (change) then break end
            end
        else
            local way = map:findWay(robot.position, base, robot.direct)
            robot:go(way, map)
            robot:turn(baseDirect)
            change = false
            while (not change) do
                robotPositions[robot.name] = robot.position
                robotPositions, start, stop, coins, change = transmitter:sync(robot.name, robotPositions, start, stop, coins)
            end
        end
    end
    logger.info("stop")
    return 0
end

print(string.format("The program ended with the code %s", main()))
