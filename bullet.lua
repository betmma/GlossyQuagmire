--! file: circle.lua
---@class Bullet:Shape
local Bullet = Shape:extend()

Bullet.FadeOut=function(self)
    local fadeFrame=self.fadeFrame or 30
    if self.frame+fadeFrame>=self.lifeFrame then
        self.safe=true
        self.spriteTransparency=(self.lifeFrame - self.frame)/fadeFrame
    end
end

Bullet.FadeIn=function(self)
    local fadeFrame=self.fadeFrame or 30
    if self.frame<=fadeFrame then
        self.safe=true
        self.spriteTransparency=self.frame/fadeFrame
    elseif self.frame==fadeFrame+1 then
        self.safe=false
    end
end

-- bullet size grows from 0 to [self.targetSize] in [self.zoomFrame] frames.
Bullet.ZoomIn=function(self)
    local zoomFrame=self.zoomFrame or 30
    local targetSize=self.targetSize or self.size
    if not self.targetSize then
        self.targetSize=self.size
    end
    if self.frame<=zoomFrame then
        self.size=targetSize*self.frame/zoomFrame
    end
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

function Bullet:getHitboxRadius()
    if self.sprite and self.sprite.data and self.sprite.data.hitRadius then
        return self.sprite.data.hitRadius * self.size
    end
    return self.size
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
        image=Asset.bulletImage,
        rotation=self.kinematicState.dir+math.pi/2+(self.spriteExtraDirection or 0),
        zoom=self.size,
        normalBatch=self.batch,
        meshBatch=Asset.bigBulletMeshes,
        color=color,
    }
end

---@param pos Position
---@param radius number
---@param rotation number
---@param quad love.Quad
---@param image love.Image
---@param color number[]|nil
function Bullet:meshDrawQuad(pos,radius,rotation,quad,image,color,meshBatch,sideNum)
    -- inner radius is hitbox radius
    local ringMeshes,fanMeshes=Shape:ringFanMesh(pos,self:getHitboxRadius(),radius,rotation,quad,image,sideNum,color)
    for _,mesh in ipairs(ringMeshes) do
        meshBatch:add(mesh)
    end
    for _,mesh in ipairs(fanMeshes) do
        meshBatch:add(mesh)
    end
end

function Bullet:update(dt)
    if self.removed then
        return
    end
    for k, func in pairs(self.extraUpdate or {}) do
        func(self,dt)
    end
    Shape.update(self,dt)
    if not self.safe then
        if #Effect.Shockwave.objects>0 then self:checkShockwaveRemove() end
    end
    self:checkHitPlayer()
    self.spriteExtraDirection=self.spriteExtraDirection+self.spriteRotationSpeed*Shape.timeSpeed
    if self.sprite then
        local data=self.sprite.data
        if data.isGIF then
            self.sprite:countDown()
        end
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
    if not self.safe then
        local selfRadius=self:getHitboxRadius()
        for key, player in pairs(Player.objects) do
            ---@cast player Player
            local dis=G.runInfo.geometry:distance(player.kinematicState.pos,self.kinematicState.pos)
            local radi=player.radius+selfRadius
            if dis<radi+player.radius*player.grazeRadiusFactor and not self.grazed then
                EventManager.post(EventManager.EVENTS.PLAYER_GRAZE,player,self:grazeValue())
                self.grazed=true
            end
            if player.invincibleFrame<=0 and dis<radi then
                EventManager.post(EventManager.EVENTS.PLAYER_HIT,player,self.damage or 1)
            end
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
end

return Bullet