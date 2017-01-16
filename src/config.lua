
local Vector = dofile("math/vector.lua")
local Direct = dofile("structs/direct.lua")

local config = {}

config.robot = {
    color = 0xff5050,
    lightColor = 0x00a0a0,
    direct = Direct.North,
    position = Vector:new(396, 447, 55)
}

config.main = {
    base = Vector:new(390, 445, 55),
    baseDirect = Direct.South
    robotNames = {
        -- "Mike",
        "Alex",
        "Frank",
        "Bob"
    }
}

config.map = {
    position = Vector:new(390, 445, 55),
    size = Vector:new(7, 9, 3),
    blocks = {
        0, 0, 0, 0, 1, 0, 0,
        0, 0, 0, 0, 1, 0, 0,
        0, 0, 0, 0, 0, 0, 0,
        0, 1, 1, 1, 0, 0, 0,
        0, 0, 0, 0, 1, 0, 0,
        0, 0, 0, 0, 1, 0, 0,
        0, 1, 1, 1, 1, 1, 1,
        1, 1, 0, 0, 1, 0, 0,
        0, 0, 0, 0, 1, 0, 0,

        0, 0, 0, 0, 1, 0, 0,
        0, 0, 0, 0, 1, 0, 0,
        0, 0, 0, 0, 0, 0, 0,
        0, 1, 1, 1, 0, 0, 0,
        0, 0, 0, 0, 1, 0, 0,
        0, 0, 0, 0, 0, 0, 0,
        0, 1, 1, 0, 1, 1, 0,
        1, 1, 0, 0, 1, 0, 0,
        0, 0, 0, 0, 1, 0, 0,

        0, 0, 0, 0, 1, 0, 0,
        0, 0, 0, 0, 1, 0, 0,
        0, 0, 0, 0, 0, 0, 0,
        0, 1, 1, 1, 0, 0, 0,
        0, 0, 0, 0, 1, 0, 0,
        0, 0, 0, 0, 1, 0, 0,
        0, 1, 1, 1, 1, 0, 1,
        1, 1, 0, 0, 1, 0, 0,
        1, 1, 0, 0, 1, 0, 0
    }
}

return config
