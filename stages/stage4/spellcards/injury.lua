---@return SpellcardPhase
return BossManager.SpellcardPhase{
    key='shouji-injury',
    bonusScore=25000,
    time=2400,
    hp=5500,
    dropItems={powerSmall=15,point=15},
    func=function(self, boss)
        boss.showHexagram=false
        boss:addHPProtection(300,3)
        local geo=G.runInfo.geometry
        ---@cast geo PortalGeometryBase
        local posp=copyTable(G.runInfo.player.kinematicState.pos)
        local dir0=G.runInfo.player.viewDirection
        Portal.setOuterPortals(posp)
        local posb,posd=geo:rThetaGo(posp,200,dir0-math.pi/2)
        DanmakuFuncs.moveToInTime(boss,posb,60)
        wait(60)
        -- portals around player
        -- angle of one portal. the other is it + pi
        local portalAngle=G.runInfo.player.keyIsDown(KEYS.SLOW) and 0 or math.pi/2
        local r=60
        local portals={}
        for i=1,2 do
            local dir=(i-1)*math.pi+dir0
            local sentry=DanmakuFuncs.PortalOnSentry(copyTable(posp),dir+portalAngle,30,r,i==1,30,{range=20,draw=true,width=15},nil,nil)--{sprite=BulletSprites.round[i==1 and 'red' or 'blue'],invincible=true,lifeFrame=9999,safe=true},15)
            portals[i]=sentry.any.portal
            Event.LoopEvent{obj=sentry,period=1,executeFunc=function ()
                sentry.kinematicState.pos=copyTable(G.runInfo.player.kinematicState.pos)
                sentry.kinematicState.dir=dir+portalAngle
            end}
            -- cannot use PortalOnSentry's back bullets
            for side=-1,1,2 do
                local bullet=Bullet{sprite=BulletSprites.round[i==1 and 'red' or 'blue'],invincible=true,lifeFrame=9999,safe=true,extraUpdate={Action.FadeIn(30,true),function (self)
                    local pos1,dir1=geo:rThetaGoRef(G.runInfo.player.kinematicState.pos,sentry.any.width,dir+portalAngle)
                    dir1=dir1+math.pi/2*side
                    local pos2=geo:rThetaGoRef(pos1,sentry.any.length*sentry.any.ratio+10,dir1)
                    self.kinematicState.pos=pos2
                end}}
            end
        end
        portals[1]:link(portals[2])
        local mainSentry=DanmakuFuncs.sentry(posb)
        Event.LoopEvent{obj=mainSentry,period=1,executeFunc=function (self,times)
            local newAim=math.pi/2
            if G.runInfo.player.keyIsDown(KEYS.SLOW) then
                newAim=0
            end
            newAim=math.modClamp(newAim,portalAngle+0.2,math.pi/2)
            portalAngle=math.lerp(portalAngle,newAim,0.2)
            if times%120==0 then
                Portal.setOuterPortals(G.runInfo.player.kinematicState.pos)
            end
        end}
        local period=300
        local slashExtraUpdate={Action.ZoomIn(30,1,3),Action.FadeIn(30,true),Action.FadeOut(20,true),function(self)
            if self.frame>30 and self.frame<150 then
                self.kinematicState.dir=self.kinematicState.dir-self.any.tilt/120
            end
            if self.frame>200 then
                self.kinematicState.speed=math.lerp(self.kinematicState.speed,100,0.003)
            end
        end}
        local function slash(tilt)
            local down=dir0+math.pi/2
            local shortDir=down+tilt
            -- ellipse
            local n=DSWITCH{70,80,90,100}
            local range=math.pi*2
            local waitFrames=0
            for i=1,n do
                local angle=range*(i/n-0.5)
                local x,y=math.cos(angle),math.sin(angle)
                x=x/DSWITCH{9,7,6,5}
                local length,dir=math.xy2rTheta(x,y)
                dir=dir+shortDir
                local speed=length*250
                local pos=geo:rThetaGo(boss.kinematicState.pos,100*length+speed*waitFrames/60,dir)
                Bullet{kinematicState={pos=copyTable(pos),dir=dir,speed=speed},lifeFrame=500,sprite=BulletSprites.ellipse.purple,extraUpdate=slashExtraUpdate,spriteColor={1,length,1,1}}.any={tilt=tilt}
                if i%5==0 then
                    SFX:play('enemyShot')
                    wait()
                    waitFrames=waitFrames+1
                end
            end
        end
        local function doubleSlash(tilt)
            Event{obj=mainSentry,action=function ()
                slash(tilt)
            end}
            wait(20)
            Event{obj=mainSentry,action=function ()
                slash(-tilt)
            end}
        end
        local function sideAttack()
            SFX:play('enemyPowerfulShot')
            local spawner=BulletSpawner{lifeFrame=4,period=9,firstPeriod=1,bulletNumber=DSWITCH{50,60,80,100},bulletSpeed=DSWITCH{70,80,90,100},bulletSprite=BulletSprites.bigStar.yellow,highlight=true,bulletLifeFrame=DSWITCH{450,500,550,600},bulletExtraUpdate={Action.FadeIn(20,true),Action.ZoomIn(30),Action.FadeOut(20,true),function (self)
                if self.frame>60 then
                    self.kinematicState.speed=math.lerp(self.kinematicState.speed,self.speed0,0.1)
                end
            end},bulletEvents={function (cir,args)
                local layer=args.index%2
                cir.angle=cir.kinematicState.dir-dir0
                local angle=math.angleDiff(cir.angle,math.pi/2)
                local threshold=math.pi/6
                local speedRatio=1/math.sin(angle)
                if speedRatio>1/math.sin(threshold) then
                    speedRatio=1/math.tan(threshold)/math.abs(math.cos(angle))
                end
                cir.speed0=cir.kinematicState.speed*speedRatio
                cir.kinematicState.speed=cir.speed0/5
            end}}
            spawner:bindState(boss)
        end
        Event.LoopEvent{obj=mainSentry,period=period,firstPeriod=1,executeFunc=function (self,times)
            local newPosb=geo:rThetaGo(boss.kinematicState.pos,math.eval(100,50),math.eval(0,99))
            if times%3==0 then
                sideAttack()
                newPosb=geo:rThetaGo(newPosb,350,dir0)
            else
                doubleSlash(times%3*0.4)
            end
            DanmakuFuncs.moveToInTime(boss,newPosb,240,Event.sineIOProgressFunc)
        end}
    end
}