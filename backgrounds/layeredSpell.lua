local Shader=...
local shader=ShaderScan:load_shader('shaders/backgrounds/layeredSpell.glsl')
local textures={}

local function loadTexture(name)
    if not textures[name] then
        local texture=love.graphics.newImage('assets/spellBackgrounds/'..name..'.png',{mipmaps=true})
        texture:setFilter('linear','linear')
        texture:setMipmapFilter('linear')
        textures[name]=texture
    end
    return textures[name]
end

local LayeredSpell=Shader:extend()
function LayeredSpell:new(args)
    LayeredSpell.super.new(self,args)
    self.shader=shader
    self.autoDark=false
    self.baseTexture=loadTexture(args.base)
    self.overlayTexture=loadTexture(args.overlay)
    self.baseSize={self.baseTexture:getDimensions()}
    self.overlaySize={self.overlayTexture:getDimensions()}
    self.spinSpeeds=args.spinSpeeds -- radians per second, base then overlay
    self.hyperbolicOverlay=args.hyperbolicOverlay or false
    self.scrollDirection=args.scrollDirection or math.pi*3/4
    self.scrollSpeed=args.scrollSpeed or 0.3 -- curvature-one distance per second
    self.paramSendFunction=function(self,shader)
        local geometry=G.runInfo.geometry
        local view=geometry.viewConfig
        local center=view.screenCenter
        local model=view.hyperbolicModel or 0
        shader:send('baseTexture',self.baseTexture)
        shader:send('overlayTexture',self.overlayTexture)
        shader:send('baseSize',self.baseSize)
        shader:send('overlaySize',self.overlaySize)
        shader:send('spinSpeeds',self.spinSpeeds)
        shader:send('time',self.frame/60)
        shader:send('hyperbolicOverlay',self.hyperbolicOverlay)
        shader:send('scrollDirection',self.scrollDirection)
        shader:send('scrollSpeed',self.scrollSpeed)
        shader:send('viewDirection',G.runInfo.player.viewDirection)
        shader:send('screenCenter',{center.x,center.y})
        shader:send('shape_axis_y',geometry.axisY or 0)
        shader:send('hyperbolic_model',model)
        shader:send('r_factor',view.diskRadiusBase and view.diskRadiusBase[model] or 1)
    end
end

local MarisaSpell=LayeredSpell:extend()
function MarisaSpell:new(args)
    args=args or {}
    MarisaSpell.super.new(self,{
        base='marisa1',overlay='marisa2',hyperbolicOverlay=true,
        spinSpeeds={0.3,0},
    })
end

local ReimuSpell=LayeredSpell:extend()
function ReimuSpell:new(args)
    args=args or {}
    ReimuSpell.super.new(self,{
        base='reimu1',overlay='reimu2',
        spinSpeeds={0,0.3},
    })
end

return {Marisa=MarisaSpell,Reimu=ReimuSpell}
