WorldObject = require("LuaScripts/WorldObject")

local Tower = WorldObject:new()

function Tower:new(cellID, cellPosition, towerStats)

    if (type(towerStats) ~= "table") then error("Tower Stats must be a table!") end
    if (towerStats.damage == nil) then error("Tower Stats must have a 'damage' attribute!") end
    if (towerStats.shotsPerSec == nil) then error("Tower Stats must have a 'shotsPerSec' attribute!") end
    if (towerStats.range == nil) then error("Tower Stats must have a 'range' attribute!") end

    local t = 
    {
        id = nil,
        damage = towerStats.damage,
        shotsPerSec = towerStats.shotsPerSec,
        circularRange = towerStats.range,
        rangeMesh = nil
    }

    self.__index = self
    setmetatable(t, self) 

    t.id = cellID .. "_t"
    print("hello from tower constructor")
    t:initCRep(t.id)
    t.cRep:addSphereMesh(5)
    t.cRep:setPickable()
    t.cRep:setScale(0.6, 1.5, 0.6);
    t.cRep:setTexture("resources/textures/modernbrick.jpg")

    t.cRep:setPosition(cellPosition.x, cellPosition.y + 10.0, cellPosition.z)

    -- setup range mesh
    t.rangeMesh = WorldObject:new()
    t.rangeMesh:initCRep(t.id .. "_r")
    t.rangeMesh.cRep:addSphereMesh(t.circularRange)
    t.rangeMesh.cRep:setScale(1, 0.1, 1);
    t.rangeMesh.cRep:setTexture("resources/textures/green.png")
    t.rangeMesh.cRep:setTransparent()
    t.rangeMesh.cRep:setPosition(cellPosition.x, cellPosition.y + 10.0, cellPosition.z)

    return t
end

return Tower