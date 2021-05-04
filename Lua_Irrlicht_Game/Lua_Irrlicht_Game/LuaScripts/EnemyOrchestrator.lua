local EnemyOrchestrator = {}
EnemyWave = require("LuaScripts/EnemyWave")

function EnemyOrchestrator:new()
    local o = {
        waypoints = {},
        spawnCell = "",
        showWaypoints = true,
        cellsAffected = {},
        waypointsConfirmed = false,

        -- below are specific variables for spawning enemies
        -- (wave interval, groups, etc.)

        waveSystemStarted = false,

        -- True..
        lastWaveSpawned = true,
        waveSystemRunning = false,

        waveSpawnerFunc = nil,
        waveSpawnerCoroutine = nil,
        currentWave = nil,
        
        wavePauseTimer = 0,

        -- Below set by file
        levelWavePauseTime = 0,
        levelWaveAmount = 0,
        levelWavesData = {}

    }

    self.__index = self
    setmetatable(o, self)

    return o
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

    -- Is current wave done spawning?
    local waveDone = false
    if (self.currentWave ~= nil) then
        waveDone = self.currentWave:update(dt)
    end

    -- A bit complex here because coroutine doesnt signify "death" until 'one-after' the last (since yield is at the end)
    -- Start the wave system
    if (self.waveSystemStarted) then
        -- If done --> Try to spawn new wave
        if (waveDone) then
            self.wavePauseTimer = self.wavePauseTimer + dt

            if (self.wavePauseTimer > self.levelWavePauseTime) then
                self.wavePauseTimer = 0

                -- Try to spawn new wave
                local co, isLastWave = coroutine.resume(self.waveSpawnerCoroutine)
                waveDone = false -- New wave meaning wave is not done!

                -- If last wave has spawned, we can turn off our wave spawning system
                if (isLastWave) then
                    self.lastWaveSpawned = true
                    self.waveSystemStarted = false  -- turn off wave spawn sys (because last wave spawned)
                end
            end
        end
    end

    -- Last wave done spawning completely
    if (self.lastWaveSpawned) and (waveDone) then
        self.currentWave = nil
        self.waveSystemRunning = false
    end
end

function EnemyOrchestrator:resetWaveSystem()
    self.currentWave = nil
    self.waveSystemRunning = false
    self.lastWaveSpawned = false
    self.waveSystemStarted = false
end

function EnemyOrchestrator:startWaveSystem()
    if (self.waveSpawnerFunc == nil) then log("Please submit a wave list before testing the wave!") return end
    if (self.waypointsConfirmed == false) then log("Please put down waypoints for the enemies!") return end
    if (self.waveSystemStarted) and (self.currentWave ~= nil) then log("Wait until the current wave system is done spawning..") return end

    self:resetWaveSystem()
    self.waveSpawnerCoroutine = coroutine.create(self.waveSpawnerFunc)

    self.waveSystemStarted = true
    self.waveSystemRunning = true
    coroutine.resume(self.waveSpawnerCoroutine)
end

function EnemyOrchestrator:isWaveSystemRunning()
    return self.waveSystemRunning
end

-- ============

function EnemyOrchestrator:setWaveData(waveData)    
    self.levelWaveAmount = #waveData
    self.levelWavesData = {}
    for i = 1, #waveData do
        table.insert(self.levelWavesData, waveData[i])
    end

    -- replace waveSpawnerFunc to use
    self.waveSpawnerFunc = function ()
        for i = 1, self.levelWaveAmount do
            self.currentWave = EnemyWave:new(self.levelWavesData[i].spawnInterval, self.levelWavesData[i].enemyPerWave, self.spawnCell)
            if (i < self.levelWaveAmount) then
                coroutine.yield(false)  -- last wave spawned not true
            else
                coroutine.yield(true)   -- last wave spawned true
            end
        end
    end

end

function EnemyOrchestrator:setWavePauseTime(pauseTime)
    self.levelWavePauseTime = pauseTime
end

function EnemyOrchestrator:addWaypoint(cell)
    if (self.waypointsConfirmed == true) then log("Waypoints already confirmed..") return end

    if (cell == self.waypoints[#self.waypoints]) then
        --print("You can't select the same waypoint as the immediate previous one!")
        log("You can't select the same waypoint as the immediate previous one!")
    elseif (#self.waypoints ~= 0) and (self.waypointsConfirmed == false) then
        -- do checks to make sure waypoint connection is never diagonal

        local newX, newZ = getCellNumber(cell)
        local prevX, prevZ = getCellNumber(self.waypoints[#self.waypoints])

        -- print(cell)
        -- print("\n")
        -- print(string.format("Prev X: %i || Prev Z: %i", prevX, prevZ))
        -- print(string.format("New X: %i || New Z: %i", newX, newZ))

        local changeInX = (newX ~= prevX)
        local changeInZ = (newZ ~= prevZ)

        -- Diagonal waypoint detected --> Dont insert
        if (changeInX) and (changeInZ) then
            --print("Diagonal waypoint not allowed. Try again")
            log("Diagonal waypoint not allowed. Try again")

        else
            --print("Waypoint set from " .. self.waypoints[#self.waypoints] .. " to " .. cell)
            table.insert(self.waypoints, cell)

            -- Affect the cells between waypoints!
            if (changeInX) then
                -- print("X!")
                -- or oldZ, doesnt matter
                local zval = newZ 
                local smaller, bigger = getSmallerAndBigger(newX, prevX)

                -- add the affected cells by waypoint
                for i = smaller, bigger do
                    local affectedCellID = string.format("cg%i,%i", i, zval)
                    self.cellsAffected[affectedCellID] = affectedCellID -- duplicates just reassign themselves
                end
                
            elseif (changeInZ) then
                -- print("Z!")
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
    --print("Waypoints reset")
    log("Waypoints reset..")
    self.waypoints = {}
    self.showWaypoints = true

    -- Reset spawn cell texture
    if (self.spawnCell ~= "") then
        cells[self.spawnCell].cRep:setTexture("resources/textures/sand.jpg")
    end

    -- Reset cell type
    if (cells[self.spawnCell] ~= nil) then
        cells[self.spawnCell]:setCellType("Valid")
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

    -- Reset wave system when waypoints are reset
    self:resetWaveSystem()

end

function EnemyOrchestrator:setSpawnCell(cellID)
    if (#self.waypoints >= 1) then
        --print("Can't set spawn cell. Reset waypoints first!")
        log("Can't set spawn cell. Reset waypoints first!")
    elseif (cells[cellID]:getType() ~= "Base") and (cells[cellID]:getStatus() == "Not Occupied") then
        self.spawnCell = cellID
        table.insert(self.waypoints, cellID)

        --print("Spawn set at: " .. cellID)
        log("Spawn set at: " .. cellID)
        
        -- Set cell to spawn texture
        cells[self.spawnCell].cRep:setTexture("resources/textures/lava.jpg")
        cells[self.spawnCell]:setCellType("Waypoint") -- Make sure other tools cant change spawn cell..
    end
end

function EnemyOrchestrator:confirmWaypoints()
    -- check if end waypoint is same as cell that base lives on
    if (self.waypoints[#self.waypoints] ~= base:getCellID()) then
        --print("Waypoint is not connected to base! Please fix this")
        log("Waypoint is not connected to base! Please fix this")
    else
        --print("Waypoints confirmed! :)")
        log("Waypoints confirmed! :)")
        self.waypointsConfirmed = true
        self.showWaypoints = false

        for key, cellID in pairs(self.cellsAffected) do
            if (cells[cellID]:getType() ~= "Base") and (cellID ~= self.spawnCell) then

                -- If tower was in the way, remove it
                cells[cellID]:removeTower()
                cells[cellID]:setCellType("Waypoint")
                cells[cellID].cRep:setTexture("resources/textures/lavasand.jpg")
            end
        end
        

    end
end

function EnemyOrchestrator:getWaypoints()
    return self.waypoints
end

function EnemyOrchestrator:getSpawnPosition()
    return cells[self.spawnCell]:getPosition()
end

return EnemyOrchestrator