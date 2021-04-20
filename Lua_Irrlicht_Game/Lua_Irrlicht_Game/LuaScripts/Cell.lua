WorldObject = require("LuaScripts/WorldObject")
Tower = require("LuaScripts/Tower")

local Cell = WorldObject:new()

function Cell:new(id, x, z) 
    local c = 
    {
        -- subtype specific variables
        id = nil,
        occupied = false,
        inhabitant = nil,                -- Base or Tower
        type = "Invalid",                -- "Invalid" (Non-placeable), "Base" (Non-placeable), "Valid" (Tower placeable)
        status = "Not Occupied"          -- "Occupied", "Not Occupied"
    }

    self.__index = self
    setmetatable(c, self) 

    c.id = id

    -- init cRep for cell
    c:initCRep(id)
    c.cRep:addCubeMesh()
    c:setPosition((x - 1) * 10.5, 0.0, (z - 1) * 10.5)
    c.cRep:setTexture("resources/textures/moderntile.jpg")
    c.cRep:addCasting()
    c.cRep:setPickable()

    print(id)

    return c
end

function Cell:setCellType(type_in)
    if (type(type_in) ~= "string") then error("Set Cell Type only accepts string!") end
    if (type_in ~= "Invalid") and 
        (type_in ~= "Base") and
        (type_in ~= "Valid") then
            error("Set Cell Type only accepts 'Invalid', 'Base' and 'Valid'")
        end

    self.type = type_in
end

function Cell:placeTower()
    if (self.type ~= "Valid") then error("Cell not valid! Cannot place tower!") end

    self.inhabitant = Tower:new(self.id, self:getPosition(), { damage = 10, shotsPerSec = 2, range = 20})
    self.status = "Occupied"
    
    return self.inhabitant
end

function Cell:removeTower()
    self.inhabitant.cRep:toggleVisible()
    self.inhabitant.rangeMesh.cRep:toggleVisible() 
    self.inhabitant = nil
    self.status = "Not Occupied"
end

function Cell:placeBase()
    if (self.type ~= "Base") then error("Cell not 'Base'! Cannot place Base!") end

    -- Replace with Base class
    self.inhabitant = WorldObject:new()
    self.inhabitant:initCRep("77777")
    self.inhabitant.cRep:addCubeMesh()
    self.inhabitant.cRep:setTexture("resources/textures/modernbrick.jpg")

    local cellPos = self:getPosition()
    self.inhabitant.cRep:setPosition(cellPos.x, cellPos.y + 10, cellPos.z)
    self.inhabitant.cRep:setScale(0.7, 1.3, 0.9)
    self.inhabitant.cRep:toggleBB()

    self.status = "Occupied"
    return self.inhabitant
end

function Cell:getType()
    return self.type
end

function Cell:getStatus()
    return self.status
end

return Cell