local WalkerShader=...
local build_lorentz_mat4=require('import.H3math').build_lorentz_mat4
local honeycombShader=ShaderScan:load_shader('shaders/backgrounds/honeycomb.glsl')
local Honeycomb=WalkerShader:extend()
function Honeycomb:new(args)
    Honeycomb.super.new(self,args)
    self.shader=honeycombShader
    self.inverse=args and args.inverse or false
    if not self.inverse then
        self.darkColor={0.3,0.3,0.3}
    end
    self.cam_translation={0.0001,0.4,0.3} -- when inverse, y=0.4 to avoid moving into ball at origin
    self.cam_pitch=self.inverse and -math.pi/2 or 0
    self.cam_yaw=math.pi/2
    self.camMoveRange={0.45,0.0}
    self.autoMove=true
    self.autoForwardSpeed=0.25
    self.autoForwardWrap=1.06 -- currently should be distance from center to center of a side. 
    self.autoForwardValue=self.cam_translation[3]
    self.manualForwardOffset=0.0
    self.manualForwardLimit=0.3
    self.reflectCount=0
    self.paramSendFunction=function(self,shader)
        local time=self.frame/60
        local lightsOn=true
        if BGM.currentAudio=='level1' then
            time=BGM:tell()
            -- 24 bars, 150 bpm -> 38.4s, to 48 bars -> 76.8s. dunno why there's delay
            local delay=0.0
            local time2=time-delay
            if time2>38.4 and time2<76.8 and (time2-38.4)%0.8>0.4 then
                lightsOn=false
            end
        end
        shader:send("neon_lights_on",lightsOn)
        shader:send("time", time)
        local screenCenter=G.runInfo.geometry.viewConfig.screenCenter
        shader:send("screenCenter",{screenCenter.x,screenCenter.y})
        local trans=self.cam_translation
        local pitch,yaw,roll=self.cam_pitch,self.cam_yaw,self.cam_roll
        local changed=self.inverse and {trans[3], trans[1], trans[2]} or {trans[3], trans[2], trans[1]} -- auto move component must be first. rest two order is to let fixed component moving away from ball at origin or edge
        local mat4=build_lorentz_mat4(pitch, yaw, roll, changed)
        shader:send("cam_mat4", mat4)
        shader:send("inverse",self.inverse)
        shader:send("SHELL_RATIO",self.inverse and 2 or 0.5)
        shader:send("reflect_count",self.reflectCount)
    end
end

function Honeycomb:update(dt)
    Honeycomb.super.update(self,dt)
    if not self.autoMove then
        return
    end
    local wrap = self.autoForwardWrap
    local manualOffset = math.clamp(self.cam_translation[3] - self.autoForwardValue, -self.manualForwardLimit, self.manualForwardLimit)
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

return Honeycomb