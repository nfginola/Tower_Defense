local EnemyWave = {}

function EnemyWave:new(spawnInterval, enemyCount, spawnCellID)

    local ew = {
        maxSpawnInterval = spawnInterval,
        maxEnemyCount = enemyCount,
        enemyLeft = enemyCount,
        spawnPosition = cells[spawnCellID]:getPosition(),
        
        spawnTimer = spawnInterval + 1
    }

    self.__index = self
    setmetatable(ew, self)

    return ew
end

function EnemyWave:spawnEnemy()
    if (self.spawnCell ~= "") then
        local newEnemy = Enemy:new(
            self.spawnPosition,
            { maxHealth = 40, damage = 10, unitsPerSec = 40}
        )
        enemies[newEnemy.id] = newEnemy
    else
        --print("No spawn point set for enemies!")
        log("No spawn point set for enemies!")
    end
end

function EnemyWave:update(dt)
    self.spawnTimer = self.spawnTimer + dt

    if (self.spawnTimer > self.maxSpawnInterval) and (self.enemyLeft > 0) then
        self:spawnEnemy()
        self.enemyLeft = self.enemyLeft - 1
        self.spawnTimer = 0
    end

    -- Return wave done state
    if (self.enemyLeft == 0) then
        return true
    else
        return false
    end
end

return EnemyWave