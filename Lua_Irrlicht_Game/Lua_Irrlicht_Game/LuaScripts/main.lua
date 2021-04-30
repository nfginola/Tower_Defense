Vector = require("LuaScripts/Vector")
WorldObject = require("LuaScripts/WorldObject")
Camera = require("LuaScripts/Camera")
Cell = require("LuaScripts/Cell")
Enemy = require("LuaScripts/Enemy")
EnemyOrchestrator = require("LuaScripts/EnemyOrchestrator")

--[[
ImporterExporter --> Talks directly with associated entities (e.g Global orchestrator, base, cells, etc.) during init
--> Talks directly with above entities when ordered to submit to file!
]]

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

function edit_mode(dt)  
    if (isKeyPressed("1")) then
        current_tool = "BaseTool"
        print("Current tool is: " .. current_tool)
    elseif (isKeyPressed("2")) then
        current_tool = "WaypointTool"
        print("Current tool is: " .. current_tool)
    elseif (isKeyPressed("5")) then
        current_tool = "ValidTool"
        print("Current tool is: " .. current_tool)
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
            if (base == nil) then
                cells[castTargetName]:setCellType("Base")
                cells[castTargetName]:placeBase()
            else
                print("Base already placed!")
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

            -- print("\n")
            -- for k, v in pairs(invalids) do
            --     print(k, ": ", v)
            -- end

        elseif (isRMBpressed()) then
            if (cells[castTargetName]:getType() == "Invalid") then
                cells[castTargetName]:setCellType("Valid")
                cells[castTargetName].cRep:setTexture("resources/textures/sand.jpg")
                invalids[castTargetName] = nil
            end

            -- print("\n")
            -- for k, v in pairs(invalids) do
            --     print(k, ": ", v)
            -- end


        end
    end
end

function play_mode(dt)
    if (isKeyPressed("3")) then
        current_tool = "TowerTool"
        print("Current tool is: " .. current_tool)
    elseif (isKeyPressed("4")) then -- Temp dev tool
        current_tool = "EnemySpawnTool"
        print("Current tool is: " .. current_tool)
    end

    -- Create enemy
    if (current_tool == "EnemySpawnTool") and (isLMBpressed()) then
        orchestrator:spawnEnemy()
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

function update(dt)

    -- Cast ray and get target cell name
    castTargetName = cam:castRayForward()

    edit_mode(dt)
    play_mode(dt)

    -- Let orchestrator give visual feedback (lines)
    orchestrator:update(dt)

    -- Move camera with default FPS cam settings
    cam:move(dt)

    if (isKeyPressed("G")) then
        cam:toggleActive()
    end


    -- Go over all enemies and towers and set states
    for k, enemy in pairs(enemies) do
        local enemyPos = enemy:getPosition()
        enemy:update(dt)

        -- Check collisions Enemy vs Base
        local baseCollided = enemy:collidesWith(base)
        if (baseCollided) then
            -- Force enemy death when it collides with base
            enemy:kill()
            base:takeDamage(10)

            if (base:isDead()) then
                print("Base died!")
            end
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
    enemies_to_delete = {}  -- reset
    
end