WorldObject = require("LuaScripts/WorldObject")

local Base = WorldObject:new()

function Base:new(cellID, cellPosition, maxHealth)
    local b = 
    {
        id = nil,
        health = maxHealth
    }

    self.__index = self
    setmetatable(b, self) 

    b.id = cellID .. "_b"
    b:initCRep(b.id)
    b.cRep:addCubeMesh()
    b.cRep:setTexture("resources/textures/modernbrick.jpg")

    b.cRep:setPosition(cellPosition.x, cellPosition.y + 10, cellPosition.z)
    b.cRep:setScale(0.7, 1.3, 0.9)
    b.cRep:toggleBB()

    return b
end

function Base:getHealth()
    return self.health
end

function Base:takeDamage(damage)
    if (type(damage) ~= "number") then error("takeDamage can only take number argument!") end
    self.health = self.health - damage
end

return Base