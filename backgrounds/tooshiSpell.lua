local Shader=...
local shader=ShaderScan:load_shader('shaders/backgrounds/tooshiSpell.glsl')
local TooshiSpell=Shader:extend()

function TooshiSpell:new(args)
    TooshiSpell.super.new(self,args)
    self.shader=shader
    self.autoDark=false
    self.travel=0
    self.paramSendFunction=function(self,shader)
        local geo=G.runInfo.geometry
        ---@cast geo MovingHyperbolic
        local view=geo.viewConfig
        shader:send('origin',{view.zoomCenterX or view.screenCenter.x,geo.axisY or 0})
        shader:send('referenceHeight',view.screenCenter.y-(geo.axisY or 0))
        shader:send('time',self.frame/60)
        shader:send('travel',self.travel)
    end
end

function TooshiSpell:update(dt)
    TooshiSpell.super.update(self,dt)
    -- zoomRatio is already a per-simulation-tick dilation, including easing.
    -- Reading it directly also works for the separate spell-background object.
    local ratio=G.runInfo.geometry--[[@as MovingHyperbolic]].viewConfig.zoomRatio or 1
    self.travel=self.travel+math.log(ratio)
end

return TooshiSpell
