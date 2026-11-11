local Shader=...
local EnriSpell=Shader:extend()
local shader=ShaderScan:load_shader('shaders/backgrounds/enriSpell.glsl')
local starMap

function EnriSpell:new(args)
    EnriSpell.super.new(self,args)
    if not starMap then
        starMap=love.graphics.newImage('assets/spellBackgrounds/stage6Nebula.jpg',{mipmaps=true})
        starMap:setWrap('repeat','clamp')
        starMap:setFilter('linear','linear')
        starMap:setMipmapFilter('linear')
    end
    self.shader=shader
    self.autoDark=false
    self.lightColor={0.5,0.5,0.5}
    self.rotation=0
    local pos=G.runInfo.player.kinematicState.pos
    local length=math.sqrt(pos.x*pos.x+pos.y*pos.y+pos.z*pos.z)
    self.rippleOrigin={pos.x/length,pos.y/length,pos.z/length}
    self.paramSendFunction=function(self,shader)
        local geometry=G.runInfo.geometry--[[@as Spherical]]
        local view=geometry.viewConfig
        local main,mini=view.primaryCircle,view.secondaryCircle
        shader:send('starMap',starMap)
        shader:send('mainCenter',{main.center.x,main.center.y})
        shader:send('mainRadius',main.radius)
        shader:send('miniCenter',{mini.center.x,mini.center.y})
        shader:send('miniRadius',mini.radius)
        shader:send('rotation',self.rotation)
        shader:send('time',self.frame/60)
        shader:send('rippleOrigin',self.rippleOrigin)
        geometry:sendCameraBasis(shader)
    end
end

function EnriSpell:update(dt)
    EnriSpell.super.update(self,dt)
    -- Match the world's rotation used by Spherical:update.
    self.rotation=(self.rotation+(G.runInfo.geometry--[[@as Spherical]].viewConfig.rotateSpeed or 0))%(2*math.pi)
end

function EnriSpell:draw()
    if G.runInfo.geometry~=G.geometries.Spherical then return end
    EnriSpell.super.draw(self)
end

return EnriSpell
