WorldObject = require("LuaScripts/WorldObject")

local Tower = WorldObject:new()

-- Global
towerRangeHidden = true
local tower_ground_height = 10

function Tower:new(cellID, towerStats)

    if (type(towerStats) ~= "table") then error("Tower Stats must be a table!") end
    if (towerStats.damage == nil) then error("Tower Stats must have a 'damage' attribute!") end
    if (towerStats.shotsPerSec == nil) then error("Tower Stats must have a 'shotsPerSec' attribute!") end
    if (towerStats.range == nil) then error("Tower Stats must have a 'range' attribute!") end

    -- local t = 
    -- {
    --     id = nil,
    --     damage = towerStats.damage,
    --     shotsPerSec = towerStats.shotsPerSec,
    --     maxRange = towerStats.range,
    --     rangeMesh = nil,

    --     timer = 0,
    --     readyToShoot = true,

    --     enemiesInRange = {},
    --     enemiesInRangeID = 1,

    --     targetEnemy = nil,

    --     doAnim = false,
    --     baseAnimScale = nil,
    --     targetAnimScale = nil,
    --     animationTimeElapsed = 0,
    --     animationTimeMax = (1 / towerStats.shotsPerSec) / 3
    -- }

    local t = WorldObject:new()
    t.id = nil
    t.damage = towerStats.damage
    t.shotsPerSec = towerStats.shotsPerSec
    t.maxRange = towerStats.range
    t.rangeMesh = nil

    t.timer = 0
    t.readyToShoot = true

    t.enemiesInRange = {}
    t.enemiesInRangeID = 1

    t.targetEnemy = nil

    t.doAnim = false
    t.baseAnimScale = nil
    t.targetAnimScale = nil
    t.animationTimeElapsed = 0
    t.animationTimeMax = (1 / towerStats.shotsPerSec) / 3


    self.__index = self
    setmetatable(t, self) 

    t.id = cellID .. "_t"
    t:initCRep(t.id)
    t.cRep:addSphereMesh(5)
    t.cRep:setPickable()

    local scale = Vector:new({ x = 0.6, y = 1.5, z = 0.6})
    t:setScale(scale.x, scale.y, scale.z)
    t.baseAnimScale = Vector:new({x = scale.x, y = scale.y, z = scale.z})
    t.targetAnimScale = Vector:new({x = scale.x + 0.1, y = scale.y + 0.2, z = scale.z + 0.1})

    t.cRep:setTexture("resources/textures/water.jpg")

    local cellPosition = cells[cellID]:getPosition()
    t:setPosition(cellPosition.x, tower_ground_height, cellPosition.z)

    -- setup range mesh
    t.rangeMesh = WorldObject:new()
    t.rangeMesh:initCRep(t.id .. "_r")
    t.rangeMesh.cRep:addSphereMesh(t.maxRange)
    t.rangeMesh:setScale(1, 0.1, 1);
    t.rangeMesh.cRep:setTexture("resources/textures/green.png")
    t.rangeMesh.cRep:setTransparent()
    t.rangeMesh:setPosition(cellPosition.x, cellPosition.y + 10.0, cellPosition.z)

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

    -- Play "recoil" anim (after shot)
    if (self.doAnim) then
        self.animationTimeElapsed = self.animationTimeElapsed + dt

        local fac = self.animationTimeElapsed / self.animationTimeMax

        -- linear interp anim
        --local interpFac = (-math.abs(4*fac - 2) + 2) / 2    -- Y goes (from 0 to 1 to 0) as X goes (from 0 to 1)

        -- quadratic interp anim looks much better! (it starts high and drops off fast --> like recoil!)
        -- best looked at on towers with slow attack speed
        local interpFac = -(fac*fac) + 1

        -- Get the interpolated scale
        currentAnimScale = self.baseAnimScale + (self.targetAnimScale - self.baseAnimScale) * interpFac

        if (self.animationTimeElapsed >= self.animationTimeMax) then
            self:setScale(self.baseAnimScale.x, self.baseAnimScale.y, self.baseAnimScale.z)
            self.doAnim = false
            self.animationTimeElapsed = 0
        else
            self:setScale(currentAnimScale.x, currentAnimScale.y, currentAnimScale.z)
        end

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
        --print("[" .. self.id .. "] deals damage to [" .. self.targetEnemy.id .. "]")
        enemy:takeDamage(self.damage)
        self.readyToShoot = false
        self.doAnim = true      -- "just shot" anim
    end
end

function Tower:getMaxRange()
    return self.maxRange
end

function Tower:toggleRangeVisible()
    self.rangeMesh.cRep:toggleVisible()
end

return Tower