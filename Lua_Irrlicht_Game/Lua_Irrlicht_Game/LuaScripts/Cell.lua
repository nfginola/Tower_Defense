WorldObject = require("LuaScripts/WorldObject")
Tower = require("LuaScripts/Tower")
Base = require("LuaScripts/Base")

local Cell = WorldObject:new()

function Cell:new(id, x, z) 
    local c = 
    {
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

    self.inhabitant = Tower:new(self.id, self:getPosition(), { damage = 10, shotsPerSec = 3, range = 25})
    self.status = "Occupied"
    
    return self.inhabitant
end

function Cell:removeTower()
    self.inhabitant.cRep:toggleVisible()

    if (towerRangeHidden == false) then
        self.inhabitant.rangeMesh.cRep:toggleVisible() 
    end
    
    self.inhabitant = nil
    self.status = "Not Occupied"
end

function Cell:placeBase()
    if (self.type ~= "Base") then error("Cell not 'Base'! Cannot place Base!") end
    if (self.status == "Occupied") then error("Something has gone terribily wrong..") end

    self.status = "Occupied"
    self.inhabitant = Base:new(self.id, self:getPosition(), 100)

    return self.inhabitant
end

function Cell:getType()
    return self.type
end

function Cell:getStatus()
    return self.status
end

return Cell