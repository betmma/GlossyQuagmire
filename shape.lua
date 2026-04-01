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
---@class DrawQuadArgs
---@field quad love.Quad
---@field image love.Image|nil
---@field rotation number
---@field zoom number
---@field normalBatch love.SpriteBatch|nil
---@field meshBatch love.SpriteBatch|nil
---@field color number[]|nil

---@param args DrawQuadArgs
function Shape:drawQuad(args)
    -- Destructure arguments for easier access
    local quad        = args.quad
    local image       = args.image
    local rotation    = args.rotation
    local zoom        = args.zoom
    local normalBatch = args.normalBatch
    local meshBatch   = args.meshBatch
    local color       = args.color or {1, 1, 1, 1}
    local geometry=G.runInfo.geometry
    local quadX,quadY,w,h=quad:getViewport()
    local sizeRatio=zoom*geometry.sizeFactor
    local radius=math.max(w,h)/2*sizeRatio
    local canSimpleDraw=geometry:canSimpleDraw(self.kinematicState,radius)
    local screenPositions=geometry:toScreen(self.kinematicState)
    local zoomFactorToScreen=geometry:zoomFactorToScreen(self.kinematicState)
    if (canSimpleDraw or not meshBatch) and normalBatch then
        normalBatch:setColor(color)
        for i,screenPos in ipairs(screenPositions) do
            if not screenPos.dummy then
                ---@cast screenPos Position
                self:simpleDrawQuad(quad,w,h,screenPos,rotation,sizeRatio*zoomFactorToScreen[i],normalBatch)
            end
        end
    else
        self:meshDrawQuad(self.kinematicState,radius,rotation,quad,image,color,meshBatch)
    end
end

---@param quad love.Quad
---@param w number
---@param h number
---@param screenPos Position
---@param rotation number
---@param sizeRatio number
---@param normalBatch love.SpriteBatch
function Shape:simpleDrawQuad(quad,w,h,screenPos,rotation,sizeRatio,normalBatch)
    normalBatch:add(quad,screenPos.x,screenPos.y,rotation,sizeRatio,sizeRatio,w/2,h/2)
end

---@param pos Position
---@param radius number
---@param rotation number
---@param quad love.Quad
---@param image love.Image
---@param color number[]|nil
function Shape:meshDrawQuad(pos,radius,rotation,quad,image,color,meshBatch)
    local meshes=self:fanMesh(pos,radius,rotation,quad,image,16,color)
    for _,mesh in ipairs(meshes) do
        meshBatch:add(mesh)
    end
end

-- calculate fan mesh for drawing large sprite to reduce distortion
---@param position Position position of the center of the sprite in geometry space
---@param posR number "radius of object"
---@param quad love.Quad "quad of sprite"
---@param image love.Image "image of sprite"
---@param n integer "number of vertices on the circle"
---@param color number[]|nil "color RGBA, each in [0,1]"
---@param square boolean|nil "if true, vertices are calculated on a square instead of a circle (for square sprites)"
---@return love.Mesh[] "fan mesh"
function Shape:fanMesh(position,posR,orientation,quad,image,n,color,square)
    local posX,posY=position.x,position.y
    color=color or {1,1,1,1}
    local x,y,w,h=quad:getViewport() -- like 100, 100, 50, 50 so needs to divide width and height
    local imgW,imgH=image:getDimensions()
    x,y,w,h=x/imgW,y/imgH,w/imgW,h/imgH
    local vertices={} -- multiple possible meshes
    local coreScreenPoses=G.runInfo.geometry:toScreen(position)
    for si,coreScreenPos in ipairs(coreScreenPoses) do
        if not coreScreenPos.dummy then -- if center is dummy, this fan mesh cannot be formed
            ---@cast coreScreenPos Position
            vertices[si]={{coreScreenPos.x,coreScreenPos.y,x+w/2,y+h/2,color[1],color[2],color[3],color[4]}}
        end
    end
    for i=0,n do
        local angle=math.pi*2/n*i
        local rRatio=1
        if square then
            rRatio=1/math.cos((angle+math.pi/4)%(math.pi/2)-math.pi/4)
        end
        local poses=G.runInfo.geometry:toScreen(G.runInfo.geometry:rThetaGo(position,posR*rRatio,angle+orientation))
        for si,screenPos in ipairs(poses) do
            if not screenPos.dummy then
                ---@cast screenPos Position
                local x2,y2=screenPos.x,screenPos.y
                local u,v=(math.cos(angle)*rRatio+1)/2,(math.sin(angle)*rRatio+1)/2
                if vertices[si] then
                    table.insert(vertices[si], {x2,y2,x+u*w,y+v*h,color[1],color[2],color[3],color[4]})
                end
            end
        end
    end
    local meshes={}
    for si,v in pairs(vertices) do
        if v and #v>=3 then
            local mesh=love.graphics.newMesh(v,'fan')
            mesh:setTexture(image)
            table.insert(meshes,mesh)
        end
    end
    return meshes
end


-- -- calculate double layered ring+fan mesh for drawing large sprite to reduce distortion
-- ---@param position Position position of the center of the sprite in geometry space
-- ---@param innerR number "inner radius of ring"
-- ---@param outerR number "outer radius of ring"
-- ---@param orientation angle "orientation of object"
-- ---@param quad love.Quad "quad of sprite"
-- ---@param image love.Image "image of sprite"
-- ---@param n integer "number of vertices on the circle"
-- ---@param color number[]|nil "color RGBA, each in [0,1]"
-- ---@return love.Mesh "ring mesh"
-- ---@return love.Mesh "fan mesh"
-- function Shape:ringFanMesh(position,innerR,outerR,orientation,quad,image,n,color)
--     color=color or {1,1,1,1}
--     local x,y,w,h=quad:getViewport() -- like 100, 100, 50, 50 so needs to divide width and height
--     local imgW,imgH=image:getDimensions()
--     x,y,w,h=x/imgW,y/imgH,w/imgW,h/imgH
--     local ratio=innerR/outerR
--     local ringMeshVertices={}
--     local fanMeshVertices={{position.x,position.y,x+w/2,y+h/2,color[1],color[2],color[3],color[4]}}
--     for i=0,n do
--         local angle=math.pi*2/n*i
--         local x2,y2=G.runInfo.geometry:rThetaGo(position, outerR, angle+orientation)
--         local u,v=(math.cos(angle)+1)/2,(math.sin(angle)+1)/2
--         ringMeshVertices[i*2+1]={x2,y2,x+u*w,y+v*h,color[1],color[2],color[3],color[4]}
--         fanMeshVertices[i+2]=ringMeshVertices[i*2+1]
--         local x3,y3=G.runInfo.geometry:rThetaGo(position, innerR, angle+orientation)
--         u,v=(math.cos(angle)*ratio+1)/2,(math.sin(angle)*ratio+1)/2
--         ringMeshVertices[i*2+2]={x3,y3,x+u*w,y+v*h,color[1],color[2],color[3],color[4]}
--     end
--     local ringMesh=love.graphics.newMesh(ringMeshVertices,'strip')
--     ringMesh:setTexture(image)
--     local fanMesh=love.graphics.newMesh(fanMeshVertices,'fan')
--     fanMesh:setTexture(image)
--     return ringMesh,fanMesh
-- end

---@class Shape:GameObject
---@field lifeFrame number after which the object will be removed
---@field frame number number of frames since the object was created. It's just an incrementer, so you can modify it freely.
---@field time number time in seconds since the object was created, affected by Shape.timeSpeed.
---@field kinematicState KinematicState
---@field drawQuad fun(self:Shape,args:DrawQuadArgs) general function to draw a quad. geometry could decide it to drawn as a quad or a mesh (with more vertices), and it's possible to force either mode by not providing the corresponding batch. image is only used for mesh drawing.
-- -@field removeDistance number distance from the screen after which the object will be removed (roughly)
return Shape