
---@class Effect:Shape
local Effect = Shape:extend()

function Effect:new(args)
    Effect.super.new(self, args)
end

-- something keep growing and reducing opacity. if the kinematicState has speed and is not sharing with other object, need to set shareKinematicState=false.
---@class Larger:Effect
local Larger=Effect:extend()
Effect.Larger=Larger
function Larger:new(args)
    -- if share kinematicState (sent fairy.kinematicState), won't call Shape.update. if not, will copy the kinematicState and call Shape.update (when the kinematicState has speed and wants it to move)
    self.shareKinematicState=args.shareKinematicState
    if self.shareKinematicState==nil then
        self.shareKinematicState=true
    end
    if not self.shareKinematicState then
        args.kinematicState=copyTable(args.kinematicState)
    end
    Larger.super.new(self, args)
    ---@type Sprite
    self.sprite=args.sprite
    if not self.sprite then
        error('Larger.new: self.sprite is nil. args='..pprint(args))
    end
    if not self.sprite.data then
        error('Larger.new: self.sprite.data is nil. sprite='..pprint(self.sprite))
    end
    self.size = args.size or 1
    self.growSpeed=args.growSpeed or 1.2
    self.animationFrame=args.animationFrame or 30
    self.spriteTransparency=args.spriteTransparency or 1
    self.batch=Asset.effectBatch
    self.meshBatch=Asset.bigBulletMeshes
end

function Larger:update(dt)
    if self.shareKinematicState then
        self.frame=self.frame+1 --Larger could share same kinamaticState with some fairy or bullet. do not call Shape.update or the speed is multiplied. why I find this bug only after 6 months of development
    else
        Larger.super.update(self,dt)
    end
    self.size=self.size+self.growSpeed
    if self.frame==self.animationFrame then
        self:remove()
    end
end

Larger.meshDrawQuad=Bullet.meshDrawQuad
Larger.getHitboxRadius=Bullet.getHitboxRadius

function Larger:draw()
    Bullet.draw(self)
end

-- A growing shockwave, that removes touched bullets and activate their :removeEffect. can change to other effect by setting effectFunc(Shockwave, Bullet)
---@class Shockwave:Larger
local Shockwave=Larger:extend()
Effect.Shockwave=Shockwave
function Shockwave:new(args)
    self.color=args.color or 'red'
    args.sprite=args.sprite or Asset.bulletSprites.shockwave[self.color] or Asset.bulletSprites.shockwave.red
    Shockwave.super.new(self, args)
    self.canRemove=args.canRemove or {bullet=true,invincible=false,safe=true}
    self.effectFunc=args.effectFunc -- default is in bullet class
end

function Shockwave:update(dt)
    Shockwave.super.update(self,dt)
end

-- generating black smoke, boding a huge attack
---@class Charge:Effect
---@field obj Shape
local Charge=Effect:extend()
Effect.Charge=Charge
function Charge:new(args)
    Charge.super.new(self, args)
    self.obj=args.obj or self
    self.sprite=args.sprite or Asset.shards.round
    self.size = args.size or 1
    self.particleSpeed=args.particleSpeed or 300
    self.particleFrame=args.particleFrame or 40
    self.particleSize=args.particleSize or 5
    self.particles={}
    self.animationFrame=args.animationFrame or 120
    self.color=args.color or {1,1,1}
    SFX:play("enemyCharge")
end

function Charge:update(dt)
    self.frame=self.frame+1
    local direction=math.pseudoRandom(self.frame)*999
    if self.frame+self.particleFrame<self.animationFrame then
        local pos,dir2=G.runInfo.geometry:rThetaGo(self.obj.kinematicState.pos,100,direction)
        table.insert(self.particles,{frame=0,kinematicState={pos=pos,dir=dir2+math.pi,speed=self.particleSpeed}})
    end
    for k,particle in pairs(self.particles) do
        particle.frame=particle.frame+1
        if particle.frame>=self.particleFrame then
            goto continue
        end
        G.runInfo.geometry:update(particle.kinematicState,dt)
        particle.kinematicState.speed=particle.kinematicState.speed*0.95
        ::continue::
    end
    if self.frame==self.animationFrame then
        self:remove()
    end
end

function Charge:draw(dt)
    for k,particle in pairs(self.particles) do
        if particle.frame>=self.particleFrame then
            goto continue
        end
        self:drawQuad{
            kinematicState=particle.kinematicState,
            quad=self.sprite.quad,
            rotation=particle.kinematicState.dir,zoom=self.size,
            normalBatch=Asset.effectBatch,meshBatch=Asset.bigBulletMeshes,
            color={self.color[1],self.color[2],self.color[3],1-0.3*particle.frame/self.particleFrame}
        }
        ::continue::
    end
end

return Effect