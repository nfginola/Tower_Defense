local LevelFileManager = { 
    data = {},
    currentSaveFileName = ""
}

LevelFileManager.data.gridSize = { x = 0, z = 0 }
LevelFileManager.data.baseCellID = ""
LevelFileManager.data.invalids = {}
LevelFileManager.data.waypoints = {}
LevelFileManager.data.timeBetweenWaves = -1

-- Element: { enemyPerWave, spawnInterval }
LevelFileManager.data.waveData = {}

-- Called on save file request
function LevelFileManager:saveCurrentState()
    if (orchestrator.waypointsConfirmed == false) then log("Waypoints not confirmed..") return false end
    if (Editor.waveListSubmitted == false) then log("Waves not submitted..") return false end

    self.data.waveData = {} -- reset current state
    self.data.invalids = {}
    self.data.waypoints = {}
    
    self.data.baseCellID = base.cellID    

    -- set invalids
    for k, v in pairs(invalids) do
        table.insert(self.data.invalids, v)
    end

    -- set waypoints (input)
    for i = 1, #orchestrator.waypoints do
        table.insert(self.data.waypoints, orchestrator.waypoints[i])
    end

    -- set level pause time between waves
    self.data.timeBetweenWaves = Editor.currTimeBetweenWaves

    -- set wave list data
    for i = 1, #Editor.waveList do
        table.insert(self.data.waveData, 
        { 
            enemyPerWave = Editor.waveList[i].enemyPerWave,  
            spawnInterval = Editor.waveList[i].spawnInterval
        }
    )
    end

    -- get current save file name
    self.currentSaveFileName = Editor.saveFileEditbox:getText()
    print(self.currentSaveFileName)

    -- print("-----------------")
    -- print("SpawnCell: ", self.data.baseCellID)
    -- print("WavePause: ", self.data.timeBetweenWaves)
    -- print("Invalids: ")
    -- for k, v in ipairs(self.data.invalids) do
    --     print(v)
    -- end
    -- print("\n")

    -- print("WaveList: ")
    -- for k, v in ipairs(self.data.waveData) do
    --     print(v.enemyPerWave, ", ", v.spawnInterval)
    -- end
    -- print("\n")

    -- print("Waypoints: ")
    -- for k, v in ipairs(self.data.waypoints) do
    --     print(v)
    -- end
    -- print("\n")

    log("Current state saved!")
    return true
end

function LevelFileManager:saveToFile()
    if (self.currentSaveFileName == "") then log("Please enter a name for your level file to save!") return end

    -- place in a "Levels" directory
    local completeFileName = self.currentSaveFileName .. ".level"

    local file = io.open(completeFileName, "w+")

    io.output(file)
    io.write("gs=", worldGridSize.x, ",", worldGridSize.z, "\n")
    io.write("bp=", base.cellID, "\n")
    io.write("lvlwpi=", self.data.timeBetweenWaves, "\n")

    io.write("wypS\n")
    for k, v in pairs(self.data.waypoints) do
        io.write(v, "\n")
    end
    io.write("wypE\n")

    io.write("invS\n")
    for k, v in pairs(self.data.invalids) do
        io.write(v, "\n")
    end
    io.write("invE\n")

    io.write("waveS\n")
    for k, v in pairs(self.data.waveData) do
        io.write("ec=", v.enemyPerWave, "\n")
        io.write("si=", v.spawnInterval, "\n")
    end
    io.write("waveE\n")

    -- why is FILE nil?
    io.close(file)

    self.data.waveData = {}
    self.data.invalids = {}
    self.data.waypoints = {}
    self.data.timeBetweenWaves = -1

end

function LevelFileManager:loadFromFile(filePath)
    -- We know we want ".level" extension, so lets check for that
    local extensionGuess = string.sub(filePath, #filePath - 5, #filePath)
    if (extensionGuess~= ".level") then log("Please select a valid level file!") return end

    local file = io.open(filePath, "r")
    io.input(file)

    -- First three always (Gridsize, Base cell ID and Level wave pause time)
    local gs = io.read()
    local bID = io.read()
    local lwpTime = io.read()

    local gsTab = split(split(gs, "=")[2], ",")
    self.data.gridSize.x = gsTab[1]
    self.data.gridSize.z = gsTab[2]
    self.data.baseCellID = split(bID, "=")[2]
    self.data.timeBetweenWaves = tonumber(split(lwpTime, "=")[2])   
    
    -- Read the rest (info that can have arbitrary length)
    -- Waypoints (wyp), Invalid grids (inv), Wave Data (wave)

    self.data.invalids = {}
    self.data.waypoints = {}
    self.data.waveData = {}

    line = io.read()
    while ( line ~= nil ) do
        if (line == "wypS") then
            self:handleWaypoints()

        elseif (line == "invS") then
            self:handleInvalids()

        elseif (line == "waveS") then
            self:handleWaveData()

        end 

        line = io.read()
    end

    io.close(file)

    -- print("Grid size: ",  self.data.gridSize.x, ", ", self.data.gridSize.z)
    -- print("Base Cell ID: ", self.data.baseCellID)
    -- print("Wave Pause Time: ", self.data.timeBetweenWaves)
    -- print("\n")

    -- print("waypoints")
    -- for k, v in ipairs(self.data.waypoints) do
    --     print(v)
    -- end
    -- print("\n")

    -- print("invalids")
    -- for k, v in ipairs(self.data.invalids) do
    --     print(v)
    -- end
    -- print("\n")

    -- print("Waves: ", #self.data.waveData)
    -- print("waveData")
    -- for k, v in ipairs(self.data.waveData) do
    --     print(v.enemyPerWave, ", ", v.spawnInterval)
    -- end
    -- print("\n")

end

function LevelFileManager:handleWaypoints()
    local innerL = io.read() 
    while (innerL ~= "wypE") do
        table.insert(self.data.waypoints, innerL)
        innerL = io.read()
    end
end

function LevelFileManager:handleInvalids()
    local innerL = io.read() 
    while (innerL ~= "invE") do
        table.insert(self.data.invalids, innerL)
        innerL = io.read()
    end
end

function LevelFileManager:handleWaveData()
    local innerL = io.read() 
    local i = 0
    
    while (innerL ~= "waveE") do
        local prev = innerL
        innerL = io.read()
        local curr = innerL

        if (i % 2 == 0) then
            local ec = tonumber(split(prev, "=")[2])
            local si = tonumber(split(curr, "=")[2])

            table.insert(self.data.waveData, { enemyPerWave = ec, spawnInterval = si })
        end
        i = i + 1
    end
end

function LevelFileManager:setWorldFromLoadedFile()
    print("world set from loaded file")

    
    -- Reset all relevant world state
    resetWorldState()

    worldGridSize = { x = self.data.gridSize.x, z = self.data.gridSize.z }

    -- Init cells
    for i = 1, worldGridSize.x do
        for u = 1, worldGridSize.z do
            local id = string.format("cg%i,%i", i, u)

            cells[id] = Cell:new(id, i, u)
            cells[id]:setCellType("Valid")      -- Make tower placeable
        end
    end

    -- Place base
    cells[self.data.baseCellID]:setCellType("Base")
    cells[self.data.baseCellID]:placeBase()

    for k, v in pairs(self.data.waypoints) do
        orchestrator:addWaypoint(v)
    end

    -- Set invalids
    for k, v in pairs(self.data.invalids) do
        invalids[v] = v
        cells[v]:setCellType("Invalid")
        cells[v].cRep:setTexture("resources/textures/lavainvalid.jpg")
    end


    -- Two routes: Either push to Editor or push directly for Play mode

    if (gameState == "Edit") then
        Editor.currTimeBetweenWaves = self.data.timeBetweenWaves
        Editor.timeBetweenWavesText:setText(tostring(Editor.currTimeBetweenWaves))
        Editor:submitWavePauseTime()
    elseif (gameState == "Play") then
        orchestrator:setWavePauseTime(self.data.timeBetweenWaves)
    end

    if (gameState == "Edit") then
        Editor:resetWaves()
        Editor.waveListbox:reset()
        for k, v in pairs(self.data.waveData) do
            Editor:addWave(v.enemyPerWave, v.spawnInterval)
        end
        Editor:submitWave()
    elseif (gameState == "Play") then
        for k, v in pairs(self.data.waveData) do
            orchestrator:setWaveData(self.data.waveData)
        end
    end

end



return LevelFileManager