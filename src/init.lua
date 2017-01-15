
local Vector = dofile("math/vector.lua")
local Robot = dofile("structs/robot.lua")
local Direct = dofile("structs/direct.lua")
local Map = dofile("structs/map.lua")

local function main()
    local robot = Robot:load("robot.txt")
    local map = Map:load("map.txt")
    local home = robot.position
    local checkpoints = {
        home,
        Vector:new(391, 447, 55),
        Vector:new(390, 451, 56),
        Vector:new(392, 452, 57),
        Vector:new(390, 453, 55),
        Vector:new(395, 452, 56)
    }
    local traversal = map:findCheckpointTraversal(checkpoints)
    local it = traversal:iterator()
    while (it:hasNext()) do
        local way = it:next()
        local it = way:iterator()
        while (it:hasNext()) do
            if (not robot:go(it:next())) then
                it:back()
            end
        end
    end
    robot:turn(Direct.North)
    return 0
end

print(string.format("The program ended with the code %s", main()))
