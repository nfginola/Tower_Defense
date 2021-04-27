Vector = require("LuaScripts/Vector")

local WorldObject = {
    cRep = nil,     -- c representation of world obj
    pos = nil,
    id = nil,
    scale = nil
}

function WorldObject:new() 
    local wo = {}

    -- VARFÖR FUNKAR INTE DET ATT INITALISERA HÄR??
    -- Det verkar vara SHARED variabel (kolla med size-reduction på Enemies!)

    -- print("world object")
    wo.pos = Vector:new({ x = 0, y = 0, z = 0})
    wo.scale = Vector:new({ x = 1, y = 1, z = 1})

    self.__index = self
    setmetatable(wo, self) 


    return wo
end

function WorldObject:initCRep(id)
    self.cRep = CWorldObject:new(id)

    -- self.pos = Vector:new({ x = 0, y = 0, z = 0})
    -- self.scale = Vector:new({ x = 1, y = 1, z = 1})
    
    self.id = id
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

function WorldObject:setScale(x, y, z)

    -- if (self.scale == nil) then
    --     print("huH!")
    -- end

    --print(self.scale)


    self.scale.x = x
    self.scale.y = y
    self.scale.z = z
    self.cRep:setScale(x, y, z)
end

function WorldObject:getScale()
    return self.scale
end

function WorldObject:update(dt)
    self.cRep:update(dt)
end

function WorldObject:collidesWith(rh)
    return self.cRep:collidesWith(rh.cRep)
end


function WorldObject:__tostring()
    str = string.format("WorldObject Pos (%f, %f, %f)", self.pos.x, self.pos.y, self.pos.z)
    return str
end

function WorldObject:getID()
    return self.id
end

function lengthBetween(o1, o2)
    return (o1:getPosition() - o2:getPosition()):length()
end



return WorldObject