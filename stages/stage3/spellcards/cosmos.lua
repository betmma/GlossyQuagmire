---@return SpellcardPhase
return BossManager.SpellcardPhase{
    key='kora-cosmos',SKIP_INCLUDE=true,
    bonusScore=20000,
    time=1800,
    hp=3200,
    dropItems={life=1},
    func=function(self, boss)
        local geo=G.runInfo.geometry
        local basePos=geo:init().pos
        local posm,dirm=geo:rThetaGo(basePos,200,G.runInfo.player.viewDirection-math.pi/2)
        local posb,dirb=geo:rThetaGo(basePos,300,G.runInfo.player.viewDirection-math.pi/2)
        local n=12
        local petalN=DSWITCH{10,10,15,20}
        local petalAnglef=function(t)
            return math.pi/n*(t*(1-t))*DSWITCH{1,1,3,3}
        end
        local petalR=DSWITCH{150,200,200,200}
        local mirrorSignal=false
        for i=1,8 do
            local rand=math.eval(0,0.05)
            local angle=math.pi/2*math.mod2Sign(i)
            local posmi,dirmi=geo:rThetaGo(posm,100,angle+dirm)
            dirmi=dirmi+math.pi-math.pi/2*math.mod2Sign(i)+rand
            local posbi,dirbi=geo:rThetaGo(posb,100,angle+dirm)
            DanmakuFuncs.moveToInTime(boss,posbi,60,Event.sineOProgressFunc)
            wait(60)
            local t1=120
            if i==1 then
                t1=60
            end
            local petalUpdate=function(self)
                if mirrorSignal and not self.mirrored then
                    Mirror.spawnReflections(self,n-1)
                end
                if self.frame>=t1 and self.frame<=t1+60 then
                    self.kinematicState.speed=self.kinematicState.speed+1
                end
                if self.frame%50==0 and geo:distance(self.kinematicState.pos,basePos)>700 then
                    self:remove()
                end
            end
            Mirror.setHSV({math.eval(0,0.5),0.5,1},0.3/n)
            local r,g,b=math.hsvToRgb(Mirror.hsv[1],0.8,1)
            local spawner=BulletSpawner{lifeFrame=3,period=9,firstPeriod=1,bulletNumber=1,bulletSprite=BulletSprites.giant.white,bulletLifeFrame=300,bulletSpeed=0,angle=0,bulletEvents={function(cir,args,self)
                DanmakuFuncs.moveToInTime(cir,posmi,60,Event.sineOProgressFunc,true)
                Event{obj=cir,action=function()
                    local dir0=dirmi
                    for j=1,5 do -- warning bullets
                        local pos,dir=geo:rThetaGo(posmi,petalR*(j-0.5)/5,dir0)
                        local sprite=BulletSprites.cross.red
                        Bullet{kinematicState={pos=pos,dir=dir,speed=0},sprite=sprite,lifeFrame=60,extraUpdate={Action.FadeIn(5,true),Action.FadeOut(30,true)},invincible=true,safe=true,spriteColor={r,g,b,0.6},highlight=true,size=(j-0.5)}
                    end
                    wait(30)
                    SFX:play('enemyPowerfulShot')
                    for j=1,petalN do
                        local t=j/petalN
                        for sign=-1,1,2 do
                            local angle=petalAnglef(t)*sign
                            local pos,dir=geo:rThetaGo(cir.kinematicState.pos,petalR*t,angle+dir0)
                            local sprite=BulletSprites.scale.white
                            if DIFF()==G.LUNATIC and j%5==0 then
                                sprite=BulletSprites.ellipse.white
                                dir=dir+math.pi/2*sign
                            end
                            local new=Bullet{kinematicState={pos=pos,dir=dir+t*sign*DSWITCH{1,2,3,4},speed=0},sprite=sprite,lifeFrame=700,extraUpdate={Action.FadeIn(30,true),petalUpdate}}
                        end
                        wait(DSWITCH{2,2,2,1})
                    end
                end}
            end},bulletExtraUpdate={Action.ZoomIn(30),Action.ZoomOut(30)}}
            spawner:bindState(boss)
            local posmin=geo:rThetaGo(posmi,100,dirmi)
            for j=-1,1,2 do
                local posm2=geo:rThetaGo(posmi,400,dirmi+math.pi/n*j)
                Mirror(posmi,posm2,posmin,{extraUpdate={Action.FadeIn(t1,false,1),Action.FadeOut(30,false)},lifeFrame=t1+60})
            end
            wait(t1)
            mirrorSignal=true
            wait(1)
            mirrorSignal=false
            wait(59)
        end
    end
}