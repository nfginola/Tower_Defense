local EnemyWave = {}

function EnemyWave:new(spawnInterval, enemyCount, spawnFunction)
    local o = {
        maxSpawnInterval = spawnInterval,
        maxEnemyCount = enemyCount,
        enemyLeft = enemyCount,
        spawnFunc = spawnFunction,
        
        spawnTimer = 0

    }

    self.__index = self
    setmetatable(o, self)

    return o
end

function EnemyWave:update(dt)
    self.spawnTimer = self.spawnTimer + dt

    if (self.spawnTimer > self.maxSpawnInterval) and (self.enemyLeft > 0) then
        self.spawnFunction()
        self.enemyLeft = self.enemyLeft - 1
        self.spawnTimer = 0
    end

    if (self.enemyLeft == 0) then
        return true
    else
        return false
    end
end

return EnemyWave