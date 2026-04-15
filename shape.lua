--! file: shape.lua
local Shape = GameObject:extend()
-- Shape.removeDistance=100
Shape.timeSpeed=1

function Shape:new(args)
    args=args or {}
    self.args=args
    if args.kinematicState then
        if not args.kinematicState.pos then
            args.kinematicState.pos=args.kinematicState.position
        end
        if not args.kinematicState.pos then
            error('Shape:new: kinematicState must have pos')
        end
        if not args.kinematicState.speed then
            args.kinematicState.speed=0
        end
        if not args.kinematicState.dir then
            args.kinematicState.dir=args.kinematicState.direction or 0
        end
    end
    self.kinematicState=args.kinematicState or G.runInfo.geometry:init()
    self.lifeFrame=args.lifeFrame or 1000
    self.time=0
    self.frame=0
    -- self.removeDistance=args.removeDistance or Shape.removeDistance
end

function Shape:bindState(other)
    self.kinematicState=other.kinematicState
    self.binded=other
end

function Shape:update(dt)
    self.time=self.time+dt*Shape.timeSpeed
    self.frame=self.frame+1
    if self.frame>self.lifeFrame then
        self:remove()
    end
    local geometry=G.runInfo.geometry
    if not self.binded then
        geometry:update(self.kinematicState,dt)
    else
        if self.binded.removed then
            self:remove()
        end
    end
    -- if self:distanceRemoveCheck() then
    --     self:remove()
    -- end
end


function Shape:getHitboxRadius()
    local size=self.size or 1
    if self.sprite and self.sprite.data and self.sprite.data.hitRadius then
        return self.sprite.data.hitRadius * size
    end
    return self.hitboxRadius or size
end

---@class DrawQuadArgs
---@field quad love.Quad
---@field rotation number
---@field zoom number
---@field normalBatch love.SpriteBatch|nil
---@field meshBatch MeshBatch|nil
---@field color number[]|nil
---@field kinematicState KinematicState|nil if provided, will be used to determine the position and whether to draw as quad or mesh. if not provided, use self.kinematicState.
---@field isSquare boolean|nil

---@param args DrawQuadArgs
function Shape:drawQuad(args)
    -- Destructure arguments for easier access
    local quad        = args.quad
    local rotation    = args.rotation
    local zoom        = args.zoom
    local normalBatch = args.normalBatch
    local meshBatch   = args.meshBatch
    local color       = args.color or {1, 1, 1, 1}
    local kinematicState = args.kinematicState or self.kinematicState
    local geometry=G.runInfo.geometry
    local quadX,quadY,w,h=quad:getViewport()
    local sizeRatio=zoom
    local radius=math.max(w,h)/2*sizeRatio
    local canSimpleDraw,suggestedSideNum=geometry:canSimpleDraw(kinematicState.pos,radius)
    local screenPositions=geometry:toScreen(kinematicState.pos)
    local zoomFactorToScreen=geometry:zoomFactorToScreen(kinematicState.pos)
    if DEV_MODE then
        if love.keyboard.isDown('f6') then
            canSimpleDraw=true
        elseif love.keyboard.isDown('f7') then
            canSimpleDraw=false
        end
    end
    if not meshBatch then
        canSimpleDraw=true
    end
    if not normalBatch then
        canSimpleDraw=false
    end
    if canSimpleDraw then
        ---@cast normalBatch love.SpriteBatch
        normalBatch:setColor(color[1],color[2],color[3],color[4])
        for i,screenPos in ipairs(screenPositions) do
            if not screenPos.dummy then
                ---@cast screenPos ScreenPosition
                local rotationWithScreen=rotation+(screenPos.rotation or 0)
                if screenPos.flip then
                    rotationWithScreen=rotationWithScreen*-1
                end
                local sizeRatioWithScreen=sizeRatio*zoomFactorToScreen[i]
                local sizeX=sizeRatioWithScreen
                local sizeY=sizeRatioWithScreen
                if screenPos.flip then
                    sizeX=sizeX*-1
                end
                self:simpleDrawQuad(quad,w,h,screenPos,rotationWithScreen,sizeX,sizeY,normalBatch)
            end
        end
    else
        if not meshBatch then
            error('Shape:drawQuad: tries to mesh draw with meshBatch = nil')
        end
        self:meshDrawQuad(kinematicState.pos,w*sizeRatio,h*sizeRatio,rotation,quad,color,meshBatch,suggestedSideNum,args.isSquare)
    end
end

---@param quad love.Quad
---@param w number
---@param h number
---@param screenPos ScreenPosition
---@param rotation number
---@param sizeX number
---@param sizeY number
---@param normalBatch love.SpriteBatch
function Shape:simpleDrawQuad(quad,w,h,screenPos,rotation,sizeX,sizeY,normalBatch)
    normalBatch:add(quad,screenPos.x,screenPos.y,rotation,sizeX,sizeY,w/2,h/2)
end

---@param pos Position
---@param w number
---@param h number
---@param rotation number
---@param quad love.Quad
---@param color number[]|nil
---@param meshBatch MeshBatch
---@param sideNum integer
---@param isSquare boolean|nil if sprite is square
function Shape:meshDrawQuad(pos,w,h,rotation,quad,color,meshBatch,sideNum,isSquare)
    MeshFuncs.fanMesh(pos,w,h,rotation,quad,sideNum,color,isSquare,meshBatch)
end

---@class Shape:GameObject
---@field lifeFrame number after which the object will be removed
---@field frame number number of frames since the object was created. It's just an incrementer, so you can modify it freely.
---@field time number time in seconds since the object was created, affected by Shape.timeSpeed.
---@field kinematicState KinematicState
---@field getHitboxRadius fun(self:Shape):number get the hitbox radius of this shape. By default, it's self.size, but if the sprite has a hitRadius defined in its data, it will be that value multiplied by self.size.
---@field drawQuad fun(self:Shape,args:DrawQuadArgs):nil general function to draw a quad. geometry could decide it to drawn as a quad or a mesh (with more vertices), and it's possible to force either mode by not providing the corresponding batch. image is only used for mesh drawing.
---@field bindState fun(self:Shape,other:Shape):nil set self's kinematicState to other's kinematicState, and cancel update to self.kinematicState, so it will follow other's kinematicState exactly. will remove self if other is removed.
---@field private binded Shape what shape the shape is binded to. if not nil, self won't update its own kinematicState.
-- -@field removeDistance number distance from the screen after which the object will be removed (roughly)
return Shape