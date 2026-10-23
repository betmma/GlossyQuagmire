---@return SpellcardPhase
return BossManager.SpellcardPhase{
    key='enri-wind',
    bonusScore=50000,
    time=2400,
    hp=4000,
    dropItems={powerSmall=30,point=15},
    func=function(self, boss)
        boss:addHPProtection(600,10)
        local geo=G.runInfo.geometry
        ---@cast geo Spherical
        local radius=geo.radius
        ---@cast geo GeometryBase
        local life=1200
        local function group(sprite,pole)
            SFX:play('enemyPowerfulShot')
            local sign=math.sign(pole.any.omega)
            local stopTime=180
            local groupExtraUpdate=function (self)
                local speed=self.any.speed
                if self.frame==self.any.initStopTime then
                    self.kinematicState.speed=0
                end
                if self.frame<=stopTime then
                elseif self.frame+stopTime>=self.lifeFrame then
                    self.kinematicState.speed=speed*((self.frame+stopTime-self.lifeFrame)/stopTime)
                else
                    local ratio=(self.frame-stopTime)/(self.lifeFrame-stopTime*2)
                    local omega=pole.any.omega*Event.sineIOProgressFunc(ratio)
                    local r,theta=geo:rThetaTo(pole.kinematicState.pos,self.kinematicState.pos)
                    theta=theta+omega
                    local newPos,newDir=geo:rThetaGo(pole.kinematicState.pos,r,theta)
                    local to=geo:to(self.kinematicState.pos,pole.kinematicState.pos)
                    self.kinematicState.dir=self.kinematicState.dir+(newDir-to+math.pi)
                    local dir=self.kinematicState.dir
                    local t1=self.frame-stopTime
                    local t2=self.lifeFrame-stopTime-self.frame
                    self.spriteExtraDirection=math.clamp(math.min(t1,t2)/60,0,1)*(math.modClamp(to-math.pi/2*sign,dir)-dir)
                    self.kinematicState.pos=newPos
                end
            end
            local extraUpdate={Action.FadeOut(10,true),groupExtraUpdate,Action.Trail(24,6,nil,0.8)}
            local n=DSWITCH{30,40,45,50}
            local goldenAngle = math.pi * (3 - math.sqrt(5))
            local function fogUpdate(self)
                local pos=self.kinematicState.pos
                local distance=geo:distance(pos,G.runInfo.player.kinematicState.pos)
                distance=math.min(distance,geo:distance(pos,boss.kinematicState.pos))
                self.spriteTransparency=math.clamp(distance/100*0.5-0.5,0,0.7)
            end
            for i=1,n do
                local angle=(i*goldenAngle*sign)%math.pi*2
                local distance=radius*math.acos(1-(2*i-1)/n)
            -- for i=1,n do
            --     local angle=math.pi*2/n*i
            --     local distance=radius*math.acos((i*3^0.5)%1*2-1) --math.eval(0,1)
                local initSpeed=radius*math.pi*60/stopTime
                local initStopTime=math.ceil(distance*60/initSpeed)
                local finalSpeed=(radius*math.pi-distance)*60/stopTime*2 -- remaining distance
                local bullet=Bullet{kinematicState={pos=copyTable(boss.kinematicState.pos),dir=angle,speed=initSpeed},lifeFrame=life,sprite=sprite,extraUpdate=extraUpdate,highlight=true,size=1.5,forceQuad=true,invincible=i%2==0}
                bullet.any={speed=finalSpeed,initStopTime=initStopTime}
                local fog=Bullet{safe=true,highlight=true,spriteTransparency=0,sprite=BulletSprites.darkLotus.gray,lifeFrame=life,extraUpdate=fogUpdate,forceQuad=true,size=2.5,invincible=i%2==0}:bindState(bullet)
            end
            Event{obj=pole,action=function()
                wait(stopTime)
                SFX:play('start')
                wait(life-stopTime*2-20)
                SFX:play('stop')
            end}
        end
        local function getPole(oscillateCenter,omega)
            local pole=DanmakuFuncs.sentry(oscillateCenter.kinematicState.pos)
            pole.lifeFrame=life
            pole.kinematicState.dir=math.eval(0,math.pi)
            pole.kinematicState.speed=DSWITCH{30,40,50,60}
            -- pole.spriteTransparency=0.6
            Event.LoopEvent{obj=pole,period=1,executeFunc=function ()
                local distance,to=geo:rThetaTo(pole.kinematicState.pos,oscillateCenter.kinematicState.pos)
                to=math.modClamp(to,pole.kinematicState.dir)
                local rotateSpeed=math.eval(0,0.01)+(to-pole.kinematicState.dir)*math.clamp((distance-50)/1000,0,0.1)
                pole.kinematicState.dir=pole.kinematicState.dir+rotateSpeed
            end}
            pole.any={omega=omega}
            return pole
        end
        local mainCenter=DanmakuFuncs.sentry(G.runInfo.player.kinematicState.pos)
        mainCenter.kinematicState.dir=math.eval(0,math.pi)
        mainCenter.kinematicState.speed=DSWITCH{5,10,15,20}
        Event.LoopEvent{obj=mainCenter,period=1,executeFunc=function ()
            mainCenter.kinematicState.dir=mainCenter.kinematicState.dir+math.eval(0,0.01)
            if mainCenter.frame%120==0 then
                local pos=geo:rThetaGo(mainCenter.kinematicState.pos,radius*math.pi,0)
                DanmakuFuncs.moveToInTime(boss,pos,120,Event.sineOProgressFunc)
            end
        end}
        for i=1,8 do
            SFX:play('enemyCharge')
            Effect.Charge{obj=boss}
            wait(60)
            local pole=getPole(mainCenter,math.mod2Sign(i)*0.04)
            local sprites={BulletSprites.ellipse.blue,BulletSprites.bigStar.yellow,BulletSprites.knife.red,BulletSprites.heart.green}
            local sprite=sprites[(i-1)%#sprites+1]
            group(sprite,pole)
            wait(DSWITCH{940,810,680,540})
        end
    end
}