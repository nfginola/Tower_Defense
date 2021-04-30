local EnemyOrchestrator = {}



function EnemyOrchestrator:new()
    o = {
        waypoints = {},
        spawnCell = "",
        showWaypoints = true,
        cellsAffected = {},
        waypointsConfirmed = false,

        waveSpawnerCoroutine = nil,
        wavePauseTimer = 0

        -- below are specific variables for spawning enemies
        -- (wave interval, groups, etc.)
    }

    self.__index = self
    setmetatable(o, self)


    -- This is resumed after every wave has been completed
    o.waveSpawnerCoroutine = coroutine.create(
        function ()
            local amountOfWaves = 10
            for i = 1, amountOfWaves do
                self.currentWave = EnemyWave:new(waveData[i].spawnInterval, waveData[i].enemyCount)
                coroutine.yield()  
            end
        end
    )


    return o
end

function getSmallerAndBigger(val1, val2)
    local smaller = val1
    local bigger = val2
    if (val2 < val1) then
        smaller = val2
        bigger = val1
    end
    return smaller, bigger
end

function EnemyOrchestrator:addWaypoint(cell)
    if (self.waypointsConfirmed == true) then error("Waypoints already confirmed..") end

    if (cell == self.waypoints[#self.waypoints]) then
        print("You can't select the same waypoint as the immediate previous one!")
    elseif (#self.waypoints ~= 0) and (self.waypointsConfirmed == false) then
        -- do checks to make sure waypoint connection is never diagonal
        local newX = tonumber(string.sub(cell, 3, 3))
        local newZ = tonumber(string.sub(cell, 5, 5))

        local prevX = tonumber(string.sub(self.waypoints[#self.waypoints], 3, 3))
        local prevZ = tonumber(string.sub(self.waypoints[#self.waypoints], 5, 5))

        local changeInX = (newX ~= prevX)
        local changeInZ = (newZ ~= prevZ)

        -- Diagonal waypoint detected --> Dont insert
        if (changeInX) and (changeInZ) then
            print("Diagonal waypoint not allowed. Try again")
            -- print(string.format("Prev X: %i || Prev Z: %i", prevX, prevZ))
            -- print(string.format("New X: %i || New Z: %i", newX, newZ))
        else
            --print("Waypoint set from " .. self.waypoints[#self.waypoints] .. " to " .. cell)
            table.insert(self.waypoints, cell)

            if (changeInX) then
                --print("X!")

                -- or oldZ, doesnt matter
                local zval = newZ 
                local smaller, bigger = getSmallerAndBigger(newX, prevX)

                -- add the affected cells by waypoint
                for i = smaller, bigger do
                    local affectedCellID = string.format("cg%i,%i", i, zval)
                    self.cellsAffected[affectedCellID] = affectedCellID -- duplicates just reassign themselves
                end
                
            elseif (changeInZ) then
                --print("Z!")

                -- add the affected cells by waypoint
                local xval = newX 
                local smaller, bigger = getSmallerAndBigger(newZ, prevZ)

                for i = smaller, bigger do
                    local affectedCellID = string.format("cg%i,%i", xval, i)
                    self.cellsAffected[affectedCellID] = affectedCellID -- duplicates just reassign themselves
                end
            end
            
            if (cells[cell]:getType() == "Base") then self:confirmWaypoints() end
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

    -- Reset affected cells
    for key, cellID in pairs(self.cellsAffected) do
        cells[cellID].cRep:setTexture("resources/textures/sand.jpg")

        -- Skip base 
        if cells[cellID]:getType() ~= "Base" then
            cells[cellID]:setCellType("Valid")
        end
    end

    self.waypointsConfirmed = false
    self.cellsAffected = {} -- reset
end

function EnemyOrchestrator:setSpawnCell(cellID)
    if (#self.waypoints >= 1) then
        print("Can't set spawn cell. Reset waypoints first!")
    elseif (cells[cellID]:getType() ~= "Base") and (cells[cellID]:getStatus() == "Not Occupied") then
        self.spawnCell = cellID
        table.insert(self.waypoints, cellID)

        print("Spawn set at: " .. cellID)
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
        self.waypointsConfirmed = true
        self.showWaypoints = false

        --[[
            do some writing into a global object that is to be written into a file once ALL edit has been submitted!
        ]]

        for key, cellID in pairs(self.cellsAffected) do
            if (cells[cellID]:getType() ~= "Base") then

                -- If tower was in the way, remove it
                cells[cellID]:removeTower()
                cells[cellID]:setCellType("Invalid")
                cells[cellID].cRep:setTexture("resources/textures/lava.jpg")

                -- print(cellID)
            end
        

            cells[cellID]:removeTower()
        end

    end


    
end

function EnemyOrchestrator:update(dt)

    -- Draw waypoints
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

    --[[

    local waveDone = self.currentWave:update(dt)
    if (waveDone) then
        self.wavePauseTimer = wavePauseTimer + dt

        if (self.wavePauseTimer > self.levelWavePauseTime) then
            self.wavePauseTimer = 0
            coroutine.resume(self.waveSpawnerCoroutine)
        end
    end
    --> After coroutine resumes --> currentWave changes and waveDone should be false all the way
    --> Until that wave is done..

    ]]

end

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

--[[

    function writeToFile()

    function readFromFile()

]]


return EnemyOrchestrator