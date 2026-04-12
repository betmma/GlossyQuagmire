--! file: circle.lua
---@class Bullet:Shape
local Bullet = Shape:extend()

---@class Action
---@field isAction true
---@field params table<string, any>
---@field func fun(self:Bullet, params:table<string, any>):nil


local fadeOut=function(self,params)
    local fadeFrame=params.fadeFrame or 30
    if self.frame+fadeFrame>=self.lifeFrame then
        if params.setSafe then
            self.safe=true
        end
        self.spriteTransparency=(self.lifeFrame - self.frame)/fadeFrame
    end
end

---@param fadeFrame integer number of frames for the fade out animation, default 30
---@param setSafe boolean whether to set the bullet safe when start fading out, default false
--- @return Action
Bullet.FadeOut=function(fadeFrame,setSafe)
    return {isAction=true,params={fadeFrame=fadeFrame,setSafe=setSafe},func=fadeOut}
end

local fadeIn=function(self,params)
    local fadeFrame=params.fadeFrame or 30
    if self.frame<=fadeFrame then
        if params.setSafe then
            self.safe=true
        end
        self.spriteTransparency=(params.fadeTransparency or 1) * self.frame/fadeFrame
    elseif self.frame==fadeFrame+1 then
        if params.setSafe then
            self.safe=false
        end
    end
end

---@param fadeFrame integer number of frames for the fade in animation, default 30
---@param setSafe boolean whether to set the bullet safe when start fading in, default false
---@param fadeTransparency number|nil if you want to set a specific transparency instead of 0-1, default nil
--- @return Action
Bullet.FadeIn=function(fadeFrame,setSafe,fadeTransparency)
    return {isAction=true,params={fadeFrame=fadeFrame,setSafe=setSafe,fadeTransparency=fadeTransparency},func=fadeIn}
end

local zoomIn=function(self,params)
    local zoomFrame=params.zoomFrame or 30
    local targetSize=params.targetSize or self.size
    if self.frame<=zoomFrame then
        self.size=targetSize*self.frame/zoomFrame
    end
end

-- bullet size grows from 0 to [self.targetSize] in [self.zoomFrame] frames.
--- @param zoomFrame integer number of frames for the zoom animation, default 30
--- @param targetSize number target size for the zoom animation, default self.size
--- @return Action
Bullet.ZoomIn=function(zoomFrame,targetSize)
    return {isAction=true,params={zoomFrame=zoomFrame,targetSize=targetSize},func=zoomIn}
end

function Bullet:new(args)
    Bullet.super.new(self, args)
    self.size = args.size or 1
    ---@type Sprite
    self.sprite=args.sprite
    if self.sprite then
        local data=self.sprite.data
        if not data then
            error('Bullet:new: self.sprite.data is nil')
        end
        if data.isGIF then
            ---@type GIFSprite
            self.sprite=copy_table(self.sprite)
            self.sprite:randomizeCurrentFrame()
        end
    end
    self.spriteColor=args.spriteColor
    self.extraUpdate=args.extraUpdate or {}
    if type(self.extraUpdate)=='function' then
        self.extraUpdate={self.extraUpdate}
    end
    -- safe means won't hit player 
    self.safe=args.safe or false
    -- fromPlayer means can hit enemy
    self.fromPlayer=args.fromPlayer or false
    -- invincible means won't be removed by normal shockwave (win shockwave can)
    self.invincible=args.invincible or false

    self.damage=args.damage or 1

    self.grazed=args.grazed or false
    self.baseGrazeValue=args.baseGrazeValue or 1

    self.batch=args.batch or (args.highlight and Asset.bulletHighlightBatch or BulletBatch)
    self.meshBatch=args.meshBatch or Asset.bigBulletMeshes
    self.forceQuad=args.forceQuad or false
    self.forceMesh=args.forceMesh or false
    self.spriteTransparency=args.spriteTransparency or 1

    self.spriteExtraDirection=0
    self.spriteRotationSpeed=0 -- used for nuke bullet
    self.spriteColor=args.spriteColor

    if self.sprite.data.key=='note' then
        self.spriteExtraDirection=math.pi -- note sprites are rotated 180 degrees
    end
    if self.sprite==BulletSprites.nuke then
        self.invincible=true
        self.batch=Asset.bulletHighlightBatch
        self.spriteRotationSpeed=0.01
    end

    if args.events then
        for _, eventFunc in pairs(args.events) do
            eventFunc(self, args)
        end
    end
end

function Bullet:draw()
    if not self.sprite then
        return
    end
    local color={1,1,1,1}
    if self.spriteColor then
        color=self.spriteColor
    end
    color[4]=color[4]*self.spriteTransparency
    self:drawQuad{
        quad=self.sprite.quad,
        rotation=self.kinematicState.dir+math.pi/2+(self.spriteExtraDirection or 0),
        zoom=self.size,
        normalBatch=(not self.forceMesh)and self.batch,
        meshBatch=(not self.forceQuad)and self.meshBatch,
        color=color,
        isSquare=self.sprite.data.isSquare
    }
end

---@param pos Position
---@param w number
---@param h number
---@param rotation number
---@param quad love.Quad
---@param color number[]|nil
---@param meshBatch MeshBatch
---@param sideNum integer
function Bullet:meshDrawQuad(pos,w,h,rotation,quad,color,meshBatch,sideNum)
    -- inner radius is hitbox radius
    MeshFuncs.ringFanMesh(pos,self:getHitboxRadius(),w,h,rotation,quad,sideNum,color,meshBatch)
end

function Bullet:update(dt)
    for k, func in pairs(self.extraUpdate or {}) do
        if type(func)=='function' then
            func(self,dt)
        elseif type(func)=='table' and func.isAction then
            func.func(self,func.params)
        end
    end
    Shape.update(self,dt)
    if not self.safe then
        if #Effect.Shockwave.objects>0 then self:checkShockwaveRemove() end
    end
    self:checkHitPlayer()
    self:updateSprite()
end

function Bullet:updateSprite()
    self.spriteExtraDirection=self.spriteExtraDirection+self.spriteRotationSpeed*Shape.timeSpeed
    if self.sprite and self.sprite.data and self.sprite.data.isGIF then
        self.sprite:countDown()
    end
end

function Bullet:checkShockwaveRemove()
    local selfRadius=self:getHitboxRadius()
    for k,shockwave in pairs(Effect.Shockwave.objects) do
        ---@cast shockwave Shockwave
        if shockwave.canRemove.bullet==true and(self.invincible==false or shockwave.canRemove.invincible==true)and(self.safe==false or shockwave.canRemove.safe==true) and G.runInfo.geometry:distance(shockwave.kinematicState.pos,self.kinematicState.pos)<shockwave:getHitboxRadius()+selfRadius then
            EventManager.post(EventManager.EVENTS.SHOCKWAVE_REMOVE_BULLET,self,shockwave)
            self:remove()
            self:removeEffect()
        end
    end
end

function Bullet:checkHitPlayer()
    if self.safe then
        return
    end
    local selfRadius=self:getHitboxRadius()
    for key, player in pairs(Player.objects) do
        ---@cast player Player
        local dis=G.runInfo.geometry:distance(player.kinematicState.pos,self.kinematicState.pos)
        local radi=player.radius+selfRadius
        if dis<radi+player.radius*player.grazeRadiusFactor and not self.grazed and self.grazeValue then
            EventManager.post(EventManager.EVENTS.PLAYER_GRAZE,player,self:grazeValue())
            self.grazed=true
        end
        if player.invincibleFrame<=0 and dis<radi then
            EventManager.post(EventManager.EVENTS.PLAYER_HIT,player,self.damage or 1)
        end
    end
end
function Bullet:grazeValue()
    local baseValue=self.baseGrazeValue or 1
    if self.lifeFrame<3 or self.frame<3 then
        return 0.05*baseValue
    end
    return 1*baseValue
end

function Bullet:removeEffect()
    Effect.Larger{kinematicState=copy_table(self.kinematicState),sprite=Asset.shards.dot,radius=1,growSpeed=0.1,animationFrame=20}
end

function Bullet:changeSpriteColor(color)
    if not color then
        local colors=self.sprite.data.possibleColors
        if not colors then
            return
        end
        local ind=math.floor(math.random(1,#colors+0.999999))
        color=colors[ind]
    end
    self.sprite=BulletSprites[self.sprite.data.key][color] or self.sprite
end

-- you shouldn't directly change self.sprite, cuz radius won't update (same as how Kanako's 神穀 spellcard has larger hitbox)
function Bullet:changeSprite(sprite)
    local data=self.sprite.data
    self.sprite=sprite
    data=self.sprite.data
    if data.isGIF then
        self.sprite=copy_table(self.sprite)
        self.sprite:randomizeCurrentFrame()
    end
        if not self.sprite then
            error('PlayerShot:hitEffect: no fade sprite for color ')
        end
        if not self.sprite.quad then
            error('PlayerShot:hitEffect: fade sprite quad is nil for color ')
        end
end

return Bullet