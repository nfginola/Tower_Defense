WorldObject = require("LuaScripts/WorldObject")

local Enemy = WorldObject:new()

local enemy_gid = 1

function Enemy:new(id, spawnPos, enemyStats)

    if (type(enemyStats) ~= "table") then error("Enemy Stats must be a table!") end
    if (enemyStats.maxHealth == nil) then error("Enemy Stats must have a 'maxHealth' attribute!") end
    if (enemyStats.damage == nil) then error("Enemy Stats must have a 'damage' attribute!") end
    if (enemyStats.unitsPerSec == nil) then error("Enemy Stats must have a 'unitsPerSec' attribute!") end

    local e = 
    {
        id = nil,
        health = enemyStats.maxHealth,
        damage = enemyStats.damage,
        unitsPerSec = enemyStats.unitsPerSec
    }

    self.__index = self
    setmetatable(e, self) 

    e.id = string.format("eg%i", enemy_gid)
    enemy_gid = enemy_gid + 1
    e:initCRep(e.id)
    e.cRep:addSphereMesh(5)
    e.cRep:toggleBB()
    e.cRep:setPosition(spawnPos.x, spawnPos.y, spawnPos.z)

    return e
end

function Enemy:getHealth()
    return self.health
end

function Enemy:takeDamage(damage)
    self.health = self.health - damage
    print("[" .. self.id .. "] has taken damage! HP left: " .. self.health .. "\n")
end

function Enemy:die()
    self.health = 0
end

function Enemy:isDead()
    return self.health <= 0
end

return Enemy