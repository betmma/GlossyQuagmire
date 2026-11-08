local Shader=...
local ShoujiSpell=Shader:extend()
local shader=ShaderScan:load_shader('shaders/backgrounds/shoujiSpell.glsl')

function ShoujiSpell:new(args)
    ShoujiSpell.super.new(self,args)
    self.shader=shader
    self.autoDark=false
    self.paramSendFunction=function(self,shader)
        local geo=G.runInfo.geometry
        local center=geo.viewConfig.screenCenter
        local screenCenter={center.x,center.y}
        if self.limitPosition then
            local viewer=G.runInfo.player
            screenCenter=Portal.positionToShaderScreen(self.limitPosition,viewer,geo,
                1/Portal.zoomFactor(viewer.kinematicState.pos))
        end
        shader:send('screenCenter',screenCenter)
        shader:send('time',self.frame/60)
    end
end

return ShoujiSpell
