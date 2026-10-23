-- 白炁混沌灌我形，禹步相隨登陽明。天回地轉步七星，躡罡履斗躋九靈。眾神助我斬妖精，兇惡濳伏邪魔傾。萬灾消滅我長生，我得長生朝上清。
-- 1. small white bullets over the screen and move towards enri
-- 2. high speed straight yellow bullets from enri representing sunlight
-- 3. they slow down and starts to rotate
-- 4. enri shoots 9 big circles
-- 5. big circles shoot bullets towards player
-- 6. all bullets become small purple bullets and moves a little
-- 7. all small bullets move outward, form a ring and returns, forcing player to move towards enri
---@return SpellcardPhase
return BossManager.SpellcardPhase{
    key='enri-dipper',
    bonusScore=50000,
    time=2770,
    hp=2000,
    dropItems={powerSmall=30,point=15},
    func=function(self, boss)
        boss:addHPProtection(1200,20)
        local geo=G.runInfo.geometry
        ---@cast geo Spherical
        local radius=geo.radius
        ---@cast geo GeometryBase
        local player=G.runInfo.player
        -- standing at Dubhe, facing Alkaid, the angle (degrees) to rotate (clockwise) and then move forward to step the dipper
        local dipperSteps={
            { -87.30, 5.4 },
            {  79.98, 7.9 },
            {  73.17, 4.5 },
            { -48.28, 5.4 },
            {   5.92, 4.4 },
            { -35.14, 6.7 },
        }
        -- transform into radians
        for _,value in ipairs(dipperSteps) do
            value[1]=value[1]/180*math.pi
            value[2]=value[2]/180*math.pi*5 -- real angle is too small
        end
        local bpm=170
        local barFrame=60/bpm*4*60
        local stepFrame=barFrame*2 -- 169.4 frames
        local stepFrameInt=math.floor(stepFrame)
        wait(60)
        local sentry=DanmakuFuncs.sentry()
        local currentStep=0--1--0
        local rotate=false
        local shoot=false
        local transform=false
        local transformedFinalSpeed=radius*math.pi/stepFrame*60*2
        local sevenLightOrbs={}
        local lightOrbTargetCounts={0,0,0,0,0,0,0,0}
        local transformUpdate=function(self)
            if not transform then
                return
            end
            if not self.flag then
                self.flag=self.frame
                self:changeSprite(BulletSprites.round.magenta)
                self.spriteColor={1,1,1,1}
                self.safe=true
                self.size=3
                self.spriteTransparency=0.2
                self.batch=Asset.bulletHighlightBatch
            else
                local t=self.frame-self.flag
                local transformFrames=30
                if t<=transformFrames then
                    local ratio=t/transformFrames
                    self.size=3-ratio
                    self.spriteTransparency=0.2+ratio*0.8
                end
                if t==transformFrames then
                    self.safe=false
                end
                if t<=stepFrame then
                    self.kinematicState.speed=self.kinematicState.speed*0.99
                end
                if t==stepFrameInt then -- 萬灾消滅我長生
                    self.kinematicState.speed=0
                    local bossPos=boss.kinematicState.pos
                    local antipode=geo:rThetaGo(bossPos,radius*math.pi,0)
                    local distance,to=geo:rThetaTo(self.kinematicState.pos,antipode)
                    self.kinematicState.dir=to
                    local ratio=1-distance/(radius*math.pi)
                    self.waitTime=math.floor(stepFrame*ratio^0.5)
                end
                if self.waitTime and t>stepFrameInt+self.waitTime and t<stepFrameInt*2+1 then
                    self.kinematicState.speed=(t-stepFrameInt)/stepFrameInt*transformedFinalSpeed
                    if not self.changed then
                        self:changeSpriteColor('red') 
                        self.changed=true
                    end
                end
                if t==stepFrameInt*2 then -- assign the orb it will aimed to in last period
                    local index=math.random(1,7)
                    -- local a=math.random(1,7) -- due to a mistake
                    local lightOrbTarget=sevenLightOrbs[index]
                    if not lightOrbTarget then -- maybe previous steps are skipped during test
                        index=8
                        lightOrbTarget=boss
                    end
                    self.orbIndex=index
                    self.target=lightOrbTarget
                    self.orbCount=lightOrbTargetCounts[index]
                    lightOrbTargetCounts[index]=lightOrbTargetCounts[index]+1
                end
                if t==stepFrameInt*2+1 then
                    local lightOrbTarget=self.target
                    local finalRadius=300
                    local angle=self.orbCount/lightOrbTargetCounts[self.orbIndex]*math.pi*2
                    local aim=geo:rThetaGo(lightOrbTarget.kinematicState.pos,finalRadius,angle)
                    local distance,to=geo:rThetaTo(self.kinematicState.pos,aim)
                    self.kinematicState.speed=distance/stepFrame*60*2
                    self.kinematicState.dir=to
                    self.lifeFrame=self.frame+stepFrame
                end
                if t==math.ceil(stepFrameInt*2.5) then
                    self.spriteTransparency=0.2
                    self.safe=true
                    self.kinematicState.speed=self.kinematicState.speed/2
                    local lightOrbTarget=self.target
                    local to=geo:to(self.kinematicState.pos,lightOrbTarget.kinematicState.pos)
                    self.kinematicState.dir=to
                    self.kinematicState.speed=300/stepFrame*60*2
                end
            end
        end
        local stepFuncs={
            -- 白炁混沌灌我形
            function()
                transform=false
                lightOrbTargetCounts={0,0,0,0,0,0,0,0}
                local n=DSWITCH{160,220,300,400}
                local extraUpdate={Action.ZoomIn(60,2,6,true),Action.FadeIn(60,true),Action.ZoomOut(20),function(self)
                    if self.frame>60 then
                        self.kinematicState.speed=self.any.speed*math.clamp((self.frame-60)/60,0,1)
                    end
                end}
                local remainingFrames=stepFrame*2
                local posb=copyTable(boss.kinematicState.pos)
                local angle0=math.eval(0,9)
                local sign=math.randomSign()
                for i=1,n do
                    local angle=3^0.5*i*sign+i*i/(n*n)+angle0
                    local distance=radius*math.acos(1-(2*i-1)/n)
                    local pos,dir=geo:rThetaGo(posb,distance,angle)
                    local bullet=Bullet{kinematicState={pos=pos,dir=dir+math.pi,speed=0},sprite=BulletSprites.cross.gray,lifeFrame=remainingFrames,extraUpdate=extraUpdate,size=math.eval(1,0.2),spriteExtraDirection=math.eval(0,9),highlight=true,forceQuad=true}
                    bullet.any={speed=distance/(remainingFrames-85)*60}
                    if i%3==0 then
                        SFX:play('enemyShot')
                        wait()
                        remainingFrames=remainingFrames-1
                    end
                end
            end,
            -- 禹步相隨登陽明
            function()
                local rays=10
                local posb=copyTable(boss.kinematicState.pos)
                local rayAngle=DSWITCH{0.06,0.08,0.09,0.10}
                local extraUpdate={Action.FadeIn(20,true),Action.ZoomIn(40,1,3,true),Action.FadeOut(20,true),function(self)
                    if transform then return end
                    if self.frame<60 then
                        self.kinematicState.speed=self.kinematicState.speed*0.95
                    else
                        self.kinematicState.speed=math.lerp(self.kinematicState.speed,100,0.02)
                    end
                    if rotate then
                        self.kinematicState.dir=self.kinematicState.dir+self.any.omega
                    end
                end,transformUpdate}
                local prepTime=100
                for i=1,rays do
                    local angle=math.pi/rays*(i*3%rays)+math.pi*(i%2)
                    local lase=GeoLaser{kinematicState={pos=copyTable(posb),dir=angle,speed=0},sprite=BulletSprites.laser.black,spriteColor={1,0.7,0.3,1},lifeFrame=prepTime+60,extraUpdate={GeoLaser.presetActions.laserZoomIn(20),GeoLaser.presetActions.laserPrep(prepTime,0.3),GeoLaser.presetActions.laserZoomOut(20),},meshBudget={capNum=1,step=0,num=20},size=0.01,rayAngle=rayAngle}
                    Event{obj=lase,action=function ()
                        wait(prepTime)
                        if sentry.removed then
                            return
                        end
                        SFX:play('enemyShot2')
                        local batch=DSWITCH{1,1,3,3}
                        BulletSpawner{kinematicState={pos=copyTable(posb),dir=0,speed=0},lifeFrame=DSWITCH{4,5,5,6},period=1,angle=lase.kinematicState.dir,bulletNumber=batch*2,bulletSprite=BulletSprites.scale.yellow,highlight=true,bulletLifeFrame=1200,range=0,bulletSpeed=0,bulletExtraUpdate=extraUpdate,bulletEvents={function(cir,args,self)
                            local index=args.index-1
                            local sign=math.mod2Sign(i)
                            if index>=batch then
                                cir.kinematicState.dir=cir.kinematicState.dir+math.pi
                            end
                            local dir=cir.kinematicState.dir
                            local idx=index%batch
                            local ratio=(idx-batch/2+0.5)/batch
                            local moveDistance=(0.5-math.abs(ratio))*30
                            local offsetAngle=ratio*rayAngle
                            local pos2,dir2=geo:rThetaGo(cir.kinematicState.pos,moveDistance,dir+offsetAngle)
                            cir.kinematicState.pos=pos2
                            cir.kinematicState.dir=dir2
                            cir.any={omega=0.005*sign}
                            cir.kinematicState.speed=cir.kinematicState.speed+400*(self.spawnTimes-1)
                        end}}
                    end}
                    wait(5)
                end
            end,
            -- 天回地轉步七星
            function()
                rotate=true
                wait(stepFrame)
                rotate=false
            end,
            -- 躡罡履斗躋九靈
            function()
                local num=9
                local angle0=math.eval(0,9)
                local extraUpdate={Action.ZoomIn(20),Action.FadeOut(20,true),transformUpdate}
                local subExtraUpdate={Action.ZoomIn(60,2),Action.FadeIn(60,false),Action.FadeOut(20,false),function(self)
                    if transform then self:remove() end
                    local aim=self.any.aim.kinematicState.pos
                    local distance,to=geo:rThetaTo(self.kinematicState.pos,aim)
                    to=math.modClamp(to,self.kinematicState.dir)
                    local ratio=math.clamp((distance-10*self.any.aim.size)/100,0,0.2)
                    self.kinematicState.dir=math.lerp(self.kinematicState.dir+math.eval(0,0.05),to,ratio)
                    self.spriteColor[4]=1-ratio*4
                end}
                for i=1,num do
                    SFX:play('enemyShot3')
                    local angle=angle0+math.pi*2/num*i
                    local r,g,b=math.hsvToRgb(math.eval(0,0.5),0.6,1)
                    local core=Bullet{kinematicState={pos=copyTable(boss.kinematicState.pos),dir=angle,speed=math.eval(300,300)*2},sprite=BulletSprites.largeOrb.white,spriteColor={r,g,b,0.6},lifeFrame=stepFrame*5,extraUpdate={Action.ZoomIn(60,1.5),Action.FadeIn(50,true),Action.FadeOut(20,true),function (self)
                        if transform then return end
                        self.kinematicState.speed=math.lerp(self.kinematicState.speed,100,0.02)
                        self.kinematicState.dir=self.kinematicState.dir+math.eval(0,0.005)
                        if shoot and self.frame%DSWITCH{45,35,25,15}==0 then
                            SFX:play('enemyShot')
                            local to=geo:to(self.kinematicState.pos,player.kinematicState.pos)
                            Bullet{kinematicState={pos=copyTable(self.kinematicState.pos),dir=to,speed=150},lifeFrame=self.lifeFrame-self.frame,sprite=BulletSprites.bill.white,size=2,spriteColor={r,g,b,1},extraUpdate=extraUpdate}
                            to=math.modClamp(to,self.kinematicState.dir)
                            self.kinematicState.dir=math.lerp(self.kinematicState.dir,to,0.1)
                            if DIFF()>=G.LUNATIC then
                                self.kinematicState.speed=self.kinematicState.speed+30
                            end
                        end
                    end,transformUpdate},forceQuad=true,invincible=true}
                    core.spriteRotationSpeed=math.eval(0,0.07)
                    for j=1,8 do
                        local sub=Bullet{kinematicState={pos=copyTable(boss.kinematicState.pos),dir=math.eval(0,9),speed=math.eval(300,50)},sprite=BulletSprites.magatama.white,spriteColor={r,g,b,0.7},lifeFrame=core.lifeFrame,extraUpdate=subExtraUpdate,highlight=true,invincible=true,safe=true}
                        sub.any={aim=core}
                        sub.spriteRotationSpeed=math.eval(0,0.17)
                    end
                    wait(5)
                end
            end,
            -- 眾神助我斬妖精
            function()
                shoot=true
                wait(stepFrame)
                shoot=false
            end,
            -- 兇惡濳伏邪魔傾
            function()
                transform=true
            end
        }
        -- first step can land on integer bars instead of even bars
        local t0=boss.frame
        local t0p=t0-t0%stepFrame+stepFrame
        local offset=0
        if t0p>t0+stepFrame/2 then
            offset=1/2
        end
        Event.LoopEvent{obj=sentry,period=1,executeFunc=function ()
            local t=boss.frame
            if math.ceil(t/stepFrame+offset)==math.ceil((t-1)/stepFrame+offset) then
                return
            end
            currentStep=currentStep%8+1 -- 8th one is rest
            SFX:play('enemyPowerfulShot')
            if currentStep>7 then
                -- 我得長生朝上清
                for i=1,7 do
                    local lightOrb=sevenLightOrbs[i]
                    if lightOrb then
                        BulletSpawner{lifeFrame=999,firstPeriod=8*(8-i),period=56,bulletNumber=DSWITCH{4,5,6,8},angle='0+999',bulletSprite=BulletSprites.round.red,bulletLifeFrame=240,bulletSpeed=DSWITCH{50,70,80,90},bulletExtraUpdate={Action.ZoomIn(20,1,3),Action.FadeIn(25,true),Action.FadeOut(15,true)}}:bindState(lightOrb)
                    end
                end
                Event{obj=sentry,action=function ()
                    wait(stepFrame/2-20)
                    SFX:play('stop')
                end}
                return
            end
            if currentStep==1 then
                boss.kinematicState.dir=geo:to(boss.kinematicState.pos,player.kinematicState.pos)
            end
            local func=stepFuncs[currentStep]
            if func then
                Event{obj=sentry,action=func}
            end
            sevenLightOrbs[currentStep]=Bullet{kinematicState={pos=copyTable(boss.kinematicState.pos),speed=0,dir=0},lifeFrame=stepFrame*(9-currentStep),sprite=BulletSprites.lightRound.red,extraUpdate={Action.ZoomIn(20,1,3),Action.FadeOut(20,true)},highlight=true,invincible=true}
            if currentStep>1 then -- connect this with previous
                local previous=sevenLightOrbs[currentStep-1]
                local this=sevenLightOrbs[currentStep]
                if previous then
                    local mids,dirs=DanmakuFuncs.midPoints(previous.kinematicState.pos,this.kinematicState.pos,30,20)
                    for i=2,#mids-1 do
                        local mid,dir=mids[i],dirs[i]
                        Bullet{kinematicState={pos=mid,dir=dir,speed=0},lifeFrame=this.lifeFrame,highlight=true,invincible=true,sprite=BulletSprites.stick.yellow,size=3,extraUpdate={Action.FadeIn(i+10,true),Action.FadeOut(20,true)}}
                    end
                end
            end
            local larger=Effect.Larger{kinematicState={pos=boss.kinematicState.pos,dir=0,speed=0},sprite=BulletSprites.shockwave.blue,size=0,growSpeed=0.1,animationFrame=60,spriteTransparency=0.8,shareKinematicState=true}
            Event.EaseEvent{obj=larger,aims={spriteTransparency=0},duration=larger.animationFrame}
            if currentStep<7 then
                local step=dipperSteps[currentStep]
                boss.kinematicState.dir=boss.kinematicState.dir+step[1]
                local aim=geo:rThetaGo(boss.kinematicState.pos,step[2]*radius,boss.kinematicState.dir)
                Event{obj=sentry,action=function ()
                    wait(stepFrame-60)
                    DanmakuFuncs.moveToInTime(boss,aim,60,Event.sineIProgressFunc,true)
                end}
            end
        end}
    end
}