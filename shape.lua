--! file: shape.lua
local Shape = GameObject:extend()
-- Shape.removeDistance=100
Shape.timeSpeed=1

function Shape:new(args)
    args=args or {}
    self.args=args
    self.kinematicState=args.kinematicState or G.runInfo.geometry.init()
    self.lifeFrame=args.lifeFrame or 1000
    self.time=0
    self.frame=0
    -- self.removeDistance=args.removeDistance or Shape.removeDistance
end


function Shape:update(dt)
    self.time=self.time+dt*Shape.timeSpeed
    self.frame=self.frame+1
    if self.frame>self.lifeFrame then
        self:remove()
    end
    local geometry=G.runInfo.geometry
    geometry:update(self.kinematicState,dt)
    -- if self:distanceRemoveCheck() then
    --     self:remove()
    -- end
end

--- general function to draw a quad. geometry could decide it to drawn as a quad or a mesh (with more vertices)
function Shape:drawQuad(quad,image,rotation,zoom,normalBatch,meshBatch,color)
    color=color or {1,1,1,1}
    normalBatch:setColor(color)
    local geometry=G.runInfo.geometry
    local quadX,quadY,w,h=quad:getViewport()
    local sizeRatio=zoom*geometry.sizeFactor
    local radius=math.max(w,h)*sizeRatio
    local canSimpleDraw=geometry:canSimpleDraw(self.kinematicState,radius)
    local screenPositions=geometry:toScreen(self.kinematicState)
    local zoomFactorToScreen=geometry:zoomFactorToScreen(self.kinematicState)
    for i,screenPos in ipairs(screenPositions) do
        if canSimpleDraw or not meshBatch then
            self:simpleDrawQuad(quad,w,h,screenPos,rotation,sizeRatio*zoomFactorToScreen[i],normalBatch)
        else
            self:meshDrawQuad(screenPos,radius,rotation,quad,image,color,meshBatch)
        end
    end
end

function Shape:simpleDrawQuad(quad,w,h,screenPos,rotation,sizeRatio,normalBatch)
    normalBatch:add(quad,screenPos.x,screenPos.y,rotation,sizeRatio,sizeRatio,w/2,h/2)
end

function Shape:meshDrawQuad(pos,radius,rotation,quad,image,color,meshBatch)
    local mesh=self:fanMesh(pos,radius,rotation,quad,image,8,color)
    meshBatch:add(mesh)
end

-- calculate fan mesh for drawing large sprite to reduce distortion
---@param position Position position of the center of the sprite in geometry space
---@param posR number "radius of object"
---@param quad love.Quad "quad of sprite"
---@param image love.Image "image of sprite"
---@param n integer "number of vertices on the circle"
---@param color number[]|nil "color RGBA, each in [0,1]"
---@param square boolean|nil "if true, vertices are calculated on a square instead of a circle (for square sprites)"
---@return love.Mesh "fan mesh"
function Shape:fanMesh(position,posR,orientation,quad,image,n,color,square)
    local posX,posY=position.x,position.y
    color=color or {1,1,1,1}
    local x,y,w,h=quad:getViewport() -- like 100, 100, 50, 50 so needs to divide width and height
    local imgW,imgH=image:getDimensions()
    x,y,w,h=x/imgW,y/imgH,w/imgW,h/imgH
    local vertices={}
    vertices[1]={posX,posY,x+w/2,y+h/2,color[1],color[2],color[3],color[4]}
    for i=0,n do
        local angle=math.pi*2/n*i
        local rRatio=1
        if square then
            rRatio=1/math.cos((angle+math.pi/4)%(math.pi/2)-math.pi/4)
        end
        local pos=G.runInfo.geometry:rThetaGo(position,posR*rRatio,angle+orientation)
        local x2,y2=pos.x,pos.y
        local u,v=(math.cos(angle)*rRatio+1)/2,(math.sin(angle)*rRatio+1)/2
        vertices[i+2]={x2,y2,x+u*w,y+v*h,color[1],color[2],color[3],color[4]}
    end
    local mesh=love.graphics.newMesh(vertices,'fan')
    mesh:setTexture(image)
    return mesh
end

---@class Shape:GameObject
---@field lifeFrame number after which the object will be removed
---@field frame number number of frames since the object was created. It's just an incrementer, so you can modify it freely.
---@field time number time in seconds since the object was created, affected by Shape.timeSpeed.
---@field kinematicState KinematicState
-- -@field removeDistance number distance from the screen after which the object will be removed (roughly)
return Shape