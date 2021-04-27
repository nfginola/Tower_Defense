local EnemyOrchestrator = {}

--[[

To-do:

    Set the affected cells (by the waypoints) to Invalid! (so no tower placement allowed!)

]]

function EnemyOrchestrator:new()
    o = {
        waypoints = {},
        spawnCell = "",
        showWaypoints = true,
        cellsAffected = {}

        -- below are specific variables for spawning enemies
        -- (wave interval, groups, etc.)
    }

    self.__index = self
    setmetatable(o, self)

    return o
end

function EnemyOrchestrator:addWaypoint(cell)

    if (cell == self.waypoints[#self.waypoints]) then
        print("You can't select the same waypoint as the immediate previous one!")
    elseif (#self.waypoints ~= 0) then
        -- do checks to make sure waypoint connection is never diagonal
        local newX = tonumber(string.sub(cell, 3, 3))
        local newZ = tonumber(string.sub(cell, 5, 5))

        local prevX = tonumber(string.sub(self.waypoints[#self.waypoints], 3, 3))
        local prevZ = tonumber(string.sub(self.waypoints[#self.waypoints], 5, 5))

        local changeInX = (newX ~= prevX)
        local changeInZ = (newZ ~= prevZ)

        -- Diagonal waypoint detected --> Dont insert
        if (changeInX) and (changeInZ) then
            print("\n")
            print("Diagonal waypoint detected! Not allowed. Try again")
            print(string.format("Prev X: %i || Prev Z: %i", prevX, prevZ))
            print(string.format("New X: %i || New Z: %i", newX, newZ))
            print("\n")
        else
            --print("Waypoint set from " .. self.waypoints[#self.waypoints] .. " to " .. cell)
            table.insert(self.waypoints, cell)

            if (changeInX) then
                print("X!")
            elseif (changeInZ) then
                print("Z!")
            end


        end
    else    
        self:setSpawnCell(cell)
    end

end

function EnemyOrchestrator:resetWaypoints()
    print("Waypoints reset")
    self.waypoints = {}
    self.showWaypoints = true

    -- Reset spawn cell texture
    if (self.spawnCell ~= "") then
        cells[self.spawnCell].cRep:setTexture("resources/textures/sand.jpg")
        self.spawnCell = ""
    end
end

function EnemyOrchestrator:setSpawnCell(cell)
    if (#self.waypoints >= 1) then
        print("Can't set spawn cell. Reset waypoints first!")
    else
        self.spawnCell = cell
        table.insert(self.waypoints, cell)

        print("Spawn set at: " .. cell)
        -- Set cell to spawn texture
        cells[self.spawnCell].cRep:setTexture("resources/textures/lava.jpg")
    end
end

function EnemyOrchestrator:getWaypoints()
    return self.waypoints
end

function EnemyOrchestrator:getSpawnPosition()
    return cells[self.spawnCell]:getPosition()
end

function EnemyOrchestrator:confirmWaypoints()
    -- check if end waypoint is same as cell that base lives on
    if (self.waypoints[#self.waypoints] ~= base:getCellID()) then
        print("Waypoint is not connected to base! Please fix this")
    else
        print("Waypoints confirmed! :)")
        self.showWaypoints = false

        --[[
            do some writing into a global object that is to be written into a file once ALL edit has been submitted!
        ]]

    end
    
end

function EnemyOrchestrator:update(dt)

    if (#self.waypoints > 1) and (self.showWaypoints == true) then
        for i = 1, #self.waypoints - 1 do
            local st = cells[self.waypoints[i]]:getPosition()
            local ed = cells[self.waypoints[i+1]]:getPosition()

            -- Make it easier to see :)
            posDrawLine(st.x, enemy_ground_height, st.z, ed.x, enemy_ground_height, ed.z)
            posDrawLine(st.x, enemy_ground_height + 0.1, st.z, ed.x, enemy_ground_height - 0.1, ed.z)
            posDrawLine(st.x, enemy_ground_height - 0.1, st.z, ed.x, enemy_ground_height + 0.1, ed.z)
            posDrawLine(st.x + 0.1, enemy_ground_height, st.z, ed.x - 0.1, enemy_ground_height, ed.z)
            posDrawLine(st.x - 0.1, enemy_ground_height, st.z, ed.x + 0.1, enemy_ground_height, ed.z)
            posDrawLine(st.x, enemy_ground_height, st.z + 0.1, ed.x, enemy_ground_height, ed.z - 0.1)
            posDrawLine(st.x, enemy_ground_height, st.z - 0.1, ed.x, enemy_ground_height, ed.z + 0.1)
        
        end
    end

end

-- Temp
function EnemyOrchestrator:spawnEnemy()

    if (self.spawnCell ~= "") then
        local newEnemy = Enemy:new(
            self:getSpawnPosition(),
            { maxHealth = 40, damage = 10, unitsPerSec = 40}
        )
        enemies[newEnemy.id] = newEnemy
    else
        print("No spawn point set for enemies!")
    end
end


return EnemyOrchestrator