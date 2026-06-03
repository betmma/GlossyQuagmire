---@return SpellcardPhase
return BossManager.SpellcardPhase{
    key='kotoba-pupil',SKIP_INCLUDE=true,
    bonusScore=10000,
    time=1800,
    hp=2400,
    dropItems={point=15,powerSmall=10},
    func=function(self, boss)
        local center=G.runInfo.geometry:init().pos
        local period=300
        local time=200
        local spawner=BulletSpawner{kinematicState=copyTable(boss.kinematicState),
            period=period,firstPeriod=20,lifeFrame=1700,bulletNumber=DSWITCH{12,14,16,18},bulletSpeed=0,bulletSize=2,angle='0+999',bulletSprite=BulletSprites.human.orange,bulletLifeFrame=time+120,fogEffect=true,fogTime=30,spawnSFXVolume=2,bulletExtraUpdate={Action.FadeOut(30,true),function(self)
                if self.frame<time then
                    local dir=self.kinematicState.dir
                    local aim=math.modClamp(G.runInfo.geometry:to(self.kinematicState.pos,G.runInfo.player.kinematicState.pos),dir)
                    self.kinematicState.dir=math.lerp(dir,aim,0.05)
                end
            end},bulletEvents={
                function(cir,args,self)
                    self.invincible=true
                    local dir=cir.kinematicState.dir
                    local edge=G.runInfo.geometry:rThetaGo(G.runInfo.geometry:init().pos,380,dir)
                    DanmakuFuncs.moveToInTime(cir, edge, math.eval(180,15), Event.sineIOProgressFunc, false)
                    GeoLaser{kinematicState=cir.kinematicState,sprite=BulletSprites.laser.orange,size=1,rayAngle=0,spriteTransparency=0.3,safe=true,invincible=true,lifeFrame=time+120,meshBudget={capNum=3,step=100,num=16},extraUpdate={GeoLaser.presetActions.laserZoomIn(time),GeoLaser.presetActions.laserZoomOut(20),function(self)
                        if self.frame==time+50 then
                            Event.EaseEvent{obj=self,duration=20,aims={size=0.1},progressFunc=Event.sineBackProgressFunc}
                        end
                        if self.frame==time+60 then
                            self.safe=false
                        end
                        if time+60<=self.frame and self.frame<time+70 then
                            self.spriteTransparency=self.spriteTransparency+(1-0.3)/10
                        end
                    end}}:bindState(cir)
                    Event{obj=cir,action=function(self)
                        wait(time)
                        local pos,dir=cir.kinematicState.pos,cir.kinematicState.dir
                        local pos0=pos
                        local angle=G.runInfo.geometry:to(pos,center)
                        local range=math.pi
                        if DIFF()>=G.HARD then
                            range=range+math.eval(0,0.2)
                        end
                        if DIFF()>=G.NORMAL then
                            local warningSpawner=BulletSpawner{kinematicState={pos=copyTable(pos),dir=dir,speed=0},period=1,lifeFrame=1,bulletNumber=4,bulletSpeed=250,range=range,angle=angle,bulletSprite=BulletSprites.flame.white,bulletLifeFrame=120,highlight=true,bulletExtraUpdate={Action.Trail(10,5)},bulletEvents={function(cir,args)
                                cir.safe=true
                                cir.spriteColor={1,0.1,0.1,0.5}
                            end}}
                        end
                        wait(60)
                        local gap=DSWITCH{40,40,50,60} -- these bullets are decorative. reduce number on higher difficulties to reduce lag
                        local index=0
                        while G.runInfo.geometry:distance(pos, center) < 380 do
                            index=index+1
                            Bullet{kinematicState={pos=copyTable(pos),dir=dir+index%2*math.pi,speed=0},sprite=BulletSprites.flame.orange,size=1,highlight=true,lifeFrame=300,extraUpdate={Action.FadeIn(10,false),function(self)
                                if self.frame>=10 and self.frame<=50 then
                                    self.kinematicState.speed=self.kinematicState.speed+10
                                end
                            end}}
                            pos,dir=G.runInfo.geometry:rThetaGo(pos,gap,dir)
                        end
                        local baseSpeed=DSWITCH{150,'<','<',50}
                        if DIFF()>=G.NORMAL then
                            local spawner=BulletSpawner{kinematicState={pos=copyTable(pos0),dir=dir,speed=0},period=1,lifeFrame=5,bulletNumber=4,highlight=true,bulletSpeed=baseSpeed,range=range,angle=angle,bulletSprite=BulletSprites.flame.orange,bulletLifeFrame=DSWITCH{'>',90,180,300},bulletExtraUpdate={Action.FadeIn(10,true),Action.FadeOut(10,true)}}
                            Event.EaseEvent{obj=spawner,duration=5,aims={bulletSpeed=250}}
                        end
                    end}
                end
            }
        }
        Event.LoopEvent{obj=spawner,period=period,firstPeriod=time+50,executeFunc=function()
            SFX:play('enemyCharge',false)
        end}
        Event.LoopEvent{obj=spawner,period=period,firstPeriod=time+110,executeFunc=function()
            SFX:play('enemyPowerfulShot',false)
        end}
    end
}