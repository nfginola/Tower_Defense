Vector = require("LuaScripts/Vector")
WorldObject = require("LuaScripts/WorldObject")

base = nil
tower_gid = 0
cell_gid = 0
enemy_gid = 0

towers = {}
cells = {}
enemies = {}

occupied_cells = {} -- temp

enemies_to_delete = {}
towers_to_delete = {}

castTargetName = nil

-- v1 = Vector:new({ x = 1, z = 5})
-- v2 = Vector:new({x = 3, y = 2})

-- print(v1 + v2)

function createTowerOn(cell)
    towers[tower_gid] = WorldObject:new(string.format("tg%f", tower_gid))
    towers[tower_gid].cRep:addSphereMesh()
    towers[tower_gid].cRep:setPickable()
    towers[tower_gid].cRep:setScale(0.5, 2, 0.5);
    towers[tower_gid].cRep:setTexture("resources/textures/modernbrick.jpg")

    local x, y, z = cell.cRep:getPosition()
    towers[tower_gid].cRep:setPosition(x, y + 10.0, z)

    tower_gid = tower_gid + 1
end

function createBaseOn(cell)
    base = WorldObject:new(777, 777)
    base.cRep:addCubeMesh()
    base.cRep:setTexture("resources/textures/modernbrick.jpg")

    local cellPos = cell:getPosition()
    base.cRep:setPosition(cellPos.x, cellPos.y + 10, cellPos.z)
    base.cRep:setScale(0.7, 1.3, 0.9)
    base.cRep:toggleBB()
end



function init()
    print("[LUA]: Init")

    -- Init cells (addCubeSceneNodes)
    for i = 1, 7 do
        cells[i] = {}
        for u = 1, 7 do
            local id = string.format("cg%i", cell_gid)
            cells[id] = WorldObject:new(id)
            cells[id].cRep:addCubeMesh()
            cells[id]:setPosition((i - 1) * 10.5, 0.0, (u - 1) * 10.5)
            cells[id].cRep:setTexture("resources/textures/moderntile.jpg")
            cells[id].cRep:addCasting()
            cells[id].cRep:setPickable()
            cell_gid = cell_gid + 1
            print(id)
        end
    end

    createBaseOn(cells["cg42"])


end

function update(dt)
    --> Extra todo: Print Cell Type and Status (Inhabited or not)

    -- Create enemy
    if (isKeyDown("K")) then
        if (isLMBpressed()) then
            local id = string.format("eg%i", enemy_gid)
            enemies[id] = WorldObject:new(id)
            enemies[id].cRep:addSphereMesh(5)
            enemies[id].cRep:toggleBB()
            enemies[id].cRep:setPosition(-10, 10, 0)

            enemy_gid = enemy_gid + 1
        end
    end

    for k, enemy in pairs(enemies) do
        -- Move each enemy (hardcoded path)
        local enemyPos = enemy:getPosition()
        enemy:setPosition(enemyPos.x + 20 * dt, enemyPos.y, enemyPos.z);

        -- Draw line between each enemy and each tower when in range
        for a, tower in pairs(towers) do
            local towerPos = tower:getPosition()
            local lenTE = (enemyPos - towerPos):length()

            if (lenTE <= 30) then
                enemy.cRep:drawLine(tower.cRep)
            end
        end

        -- Check collisions Enemy vs Base
        if (enemy.cRep:collidesWith(base.cRep)) then
            print("[LUA]: Lost HP!") -- Should call some "Base:takeDamage"
            enemies_to_delete[k] = true
        end
    end

    -- Remove to deletes
    for k, delete in pairs(enemies_to_delete) do
        enemies[k].cRep:deleteExplicit()
        enemies[k] = nil
    end
    enemies_to_delete = {}  -- reset

    -- Place tower
    if (isLMBpressed()) then
        if (cells[castTargetName] ~= nil) and (occupied_cells[castTargetName] == nil) then
            createTowerOn(cells[castTargetName])
            occupied_cells[castTargetName] = true
        else
            print("Cell occupied!")
        end
    end
end