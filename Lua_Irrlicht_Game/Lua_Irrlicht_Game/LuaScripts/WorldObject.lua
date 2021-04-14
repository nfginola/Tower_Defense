Vector = require("LuaScripts/Vector")

local WorldObject = {
    cRep = nil,     -- c representation of world obj
    pos = nil
}

function WorldObject:new(id) 
    local wo = {}

    self.__index = self
    setmetatable(wo, self) 

    wo.cRep = CWorldObject:new(id)
    wo.pos = Vector:new({ x = 0, y = 0, z = 0})

    return wo
end

function WorldObject:getPosition()
    local x, y, z = self.cRep:getPosition()
    self.pos.x = x
    self.pos.y = y
    self.pos.z = z
    return self.pos
end

function WorldObject:setPosition(x, y, z)
    self.pos.x = x
    self.pos.y = y
    self.pos.z = z
    self.cRep:setPosition(x, y, z)
end

function WorldObject:collidesWith(rh)
    return self.cRep:collidesWith(rh.cRep)
end


function WorldObject:__tostring()
    str = string.format("WorldObject Pos (%f, %f, %f)", self.pos.x, self.pos.y, self.pos.z)
    return str
end


return WorldObject