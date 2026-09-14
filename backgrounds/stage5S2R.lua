local WalkerShader=...

local stage5Shader=ShaderScan:load_shader('shaders/backgrounds/stage5S2R.glsl')
local noiseShader=ShaderScan:load_shader('shaders/backgrounds/stage5CloudNoise.glsl')
local Stage5S2R=WalkerShader:extend()
local noiseLattice

local function getNoiseLattice()
    if noiseLattice then return noiseLattice end
    -- Preserve the procedural hash values in a floating-point atlas. On a
    -- renderer without this format the cloud shader keeps its procedural path.
    if not love.graphics.getCanvasFormats().r32f then return nil end
    noiseLattice=love.graphics.newCanvas(2048,1024,{format='r32f',dpiscale=1,msaa=0})
    noiseLattice:setFilter('linear','linear')
    local previousCanvas=love.graphics.getCanvas()
    love.graphics.push('all')
    love.graphics.setCanvas(noiseLattice)
    love.graphics.origin()
    love.graphics.setScissor()
    love.graphics.setStencilTest()
    love.graphics.setBlendMode('replace')
    love.graphics.setColor(1,1,1,1)
    love.graphics.setShader(noiseShader)
    love.graphics.rectangle('fill',0,0,2048,1024)
    love.graphics.pop()
    love.graphics.setCanvas(previousCanvas)
    return noiseLattice
end

function Stage5S2R:new(args)
    Stage5S2R.super.new(self,args)
    self.shader=stage5Shader
    self.noiseLattice=getNoiseLattice()
    self.cam_translation={0,0,0}
    self.camMoveRange={999,999} -- xy plane is S^2 so unlimited
    self.camMoveSpeed=0.3
    self.reverseX=false
    self.sphereRadius=1
    self.cameraSpeed=1.30
    self.axialPosition=0
    self.lightColor={0.70,0.70,0.70}
    self.darkColor={0.35,0.35,0.35}

    self.paramSendFunction=function(self,shader)
        local center=G.runInfo.geometry.viewConfig.screenCenter
        shader:send('screenCenter',{center.x,center.y})
        shader:send('translation',{self.cam_translation[1],self.cam_translation[2],self.cam_translation[3]+self.axialPosition})
        shader:send('pitch',self.cam_pitch)
        shader:send('yaw',self.cam_yaw)
        shader:send('roll',self.cam_roll-self.cam_translation[1]) -- so left and right also rotates the view, matching the following behaviour of gameplay area
        shader:send('sphere_radius',self.sphereRadius)
        shader:send('use_noise_lattice',self.noiseLattice~=nil)
        if self.noiseLattice then shader:send('noise_lattice',self.noiseLattice) end
    end
end

function Stage5S2R:update(dt)
    Stage5S2R.super.update(self,dt)
    -- Match WORLD_PERIOD in the shader. Repeated scenery, not a quotient of R.
    self.axialPosition=(self.axialPosition+self.cameraSpeed*dt)%12
end

return Stage5S2R
