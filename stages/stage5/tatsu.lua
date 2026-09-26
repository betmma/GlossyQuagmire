local function getBall(boss)
    local ball=Bullet{kinematicState={pos=boss.kinematicState.pos,dir=0,speed=0},lifeFrame=9999,sprite=BulletSprites.lotus.red,invincible=true,extraUpdate={Action.ZoomIn(20)},size=1.5}
    ball.spriteRotationSpeed=0.05
    local fairy=Enemy{sprite=Asset.fairySprites.small.red,lifeFrame=9999,spriteTransparency=0,maxhp=9999}
    fairy.size=8
    fairy.safe=true
    fairy:bind(boss)
    fairy:bindState(ball)
    return ball
end

local function lightOrbSpawner(ball,sign,i,num,geo,sentry,angle,bulletLifeFrame,accDiv,idx)
    local colors={'blue','magenta','black'}
    local color=colors[idx]
    BulletSpawner{kinematicState={pos=ball.kinematicState.pos,dir=0,speed=0},lifeFrame=20,period=99,firstPeriod=1,angle=sign*math.mod2Sign(i)*math.pi/2+math.pi/2,range=0,bulletNumber=num,bulletSprite=BulletSprites.lightRound.red,highlight=true,bulletLifeFrame=bulletLifeFrame,bulletSpeed=0,bulletExtraUpdate={Action.FadeIn(10,true),Action.ZoomOut(20),function(self)
        if sentry.any.flag and not self.flagTime then
            self.flagTime=self.frame
            self.kinematicState.speed=0
            local newDir
            if idx==1 then
                newDir=geo:to(self.kinematicState.pos,ball.kinematicState.pos)+math.pi
            elseif idx==2 then
                newDir=geo:to(self.kinematicState.pos,ball.kinematicState.pos)
            else
                newDir=math.pi-geo:to(self.kinematicState.pos,G.runInfo.player.kinematicState.pos)
            end
            self.kinematicState.dir=newDir
            local distPos = idx == 3 and G.runInfo.player.kinematicState.pos or ball.kinematicState.pos
            self.dist = geo:distance(self.kinematicState.pos, distPos)
            self:changeSpriteColor(color)
            local cos=math.cos(self.kinematicState.dir)
            self.horizontal=math.abs(cos*self.dist)/(geo.a/3)
        end
        if self.flagTime and self.frame<self.flagTime+90 then
            local t=(self.frame-self.flagTime)/90
            self.kinematicState.speed=self.kinematicState.speed+self.dist/accDiv
            local c=math.lerp(1,1-self.horizontal*0.7,t)
            self.spriteColor={1,c,1,1}
        end
    end},bulletEvents={function(cir,args,self)
        cir.spriteColor={1,0.5,0.5,1}
        cir.forceQuad=true
        cir.kinematicState.dir=cir.kinematicState.dir+(args.index%2)*math.pi+(angle*sign*math.mod2Sign(i))
        if args.index<=2 and self.spawnTimes==1 then
            local lase=GeoLaser{kinematicState={pos=copyTable(ball.kinematicState.pos),dir=cir.kinematicState.dir,speed=0},sprite=BulletSprites.laser.red,size=2,rayAngle=0,spriteTransparency=0.3,safe=true,invincible=true,lifeFrame=300,meshBudget={capNum=2,step=80,num=60},spriteColor={1,0.4,0.4,1},extraUpdate={GeoLaser.presetActions.laserZoomIn(22),GeoLaser.presetActions.laserZoomOut(20)}}
        end
        cir.kinematicState.speed=cir.kinematicState.speed+(args.index-0.5)/num*960
        cir.size=cir.size+(num-args.index)/num
    end}}
end

local boss=BossManager.BossSegment{
    bossName='tatsu',
    key='5-boss',
    -- BGM='level5b',
    getBossSpawnPos=function(self)
        local geo=G.runInfo.geometry
        local playerPos=G.runInfo.player.kinematicState.pos
        local pos,dir=geo:rThetaGo(playerPos,280*math.pi,0)
        return {x=pos.x,y=200}
    end,
    rounds={
        BossManager.BossRound{phases={
            BossManager.NonSpellPhase{
                key='5-boss-tatsu-non-1',
                time=1800,
                hp=2000,
                func=function(self, boss)
                    local geo=G.runInfo.geometry
                    ---@cast geo Cylinder
                    local basePos=geo:init().pos
                    local pos0=boss.kinematicState.pos
                    local ball=getBall(boss)
                    local sign=math.randomSign()
                    local sentry=DanmakuFuncs.sentry()
                    sentry.any={flag=false}
                    for i=1,5 do
                        boss:addHPProtection(300,5)
                        local pos1=geo:rThetaGo(boss.kinematicState.pos,200,-math.pi/2)
                        DanmakuFuncs.moveToInTime(ball,pos1,120,Event.sineOProgressFunc)
                        wait(120)
                        local angle=DSWITCH{0.1,0.08,0.06,0.04}*math.eval(1,0.1)
                        SFX:play('enemyPowerfulShot')
                        local num=DSWITCH{200,200,200,160}
                        local bulletLifeFrame=1200
                        local accDiv=200
                        lightOrbSpawner(ball,sign,i,num,geo,sentry,angle,bulletLifeFrame,accDiv,1)
                        sentry.any.flag=false
                        wait(60)
                        Event.LoopEvent{obj=ball,period=1,times=360,executeFunc=function(self,times,maxTimes)
                            local x=ball.kinematicState.pos.x
                            local aimx=G.runInfo.player.kinematicState.pos.x
                            aimx=math.modClamp(aimx,x,geo.a/2)
                            local maxSpeed=math.min(12,times/10)
                            local lerpSpeed=math.abs(aimx-x)*0.03
                            local speed=math.min(maxSpeed,lerpSpeed)
                            ball.kinematicState.pos.x=x+speed*math.sign(aimx-x)
                            if times==180 then
                                SFX:play('enemyCharge')
                            end
                            if times==240 then
                                SFX:play('enemyPowerfulShot')
                                sentry.any.flag=true
                            end
                        end}
                        wait(360)
                        sentry.any.flag=false
                    end
                end
            },
            BossManager.NonSpellPhase{
                key='5-boss-tatsu-non-2',
                time=1800,
                hp=2000,
                func=function(self, boss)
                    local geo=G.runInfo.geometry
                    ---@cast geo Cylinder
                    local basePos=geo:init().pos
                    local pos0=boss.kinematicState.pos
                    local ball=getBall(boss)
                    local sign=math.randomSign()
                    local sentry=DanmakuFuncs.sentry()
                    sentry.any={flag=false}
                    for i=1,5 do
                        boss:addHPProtection(300,5)
                        local pos1=geo:rThetaGo(boss.kinematicState.pos,200,-math.pi/2)
                        DanmakuFuncs.moveToInTime(ball,pos1,120,Event.sineOProgressFunc)
                        wait(120)
                        local angle=DSWITCH{0.1,0.09,0.09,0.075}*math.eval(1,0.1)
                        SFX:play('enemyPowerfulShot')
                        local num=DSWITCH{120,120,150,150}
                        local bulletLifeFrame=1200
                        local accDiv=DSWITCH{300,300,200,200}
                        lightOrbSpawner(ball,sign,i,num,geo,sentry,angle,bulletLifeFrame,accDiv,2)
                        sentry.any.flag=false
                        wait(60)
                        Event.LoopEvent{obj=ball,period=1,times=360,executeFunc=function(self,times,maxTimes)
                            local x=ball.kinematicState.pos.x
                            local aimx=G.runInfo.player.kinematicState.pos.x
                            aimx=math.modClamp(aimx,x,geo.a/2)
                            local maxSpeed=math.min(12,times/10)
                            local lerpSpeed=math.abs(aimx-x)*0.03
                            local speed=math.min(maxSpeed,lerpSpeed)
                            ball.kinematicState.pos.x=x+speed*math.sign(aimx-x)
                            if times==180 then
                                SFX:play('enemyCharge')
                            end
                            if times==240 then
                                SFX:play('enemyPowerfulShot')
                                sentry.any.flag=true
                            end
                        end}
                        wait(360)
                        sentry.any.flag=false
                    end
                end
            },
            BossManager.NonSpellPhase{
                key='5-boss-tatsu-non-3',
                time=1800,
                hp=2000,
                func=function(self, boss)
                    local geo=G.runInfo.geometry
                    ---@cast geo Cylinder
                    local basePos=geo:init().pos
                    local pos0=boss.kinematicState.pos
                    local ball=getBall(boss)
                    local sign=math.randomSign()
                    local sentry=DanmakuFuncs.sentry()
                    sentry.any={flag=false}
                    for i=1,5 do
                        boss:addHPProtection(300,5)
                        local pos1=geo:rThetaGo(boss.kinematicState.pos,200,-math.pi/2)
                        DanmakuFuncs.moveToInTime(ball,pos1,120,Event.sineOProgressFunc)
                        wait(120)
                        local angle=0.075*math.eval(1,0.1)
                        SFX:play('enemyPowerfulShot')
                        local num=DSWITCH{120,130,140,145}
                        local bulletLifeFrame=600
                        local accDiv=DSWITCH{300,300,200,200}
                        lightOrbSpawner(ball,sign,i,num,geo,sentry,angle,bulletLifeFrame,accDiv,3)
                        sentry.any.flag=false
                        Event.LoopEvent{obj=ball,period=1,times=300,executeFunc=function(self,times,maxTimes)
                            local x=ball.kinematicState.pos.x
                            local aimx=G.runInfo.player.kinematicState.pos.x
                            aimx=math.modClamp(aimx,x,geo.a/2)
                            local maxSpeed=math.min(12,times/10)
                            local lerpSpeed=math.abs(aimx-x)*0.03
                            local speed=math.min(maxSpeed,lerpSpeed)
                            ball.kinematicState.pos.x=x+speed*math.sign(aimx-x)
                            if times==180 then
                                SFX:play('enemyCharge')
                            end
                            if times==240 then
                                SFX:play('enemyPowerfulShot')
                                sentry.any.flag=true
                            end
                        end}
                        wait(300)
                        sentry.any.flag=false
                    end
                end
            },
        }},
    }
}

return boss