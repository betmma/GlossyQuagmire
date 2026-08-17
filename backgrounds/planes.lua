local WalkerShader=...
local build_lorentz_mat4=require('import.H3math').build_lorentz_mat4
local planesShader=ShaderScan:load_shader('shaders/backgrounds/planes.glsl')
local Planes=WalkerShader:extend()
local MIRROR_OFFSET=4.61
function Planes:new(args)
    Planes.super.new(self,args)
    self.shader=planesShader
    self.cam_translation={0.0001,0.4,3.0001}
    -- self.cam_pitch=math.pi/2
    self.cam_yaw=math.pi/2
    -- self.cam_roll=math.pi/20
    self.camMoveSpeed=0.25
    self.camMoveRange={0.0,0.0}
    self.autoMove=true
    self.autoForwardSpeed=0.25
    self.autoForwardWrap=MIRROR_OFFSET
    self.autoForwardValue=self.cam_translation[3]
    self.manualForwardOffset=0.0
    self.reflectCount=0
    self.paramSendFunction=function(self,shader)
        local screenCenter=G.runInfo.geometry.viewConfig.screenCenter
        shader:send("screenCenter",{screenCenter.x,screenCenter.y})
        local trans=self.cam_translation
        local pitch,yaw,roll=self.cam_pitch,self.cam_yaw,self.cam_roll
        local changed={trans[3], trans[2], trans[1]} -- auto move component must be first.
        local mat4=build_lorentz_mat4(pitch, yaw, roll, changed)
        shader:send("cam_mat4", mat4)
        shader:send("reflect_count",self.reflectCount)
    end
end

function Planes:update(dt)
    Planes.super.update(self,dt)
    if not self.autoMove then
        return
    end
    local wrap = self.autoForwardWrap
    local manualOffset = self.cam_translation[3] - self.autoForwardValue
    self.manualForwardOffset = manualOffset
    self.autoForwardValue = self.autoForwardValue + (self.autoForwardSpeed or 0.0) * dt
    local span = wrap * 2.0
    if self.autoForwardValue > wrap then
        self.autoForwardValue = self.autoForwardValue - span
        self.reflectCount = self.reflectCount + 1
    elseif self.autoForwardValue < -wrap then
        self.autoForwardValue = self.autoForwardValue + span
        self.reflectCount = self.reflectCount + 1
    end
    self.cam_translation[3] = self.autoForwardValue + self.manualForwardOffset
end

return Planes