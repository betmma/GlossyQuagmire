---@type ShaderBackground
local Shader=...
local WalkerShader=Shader:extend()
function WalkerShader:new()
    WalkerShader.super.new(self)
    self.autoDark=true
    self.cam_translation={0,1.5,0.5}
    self.cam_pitch=0
    self.cam_yaw=0
    self.cam_roll=0
    self.camMoveRange={0.3,0.0}
    self.camMoveSpeed=0.2
    self.reverseX=true -- don't know why but previous H^3 shaders reverse left and right key
    self.paramSendFunction=function(self,shader)
        shader:send("time", self.frame/60)
        local trans=self.cam_translation or {0,0,0}
        shader:send("translation", trans)
        local pitch=self.cam_pitch or 0
        shader:send("pitch", pitch)
        shader:send("yaw", self.cam_yaw or 0)
        local roll=self.cam_roll or 0
        shader:send("roll", roll)
    end
end
WalkerShader.update=function(self,dt)
    WalkerShader.super.update(self,dt)
    local xRange,yRange=self.camMoveRange[1],self.camMoveRange[2]
    if not self.camMoveCenter then
        self.camMoveCenter={self.cam_translation[1],self.cam_translation[2]}
    end
    local xCenter,yCenter=self.camMoveCenter[1],self.camMoveCenter[2]
    local xyStep=self.camMoveSpeed*dt
    self.frame=self.frame+1
    local keyIsDown=love.keyboard.isDown
    if keyIsDown("n") then
        self.cam_pitch = self.cam_pitch - dt
    end
    if keyIsDown("m") then
        self.cam_pitch = self.cam_pitch + dt
    end
    if keyIsDown("h") then
        self.cam_yaw = self.cam_yaw - dt
    end
    if keyIsDown("j") then
        self.cam_yaw = self.cam_yaw + dt
    end
    if keyIsDown("y") then
        self.cam_roll = self.cam_roll - dt
    end
    if keyIsDown("u") then
        self.cam_roll = self.cam_roll + dt
    end
    if keyIsDown("i") then
        self.cam_translation[3] = self.cam_translation[3] + dt
    end
    if keyIsDown("k") then
        self.cam_translation[3] = self.cam_translation[3] - dt
    end
    if G.runInfo.player then
        keyIsDown=G.runInfo.player.keyIsDown -- nmhjyuik aren't recorded in player, so these keys use love.keyboard.isDown. arrow keys use player to restore in replay
    end
    local reverseX=self.reverseX and -1 or 1
    if keyIsDown("right") then
        self.cam_translation[1] = math.clamp(self.cam_translation[1] + xyStep * reverseX,-xRange+xCenter,xRange+xCenter)
    end
    if keyIsDown("left") then
        self.cam_translation[1] = math.clamp(self.cam_translation[1] - xyStep * reverseX,-xRange+xCenter,xRange+xCenter)
    end
    if keyIsDown("up") then
        self.cam_translation[2] = math.clamp(self.cam_translation[2] - xyStep,-yRange+yCenter,yRange+yCenter)
    end
    if keyIsDown("down") then
        self.cam_translation[2] = math.clamp(self.cam_translation[2] + xyStep,-yRange+yCenter,yRange+yCenter)
    end
end

return WalkerShader