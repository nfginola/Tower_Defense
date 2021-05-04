-- ============== GUI
setGlobalGUIFont("Resources/Fonts/smallerfont.xml")

local Editor = {}



-- ================================================= TOOLING 
firstTime = true

-- BaseTool
-- WaypointTool
-- TowerTool
-- EnemyTool
-- ValidTool
currentTool = ""    -- Global

Editor.waveList = {}
Editor.waveListSubmitted = false

-- Initial value --> Minimum value
Editor.currTimeBetweenWaves = 0.1
Editor.currEnemyPerWave = 3
Editor.currSpawnInterval = 0.1


-- ================================================== EDITOR GUI
-- clearGUI() requires all GUI elements to be nil! 
-- GUI TEST

toolText = CText:new(700, 20, 400, 70, "Tool", "Resources/Fonts/myfont.xml")

-- Level
Editor.timeBetweenWavesText = CText:new(1510, 75, 30, 15, tostring(Editor.currTimeBetweenWaves), "Resources/Fonts/smallerfont.xml")
Editor.timeBetweenWavesText:setBGColor(255, 255, 255, 255)
Editor.levelEditText = CText:new(1310, 100, 400, 60, "Wave Pause Time", "Resources/Fonts/smallerfont.xml")

-- Wave
Editor.spawnIntervalText = CText:new(1510, 255, 30, 15, tostring(Editor.currSpawnInterval), "Resources/Fonts/smallerfont.xml")
Editor.spawnIntervalText:setBGColor(255, 255, 255, 255)
Editor.spawnIntervalEditText = CText:new(1310, 280, 300, 15, "Enemy Spawn Interval", "Resources/Fonts/smallerfont.xml")

Editor.enemyPerWaveText = CText:new(1510, 225, 30, 15, tostring(Editor.currEnemyPerWave), "Resources/Fonts/smallerfont.xml")
Editor.enemyPerWaveText:setBGColor(255, 255, 255, 255)
Editor.enemyPerWaveEditText = CText:new(1310, 200, 300, 15, "Enemy Per Wave", "Resources/Fonts/smallerfont.xml")


-- GUI that uses ID
levelEditSubmitButton = CButton:new(1150, 75, 140, 60, 1, "SUBMIT!", "Resources/Fonts/myfont.xml")

Editor.waveEditSubmitButton = CButton:new(1250, 540, 140, 60, 50, "SUBMIT!", "Resources/Fonts/myfont.xml")
Editor.waveEditAddButton = CButton:new(1150, 225, 140, 60, 51, "ADD!", "Resources/Fonts/myfont.xml")
Editor.waveEditResetButton = CButton:new(1411, 540, 140, 60, 52, "RESET!", "Resources/Fonts/myfont.xml")


-- Scroll bar
Editor.levelWavePauseScrollbar = CScrollbar:new(
    1300, 75, 200, 15, -- topLeft X/Y and width/height
    Editor.currTimeBetweenWaves * 10, 100,  -- min/max/curr
    3)     -- id

Editor.enemyPerWaveScrollbar = CScrollbar:new(
    1300, 225, 200, 15, -- topLeft X/Y and width/height
    Editor.currEnemyPerWave, 50,  -- min/max
    4)     -- id

Editor.spawnIntervalScrollbar = CScrollbar:new(
    1300, 255, 200, 15, -- topLeft X/Y and width/height
    Editor.currSpawnInterval * 10, 20,  -- min/max
    5)     -- id

-- List box
Editor.waveListbox = CListbox:new(
    1225, 325, 325, 200,
    6
)

-- Save file button
Editor.saveFileButton = CButton:new(1250, 700, 300, 70, 1500, "Save Level", "Resources/Fonts/myfont.xml")
Editor.saveFileEditbox = CEditbox:new(1280, 650, 230, 30)
Editor.saveFileEditbox:setText("default")
Editor.saveFileEditboxTip = CText:new(1340, 620, 300, 40, "Save File Name", "Resources/Fonts/smallerfont.xml")

-- Load file
Editor.loadFileButton = CButton:new(1250, 790, 300, 70, 1501, "Load Level", "Resources/Fonts/myfont.xml")
Editor.selectFileButton = CButton:new(1320, 860, 160, 30, 1337, "SELECT FILE", "Resources/Fonts/smallerfont.xml")


-- ====================== EDITOR FUNCTIONS

function clearEditor()
    Editor = nil
    clearGUI()
end

function Editor:run(dt)
    if (firstTime) then
        -- Default wave time
        Editor:submitWavePauseTime()
        firstTime = false
    end

    if (isKeyPressed("1")) and (cam.active) then
        currentTool = "BaseTool"
        toolText:setText(currentTool)
        --print("Current tool is: " .. currentTool)
    elseif (isKeyPressed("2")) and (cam.active) then
        currentTool = "WaypointTool"
        toolText:setText(currentTool)
       -- print("Current tool is: " .. currentTool)
    elseif (isKeyPressed("3")) and (cam.active) then
        currentTool = "EnemySpawnTool"
        toolText:setText(currentTool)
        --print("Current tool is: " .. currentTool)  
    elseif (isKeyPressed("4")) and (cam.active) then
        currentTool = "ValidTool"
        toolText:setText(currentTool)
        --print("Current tool is: " .. currentTool)
    elseif (isKeyPressed("G")) then
        cam:toggleActive()
        currentTool = "NoTool"
        toolText:setText(currentTool)
    end
    
    -- Enemy Spawn + Waypoint
    if (currentTool == "WaypointTool") then
        if (isKeyPressed("R")) then
            orchestrator:resetWaypoints()
            orchestrator:resetWaveSystem()
        elseif (isLMBpressed()) then
            if (base == nil) then log("Can't place waypoints unless the base has been placed..")
            else orchestrator:addWaypoint(castTargetName) end
        end
    end

    -- Start enemy wave system
    if (currentTool == "EnemySpawnTool") then
        if (isLMBpressed()) then
            orchestrator:startWaveSystem()
        end
    end

    -- Base tool
    if (currentTool == "BaseTool") then
        if (isRMBpressed()) then
            -- Remove base
            local wasBase = cells[castTargetName]:getType() == "Base"

            for k, v in pairs(enemies) do
                v.cRep:toggleVisible()
            end
            enemies = {}
            cells[castTargetName]:removeBase()
            
            if (wasBase) then
                orchestrator:resetWaypoints()   -- force reset waypoints if move base
            end
        elseif (isLMBpressed()) then
            -- Place base
            if (base == nil) and (cells[castTargetName]:getType() == "Valid") then
                cells[castTargetName]:setCellType("Base")
                cells[castTargetName]:placeBase()
            elseif (cells[castTargetName]:getType() == "Invalid") then
                --print("Cant place base here!")
                log("Cant place base here!")
            else
                --print("Base already placed!")
                log("Base already placed!")
            end
        end
    end

    -- Valid tool
    if (currentTool == "ValidTool") then
        if (isLMBpressed()) then
            if (cells[castTargetName]:getType() == "Valid") then
                cells[castTargetName]:setCellType("Invalid")
                cells[castTargetName].cRep:setTexture("resources/textures/lavainvalid.jpg")
                invalids[castTargetName] = castTargetName
            end

        elseif (isRMBpressed()) then
            if (cells[castTargetName]:getType() == "Invalid") then
                cells[castTargetName]:setCellType("Valid")
                cells[castTargetName].cRep:setTexture("resources/textures/sand.jpg")
                invalids[castTargetName] = nil
            end
        elseif (isKeyPressed("R")) then
            for k, cellID in pairs(invalids) do
                cells[cellID]:setCellType("Valid")
                cells[cellID].cRep:setTexture("resources/textures/sand.jpg")
            end
            invalids = {}
        end
    end
end

function Editor:addWave(epw, si)
    table.insert(self.waveList, { enemyPerWave = epw, spawnInterval = si })
    Editor.waveListSubmitted = false

    -- Add to listbox
    self.waveListbox:addToList("Wave #" .. #self.waveList .. " --- En. Per W.: " .. 
    epw .. " --- " .. "Spawn Int.: " .. si)

    -- print("\n")
    -- for k, v in ipairs(self.waveList) do
    --     print(v.enemyPerWave .. " || " .. v.spawnInterval)
    -- end
end

function Editor:resetWaves()
    self.waveList = {}
end

function Editor:submitWave()
    if (orchestrator:isWaveSystemRunning()) then log("Wait until the enemy is done spawning..") return end 
    if (#self.waveList == 0) then log("Can't submit empty wave list..") return end 

    Editor.waveListSubmitted = true
    orchestrator:setWaveData(self.waveList)
end

function Editor:submitWavePauseTime()
    if (orchestrator:isWaveSystemRunning()) then log("Wait until the enemy is done spawning..") return end 
    orchestrator:setWavePauseTime(self.currTimeBetweenWaves)
end

function Editor:handleScrollbarEvent(guiID, value)
    if (guiID == 3) then
        self.currTimeBetweenWaves = value / 10
        self.timeBetweenWavesText:setText(self.currTimeBetweenWaves)
    elseif (guiID == 4) then
        self.currEnemyPerWave = value
        self.enemyPerWaveText:setText(self.currEnemyPerWave)
    elseif (guiID == 5) then
        self.currSpawnInterval = value / 10
        self.spawnIntervalText:setText(self.currSpawnInterval)
    end
end

function Editor:handleButtonClickEvent(guiID)
    if (guiID == 1) then
        -- Submit the levels wave pause time
        log("The levels wave pause time now set to " .. self.currTimeBetweenWaves .. " seconds")  
        self:submitWavePauseTime(self.currTimeBetweenWaves)
    elseif (guiID == 50) then
        -- Submit list to Orchestrator
        log("Waves have been submitted!")
        self:submitWave()

    elseif (guiID == 51) then
        -- Add to list
        self:addWave(self.currEnemyPerWave, self.currSpawnInterval)


    elseif (guiID == 52) then
        self.waveListbox:reset()
        self:resetWaves()

    -- Editor save level
    elseif (guiID == 1500) then
        local statusGood = LevelFileManager:saveCurrentState()
        if (statusGood) then LevelFileManager:saveToFile() end

    -- Editor load level
    elseif (guiID == 1501) then
        if (lastFilePathSelected == "") then log("Please select a file..") return end

        -- pause raycast for a second to avoid irrlicht raycast conflict (make time for garbage collection)
        cam:pauseRaycast(1)  

        LevelFileManager:loadFromFile(lastFilePathSelected)
        LevelFileManager:setWorldFromLoadedFile()
    end

end

return Editor
