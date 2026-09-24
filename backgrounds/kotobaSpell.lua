local Shader=...
local KotobaSpell=Shader:extend()
local shader=ShaderScan:load_shader('shaders/backgrounds/kotobaSpell.glsl')
local textTexture,patternTexture

function KotobaSpell:new(args)
    args=args or {}
    KotobaSpell.super.new(self,args)
    if not textTexture then
        textTexture=love.graphics.newImage('assets/spellBackgrounds/kotoba1.png',{mipmaps=true})
        patternTexture=love.graphics.newImage('assets/spellBackgrounds/kotoba2.png',{mipmaps=true})
        textTexture:setFilter('linear','linear')
        patternTexture:setFilter('linear','linear')
        textTexture:setMipmapFilter('linear')
        patternTexture:setMipmapFilter('linear')
    end
    self.shader=shader
    self.autoDark=false
    -- Text first, pattern second. Speeds are in curvature-one distance per second.
    self.layerDirections=args.layerDirections or {-math.pi/4,math.pi*3/4}
    self.layerSpeeds=args.layerSpeeds or {0.08,0.05}
    self.paramSendFunction=function(self,shader)
        local geometry=G.runInfo.geometry
        if geometry~=G.geometries.Hyperbolic then
            return
        end
        ---@cast geometry Hyperbolic
        local view=geometry.viewConfig
        local center=view.screenCenter
        shader:send('textTexture',textTexture)
        shader:send('patternTexture',patternTexture)
        shader:send('time',self.frame/60)
        shader:send('viewDirection',G.runInfo.player.viewDirection)
        shader:send('layerDirections',self.layerDirections)
        shader:send('layerSpeeds',self.layerSpeeds)
        shader:send('screenCenter',{center.x,center.y})
        shader:send('shape_axis_y',geometry.axisY)
        local model=view.hyperbolicModel
        if model==G.geometries.Hyperbolic.HYPERBOLIC_MODELS.P_DISK then
            -- model=G.geometries.Hyperbolic.HYPERBOLIC_MODELS.K_DISK -- make it bigger
        end
        shader:send('hyperbolic_model',model)
        shader:send('r_factor',view.diskRadiusBase[view.hyperbolicModel] or 1)
    end
end

return KotobaSpell
