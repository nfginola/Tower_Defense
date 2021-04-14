Vector = require("LuaScripts/Vector")


base = nil

tower_gid = 0
cell_gid = 0
enemy_gid = 0

towers = {}
cells = {}
enemies = {}

myWorldObject = nil
castTargetName = nil

function setCastTargetName(name)
    castTargetName = name
end

function init()
    print("[LUA]: Init")

    -- Init cells (addCubeSceneNodes)
    for i = 1, 50 do
        cells[i] = {}
        for u = 1, 50 do
            local id = string.format("cg%f", cell_gid)
            cells[id] = WorldObject.new(id)
            cells[id]:addCubeMesh()
            cells[id]:setPosition((i - 1) * 10.5, 0.0, (u - 1) * 10.5)
            cells[id]:setTexture("resources/textures/moderntile.jpg")
            cells[id]:addCasting()
            cells[id]:setPickable()
            cell_gid = cell_gid + 1
        end
    end

    -- Init base (addCubeSceneNodes) (single)
    base = WorldObject.new(777, 777)
    base:addCubeMesh()
    base:setTexture("resources/textures/modernbrick.jpg")
    base:setPosition(6 * 10.5, 10, 0)
    base:setScale(0.7, 1.3, 0.9)
    base:toggleBB()


    -- Init enemy (addSphereSceneNodes) (single)


end

function update(dt)
   -- print("[LUA]: dt: " .. dt)

    -- Handle Input (Call EvRec IsKeyDown in C++ from LUA with string mappings) 
    -- SetPosition (MovePlayer) (Call C++ and send the new positions) 

    -- Intersect check (Call C++)
    --> Get CELL
    --> Place a Tower
    --> Extra: Print Cell Type and Status (Inhabited or not)
    if (is_key_down("K")) then
        if (is_lmb_pressed()) then
            local id = string.format("eg%f", enemy_gid)
            enemies[id] = WorldObject.new(id)
            enemies[id]:addSphereMesh(5)
            enemies[id]:toggleBB()
            print("[LUA]: lmb pressed!")
      
            enemies[id]:setPosition(-10, 10, 0)
            local x, y, z = enemies[id]:getPosition()
            print(string.format("[LUA]: Pos: (%f, %f, %f)", x, y, z))
            enemy_gid = enemy_gid + 1
        end
    end

    for k, enemy in pairs(enemies) then
        local x1, y1, z1 = myWorldObject:getPosition()
        enemy:setPosition(x1 + 10 * dt, y1, z1);
    
    
        enemy:drawLine(base)
    
        if (enemy:collidesWith(base)) then
            print("[LUA]: Lost HP!")
            enemy:deleteExplicit()
            enemy = nil
        end
    end


    -- draw line from each enemy to tower
    if (myWorldObject) then
        for key, val in pairs(towers) do
            myWorldObject:drawLine(val)
        end
    end


    if (is_lmb_pressed()) then
        towers[tower_gid] = WorldObject.new(string.format("tg%f", tower_gid))
        towers[tower_gid]:addSphereMesh()
        towers[tower_gid]:setPickable()
        towers[tower_gid]:setScale(0.5, 2, 0.5);
        towers[tower_gid]:setTexture("resources/textures/modernbrick.jpg")

        local x, y, z = cells[castTargetName]:getPosition()
        towers[tower_gid]:setPosition(x, y + 10.0, z)

        tower_gid = tower_gid + 1
    end




end