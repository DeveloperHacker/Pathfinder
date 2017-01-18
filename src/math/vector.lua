local Vector = {}

function Vector:new(x, y, z)
    local object = {
        x = x,
        y = y,
        z = z
    }
    self.__index = self
    return setmetatable(object, self)
end

local zero = Vector:new(0, 0, 0)

function Vector.zero()
    return zero
end

function Vector:clone() -- const
    return Vector:new(self.x, self.y, self.z)
end

function Vector:sabs() -- const
    return self.x^2 + self.y^2 + self.z^2
end

function Vector:abs() -- const
    return math.sqrt(self:sabs())
end

function Vector.__add(v1, v2) -- const
    return Vector:new(v1.x + v2.x, v1.y + v2.y, v1.z + v2.z)
end

function Vector.__sub(v1, v2) -- const
    return Vector:new(v1.x - v2.x, v1.y - v2.y, v1.z - v2.z)
end

function Vector.__mul(v1, v2) -- const
    return Vector:new(v1.y * v2.z - v1.z * v2.y, v1.x * v2.z - v1.z * v2.x, v1.x * v2.y - v1.y * v2.x) 
end

function Vector.__unm(v) -- const
    return Vector:new(-v.x, -v.y, -v.z)
end

--/** Возвращает скалярное произведение self на v */
function Vector:dot(v) -- const
    return self.x * v.x + self.y * v.y + self.z * v.z
end

function Vector:cos(v) -- const
    return self:dot(v) / (self:abs() * v:abs())
end

--/** Возвращает вектор в а раз больший текущего */ 
function Vector:scale(a) -- const
    return Vector:new(self.x * a, self.y * a, self.z * a)
end

function Vector:equals(v)
    return (self.x == v.x) and (self.y == v.y) and (self.z == v.z)
end

function Vector:toString()
    return "("..self.x.."; "..self.y.."; "..self.z..")"
end

return Vector
