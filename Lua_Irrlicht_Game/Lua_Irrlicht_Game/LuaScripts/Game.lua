local Game = {}

local currency = "Water Droplets"
-- ============== GUI
local winText = nil
local baseHP = nil
local moneyText = nil

Game.helpText1 = nil
Game.helpText2 = nil
Game.quitText = nil
Game.ready = false

-- ============== Game start
local gameStartTime = 10
local beforeGameTimer = 0

local logBeforeGameTimer = 2
local logBeforeGameInterval = 1

-- ============== Game quit
local gameQuitTime = 15
local quitTimer = 0

local logQuitTimer = 2
local logGameQuitInterval = 1

-- ============== State
local canWin = true
local gameStarted = false
local won = false
local money = 0   -- Set by file
local moneyPerSec = 4

local placeTowerCost = 21
local refundTowerGet = 15

function Game:start()
    local statusGood = LevelFileManager:loadFromFile(lastFilePathSelected)
    if (not statusGood) then return statusGood end

    LevelFileManager:setWorldFromLoadedFile() 

    self.quitText = CText:new(1130, 20, 500, 30, "Press ESC: Go to Main Menu", "Resources/Fonts/myfont.xml")
    self.helpText1 = CText:new(1130, 60, 500, 50, "Press H: Show/Hide Tower Range", "Resources/Fonts/myfont.xml")
    self.helpText2 = CText:new(1130, 100, 500, 70, "Click LMB/RMB to Place/Remove Tower", "Resources/Fonts/myfont.xml")

    baseHP = CText:new(20, 200, 600, 50, "Base HP: " .. tostring(base:getHP()), "Resources/Fonts/myfont.xml")
    moneyText = CText:new(20, 250, 600, 50, currency .. ": " .. tostring(money), "Resources/Fonts/myfont.xml")

    self.ready = true
    return statusGood
end

function Game:initMoney(curr)
    money = curr
end

function Game:isReady()
    return self.ready
end

function Game:updateBaseHPText(hp)
    baseHP:setText("Base HP: " .. tostring(hp))
end

function Game:setMoney(newMoney)
    money = newMoney
    moneyText:setText(currency .. ": " .. tostring(math.floor(money)))
end

function Game:handleControls(dt)
    if (isKeyPressed("1")) then
        currentTool = "TowerTool"
        toolText:setText(currentTool)
        --print("Current tool is: " .. currentTool)
      
    end

    -- Place tower with CELL
    if (currentTool == "TowerTool") and (isLMBpressed()) then
        if (money - placeTowerCost < 0) then log("Not enough " .. currency .. " to place tower!") return end

        local statusGood = cells[castTargetName]:placeTower()
        if (statusGood) then
            self:setMoney(money - placeTowerCost)
            log("Bought tower for " .. tostring(placeTowerCost) .. " " .. currency)
        end

    end

    -- Delete with CELL
    if (currentTool == "TowerTool") and (isRMBpressed()) then
        local statusGood = cells[castTargetName]:removeTower()
        if (statusGood) then
            log("Refunded tower for " .. tostring(refundTowerGet) .. " " .. currency)
            self:setMoney(money + refundTowerGet)
        end
    end

    -- Toggle tower range visible
    if (isKeyPressed("H")) then
        towerRangeHidden = not towerRangeHidden -- Modify global in Tower.lua to sync visibility
        for k, tower in pairs(towers) do
                tower:toggleRangeVisible()
        end
    end
end

function Game:handleWinOrLoseState()
    if (not orchestrator:isWaveSystemRunning()) and (getTableLength(enemies) == 0) and (not base:isDead()) then
        if (canWin) then
            --log("You've won the game!")
            canWin = false
            winText = CText:new(700, 120, 400, 70, "YOU WON!", "Resources/Fonts/largefont.xml")
        end
    elseif (base:isDead()) then
        if (canWin) then
            --log("You've won the game!")
            canWin = false
            winText = CText:new(700, 120, 400, 70, "YOU LOST!", "Resources/Fonts/largefont.xml")
            orchestrator:resetWaveSystem()
        end
    end
end

function Game:countdownBeforeGameStart(dt)
    beforeGameTimer = beforeGameTimer + dt
    logBeforeGameTimer = logBeforeGameTimer + dt

    if (logBeforeGameTimer > logBeforeGameInterval) then
        log("Game starts in.. " .. tostring(math.ceil(gameStartTime - beforeGameTimer)))
        logBeforeGameTimer = 0
    end

    if (beforeGameTimer > gameStartTime) then
        orchestrator:startWaveSystem()
        gameStarted = true
    end

end

function Game:countdownToExit(dt)
    quitTimer = quitTimer + dt
    logQuitTimer = logQuitTimer + dt

    if (logQuitTimer > logGameQuitInterval) then
        log("Going back to main menu in.. " .. tostring(math.ceil(gameQuitTime - quitTimer)))
        logQuitTimer = 0
    end

    if (quitTimer > gameQuitTime) then
        resetLuaState()
    end
end

function Game:run(dt)
    if (not gameStarted) then
        self:countdownBeforeGameStart(dt)
    else
        self:handleWinOrLoseState()

        if (canWin) then
            self:setMoney(money + moneyPerSec * dt)
        end
    end

    self:handleControls(dt)

    if (not canWin) then
        self:countdownToExit(dt)
    end
   
end


return Game