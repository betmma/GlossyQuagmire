---@return SpellcardPhase
return BossManager.LastSpellcardPhase{
    key='enri-rotate',
    bonusScore=200000,
    time=7200,
    hp=6000,
    dropItems={point=0}, -- no time to collect
    func=function (self, boss)
        local geo=G.runInfo.geometry
        ---@cast geo Spherical
        local radius=geo.radius
        ---@cast geo GeometryBase
        local player=G.runInfo.player
        local viewDirection=player.viewDirection
        local r1=radius*(math.pi/2-math.asin(3^-0.5))
        local pos1,dir1=geo:rThetaGo(player.kinematicState.pos,r1,viewDirection-math.pi/4)
        local sentry=DanmakuFuncs.sentry(pos1)
        sentry.kinematicState.dir=dir1+math.pi
        local offset=0
        Event.LoopEvent{obj=sentry,period=1,executeFunc=function ()
            local aimPos=geo:rThetaGo(sentry.kinematicState.pos,r1,sentry.kinematicState.dir+math.pi*2/3)
            local r,theta=geo:rThetaTo(boss.kinematicState.pos,aimPos)
            boss.kinematicState.pos=geo:rThetaGo(boss.kinematicState.pos,r*0.02,theta)
        end}
        Event.LoopEvent{obj=sentry,period=180,executeFunc=function ()
            local rand=math.eval(0,0.8)-offset*0.5
            offset=offset+rand
            Event.EaseEvent{obj=sentry,easeObj=sentry.kinematicState,aims={speed=DSWITCH{0,10,20,30},dir=sentry.kinematicState.dir+rand},duration=180,progressFunc=Event.sineIOProgressFunc}
        end}
        local function follow(self)
            local parent,r,angle=self.any.parent,self.any.r,self.any.angle
            self.kinematicState.pos,self.kinematicState.dir=geo:rThetaGo(parent.kinematicState.pos,r,angle+parent.kinematicState.dir)
        end
        local signal=-1
        local duration=420
        local n1,n2,n3=DSWITCH{25,30,35,40},DSWITCH{20,25,30,35},10
        local function getTargetR(self,enableInside)
            local sentryi=self.any.parent
            local r=self.any.r
            local unit=math.pi/2*radius
            local mod=r%unit
            local direction=math.mod2Sign(math.ceil(r/unit)) -- initial is -1
            local flip=direction*(sentryi.any.playerInside and enableInside and 1 or -1)
            local moveDistance=(flip==1 and unit-mod or -mod)*2
            return r+moveDistance
        end
        local layerUpdates={
            function(self)
                self.any.angle=self.any.angle+math.pi/360
                if signal==self.any.i and not self.any.moving then
                    self.any.moving=true
                    self:changeSpriteColor('purple')
                    Event.EaseEvent{obj=self,easeObj=self.any,aims={r=getTargetR(self,true)},duration=duration,progressFunc=Event.sineIOProgressFunc,afterFunc=function ()
                        self.any.moving=false
                        self:changeSpriteColor('blue')
                    end}
                    -- change same group bullets from same r different angle to less different angle different r during movement
                    local group=5
                    local offset=self.any.j%group-group/2+0.5
                    local r=self.any.r
                    local unit=math.pi/2*radius
                    local sign=math.mod2Sign(math.ceil(r/unit))
                    -- DIFF()>G.LUNATIC and -1 or 1 thing flips the angle of moving group. at regular difficulties bullets form a row -> but for overdrive it becomes |>
                    Event.EaseEvent{obj=self,easeObj=self.any,aims={r=self.any.r-offset*10*sign*(DIFF()>G.LUNATIC and -1 or 1),angle=self.any.angle-offset*math.pi*2/n1*(1-0.3)},duration=duration,progressFunc=function (x)
                        local v=math.min(x*5,(1-x)*5,1)
                        return Event.sineIOProgressFunc(v)
                    end}
                end
            end,
            function(self)
                self.any.angle=self.any.angle-math.pi/360
                if signal==self.any.i and not self.any.moving then
                    self.any.moving=true
                    self:changeSpriteColor('purple')
                    local ratio=self.any.j/n2
                    local delayRatio=0.2
                    Event.EaseEvent{obj=self,easeObj=self.any,aims={r=getTargetR(self)},duration=duration,progressFunc=function (x)
                        local v=math.clamp(x*(1+delayRatio)-(math.sin(ratio*math.pi*8)*0.5+0.5)*delayRatio,0,1)
                        return Event.sineIOProgressFunc(v)
                    end,afterFunc=function ()
                        self.any.moving=false
                        self:changeSpriteColor('blue')
                    end}
                end
            end,
            function(self)
                self.any.angle=self.any.angle-math.pi/120
                if signal==self.any.i and not self.any.moving then
                    self.any.moving=true
                    self:changeSpriteColor('purple')
                    Event.EaseEvent{obj=self,easeObj=self.any,aims={r=0},duration=duration,progressFunc=Event.sineBackProgressFunc,afterFunc=function ()
                        self.any.moving=false
                        self:changeSpriteColor('blue')
                    end}
                end
            end
        }
        local extraUpdates={Action.ZoomIn(30,1,3,true),Action.FadeIn(60,true),follow,}
        local layerExtraUpdates={}
        for index, value in ipairs(layerUpdates) do
            local new=copyTable(extraUpdates)
            table.insert(new,value)
            table.insert(layerExtraUpdates,new)
        end
        -- six points from the sentry, 3 points r=radius*asin(3^-0.5), angle evenly scattered, and their antipodal points
        local sentries={}
        for i=1,6 do
            local angle=math.pi*2/3*i
            local r=r1
            if i>3 then
                r=radius*math.pi-r
                angle=angle+math.pi
            end
            local posi=geo:rThetaGo(sentry.kinematicState.pos,r,angle)
            local sentryi=DanmakuFuncs.sentry(posi)
            sentryi.any={r=r,angle=angle,parent=sentry,playerInside=false}
            table.insert(sentryi.extraUpdate,follow)
            table.insert(sentryi.extraUpdate,function (self)
                local distance=geo:distance(self.kinematicState.pos,player.kinematicState.pos)
                self.any.playerInside=distance<r1 or distance>(math.pi*radius-r1)
            end)
            table.insert(sentries,sentryi)
        end
        local layerFuncs={
            function ()
                duration=DSWITCH{300,280,230,200}
                SFX:play('enemyPowerfulShot')
                for i=1,#sentries do
                    local sentryi=sentries[i]
                    for j=1,n1 do
                        local angle2=j/n1*math.pi*2
                        local rj=math.pi/4*radius
                        local posj=geo:rThetaGo(sentryi.kinematicState.pos,rj,angle2)
                        local bullet=Bullet{kinematicState={pos=posj,dir=0,speed=0},sprite=BulletSprites.round.blue,lifeFrame=9999,extraUpdate=layerExtraUpdates[1]}
                        bullet.any={r=rj,angle=angle2,parent=sentryi,i=i%3,j=j}
                    end
                end
            end,
            function ()
                duration=DSWITCH{600,540,480,420}
                SFX:play('enemyPowerfulShot')
                for i=1,#sentries do
                    local sentryi=sentries[i]
                    for j=1,n2 do
                        local angle2=j/n2*math.pi*2
                        local rj=math.pi/4*0.9*radius
                        local posj=geo:rThetaGo(sentryi.kinematicState.pos,rj,angle2)
                        local bullet=Bullet{kinematicState={pos=posj,dir=0,speed=0},sprite=BulletSprites.bigRound.blue,lifeFrame=9999,extraUpdate=layerExtraUpdates[2]}
                        bullet.any={r=rj,angle=angle2,parent=sentryi,i=i%3,j=j}
                    end
                end
            end,
            function ()
                duration=DSWITCH{720,660,600,540}
                SFX:play('enemyPowerfulShot')
                for i=1,#sentries do
                    local sentryi=sentries[i]
                    local angle0=math.eval(0,math.pi)
                    for k=1,2 do
                        local anglek=math.pi*k+angle0
                        local rk=math.pi/4*radius*0.4
                        local posk,dirk=geo:rThetaGo(sentryi.kinematicState.pos,rk,anglek)
                        local sentryk=DanmakuFuncs.sentry(posk)
                        sentryk.any={r=rk,angle=anglek,parent=sentryi,i=i%3}
                        sentryk.extraUpdate={
                            follow,
                            function(self)
                                self.any.angle=self.any.angle+math.pi/360
                                self.safe=true
                                if signal==self.any.i and not self.any.moving then
                                    self.any.moving=true
                                    Event.EaseEvent{obj=self,easeObj=self.any,aims={r=getTargetR(self,false)},duration=duration,progressFunc=Event.sineIOProgressFunc,afterFunc=function ()
                                        self.any.moving=false
                                    end}
                                end
                            end
                        }
                        for j=1,n3 do
                            local angle2=j/n3*math.pi*2
                            local rj=math.pi/4*radius*DSWITCH{0.2,0.2,0.25,0.3}
                            local posj=geo:rThetaGo(posk,rj,angle2+dirk)
                            local bullet=Bullet{kinematicState={pos=posj,dir=0,speed=0},sprite=BulletSprites.lightRound.blue,lifeFrame=9999,extraUpdate=layerExtraUpdates[3],highlight=true}
                            bullet.any={r=rj,angle=angle2,parent=sentryk,i=i%3,j=j}
                        end
                    end
                end
            end,
        }
        layerFuncs[1]()
        -- layerFuncs[2]()
        -- layerFuncs[3]()
        local framePassed=0
        local loopFunc=function (self, index, total)
            SFX:play('enemyShot2')
            framePassed=sentry.frame
            signal=index%3
            wait()
            signal=-1
        end
        local previousLoopEvent=Event.LoopEvent{obj=sentry,period=duration*5/9,firstPeriod=120,executeFunc=loopFunc}
        boss.hpSegments={0.75,0.45}
        boss:addHPProtection(300,10)
        boss.hpSegmentsFunc=function (self,hplevel)
            self:addHPProtection(300,10)
            layerFuncs[hplevel+1]()
            previousLoopEvent:remove()
            previousLoopEvent=Event.LoopEvent{obj=sentry,period=duration*5/9,firstPeriod=duration*5/9-(sentry.frame-framePassed),executeFunc=loopFunc}
        end
    end
}