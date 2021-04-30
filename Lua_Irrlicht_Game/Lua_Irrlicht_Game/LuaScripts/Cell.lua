WorldObject = require("LuaScripts/WorldObject")
Tower = require("LuaScripts/Tower")
Base = require("LuaScripts/Base")

-- Simply inherit all operations
local Cell = WorldObject:new()

function Cell:new(id, x, z) 
    local c = 
    {
        id = nil,
        occupied = false,
        inhabitant = nil,                -- Base or Tower
        type = "Invalid",                -- "Invalid" (Non-placeable), "Base" (Non-placeable), "Valid" (Tower placeable), "Waypoint"
        status = "Not Occupied"          -- "Occupied", "Not Occupied"
    }

    -- local c = WorldObject:new()
    -- c.id = nil
    -- c.occupied = false
    -- c.inhabitant = nil
    -- c.type = "Invalid"
    -- c.status = "Not Occupied"

    self.__index = self
    setmetatable(c, self) 

    c.id = id

    -- init cRep for cell
    c:initCRep(id)
    c.cRep:addCubeMesh()
    c:setPosition((x - 1) * 10.5, 0.0, (z - 1) * 10.5)
    c.cRep:setTexture("resources/textures/sand.jpg")
    c.cRep:addCasting()
    c.cRep:setPickable()

    -- print(id)

    return c
end

function Cell:setCellType(type_in)
    if (type(type_in) ~= "string") then error("Set Cell Type only accepts string!") end
    if (type_in ~= "Invalid") and 
        (type_in ~= "Base") and
        (type_in ~= "Valid") and
        (type_in ~= "Waypoint") then
            error("Set Cell Type only accepts 'Invalid', 'Base', 'Valid', 'Waypoint'")
        end

    self.type = type_in
end

function Cell:placeTower()
    if (self.type ~= "Valid") then error("Cell not valid! Cannot place tower!") end
    if (self.status == "Occupied") then error("Cell occupied! Cannot place tower!") end

    self.inhabitant = Tower:new(self.id, { damage = 10, shotsPerSec = 3, range = 25})
    self.status = "Occupied"

    towers[self.inhabitant.id] = self.inhabitant
end

function Cell:removeTower()
    if (self.type == "Valid") and (self.status == "Occupied") then

        -- hide immediately (emulate instant deletion)
        self.inhabitant.cRep:toggleVisible()   
        if (towerRangeHidden == false) then
            self.inhabitant.rangeMesh.cRep:toggleVisible() 
        end
        
        towers[self.inhabitant.id] = nil
        self.inhabitant = nil
        self.status = "Not Occupied"
    --else
    --    print("No tower to delete")
    end
end

function Cell:placeBase()
    if (self.type ~= "Base") then error("Cell not 'Base'! Cannot place Base!") end
    if (self.status == "Occupied") then error("Something has gone terribily wrong..") end

    self.status = "Occupied"
    self.inhabitant = Base:new(self.id, self:getPosition(), 100)
    base = self.inhabitant
end

function Cell:removeBase()
    if (self.type == "Base") then
        self.status = "Not Occupied"
        self.type = "Valid"
        self.inhabitant.cRep:toggleVisible()
        self.inhabitant = nil
        base = nil
    end
end

function getCellNumber(cellID)
    local delim = ","
    local cellNumbers = string.sub(cellID, 3, #cellID) .. delim
    local elements = {}
    for element in (cellNumbers):gmatch("([^" .. delim .. "]*)" .. delim) do 
        table.insert(elements, element) 
    end

    local x = elements[1]
    local z = elements[2]

    return tonumber(x), tonumber(z)
end

function Cell:getType()
    return self.type
end

function Cell:getStatus()
    return self.status
end

return Cell