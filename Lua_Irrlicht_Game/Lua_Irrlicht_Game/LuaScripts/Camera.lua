Vector = require("LuaScripts/Vector")

local Camera = {
    cRep = nil,     -- c representation of camera
    pos = nil,
    moveSpeed = 20
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

function Camera:castRayForward()
    local target = self.cRep:castRayForward()
    return target
end

function Camera:move(dt)
    local playerPos = self:getPosition()
    local fwdVec = self:getForwardVec()
    local rightVec = self:getRightVec()
    local upVec = self:getUpVec()

    if (isKeyDown("W")) then
        playerPos = playerPos + fwdVec * self.moveSpeed * dt
    elseif (isKeyDown("S")) then
        playerPos = playerPos - fwdVec * self.moveSpeed * dt
    end
    if (isKeyDown("A")) then
        playerPos = playerPos - rightVec * self.moveSpeed * dt
    elseif (isKeyDown("D")) then
        playerPos = playerPos + rightVec * self.moveSpeed * dt
    end
    if (isKeyDown("E")) then
        playerPos = playerPos + upVec * self.moveSpeed * dt
    elseif (isKeyDown("LShift")) then
        playerPos = playerPos - upVec * self.moveSpeed * dt
    end

    self:setPosition(playerPos.x, playerPos.y, playerPos.z)
end

function Camera:__tostring()
    str = string.format("Camera Pos (%f, %f, %f)", self.pos.x, self.pos.y, self.pos.z)
    return str
end


return Camera