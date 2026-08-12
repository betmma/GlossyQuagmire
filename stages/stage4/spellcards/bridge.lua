---@return SpellcardPhase
return BossManager.SpellcardPhase{
    key='shouji-bridge',SKIP_INCLUDE=true,
    bonusScore=25000,
    time=1800,
    hp=4600,
    dropItems={bomb=1},
    func=function(self, boss)
        boss.showHexagram=false
        local geo=G.runInfo.geometry
        ---@cast geo PortalGeometryBase
        local posp=G.runInfo.player.kinematicState.pos
        Portal.setOuterPortals(posp)
        local width,height=30,200
        local dir0=G.runInfo.player.viewDirection
        local posb,dirb=geo:rThetaGoRef(posp,height+50,dir0-math.pi/2)
        DanmakuFuncs.moveToInTime(boss,posb,60,Event.sineOProgressFunc,true)
        local posr,dirr=geo:rThetaGoRef(posp,width,dir0)
        local posl,dirl=geo:rThetaGoRef(posp,-width,dir0)
        local colors={'blue','orange','red','purple'}
        local color=colors[DSWITCH{1,2,3,4}]
        -- flame walls and portals
        local offsets={{y=0,size=0},{y=0,size=0}}
        local function getSeg(side)
            local pos,dir=posr,dirr
            if side==2 then
                pos,dir=posl,dirl
            end
            local offset=offsets[side]
            local posb1,dirb1=geo:rThetaGoRef(pos,offset.y*(1+offset.size),dir+math.pi/2)
            return posb1,dirb1-math.pi/2,height*(1+offset.size)
        end
        local wallUpdateFunc=function(self)
            local pos,dir,len=getSeg(self.side2)
            local pos2=geo:rThetaGoRef(pos,len+self.extraLen,dir+math.pi/2*self.side)
            self.kinematicState.pos=pos2
        end
        for side=-1,1,2 do
            local flameColor=color
            if DIFF()==G.LUNATIC and G.save.options.language=='zh_cn' then -- fit the Chinese name 二河白道
                flameColor=side==-1 and 'red' or 'blue'
                color='white'
            end
            for i=0,DSWITCH{12,12,18,18} do
                local pos1,pos2=geo:rThetaGoRef(posr,height+i*10,dirr+math.pi/2*side),geo:rThetaGoRef(posl,height+i*10,dirl+math.pi/2*side)
                local midPoints,dirs=DanmakuFuncs.midPoints(pos1,pos2,nil,i==DSWITCH{6,6,9,9} and 10 or 1)
                for j,midPos in ipairs(midPoints) do
                    local side2=0
                    if j==1 then
                        side2=1
                    elseif j==#midPoints then
                        side2=2
                    end
                    local zoomTime=10+math.abs(j-6)*3+i*5
                    local bullet=Bullet{kinematicState={pos=midPos,dir=dirs[j],speed=0},sprite=BulletSprites.flame[flameColor],lifeFrame=99999,invincible=true,extraUpdate={Action.ZoomIn(zoomTime),Action.FadeIn(20,false),Action.FadeOut(30,false),side2>0 and wallUpdateFunc or nil},highlight=true}
                    if side2>0 then
                        bullet.side=side
                        bullet.side2=side2
                        bullet.extraLen=i*10
                    end
                end
            end
        end
        local sentry=DanmakuFuncs.sentry(posp)
        local portals={}
        for i=1,2 do
            local pos,dir=posr,dirr
            if i==2 then
                pos,dir=posl,dirl
            end
            local pa,pb=Portal.segment(pos,dir,height*0.05)
            local portalArgs={range=20,draw=true,width=5,color={1,0.5,0.5,0.5},lifeFrame=99999,extraUpdate={Action.FadeIn(20,false),Action.FadeOut(15,false),function (self)
                if sentry.removed then
                    self:remove()
                end
                local ratio=self.args.ratio or 0.05
                if self.frame+20>self.lifeFrame then
                    ratio=1-(self.frame+20-self.lifeFrame)/21
                end
                if self.frame<20 then
                    ratio=math.clamp(self.frame/20+0.05,0,1)
                end
                self.args.ratio=ratio
                local posi,diri,leni=getSeg(i)
                local pa,pb=Portal.segment(posi,diri,leni*ratio)
                self:set(pa,pb)
            end}}
            local portal=Portal(pa,pb,posp,portalArgs)
            table.insert(portals,portal)
        end
        local lifeRatio=DSWITCH{1,1,1,45/32}
        local bulletSpawner=BulletSpawner{kinematicState={pos=posb,dir=0,speed=0},lifeFrame=99999,period=72,firstPeriod=math.eval(30,15),bulletNumber=1,bulletSprite=BulletSprites.lightRound[color],bulletLifeFrame=300*lifeRatio,bulletSpeed=150/lifeRatio,angle=dirb+math.pi,bulletExtraUpdate={Action.ZoomIn(20,2),Action.ZoomOut(20)},highlight=true}
        Event{obj=sentry,action=function ()
            if DIFF()==G.EASY then
                for i=1,20 do
                    SFX:play('enemyCharge')
                    wait(60)
                    SFX:play('enemyPowerfulShot')
                    local sign=math.mod2Sign(i)
                    for j=1,2 do
                        Event.EaseEvent{obj=sentry,easeObj=offsets[j],aims={y=60*sign*math.mod2Sign(j)},duration=60,progressFunc=Event.sineOProgressFunc}
                    end
                    wait(180)
                end
            elseif DIFF()==G.NORMAL then
                SFX:play('enemyCharge')
                wait(60)
                SFX:play('enemyPowerfulShot')
                Event.LoopEvent{obj=sentry,period=180,firstPeriod=0,times=20,executeFunc=function(self,i)
                    local sign=math.mod2Sign(i)
                    for j=1,2 do
                        Event.EaseEvent{obj=sentry,easeObj=offsets[j],aims={y=60*sign*math.mod2Sign(j)},duration=180,progressFunc=Event.sineBackProgressFunc}
                    end
                end}
            elseif DIFF()==G.HARD then
                SFX:play('enemyCharge')
                wait(60)
                SFX:play('enemyPowerfulShot')
                Event.LoopEvent{obj=sentry,period=180,firstPeriod=0,times=20,executeFunc=function(self,i)
                    local sign=math.mod2Sign(i)
                    for j=1,2 do
                        Event.EaseEvent{obj=sentry,easeObj=offsets[j],aims={y=30*sign*math.mod2Sign(j),size=0.3*sign*math.mod2Sign(j)},duration=180,progressFunc=Event.sineBackProgressFunc}
                    end
                end}
            else
                SFX:play('enemyCharge')
                wait(60)
                SFX:play('enemyPowerfulShot')
                local period1=math.ceil(math.eval(120,20))
                local period2=math.ceil(math.eval(180,30))
                Event.LoopEvent{obj=sentry,period=period1,firstPeriod=0,times=20,executeFunc=function(self,i)
                    local sign=math.mod2Sign(i)
                    for j=1,2 do
                        Event.EaseEvent{obj=sentry,easeObj=offsets[j],aims={y=40*sign*math.mod2Sign(j)},duration=period1,progressFunc=Event.sineBackProgressFunc}
                    end
                end}
                Event.LoopEvent{obj=sentry,period=period2,firstPeriod=0,times=20,executeFunc=function(self,i)
                    local sign=math.mod2Sign(i)
                    for j=1,2 do
                        Event.EaseEvent{obj=sentry,easeObj=offsets[j],aims={size=0.3*sign*math.mod2Sign(j)},duration=period2,progressFunc=Event.sineBackProgressFunc}
                    end
                end}
            end
        end}
        portals[1]:link(portals[2])
    end
}