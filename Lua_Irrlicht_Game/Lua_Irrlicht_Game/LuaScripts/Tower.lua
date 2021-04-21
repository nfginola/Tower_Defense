WorldObject = require("LuaScripts/WorldObject")

local Tower = WorldObject:new()

-- Global
towerRangeHidden = true

function Tower:new(cellID, cellPosition, towerStats)

    if (type(towerStats) ~= "table") then error("Tower Stats must be a table!") end
    if (towerStats.damage == nil) then error("Tower Stats must have a 'damage' attribute!") end
    if (towerStats.shotsPerSec == nil) then error("Tower Stats must have a 'shotsPerSec' attribute!") end
    if (towerStats.range == nil) then error("Tower Stats must have a 'range' attribute!") end

    local t = 
    {
        id = nil,
        damage = towerStats.damage,
        shotsPerSec = towerStats.shotsPerSec,
        maxRange = towerStats.range,
        rangeMesh = nil,

        timer = 0,
        readyToShoot = true,

        enemiesInRange = {},
        enemiesInRangeID = 1,

        targetEnemy = nil
    }

    self.__index = self
    setmetatable(t, self) 

    t.id = cellID .. "_t"
    t:initCRep(t.id)
    t.cRep:addSphereMesh(5)
    t.cRep:setPickable()
    t.cRep:setScale(0.6, 1.5, 0.6);
    t.cRep:setTexture("resources/textures/modernbrick.jpg")

    t.cRep:setPosition(cellPosition.x, cellPosition.y + 10.0, cellPosition.z)

    -- setup range mesh
    t.rangeMesh = WorldObject:new()
    t.rangeMesh:initCRep(t.id .. "_r")
    t.rangeMesh.cRep:addSphereMesh(t.maxRange)
    t.rangeMesh.cRep:setScale(1, 0.1, 1);
    t.rangeMesh.cRep:setTexture("resources/textures/green.png")
    t.rangeMesh.cRep:setTransparent()
    t.rangeMesh.cRep:setPosition(cellPosition.x, cellPosition.y + 10.0, cellPosition.z)

    -- Sync range visibility with main program when creating new tower
    if (towerRangeHidden == true) then
        t.rangeMesh.cRep:toggleVisible()
    end

    return t
end

function Tower:update(dt)
    if (self.readyToShoot == false) then
        self.timer = self.timer + dt
    end
    
    if (self.timer >= 1/self.shotsPerSec) then
        self.readyToShoot = true
        self.timer = 0
    end

    self.targetEnemy = self:getCurrentEnemyFirstIn()

    -- Debug draw line
    if (self.targetEnemy ~= nil) then
        self.cRep:drawLine(self.targetEnemy.cRep)
    end

    -- Attack target enemy
    if (self.targetEnemy ~= nil) then
        self:attack(self.targetEnemy)
    end

end

-- Gets the enemy that came in first within the current list of enemies in range.
-- This naive solution should be O.K with the assumption that enemiesInRange table
-- does not get too large! :)
function Tower:getCurrentEnemyFirstIn() 
    min = math.maxinteger
    ret = nil
    for k, v in pairs(self.enemiesInRange) do
        if (v[1] < min) then
            min = v[1]
            ret = v[2]
        end
    end
    return ret
end

function Tower:onEnemyEnter(enemy)
    -- If enemy does not exist in our list of enemiesInRange --> Add it
    if (self.enemiesInRange[enemy.id] == nil) then
        self.enemiesInRange[enemy.id] = { self.enemiesInRangeID, enemy }
        self.enemiesInRangeID = self.enemiesInRangeID + 1
    end
    -- If it already does exist, skip.
end

function Tower:onEnemyLeave(enemy)
    -- If enemy exists in our current list of enemiesInRange --> Make it leave
    if (self.enemiesInRange[enemy.id] ~= nil) then
        self.enemiesInRange[enemy.id] = nil
    end
    -- If it doesn't exist, skip.
end

function Tower:attack(enemy)
    if (self.readyToShoot) then
        print("[" .. self.id .. "] deals damage to [" .. self.targetEnemy.id .. "]")
        enemy:takeDamage(self.damage)
        self.readyToShoot = false
    end
end

function Tower:getMaxRange()
    return self.maxRange
end

function Tower:toggleRangeVisible()
    self.rangeMesh.cRep:toggleVisible()
end

return Tower