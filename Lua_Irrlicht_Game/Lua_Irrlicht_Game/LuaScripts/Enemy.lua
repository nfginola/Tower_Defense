WorldObject = require("LuaScripts/WorldObject")

-- waypoints = { "cg3,1", "cg3,4", "cg5,4", "cg5,1", "cg8,1" }


local Enemy = WorldObject:new()
local enemy_gid = 1

enemy_ground_height = 10

-- Called from C++
function getNextWaypoint(enemyID)
    if (coroutine.status(enemies[enemyID].moveCoroutine) ~= "dead") then
        coroutine.resume(enemies[enemyID].moveCoroutine)
        return true
    else
        return false
    end
end

-- Enemy:new()
-- Enemy:initCRep()

function Enemy:new(spawnPos, enemyStats)

    if (type(enemyStats) ~= "table") then error("Enemy Stats must be a table!") end
    if (enemyStats.maxHealth == nil) then error("Enemy Stats must have a 'maxHealth' attribute!") end
    if (enemyStats.damage == nil) then error("Enemy Stats must have a 'damage' attribute!") end
    if (enemyStats.unitsPerSec == nil) then error("Enemy Stats must have a 'unitsPerSec' attribute!") end

    local e = 
    {
        id = nil,
        health = enemyStats.maxHealth,
        maxHealth = enemyStats.maxHealth,
        damage = enemyStats.damage,
        unitsPerSec = enemyStats.unitsPerSec,

        baseScale = nil,

        moveCoroutine = nil
    }

    -- local e = WorldObject:new()
    -- e.id = nil
    -- e.health = enemyStats.maxHealth
    -- e.maxHealth = enemyStats.maxHealth
    -- e.damage = enemyStats.damage
    -- e.unitsPerSec = enemyStats.unitsPerSec
    -- e.baseScale = nil
    -- e.moveCoroutine = nil

    self.__index = self
    setmetatable(e, self) 

    e.id = string.format("eg%i", enemy_gid)
    enemy_gid = enemy_gid + 1
    e:initCRep(e.id)    
    e.cRep:setDynamic()
    e.cRep:addSphereMesh(5)
    e.cRep:toggleBB()
    e.cRep:setTexture("resources/textures/lava.jpg")
    e:setPosition(spawnPos.x, spawnPos.y, spawnPos.z)
    e:setScale(0.7, 0.7, 0.7)
    -- e.baseScale = e:getScale() -- watch out, this is a reference!
    e.baseScale = Vector:new({ x = e:getScale().x, y = e:getScale().y, z = e:getScale().z })


    --[[
        Create a coroutine for this enemy
    ]]

    e.moveCoroutine = coroutine.create(
        function ()
            local waypoints = orchestrator:getWaypoints()
            for i = 1, #waypoints do
                e:moveToCell(waypoints[i])
                coroutine.yield()  
            end
        end
    )

    -- start first time
    coroutine.resume(e.moveCoroutine)

    return e
end

function Enemy:moveToCell(cellID)
    local toMove = cells[cellID]:getPosition()
    toMove.y = toMove.y + 10.5

    local currPos = self:getPosition()

    -- solve the time needed to cover the distance with the speed of this enemy
    -- this can be done once at init! (waypoints are static)
    local dist = lengthBetween(cells[cellID], self)
    local moveTime = dist / self.unitsPerSec

    self.cRep:setMoveNextPoint(
        currPos.x, enemy_ground_height, currPos.z, 
        toMove.x, enemy_ground_height, toMove.z, 
        moveTime)
    --print("Next move assigned to: " .. self.id)
end

function Enemy:getHealth()
    return self.health
end

function Enemy:takeDamage(damage)
    self.health = self.health - damage
    --print("[" .. self.id .. "] has taken damage! HP left: " .. self.health .. "\n")

    -- visual feedback for damage (scale halved each time!)
    local hpFac = self.health / self.maxHealth  -- [1, 0]
    hpFac = hpFac * 0.5 -- [0.5, 0]
    hpFac = hpFac + 0.5 -- [1, 0.5]

    -- interps from baseScale to half of baseScale as it gets to 0 HP
    -- print(self.id .. ": ")
    -- print(self.baseScale)

    -- print("before:", self.id, ":", self.baseScale)

    self:setScale(self.baseScale.x * hpFac, self.baseScale.y * hpFac, self.baseScale.z * hpFac)

    -- print("after:", self.id, ":", self.baseScale * hpFac)
    --print("after:", self.id, ":", self.baseScale * hpFac)

end

function Enemy:kill()
    self.health = 0
end

function Enemy:isDead()
    return self.health <= 0
end

return Enemy