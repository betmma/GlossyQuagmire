local tooshiBoss=BossManager.BossSegment{
    bossName='tooshi',
    key='2-boss',
    BGM='level2b',
    -- beforeDialogueKey=function ()
    --     return G.runInfo.playerType..'S2BossBefore'
    -- end,
    getBossSpawnPos=function(self)
        local geo=G.runInfo.geometry
        local basePos=geo:init().pos
        local pos,dir=geo:rThetaGo(basePos,200,-math.pi/2)
        return pos
    end,
    rounds={
        BossManager.BossRound{SKIP_INCLUDE=true,phases={
            BossManager.NonSpellPhase{SKIP_INCLUDE=true,
                key='2-boss-tooshi-non-1',
                time=1500,
                hp=2000,
                func=function(self, boss)
                    boss.frame=0 -- for dance spellcard to align with music
                    local geo=G.runInfo.geometry
                    local basePos=geo:init().pos
                    wait(30)
                    for i=1,16 do
                        local sign=math.mod2Sign(i)
                        local dir=geo:to(boss.kinematicState.pos,G.runInfo.player.kinematicState.pos)
                        local spawner
                        local lifeFrame=60
                        spawner=BulletSpawner{angle=dir-math.pi*0.3*sign,range=math.pi*0,bulletNumber=15,lifeFrame=lifeFrame,period=2,bulletLifeFrame=300,bulletSize=0.25,bulletSpeed=500,bulletSprite=BulletSprites.ellipse.orange,highlight=true,bulletEvents={function(cir,args,self)
                            cir.kinematicState.dir=math.eval(cir.kinematicState.dir,0.005)
                            cir.speedRef=cir.kinematicState.speed+math.eval(0,30)
                            cir.keyFrame=lifeFrame+spawner.frame
                            Event.EaseEvent{obj=cir,easeObj=cir.kinematicState,aims={speed=50},duration=lifeFrame}
                        end},bulletExtraUpdate={function(self)
                            if self.frame>self.keyFrame then
                                if not self.flag then
                                    self.batch=BulletBatch
                                    self.spriteTransparency=0
                                    self.flag=true
                                    local removeThre=DSWITCH{0.8,0.6,0.3,0}
                                    if math.random()<removeThre then
                                        self:remove()
                                        return
                                    end
                                end
                                self.spriteTransparency=math.min(1,self.spriteTransparency+0.05)
                                self.kinematicState.dir=self.kinematicState.dir+0.01*sign
                                self.kinematicState.speed=self.kinematicState.speed+self.speedRef*0.01
                            end
                        end}}
                        spawner:bindState(boss)
                        Event.EaseEvent{obj=spawner,aims={angle=spawner.angle+math.pi*0.7*sign,bulletSpeed=0},duration=lifeFrame}
                        Event.EaseEvent{obj=spawner,aims={range=math.pi/2,bulletSize=1},duration=lifeFrame,progressFunc=Event.sineBackProgressFunc}
                        wait(180)
                    end
                end
            },
            require('stages.stage2.spellcards.dance'),
        }},
        BossManager.BossRound{SKIP_INCLUDE=true,phases={
            BossManager.NonSpellPhase{SKIP_INCLUDE=true,
                key='2-boss-tooshi-non-2',
                time=1500,
                hp=1600,
                func=function(self, boss)
                    local geo=G.runInfo.geometry
                    local basePos=geo:init().pos
                    local pos,dir=geo:rThetaGo(basePos,200,-math.pi/2)
                    DanmakuFuncs.moveToInTime(boss,pos,60,Event.sineOProgressFunc)
                    wait(60)
                    for i=1,16 do
                        local sign=math.mod2Sign(i)
                        local dir=geo:to(boss.kinematicState.pos,G.runInfo.player.kinematicState.pos)
                        -- laser
                        local laserTime=80
                        local laserBase=Bullet{kinematicState={pos=copyTable(boss.kinematicState.pos),dir=dir-sign*1,speed=300},sprite=BulletSprites.giant.orange,lifeFrame=laserTime+40,invincible=true,highlight=true,extraUpdate={function(self)
                            self.kinematicState.speed=self.kinematicState.speed*0.95
                        end,Action.ZoomIn(20),Action.ZoomOut(20)}}
                        local laser=GeoLaser{kinematicState={pos=copyTable(boss.kinematicState.pos),dir=geo:to(boss.kinematicState.pos,G.runInfo.player.kinematicState.pos),speed=0},sprite=BulletSprites.laser.orange,size=0.1,rayAngle=0,spriteTransparency=0.3,safe=true,invincible=true,lifeFrame=laserBase.lifeFrame,meshBudget={capNum=3,step=25,num=16},extraUpdate={GeoLaser.presetActions.laserZoomIn(20),GeoLaser.presetActions.laserZoomOut(20),function(self)
                            self.kinematicState.pos=copyTable(laserBase.kinematicState.pos)
                            if self.frame<laserTime-20 then
                                local dir=self.kinematicState.dir
                                local aim=math.modClamp(G.runInfo.geometry:to(self.kinematicState.pos,G.runInfo.player.kinematicState.pos),dir)
                                self.kinematicState.dir=math.lerp(dir,aim,0.05)
                            elseif self.frame==laserTime-20 then
                                SFX:play('enemyCharge')
                            end
                            if self.frame==laserTime then
                                Event.EaseEvent{obj=self,duration=20,aims={size=1},progressFunc=Event.sineOProgressFunc}
                            end
                            if self.frame==laserTime+10 then
                                self.safe=false
                            end
                            if laserTime+10<=self.frame and self.frame<laserTime+20 then
                                self.spriteTransparency=self.spriteTransparency+(1-0.3)/10
                            end
                        end}}
                        -- 
                        local spawner
                        local lifeFrame=60
                        spawner=BulletSpawner{angle=dir-math.pi*0.3*sign,range=math.pi*0,bulletNumber=30,lifeFrame=lifeFrame,period=4,bulletLifeFrame=300,bulletSize=0.25,bulletSpeed=500,bulletSprite=BulletSprites.ellipse.orange,highlight=true,bulletEvents={function(cir,args,self)
                            cir.kinematicState.dir=math.eval(cir.kinematicState.dir,0.01)
                            cir.speedRef=cir.kinematicState.speed+math.eval(0,30)
                            cir.keyFrame=lifeFrame+spawner.frame
                            Event.EaseEvent{obj=cir,easeObj=cir.kinematicState,aims={speed=50},duration=lifeFrame}
                        end},bulletExtraUpdate={function(self)
                            local dt=laser.frame-laserTime
                            if self.frame<120 and dt==10 then -- reduce check cost
                                if laser:collide(self.kinematicState.pos,self:getHitboxRadius()*DSWITCH{3,2,1.5,1}) then
                                    self.lifeFrame=self.frame+10
                                    self.extraUpdate[#self.extraUpdate+1]=Action.FadeOut(9,true)
                                    return
                                end
                            end
                            if self.frame>self.keyFrame then
                                self.spriteTransparency=math.min(1,self.spriteTransparency+0.05)
                                self.kinematicState.dir=self.kinematicState.dir+0.01*sign
                                self.kinematicState.speed=self.kinematicState.speed+self.speedRef*0.01
                            end
                        end}}
                        spawner:bindState(boss)
                        Event.EaseEvent{obj=spawner,aims={angle=spawner.angle+math.pi*0.7*sign,bulletSpeed=0},duration=lifeFrame}
                        Event.EaseEvent{obj=spawner,aims={range=math.pi/2,bulletSize=1},duration=lifeFrame,progressFunc=Event.sineBackProgressFunc}
                        wait(180)
                    end
                end
            },
            require('stages.stage2.spellcards.lantern')
        }},
        BossManager.BossRound{phases={
            require('stages.stage2.spellcards.flower')
        }},
    }
}
return tooshiBoss