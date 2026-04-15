---@class Enemy:Shape
---@field maxhp number
---@field hp number
local Enemy=Shape:extend()

function Enemy:new(args)
    Enemy.super.new(self, args)
    self.maxhp=args.maxhp or args.hp or 1000
    self.hp=args.hp or self.maxhp
    self.size=1
    self.hitboxRadius=16
    -- safe means enemy's body (circle) won't hit player, similar to circle.safe
    self.safe=false
    self.sprite=args.sprite
    self.spriteTransparency=args.spriteTransparency or 1
    if self.sprite and self.sprite.is and self.sprite:is(Asset.MovingSprite) then
        self.sprite=shallowCopyTable(self.sprite)
    end
    self.extraUpdate=args.extraUpdate or {}
    if type(self.extraUpdate)=='function' then
        self.extraUpdate={self.extraUpdate}
    end
end

function Enemy:update(dt)
    for k, func in pairs(self.extraUpdate or {}) do
        if type(func)=='function' then
            func(self,dt)
        elseif type(func)=='table' and func.isAction then
            func.func(self,func.params)
        end
    end
    Enemy.super.update(self,dt)
    Bullet.checkHitPlayer(self)
    self:checkHitByPlayer(self.bindedEnemy)
    if self.bindedEnemy then
        self.hp=self.bindedEnemy.hp
        self.damageResistance=self.bindedEnemy.damageResistance
    end
    self.orientation=self:upwardDeltaOrientation()
    self:calculateMovingTransitionSprite()
end

--- make this enemy share hp and transfer damage with otherEnemy
function Enemy:bind(otherEnemy)
    self.bindedEnemy=otherEnemy
    self.maxhp=otherEnemy.maxhp
    self.hp=otherEnemy.hp
end

-- increase enemy's damageResistance by [value] and fade out in [time] frames
-- to prevent player from killing the enemy too quickly
function Enemy:addHPProtection(time,value)
    self.damageResistance=(self.damageResistance or 1)+value
    Event.EaseEvent{
        obj=self,
        easeFrame=time,
        aimTable=self,
        aimKey='damageResistance',
        aimValue=self.damageResistance-value,
    }
end

-- objToReduceHp is to allow familiars to take damage for the enemy
function Enemy:checkHitByPlayer(objToReduceHp,damageFactor)
    objToReduceHp=objToReduceHp or self
    damageFactor=damageFactor or 1
    local damageSum=0
    local selfRadius=self:getHitboxRadius()+32 -- easier to hit. doesn't directly increase hitbox so player can stand above enemy to hit without being hit.
    for key, circ in pairs(PlayerShot.objects) do
        ---@cast circ PlayerShot
        local radius=selfRadius+circ:getHitboxRadius()
        if not circ.safe and G.runInfo.geometry:distance(circ.kinematicState.pos,self.kinematicState.pos)<radius then
            damageSum=damageSum+(circ.damage or 1)
            circ:hitEffect(self)
            -- hit visual effect. at bullet position. pseudo random
            local rand1=math.pseudoRandom(circ.kinematicState.pos,1)
            local speed=5+10*rand1
            local rand2=math.pseudoRandom(circ.kinematicState.pos,2)
            local direction=rand2*math.pi*2
            local kinematicState={pos=copyTable(circ.kinematicState.pos),dir=direction,speed=speed}
            Effect.Larger{kinematicState=kinematicState,sprite=Asset.shards.dot,size=3,growSpeed=0,animationFrame=20,spriteTransparency=0.3}
            -- if self.hp<self.maxhp*0.01 and self.mainEnemy and not self.presaved then
            --     self.presaved=true
            -- end
            EventManager.post(EventManager.EVENTS.PLAYER_BULLET_HIT_ENEMY,circ,self)
        end
    end

    if damageSum==0 then
        return
    end
    SFX:play('damage')
    objToReduceHp.hp=objToReduceHp.hp-damageSum*damageFactor/(objToReduceHp.damageResistance or 1)
    if objToReduceHp.hp<0 and not objToReduceHp.removed then
        objToReduceHp:dieEffect()
    end
end

function Enemy:dieEffect()
    SFX:play('kill',true)
    local spriteColor=self.sprite and self.sprite.data and self.sprite.data.color or 'gray'
    Effect.Larger{kinematicState=self.kinematicState,sprite=BulletSprites.shockwave[spriteColor],size=0,growSpeed=self.size*0.2,animationFrame=10,spriteTransparency=0.8}
    self:remove()
end


function Enemy:calculateMovingTransitionSprite()
    if not self.sprite then
        return
    end
    if self.sprite.is and self.sprite:is(Asset.MovingSprite) then
        local movingDir=math.cos(self.kinematicState.dir-self.orientation+math.pi/2)
        local isLeft=movingDir<-0.5
        local isRight=movingDir>0.5
        self.sprite:countDown(isLeft,isRight)
    end

    if self.sprite.key=='boss'then -- calculate whether enemy is moving left or right relative to player is kinda complex, so just use normal sprites
        local sprites=self.sprite.normal
        local t=self.time
        local index=math.floor(t/0.2)%#sprites+1
        self.currentSprite=sprites[index]
    end
end

-- originally it's designed to calculate to make the sprite upward, how much to rotate the sprite. but it would require an equivalent lua function of shaders used by geometry and feel ugly, currently it just faces player
function Enemy:upwardDeltaOrientation()
    local player=G.runInfo.player
    if not player then
        return 0
    end
    -- local rotateAngle=player.viewDirection
    local selfToPlayer=G.runInfo.geometry:to(self.kinematicState.pos,player.kinematicState.pos)
    -- local playerToSelf=G.runInfo.geometry:to(player.kinematicState.pos,self.kinematicState.pos)
    return selfToPlayer-math.pi/2
end

function Enemy:drawSprite()
    local sprite=self.sprite
    if not sprite then
        return
    end
    local orientation=self.orientation or 0
    if sprite.key=='boss' then
        local kinematicState=self.kinematicState
        local offDistance=math.sin(self.time)*3 -- slightly floating
        local pos,direction=G.runInfo.geometry:rThetaGo(kinematicState.pos,offDistance,orientation+math.pi/2)
        self:drawQuad{
            kinematicState={pos=pos,dir=direction,speed=kinematicState.speed},
            quad=self.currentSprite,
            rotation=orientation,
            zoom=self.size,
            normalBatch=Asset.bossBatch,
            meshBatch=Asset.bossMeshes,
        }
    else
        self:drawQuad{
            quad=self.sprite.quad,
            rotation=orientation,
            zoom=self.size,
            normalBatch=Asset.fairyBatch,
            color={1,1,1,self.spriteTransparency or 1},
            -- meshBatch=Asset.bigBulletMeshes,
        }
    end
end

---@class Boss:Enemy
local Boss=Enemy:extend()
Enemy.hpSegmentsFuncShockwave=function(self,hpLevel,canRemove)
    SFX:play('enemyCharge',true)
    Effect.Shockwave{kinematicState=self.kinematicState,lifeFrame=20,radius=20,growSpeed=1.2,color='yellow',canRemove=canRemove or {bullet=true,invincible=true}}
end

-- parameters: [maxhp], [hp] (defaulted as maxhp), [mainEnemy] if true, killing it wins the scene. [hpSegments] a table of hp levels that triggers special effects. [hpSegmentsFunc] a function that triggers special effects when hp reaches a certain level. note that the hpLevel parameter passed to hpSegmentsFunc is 1-based. (hplevel 1->2 sends 1)
function Boss:new(args)
    args.lifeFrame=99999999
    Boss.super.new(self, args)
    self.size=2
    self.hitboxRadius=32
    self.mainEnemy=true--args.mainEnemy
    self.showCircleHPBar=self.mainEnemy
    self.showHexagram=self.mainEnemy
    -- if self.mainEnemy then
    --     G.mainEnemy=self
    -- end
    -- safe means enemy's body (circle) won't hit player, similar to circle.safe
    self.safe=false
    self.hpBarTransparency=1
    self.hpSegments=args.hpSegments or {} -- draw a small bar marking special hp values. These are only visual effects. If you want a shockwave removing bullets when reaching special values, you need to do it manually.
    table.sort(self.hpSegments,function (a,b) return a>b end) -- we want it decreasing
    self.hpSegmentsFunc=args.hpSegmentsFunc or function(self,hpLevel)end 
    self.damageResistance=1
    self._hpLevel=self:getHPLevel()
    self.sprite=args.sprite
    if not self.sprite then
        self.sprite=Asset.boss.placeholder
    end
    self.bindedEnemy=nil

end

function Boss:update(dt)
    Boss.super.update(self,dt)
    local player=G.runInfo.player
    if player and G.runInfo.geometry:distance(player.kinematicState.pos,self.kinematicState.pos)<50 then
        self.hpBarTransparency=0.85*(self.hpBarTransparency-0.5)+0.5
    else
        self.hpBarTransparency=0.85*(self.hpBarTransparency-1)+1
    end
    local hpLevel=self:getHPLevel()
    if self._hpLevel~=hpLevel then
        self.hpSegmentsFunc(self,self._hpLevel)
        self._hpLevel=hpLevel
    end
end

--- make this enemy share hp and transfer damage with otherEnemy
function Boss:bind(otherEnemy)
    Boss.super.bind(self,otherEnemy)
    self.hpSegments=otherEnemy.hpSegments
    self.showCircleHPBar=otherEnemy.showCircleHPBar
    self.showHexagram=otherEnemy.showHexagram
    if self.mainEnemy then
        error('Enemy:bind: mainEnemy cannot bind with other enemy')
    end
end

-- get the hp level of the enemy. Useful with hpSegments set. e.g. if hpSegments={0.8,0.5,0.2}, getHPLevel() returns 1 if hp/maxhp is in [0.8,1], 2 if in [0.5,0.8), 3 if in [0.2,0.5), 4 if in [0,0.2).
function Boss:getHPLevel()
    local hpp=self.hp/self.maxhp
    for i=1,#self.hpSegments do
        if hpp>=self.hpSegments[i] then
            return i
        end
    end
    return #self.hpSegments+1
end

-- get the ratio of hp in the current level. e.g. if hpSegments={0.8,0.5,0.2}, getHPPercentOfCurrentLevel() returns 0.5 if hp/maxhp is 0.9 (half of the way from 0.8 to 1), 0.65 (half of the way from 0.5 to 0.8), 0.35 (half of the way from 0.2 to 0.5), and 0.1 (half of the way from 0 to 0.2).
function Boss:getHPPercentOfCurrentLevel()
    local hpp=self.hp/self.maxhp
    local hpLevel=self:getHPLevel()
    if hpLevel>#self.hpSegments then
        return hpp/self.hpSegments[hpLevel-1]
    elseif hpLevel==1 then
        return (hpp-self.hpSegments[hpLevel])/(1-self.hpSegments[hpLevel])
    else
        return (hpp-self.hpSegments[hpLevel])/(self.hpSegments[hpLevel-1]-self.hpSegments[hpLevel])
    end
end

function Boss:dieEffect()
    Boss.super.dieEffect(self)
end

function Enemy:draw()
    self:drawSprite()
end

function Boss:draw()
    Boss.super.draw(self)
    if self.showHexagram then
        self:drawHexagram()
    end
    -- if not G.levelIsTimeoutSpellcard and self.showCircleHPBar then
    --     self:drawCircleHPBar()
    -- end
end

function Boss:drawText()
    -- if self.showUpperHPBar and not G.levelIsTimeoutSpellcard then
    --     self:drawUpperHPBar()
    -- end
end

-- an HP bar around enemy (like DDC)
function Boss:drawCircleHPBar()
    local color={love.graphics.getColor()}
    love.graphics.setColor(1,0.3,0.3,self.hpBarTransparency)
    Shape.drawCircle(self.x,self.y,30.5)--inner circle
    Shape.drawCircle(self.x,self.y,32.5)--outer circle
    local ratio=self.hp/self.maxhp
    local yellowRatio=(self.damageResistance or 1)^0.5
    love.graphics.setColor(1,1,1/yellowRatio,self.hpBarTransparency)
    local vertices={}
    local angle0=self.orientation+math.pi*(1.5-2*ratio)
    local num=50
    local X,Y,W,H=love.graphics.getQuadXYWHOnImage(BulletSprites.laser.white.quad,Asset.bulletImage)
    for i=0,num do
        local angle=angle0+i/num*math.pi*2*ratio
        local x1,y1=Shape.rThetaPos(self.x,self.y,30.5,angle)
        local x2,y2=Shape.rThetaPos(self.x,self.y,32.5,angle)
        table.insert(vertices,{x1,y1,X,Y,1,1,1/yellowRatio,self.hpBarTransparency})
        table.insert(vertices,{x2,y2,X+W,Y,1,1,1/yellowRatio,self.hpBarTransparency})
    end
    if not self.circleHPBarMesh then
        self.circleHPBarMesh=love.graphics.newMesh(vertices,'strip')
        self.circleHPBarMesh:setTexture(Asset.bulletImage)
    else
        self.circleHPBarMesh:setVertices(vertices)
    end
    Asset.bossEffectMeshes:add(self.circleHPBarMesh)
    -- love.graphics.setColor(1,0.3,0.3,self.hpBarTransparency)
    for i,ratio in pairs(self.hpSegments) do
        local rin,rout=29.5,33.5
        local x1,y1=Shape.rThetaPos(self.x,self.y,rin,self.orientation+math.pi*(1.5-2*ratio))
        local x2,y2=Shape.rThetaPos(self.x,self.y,rout,self.orientation+math.pi*(1.5-2*ratio))
        Shape.drawSegment(x1,y1,x2,y2)
    end
    -- SetFont(12)
    -- love.graphics.print(""..ratio..', ', 10, 100)
    love.graphics.setColor(color[1],color[2],color[3])
end

-- an HP bar at top of screen (like UFO)
function Boss:drawUpperHPBar()
    local color={love.graphics.getColor()}
    local ratio=self.hp/self.maxhp
    local yellowRatio=(self.damageResistance or 1)^0.5
    local beginX=5
    local width=490
    local last=0
    local num=#self.hpSegments
    local hpLevel=self:getHPLevel()
    for i=num,hpLevel,-1 do -- increasing order of hpSegments. hpLevel is the last full part of the bar and drawn as grey
        local ratio=self.hpSegments[i]
        love.graphics.setColor(0.5,0.5,0.5,0.7)
        love.graphics.rectangle('fill',beginX+width*last,1,width*(ratio-last),3)
        last=ratio
        love.graphics.setColor(1,0.3,0.3,1)
        love.graphics.rectangle('fill',beginX+width*ratio,0,3,5) -- a red mark on segment point
    end
    love.graphics.setColor(1,1,1/yellowRatio,0.7)
    love.graphics.rectangle('fill',beginX+width*last,1,width*(ratio-last),3)
    love.graphics.setColor(color[1],color[2],color[3])
end

-- due to hyperbolic geometry, it's not feasible to prepare an image for rotating hexagram
function Boss:drawHexagram()
    local width=5
    local selfPos=self.kinematicState.pos
    local hexagramPoints={}
    local hexagramSize=150
    for i=1,6 do
        local angle=math.pi/3*(i-1)+self.time*6/5
        local pos=G.runInfo.geometry:rThetaGo(selfPos,hexagramSize,angle)
        table.insert(hexagramPoints,pos)
    end
    local triangles={
        {hexagramPoints[1],hexagramPoints[3],hexagramPoints[5],hexagramPoints[1]},
        {hexagramPoints[2],hexagramPoints[4],hexagramPoints[6],hexagramPoints[2]}
    }
    for _,triangle in ipairs(triangles) do
        MeshFuncs.polylineMesh(triangle,width,BulletSprites.laser.red.quad,{1,0.5,0.5,0.8},nil,10,Asset.bossEffectMeshes)
    end
    local ringWidth=30
    MeshFuncs.ringMesh(selfPos,hexagramSize,hexagramSize+ringWidth,self.time*6/5,BulletSprites.laserDark.red.quad,48,{1,0.5,0.5,0.8},nil,Asset.bossEffectMeshes)
end
Enemy.Boss=Boss
return Enemy