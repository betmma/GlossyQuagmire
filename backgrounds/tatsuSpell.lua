local Shader=...
local TatsuSpell=Shader:extend()
local shader=ShaderScan:load_shader('shaders/backgrounds/tatsuSpell.glsl')
local CYCLE=60
local STEP=40

function TatsuSpell:new(args)
    TatsuSpell.super.new(self,args)
    self.autoDark=false
    self.completedCycles=0
    self.size=G.runInfo.geometry--[[@as Cylinder]].r0*3
end

local function smooth(t)
    t=math.max(0,math.min(1,t))
    return t*t*(3-2*t)
end

function TatsuSpell:render(center,slide,seams,initial,soften,x,y,rotation,zoom)
    love.graphics.setShader(shader)
    shader:send('history',self.front)
    shader:send('origin',center)
    shader:send('extent',self.size)
    shader:send('cycle',self.completedCycles)
    shader:send('cutAngle',(self.completedCycles%2)*math.pi/8)
    shader:send('slide',slide)
    shader:send('seams',seams)
    shader:send('initial',initial)
    rotation=rotation or 0
    zoom=zoom or 1
    shader:send('viewRotation',rotation)
    shader:send('viewZoom',zoom)
    local bounds=self.size*zoom*(math.abs(math.cos(rotation))+math.abs(math.sin(rotation)))
    love.graphics.rectangle('fill',x or 0,y or 0,bounds,bounds)
end

function TatsuSpell:draw()
    if G.save.options.reduceVisualQuality then return end
    love.graphics.push('all')
    -- Canvas passes must not inherit the game's screen transform or clipping.
    local target=love.graphics.getCanvas()
    love.graphics.push('all')
    love.graphics.origin()
    love.graphics.setScissor()
    love.graphics.setBlendMode('replace','premultiplied')
    love.graphics.setColor(1,1,1,1)
    if not self.front then
        self.front=love.graphics.newCanvas(self.size,self.size)
        self.back=love.graphics.newCanvas(self.size,self.size)
        self.front:setFilter('linear','linear')
        self.back:setFilter('linear','linear')
        love.graphics.setCanvas(self.back)
        self:render({self.size/2,self.size/2},0,0,true,false)
        self.front,self.back=self.back,self.front
    end
    local cycles=math.floor(self.frame/CYCLE)
    -- Bake only whole moves, never outlines. Drawing extra frames cannot
    -- advance the feedback, and skipped draws still preserve every recut.
    while self.completedCycles<cycles do
        love.graphics.setCanvas(self.back)
        self:render({self.size/2,self.size/2},STEP,0,false,true)
        self.front,self.back=self.back,self.front
        self.completedCycles=self.completedCycles+1
    end
    love.graphics.pop()
    love.graphics.setCanvas(target)
    love.graphics.setBlendMode('alpha','alphamultiply')
    love.graphics.setColor(1,1,1,self.transparency)
    local phase=self.frame%CYCLE
    local slide=STEP*smooth(phase/CYCLE)
    local seams=smooth(phase/CYCLE*5)*(1-smooth((phase-CYCLE*0.8)/CYCLE*5))
    local geometry=G.runInfo.geometry
    ---@cast geometry Cylinder
    local center=geometry.viewConfig.screenCenter
    local playerPos=G.runInfo.player.kinematicState.pos
    -- Match the camera-dependent terms of Cylinder:toScreen. Apply them
    -- only for display so camera movement never gets baked into history.
    local rotation=geometry.viewConfig.following and (playerPos.x/geometry.r0+math.pi/2) or 0
    local zoom=math.exp(-math.min(playerPos.y/geometry.r0,0))
    local bounds=self.size*zoom*(math.abs(math.cos(rotation))+math.abs(math.sin(rotation)))
    self:render({center.x,center.y},slide,seams,false,false,
        center.x-bounds/2,center.y-bounds/2,rotation,zoom)
    love.graphics.pop()
end

function TatsuSpell:remove()
    if self.front then
        self.front:release()
        self.back:release()
        self.front,self.back=nil,nil
    end
    TatsuSpell.super.remove(self)
end

return TatsuSpell
