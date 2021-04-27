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

enemies_to_delete = {}

-- Create FPS cam
cam = Camera:new()
cam:createFPSCam()

--[[

WAY TO SOLVE THE AMOUNT OF TOWER VS ENEMY CHECKING?

NO NEED!!
Christopher: Du behöver inte hantera den optimeringen

]]

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


    -- -- Initialize waypoints
    -- orchestrator:setSpawn("cg4,5")
    -- waypoints = { "cg1,5", "cg1,1", "cg3,1", "cg3,4", "cg5,4", "cg5,1", "cg8,1" }
    -- -- waypoints = { "cg1,1", "cg5,1" }
    -- for i = 1, #waypoints do
    --     orchestrator:addWaypoint(waypoints[i])
    -- end

end

-- BaseTool
-- WaypointTool
-- TowerTool
-- EnemyTool
current_tool = ""

function edit_mode(dt)
    if (isKeyPressed("1")) then
        current_tool = "BaseTool"
        print("Current tool is: " .. current_tool)
    elseif (isKeyPressed("2")) then
        current_tool = "WaypointTool"
        print("Current tool is: " .. current_tool)
    end
    
    -- Enemy Spawn + Waypoint
    if (current_tool == "WaypointTool") then
        if (isKeyPressed("R")) then
            orchestrator:resetWaypoints()
        elseif (isLMBpressed()) then
            orchestrator:addWaypoint(castTargetName)
        elseif (isKeyPressed("O")) then
            orchestrator:confirmWaypoints()
        end
    end


end

function update(dt)

    edit_mode(dt)

    if (isKeyPressed("3")) then
        current_tool = "TowerTool"
        print("Current tool is: " .. current_tool)
    elseif (isKeyPressed("4")) then
        current_tool = "EnemySpawnTool"
        print("Current tool is: " .. current_tool)
    end

    orchestrator:update(dt)

    -- Move camera with default FPS cam settings
    cam:move(dt)

    if (isKeyPressed("G")) then
        cam.cRep:toggleActive()
    end

    -- Cast ray and get target cell name
    castTargetName = cam:castRayForward()

    -- Toggle range visible
    if (isKeyPressed("H")) then
        towerRangeHidden = not towerRangeHidden -- Modify global in Tower.lua to sync visibility
        for k, tower in pairs(towers) do
            tower:toggleRangeVisible()
        end
    end

    -- Create enemy
    if (current_tool == "EnemySpawnTool") and (isLMBpressed()) then
        orchestrator:spawnEnemy()
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

    -- Place tower with CELL
    if (current_tool == "TowerTool") and (isLMBpressed()) then
        if (cells[castTargetName] ~= nil) and 
            (cells[castTargetName]:getStatus() == "Not Occupied") then

            if (towers[castTargetName] ~= nil) then error("Something is wrong!") end

            towers[castTargetName] = cells[castTargetName]:placeTower()
            
        else
            print("Cell occupied!")
        end
    end

    -- Delete with CELL
    if (current_tool == "TowerTool") and (isRMBpressed()) then
        if (cells[castTargetName] ~= nil) and (cells[castTargetName]:getStatus() == "Occupied") 
            and (cells[castTargetName]:getType() == "Valid") then
            cells[castTargetName]:removeTower()
            towers[castTargetName] = nil
        else
            print("No tower here")
        end
    end

    -- Remove the enemies marked for deletion
    for k, delete in pairs(enemies_to_delete) do
        enemies[k].cRep:removeNode()
        enemies[k] = nil
    end
    enemies_to_delete = {}  -- reset
    
end