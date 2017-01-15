
local Vector = dofile("math/vector.lua")

local Direct = Vector

Direct.North = Direct:new(0, -1, 0)
Direct.South = Direct:new(0, 1, 0)
Direct.West = Direct:new(-1, 0, 0)
Direct.East = Direct:new(1, 0, 0)
Direct.Up = Direct:new(0, 0, 1)
Direct.Down = Direct:new(0, 0, -1)

function Direct.valueOf(direct)
    direct = string.lower(direct)
    if (direct == "north") then
        return Direct.North
    elseif (direct == "south") then
        return Direct.South
    elseif (direct == "west") then
        return Direct.West
    elseif (direct == "east") then
        return Direct.East
    else
        return nil
    end
end

function Direct:toString()
    if (self:equals(Direct.North)) then
        return "north"
    elseif (self:equals(Direct.South)) then
        return "south"
    elseif (self:equals(Direct.West)) then
        return "west"
    elseif (self:equals(Direct.East)) then
        return "east"
    elseif (self:equals(Direct.Up)) then
        return "up"
    elseif (self:equals(Direct.Down)) then
        return "down"
    else
        return nil
    end
end

function Direct:left()
    return Vector:new(self.y, -self.x, 0)
end

function Direct:right()
    return Vector:new(-self.y, self.x, 0)
end

function Direct:back()
    return Vector:new(-self.x, -self.y, 0)
end

return Direct
