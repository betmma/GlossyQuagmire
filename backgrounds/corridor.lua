local WalkerShader=...

local corridorShader=ShaderScan:load_shader('shaders/backgrounds/corridor.glsl')
local Corridor=WalkerShader:extend()
function Corridor:new(args)
    Corridor.super.new(self,args)
    self.cam_translation={0,0,0}
    self.camMoveRange={1,1}
    self.camMoveSpeed=-0.5
    self.shader=corridorShader
    self.lightColor={0.8,0.8,0.8} -- it's too bright
end

function Corridor:update(dt)
    Corridor.super.update(self,dt)
    local bulletNum=#Bullet.objects
    local brightness=math.clamp(1-(bulletNum)/3000,0.6,0.8)
    self.lightColor={brightness,brightness,brightness}
end

return Corridor