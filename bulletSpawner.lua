---@class BulletSpawner:Shape
local BulletSpawner=Shape:extend()

-- a spawner spawns [bulletNumber] or bullets with size=[bulletSize], speed=[bulletSpeed] from angle=[angle] to [angle+range] every [period] frames.
-- all numbers except for [period] can be set to 'a+b' form to mean random.range(a-b,a+b). angle can be 'player' to mean player. (can't use on other params)
-- each function in [bulletEvents] should takes a bullet (circle) and adds event to it.
-- [spawnBatchFunc] and [spawnBulletFunc] can be modified to spawn non-circle pattern bullets (like a line of bullets of different speed or spawn spawners)
function BulletSpawner:new(args)
    BulletSpawner.super.new(self, args)
    self.size=args.size or 0.2
    self.visible=args.visible
    if self.visible==nil then
       self.visible=(self.lifeFrame>60 and true or false)
    end
    self.sprite=BulletSprites.lotus[args.bulletSprite and Asset.spectrum1MapSpectrum2[args.bulletSprite.data.color] or 'gray']
    self.period=args.period or 60
    self.firstPeriod=args.firstPeriod
    self.times=args.times or nil -- if not nil, means spawn [times] times
    self.bulletNumber=args.bulletNumber and math._extractABfromstr(args.bulletNumber) or 10
    self.angle=args.angle and (args.angle=='player' and args.angle or math._extractABfromstr(args.angle)) or 0
    self.range=args.range and math._extractABfromstr(args.range) or math.pi*2
    self.spawnCircleRadius=args.spawnCircleRadius and math._extractABfromstr(args.spawnCircleRadius) or 0
    self.spawnCircleAngle=args.spawnCircleAngle and math._extractABfromstr(args.spawnCircleAngle) or 0
    self.spawnCircleRange=args.spawnCircleRange and math._extractABfromstr(args.spawnCircleRange) or math.pi*2
    self.bulletSpeed=args.bulletSpeed and math._extractABfromstr(args.bulletSpeed) or 20
    self.bulletSize=args.bulletSize and math._extractABfromstr(args.bulletSize) or 1
    self.bulletLifeFrame=args.bulletLifeFrame or 2000
    self.bulletEvents=args.bulletEvents or {}
    self.bulletExtraUpdate=args.bulletExtraUpdate
    self.bulletSprite=args.bulletSprite
    self.bulletBatch=args.bulletBatch or (args.highlight and Asset.bulletHighlightBatch or BulletBatch)
    -- when spawning bullets, spawn a fog that turns into bullet sometime later
    self.fogEffect=args.fogEffect or false
    self.fogTime=args.fogTime or 60
    self.spawnSFXVolume=args.spawnSFXVolume -- nil means default volume set in audio.lua (50%)
    self.spawnTimes=0
    self.spawnBulletFunc=args.spawnBulletFunc or function(self,_args)
        if not _args.lifeFrame then
            _args.lifeFrame=self.bulletLifeFrame
        end
        if not _args.sprite then
            _args.sprite=self.bulletSprite
        end
        _args.kinematicState.dir=math.eval(_args.kinematicState.dir)
        _args.kinematicState.speed=math.eval(_args.kinematicState.speed)
        _args.invincible=_args.invincible or args.invincible or false
        -- if _args.sprite.data.isLaser then
        --     _args.laserEvents=args.laserEvents or {}
        --     _args.bulletEvents=self.bulletEvents
        --     _args.warningFrame=args.warningFrame or 0
        --     _args.fadingFrame=args.fadingFrame or 0
        --     _args.frequency=args.frequency
        --     local cir=Laser(_args)
        --     return
        -- end
        _args.extraUpdate=self.bulletExtraUpdate or {}
        local cir=Bullet(_args)
        -- table.insert(ret,cir)
        for key, func in pairs(self.bulletEvents) do
            func(cir,_args,self)
        end
        return cir
    end
    if self.fogEffect then
        self.spawnBulletFuncRef=self.spawnBulletFunc
        self.spawnBulletFunc=function(self,args)
            self.wrapFogEffect(args,function()
                self.spawnBulletFuncRef(self,args)
            end)
        end
    end
    self.spawnBatchFunc=args.spawnBatchFunc or function(self)
        ---@cast self BulletSpawner
        SFX:play('enemyShot',true,self.spawnSFXVolume)
        local num=math.eval(self.bulletNumber)
        local range=math.eval(self.range)
        local angle=self.angle=='player' and G.runInfo.geometry:to(self.kinematicState.pos,G.runInfo.player.kinematicState.pos) or math.eval(self.angle)
        local spawnCircleAngle=math.eval(self.spawnCircleAngle)
        local spawnCircleRange=math.eval(self.spawnCircleRange)
        local spawnCircleRadius=math.eval(self.spawnCircleRadius)
        local speed=math.eval(self.bulletSpeed)
        local size=math.eval(self.bulletSize)
        for i = 1, num, 1 do
            local direction=range*(i-0.5-num/2)/num+angle
            local pos=G.runInfo.geometry:rThetaGo(self.kinematicState.pos,spawnCircleRadius,spawnCircleRange*(i-0.5-num/2)/num+spawnCircleAngle)
            if spawnCircleRadius~=0 then
                direction=G.runInfo.geometry:to(pos,self.kinematicState.pos)+math.pi+angle
            end
            local kinematicState={pos=pos,dir=direction,speed=speed}
            self:spawnBulletFunc{kinematicState=kinematicState,size=size,index=i,batch=self.bulletBatch,fogTime=self.fogTime,sprite=self.bulletSprite}
        end
    end
    ---@type LoopEvent
    self.spawnEvent=Event.LoopEvent{obj=self,period=self.period,firstPeriod=self.firstPeriod,times=self.times,executeFunc=function(event,dt)
        self.spawnTimes=self.spawnTimes+1
        self:spawnBatchFunc()
    end}
end

function BulletSpawner:update(dt)
    BulletSpawner.super.update(self,dt)
    local selfHitboxRadius=self:getHitboxRadius()
    for k,shockwave in pairs(Effect.Shockwave.objects) do
        ---@cast shockwave Shockwave
        if shockwave.canRemove.bulletSpawner and G.runInfo.geometry:distance(shockwave.kinematicState.pos,self.kinematicState.pos)<shockwave:getHitboxRadius()+selfHitboxRadius then
            self:remove()
        end
    end
end

function BulletSpawner:draw()
    -- local color={love.graphics.getColor()}
    -- love.graphics.setColor(1,0,1)
    -- G.runInfo.geometry:drawCircle(self.x,self.y,self.size)
    -- love.graphics.setColor(color[1],color[2],color[3])
    if self.visible then
        self:drawSprite()
    end
end

---@class fogArgs
---@field fogTime number frames before fog disappears and calls func
---@field sprite Sprite
---@field color string|nil defaults to args.sprite.data.color
---@field kinematicState KinematicState
---@field fogSize number|nil defaults to 1
---@field fogTransparency number|nil transparency of fog, defaults to 1

---@param args fogArgs
---@param func function|nil to be called after fog disappears. defaults to Circle
---@param wrapping boolean|nil if true, will call func(args), otherwise only func() (so you need to wrap it to send args)
function BulletSpawner.wrapFogEffect(args, func, wrapping)
    if not func then
        func,wrapping=Bullet,true
    end
    local color=args.color or (args.sprite and args.sprite.data.color) or 'red'
    local fogTime=args.fogTime or 60
    local pos=copyTable(args.kinematicState.pos)
    local size=args.fogSize or 1
    local fog=Bullet({kinematicState={pos=pos,speed=0,dir=0}, size=size, lifeFrame=fogTime, sprite=Asset.bulletSprites.fog[color],safe=true,spriteTransparency=args.fogTransparency or 1})
    local easeFunc=func
    if wrapping then
        easeFunc=function()func(args)end
    end
    Event.EaseEvent{
        obj=fog,
        duration=fogTime,
        aims={spriteTransparency=0},
        afterFunc=easeFunc
    }
end

function BulletSpawner:drawSprite()
    if not self.sprite then
        return
    end
    self:drawQuad{
        quad=self.sprite.quad,
        rotation=self.time,
        zoom=self.size,
        normalBatch=self.batch,
        meshBatch=Asset.bigBulletMeshes,
        color=self.spriteColor,
    }
end

return BulletSpawner