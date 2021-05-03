Vector = require("LuaScripts/Vector")
WorldObject = require("LuaScripts/WorldObject")
Camera = require("LuaScripts/Camera")
Cell = require("LuaScripts/Cell")
Enemy = require("LuaScripts/Enemy")
EnemyOrchestrator = require("LuaScripts/EnemyOrchestrator")


base = nil
towers = {}
cells = {}
enemies = {}
orchestrator = EnemyOrchestrator:new()

-- Ray cast target
castTargetName = nil

-- Marked for deletion
enemies_to_delete = {}

-- Create FPS cam
cam = Camera:new()
cam:createFPSCam()

-- BaseTool
-- WaypointTool
-- TowerTool
-- EnemyTool
-- ValidTool
current_tool = ""

invalids = {}


function init()
    print("[LUA]: Init")

    io.write("Enter desired X and Z dimensions of the level:\n")
    xLen = io.read("*n")
    zLen = io.read("*n")

    -- Init skybox
    -- top, bottom, left, right, front, back
    setSkyboxTextures(
        "resources/textures/skybox/py.png",
        "resources/textures/skybox/ny.png",
        "resources/textures/skybox/nx.png",
        "resources/textures/skybox/px.png",
        "resources/textures/skybox/pz.png",
        "resources/textures/skybox/nz.png"
    )
    
    -- Init cells
    for i = 1, xLen do
        cells[i] = {}
        for u = 1, zLen do
            local id = string.format("cg%i,%i", i, u)

            cells[id] = Cell:new(id, i, u)
            cells[id]:setCellType("Valid")      -- Make tower placeable
        end
    end


    baseCellID = string.format("cg%i,%i", xLen, 1)
    -- Place base
    cells[baseCellID]:setCellType("Base")
    cells[baseCellID]:placeBase()

end

--[[

    To-do:
        Irrlicht TextBox! (To add EnemyWave elements on the fly)

    --> Set up local table and insert Level variables and Wave configs
    --> Click some confirm button
    --> orchestrator:submitLevelConfig(tab)
        --> overwrite existing coroute function (with the configs)
        --> set level variables and wave coinfigs

]]

function edit_mode(dt)  
    if (isKeyPressed("1")) then
        current_tool = "BaseTool"
        toolText:setText(current_tool)
        --print("Current tool is: " .. current_tool)
    elseif (isKeyPressed("2")) then
        current_tool = "WaypointTool"
        toolText:setText(current_tool)
       -- print("Current tool is: " .. current_tool)
    elseif (isKeyPressed("5")) then
        current_tool = "ValidTool"
        toolText:setText(current_tool)
        --print("Current tool is: " .. current_tool)
    end
    
    -- Enemy Spawn + Waypoint
    if (current_tool == "WaypointTool") then
        if (isKeyPressed("R")) then
            orchestrator:resetWaypoints()
        elseif (isLMBpressed()) then
            orchestrator:addWaypoint(castTargetName)
        end
    end

    -- Base tool
    if (current_tool == "BaseTool") then
        if (isRMBpressed()) then
            -- Remove base
            local wasBase = cells[castTargetName]:getType() == "Base"

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
    if (current_tool == "ValidTool") then
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

function play_mode(dt)
    if (isKeyPressed("3")) then
        current_tool = "TowerTool"
        toolText:setText(current_tool)
        --print("Current tool is: " .. current_tool)
    elseif (isKeyPressed("4")) then
        current_tool = "EnemySpawnTool"
        toolText:setText(current_tool)
        --print("Current tool is: " .. current_tool)        
    end

    -- Create enemy
    if (current_tool == "EnemySpawnTool") then
        if (isLMBpressed()) then
            orchestrator:startWaveSystem()
        end
    end

    -- Place tower with CELL
    if (current_tool == "TowerTool") and (isLMBpressed()) then
        cells[castTargetName]:placeTower()
    end

    -- Delete with CELL
    if (current_tool == "TowerTool") and (isRMBpressed()) then
        cells[castTargetName]:removeTower()
    end

    -- Toggle tower range visible
    if (isKeyPressed("H")) then
        towerRangeHidden = not towerRangeHidden -- Modify global in Tower.lua to sync visibility
        for k, tower in pairs(towers) do
                tower:toggleRangeVisible()
        end
    end

end

function update_game_objects(dt)
    -- Go over all enemies and towers and set states
    for k, enemy in pairs(enemies) do
        local enemyPos = enemy:getPosition()
        enemy:update(dt)

        -- Check collisions Enemy vs Base
        local baseCollided = enemy:collidesWith(base)
        if (baseCollided) then
            -- Force enemy death when it collides with base
            enemy:kill()
            base:takeDamage(enemy.damage)
        end

        -- Check Enemy vs Tower
        for a, tower in pairs(towers) do
            local lenTE = lengthBetween(enemy, tower)

            if (lenTE <= tower:getMaxRange()) then
                tower:onEnemyEnter(enemy)
            else
                tower:onEnemyLeave(enemy)
            end

            -- We force leave all dead enemies from the Towers enemy list
            if (enemy:isDead()) then
                tower:onEnemyLeave(enemy)
            end
        end

        -- Mark to delete if enemy died
        if (enemy:isDead()) then
            enemies_to_delete[k] = true
        end
    end

    -- Update all towers (act upon state set on Towers)
    for k, tower in pairs(towers) do
        tower:update(dt)        
    end

    -- Remove the enemies marked for deletion
    for k, delete in pairs(enemies_to_delete) do
        enemies[k].cRep:removeNode()
        enemies[k] = nil
    end
    enemies_to_delete = {}  -- Reset enemies marked for deletion
end

canWin = true
function update_game_state(dt)

    -- Check win state
    if (orchestrator:isDoneSpawning()) and (get_table_length(enemies) == 0) and (not base:isDead()) then
        if (canWin) then
            --print("You've won the game!")
            -- Temporary "Won game"
            log("You've won the game!")
            canWin = false
        end
    end


end

function update_gui_anims(dt)
    -- Timer for log transparency interpolation
    logTimer = logTimer + dt
    local fac = logTimer/maxLogTime -- [0, 1]
    local transparency = 255 * (1 - fac)
    if (fac > 1) then
        logText:setColor(0, 0, 0, 0)
    else
        logText:setColor(0, 0, 0, transparency)
    end
end

function update(dt) 
    -- Cast ray and get target cell name
    castTargetName = cam:castRayForward()

    edit_mode(dt)
    play_mode(dt)

    orchestrator:update(dt)

    -- Move camera with default FPS cam settings
    cam:move(dt)

    if (isKeyPressed("G")) then
        cam:toggleActive()
        current_tool = "None"
        toolText:setText(current_tool)
    end

    update_game_objects(dt)
    update_game_state(dt)
    update_gui_anims(dt)

end


-- ======================== GUI

setGlobalGUIFont("Resources/Fonts/smallerfont.xml")

-- clearGUI() requires all GUI elements to be nil! 
-- GUI TEST
logText = CText:new(20, 20, 600, 300, "Error text", "Resources/Fonts/myfont.xml")

toolText = CText:new(700, 20, 400, 70, "Tool", "Resources/Fonts/myfont.xml")


-- Level
timeBetweenWavesText = CText:new(1510, 75, 30, 15, "0.0", "Resources/Fonts/smallerfont.xml")
timeBetweenWavesText:setBGColor(255, 255, 255, 255)
levelEditText = CText:new(1300, 35, 400, 60, "Wave Pause Time", "Resources/Fonts/myfont.xml")

-- Wave
spawnIntervalText = CText:new(1510, 255, 30, 15, "0.0", "Resources/Fonts/smallerfont.xml")
spawnIntervalText:setBGColor(255, 255, 255, 255)
spawnIntervalEditText = CText:new(1310, 280, 300, 15, "Enemy Spawn Interval", "Resources/Fonts/smallerfont.xml")

enemyPerWaveText = CText:new(1510, 225, 30, 15, "1.0", "Resources/Fonts/smallerfont.xml")
enemyPerWaveText:setBGColor(255, 255, 255, 255)
enemyPerWaveEditText = CText:new(1310, 200, 300, 15, "Enemy Per Wave", "Resources/Fonts/smallerfont.xml")


-- GUI that uses ID
levelEditSubmitButton = CButton:new(1150, 75, 140, 60, 1, "SUBMIT!", "Resources/Fonts/myfont.xml")


waveEditSubmitButton = CButton:new(1250, 540, 140, 60, 50, "SUBMIT!", "Resources/Fonts/myfont.xml")
waveEditAddButton = CButton:new(1150, 225, 140, 60, 51, "ADD!", "Resources/Fonts/myfont.xml")
waveEditResetButton = CButton:new(1411, 540, 140, 60, 52, "RESET!", "Resources/Fonts/myfont.xml")

-- Scroll bar
levelWavePauseScrollbar = CScrollbar:new(
    1300, 75, 200, 15, -- topLeft X/Y and width/height
    0, 100,  -- min/max
    3)     -- id

enemyPerWaveScrollbar = CScrollbar:new(
    1300, 225, 200, 15, -- topLeft X/Y and width/height
    1, 50,  -- min/max
    4)     -- id

spawnIntervalScrollbar = CScrollbar:new(
    1300, 255, 200, 15, -- topLeft X/Y and width/height
    0, 20,  -- min/max
    5)     -- id

-- List box
wavesListbox = CListbox:new(
    1225, 325, 325, 200,
    6
)

-- Open file test (for Edit mode and Start Game)
fileButtonTest = CButton:new(800, 800, 160, 60, 1337, "OPEN FILE!", "Resources/Fonts/myfont.xml")


currEnemyPerWave = 0
currSpawnInterval = 0
currTimeBetweenWaves = 0

-- Events from Irrlicht
function scrollbarEvent(guiID, value)
    if (guiID == 3) then
        currTimeBetweenWaves = value / 10
        timeBetweenWavesText:setText(currTimeBetweenWaves)
    elseif (guiID == 4) then
        currEnemyPerWave = value
        enemyPerWaveText:setText(currEnemyPerWave)
    elseif (guiID == 5) then
        currSpawnInterval = value / 10
        spawnIntervalText:setText(currSpawnInterval)
    end

end

function buttonClickEvent(guiID)
    if (guiID == 1337) then
        openFileDialog()
    elseif (guiID == 1) then
        -- Submit the levels wave pause time
        log("The levels wave pause time now set to " .. currTimeBetweenWaves .. " seconds")  
    elseif (guiID == 50) then
        -- Submit list to Orchestrator
        log("Waves have been submitted!")

    elseif (guiID == 51) then
        -- Add to list
        wavesListbox:addToList("Wave #0 --- En. Per W.: " .. currEnemyPerWave .. " --- " .. "Spawn Int.: " .. currSpawnInterval)
    elseif (guiID == 52) then
        wavesListbox:reset()
    end
end
    
function fileSelected(path)
    print("path: " .. path)

end

maxLogTime = 2
logTimer = maxLogTime + 1   -- keep it hidden in the beginning
function log(text)
    logText:setText(text)
    logTimer = 0
end

-- ======================= Helpers below

function get_table_length(tab)
    local count = 0
    for k, v in pairs(tab) do
        count = count + 1
    end
    return count
end

function getSmallerAndBigger(val1, val2)
    if (val2 < val1) then
        val1, val2 = val2, val1
    end

    return val1, val2
end
