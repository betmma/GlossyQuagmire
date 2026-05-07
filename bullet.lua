--! file: circle.lua
---@class Bullet:Shape
---@field size number The scale/zoom factor of the bullet.
---@field sprite Sprite|GIFSprite The visual representation of the bullet.
---@field spriteColor rgbaColor|nil RGBA table for tinting the sprite.
---@field safe boolean If true, the bullet will not damage the player.
---@field fromPlayer boolean Whether the bullet originated from the player.
---@field invincible boolean If true, normal shockwaves won't remove this bullet.
---@field damage number Amount of damage dealt to player on hit. Probably wont be value other than 1.
---@field grazed boolean Whether this bullet has already triggered a graze event.
---@field baseGrazeValue number The amount added to graze stats. Probably wont be value other than 1.
---@field batch love.SpriteBatch|nil The sprite batch used for standard drawing.
---@field meshBatch MeshBatch|nil The mesh batch used for complex/deformed drawing.
---@field forceQuad boolean If true, forces simple quad drawing even if geometry suggests mesh.
---@field forceMesh boolean If true, forces mesh drawing.
---@field spriteTransparency number Alpha multiplier (0-1).
---@field spriteExtraDirection number Internal rotation offset (e.g., for 'note' sprites or rotation effects).
---@field spriteRotationSpeed number How fast the sprite rotates over time.
---@field updateSprite fun(self:Bullet):nil Updates animation frames and rotation.
---@field checkShockwaveRemove fun(self:Bullet):nil Checks collision with active shockwaves.
---@field checkHitPlayer fun(self:Bullet):nil Checks collision with player hitbox and graze box.
---@field grazeValue fun(self:Bullet):number Calculates the final graze value.
---@field removeEffect fun(self:Bullet):nil Spawns visual effects upon bullet removal.
---@field changeSpriteColor fun(self:Bullet, color?:string):nil Changes the sprite variant based on a color key.
---@field changeSprite fun(self:Bullet, sprite:Sprite):nil Safely swaps the bullet sprite and handles GIF initialization.
---@overload fun(args:BulletArgs):Bullet
local Bullet = Shape:extend()

---@class BulletArgs:ShapeArgs
---@field size number|nil The scale/zoom factor of the bullet. Default is 1.
---@field sprite Sprite
---@field spriteColor rgbaColor|nil RGBA table for tinting the sprite.
---@field safe boolean|nil If true, the bullet will not damage the player. Default is false.
---@field invincible boolean|nil If true, normal shockwaves won't remove this bullet. Default is false.
---@field damage number|nil Amount of damage dealt to player on hit. Default is 1.
---@field grazed boolean|nil Whether this bullet has already triggered a graze event. Default is false.
---@field baseGrazeValue number|nil The amount added to graze stats. Default is 1.
---@field batch love.SpriteBatch|nil The sprite batch used for standard drawing. Default is BulletBatch or Asset.bulletHighlightBatch if highlight is true.
---@field meshBatch MeshBatch|nil The mesh batch used for complex/deformed drawing. Default is Asset.bigBulletMeshes.
---@field forceQuad boolean|nil If true, forces simple quad drawing even if geometry suggests mesh. Default is false.
---@field forceMesh boolean|nil If true, forces mesh drawing. Default is false.
---@field spriteTransparency number|nil Alpha multiplier (0-1). Default is 1.
---@field extraUpdate ExtraUpdate|function|nil Additional update functions or actions to execute each frame.
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
            self.sprite=copyTable(self.sprite)
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
    self.fromPlayer=false
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

    for _, func in ipairs(self.extraUpdate) do
        if type(func)=='table' and func.isAction and func.init then
            func.init(self, func.params)
        end
    end
    if args.events then
        for _, eventFunc in ipairs(args.events) do
            eventFunc(self, args)
        end
    end
end

function Bullet:draw()
    if not self.sprite then
        return
    end
    local color={1,1,1,1}
    local spriteColor=self.spriteColor
    if spriteColor then
        color=copyTable(spriteColor)
    end
    color[4]=(color[4]or 1)*self.spriteTransparency
    self:drawQuad{
        quad=self.sprite.quad,
        rotation=self.kinematicState.dir+math.pi/2+(self.spriteExtraDirection or 0),
        zoom=self.size,
        normalBatch=(not self.forceMesh)and self.batch or nil,
        meshBatch=(not self.forceQuad)and self.meshBatch or nil,
        color=color,
        isSquare=self.sprite.data.isSquare
    }
end

---@param pos Position
---@param w number
---@param h number
---@param rotation number
---@param quad love.Quad
---@param color rgbaColor|nil
---@param meshBatch MeshBatch
---@param sideNum integer
function Bullet:meshDrawQuad(pos,w,h,rotation,quad,color,meshBatch,sideNum)
    -- inner radius is hitbox radius
    MeshFuncs.ringFanMesh(pos,self:getHitboxRadius(),w,h,rotation,quad,sideNum,color,meshBatch)
end

function Bullet:update(dt)
    self:executeExtraUpdate(dt)
    Shape.update(self,dt)
    if #Effect.Shockwave.objects>0 then self:checkShockwaveRemove() end
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
        if shockwave.canRemove.bullet==true and
        (self.invincible==false or shockwave.canRemove.invincible==true) and
        (self.safe==false or shockwave.canRemove.safe==true) and
        (self.fromPlayer==false or shockwave.canRemove.fromPlayer==true) and
        G.runInfo.geometry:distance(shockwave.kinematicState.pos,self.kinematicState.pos)<shockwave:getHitboxRadius()+selfRadius then
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
    return 1*baseValue
end

function Bullet:removeEffect()
    Effect.Larger{kinematicState=copyTable(self.kinematicState),sprite=Asset.shards.dot,radius=1,growSpeed=0.1,animationFrame=20}
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
        self.sprite=copyTable(self.sprite)
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