---@return SpellcardPhase
return BossManager.SpellcardPhase{
    key='enri-yinyang',
    bonusScore=50000,
    time=2400,
    hp=4000,
    dropItems={powerSmall=30,point=15},
    func=function(self, boss)
        boss:addHPProtection(300,5)
        local geo=G.runInfo.geometry
        ---@cast geo Spherical
        local radius=geo.radius
        ---@cast geo GeometryBase
        local player=G.runInfo.player
        local viewDirection=player.viewDirection
        local aim=geo:rThetaGo(player.kinematicState.pos,radius*math.pi/2+1,viewDirection-math.pi/2)
        DanmakuFuncs.moveToInTime(boss,aim,60,Event.sineOProgressFunc,true)
        boss.safe=true
        -- to prevent leaked red color clash with trail of edge bullets
        boss.showHexagram=false
        wait(60)
        SFX:play('enemyPowerfulShot')
        boss.safe=false
        boss.kinematicState.dir=boss.kinematicState.dir-math.pi/2
        -- yin yang ball: boundary between black and white is 4 semicircles with r=radius*math.pi/4. boss is at a white eye and player starts near a black eye.
        -- still it's easier to describe bullets based on the point (A) furthest from 4 semicircle centers. points inside can be described as distance to A<radius*pi/2 (and distance to corresponding semicircle>radius*pi/4) / (or distance to corresponding semicircle<radius*pi/4)
        -- however for smoother edge and accurate eyes, actually draws a hemisphere with four hemicircles removed, and then draw two small circles
        local pointA=geo:rThetaGo(boss.kinematicState.pos,radius*math.pi/2,boss.kinematicState.dir)
        local dir0=geo:to(pointA,boss.kinematicState.pos)
        local r0=radius*math.pi/2
        local gap=60
        local n=math.ceil(r0*1.5/gap)
        local bulletExtraUpdate={Action.FadeIn(90,true),Action.ZoomOut(20),function (self)
            local r,theta=self.any.r,self.any.theta
            self.kinematicState.pos,self.kinematicState.dir=geo:rThetaGo(boss.kinematicState.pos,r,theta+boss.kinematicState.dir)
        end}
        local function spawnBullet(pos,r,theta,size)
            size=size or 1.5
            if r and theta then
                pos=geo:rThetaGo(boss.kinematicState.pos,r,theta)
            else
                r,theta=geo:rThetaTo(boss.kinematicState.pos,pos)
            end
            local bullet=Bullet{kinematicState={pos=pos,dir=0,speed=0},lifeFrame=9999,sprite=BulletSprites.lightRound.white,highlight=true,extraUpdate=bulletExtraUpdate,size=size,forceQuad=true,invincible=true}
            bullet.any={r=r,theta=theta-boss.kinematicState.dir}
            return bullet
        end
        local balance=0.2
        local dynamicPointA
        for i=0,n do
            local r=i*gap
            local circum=math.sin(r/radius)*radius*math.pi*2
            local n2=math.max(1,math.ceil(circum/gap))
            local angle0=math.eval(0,math.pi)
            for j=1,n2 do
                local angle=angle0+math.pi*2/n2*j
                local pos=geo:rThetaGo(pointA,r,angle)
                local angles=angle-dir0
                -- due to balance, it's complex to calculate which section it's in
                local section=0
                for s=1,3 do
                    if math.angleDiff(angles,math.pi/2*s)<math.pi/4*(1-math.mod2Sign(s)*balance) then
                        section=s
                        break
                    end
                end
                local angle2=dir0+math.pi/2*(section)
                local smallCircle=geo:rThetaGo(pointA,r0,angle2)
                local smallCircleDistance=geo:distance(pos,smallCircle)
                local insideSmallCircle=smallCircleDistance<radius*math.pi/4*(1-balance*math.mod2Sign(section)+0.2)
                local insideSemisphere=r<radius*math.pi/2
                if (insideSemisphere and not insideSmallCircle) then
                    local bullet=spawnBullet(pos,nil,nil,3)
                    if i==0 then
                        dynamicPointA=bullet
                    end
                end
            end
        end
        local function inWhite(pos)
            local distance,dir=geo:rThetaTo(dynamicPointA.kinematicState.pos,pos)
            if distance<math.pi/4*radius then
                return true
            end
            if distance>math.pi*3/4*radius then
                return false
            end
            local dir0=geo:to(dynamicPointA.kinematicState.pos,boss.kinematicState.pos)
            local section=math.ceil((dir-dir0-math.pi/4)/(math.pi/2))
            local angle2=dir0+math.pi/2*(section)
            local smallCircle=geo:rThetaGo(dynamicPointA.kinematicState.pos,r0,angle2)
            local smallCircleDistance=geo:distance(pos,smallCircle)
            local insideSmallCircle=smallCircleDistance<radius*math.pi/4
            local insideSemisphere=distance<radius*math.pi/2
            if section%2==1 then
                return insideSemisphere and not insideSmallCircle
            end
            return insideSemisphere or insideSmallCircle
        end
        local t=240
        -- bullet spawner. spawns when moved certain distance
        local switchExtraUpdate={Action.ZoomIn(20,1,2),Action.FadeIn(20,true),Action.ZoomOut(20),function (self)
            -- it means whether the bullet is in white area. its sprite color is opposite to the area color it's in
            local currentWhite=self.any.currentWhite
            local t1=self.frame
            if t1%2==1 then
                local white=inWhite(self.kinematicState.pos)
                if white~=currentWhite then
                    self.any.currentWhite=white
                    self:changeSpriteColor(white and 'black' or 'white')
                    if white then
                        self.spriteColor={0.5,0.5,0.5,1}
                    else
                        local dirRef=self.kinematicState.dir
                        self.kinematicState.dir=geo:to(self.kinematicState.pos,player.kinematicState.pos)
                        self.deltaDir=(self.deltaDir or 0)+self.kinematicState.dir-dirRef
                        self.spriteColor={1,1,1,1}
                    end
                end
            end
            self.kinematicState.speed=math.lerpCondition(self.kinematicState.speed,currentWhite,200,100,0.1)
        end}
        local coreExtraUpdate=copyTable(switchExtraUpdate)
        table.insert(coreExtraUpdate,function (self)
            local currentWhite=self.any.currentWhite
            local flip=self.any.flip
            self.any.r=math.lerpCondition(self.any.r,currentWhite==flip,20,100,0.02)
            -- self.kinematicState.speed=100
        end)
        local followerExtraUpdate={Action.ZoomIn(20,1,2),Action.FadeIn(20,true),Action.ZoomOut(20),function (self)
            -- it means whether the bullet is in white area. its sprite color is opposite to the area color it's in
            local currentWhite=self.any.currentWhite
            local t1=self.frame
            if t1%2==1 then
                local white=inWhite(self.kinematicState.pos)
                if white~=currentWhite then
                    self.any.currentWhite=white
                    self:changeSpriteColor(white and 'black' or 'white')
                    if white then
                        self.spriteColor={0.5,0.5,0.5,1}
                    else
                        self.spriteColor={1,1,1,1}
                    end
                end
            end
            local core=self.any.core
            self.kinematicState.pos,self.kinematicState.dir=geo:rThetaGo(core.kinematicState.pos,core.any.r,self.any.dir+core.kinematicState.dir-(core.deltaDir or 0))
        end}
        local round=0
        local resetSignal=false
        local spawnerExtraUpdate=copyTable(bulletExtraUpdate)
        table.insert(spawnerExtraUpdate,function (self)
            local pos=self.kinematicState.pos
            if resetSignal then
                if DIFF()<=G.NORMAL or round%2==1 then
                    BulletSpawner{kinematicState={pos=pos,dir=0,speed=0},bulletSprite=BulletSprites.knife[self.sprite.data.color],spawnCircleRadius=30,period=3,lifeFrame=DSWITCH{12,18,24,30},bulletNumber=2,bulletLifeFrame=600,bulletSpeed=150,bulletExtraUpdate=switchExtraUpdate,bulletEvents={function (cir,args,self)
                        cir.any={currentWhite=nil}
                    end},highlight=false}
                else
                    BulletSpawner{kinematicState={pos=pos,dir=0,speed=0},bulletSprite=BulletSprites.bigRound[self.sprite.data.color],spawnCircleRadius=30,period=3,firstPeriod=1,lifeFrame=2,bulletNumber=1,bulletLifeFrame=600,bulletSpeed=50,size=2,bulletExtraUpdate=coreExtraUpdate,bulletEvents={function (cir,args,self)
                        local angle=math.eval(0,math.pi)
                        local flip=cir.sprite.data.color=='black'
                        cir.any={currentWhite=nil,r=0,flip=flip}
                        for i=1,8 do
                            local following=Bullet{sprite=BulletSprites.heart[self.sprite.data.color],lifeFrame=600,extraUpdate=followerExtraUpdate}
                            following.spriteExtraDirection=flip and math.pi or 0
                            following.any={dir=math.pi*2/8*i+angle,core=cir,currentWhite=nil}
                        end
                    end},highlight=false}
                end
            end
        end)
        -- two eyes in black area. also spawns at white area eyes for bullet spawning.
        for i=1,4 do
            local r1,theta1=radius*math.pi/2*(i),boss.kinematicState.dir+math.pi/2
            local bullet=spawnBullet(nil,r1,theta1)
            bullet.batch=BulletBatch
            if i%2==0 then
                bullet.spriteColor={0.2,0.2,0.2,1}
                bullet:changeSpriteColor('black')
            end
            bullet.any.accumulatedMovement=0
            bullet.extraUpdate=spawnerExtraUpdate
        end
        -- directly draw edge of 4 semicircles to make edge more smooth, also will spawn trail (doppler effect to hint how boundary moves)
        local trailExtraUpdate=copyTable(bulletExtraUpdate)
        local period=2
        table.insert(trailExtraUpdate,function (self)
            if G.save.options.reduceVisualQuality then
                return
            end
            if self.frame%period==0 and self.posRef and self.frame>120 then
                local distance,dir=geo:rThetaTo(self.kinematicState.pos,self.posRef)
                dir=dir+math.pi
                local towardsWhite=self.any.towardsWhite+self.kinematicState.dir
                local diff=math.angleDiff(dir,towardsWhite)
                local transparency=math.abs(math.cos(diff))*math.clamp(distance/3,0,1)
                local color=diff<math.pi/2 and {1,0,0,1} or {0,0,1,1}
                Bullet{kinematicState={pos=self.kinematicState.pos,dir=self.kinematicState.dir,speed=0},lifeFrame=2,sprite=BulletSprites.lightRound.white,safe=true,highlight=true,forceQuad=true,invincible=true,spriteTransparency=transparency,size=self.size,spriteColor=color}
            end
            self.posRef=copyTable(self.kinematicState.pos)
        end)
        for i=1,4 do
            local smallCircle,dir=geo:rThetaGo(boss.kinematicState.pos,math.pi/2*i*radius,boss.kinematicState.dir+math.pi/2)
            local sign=math.mod2Sign(i)
            local nj=15+(sign==1 and 5 or 0)
            local r=radius*math.pi/4*(1-sign*balance) -- due to bullets have size, reduce white part radius to balance
            for j=1,nj do
                local anglej=(j-0.5-nj/2)/nj*math.pi*(sign==1 and 2 or 1) -- white part draws whole circle instead, due to the inner half circle is difficult to be covered by central part
                local angle=dir+sign*math.pi/2+anglej
                local pos,newAngle=geo:rThetaGo(smallCircle,r,angle)
                local bullet=spawnBullet(pos,nil,nil,2)
                if math.abs(anglej)<math.pi/2 then
                    bullet.extraUpdate=trailExtraUpdate
                    bullet.any.towardsWhite=newAngle+(sign==1 and math.pi or 0)-geo:to(pos,boss.kinematicState.pos)
                end
            end
        end
        -- fill two small circles
        for i=1,2 do
            local smallCircle,dir=geo:rThetaGo(boss.kinematicState.pos,math.pi*i*radius,boss.kinematicState.dir+math.pi/2)
            local nj=10
            for j=1,nj do
                local angle=dir+(j-0.5-nj/2)/nj*math.pi*2
                local pos=geo:rThetaGo(smallCircle,radius*math.pi/4*0.55,angle)
                local bullet=spawnBullet(pos,nil,nil,3)
            end
        end
        local sentry=DanmakuFuncs.sentry()
        sentry.removeEffect=function ()
            boss.showHexagram=true -- restore hexagram
        end
        local multi=DSWITCH{1,1.2,1.5,2}
        local movements={
            -- boss directly rotate. black area rotates around boss (along long direction), cannot be too fast
            function ()
                Event.EaseEvent{obj=sentry,easeObj=boss.kinematicState,aims={dir=boss.kinematicState.dir+math.randomSign()*math.pi/2*multi^0.5},duration=t,progressFunc=Event.sineIOProgressFunc}
            end,
            -- boss directly moves forward. two small black circles are static while the middle part rotates. can be fast
            function ()
                local pos=geo:rThetaGo(boss.kinematicState.pos,math.pi/2*radius*math.min(2,multi),boss.kinematicState.dir)
                DanmakuFuncs.moveToInTime(boss,pos,t,Event.sineIOProgressFunc,true,sentry)
            end,
            -- boss moves perpendicularly to its direction. the middle part of black area is static. can be fast
            function()
                local pos=geo:rThetaGo(boss.kinematicState.pos,math.pi/2*radius*math.min(2,multi),boss.kinematicState.dir+math.randomSign()*math.pi/2)
                DanmakuFuncs.moveToInTime(boss,pos,t,Event.sineIOProgressFunc,true,sentry)
            end,
            -- boss moves in circle with a diameter of centers of two small circles. so it rotates like regular taichi. cannot be too fast
            function()
                local angle
                if DIFF()>=G.LUNATIC then
                    angle=boss.kinematicState.dir+math.pi/2*math.randomSign()
                else
                    -- the rotation center would be near player
                    angle=math.modClamp(boss.kinematicState.dir+math.pi/2,geo:to(boss.kinematicState.pos,player.kinematicState.pos),math.pi/2)
                    if geo:distance(boss.kinematicState.pos,player.kinematicState.pos)>radius*math.pi/2 then
                        angle=angle+math.pi
                    end
                end
                local delta=angle-boss.kinematicState.dir
                local pos=geo:rThetaGo(boss.kinematicState.pos,math.pi/4*radius,angle)
                local dir0=geo:to(pos,boss.kinematicState.pos)
                local sign=math.randomSign()
                Event.LoopEvent{obj=sentry,period=1,times=t,executeFunc=function (self, index, total)
                    local progress=Event.sineIOProgressFunc(index/total)
                    local angle=dir0+progress*math.pi*sign
                    local posi,diri=geo:rThetaGo(pos,math.pi/4*radius,angle)
                    boss.kinematicState.pos=posi
                    boss.kinematicState.dir=diri+delta
                end}
            end,
        }
        local lastIndex=math.random(1,#movements)
        Event.LoopEvent{obj=sentry,period=240,firstPeriod=120,executeFunc=function (self,times)
            round=round+1
            resetSignal=true
            SFX:play('enemyPowerfulShot')
            local index=(lastIndex+math.random(0,#movements-2))%#movements+1
            movements[index]()
            lastIndex=index
            wait()
            resetSignal=false
        end}
    end
}