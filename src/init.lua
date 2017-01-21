
local Robot = dofile("structs/robot.lua")
local Map = dofile("structs/map.lua")
local Way = dofile("structs/way.lua")
local Transmitter = dofile("structs/transmitter.lua")
local logger = dofile("structs/logger.lua")
local Stream = dofile("std/stream.lua")
local configurator = dofile("configurator.lua") 


local function sync(sleep, transmitter, name, position, finish)
    if (finish) then
        transmitter:send({"sync", name, position.x, position.y, position.z, finish.x, finish.y, finish.z}) 
    else
        transmitter:send({"sync", name, position.x, position.y, position.z}) 
    end
    os.sleep(sleep)
    return transmitter.sync:latch()
end

local function main(home_number, color)
    local config = configurator.config(home_number, color)
    local robot = Robot.load(config.robot)
    local map = Map.load(config.map)
    local name = config.robot.name
    local transmitter = Transmitter.load(config.transmitter)
    local home = config.main.homes[home_number]
    local base = config.main.base
    local homes = config.main.homes
    local direct = config.main.direct
    local averageStepTime = config.main.averageStepTime
    local averageCalcTime = config.main.averageCalcTime
    local data = transmitter.sync:latch()
    
    logger.info("init")

    while (not Stream.valueOf(data.syncs):all()) do
        data = sync(0.1, transmitter, name, robot.position)
    end
    
    logger.info("ready")
    
    while (not data.start) do
        data = sync(0.1, transmitter, name, robot.position)
    end
    data.stop = false
    transmitter.sync.data.stop = false

    logger.info("start")
    
    while (not data.stop) do
        local way = robot:optimal(map, base, data.coins, data.positions)
        local homedist = map:estiminateDisatence(way.finish, home, averageStepTime, 0)
        if (homedist > data.remainig) then break end
        local complite = robot:go(
            way, map,
            function (robot, way, map)
                data = sync(0.1, transmitter, name, robot.position)
                return robot:optimal(map, base, data.coins, data.positions)
            end,
            function (robot, way, it, map)
                if (it.index % 3) then
                    local position = robot.position
                    data = sync(0.1, transmitter, name, position)
                    local toBase = way.finish:equals(base)
                    if (toBase or data.coins[way.finish:toString()]) then
                        local distances = {}
                        local delete = nil
                        for key, pair in pairs(data.coins) do
                            local coin = pair[1]
                            local time = os.clock() - pair[2]
                            if (position:equals(coin)) then
                                transmitter:send({"sync", name, position.x, position.y, position.z, coin.x, coin.y, coin.z})
                                robot:suckDown()
                                delete = key
                            else
                                distances[key] = map:estiminateDisatence(robot.position, coin, time, averageCalcTime)
                            end
                        end
                        if (delete) then
                            data.coins[delete] = nil
                            transmitter.sync.data.coins[delete] = nil
                        end
                        local optimal, key = Stream.valueOf(distances):min()
                        local relevant = (toBase or (optimal < ((way:length() - it.index) * (os.clock() - data.coins[way.finish:toString()][2]))))
                        local homedist = map:estiminateDisatence(way.finish, home, averageStepTime, 0)
                        if (homedist <= data.remainig and optimal and relevant) then
                            local way = map:findWay(robot.position, data.coins[key][1], robot.direct)
                            return way, way:iterator()
                        else
                            return way, it
                        end
                    else
                        local way = robot:optimal(map, base, data.coins, data.positions)
                        return way, way: iterator()
                    end
                else
                    return way, it
                end
            end
        )
        if (complite) then robot:suckDown() end
        local key = way.finish:toString()
        data.coins[key] = nil
        transmitter.sync.data.coins[key] = nil
        if (way.finish:equals(base)) then robot:turn(direct) end
        data = sync(0.1, transmitter, name, robot.position, way.finish)
    end
    
    logger.info("collect")
    
    local i = home_number
    local complite = false
    while (not complite) do
        local home = homes[i]
        local way = map:findWay(robot.position, home, robot.direct)
        complite = robot:go(way, map)
        i = i % #(homes) + 1
    end
    robot:dropDown()
    
    logger.info("home")
    
    local way = map:findWay(robot.position, base, robot.direct)
    robot:go(way, map)
    robot:turn(direct)
    
    logger.info("stop")
    
    return 0
end

local home_number, color = ...
print(string.format("The program ended with the code %s", main(tonumber(home_number), color)))
