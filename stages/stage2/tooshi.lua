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
            BossManager.NonSpellPhase{
                key='2-boss-tooshi-non-1',
                time=1500,
                hp=2000,
                func=function(self, boss)
                    boss.frame=0 -- for dance spellcard to align with music
                    local geo=G.runInfo.geometry
                    local basePos=geo:init().pos
                    for i=1,16 do
                        local sign=math.mod2Sign(i)
                        local dir=geo:to(boss.kinematicState.pos,G.runInfo.player.kinematicState.pos)
                        local spawner
                        local lifeFrame=60
                        spawner=BulletSpawner{angle=dir-math.pi*0.3*sign,range=math.pi*0,bulletNumber=15,lifeFrame=lifeFrame,period=2,bulletLifeFrame=300,bulletSize=0.25,bulletSpeed=500,bulletSprite=BulletSprites.ellipse.orange,highlight=true,bulletEvents={function(cir,args,self)
                            cir.kinematicState.dir=math.eval(cir.kinematicState.dir,0.01)
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
        }}
    }
}
return tooshiBoss