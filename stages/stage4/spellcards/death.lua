---@return SpellcardPhase
return BossManager.SpellcardPhase{
    key='shouji-death',
    bonusScore=25000,
    time=2880,
    hp=3000,
    dropItems={powerSmall=15,point=15},
    func=function(self, boss)
        boss.showHexagram=false
        boss:addHPProtection(960,10)
        local geo=G.runInfo.geometry
        ---@cast geo PortalGeometryBase
        for i=1,5 do
            local posp=copyTable(G.runInfo.player.kinematicState.pos)
            local dir0=G.runInfo.player.viewDirection
            posp=geo:rThetaGoRef(posp,100,dir0+math.pi/2)
            local sentry=DanmakuFuncs.sentry(posp)
            Portal.setOuterPortals(posp)
            SFX:play('enemyShot')
            local warningBullet=Bullet{kinematicState={pos=posp,dir=0,speed=0},sprite=BulletSprites.giant.white,lifeFrame=180,invincible=true,safe=true,size=1,extraUpdate={Action.ZoomIn(30,3,10),Action.FadeIn(30,false),Action.FadeOut(30,false)},spriteColor={1,1,0,0.5},highlight=true}
            wait(60)
            SFX:play('enemyCharge')
            local enemyPos=geo:rThetaGoRef(posp,350,dir0-math.pi/2)
            DanmakuFuncs.moveToInTime(boss,enemyPos,60,Event.sineOProgressFunc,true) -- prevent boss staying inside octagon and blocking paths
            wait(60)
            SFX:play('enemyPowerfulShot')
            local theta0=0
            local data={{r=0,theta=theta0,thickness=0,flag=0},{r=500,theta=theta0,thickness=0}}
            local function extraUpdate(self)
                local layer,theta,ratio=self.layer,self.theta,self.ratio
                if self.flag then
                    local offsetToMid=(theta-theta0)%(math.pi/4)
                    theta=(theta-theta0)-offsetToMid+math.pi/8+(offsetToMid-math.pi/8)*(1+data[1].flag)+theta0
                    ratio=ratio*data[1].flag
                end
                local r=data[layer].r
                local sign=-1--layer==1 and 1 or -1
                r=r+sign*data[layer].thickness*ratio
                local thetap=data[layer].theta
                r,thetap=math.polygonize(8,thetap+theta,r,thetap)
                local func=sentry.frame<300 and geo.rThetaGo or geo.rThetaGoRef
                if sentry.frame==300 then
                    self.kinematicState.skipPortal=true
                end
                local pos,dir=func(geo,sentry.kinematicState.pos,r,thetap)
                self.kinematicState.pos=pos
                self.kinematicState.dir=dir+math.pi*(layer-1)
            end
            for layer=1,2 do
                local life=900
                -- octagon
                BulletSpawner{kinematicState={pos=posp,dir=0,speed=0},period=9,firstPeriod=1,lifeFrame=2,bulletNumber=160,range=math.pi*2,angle=0,bulletSpeed=0,spawnCircleRadius=data[layer].r,spawnCircleAngle=data[layer].theta,bulletSprite=BulletSprites.flame.yellow,highlight=true,bulletLifeFrame=life,bulletExtraUpdate={Action.ZoomIn(30),Action.FadeOut(30,true),extraUpdate},bulletEvents={function(cir,args,self)
                    cir.layer=layer
                    cir.theta=args.index/160*math.pi*2
                    cir.ratio=0
                    if math.polygonize(8,cir.theta)<=math.polygonize(8,math.pi/16,nil,math.pi/8) and layer==1 then
                        cir.flag=true -- for center of each inner side to move inwards
                        cir.ratio=0.5
                    end
                end}}
                -- radial lines
                local n,exceedN=5,0
                if layer==1 then
                    n=7
                end
                local exceedingOutward=DIFF()>=G.HARD
                if exceedingOutward then
                    exceedN=4
                end
                local sumN=n+exceedN
                BulletSpawner{kinematicState={pos=posp,dir=0,speed=0},period=9,firstPeriod=1,lifeFrame=2,bulletNumber=8*sumN,range=math.pi*2*sumN,angle=math.pi/8,bulletSpeed=0,spawnCircleRadius=data[layer].r,spawnCircleAngle=data[layer].theta,bulletSprite=BulletSprites.flame.orange,highlight=true,bulletLifeFrame=life,bulletExtraUpdate={Action.ZoomIn(30),Action.FadeOut(30,true),extraUpdate},bulletEvents={function(cir,args,self)
                    cir.layer=layer
                    cir.theta=args.index/8*math.pi*2+theta0
                    cir.ratio=(math.ceil(args.index/8)-exceedN)/n
                end}}
            end
            wait(60)
            SFX:play('enemyPowerfulShot')
            for layer=1,2 do
                Event.EaseEvent{obj=sentry,easeObj=data[layer],aims={r=200+50*math.mod2Sign(layer),thickness=layer==1 and 80 or 50},duration=120,progressFunc=Event.sineOProgressFunc}
            end
            wait(60)
            Event.EaseEvent{obj=sentry,easeObj=data[1],aims={flag=1},duration=60,progressFunc=Event.sineOProgressFunc}
            wait(60)
            local spinTime=600
            for layer=1,2 do
                Event.EaseEvent{obj=sentry,easeObj=data[layer],aims={theta=math.pi*math.mod2Sign(layer)},duration=spinTime,progressFunc=Event.sineIOProgressFunc}
            end
            SFX:play('enemyPowerfulShot')
            local portalAngle=math.pi/8
            local portals={}
            local slotTaken={[-1]={},[1]={}}
            for layer=-1,1,2 do
                for idx=1,8 do
                    slotTaken[layer][idx]=false
                end
            end
            local function getRandomSlot(layer)
                local availableSlots={}
                for idx=1,8 do
                    if not slotTaken[layer][idx] then
                        table.insert(availableSlots, idx)
                    end
                end
                if #availableSlots == 0 then
                    return nil
                end
                return availableSlots[math.random(1, #availableSlots)]
            end
            local function createPortal(layer,idx,flip)
                slotTaken[layer][idx]=true
                local r0=layer==-1 and 60 or 135
                local function getPoses(self)
                    self=self or {frame=1,lifeFrame=99}
                    local lenRatio=math.min(1,self.frame/30)
                    if self.frame>self.lifeFrame-30 then
                        lenRatio=math.max((self.lifeFrame-self.frame)/30,0.01)
                    end
                    local thetap=data[1].theta
                    local theta=portalAngle+thetap+idx/8*math.pi*2
                    local posBase=geo:rThetaGoRef(sentry.kinematicState.pos,r0,theta)
                    local pos1,pos2=Portal.segment(posBase,theta,15*lenRatio)
                    if flip then
                        pos1,pos2=pos2,pos1
                    end
                    local posIn=geo:rThetaGoRef(sentry.kinematicState.pos,r0+layer*10,theta)
                    return pos1,pos2,posIn
                end
                local pos1,pos2,posIn=getPoses()
                local portal=Portal(pos1,pos2,posIn,{range=20,draw=true,color={1,1,0,1},width=10,lifeFrame=spinTime,extraUpdate={function (self)
                    if sentry.removed then
                        self:remove()
                    end
                    local pos1,pos2,posIn=getPoses(self)
                    self:set(pos1,pos2)
                end}})
                table.insert(portals,portal)
            end
            -- real portals (connects inner and outer sides)
            for layer=-1,1,2 do
                createPortal(layer,getRandomSlot(layer))
            end
            portals[1]:link(portals[2])
            -- add some distraction portals (outer connects to outer) for higher difficulties
            local distractionPairCount=DSWITCH{0,1,2,3}
            -- local firstLayer=math.randomSign()
            for pair=1,distractionPairCount do
                local layer=1
                for i=1,2 do
                    createPortal(layer,getRandomSlot(layer),i==2)
                end
                portals[#portals-1]:link(portals[#portals])
            end
            wait(spinTime-60)
            SFX:play('enemyCharge')
            wait(30)
            for layer=1,2 do
                Event.EaseEvent{obj=sentry,easeObj=data[layer],aims={r=200-10*math.mod2Sign(layer)},duration=30,progressFunc=Event.sineIProgressFunc}
            end
            wait(30)
            SFX:play('enemyPowerfulShot')
            wait(60)
        end
    end
}