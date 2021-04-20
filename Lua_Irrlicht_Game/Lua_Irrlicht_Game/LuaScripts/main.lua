Vector = require("LuaScripts/Vector")
WorldObject = require("LuaScripts/WorldObject")
Camera = require("LuaScripts/Camera")
Cell = require("LuaScripts/Cell")


tower_gid = 0 -- ready to delete
enemy_gid = 0

base = nil
towers = {} -- used to more easily keep track of existing towers (rather than searching the cells)
cells = {}
enemies = {}

enemies_to_delete = {}

-- Create FPS cam
cam = Camera:new()
cam:createFPSCam()

--[[
    Idea:

Tower inherits from WorldObject
- damage attr
- attackspeed attr

Base inherits form WorldObject

Enemy inherits from WorldObject
- hp attr
- speed attr
- damage (to base) attr

Cell is a CONTAINER that has:
- Cell WorldObject
- Inhabitant WorldObject (Tower)
- occupied bool
- TYPE: "Placeable", "Invalid", "Waypoint", "Base" (?)

x Cell has easy functions:
Cell.placeTower()
Cell.removeTower()
Cell.placeBase() : note, only one global base! this is just to make it easy


WAY TO SOLVE THE AMOUNT OF TOWER VS ENEMY CHECKING!

NO NEED!!
Christopher: Du behöver inte hantera den optimeringen


-------------

tower.attack(enemy) --> (inside) enemy.takeDamage(tower.damage)

-------------

Tower 1 Selected --> LMB --> Find the cell --> Check if it is Occupied --> If not, create tower there, if it is: Print occupied

]]

function createTowerOn(cell)
    --towers[tower_gid] = WorldObject:new(string.format("tg%i", tower_gid))
    towers[tower_gid] = WorldObject:new()
    towers[tower_gid]:initCRep(string.format("tg%i", tower_gid))
    towers[tower_gid].cRep:addSphereMesh(5)
    towers[tower_gid].cRep:setPickable()
    towers[tower_gid].cRep:setScale(0.6, 1.5, 0.6);
    towers[tower_gid].cRep:setTexture("resources/textures/modernbrick.jpg")

    local cellPos = cell:getPosition()
    towers[tower_gid].cRep:setPosition(cellPos.x, cellPos.y + 10.0, cellPos.z)

    --yeah = WorldObject:new(string.format("tg%i", tower_gid))
    yeah = WorldObject:new()
    yeah:initCRep(string.format("tg%i", tower_gid))
    yeah.cRep:addSphereMesh(20)
    yeah.cRep:setScale(1, 0.1, 1);
    yeah.cRep:setTexture("resources/textures/green.png")
    yeah.cRep:setTransparent()

    yeah.cRep:setPosition(cellPos.x, cellPos.y + 10.0, cellPos.z)

    tower_gid = tower_gid + 1
end

function createBaseOn(cell)
    -- base = WorldObject:new(777, 777)
    base = WorldObject:new()
    base:initCRep("777")
    base.cRep:addCubeMesh()
    base.cRep:setTexture("resources/textures/modernbrick.jpg")

    local cellPos = cell:getPosition()
    base.cRep:setPosition(cellPos.x, cellPos.y + 10, cellPos.z)
    base.cRep:setScale(0.7, 1.3, 0.9)
    base.cRep:toggleBB()
end

function init()
    print("[LUA]: Init")

    io.write("Enter desired X and Z dimensions of the level:\n")
    xLen = io.read("*n")
    zLen = io.read("*n")

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
    base = cells[baseCellID]:placeBase()
end

time = 0

function update(dt)
    -- TO DO:
    -- Base rep (inherit WO)
    -- Enemy rep (inherit WO)

    -- Move camera with default FPS cam settings
    cam:move(dt)





    -- Cast ray and get target cell
    castTargetName = cam:castRayForward()
    time = time + dt
    if (time >= 0.5) then
        print(castTargetName)
        time = 0
    end




    -- Create enemy
    if (isKeyDown("K")) then
        if (isLMBpressed()) then
            local id = string.format("eg%i", enemy_gid)
            --enemies[id] = WorldObject:new(id)
            enemies[id] = WorldObject:new()
            enemies[id]:initCRep(id)
            enemies[id].cRep:addSphereMesh(5)
            enemies[id].cRep:toggleBB()
            enemies[id].cRep:setPosition(-10, 10, 0)

            enemy_gid = enemy_gid + 1
        end
    end

    -- Go over all enemies and towers
    for k, enemy in pairs(enemies) do
        -- Move each enemy (hardcoded path)
        local enemyPos = enemy:getPosition()
        enemy:setPosition(enemyPos.x + 20 * dt, enemyPos.y, enemyPos.z);

        -- Draw line between each enemy and each tower when in range
        for a, tower in pairs(towers) do
            local towerPos = tower:getPosition()

            -- if (math.abs(enemyPos.x - towerPos.x) < 30) and
            --     (math.abs(enemyPos.y - towerPos.y) < 30) and
            --     (math.abs(enemyPos.z - towerPos.z) < 30) 
            --     then
                -- no need to fix this now (unless critical)
                enemy.cRep:drawLine(tower.cRep)
                local lenTE = (enemyPos - towerPos):length()
                -- if (lenTE <= 30) then
                --     enemy.cRep:drawLine(tower.cRep)
                -- end
            -- end
        end

        -- Check collisions Enemy vs Base
        if (enemy:collidesWith(base)) then
            --print("[LUA]: Lost HP!") -- Should call some "Base:takeDamage"
            enemies_to_delete[k] = true
        end
    end

    -- Remove to deletes
    for k, delete in pairs(enemies_to_delete) do
        enemies[k].cRep:removeNode()
        enemies[k] = nil
    end
    enemies_to_delete = {}  -- reset






    -- Place tower with CELL
    if (isLMBpressed()) then
        if (cells[castTargetName] ~= nil) and 
            (cells[castTargetName]:getStatus() == "Not Occupied") then

            if (towers[castTargetName] ~= nil) then error("Something is wrong!") end

            towers[castTargetName] = cells[castTargetName]:placeTower()
            
        else
            print("Cell occupied!")
        end
    end

    -- Delete with CELL
    if (isRMBpressed()) then
        if (cells[castTargetName] ~= nil) and (cells[castTargetName]:getStatus() == "Occupied") 
            and (cells[castTargetName]:getType() == "Valid") then
            cells[castTargetName]:removeTower()
            towers[castTargetName] = nil
        else
            print("No tower here")
        end
    end
end