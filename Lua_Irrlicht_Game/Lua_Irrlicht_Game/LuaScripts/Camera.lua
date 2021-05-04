Vector = require("LuaScripts/Vector")

local Camera = {
    cRep = nil,     -- c representation of camera
    pos = nil,
    active = true,

    --shouldRaycast = true,
    --raycastPauseTimer = 0,
    --raycastPauseMaxTime = 1,

    moveSpeed = 30
}

function Camera:new(id) 
    local wo = {}

    self.__index = self
    setmetatable(wo, self) 

    wo.cRep = CCamera:new(id)
    wo.pos = Vector:new({ x = 0, y = 0, z = 0})

    return wo
end

function Camera:getPosition()
    local x, y, z = self.cRep:getPosition()
    self.pos.x = x
    self.pos.y = y
    self.pos.z = z
    return self.pos
end

function Camera:setPosition(x, y, z)
    self.pos.x = x
    self.pos.y = y
    self.pos.z = z
    self.cRep:setPosition(x, y, z)
end

function Camera:createFPSCam()
    self.cRep:createFPSCam()
end

function Camera:getForwardVec()
    local x1, y1, z1 = self.cRep:getForwardVec()
    local vec = Vector:new({ x = x1, y = y1, z = z1 })
    return vec
end

function Camera:getRightVec()
    local x1, y1, z1 = self.cRep:getRightVec()
    local vec = Vector:new({ x = x1, y = y1, z = z1 })
    return vec
end

function Camera:getUpVec()
    local x1, y1, z1 = self.cRep:getUpVec()
    local vec = Vector:new({ x = x1, y = y1, z = z1 })
    return vec
end

-- function Camera:pauseRaycast(time)
--     self.shouldRaycast = false
--     self.raycastPauseTimer = 0
--     self.raycastPauseMaxTime = time
-- end


function Camera:castRayForward()
    local target = ""
    if (self.active) then
        target = self.cRep:castRayForward()
    end
    --print("shouldRaycast?: ", self.shouldRaycast)
    return target
end

function Camera:toggleActive()
    self.active = (not self.active)
    self.cRep:toggleActive()

    -- if (not self.active) then
    --     self.shouldRaycast = not self.active
    -- elseif (self.active) then
    --     self.shouldRaycast = self.active
    -- end
end

-- function Camera:handleRaycastTimer(dt)
--     if (not self.shouldRaycast) then
--         self.raycastPauseTimer = self.raycastPauseTimer + dt    
--         if (self.raycastPauseTimer > self.raycastPauseMaxTime) then
--             self.shouldRaycast = true
--         end
--     end
-- end

function Camera:move(dt)
    --self:handleRaycastTimer(dt)

    local playerPos = self:getPosition()
    local fwdVec = self:getForwardVec()
    local rightVec = self:getRightVec()
    local upVec = self:getUpVec()

    if (isKeyDown("W")) and (self.active) then
        playerPos = playerPos + fwdVec * self.moveSpeed * dt
    elseif (isKeyDown("S")) and (self.active) then
        playerPos = playerPos - fwdVec * self.moveSpeed * dt
    end
    if (isKeyDown("A")) and (self.active) then
        playerPos = playerPos - rightVec * self.moveSpeed * dt
    elseif (isKeyDown("D")) and (self.active) then
        playerPos = playerPos + rightVec * self.moveSpeed * dt
    end
    if (isKeyDown("E")) and (self.active) then
        playerPos = playerPos + upVec * self.moveSpeed * dt
    elseif (isKeyDown("LShift")) and (self.active) then
        playerPos = playerPos - upVec * self.moveSpeed * dt
    end

    self:setPosition(playerPos.x, playerPos.y, playerPos.z)
end

function Camera:__tostring()
    str = string.format("Camera Pos (%f, %f, %f)", self.pos.x, self.pos.y, self.pos.z)
    return str
end


return Camera