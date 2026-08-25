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
        local posb=geo:rThetaGo(posp,200,dir0-math.pi/2+0.3)
        local outerPortals=Portal.setOuterPortals(posb)
        outerPortals[1]:remove() -- remove top and bottom
        outerPortals[3]:remove()
        for i=1,4 do
            outerPortals[i]=nil
        end
        DanmakuFuncs.moveToInTime(boss,posb,40)
        wait(40)
        Portal.zoomC=80
        local bigPortalSentry=DanmakuFuncs.PortalOnSentry(posb,dir0+math.pi/2,370,-150,false,60,{draw=true,width=3,range=300})
        local bigPortal=bigPortalSentry.any.portal
        local smallPortalAngle=dir0+math.pi/2
        local smallLength=200
        local smallDistanceFunc=function ()
            local final=200
            return final+(350-final)*math.exp(-bigPortalSentry.frame/30)
        end
        local smallPortalSentry=DanmakuFuncs.PortalOnSentry(posb,dir0-math.pi/2,smallLength,-smallDistanceFunc(),true,60,{draw=true,width=3,range=300})
        Event.LoopEvent{obj=smallPortalSentry,period=1,executeFunc=function ()
            smallPortalSentry.any.width=-smallDistanceFunc()
        end}
        --- flames to prevent escape
        for x=-350,350,10 do
            local xabs=math.abs(x)
            local xRatio=(xabs-smallLength)/(350-smallLength)
            if xabs<smallLength-10 then
                goto continue
            elseif xabs<smallLength+10 then
                x=math.sign(x)*(smallLength+10)
            end
            local p0=geo:rThetaGoRef(posb,x,dir0)
            local p1,dir1=geo:rThetaGoRef(p0,-350,dir0-math.pi/2)
            local bullet=Bullet{kinematicState={pos=p1,dir=dir1,speed=0,skipPortal=true},lifeFrame=9999,sprite=BulletSprites.flame.black,extraUpdate={Action.FadeIn(20,false),function (self)
                self.kinematicState.pos=geo:rThetaGoRef(p0,-smallDistanceFunc()*(1-xRatio),dir0-math.pi/2)
            end},invincible=true,highlight=true}
            ::continue::
        end
        local smallPortal=smallPortalSentry.any.portal
        local ratioFunc=function ()
            local t=bigPortalSentry.frame
            return 0.2--0.05*math.cos(t/100)
        end
        local colors={'red','yellow','green','blue','purple','white','black'}
        local groupN=15
        local compensateFrame=30
        local initPhase=math.eval(0,1)
        local spawner=BulletSpawner{lifeFrame=9999,period=DSWITCH{4,3,2,1},bulletNumber=1,angle=smallPortalAngle,bulletSprite=BulletSprites.flame.red,bulletSpeed=350,highlight=true,bulletLifeFrame=600,bulletEvents={function (cir,args,self)
            local groupIndex=self.spawnTimes%groupN
            local phase=math.sin(initPhase+self.spawnTimes%3*math.pi*2/3+math.cos(self.spawnTimes/60))--%2-1
            --cir.kinematicState.speed=cir.kinematicState.speed*math.eval(1,0.05*math.min(1,self.frame/1200))
            local compensateDist=cir.kinematicState.speed*(groupIndex*self.period)/60
            cir.speedRef=cir.kinematicState.speed
            cir.kinematicState.speed=cir.kinematicState.speed+compensateDist*60/compensateFrame*2
            cir.speed0=cir.kinematicState.speed
            local offset=phase*smallLength*ratioFunc()
            cir.kinematicState.pos=geo:rThetaGo(cir.kinematicState.pos,offset,cir.kinematicState.dir+math.pi/2)
            cir.flashPeriod=math.eval(60,20)
        end},bulletExtraUpdate={Action.FadeOut(20,true),function (self)
            if self.kinematicState.teleportedPortals and self.frame>60 then
                local portal=Portal.objects[self.kinematicState.teleportedPortals[1]]
                if portal==bigPortal then -- prevent teleporting from reaching big portal's back side
                    self:remove()
                end
                if portal==smallPortal then
                    self.teleportCount=(self.teleportCount or 0)+1
                    self:changeSpriteColor(colors[self.teleportCount%#colors+1])
                end
            end
            local phase=self.frame/self.flashPeriod*math.pi*2
            local val=math.sin(phase)*0.2+0.8
            self.spriteColor={1,val,val,1}
            self.kinematicState.speed=(self.speed0-self.speedRef)*(1-math.min(1,self.frame/compensateFrame))+self.speedRef-math.min((self.teleportCount or 0)*50,280)
        end}}
        spawner:bindState(boss)
        bigPortal:link(smallPortal)
    end
}