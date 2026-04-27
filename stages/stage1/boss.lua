
---@type BossSegment
return BossManager.BossSegment{
    bossName='kotoba',
    key='1-mid',
    getBossSpawnPos=function(self)
        local geometry=G.runInfo.geometry
        local pos,dir=geometry:rThetaGo(geometry:init().pos,200,G.runInfo.player.viewDirection-math.pi/2)
        return pos
    end,
    rounds={
        BossManager.BossRound{phases={
            BossManager.NonSpellPhase{
                time=1200,
                hp=1800,
                func=function(self, boss)
                    for j=1,4 do
                        local flip=math.mod2Sign(j)
                        local angle=G.runInfo.geometry:to(boss.kinematicState.pos,G.runInfo.player.kinematicState.pos)
                        local num=40
                        for i=1,num do
                            local dangle=math.pi/num*2*(i-num/2)*flip
                            local r=(120-80*math.abs(math.sin(dangle-math.pi/4*flip)))*(j*0.2+1)
                            local pos,dir=G.runInfo.geometry:rThetaGo(boss.kinematicState.pos,r,angle+dangle)
                            local spawner=BulletSpawner{
                                kinematicState={pos=pos,dir=dir,speed=0},
                                period=3,firstPeriod=30,lifeFrame=60,bulletNumber=2,bulletSpeed=90,range=math.pi/4,bulletSize=1,angle=dir,bulletSprite=BulletSprites.heart.gray,bulletLifeFrame=600,bulletEvents={
                                    function(cir,args,self)
                                        self.bulletSpeed=self.bulletSpeed+7
                                        Event{obj=cir,action=function()
                                            local edge=math.abs(i-num/2)
                                            wait(30)
                                            local speedRef=cir.kinematicState.speed
                                            for i=1,30 do
                                                cir.kinematicState.speed=cir.kinematicState.speed*0.8
                                            end
                                            wait(30)
                                            if edge>10 then
                                                cir.kinematicState.dir=math.eval(cir.kinematicState.dir,1.5)
                                                cir:changeSpriteColor('yellow')
                                                cir.kinematicState.speed=speedRef
                                                return
                                            end
                                            local sign=math.sign(i-num/2)
                                            if edge>3 then
                                                wait((edge-3)*10)
                                                cir.kinematicState.dir=cir.kinematicState.dir-sign*math.pi*(0.5+edge*0.03)*flip
                                                cir:changeSpriteColor('green')
                                                cir.kinematicState.speed=speedRef
                                            else
                                                wait(30)
                                                cir:changeSpriteColor('purple')
                                                cir.kinematicState.speed=speedRef
                                            end
                                        end}
                                    end
                                }
                            }
                            wait()
                        end
                        wait(220)
                    end
                end
            },
            -- BossManager.SpellcardPhase{
            --     key='test',
            --     bonusScore=10000,
            --     time=900,
            --     hp=900,
            --     dropItems={life=1},
            --     name='Test Spell',
            --     func=function(self, boss)
            --         local spawner=BulletSpawner{
            --             period=20,firstPeriod=20,lifeFrame=880,bulletNumber=5,bulletSpeed=150,bulletSize=1,angle='player',bulletSprite=BulletSprites.round.blue,bulletLifeFrame=600
            --         }:bindState(boss)
            --     end
            -- }
        }}
    }
}