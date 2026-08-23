---@return SpellcardPhase
return BossManager.SpellcardPhase{
    key='shouji-trick',
    bonusScore=25000,
    time=2400,
    hp=5000,
    dropItems={powerSmall=15,point=15},
    func=function(self, boss)
        SFX:play('enemyPowerfulShot')
        boss.showHexagram=false
        -- boss:addHPProtection(600,10)
        local geo=G.runInfo.geometry
        ---@cast geo PortalGeometryBase
        local posp=copyTable(G.runInfo.player.kinematicState.pos)
        Portal.setOuterPortals(posp)
        local dir0=G.runInfo.player.viewDirection
        local posb=geo:rThetaGo(posp,330,dir0-math.pi/2)
        Portal.setOuterPortals(posb)
        DanmakuFuncs.moveToInTime(boss,posb,40)
        wait(40)
        Portal.zoomC=80
        local bigPortalSentry=DanmakuFuncs.PortalOnSentry(posb,dir0+math.pi/2,370,150,false,60,{draw=true,width=3,range=30})
        local bigPortal=bigPortalSentry.any.portal
        local smallPortalAngle=function(dt)
            local t=bigPortalSentry.frame+(dt or 0)
            return dir0+math.pi/2+math.sin(t/200)*math.pi/3
        end
        local smallLength=50
        local smallDistance=100
        local smallPortalSentry=DanmakuFuncs.PortalOnSentry(posb,dir0+math.pi/2,smallLength,-smallDistance,true,60,{draw=true,width=3,range=30})
        local smallPortal=smallPortalSentry.any.portal
        local spawner=BulletSpawner{lifeFrame=9999,period=DSWITCH{3,2,2,1},bulletNumber=1,angle=smallPortalAngle(),bulletSprite=BulletSprites.flame.red,bulletSpeed=150,highlight=true,bulletLifeFrame=300,bulletEvents={function (cir,args,self)
            local phase=self.spawnTimes/20+self.spawnTimes%3*math.pi*2/3
            cir.kinematicState.speed=cir.kinematicState.speed*(2-math.abs(math.cos(phase)))*math.eval(1,0.05*math.min(1,self.frame/1200))
            local time=smallDistance*60/cir.kinematicState.speed*1.05
            cir.kinematicState.dir=smallPortalAngle(time)
            local offset=math.sin(phase)*smallLength*0.9*math.min(1,smallPortalSentry.any.ratio+time/60)
            cir.kinematicState.pos=geo:rThetaGo(cir.kinematicState.pos,offset,cir.kinematicState.dir+math.pi/2)
            cir.flashPeriod=math.eval(60,20)
        end},bulletExtraUpdate={Action.FadeOut(20,true),function (self)
            if self.kinematicState.teleportedPortals and self.frame>60 then
                if Portal.objects[self.kinematicState.teleportedPortals[1]]==smallPortal then -- prevent secondary messy bullets
                    self:remove()
                end
            end
            local phase=self.frame/self.flashPeriod*math.pi*2
            local val=math.sin(phase)*0.4+0.6
            self.spriteColor={1,val,val,1}
        end}}
        spawner:bindState(boss)
        Event.LoopEvent{obj=smallPortalSentry,period=1,executeFunc=function (self,times)
            smallPortalSentry.kinematicState.dir=smallPortalAngle()+math.pi
        end}
        bigPortal:link(smallPortal)
        local function upward(sign,idx)
            local period=22
            local maxtan=3
            local num=DSWITCH{3,3,3,3}
            local type=math.random(1,DSWITCH{1,2,4,6})--idx%6+1--math.ceil(math.pseudoRandom(idx)*6)
            local upwardSpawner=BulletSpawner{lifeFrame=period-1,period=1,bulletNumber=num,angle=dir0,bulletSprite=BulletSprites.kunai.blue,bulletSize=1.5,bulletSpeed=math.min(100,50+idx*10),highlight=true,bulletLifeFrame=300,bulletEvents={function (cir,args,self)
                local time=self.frame%period
                local ratio=time/period-0.5
                local tan=ratio*maxtan
                local index=args.index-num/2-0.5
                if type==2 then
                    tan=tan+index*0.1
                elseif type==3 then
                    tan=tan-index*0.1
                elseif type>=4 then
                    local gap=(type-3)*0.1
                    local n=math.ceil(2/gap)
                    local extra=gap*(n-1)
                    tan=ratio*(maxtan-extra)+gap*math.floor(ratio*n)+index*gap/3
                end
                local angle=math.atan(tan)*sign
                cir.kinematicState.dir=angle+dir0-math.pi/2
                cir.kinematicState.speed=(cir.kinematicState.speed+10*args.index)/math.cos(angle)
                cir.speedRef=cir.kinematicState.speed
                cir.kinematicState.speed=cir.kinematicState.speed*(1+time/20)
                cir.speed0=cir.kinematicState.speed
                cir.flashPeriod=math.eval(60,20)
                local val=1-math.abs(ratio)*1.6
                cir.spriteColor={1,val,1,1}
            end},bulletExtraUpdate={Action.FadeOut(20,true),function (self)
                self.kinematicState.speed=math.lerp(self.speed0,self.speedRef,math.min(1,self.frame/40))
            end}}
            upwardSpawner:bindState(boss)
        end
        Event.LoopEvent{obj=smallPortalSentry,period=120,executeFunc=function (self,times)
            upward(math.mod2Sign(times),times+2)
        end}
    end
}