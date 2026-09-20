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
    -- WalkerShader still handles look controls and manual travel along R.
    -- Spherical movement is integrated separately in the transported frame.
    self.camMoveRange={0,0}
    self.spherePosition={0,0,1}
    self.sphereRight={1,0,0}
    self.sphereDown={0,1,0}
    self.followRoll=0
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
        shader:send('axial_position',self.cam_translation[3]+self.axialPosition)
        shader:send('sphere_position',self.spherePosition)
        shader:send('sphere_right',self.sphereRight)
        shader:send('sphere_down',self.sphereDown)
        shader:send('pitch',self.cam_pitch)
        shader:send('yaw',self.cam_yaw)
        shader:send('roll',self.cam_roll+self.followRoll) -- horizontal input also rotates the view, matching the following gameplay area
        shader:send('sphere_radius',self.sphereRadius)
        shader:send('use_noise_lattice',self.noiseLattice~=nil)
        if self.noiseLattice then shader:send('noise_lattice',self.noiseLattice) end
    end
end

-- dx/dy are angular displacements in the current spherical tangent frame.
-- Rotate the position and transport both axes along the same great circle.
function Stage5S2R:moveOnSphere(dx,dy)
    local angle=math.sqrt(dx*dx+dy*dy)
    if angle==0 then return end
    local q,right,down=self.spherePosition,self.sphereRight,self.sphereDown
    local a,b=dx/angle,dy/angle
    local ux,uy,uz=a*right[1]+b*down[1],a*right[2]+b*down[2],a*right[3]+b*down[3]
    local c,s=math.cos(angle),math.sin(angle)
    local qx,qy,qz=q[1]*c+ux*s,q[2]*c+uy*s,q[3]*c+uz*s
    -- The component of right along the travel tangent rotates with it;
    -- its component perpendicular to the great-circle plane stays fixed.
    local rx=right[1]+a*(ux*(c-1)-q[1]*s)
    local ry=right[2]+a*(uy*(c-1)-q[2]*s)
    local rz=right[3]+a*(uz*(c-1)-q[3]*s)

    -- Correct roundoff locally, without rebuilding the frame from a pole.
    local qLength=math.sqrt(qx*qx+qy*qy+qz*qz)
    qx,qy,qz=qx/qLength,qy/qLength,qz/qLength
    local radial=qx*rx+qy*ry+qz*rz
    rx,ry,rz=rx-qx*radial,ry-qy*radial,rz-qz*radial
    local rLength=math.sqrt(rx*rx+ry*ry+rz*rz)
    rx,ry,rz=rx/rLength,ry/rLength,rz/rLength
    q[1],q[2],q[3]=qx,qy,qz
    right[1],right[2],right[3]=rx,ry,rz
    down[1],down[2],down[3]=qy*rz-qz*ry,qz*rx-qx*rz,qx*ry-qy*rx
end

function Stage5S2R:update(dt)
    Stage5S2R.super.update(self,dt)
    local keyIsDown=G.runInfo.player and G.runInfo.player.keyIsDown or love.keyboard.isDown
    local horizontal=(keyIsDown('right') and 1 or 0)-(keyIsDown('left') and 1 or 0)
    local vertical=(keyIsDown('down') and 1 or 0)-(keyIsDown('up') and 1 or 0)
    local step=self.camMoveSpeed*dt
    local dx=horizontal*step*(self.reverseX and -1 or 1)
    self:moveOnSphere(dx,vertical*step)
    self.followRoll=(self.followRoll-dx)%(2*math.pi)
    -- Match WORLD_PERIOD in the shader. Repeated scenery, not a quotient of R.
    self.axialPosition=(self.axialPosition+self.cameraSpeed*dt)%12
end

return Stage5S2R
