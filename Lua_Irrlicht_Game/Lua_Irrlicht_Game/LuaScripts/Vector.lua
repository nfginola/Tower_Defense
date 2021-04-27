local Vector = {
    x = 0,
    y = 0,
    z = 0
}

function Vector:__tostring()
    str = string.format("Vector: (%f, %f, %f)", self.x, self.y, self.z)
    return str
end

function Vector:__add(vec) 

    if (getmetatable(self) ~= Vector or 
        getmetatable(vec) ~= Vector) then 
            error("A Vector can only be added to another Vector!") 
    end
    sumVec = Vector:new()   -- Get a new Vector that we will fill
    sumVec.x = self.x + vec.x
    sumVec.y = self.y + vec.y
    sumVec.z = self.z + vec.z
    return sumVec
end

function Vector:__sub(vec) 

    if (getmetatable(self) ~= Vector or 
        getmetatable(vec) ~= Vector) then 
            error("A Vector can only be subtracted by another Vector!") 
    end
    sumVec = Vector:new()   -- Get a new Vector that we will fill
    sumVec.x = self.x - vec.x
    sumVec.y = self.y - vec.y
    sumVec.z = self.z - vec.z
    return sumVec
end

function Vector:__mul(v)
    if (type(self) == "number" and getmetatable(v) == Vector) then
        resVec = Vector:new()
        resVec.x = v.x * self
        resVec.y = v.y * self
        resVec.z = v.z * self
        return resVec
    elseif (getmetatable(self) == Vector and type(v) == "number") then
        resVec = Vector:new()
        resVec.x = self.x * v
        resVec.y = self.y * v
        resVec.z = self.z * v
        return resVec
    elseif (getmetatable(self) == Vector and getmetatable(v) == Vector) then
        dotprod = self.x * v.x + self.y * v.y + self.z * self.z
        return dotprod
    else
        error("Multiplication can only be done between Vectors or between a Vector and a Number")
    end
end

function Vector:new(values) 
    local vec = values or { x = 0, y = 0, z = 0 }
    --local vec = {}

    self.__index = self
    
    setmetatable(vec, self)


    -- if (values ~= nil and type(values) == "table") then
    --     vec.x = values.x
    --     vec.y = values.y
    --     vec.z = values.z
    -- end

    return vec
end

function Vector:length()
    return math.sqrt(self.x * self.x + self.y * self.y + self.z * self.z)
end

function Vector:normalize()
    if (self:length() == 0) then error("Trying to normalize a vector with length 0!") end
    len = self:length()
    self.x = self.x / len
    self.y = self.y / len
    self.z = self.z / len
end

function Vector:toString()
    local str = string.format("(%f, %f, %f)", self.x, self.y, self.z)
    return str
end

return Vector