local WalkerShader=...
local stage6Shader=ShaderScan:load_shader('shaders/backgrounds/stage6S3.glsl')
local cloudAtlasShader=ShaderScan:load_shader('shaders/backgrounds/stage6CloudAtlas.glsl')
local Stage6S3=WalkerShader:extend()
local textures
local cloudField

local function getCloudField()
    if cloudField then return cloudField end
    local formats=love.graphics.getCanvasFormats()
    local format=formats.r16f and 'r16f' or (formats.rgba16f and 'rgba16f')
    if not format then return nil end -- Keep the original procedural path.
    -- Cache the angular density once, shared by every stage instance. The time
    -- offset scrolls this periodic field; it does not require regenerating it.
    cloudField=love.graphics.newCanvas(4096,1024,{format=format,dpiscale=1,msaa=0})
    cloudField:setFilter('linear','linear')
    cloudField:setWrap('repeat','repeat')
    local previousCanvas=love.graphics.getCanvas()
    love.graphics.push('all')
    love.graphics.setCanvas(cloudField)
    love.graphics.origin()
    love.graphics.setScissor()
    love.graphics.setStencilTest()
    love.graphics.setBlendMode('replace')
    love.graphics.setColor(1,1,1,1)
    love.graphics.setShader(cloudAtlasShader)
    love.graphics.rectangle('fill',0,0,4096,1024)
    love.graphics.pop()
    love.graphics.setCanvas(previousCanvas)
    return cloudField
end

local function getTextures()
    if textures then return textures end
    textures={}
    for _,name in ipairs({'earth','earth_clouds','moon'}) do
        local texture=love.graphics.newImage('assets/backgrounds/'..name..'.jpg')
        texture:setWrap('repeat','clamp')
        texture:setFilter('linear','linear')
        textures[name]=texture
    end
    return textures
end

function Stage6S3:new(args)
    Stage6S3.super.new(self,args)
    self.shader=stage6Shader
    self.textures=getTextures()
    self.cloudField=getCloudField()
    -- a,b tilt the forward great-circle plane; t is intrinsic arc length.
    -- Every fixed arrow-key offset follows a great circle, not a latitude.
    self.cam_translation={0,0,0}
    self.camMoveRange={0.12,0.12}
    self.camMoveSpeed=0.12
    self.reverseX=false
    self.cameraSpeed=0.24
    self.elapsed=0
    -- Face the local forward tangent of the trail.
    self.cam_yaw=0
    self.lightColor={0.80,0.80,0.80}
    self.darkColor={0.40,0.40,0.40}
    self.paramSendFunction=function(self,shader)
        local center=G.runInfo.geometry.viewConfig.screenCenter
        shader:send('screenCenter',{center.x,center.y})
        shader:send('translation',self.cam_translation)
        shader:send('time',self.elapsed)
        shader:send('pitch',self.cam_pitch)
        shader:send('yaw',self.cam_yaw)
        shader:send('roll',self.cam_roll)
        shader:send('earth_texture',self.textures.earth)
        shader:send('cloud_texture',self.textures.earth_clouds)
        shader:send('moon_texture',self.textures.moon)
        shader:send('use_cloud_field',self.cloudField~=nil)
        if self.cloudField then shader:send('cloud_field',self.cloudField) end
    end
end

function Stage6S3:update(dt)
    Stage6S3.super.update(self,dt)
    self.elapsed=self.elapsed+dt
    self.cam_translation[3]=(self.cam_translation[3]+self.cameraSpeed*dt)%(2*math.pi)
end

return Stage6S3
