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
                            self.kinematicState.speed=self.kinematicState.speed+4+DSWITCH{-0.3,-0.2,-0.1,0.05}
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
                        spawnFog(fogData,boss.kinematicState.pos)
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
            require('stages.stage6.spellcards.dipper'),
            require('stages.stage6.spellcards.galaxy'),
        }},
    }
}

return boss