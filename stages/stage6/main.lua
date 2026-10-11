---@type OneStageDataRaw
return{
    init=function(stageKey)
        -- G:replaceBackgroundPatternIfNot(BackgroundPattern.SphericalGrid)
        StageManager.commonStageInit(stageKey)
    end,
    segments={
        {
            key='6-1',
            type='midStage',
            func=function() -- 20s
                local geo=G.runInfo.geometry
                local player=G.runInfo.player
                local sign=math.randomSign()
                local extraUpdate2={Action.FadeOut(10,true),Action.Trail(12,4),function(self)
                    local t=math.sin(self.frame/5)*0.2+0.6
                    self.spriteColor={1,t,t,1}
                end}
                local function swirl(self)
                    SFX:play('enemyPowerfulShot')
                    local dir0=geo:to(self.kinematicState.pos,player.kinematicState.pos)
                    local period=5
                    BulletSpawner{kinematicState={pos=copyTable(self.kinematicState.pos),dir=self.kinematicState.dir,speed=self.kinematicState.speed},lifeFrame=240,bulletSize=2,firstPeriod=1,period=period,bulletNumber=15,range=math.pi,angle=dir0,bulletSprite=BulletSprites.scaleDark.white,bulletSpeed=100,bulletLifeFrame=360,bulletExtraUpdate={Action.FadeOut(10,true),function(self)
                        if self.any then
                            if self.frame==math.ceil(self.lifeFrame/2) then
                                self.kinematicState.dir=geo:to(self.kinematicState.pos,player.kinematicState.pos)
                                self.lifeFrame=self.frame+180
                                self.kinematicState.speed=200
                                self.extraUpdate=extraUpdate2
                                SFX:play('enemyShot')
                                return
                            end
                        end
                        self.kinematicState.dir=self.kinematicState.dir+math.pi/self.lifeFrame*sign
                    end},bulletEvents={function (cir,args,self)
                        local index=args.index
                        if index==1 then
                            self.angle=self.angle-math.pi/24*period/10*sign
                            self.bulletSpeed=self.bulletSpeed+period*2
                            self.bulletLifeFrame=self.bulletLifeFrame-period
                        end
                        if (index-self.spawnTimes%2)%self.bulletNumber==0 and DIFF()>G.LUNATIC then -- it's too complex for lunatic so leave for overdrive lol
                            cir.any=true
                        end
                    end}}
                end
                local function dieEffect(self)
                    local n=80
                    ---@cast geo Spherical
                    local antipode=geo:rThetaGo(self.kinematicState.pos,geo.radius*math.pi,0)
                    -- warning
                    Bullet{kinematicState={pos=antipode,dir=0,speed=0},safe=true,highlight=true,sprite=BulletSprites.cross.red,spriteColor={1,0.2,0.2,1},extraUpdate={Action.FadeIn(20,false),Action.ZoomIn(20,1,2,true),Action.FadeOut(20,false)},lifeFrame=690*60/200,size=4}
                    BulletSpawner{kinematicState={pos=copyTable(self.kinematicState.pos),dir=0,speed=0},spawnSFX='enemyShot2',lifeFrame=3,firstPeriod=1,period=9,bulletNumber=n,range=math.pi*2*n/DSWITCH{3,5,7.1,5^0.5},angle='player',bulletSprite=BulletSprites.bigStar.white,bulletSpeed=200,bulletLifeFrame=360,bulletExtraUpdate={Action.ZoomIn(10),Action.FadeOut(10,true),},bulletEvents={function (cir,args,self)
                        local index=args.index
                        if index%2==0 then
                            cir:changeSpriteColor('black')
                        end
                        cir.kinematicState.speed=cir.kinematicState.speed+index*3
                        cir.size=0.8+index/n
                        cir.spriteRotationSpeed=0.08
                        cir.lifeFrame=690*60/cir.kinematicState.speed+10
                        cir.spriteColor={0.8,0.8,1,1}
                    end}}
                end
                local function spawnFairy(pos,dir,speed)
                    local fairy=Enemy{kinematicState=copyTable{pos=pos,dir=dir or 0,speed=speed or 0},maxhp=20,sprite=Asset.fairySprites.large.black,lifeFrame=300,extraUpdate={Enemy.presetActions.fadeAndHint,Action.Finale(20)},dropItems={powerSmall=10,point=5},extraDieEffects={dieEffect}}
                    fairy:addHPProtection(180,99)
                    swirl(fairy)
                end
                local init=geo:init()
                local pos1,dir1=geo:rThetaGo(player.kinematicState.pos,300,player.viewDirection-math.pi/2)
                spawnFairy(pos1)
                wait(300)
                pos1,dir1=geo:rThetaGo(player.kinematicState.pos,300,player.viewDirection-math.pi/2)
                spawnFairy(pos1,math.eval(dir1,1.5),100)
                wait(300)
                pos1,dir1=geo:rThetaGo(player.kinematicState.pos,300,player.viewDirection-math.pi/2)
                spawnFairy(pos1,math.eval(dir1,1.5),150)
                wait(300)
                DynamicUIObjs.showStageTitle('stage6')
                wait(300)
            end
        },
        {
            key='6-2',
            type='midStage',
            func=function() --21s
                local geo=G.runInfo.geometry
                ---@cast geo Spherical
                local radius=geo.radius
                ---@cast geo GeometryBase
                local player=G.runInfo.player
                local sentry=DanmakuFuncs.sentry()
                local fairyDie=false
                local fairyExtraUpdate=function(self)
                    local t=math.max(self.frame-0,0)
                    self.kinematicState.pos,self.kinematicState.dir=geo:rThetaGo(self.any.pos,t*2,self.any.dir+t/120)
                    self.kinematicState.dir=self.kinematicState.dir+t/100
                    if fairyDie then
                        self:addHPProtection(60,999)
                    end
                end
                local ringBulletExtraUpdate=function(self)
                    local t=120
                    if self.frame>t-10 and self.frame<=t+10 then
                        self.size=math.abs(self.frame-t)/10
                    end
                    if self.frame==t then
                        SFX:play('enemyShot2')
                        self.spriteColor={1,1,1,1}
                        self.safe=false
                    end
                    if self.frame==self.any.trigger then
                        self:changeSpriteColor('red')
                        local toPlayer=geo:to(self.kinematicState.pos,player.kinematicState.pos)
                        local sign=math.sign(math.modClamp(toPlayer,self.kinematicState.dir)-self.kinematicState.dir)
                        local dir=self.kinematicState.dir+math.pi/2*sign
                        local aim=geo:rThetaGo(self.kinematicState.pos,radius*math.pi/2,dir)
                        self.any.aim=aim
                        self.kinematicState.speed=self.kinematicState.speed*(1+self.any.layer*0.2)
                    end
                    if self.any and self.any.aim then
                        local toAim=geo:to(self.kinematicState.pos,self.any.aim)
                        toAim=math.modClamp(toAim,self.kinematicState.dir)
                        self.kinematicState.dir=math.lerp(self.kinematicState.dir,toAim,0.01)
                    end
                end
                local function ring(pos,sign,n)
                    SFX:play('enemyShot3')
                    local layers=4
                    n=n or 20
                    local dir=geo:to(pos,player.kinematicState.pos)
                    local bulletSprite='giant'
                    if DIFF()==G.EASY then
                        bulletSprite='round'
                    elseif DIFF()==G.NORMAL then
                        bulletSprite='bigRound'
                    end
                    for i=1,n do
                        local layer=(-i*sign)%layers
                        local d=radius*math.pi*2/n*i
                        local posi,diri=geo:rThetaGo(pos,d,dir)
                        local bullet=Bullet{kinematicState={pos=posi,dir=diri+(sign<0 and math.pi or 0),speed=200},lifeFrame=360,safe=true,sprite=BulletSprites[bulletSprite].blue,highlight=true,extraUpdate={Action.FadeIn(30,false),Action.ZoomOut(20),ringBulletExtraUpdate},spriteColor={1,0.3,0.3,1},forceQuad=true}
                        bullet.any={layer=layer,trigger=160+20*sign}
                    end
                end
                local function spawnFairy(pos,dir)
                    local speed=400
                    local fairy=Enemy{kinematicState=copyTable{pos=pos,dir=dir or 0,speed=0},maxhp=20,sprite=Asset.fairySprites.large.white,lifeFrame=900,extraUpdate={Enemy.presetActions.fadeAndHint,fairyExtraUpdate},dropItems={powerSmall=10,point=DSWITCH{0,1,3,5}},extraDieEffects={function(self)
                        fairyDie=true
                        Event{obj=sentry,action=function ()
                            wait()
                            fairyDie=false
                        end}
                        local n=20
                        if DIFF()==G.LUNATIC then
                            n=12
                            ring(self.kinematicState.pos,-1,n)
                        end
                        ring(self.kinematicState.pos,1,n)
                    end}}
                    fairy:addHPProtection(360,999)
                    fairy.any={pos=pos,dir=dir}
                    BulletSpawner{bulletNumber=3,period=4,lifeFrame=999,bulletSprite=BulletSprites.scale.white,bulletLifeFrame=radius*math.pi*60/speed+10,range=math.pi/12,angle=math.pi,useRelativeAngle=true,bulletSpeed=speed,bulletExtraUpdate={Action.ZoomIn(10),Action.FadeOut(10,true),},bulletSize=2}:bindState(fairy)
                end
                local pos1,dir1=geo:rThetaGo(player.kinematicState.pos,radius*math.pi/2,player.viewDirection-math.pi/2)
                local n=7
                for i=1,n do
                    spawnFairy(pos1,dir1+math.pi/2+math.pi*2/n*i)
                    wait(30)
                end
                wait(1050)
            end
        },
        {
            key='6-3',
            type='midStage',
            func=function() --21s
                local geo=G.runInfo.geometry
                ---@cast geo Spherical
                local radius=geo.radius
                local quarter=radius*math.pi/2
                ---@cast geo GeometryBase
                local player=G.runInfo.player
                local fairyN=20
                local sentry=DanmakuFuncs.sentry()
                local fairyDie=false
                local function fairyExtraUpdate(self)
                    self.kinematicState.pos,self.kinematicState.dir=geo:rThetaGo(player.kinematicState.pos,quarter,self.any.angle+player.viewDirection+math.sin(sentry.frame/300)*9)
                    if fairyDie then
                        self:addHPProtection(20,999)
                    end
                end
                for i=1,fairyN do
                    local angle=math.pi*2/fairyN*(i*9%fairyN)
                    local pos=geo:rThetaGo(player.kinematicState.pos,quarter,angle)
                    local fairy=Enemy{kinematicState=copyTable{pos=pos,dir=0,speed=0},maxhp=50,sprite=Asset.fairySprites.small.white,lifeFrame=900,extraUpdate={Enemy.presetActions.fadeAndHint,fairyExtraUpdate},dropItems={powerSmall=3},extraDieEffects={function(self)
                        fairyDie=true
                        Event{obj=sentry,action=function ()
                            wait()
                            fairyDie=false
                        end}
                    end}}
                    fairy:addHPProtection(120,99)
                    fairy.any={angle=angle}
                    local speed=150
                    local spawner=BulletSpawner{bulletNumber=3,period=60,lifeFrame=999,bulletSprite=BulletSprites.scale.white,bulletLifeFrame=quarter*60/speed+10,range=math.pi/24,angle=math.pi,useRelativeAngle=true,bulletSpeed=speed,bulletExtraUpdate={Action.ZoomIn(10),Action.FadeOut(10,true),},bulletSize=2}
                    spawner:bindState(fairy)
                    Event.LoopEvent{obj=spawner,period=60,executeFunc=function ()
                        spawner.range=spawner.range+math.pi/12
                    end}
                    wait(3)
                end
                wait(1200)
            end
        },
        require("stages.stage6.enri")
    }
}