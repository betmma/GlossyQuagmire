---@return SpellcardPhase
return BossManager.SpellcardPhase{
    key='shouji-scenery',
    bonusScore=25000,
    time=1200,
    isTimeout=true,
    hp=4000,
    dropItems={powerSmall=15,point=15},
    func=function(self, boss)
        if DIFF()>=G.HARD then -- 10 seconds longer for hard and lunatic
            self.remainingFrames=self.remainingFrames+600
        end
        boss.showHexagram=false
        local geo=G.runInfo.geometry
        ---@cast geo PortalGeometryBase
        local posp=copyTable(G.runInfo.player.kinematicState.pos)
        local dir0=G.runInfo.player.viewDirection
        local sentry=DanmakuFuncs.sentry(posp)
        Portal.setOuterPortals(posp)
        Portal.zoomC=40
        local bossPos=geo:rThetaGo(posp,200,dir0-math.pi/2)
        DanmakuFuncs.moveToInTime(boss,bossPos,60)
        SFX:play('enemyPowerfulShot')
        -- build portals
        local r0=75
        local vertexData,vertexPoses
        local posC=copyTable(posp)
        local portalShapeD=DIFF()==G.EASY or DIFF()==G.LUNATIC
        if portalShapeD then
            vertexData={{r0,0},{r0,math.pi/3},{r0,math.pi*2/3},{r0,math.pi*4/3}}
        else
            vertexData={{r0,-math.pi/6},{r0,math.pi/6},{r0,math.pi/2},{r0,math.pi*5/6}}
            posC=geo:rThetaGo(posp,r0/5,-math.pi*2/3)
        end
        vertexPoses={}
        for i,vertex in pairs(vertexData) do
            local pos,dir=geo:rThetaGo(posC,vertex[1],vertex[2]+dir0)
            vertexPoses[i]=pos
        end
        local portals={}
        for i=1,#vertexPoses do
            local pos1=vertexPoses[i]
            local pos2=vertexPoses[(i%#vertexPoses)+1]
            local swap=false
            swap=i>2
            if swap then
                pos1,pos2=pos2,pos1
            end
            local dir=geo:toRef(pos1,pos2)
            local dir2=geo:toRef(pos2,pos1)
            local dist=geo:distanceRef(pos1,pos2)
            local getPoses=function(self)
                local t=self.frame
                local ratio=math.clamp(t/30,0.01,0.7)
                local p1=geo:rThetaGoRef(pos2,dist*(0.5+ratio),dir2)
                local p2=geo:rThetaGoRef(pos1,dist*(0.5+ratio),dir)
                return p1,p2
            end
            local p1,p2=getPoses({frame=0})
            local portal=Portal(p1,p2,posp,{range=40,draw=false,color={1,0,0,0.5},width=5,lifeFrame=9999,extraUpdate={function (self)
                if sentry.removed then
                    self:remove()
                end
                local pos1,pos2=getPoses(self)
                self:set(pos1,pos2)
            end}})
            table.insert(portals,portal)
        end
        portals[1]:link(portals[3])
        portals[2]:link(portals[4])
        -- spawn the fairy
        local fairyPos=geo:rThetaGo(posp,35,math.pi/3)
        local warning=Bullet{kinematicState={pos=fairyPos,dir=0,speed=0},sprite=BulletSprites.giant.white,lifeFrame=120,invincible=true,safe=true,size=1,extraUpdate={Action.ZoomIn(30,0.5,2),Action.FadeIn(30,false),Action.FadeOut(30,false)},spriteColor={1,0,0,0.9},highlight=false}
        wait(90)
        local bulletSpawner
        if DIFF()<=G.NORMAL then -- rope
            local orb=Bullet{kinematicState={pos=copyTable(fairyPos),dir=math.pi/3+math.eval(1,0.5)*math.randomSign()/100,speed=0},sprite=BulletSprites.giant.red,lifeFrame=9999,invincible=true,size=1,extraUpdate={Action.ZoomIn(30,0.3,1),Action.FadeIn(30,false),Action.FadeOut(30,false)},highlight=false}
            bulletSpawner=BulletSpawner{period=6,firstPeriod=60,lifeFrame=9999,bulletLifeFrame=DSWITCH{300,400,'<','<'},bulletSprite=BulletSprites.round.red,bulletSpeed=90,bulletNumber=1,useRelativeAngle=true,angle=0,bulletEvents={function(cir,args,self)
                if self.spawnTimes%6~=0 then
                    cir:changeSprite(BulletSprites.dot.red)
                    cir.spriteColor={1,0.2,0.2,0.5}
                    cir.safe=true
                end
            end},bulletExtraUpdate={Action.ZoomOut(30),function(self)
                if self.frame+60>self.lifeFrame then
                    self.kinematicState.speed=math.lerp(self.kinematicState.speed,0,0.05)
                else
                    self.kinematicState.speed=math.lerp(self.kinematicState.speed,30,0.003)
                end
            end}}
            Event{obj=orb,action=function ()
                wait(120)
                SFX:play('enemyPowerfulShot')
                for i=1,600 do
                    orb.kinematicState.speed=orb.kinematicState.speed+0.15
                    wait(1)
                end
            end}
            Event{obj=bulletSpawner,action=function ()
                for i=1,10 do
                    Event.EaseEvent{obj=bulletSpawner,aims={angle=bulletSpawner.angle+math.pi/99*math.mod2Sign(i)},duration=300,progressFunc=Event.sineBackProgressFunc}
                    wait(300)
                end
            end}
            bulletSpawner:bindState(orb)
        else -- triangle
            local dir=math.eval(0,99)
            local orbs={}
            local maxZoom=1
            for i=1,3 do
                local speed=0
                local angle=dir+math.pi*2/3*(i-1)
                local flagRemove=false
                local orb=Bullet{kinematicState={pos=copyTable(fairyPos),dir=angle,speed=50},sprite=BulletSprites.giant.red,lifeFrame=9999,invincible=true,highlight=true,size=1,extraUpdate={Action.ZoomIn(30,0.3,1),Action.FadeIn(30,false),Action.FadeOut(30,false),function (self)
                    if flagRemove then
                        self.safe=true
                        self.spriteTransparency=math.lerp(self.spriteTransparency,0.5,0.1)
                    else
                        self.safe=false
                        self.spriteTransparency=math.lerp(self.spriteTransparency,1,0.1)
                    end
                    local zoom=Portal.zoomFactor(self.kinematicState.pos)
                    local lastZoom=self.lastZoom or zoom
                    local delta=zoom/lastZoom
                    if math.abs(math.log(delta))>0.2 then -- crossed a portal, zoom factor changed much
                        self.ratio=self.ratio*delta
                    end
                    self.lastZoom=zoom
                    self.ratioTimesZoom=self.ratio/zoom
                    -- self.size=self.ratioTimesZoom*0.5
                    self.kinematicState.speed=speed*self.ratioTimesZoom/maxZoom
                end}}
                orb.ratio=1
                table.insert(orbs,orb)
                bulletSpawner=BulletSpawner{period=6,firstPeriod=60,lifeFrame=9999,bulletLifeFrame=300,bulletSprite=BulletSprites.scale.red,highlight=true,bulletSpeed=90,bulletNumber=2,useRelativeAngle=true,angle=math.pi,range=math.pi*2/3,bulletEvents={function(cir,args,self)
                    local h=(i-2)*0.2
                    if self.spawnTimes%6~=0 then
                        cir:changeSprite(BulletSprites.stick.red)
                        local r,g,b=math.hsvToRgb(h,0.8,1)
                        cir.spriteColor={r,g,b,0.5}
                        cir.kinematicState.speed=cir.kinematicState.speed*1.5
                        cir.safe=true
                    else
                        local r,g,b=math.hsvToRgb(h,0.2,1)
                        cir.spriteColor={r,g,b,1}
                    end
                    cir.targetOrbIndex=(i-1+(args.index==1 and 1 or -1))%3+1
                end},bulletExtraUpdate={function(self)
                    if self.frame+60>self.lifeFrame then
                        self.kinematicState.speed=math.lerp(self.kinematicState.speed,0,0.05)
                    else
                        self.kinematicState.speed=math.lerp(self.kinematicState.speed,30,0.003)
                    end
                    if flagRemove then
                        self.safe=true
                        self.spriteTransparency=math.lerp(self.spriteTransparency,0,0.1)
                        if self.spriteTransparency<0.05 then
                            self:remove()
                        end
                    end
                    if self.targetOrbIndex and self.frame%2==0 then
                        local orbt=orbs[self.targetOrbIndex]
                        if geo:distanceRef(self.kinematicState.pos,orbt.kinematicState.pos)<5 then
                            self:remove()
                        end
                    end
                end}}
                bulletSpawner:bindState(orb)
                local warningArrow=Bullet{sprite=BulletSprites.scale.red,lifeFrame=9999,invincible=true,highlight=true,safe=true,extraUpdate={function (self)
                    if flagRemove then
                        self.safe=true
                        self.spriteTransparency=math.lerp(self.spriteTransparency,0.5,0.1)
                    else
                        self.safe=false
                        self.spriteTransparency=math.lerp(self.spriteTransparency,1,0.1)
                    end
                end}}
                warningArrow:bindState(orb)
                Event{obj=orb,action=function ()
                    for i=1,7 do
                        SFX:play('enemyPowerfulShot')
                        flagRemove=true
                        for t=1,40 do
                            speed=(i*30+50)*DSWITCH{0.5,0.6,0.7,1}*math.sin(math.pi*t/40)
                            wait()
                        end
                        speed=0
                        wait(20)
                        flagRemove=false
                        wait(160)
                        if i>=5 then
                            wait((i-4)*40)
                        end
                    end
                end}
            end
            Event.LoopEvent{obj=sentry,period=1,executeFunc=function (event,dt)
                maxZoom=0
                for _,orb in pairs(orbs) do
                    maxZoom=math.max(maxZoom,orb.ratioTimesZoom)
                end
            end}
        end
    end
}