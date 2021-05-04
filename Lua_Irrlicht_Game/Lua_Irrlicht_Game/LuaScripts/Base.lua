WorldObject = require("LuaScripts/WorldObject")

local Base = WorldObject:new()

function Base:new(cellID, cellPosition, maxHealth)
    local b = 
    {
        id = nil,
        cellID = nil,
        health = maxHealth
    }

    -- local b = WorldObject:new()
    -- b.id = nil
    -- b.health = maxHealth

    self.__index = self
    setmetatable(b, self) 

    b.cellID = cellID
    b.id = cellID .. "_b"
    b:initCRep(b.id)
    b.cRep:addCubeMesh()
    b.cRep:setTexture("resources/textures/leavesv2.jpg")

    b.cRep:setPosition(cellPosition.x, cellPosition.y + 10, cellPosition.z)
    b:setScale(0.7, 1.3, 0.9)
    --b.cRep:toggleBB()

    return b
end

function Base:isDead()
    return self.health <= 0
end

function Base:takeDamage(damage)
    if (type(damage) ~= "number") then error("takeDamage can only take number argument!") end
    self.health = self.health - damage
    -- print("Base HP left: " .. self.health)
end

function Base:getCellID()
    return string.sub(self.id, 1, #self.id - 2)
end

return Base