Vector = require("LuaScripts/Vector")
WorldObject = require("LuaScripts/WorldObject")
Camera = require("LuaScripts/Camera")
Cell = require("LuaScripts/Cell")
Enemy = require("LuaScripts/Enemy")
EnemyOrchestrator = require("LuaScripts/EnemyOrchestrator")
LevelFileManager = require("LuaScripts/LevelFileManager")
MainMenu = require("LuaScripts/MainMenu")
Game = require("LuaScripts/Game")

Editor = nil

setGlobalGUIFont("Resources/Fonts/smallerfont.xml")

worldGridSize = { x = 0, z = 0 }
base = nil
towers = {}
cells = {}
enemies = {}
invalids = {}
orchestrator = EnemyOrchestrator:new()

-- GUI
logText = CText:new(20, 20, 600, 300, "Error text", "Resources/Fonts/myfont.xml")
toolText = nil


-- Game state ("Menu", "Play" or "Edit")
gameState = "Menu"

-- Ray cast target
castTargetName = nil

-- Marked for deletion
enemiesToDelete = {}

cam = nil

function startGame()
    cam = Camera:new()
    cam:createFPSCam()

    toolText = CText:new(700, 20, 400, 70, "Tool", "Resources/Fonts/myfont.xml")

    Game:start()

end

function startEditor(xGridSet, zGridSet)
    Editor = require("LuaScripts/Editor")

    toolText = CText:new(700, 20, 400, 70, "Tool", "Resources/Fonts/myfont.xml")

    cam = Camera:new()
    cam:createFPSCam()

    Editor:start(xGridSet, zGridSet)
end

function init()
    print("[LUA]: Init")

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

end

function updateGameObjects(dt)
    -- Go over all enemies and towers and set states
    for k, enemy in pairs(enemies) do
        local enemyPos = enemy:getPosition()
        enemy:update(dt)

        -- Check collisions Enemy vs Base
        local baseCollided = enemy:collidesWith(base)
        if (baseCollided) then
            -- Force enemy death when it collides with base
            enemy:kill()
            if (gameState == "Play") then
                base:takeDamage(enemy.damage)
                Game:updateBaseHPText(base:getHP())
            end
        end

        -- Check Enemy vs Tower
        for a, tower in pairs(towers) do

            -- Naive range check
            -- We compare squares to avoid having to do sqrts..
            local lenTE = lengthBetweensq(enemy, tower)

            if (lenTE <= tower:getMaxRange() * tower:getMaxRange()) then
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
            enemiesToDelete[k] = true
        end
    end

    -- Update all towers (act upon state set on Towers)
    for k, tower in pairs(towers) do
        tower:update(dt)        
    end

    -- Remove the enemies marked for deletion
    for k, delete in pairs(enemiesToDelete) do
        enemies[k].cRep:removeNode()
        enemies[k] = nil
    end
    enemiesToDelete = {}  -- Reset enemies marked for deletion
end

function updateLogTextAnim(dt)
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

function updateGuiAnims(dt)
    updateLogTextAnim(dt)
end

dtimer = 0
function update(dt) 
    if (cam ~= nil) then
        -- Cast ray and get target cell name
        castTargetName = cam:castRayForward()
        -- Move camera with default FPS cam settings
        cam:move(dt)
    end

    -- dtimer = dtimer + dt
    -- if (dtimer > 0.25) then
    --     print(castTargetName)
    --     dtimer = 0
    -- end


    if (gameState == "Edit") and (Editor ~= nil) then
        Editor:run(dt)
    elseif (gameState == "Play") then
        Game:run(dt)
    elseif (gameState == "Menu") then
        MainMenu:run(dt)
    end

    orchestrator:update(dt)

    updateGameObjects(dt)
    updateGuiAnims(dt)

    -- Exit app
    if (isKeyPressed("ESC")) then
        exitApp()
    end
end

-- ===================== GUI Events
function scrollbarEvent(guiID, value)
    if (gameState == "Edit") then
        Editor:handleScrollbarEvent(guiID, value)
    elseif (gameState == "Play") then
        log("Handle scrollbar in Play mode..")
    elseif (gameState == "Menu") then
        MainMenu:handleScrollbarEvent(guiID, value)
    end

end

function buttonClickEvent(guiID)
    if (gameState == "Edit") then
        Editor:handleButtonClickEvent(guiID)
    elseif (gameState == "Play") then
        log("Handle scrollbar in Play mode..")
    elseif (gameState == "Menu") then
        MainMenu:handleButtonClickEvent(guiID)
    end

end
    
lastFilePathSelected = ""
function fileSelected(path)
    lastFilePathSelected = path
end

-- ====================== GUI Log

-- Log text that disappears over time.. :)
maxLogTime = 2
logTimer = maxLogTime + 1   -- keep it hidden in the beginning
function log(text)
    logText:setText(text)
    logTimer = 0
end

-- ======================= Helpers below
function resetWorldState()
    if (base ~= nil) then
        base.cRep:toggleVisible()   -- immediate hide 
    end
    base = nil
    
    for k, v in pairs(cells) do
        v.cRep:toggleVisible()
    end
    cells = {}
    
    for k, v in pairs(enemies) do
        v.cRep:toggleVisible()
    end
    enemies = {}

    towers = {}
    invalids = {}
    orchestrator = EnemyOrchestrator:new()
    worldGridSize = { x = 0, z = 0 }
end

function getTableLength(tab)
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

function split(str, delim)
    local toSplit = str .. delim    -- append delim at end
    local elements = {}
    for element in (toSplit):gmatch("([^" .. delim .. "]*)" .. delim) do 
        table.insert(elements, element) 
    end

    return elements
end