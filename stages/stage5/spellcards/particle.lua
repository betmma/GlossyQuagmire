---@return SpellcardPhase
return BossManager.LastSpellcardPhase{
    key='tatsu-particle',SKIP_INCLUDE=true,
    bonusScore=100000,
    time=3000,
    hp=5600,
    dropItems={lifePiece=2,bombPiece=2},
    func=function(self, boss)
        local player=G.runInfo.player
        local geo=G.runInfo.geometry
        ---@cast geo Cylinder
        local ball=boss.any.getBall(boss)
        local particleData={dir=0,speed=0,attract=0}
        local cores={}
        local edge=20
        local function wrap(self)
            -- self.safe=true
            self.kinematicState.pos.y=math.modClamp(self.kinematicState.pos.y,0,geo.r0+edge)
            self.spriteColor={1,1,1,math.clamp(1+(geo.r0-math.abs(self.kinematicState.pos.y))/edge,0,1)}
        end
        local function particleMoveUpdate(self)
            self.kinematicState.dir=particleData.dir
            self.kinematicState.speed=particleData.speed
            local offset=self.any.offset
            local lastBest=self.any.lastBest
            local shiftFrame=self.any.shiftFrame
            local pos=self.kinematicState.pos
            local pos0={x=pos.x-offset.x,y=pos.y-offset.y}
            local restore=0.98
            local newOffset={x=offset.x*restore,y=offset.y*restore}
            local min,best=999,cores[1]
            local min2,best2=1000,cores[1]
            for index, value in ipairs(cores) do
                local posi=value.kinematicState.pos
                local x,y=math.modClamp(posi.x,pos0.x,geo.a/2),math.modClamp(posi.y,pos0.y,geo.r0+edge)
                local distance=math.distance(pos0.x,pos0.y,x,y)
                if distance<min then
                    min2,best2=min,best
                    min,best=distance,value
                elseif distance<min2 then
                    min2,best2=distance,value
                end
            end
            local posi=best.kinematicState.pos
            local x,y=math.modClamp(posi.x,pos0.x,geo.a/2),math.modClamp(posi.y,pos0.y,geo.r0+edge)
            local vale=particleData.attract*(1-restore)*math.clamp((min2-min)/20,0,1)
            newOffset.x=newOffset.x-(pos0.x-x)*vale
            newOffset.y=newOffset.y-(pos0.y-y)*vale
                -- local delta={x=pos0.x-x,y=pos0.y-y}
            self.kinematicState.pos={x=pos0.x+newOffset.x,y=pos0.y+newOffset.y}
            self.any.offset=newOffset
            if particleData.attract>0.01 then
                if best~=lastBest then
                    self.any.shiftFrame=self.frame+60
                    self.batch=BulletBatch
                end
                if self.frame==shiftFrame then
                    self.batch=Asset.bulletHighlightBatch
                end
                self.size=math.lerp(self.size,math.clamp((min2-min)/100,0,particleData.attract)+1,0.05)
            else
                self.batch=Asset.bulletHighlightBatch
                self.size=math.lerp(self.size,1,0.1)
            end
            self.any.lastBest=best
        end
        local particleUpdates={Action.ZoomIn(30),Action.FadeIn(30,true),wrap,particleMoveUpdate}
        local n1,n2=10,31
        local sentry=DanmakuFuncs.sentry()
        Event{obj=sentry,action=function (self)
            for i=1,n1 do
                local y=(geo.r0+edge)*(i/n1*2-1)
                for j=1,n2 do
                    local x=geo.a*((j+i*0.5)/n2)
                    local warning=Bullet{kinematicState={pos={x=x,y=y},dir=0,speed=0},sprite=BulletSprites.cross.red,lifeFrame=120,extraUpdate={Action.ZoomIn(60,2,3,true),Action.FadeIn(30,false),Action.FadeOut(20,false)},highlight=true,safe=true,invincible=true}
                end
            end
            wait(90)
            local bulletType=DIFF()<=G.NORMAL and 'round' or 'bigRound'
            for i=1,n1 do
                local y=(geo.r0+edge)*(i/n1*2-1)
                for j=1,n2 do
                    local x=geo.a*((j+i*0.5)/n2)
                    local particle=Bullet{kinematicState={pos={x=x,y=y},dir=0,speed=0},sprite=BulletSprites[bulletType].blue,lifeFrame=9999,extraUpdate=particleUpdates,invincible=true,forceQuad=true}
                    particle.any={offset={x=0,y=0}}
                end
            end
        end}
        local nc1,nc2=2,6
        if DIFF()<=G.NORMAL then
            nc1,nc2=3,3
        end
        local coreExtraDir=0
        local particleSpeed=DSWITCH{60,60,60,120}
        local coreSpeedMult=DSWITCH{2,2,2,0.5}
        for i=1,nc1 do
            for j=1,nc2 do
                local y=(geo.r0+edge)*2*(i/nc1)
                local x=geo.a*((j+i*0.5)/nc2)
                local core=Bullet{kinematicState={pos={x=x,y=y},dir=0,speed=0},sprite=BulletSprites.giant.red,lifeFrame=9999,extraUpdate={wrap,function (self)
                    self.kinematicState.dir=particleData.dir+coreExtraDir
                    self.kinematicState.speed=particleData.speed*coreSpeedMult
                end},safe=true,invincible=true,highlight=true,spriteTransparency=0}
                table.insert(cores,core)
            end
        end
        for i=1,6 do
            local pos1={x=G.runInfo.player.kinematicState.pos.x,y=0}
            wait(60)
            DanmakuFuncs.moveToInTime(ball,pos1,120,Event.sineOProgressFunc)
            Event.EaseEvent{obj=sentry,easeObj=particleData,aims={speed=0},duration=60}
            SFX:play('enemyCharge')
            wait(60)
            Event.EaseEvent{obj=sentry,easeObj=particleData,aims={speed=particleSpeed},duration=120}
            particleData.dir=math.eval(particleData.dir,math.pi)
            SFX:play('enemyPowerfulShot')
            Event.EaseEvent{obj=sentry,easeObj=particleData,aims={attract=0.7},duration=300,progressFunc=Event.sineIOProgressFunc}
            Event.EaseEvent{obj=sentry,easeObj=particleData,aims={dir=particleData.dir+math.pi*math.mod2Sign(i)},duration=300}
            wait(360)
            SFX:play('enemyCharge')
            wait(60)
            SFX:play('enemyPowerfulShot')
            Event.EaseEvent{obj=sentry,easeObj=particleData,aims={attract=0},duration=30}
            wait(120)
            coreExtraDir=math.eval(0,1)
            if DIFF()<=G.HARD then
                coreSpeedMult=coreSpeedMult+0.3
            else
                particleSpeed=particleSpeed+20
            end
        end
    end
}