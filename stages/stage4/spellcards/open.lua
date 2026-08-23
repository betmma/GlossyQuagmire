---@return SpellcardPhase
return BossManager.SpellcardPhase{
    key='shouji-open',
    bonusScore=25000,
    time=2400,
    hp=5500,
    dropItems={powerSmall=15,point=15},
    func=function(self, boss)
        boss.showHexagram=false
        boss:addHPProtection(600,3)
        local geo=G.runInfo.geometry
        ---@cast geo PortalGeometryBase
        local posp=copyTable(G.runInfo.player.kinematicState.pos)
        local dir0=G.runInfo.player.viewDirection
        local outerPortals=Portal.setOuterPortals(posp)
        for i=1,#outerPortals do
            outerPortals[i]:remove()
            outerPortals[i]=nil
        end
        local posb,posd=geo:rThetaGo(posp,100,dir0-math.pi/2)
        DanmakuFuncs.moveToInTime(boss,posb,30)
        wait(30)
        local sentry=DanmakuFuncs.sentry(posb)
        local portalAngle=dir0
        local rotateSpeed=math.pi/480
        Event.LoopEvent{obj=sentry,period=1,executeFunc=function ()
            portalAngle=portalAngle+rotateSpeed
        end}
        local r=250
        local portals={}
        --[[1,1: 1-2 3-4 5-6 7-8
        1,5: 1-2 7-8 5-6 3-4
        4,1: 1-5 6-2 3-7 8-4]]
        for i=1,8 do
            local dir=i/8*math.pi*2
            local flipCond=i%2==1
            if DIFF()<=G.HARD then
                flipCond=i>4
            end
            local sentry=DanmakuFuncs.PortalOnSentry(copyTable(posb),dir+portalAngle,150,-r,flipCond,30,{range=100,draw=true,width=15},nil,nil)
            portals[i]=sentry.any.portal
            Event.LoopEvent{obj=sentry,period=1,executeFunc=function ()
                sentry.kinematicState.dir=dir+portalAngle
            end}
        end
        for i=1,4 do
            if DIFF()<=G.HARD then -- giant orbs always pass center, so its easier
                portals[i]:link(portals[i+4])
            else
                portals[i*2-1]:link(portals[i*2])
            end
        end
        local extraUpdate={Action.ZoomIn(20),Action.FadeOut(10,true),function (self)
            if self.frame<self.any.time0 then
                self.kinematicState.speed=self.any.periodSpeed*2*(1-self.frame/self.any.time0)
            elseif self.frame==self.any.time0 then
                self.safe=false
                self.spriteTransparency=1
                self.kinematicState.dir=self.kinematicState.dir+math.pi/2
                self.kinematicState.speed=self.any.periodSpeed
                self.kinematicState.pos=self.any.aim
            end
        end}
        local function shoot(period,startIndex,jumpNumber,extraAngle)
            local rotation=rotateSpeed*period
            local deltaAngle=math.modClamp(rotation+jumpNumber*math.pi*2/8)
            -- imagine the in portal is at left |  .
            local inAngle=math.pi/2-deltaAngle/2
            -- the bullet starts from boss, move to the midpoint of a chord, then move towards startIndex portal's center. first movement takes extraTime
            local time0=period/2/math.tan(deltaAngle/2) -- first movement and movement during half period forms a right triangle with central angle deltaAngle/2
            local timeTillFirstPeriod=time0+period/2
            local angleWhenFirstPeriodStart=portalAngle+rotateSpeed*timeTillFirstPeriod+startIndex*math.pi*2/8+extraAngle
            local realInAngle=angleWhenFirstPeriodStart+inAngle+math.pi
            local shootAngle=realInAngle-math.pi/2
            local periodSpeed=r*2*math.sin(deltaAngle/2)/period*60/math.cos(math.modClamp(deltaAngle,0,math.pi/8))
            if periodSpeed<0 then
                periodSpeed=-periodSpeed
                shootAngle=shootAngle+math.pi
            end
            local bullet=Bullet{kinematicState={pos=copyTable(posb),dir=shootAngle,speed=periodSpeed*2},sprite=BulletSprites.bullet.blue,spriteColor={math.min(1,240/period),1,1,1},lifeFrame=timeTillFirstPeriod+period*2,extraUpdate=extraUpdate,spriteTransparency=0.3,safe=true}
            bullet.any={periodSpeed=periodSpeed,time0=math.ceil(time0),aim=geo:rThetaGo(posb,periodSpeed*time0/60,shootAngle)}
        end
        local function batch(startIndex,jumpNumber)
            for period=240,360,120 do
                local n=1
                for i=1,n do
                    shoot(period,startIndex,jumpNumber,((i-0.5)/n-0.5)*math.pi/4)
                end
            end
        end
        Event.LoopEvent{obj=sentry,period=240,firstPeriod=120,executeFunc=function (self,times)
            SFX:play('enemyPowerfulShot')
            local num=2^math.clamp(times-DSWITCH{2,1,0,0},0,DSWITCH{0,1,2,3})
            if DIFF()==G.EASY and times%2==1 then
                -- skip giants
            else
                BulletSpawner{lifeFrame=50,period=40,bulletNumber=num,angle=geo:to(posb,G.runInfo.player.kinematicState.pos),bulletSprite=BulletSprites.giant.blue,highlight=true,bulletSpeed=100,bulletLifeFrame=600,bulletExtraUpdate={Action.FadeOut(20,true),Action.ZoomIn(20),Action.ZoomOut(20)}}:bindState(boss)
            end
            for i=1,8*DSWITCH{3,4,5,6} do
                local i2=i%8
                batch(i2,1)
                wait()
            end
        end}
    end
}