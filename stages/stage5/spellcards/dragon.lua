---@return SpellcardPhase
return BossManager.SpellcardPhase{
    key='tatsu-dragon',SKIP_INCLUDE=true,
    bonusScore=40000,
    time=2400,
    hp=2400,
    dropItems={powerSmall=20,point=20},
    func=function(self, boss)
        boss:addHPProtection(120,3)
        local geo=G.runInfo.geometry
        ---@cast geo Cylinder
        local ball=boss.any.getBall(boss)
        local sign=math.randomSign()
        local cycles=DSWITCH{2,3,4,5}-0.03
        local wave=DSWITCH{0,0,0,5}
        local time=420
        local function speedF(frame)
            frame=frame-120
            local ratio=frame/(time-120)
            if frame<0 then
                return 0
            end
            return ratio^2*1800*cycles/2
        end
        local function stopUpdate(self)
            local dist=self.any.dist
            local dist2=math.abs(dist)
            local timeY=time-dist2
            local ratio=math.min(1,self.frame/timeY)
            self.kinematicState.pos.y=self.any.dist*ratio
            if wave>0 then
                self.spriteColor={1,1,math.min(1,1-ratio*0.8*math.cos(self.any.phase))}
            end
            self.kinematicState.speed=speedF(self.frame)
        end
        local function dropUpdate(self)
            local vx,vy=math.rTheta2xy(self.kinematicState.speed,self.kinematicState.dir)
            vy=vy+1
            self.kinematicState.speed,self.kinematicState.dir=math.xy2rTheta(vx,vy)
        end
        for i=1,8 do
            local pos1={x=G.runInfo.player.kinematicState.pos.x,y=0}
            DanmakuFuncs.moveToInTime(ball,pos1,120,Event.sineOProgressFunc)
            wait(60)
            SFX:play('enemyCharge')
            wait(60)
            SFX:play('enemyPowerfulShot')
            local lr=math.mod2Sign(i)*sign
            local side=math.sign(G.runInfo.player.kinematicState.pos.y)
            local angle=math.atan(1/(math.pi*2*cycles))
            local num=math.ceil(cycles*70-1)
            local dir=side*(math.pi/2+(math.pi/2-angle)*lr)
            local dirh=math.pi/2*(1+lr)
            ball.kinematicState.dir=dirh
            local sentry=DanmakuFuncs.sentry()
            sentry.lifeFrame=time-1
            ball.safe=true
            local lastXratio=0
            local multi=math.eval(7.37,0.05)
            sentry.extraUpdate={function(self)
                ball.kinematicState.speed=speedF(self.frame)
                local xratio=ball.kinematicState.pos.x/geo.a*multi
                if math.ceil(xratio)~=math.ceil(lastXratio) and sentry.frame>60 then
                    BulletSpawner{kinematicState={pos=copyTable(ball.kinematicState.pos),dir=0,speed=0},firstPeriod=1,period=5,lifeFrame=2,bulletNumber=4,angle=-math.pi/2,range=math.pi/2,bulletSprite=BulletSprites.giant.green,bulletSpeed=500-sentry.frame,highlight=true,bulletExtraUpdate={Action.ZoomIn(20),Action.ZoomOut(20),dropUpdate},bulletLifeFrame=500,bulletEvents={function(cir)
                        cir.forceQuad=true
                    end}}
                end
                lastXratio=xratio
            end}
            for j=1,num do
                local dist=j/num*geo.a*cycles
                local posAim=geo:rThetaGo(ball.kinematicState.pos,dist,dir)
                local bullet=Bullet{kinematicState={pos={x=posAim.x,y=0},dir=dirh,speed=0},sprite=BulletSprites.lightRound.green,lifeFrame=time,extraUpdate={Action.ZoomIn(10),Action.ZoomOut(10),stopUpdate},highlight=true,forceQuad=true,size=0.8}
                local phase=j/num*math.pi*2*cycles
                bullet.any={dist=posAim.y+wave*math.sin(phase),phase=phase}
            end
            boss:addHPProtection(400,3)
            wait(120)
            SFX:play('enemyPowerfulShot')
            wait(time-120)
            ball.safe=false
            ball.kinematicState.speed=0
            Event.LoopEvent{obj=ball,period=1,times=240,executeFunc=function(self,times,maxTimes)
                local x=ball.kinematicState.pos.x
                local aimx=G.runInfo.player.kinematicState.pos.x
                aimx=math.modClamp(aimx,x,geo.a/2)
                local maxSpeed=math.min(12,times/10)
                local lerpSpeed=math.abs(aimx-x)*0.03
                local speed=math.min(maxSpeed,lerpSpeed)
                ball.kinematicState.pos.x=x+speed*math.sign(aimx-x)
            end}
            wait(240)
        end
    end
}