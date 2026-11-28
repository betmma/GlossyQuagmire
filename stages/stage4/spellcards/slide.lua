---@return SpellcardPhase
return BossManager.LastSpellcardPhase{
    key='shouji-slide',
    bonusScore=50000,
    time=2400,
    hp=4000,
    dropItems={lifePiece=2,bombPiece=2},
    func=function(self, boss)
        SFX:play('enemyPowerfulShot')
        boss.showHexagram=false
        boss:addHPProtection(600,10)
        local geo=G.runInfo.geometry
        ---@cast geo PortalGeometryBase
        local posp=copyTable(G.runInfo.player.kinematicState.pos)
        local dir0=0
        local outerPortals=Portal.setOuterPortals(posp)
        for i=1,#outerPortals do
            outerPortals[i]:remove()
            outerPortals[i]=nil
        end
        local posb=geo:rThetaGoRef(posp,500,dir0-math.pi/2)
        Effect.Charge{obj=G.runInfo.player,size=2}
        boss.safe=true
        G.runInfo.player.viewDirection=math.modClamp(G.runInfo.player.viewDirection)
        Event.EaseEvent{obj=G.runInfo.player,aims={viewDirection=0},duration=30,progressFunc=Event.sineIOProgressFunc}
        wait(30)
        boss.kinematicState.pos=posb
        local sentry=DanmakuFuncs.sentry(posb)
        Event.LoopEvent{obj=sentry,period=1,executeFunc=function ()
            boss.kinematicState.pos=sentry.kinematicState.pos
        end}
        local fixedSentry=DanmakuFuncs.sentry(posp)
        local width,height=200,100
        local movePortals,fixedPortals={},{}
        local portalArgs={range=50,draw=false,color={1,0,0,1}}
        for i=1,4 do
            local angle=dir0+math.pi/2*i
            local l1,l2=height,width
            if i%2==1 then
                l1,l2=width,height
                local posi=geo:rThetaGoRef(posp,l2-1,angle)
                local p1,p2=Portal.segment(posi,angle,l1)
                local points,angles=DanmakuFuncs.midPoints(p1,p2,20,30)
                for index=1,#points-1 do
                    local point=points[index]
                    local anglei=angles[index]
                    -- horizontal borders
                    Bullet{kinematicState={pos=point,dir=anglei,speed=0},lifeFrame=9999,invincible=true,highlight=true,sprite=BulletSprites.stick.red,extraUpdate=Action.ZoomIn(30)}
                end
            end
        end
        for i=1,4 do
            local angle=dir0+math.pi/2*i
            local l1,l2=height,width
            if i%2==1 then
                l1,l2=width,height
            end
            
            local sentryi=DanmakuFuncs.PortalOnSentry(posb,angle,l1,-l2,i==2,30,portalArgs)
            Event.LoopEvent{obj=sentryi,period=1,executeFunc=function(self,dt)
                sentryi.kinematicState.pos=sentry.kinematicState.pos
            end}
            table.insert(movePortals,sentryi.any.portal)
            local sentryi=DanmakuFuncs.PortalOnSentry(posp,angle,l1,-l2,i~=2,30,portalArgs)
            table.insert(fixedPortals,sentryi.any.portal)
            Event.LoopEvent{obj=sentryi,period=1,executeFunc=function(self,dt)
                sentryi.kinematicState.pos=fixedSentry.kinematicState.pos
            end}
        end
        movePortals[2]:link(movePortals[4])
        fixedPortals[2]:link(fixedPortals[4])
        movePortals[1]:link(fixedPortals[3])
        movePortals[3]:link(fixedPortals[1])
        Event.LoopEvent{obj=sentry,period=1,executeFunc=function(self,dt)
            local pos=G.runInfo.player.kinematicState.pos
            local posf=fixedSentry.kinematicState.pos
            if math.abs(pos.x-posf.x)<=width and math.abs(pos.y-posf.y)<=height then
                -- limit sentry range to prevent exceeding canvas or overlap with fixed portals
                sentry.kinematicState.pos.x=math.clamp(sentry.kinematicState.pos.x,posf.x-500,posf.x+500)
                sentry.kinematicState.pos.y=math.clamp(sentry.kinematicState.pos.y,posf.y-900,posf.y-350)
                -- sentry.kinematicState.pos=geo:rThetaGo(G.runInfo.player.kinematicState.pos,500,dir0-math.pi/2)
                sentry.kinematicState.speed=G.runInfo.player.kinematicState.speed
                sentry.kinematicState.dir=G.runInfo.player.kinematicState.dir
            else
                sentry.kinematicState.speed=0
            end
            Portal.canvasOffset.y=(G.runInfo.player.kinematicState.pos.y-(sentry.kinematicState.pos.y+posf.y)/2)
        end}
        -- sentry.drawText=function ()
        --     love.graphics.print(pprint(movePortals[1].any.sentry.kinematicState.pos),20,120)
        -- end
        local rands={}
        for i=1,16 do
            table.insert(rands,math.eval(0.5,0.5))
        end
        local function noise(t,randIndex)
            local val=0
            local period=120
            local a=1
            for i=0,3 do
                val=val+math.sin(t/period+rands[randIndex+i]*math.pi*2)*a
                period=period/2
                a=a/2
            end
            return val
        end
        local familiarUpdate=function (self)
            self.kinematicState.speed=noise(self.frame/2,1)*100
        end
        local n=DSWITCH{5,5,3,3}
        for i=1,n do
            local pos,dir=geo:rThetaGo(sentry.kinematicState.pos,((i-0.5)/n-0.5)*width*2,dir0)
            local familiar=Bullet{kinematicState={pos=pos,dir=dir,speed=0},sprite=BulletSprites.giant.white,lifeFrame=9999,extraUpdate={Action.ZoomIn(30),familiarUpdate},highlight=true,invincible=true}
            local spawner=BulletSpawner{lifeFrame=9999,period=5,firstPeriod=60,bulletNumber=DSWITCH{2,2,2,2,3},bulletSprite=BulletSprites.kunai.white,bulletLifeFrame=DSWITCH{150,150,300,300},bulletSpeed=DSWITCH{179,179,89,89},angle=0,useRelativeAngle=true,bulletExtraUpdate={Action.FadeIn(20,true),Action.FadeOut(20,true)}}
            spawner:bindState(familiar)
            Event.LoopEvent{obj=spawner,period=1,executeFunc=function (self, index, total)
                spawner.angle=math.sin(index/60)*DSWITCH{0,0.1,0.2,0.3}*math.min(index/240,1)
            end}
        end
    end
}