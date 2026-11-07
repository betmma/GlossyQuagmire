local WalkerShader=...
local shader=ShaderScan:load_shader('shaders/backgrounds/koraSpell.glsl')
local KoraSpell=WalkerShader:extend()

local initialYaw=-math.atan(0.5)
local initialPitch=-math.atan(1/math.sqrt(5))

function KoraSpell:new(args)
    KoraSpell.super.new(self,args)
    self.lightColor={0.5,0.5,0.5}
    self.shader=shader
    self.cam_translation={0,0,0}
    self.cam_yaw=initialYaw
    self.cam_pitch=initialPitch
    self.camMoveRange={0.12,0.12}
    self.camMoveSpeed=0.2
    self.reverseX=false
    self.cameraSpeed=1.5
    self.travel=0
    self.viewDistance=80
    self.fogDensity=0.055
    self.paramSendFunction=function(self,shader)
        local center=G.runInfo.geometry.viewConfig.screenCenter
        shader:send('resolution',{800,600})
        shader:send('screenCenter',{center.x,center.y})
        shader:send('look',{self.cam_yaw,self.cam_pitch})
        shader:send('roll',self.cam_roll)
        -- Walker offsets are camera-local (positive y is down). Keep the
        -- automatic route along (1,1,2), clear of the balloon centers.
        local x,y,z=unpack(self.cam_translation)
        local sy,cy=math.sin(initialYaw),math.cos(initialYaw)
        local sp,cp=math.sin(initialPitch),math.cos(initialPitch)
        z=z+self.travel
        shader:send('cameraPosition',{
            0.25+cy*x-sy*sp*y-sy*cp*z,
            -0.25-cp*y-sp*z,
            -0.60+sy*x+cy*sp*y+cy*cp*z
        })
        shader:send('viewDistance',self.viewDistance)
        shader:send('fogDensity',self.fogDensity)
    end
end

function KoraSpell:update(dt)
    KoraSpell.super.update(self,dt)
    -- Advancing sqrt(6) repeats the lattice by the integer vector (1,1,2).
    self.travel=(self.travel+self.cameraSpeed*dt)%math.sqrt(6)
end

return KoraSpell
