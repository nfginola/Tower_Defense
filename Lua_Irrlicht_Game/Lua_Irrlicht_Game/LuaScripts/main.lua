Vector = require("LuaScripts/Vector")
WorldObject = require("LuaScripts/WorldObject")
Camera = require("LuaScripts/Camera")
Cell = require("LuaScripts/Cell")
Enemy = require("LuaScripts/Enemy")

base = nil
towers = {}
cells = {}
enemies = {}

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

function update(dt)
    -- Move camera with default FPS cam settings
    cam:move(dt)

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
    if (isKeyDown("K")) then
        if (isLMBpressed()) then
            local newEnemy = Enemy:new(
                id, 
                { x = -10, y = 10, z = 0}, 
                { maxHealth = 30, damage = 10, unitsPerSec = 10}
            )
            enemies[newEnemy.id] = newEnemy
        end
    end

    -- Go over all enemies and towers and set states
    for k, enemy in pairs(enemies) do
        local enemyPos = enemy:getPosition()
        enemy:setPosition(enemyPos.x + 20 * dt, enemyPos.y, enemyPos.z);

        -- Check collisions Enemy vs Base
        local baseCollided = enemy:collidesWith(base)
        if (baseCollided) then
            -- Force enemy death when it collides with base
            enemy:die()
            base:takeDamage(10)

            print("HP: " .. base:getHealth())
            if (base:getHealth() <= 0) then
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

    -- Remove the enemies marked for deletion
    for k, delete in pairs(enemies_to_delete) do
        enemies[k].cRep:removeNode()
        enemies[k] = nil
    end
    enemies_to_delete = {}  -- reset
    
end