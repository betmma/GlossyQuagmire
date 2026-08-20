---@return SpellcardPhase
return BossManager.SpellcardPhase{
    key='shouji-block',
    bonusScore=25000,
    time=1800,
    isTimeout=true,
    hp=4000,
    dropItems={powerSmall=15,point=15},
    func=function(self, boss)
        boss.showHexagram=false
        local geo=G.runInfo.geometry
        ---@cast geo PortalGeometryBase
        local posp=copyTable(G.runInfo.player.kinematicState.pos)
        local outerPortals=Portal.setOuterPortals(posp)
        for i=1,#outerPortals do
            outerPortals[i]:remove()
            outerPortals[i]=nil
        end
        Event.EaseEvent{obj=boss,aims={spriteTransparency=0},duration=30}
        wait(30)
        G.runInfo.player.immobileFrame=30
        G.runInfo.player.viewDirection=math.modClamp(G.runInfo.player.viewDirection)
        Event.EaseEvent{obj=G.runInfo.player,aims={viewDirection=0},duration=30,progressFunc=Event.sineIOProgressFunc}
        wait(30)
        G.runInfo.player.viewDirection=0
        local dir0=G.runInfo.player.viewDirection
        boss.safe=true
        Event{obj=boss,action=function ()
            wait(1800)
            Portal.canvasOffset.x=0
            Event.EaseEvent{obj=boss,aims={spriteTransparency=1},duration=60}
            wait(60)
            boss.safe=false
        end}
        local width,height=500,600
        local gap=800
        local center1,dir1=geo:rThetaGoRef(posp,100,dir0-math.pi/2)
        local centers={center1,geo:rThetaGoRef(center1,gap,dir1+math.pi/2)}
        wait(1)
        -- border bullets
        for i=1,2 do
            local center=centers[i]
            local r,l=Portal.segment(center,dir1,width/2)
            local rd,ru=Portal.segment(r,dir1+math.pi/2,height/2)
            local ld,lu=Portal.segment(l,dir1+math.pi/2,height/2)
            local poses={ru,rd,ld,lu}
            for j=1,4 do
                local pos1,pos2=poses[j],poses[j%4+1]
                local midPoints=DanmakuFuncs.midPoints(pos1,pos2,20)
                for z=1,#midPoints-1 do
                    local midPoint=midPoints[z]
                    Bullet{kinematicState={pos=midPoint,dir=dir1,speed=0,skipPortal=true},sprite=BulletSprites.flame[i==1 and 'yellow' or 'white'],invincible=true,highlight=true,size=1.5,lifeFrame=9999,extraUpdate={Action.FadeIn(30,false)}}
                end
            end
        end
        local currentSide=0
        local player=G.runInfo.player
        local function posWrap(pos,side)
            return {x=math.modClamp(pos.x,posp.x+side*gap,gap/2),y=pos.y}
        end
        local mainSentry=DanmakuFuncs.sentry(posp)
        local shrinking=true -- false means portal grows
        if DIFF()<=G.NORMAL then -- shrinking=false is more difficult as player is teleported at the moment of open, and has very limited view of the current side. but by adding shockwave to clear bullets for a while it should be fine for easy and normal
            shrinking=false
        end
        local canvasOffsetValue=500
        Portal.canvasOffset.x=-canvasOffsetValue
        local function open()
            local portals={}
            local pos0=copyTable(player.kinematicState.pos)
            local dir0=G.runInfo.player.viewDirection
            local r=10
            local rmin,dr=r,270
            if shrinking then
                r=rmin+dr
            end
            local angle=0
            local t=300
            local sideRef=currentSide
            Event.LoopEvent{obj=mainSentry,period=1,times=t,executeFunc=function (self,times)
                local progress=(times+1)/t
                if shrinking then -- both reduce small r time
                    progress=Event.sineIProgressFunc(progress)
                else
                    progress=Event.sineOProgressFunc(progress)
                end
                r=shrinking and (rmin+(1-progress)*dr) or rmin+progress*dr
                angle=math.mod2Sign(sideRef)*Event.sineIOProgressFunc(progress)*math.pi
                if times+1==t and shrinking then
                    player.kinematicState.pos=posWrap(player.kinematicState.pos,1-sideRef)
                    Portal.canvasOffset.x=canvasOffsetValue*math.mod2Sign(sideRef)
                end
            end}
            if not shrinking then -- teleport now, switch side
                player.kinematicState.pos=posWrap(pos0,1-sideRef)
                Portal.canvasOffset.x=canvasOffsetValue*math.mod2Sign(sideRef)
                player.invincibleFrame=player.invincibleFrame+20
                Effect.Shockwave{kinematicState={pos=posWrap(pos0,1-sideRef),dir=0,speed=0,skipPortal=true},lifeFrame=60,radius=3,growSpeed=0,spriteTransparency=1,color=sideRef==0 and 'gray' or 'yellow',canRemove={bullet=true}}:bindState(player)
            end
            for side=0,1 do
                local posSide=posWrap(pos0,side)
                local sign=((sideRef==side)~=shrinking) and 1 or -1
                for i=1,4 do
                    local dir=math.pi/2*(i+side*2)
                    local sentry=DanmakuFuncs.PortalOnSentry(posSide,dir,r,r*sign,side==0,nil,{lifeFrame=t,draw=true,range=0.1})
                    if side==0 then
                        portals[i]=sentry.any.portal
                    else
                        portals[i]:link(sentry.any.portal)
                    end
                    Event.LoopEvent{obj=sentry,period=1,executeFunc=function ()
                        sentry.any.length=r
                        sentry.any.width=r*sign
                        sentry.kinematicState.dir=angle+dir
                        sentry.kinematicState.pos=posWrap(player.kinematicState.pos,side)
                    end}
                end
            end
            currentSide=1-currentSide
        end
        local function openprep()
            if not shrinking then
                SFX:play('enemyCharge')
            end
            wait(60)
            if not shrinking then
                SFX:play('enemyPowerfulShot')
            end
            open()
        end
        local function bulletSideUpdate(self)
            local side=self.side
            local center=centers[side+1]
            local pos=self.kinematicState.pos
            if pos.x<center.x-width/2 or pos.x>center.x+width/2 or pos.y<center.y-height/2 or pos.y>center.y+height/2 then
                if not self.flag then
                    self.flag=true
                    self.lifeFrame=self.frame+20
                end
            end
        end
        local function leftSide(side)
            local center=centers[side+1]
            local posSpawn=geo:rThetaGoRef(center,150,dir0-math.pi/2)
            local function bombUpdate(self)
                self.kinematicState.speed=self.kinematicState.speed*0.97
                if self.frame+60>self.lifeFrame then
                    local ratio=(self.frame+60-self.lifeFrame)/60
                    self.spriteColor={1,1-ratio,1-ratio,1}
                end
                if self.frame==self.lifeFrame-1 then
                    -- aimed attack
                    SFX:play('enemyPowerfulShot',true,0.5)
                    local playerPos=posWrap(player.kinematicState.pos,side)
                    local dir=geo:toRef(self.kinematicState.pos,playerPos)
                    BulletSpawner{kinematicState={pos=copyTable(self.kinematicState.pos),dir=0,speed=0},lifeFrame=3,firstPeriod=1,period=9,bulletNumber=15,bulletSpeed=150,bulletLifeFrame=600,range=math.pi/12,angle=dir,bulletSprite=BulletSprites.round.yellow,highlight=true,bulletSize=1,bulletEvents={function (cir,args,self)
                        cir.kinematicState.skipPortal=true
                        cir.side=side
                        cir.kinematicState.speed=cir.kinematicState.speed+math.eval(0,DSWITCH{50,75,100,100})
                        local sprite=math.random(1,4)
                        if sprite==2 then
                            cir:changeSprite(BulletSprites.bigRound.yellow)
                        elseif sprite==3 then
                            cir:changeSprite(BulletSprites.giant.yellow)
                        else
                            cir:changeSprite(BulletSprites.lightRound.yellow)
                        end
                    end},bulletExtraUpdate={Action.FadeOut(20,true),bulletSideUpdate}}
                    -- falling attack
                    local sign=math.randomSign()
                    BulletSpawner{kinematicState={pos=copyTable(self.kinematicState.pos),dir=0,speed=0},lifeFrame=50,firstPeriod=1,period=10,bulletNumber=10,bulletSpeed=150,bulletLifeFrame=600,range=math.pi*2,angle=math.eval(0,99),bulletSprite=BulletSprites.rice.yellow,bulletEvents={function (cir,args,self)
                        cir.kinematicState.skipPortal=true
                        if args.index==1 then
                            self.angle=self.angle+sign*0.03
                        end
                        cir.side=side
                    end},bulletExtraUpdate={Action.FadeOut(20,true),bulletSideUpdate,function(self)
                        local vx,vy=math.rTheta2xy(self.kinematicState.speed,self.kinematicState.dir)
                        vy=vy+1
                        self.kinematicState.speed,self.kinematicState.dir=math.xy2rTheta(vx,vy)
                    end}}
                end
            end
            local function spawn()
                local speed=math.eval(200,100)
                local dir=math.eval(dir0+math.pi/2,math.pi*2/3)
                SFX:play('enemyShot')
                local bomb=Bullet{kinematicState={pos=copyTable(posSpawn),dir=dir,speed=speed},sprite=BulletSprites.giant.yellow,lifeFrame=120,size=2,extraUpdate={Action.ZoomIn(20),Action.FadeOut(5,true),bombUpdate}}
            end
            for i=1,20 do
                local n=math.ceil(i/4)
                for j=1,n do
                    spawn()
                    wait(20)
                end
                wait(120)
            end
        end
        local function rightSide(side)
            local center=centers[side+1]
            local posSpawn=geo:rThetaGoRef(center,150,dir0-math.pi/2)
            local sign=math.randomSign()
            local spawner2Args={lifeFrame=9999,firstPeriod=1,period=20,bulletNumber=3,bulletSpeed=80,bulletLifeFrame=600,range=DSWITCH{0,'<',math.pi*2,'<'},angle=0,useRelativeAngle=true,bulletSprite=BulletSprites.rim.white,bulletSize=1,bulletExtraUpdate={Action.ZoomIn(10),Action.FadeOut(20,true),bulletSideUpdate},bulletEvents={function (cir,args)
                if DIFF()<=G.NORMAL then
                    cir.kinematicState.speed=cir.kinematicState.speed-args.index*10
                end
                cir.kinematicState.skipPortal=true
                cir.side=side
            end}}
            local spawner=BulletSpawner{kinematicState={pos=copyTable(posSpawn),dir=0,speed=0,skipPortal=true},lifeFrame=9999,firstPeriod=1,period=75,bulletNumber=2,bulletSpeed=150,bulletLifeFrame=600,range=math.pi*2,angle='0+999',bulletSprite=BulletSprites.rimDark.black,bulletSize=3,bulletEvents={function (cir,args,self)
                cir.kinematicState.skipPortal=true
                cir.side=side
                cir.sign=math.randomSign()
                local spawner2=BulletSpawner(spawner2Args)
                spawner2:bindState(cir)
            end},bulletExtraUpdate={Action.ZoomIn(30),Action.FadeOut(20,true),bulletSideUpdate,function(self)
                self.kinematicState.dir=self.kinematicState.dir+self.sign*0.005
                -- if self.flag and not self.f0 then
                --     local pos,dir=geo:rThetaGoRef(self.kinematicState.pos,20,self.kinematicState.dir+math.pi)
                --     dir=dir+math.eval(0,0.7)
                -- end
            end}}
            wait(450)
            spawner.bulletNumber=3
            wait(450)
            if DIFF()>=G.HARD then
                spawner.bulletNumber=4
            end
            wait(450)
            if DIFF()>=G.LUNATIC then
                spawner.bulletNumber=5
            end
        end
        Event{obj=mainSentry,action=function ()
            leftSide(0)
        end}
        Event{obj=mainSentry,action=function ()
            rightSide(1)
        end}
        wait(60)
        for i=1,7 do
            openprep()
            wait(150)
        end
    end
}