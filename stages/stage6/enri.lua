local function spawnFog(fogData,fogCenter,speed,fogn)
    fogn=fogn or 50
    speed=speed or 250
    fogData.fogCenter=copyTable(fogCenter)
    fogData.fogRadius=0
    fogData.signal=true
    local geo=G.runInfo.geometry
    ---@cast geo Spherical
    local radius=geo.radius
    ---@cast geo GeometryBase
    local time=radius*math.pi*60/speed
    local playerAngle=geo:to(fogCenter,G.runInfo.player.kinematicState.pos)
    for i=1,fogn do
        local angle=math.pi*2*Event.sineIOProgressFunc(i/fogn)+playerAngle -- more fog at player
        local speedi=speed*math.eval(1,0.3)
        local bullet=Bullet{kinematicState={pos=copyTable(fogCenter),dir=angle,speed=speedi},sprite=BulletSprites.darkLotus.gray,highlight=true,size=math.eval(2.5,1),lifeFrame=time*speed/speedi,extraUpdate={Action.ZoomIn(20),Action.ZoomOut(20)},safe=true,forceQuad=true,invincible=true,spriteTransparency=0.7}
        bullet.spriteRotationSpeed=math.eval(0,0.07)
    end
    local sentry=DanmakuFuncs.sentry()
    Event.LoopEvent{obj=sentry,period=1,times=math.ceil(time),executeFunc=function (self,times)
        fogData.fogRadius=speed*times/60
    end,afterFunc=function ()
        fogData.signal=false
    end}
end
local function getBossSpawnPos(self)
    local geo=G.runInfo.geometry
    local playerPos=G.runInfo.player.kinematicState.pos
    local pos,dir=geo:rThetaGo(playerPos,220*math.pi/2,G.runInfo.player.viewDirection-math.pi/2)
    return pos
end
local boss=BossManager.BossSegment{
    bossName='enri',
    key='6-boss',
    BGM='level6b',
    getBossSpawnPos=getBossSpawnPos,
    bossSpawnCallback=function (self, boss)
        -- easier to hit. surprisingly, it's more difficult to hit the stage 6 boss though the space converges
        boss.extraHitRadius=64
    end,
    -- beforeDialogueKey=function ()
    --     return G.runInfo.playerType..'S6BossBefore'
    -- end,
    -- afterDialogueKey=function ()
    --     return G.runInfo.playerType..'S6BossAfter'
    -- end,
    rounds={
        BossManager.BossRound{phases={
            BossManager.NonSpellPhase{
                key='6-boss-enri-non-1',
                time=1800,
                hp=4000,
                func=function(self, boss)
                    local geo=G.runInfo.geometry
                    ---@cast geo Spherical
                    local radius=geo.radius
                    ---@cast geo GeometryBase
                    local fogData={}
                    local player=G.runInfo.player
                    local coreExtraUpdate={Action.ZoomIn(20),Action.FadeIn(20,true),Action.FadeOut(20,true),function(self)
                        if fogData.signal and not self.flag and self.frame%5==0 and math.abs(fogData.fogRadius-geo:distance(fogData.fogCenter,self.kinematicState.pos))<25 then
                            self:changeSpriteColor('white')
                            self.flag=true
                            self.kinematicState.speed=0
                            self.kinematicState.dir=geo:to(self.kinematicState.pos,player.kinematicState.pos)
                        end
                        if not self.flag then
                            self.kinematicState.speed=self.kinematicState.speed*0.995
                        else
                            self.kinematicState.speed=math.lerp(self.kinematicState.speed,100,0.01)
                        end
                    end}
                    local petalExtraUpdate={Action.ZoomIn(20),Action.FadeIn(20,true),Action.FadeOut(20,true),function(self)
                        local t=self.frame
                        if fogData.signal and not self.flag and t%5==0 and math.abs(fogData.fogRadius-geo:distance(fogData.fogCenter,self.kinematicState.pos))<25 then
                            self:changeSpriteColor('white')
                            self.flag=true
                            self.kinematicState.speed=50
                            local pos1=boss.kinematicState.pos
                            local pos2=geo:rThetaGo(pos1,radius*math.pi,0)
                            local aim=pos1
                            local distance=geo:distance(self.kinematicState.pos,pos1)
                            local distance2=geo:distance(self.kinematicState.pos,pos2)
                            if distance2>distance then
                                aim=pos2
                            end
                            self.any.aim=aim
                        end
                        if not self.flag then
                            local r,angle,core=self.any.r,self.any.angle,self.any.core
                            if core.flag then
                                return
                            end
                            r=r*(1-math.exp(-t/30))
                            angle=angle+t/60+core.kinematicState.dir
                            self.kinematicState.pos,self.kinematicState.dir=geo:rThetaGo(core.kinematicState.pos,r,angle)
                        elseif not self.flag2 then
                            local aim=self.any.aim
                            local distance=geo:distance(self.kinematicState.pos,aim)
                            local to=geo:to(self.kinematicState.pos,aim)
                            to=math.modClamp(to,self.kinematicState.dir)
                            self.kinematicState.speed=math.lerp(self.kinematicState.speed,math.clamp(9000/distance,100,300),0.01)
                            self.kinematicState.dir=math.lerp(self.kinematicState.dir,to,0.02)
                            if distance<30 then
                                self.lifeFrame=self.frame+10
                                self.flag2=true
                            end
                        end
                    end}
                    local function flower(pos,dir,speed)
                        SFX:play('enemyShot')
                        local core=Bullet{kinematicState={pos=copyTable(pos),dir=dir,speed=speed},sprite=BulletSprites.round.yellow,lifeFrame=600,extraUpdate=coreExtraUpdate,highlight=true}
                        local n=DSWITCH{4,4,4,5}
                        for i=1,n do
                            local angle=i/n*math.pi*2
                            local petal=Bullet{sprite=BulletSprites.egg.red,lifeFrame=600,extraUpdate=petalExtraUpdate,highlight=true}
                            petal.any={core=core,r=20,angle=angle}
                        end
                    end
                    local sentry=DanmakuFuncs.sentry()
                    local function wave()
                        local pos=boss.kinematicState.pos
                        local angle0=math.eval(0,99)
                        local n=DSWITCH{25,30,35,40}
                        Event{obj=sentry,action=function ()
                            for i=1,n do
                                local angle=math.pi*2/n*(i)
                                local r,angle2=math.polygonize(5,angle)
                                local posi=geo:rThetaGo(pos,r*100,angle2+angle0)
                                flower(posi,angle+angle0,(r-0.8)*1200)
                                SFX:play('enemyShot')
                                wait(3)
                            end
                            SFX:play('enemyCharge')
                            wait(60)
                            SFX:play('enemyPowerfulShot')
                            spawnFog(fogData,boss.kinematicState.pos)
                        end}
                    end
                    for i=1,8 do
                        wave()
                        wait(500)
                    end
                end
            },
            require('stages.stage6.spellcards.military'),
        }},
        BossManager.BossRound{phases={
            BossManager.NonSpellPhase{
                key='6-boss-enri-non-2',
                time=1800,
                hp=4000,
                func=function (self, boss)
                    local geo=G.runInfo.geometry
                    ---@cast geo Spherical
                    local radius=geo.radius
                    ---@cast geo GeometryBase
                    local fogData={}
                    wait(120)
                    local function webUpdate(self)
                        if self.frame<80 then
                            self.kinematicState.speed=self.kinematicState.speed*0.98
                            self.kinematicState.dir=self.kinematicState.dir+self.any.sign*0.01
                            return
                        elseif self.frame==80 then
                            self:changeSprite(BulletSprites.note[self.sprite.data.color])
                            self.size=1
                            self.kinematicState.dir=self.kinematicState.dir+self.any.sign*(math.pi/2-self.any.index*0.02)+(self.any.index2)*math.pi*0.7
                        elseif self.frame<140 and not self.flag then
                            self.kinematicState.speed=self.kinematicState.speed+4+DSWITCH{-0.3,-0.2,-0.1,0}
                            self.kinematicState.dir=self.kinematicState.dir+math.eval(0,DSWITCH{0,0.02,0.02,0.02})
                        end
                        local t=self.frame
                        if fogData.signal and not self.flag and t%5==0 and math.abs(fogData.fogRadius-geo:distance(fogData.fogCenter,self.kinematicState.pos))<25 then
                            self:changeSpriteColor('white')
                            self.flag=true
                            self.kinematicState.speed=50
                            local pos1=boss.kinematicState.pos
                            local pos2=geo:rThetaGo(pos1,radius*math.pi,0)
                            local aim=pos1
                            local distance=geo:distance(self.kinematicState.pos,pos1)
                            local distance2=geo:distance(self.kinematicState.pos,pos2)
                            if distance2>distance then
                                aim=pos2
                            end
                            self.any.aim=aim
                        end
                        if self.flag and not self.flag2 then
                            local aim=self.any.aim
                            local distance=geo:distance(self.kinematicState.pos,aim)
                            local to=geo:to(self.kinematicState.pos,aim)
                            to=math.modClamp(to,self.kinematicState.dir)
                            self.kinematicState.speed=math.lerp(self.kinematicState.speed,math.clamp(90000/distance,100,600),0.03)
                            self.kinematicState.dir=math.lerp(self.kinematicState.dir,to,0.04)
                            if distance<50 then
                                self.lifeFrame=self.frame+10
                                self.flag2=true
                                self.kinematicState.speed=self.kinematicState.speed*0.3
                            end
                        end
                    end
                    local colors={'green','purple','red','yellow'}
                    local function web(dir,sign)
                        local n=5
                        local gap=50
                        for i=1,n do
                            local d1=gap*(i-0.5-n/2)
                            local pos1,dir1=geo:rThetaGo(boss.kinematicState.pos,d1,dir-math.pi/2)
                            dir1=dir1+math.pi/2
                            BulletSpawner{kinematicState={pos=pos1,dir=0,speed=0},angle=dir1,bulletNumber=1,lifeFrame=240,period=DSWITCH{8,4,4,4},highlight=true,bulletSprite=BulletSprites.stick[colors[(DIFF()-1)%#colors+1]],bulletSize=2,bulletLifeFrame=600,bulletSpeed=400,bulletExtraUpdate={Action.ZoomIn(20),Action.FadeOut(20,true),webUpdate},bulletEvents={function (cir,args,self)
                                cir.any={sign=sign,index=self.spawnTimes,index2=(i-0.5-n/2)/n}
                                cir.forceQuad=true
                            end}}
                        end
                    end
                    local sentry=DanmakuFuncs.sentry()
                    for i=1,8 do
                        local sign=math.mod2Sign(i)
                        web(geo:to(boss.kinematicState.pos,G.runInfo.player.kinematicState.pos)-sign*math.pi*DSWITCH{0.5,0.55,0.6,0.65},sign)
                        wait(240)
                        SFX:play('enemyCharge')
                        wait(60)
                        SFX:play('enemyPowerfulShot')
                        spawnFog(fogData,boss.kinematicState.pos,nil,40)
                        if i==1 and DIFF()>=G.HARD then
                            local n=DSWITCH{5,5,5,10}
                            Event.LoopEvent{obj=sentry,period=120,firstPeriod=1,executeFunc=function (self,times)
                                SFX:play('enemyShot2')
                                local speed=100
                                local spawner=BulletSpawner{kinematicState={pos=copyTable(boss.kinematicState.pos),dir=0,speed=0},angle=geo:to(boss.kinematicState.pos,G.runInfo.player.kinematicState.pos),bulletNumber=100,period=3,firstPeriod=1,lifeFrame=2,bulletSprite=BulletSprites.rest.blue,bulletSpeed=speed,bulletLifeFrame=200,bulletExtraUpdate={Action.ZoomIn(20),Action.FadeOut(20,true),function(self)
                                    if self.frame>60 then
                                        self.kinematicState.speed=self.kinematicState.speed+1+self.ratio
                                    end
                                end},bulletEvents={function (cir,args,self)
                                    cir.ratio=(-math.mod2Sign(times)*args.index%n)/n
                                end}}
                            end}
                        end
                        wait(60)
                    end
                end
            },
            require('stages.stage6.spellcards.wind'),
        }},
        BossManager.BossRound{phases={
            BossManager.NonSpellPhase{
                key='6-boss-enri-non-3',
                time=1800,
                hp=4000,
                func=function (self, boss)
                    local geo=G.runInfo.geometry
                    ---@cast geo Spherical
                    local radius=geo.radius
                    ---@cast geo GeometryBase
                    local fogData={}
                    wait(60)
                    local potShapeExtraUpdate={Action.FadeIn(20,true),Action.FadeOut(20,true),function (self)
                        local t=self.frame
                        if not self.flag and self.frame>=150 then
                            if self.frame%30==0 then
                                self:changeSpriteColor('magenta')
                            elseif self.frame%30==10 then
                                self:changeSpriteColor('yellow')
                            end
                            if self.frame%30>=10 then
                                self.spriteColor={1,(self.frame%30-10)/19,1,1}
                            end
                        end
                        if self.any.sentry.flag and not self.flag then
                            self:changeSpriteColor('white')
                            self.spriteColor={1,1,1,1}
                            self.flag=true
                            if DIFF()<=G.EASY then
                                self.lifeFrame=self.frame+20
                            else
                                self.kinematicState.speed=200
                            end
                        end
                    end}
                    local function pot(dir,i)
                        SFX:play('enemyPowerfulShot')
                        local sentry=DanmakuFuncs.sentry(boss.kinematicState.pos)
                        sentry.kinematicState.dir=dir
                        sentry.extraUpdate={function (self)
                            local t=self.frame
                            if fogData.signal and not self.flag and t%5==0 and math.abs(fogData.fogRadius-geo:distance(fogData.fogCenter,self.kinematicState.pos))<25 then
                                self.flag=true
                                self.any=true
                                self.lifeFrame=self.frame+20
                            end
                        end}
                        Event{obj=sentry,action=function ()
                            Event.EaseEvent{obj=sentry,easeObj=sentry.kinematicState,aims={speed=100},duration=120}
                            wait(120)
                            local group,num=5,DSWITCH{5,10,10,15}
                            local spawner=BulletSpawner{lifeFrame=600,period=30,bulletNumber=num,range=math.pi*2*num/group,bulletSprite=BulletSprites.flame.magenta,highlight=true,bulletSpeed=i==1 and 180 or 230,bulletLifeFrame=480,bulletExtraUpdate={Action.ZoomIn(20,1,3,true),Action.FadeOut(20,true),function(self)
                                if not self.flag then
                                    self.kinematicState.speed=math.clamp(self.kinematicState.speed,380,0.01)
                                end
                                local t=self.frame
                                if fogData.signal and not self.flag and t%3==0 and math.abs(fogData.fogRadius-geo:distance(fogData.fogCenter,self.kinematicState.pos))<25 then
                                    self:changeSpriteColor('white')
                                    self.flag=true
                                    self.kinematicState.speed=0
                                end
                            end},angle='player'--[[math.eval(0,math.pi)]],bulletEvents={function (cir,args,self)
                                cir.forceQuad=true
                                if num==10 then
                                    cir.kinematicState.dir=cir.kinematicState.dir+math.pi/5
                                end
                                local groupIndex=math.ceil((args.index-group)/group)
                                cir.kinematicState.speed=cir.kinematicState.speed+40*groupIndex
                                cir.zoomInTargetSize=1+(num/group-1-groupIndex)*0.4
                                cir.size=cir.size*cir.zoomInTargetSize
                                cir.zoomInInitialSize=cir.size
                            end}}
                            spawner:bindState(sentry)
                            Event.LoopEvent{obj=spawner,period=1,executeFunc=function ()
                                if sentry.any then
                                    spawner:remove()
                                end
                            end}
                        end}
                        -- yellow circle
                        local r1=50
                        for i=1,18 do
                            local angle=math.pi*2/18*i
                            local bullet=Bullet{lifeFrame=600,sprite=BulletSprites.lightRound.yellow,extraUpdate=copyTable(potShapeExtraUpdate),highlight=true,invincible=true,size=i%2==0 and 1 or 0.8}
                            bullet.any={angle=angle,sentry=sentry}
                            DanmakuFuncs.orbitBind(bullet,sentry,function (self, centerObj)
                                local t=self.frame
                                return {r=r1*math.min(1,t/60),theta=self.any.angle+t/10}
                            end)
                            -- 3 foot
                            if i%6==0 then
                                for j=-1,1,2 do
                                    local r=r1+j*20
                                    local bullet=Bullet{lifeFrame=600,sprite=BulletSprites.lightRound.yellow,extraUpdate=copyTable(potShapeExtraUpdate),highlight=true,invincible=true}
                                    bullet.any={angle=angle,sentry=sentry}
                                    DanmakuFuncs.orbitBind(bullet,sentry,function (self, centerObj)
                                        local t=self.frame
                                        return {r=r*math.min(1,t/60),theta=self.any.angle+t/10}
                                    end)
                                end
                            end
                        end
                    end
                    for i=1,8 do
                        local sign=math.mod2Sign(i)
                        local to=geo:to(boss.kinematicState.pos,G.runInfo.player.kinematicState.pos)
                        if DIFF()>=G.HARD and i>1 then
                            pot(to-math.pi/3*sign,i)
                            wait(60)
                            pot(to+math.pi/3*sign,i)
                        else
                            pot(to,i)
                        end
                        wait(180)
                        SFX:play('enemyCharge')
                        wait(60)
                        SFX:play('enemyPowerfulShot')
                        spawnFog(fogData,boss.kinematicState.pos,300)
                        wait(60)
                    end
                end
            },
            require('stages.stage6.spellcards.dipper'),
        }},
        BossManager.BossRound{phases={
            BossManager.NonSpellPhase{
                key='6-boss-enri-non-4',
                time=1800,
                hp=4000,
                func=function (self,boss)
                    boss:addHPProtection(180,9)
                    local geo=G.runInfo.geometry
                    ---@cast geo Spherical
                    local radius=geo.radius
                    ---@cast geo GeometryBase
                    local fogData={}
                    wait(60)
                    local sentry=DanmakuFuncs.sentry()
                    local group=5
                    local bulletSpawner
                    bulletSpawner=BulletSpawner{lifeFrame=9999,bulletNumber=1,spawnCircleRadius=0,spawnCircleAngle=math.eval(0,1),period=6,bulletSprite=BulletSprites.flame.blue,bulletSpeed=150,bulletLifeFrame=300,highlight=true,useRelativeAngle=true,bulletExtraUpdate={Action.ZoomIn(20),Action.FadeOut(20,true),function (self)
                        local t=self.frame
                        if fogData.signal and not self.flag and t%5==0 and math.abs(fogData.fogRadius-geo:distance(fogData.fogCenter,self.kinematicState.pos))<25 then
                            self.flag=true
                            self.any=true
                            self:changeSpriteColor('white')
                            self.kinematicState.speed=100
                            if DIFF()<=G.NORMAL then
                                self.lifeFrame=math.min(self.lifeFrame,self.frame+60)
                            end
                        end
                        if not self.flag then
                            local speed=self.kinematicState.speed
                            self.kinematicState.speed=math.lerp(speed,bulletSpawner.bulletSpeed,0.05)
                        end
                    end},bulletEvents={function (cir,args,self)
                        local index=self.spawnTimes
                        index=(index-0.5)/group-0.5
                        cir.kinematicState.speed=cir.kinematicState.speed+index*300
                        cir.kinematicState.dir=cir.kinematicState.dir+index*DSWITCH{0.1,0.15,0.2,0.3}*(self.sign or 1)
                    end}}
                    bulletSpawner:bindState(boss)
                    Event.LoopEvent{obj=bulletSpawner,period=30,executeFunc=function (_,times)
                        bulletSpawner.spawnCircleRadius=math.min(80,bulletSpawner.spawnCircleRadius+10)
                        bulletSpawner.bulletNumber=math.min(DSWITCH{4,5,7,9},bulletSpawner.bulletNumber+1)
                        bulletSpawner.spawnCircleAngle=bulletSpawner.spawnCircleAngle+math.pi/(bulletSpawner.bulletNumber-1)
                        bulletSpawner.angle=bulletSpawner.angle+math.pi*2/(bulletSpawner.bulletNumber+3)
                        bulletSpawner.bulletSpeed=math.min(260,bulletSpawner.bulletSpeed+10)
                        bulletSpawner.spawnTimes=0
                        bulletSpawner.sign=math.mod2Sign(times)
                    end}
                    Event.LoopEvent{obj=sentry,period=240,executeFunc=function ()
                        local pos=geo:rThetaGo(boss.kinematicState.pos,math.eval(30,20),math.eval(0,math.pi))
                        DanmakuFuncs.moveToInTime(boss,pos,60,Event.sineOProgressFunc,true)
                        local fogCenter=geo:rThetaGo(G.runInfo.player.kinematicState.pos,math.eval(radius*math.pi/2,100),math.eval(0,math.pi))
                        SFX:play('enemyPowerfulShot')
                        spawnFog(fogData,fogCenter,300,40)
                    end}
                end
            },
            require('stages.stage6.spellcards.galaxy'),
        }},
        BossManager.BossRound{phases={
            BossManager.NonSpellPhase{SKIP_INCLUDE=true,
                key='6-boss-enri-non-5',
                time=1800,
                hp=4000,
                func=function (self,boss)
                    boss:addHPProtection(180,9)
                    local geo=G.runInfo.geometry
                    ---@cast geo Spherical
                    local radius=geo.radius
                    ---@cast geo GeometryBase
                    local fogData={}
                    local player=G.runInfo.player
                    wait(60)
                    local sentry=DanmakuFuncs.sentry()
                    local colors={'red','yellow','blue'}
                    local silkExtraUpdate={Action.FadeIn(50,true),Action.ZoomOut(10),function (self)
                        local t=self.frame
                        if fogData.signal and not self.flag and t%5==0 and self.frame<self.lifeFrame-10 and math.abs(fogData.fogRadius-geo:distance(fogData.fogCenter,self.kinematicState.pos))<25 then
                            self.flag=true
                            self.size=1
                            self.batch=BulletBatch
                            local type,mod2Sign=self.any.type,self.any.mod2Sign
                            if type==1 then
                                if DIFF()<=G.EASY and mod2Sign<0 then
                                    self:remove()
                                end
                                self.kinematicState.dir=self.kinematicState.dir+math.pi/2
                                self:changeSprite(BulletSprites.ellipse.white)
                            elseif type==2 then
                                if DIFF()<=G.NORMAL and mod2Sign<0 then
                                    self:remove()
                                end
                                self.kinematicState.dir=self.kinematicState.dir-math.pi/2
                                self:changeSprite(BulletSprites.ellipse.white)
                            elseif type==3 then
                                if DIFF()<=G.HARD then
                                    self:remove()
                                end
                                self.kinematicState.dir=geo:to(self.kinematicState.pos,player.kinematicState.pos)
                                self:changeSprite(BulletSprites.ellipse.black)
                                self.spriteColor={0.7,0.7,0.7,1}
                                self.kinematicState.speed=-20
                            end
                            self.lifeFrame=self.lifeFrame+250
                        end
                        if self.flag then
                            self.kinematicState.speed=math.lerp(self.kinematicState.speed,DSWITCH{170,175,180,190},0.02)
                        end
                    end}
                    local function silk(pos,dir,typeMap)
                        local rows=5
                        local gap=25
                        local n=36
                        local dirOffset=0
                        local posFunc=function(i)
                            return geo:rThetaGo(pos,(i/n*900)%(radius*math.pi*2)+100,dir+i/n*math.pi*.2+math.sin(i/100)*2+dirOffset)
                        end
                        Event.Event{obj=sentry,action=function ()
                            for index=1,n*999 do
                                -- local distance=gap*index
                                local pos1=posFunc(index)
                                local dir1=geo:to(pos1,posFunc(index+1))
                                for i=1,rows do
                                    local i2=i-0.5-rows/2
                                    local pos2,dir2=geo:rThetaGo(pos1,gap*i2,dir1-math.pi/2)
                                    dir2=dir2+math.pi/2
                                    local type=typeMap(index,i)
                                    local color=colors[type]
                                    if geo:distance(pos2,player.kinematicState.pos)>80 then
                                        local bullet=Bullet{kinematicState={pos=pos2,dir=dir2,speed=0},sprite=BulletSprites.roundDark[color],lifeFrame=100,extraUpdate=silkExtraUpdate,highlight=true,size=1.5}
                                        bullet.any={type=type,mod2Sign=math.mod2Sign(index+i)}
                                    end
                                end
                                local distance,to=geo:rThetaTo(pos,player.kinematicState.pos)
                                local posn,dirn=geo:rThetaGo(pos,math.clamp(distance-30,0,5),to)
                                pos=posn
                                dirOffset=dirOffset+dirn-to
                                SFX:play('enemyShot')
                                -- if index%2==0 then
                                    wait(2)
                                -- end
                            end
                        end}
                    end
                    local pos=geo:rThetaGo(player.kinematicState.pos,1,math.eval(0,math.pi))
                    local squareSpiral={
                        {1,1,1,1,3,1,1,1,1,1},
                        {2,2,2,2,3,2,2,2,2,2},
                        {1,1,1,2,3,2,1,1,1,2},
                        {1,2,2,2,3,2,2,2,1,2},
                        {1,1,1,1,3,1,1,1,1,2},
                    }
                    -- need to prevent any color appearing in all columns
                    silk(pos,math.eval(0,math.pi),function (index,i)
                        local variationCount=4
                        local variation=math.ceil(index/150-1)%variationCount+1
                        local step=index-1
                        local column=step
                        local x=column%5+1
                        if variation==4 then
                            return squareSpiral[i][column%10+1]
                        elseif variation==2 then
                            -- Alternating square rings around the center of each tile.
                            if x==3 and i==3 then return 3 end
                            return math.max(math.abs(x-3),math.abs(i-3))%2+1
                        elseif variation==3 then
                            -- Diagonal bands fold back every four columns.
                            local zigzag=4-math.abs(column%6-3)
                            -- Mark the alternating outer tips
                            if (zigzag==1 or zigzag==4) and (i==1 or i==5) then
                                return 3
                            end
                            return math.floor((i-1+zigzag)/2)%2+1
                        end
                        -- bands
                        return math.ceil(column/4)%3+1
                    end)
                    Event.LoopEvent{obj=sentry,period=300,firstPeriod=120,executeFunc=function (self, index, total)
                        local fogCenter=geo:rThetaGo(G.runInfo.player.kinematicState.pos,math.eval(radius*math.pi/2,100),math.eval(0,math.pi))
                        SFX:play('enemyPowerfulShot')
                        spawnFog(fogData,fogCenter,300,40)
                    end}
                end
            },
            require('stages.stage6.spellcards.yinyang'),
        }},
    }
}

return boss
