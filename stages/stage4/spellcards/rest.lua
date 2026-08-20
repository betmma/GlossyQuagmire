---@return SpellcardPhase
return BossManager.SpellcardPhase{
    key='shouji-rest',
    bonusScore=25000,
    time=2400,
    hp=4000,
    dropItems={powerSmall=15,point=15},
    func=function(self, boss)
        SFX:play('enemyPowerfulShot')
        boss.showHexagram=false
        boss:addHPProtection(600,3)
        local geo=G.runInfo.geometry
        ---@cast geo PortalGeometryBase
        local posp=copyTable(G.runInfo.player.kinematicState.pos)
        Effect.Charge{obj=G.runInfo.player,size=2}
        local dir0=G.runInfo.player.viewDirection
        local posb,posd=geo:rThetaGo(posp,400,dir0-math.pi/4)
        DanmakuFuncs.moveToInTime(boss,posb,30)
        G.runInfo.player.immobileFrame=30
        wait(30)
        local outerPortals=Portal.setOuterPortals(posb)
        for i=1,#outerPortals do
            outerPortals[i]:remove()
            outerPortals[i]=nil
        end
        local portalArgs={range=50,draw=true,color={0,0,1,1}}
        local polygonN=DSWITCH{4,4,3,3}
        local lengthRatio=math.tan(math.pi/polygonN)
        local playerSideR=100
        local playerSidePortals={}
        for i=1,polygonN do
            local dir=dir0+math.pi*2/polygonN*(i-1)+math.pi/4
            local sentry=DanmakuFuncs.PortalOnSentry(posp,dir,playerSideR,-playerSideR,false,30,portalArgs)
            playerSidePortals[i]=sentry.any.portal
            Event.LoopEvent{obj=sentry,period=1,executeFunc=function(self,dt)
                sentry.any.length=playerSideR*1.4*lengthRatio
                sentry.any.width=-playerSideR
            end}
        end

        local bossSideR=100
        local bossSidePortals={}
        for i=1,polygonN do
            local dir=dir0+math.pi*2/polygonN*(i-1)+math.pi/4
            local sentry=DanmakuFuncs.PortalOnSentry(posb,dir,bossSideR,-bossSideR,true,30,portalArgs)
            bossSidePortals[i]=sentry.any.portal
            Event.LoopEvent{obj=sentry,period=1,executeFunc=function(self,dt)
                sentry.any.length=bossSideR*1.4*lengthRatio
                sentry.any.width=-bossSideR
            end}
        end

        for i=1,polygonN do
            playerSidePortals[i]:link(bossSidePortals[(i+math.floor(polygonN/2)-1)%polygonN+1])
        end
        local mainSentry=DanmakuFuncs.sentry(posb)
        Event.LoopEvent{obj=mainSentry,period=1,executeFunc=function(self,times)
            local ratio=math.sin(times/120)
            playerSideR=100+ratio*50
            bossSideR=100-ratio*50
        end}
        local rows=DSWITCH{1,2,2,3}
        local columns=DSWITCH{64,32,48,48}
        local sprite=DIFF()<=G.HARD and 'round' or 'roundDark'
        local spawner=BulletSpawner{lifeFrame=9999,bulletSprite=BulletSprites[sprite].cyan,bulletSpeed=columns*4/2,bulletNumber=columns*rows,bulletLifeFrame=600,period=480,firstPeriod=60,angle='player',range=0,bulletExtraUpdate={Action.FadeOut(30,true),Action.ZoomOut(30)},bulletEvents={function(cir,args,self)
            if self.spawnTimes%2==0 then
                cir:changeSpriteColor('blue')
            end
            local index=args.index
            if index==1 then
                SFX:play('enemyPowerfulShot')
            end
            local row,col=index%rows,math.ceil(index/rows)
            cir.kinematicState.pos=geo:rThetaGo(cir.kinematicState.pos,40*(row-rows/2+0.5),cir.kinematicState.dir+math.pi/2)
            cir.kinematicState.speed=cir.kinematicState.speed-col*4
        end}}
        spawner:bindState(boss)
        Event.LoopEvent{obj=mainSentry,period=480,firstPeriod=1,executeFunc=function(self,times)
            SFX:play('enemyCharge')
            spawner.angle=geo:to(boss.kinematicState.pos,G.runInfo.player.kinematicState.pos)+math.eval(0,0.1)
        end}
    end
}