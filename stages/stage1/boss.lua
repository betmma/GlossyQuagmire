
local midboss=BossManager.BossSegment{
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
                    for j=1,6 do
                        local flip=math.mod2Sign(j)
                        local angle=G.runInfo.geometry:to(boss.kinematicState.pos,G.runInfo.player.kinematicState.pos)+math.eval(0,0.1)
                        local num=21
                        for i=1,num do
                            local dangle=math.pi/num*1*(i-num/2-i%3)*flip
                            local ovalangle=dangle-math.pi/4*flip
                            local r=((math.sin(ovalangle)*80)^2+(math.cos(ovalangle)*120)^2)^0.5
                            local pos,dir=G.runInfo.geometry:rThetaGo(boss.kinematicState.pos,r,angle+dangle)
                            local spawner=BulletSpawner{
                                kinematicState={pos=pos,dir=dir,speed=0},
                                period=1,firstPeriod=30,lifeFrame=60,bulletNumber=2,bulletSpeed=90,range=math.pi*2,bulletSize=1,angle=dir,bulletSprite=BulletSprites.ellipse.gray,bulletLifeFrame=600,bulletExtraUpdate={Action.FadeOut(30,true)},bulletEvents={
                                    function(cir,args,self)
                                        local index=self.spawnTimes
                                        self.bulletSpeed=self.bulletSpeed+10
                                        Event{obj=cir,action=function()
                                            local edge=math.abs(i-math.floor(num/2))
                                            wait(30)
                                            local speedRef=cir.kinematicState.speed
                                            for i=1,30 do
                                                cir.kinematicState.speed=cir.kinematicState.speed*0.8
                                            end
                                            wait(30)
                                            if index<5 then
                                                cir.kinematicState.dir=math.eval(cir.kinematicState.dir,1.1)+math.pi
                                                cir.kinematicState.speed=speedRef*2
                                                cir.lifeFrame=cir.frame+90
                                                return
                                            end
                                            local sign=math.sign(i-num/2+0.01)
                                            if edge%3<2 then
                                                BulletSpawner.wrapFogEffect({fogTime=10,kinematicState=copyTable(cir.kinematicState),sprite=BulletSprites.fog.purple},function()end)
                                                cir.kinematicState.dir=cir.kinematicState.dir-math.pi*(0.5)*flip*math.mod2Sign(edge%3)
                                                cir:changeSprite(BulletSprites.knife.purple)
                                                cir.kinematicState.speed=speedRef/4*(0.5+0.3*math.sin(index/2))
                                                Event.EaseEvent{obj=cir.kinematicState,aims={speed=speedRef/4},duration=120}
                                            else
                                                cir:changeSprite(BulletSprites.stone.purple)
                                                cir.kinematicState.dir=cir.kinematicState.dir--sign*math.pi/8*flip
                                                cir.kinematicState.speed=speedRef/4
                                                -- Event.EaseEvent{obj=cir.kinematicState,aims={speed=speedRef/2},duration=120}
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
local addFollow=function(boss)
    local event=Event{obj=boss,action=function()
        while true do
            wait(100)
            local aim=G.runInfo.geometry:rThetaGo(G.runInfo.player.kinematicState.pos,400,G.runInfo.player.viewDirection-math.pi/2)
            for i=1,60 do
                local dir=G.runInfo.geometry:to(boss.kinematicState.pos,aim)
                local distance=G.runInfo.geometry:distance(boss.kinematicState.pos,aim)
                boss.kinematicState.pos=G.runInfo.geometry:rThetaGo(boss.kinematicState.pos,distance/30,dir)
                wait()
            end
            wait(60)
        end
    end}
    EventManager.listenTo(EventManager.EVENTS.FINISH_BOSS_PHASE,function()
        event:remove()
    end,EventManager.EVENTS.FINISH_BOSS_PHASE)
end
local finalBoss=BossManager.BossSegment{
    bossName='kotoba',
    key='1-boss',
    getBossSpawnPos=function(self)
        local geometry=G.runInfo.geometry
        local pos,dir=geometry:rThetaGo(geometry:init().pos,200,G.runInfo.player.viewDirection-math.pi/2)
        return pos
    end,
    rounds={
        BossManager.BossRound{phases={
            BossManager.NonSpellPhase{
                time=1500,
                hp=2000,
                func=function(self, boss)
                    addFollow(boss)
                    for j=1,6 do
                        local flip=math.mod2Sign(j)
                        local angle=G.runInfo.geometry:to(boss.kinematicState.pos,G.runInfo.player.kinematicState.pos)+math.eval(0,0.1)
                        local num=21
                        for i=1,num do
                            local dangle=math.pi/num*1*(i-num/2-0.5-(i-1)%3)*flip
                            local ovalangle=dangle-math.pi/4*flip
                            local r=((math.sin(ovalangle)*80)^2+(math.cos(ovalangle)*120)^2)^0.5
                            local pos,dir=G.runInfo.geometry:rThetaGo(boss.kinematicState.pos,r,angle+dangle)
                            local spawner=BulletSpawner{
                                kinematicState={pos=pos,dir=dir,speed=0},
                                period=1,firstPeriod=30,lifeFrame=60,bulletNumber=1,bulletSpeed=0,range=math.pi/4,bulletSize=1,angle=dir,bulletSprite=BulletSprites.ellipse.gray,bulletLifeFrame=600,bulletExtraUpdate={Action.FadeOut(30,true),function(self)
                                    if self.frame<100 then
                                        self.kinematicState.dir=self.kinematicState.dir+0.05*flip*math.mod2Sign(i)*self.kinematicState.speed/1000
                                    end
                                end},bulletEvents={
                                    function(cir,args,self)
                                        local index=self.spawnTimes
                                        -- self.angle=self.angle+math.pi/500*flip*math.mod2Sign(i)
                                        self.bulletSpeed=self.bulletSpeed+16
                                        Event{obj=cir,action=function()
                                            local edge=math.abs(i-math.floor(num/2))
                                            wait(120)
                                            local speedRef=cir.kinematicState.speed
                                            for i=1,60 do
                                                cir.kinematicState.speed=cir.kinematicState.speed*0.9
                                            end
                                            wait((32-index)*5)
                                            local sign=math.sign(i-num/2+0.01)
                                            if edge%3<2 then
                                                BulletSpawner.wrapFogEffect({fogTime=10,kinematicState=copyTable(cir.kinematicState),sprite=BulletSprites.fog.purple},function()end)
                                                cir.kinematicState.dir=cir.kinematicState.dir-math.pi*(0.95)*flip*math.mod2Sign(edge%3)
                                                cir:changeSprite(BulletSprites.knife.purple)
                                                cir.kinematicState.speed=speedRef/3*(0.5+0.3*math.sin(index/2))
                                                Event.EaseEvent{obj=cir.kinematicState,aims={speed=speedRef/3},duration=120}
                                            else
                                                cir:changeSprite(BulletSprites.stone.purple)
                                                cir.kinematicState.dir=cir.kinematicState.dir-sign*math.pi*flip
                                                cir.kinematicState.speed=speedRef/2
                                                -- wait(140)
                                                -- cir.kinematicState.dir=G.runInfo.geometry:to(cir.kinematicState.pos,G.runInfo.player.kinematicState.pos)+edge*sign*0.03
                                                -- cir.kinematicState.speed=400
                                                -- Event.EaseEvent{obj=cir.kinematicState,aims={speed=speedRef/2},duration=120}
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
        }},
        BossManager.BossRound{phases={
            BossManager.NonSpellPhase{
                time=1500,
                hp=2000,
                func=function(self, boss)
                    for j=1,6 do
                        local flip=math.mod2Sign(j)
                        local angle=G.runInfo.geometry:to(boss.kinematicState.pos,G.runInfo.player.kinematicState.pos)+math.eval(0,0.1)
                        local num=21
                        for i=1,num do
                            local dangle=math.pi/num*1*(i-num/2-0.5-(i-1)%3)*flip
                            local ovalangle=dangle-math.pi/4*flip
                            local r=((math.sin(ovalangle)*80)^2+(math.cos(ovalangle)*120)^2)^0.5
                            local pos,dir=G.runInfo.geometry:rThetaGo(boss.kinematicState.pos,r,angle+dangle)
                            local spawner=BulletSpawner{
                                kinematicState={pos=pos,dir=dir,speed=0},
                                period=1,firstPeriod=30,lifeFrame=60,bulletNumber=1,bulletSpeed=40,range=math.pi/4,bulletSize=1,angle=dir,bulletSprite=BulletSprites.ellipse.gray,bulletLifeFrame=600,bulletExtraUpdate={Action.FadeOut(30,true)},bulletEvents={
                                    function(cir,args,self)
                                        local index=self.spawnTimes
                                        -- self.angle=self.angle+math.pi/500*flip*math.mod2Sign(i)
                                        self.bulletSpeed=self.bulletSpeed+30
                                        Event{obj=cir,action=function()
                                            local edge=math.abs(i-math.floor(num/2))
                                            wait(60)
                                            local speedRef=cir.kinematicState.speed
                                            for i=1,60 do
                                                cir.kinematicState.speed=cir.kinematicState.speed*0.9
                                            end
                                            wait((32-index)*5)
                                            local sign=math.sign(i-num/2+0.01)
                                            if edge%3<2 then
                                                BulletSpawner.wrapFogEffect({fogTime=10,kinematicState=copyTable(cir.kinematicState),sprite=BulletSprites.fog.purple},function()end)
                                                cir.kinematicState.dir=cir.kinematicState.dir-math.pi*(0.95)*flip*math.mod2Sign(edge%3)
                                                cir:changeSprite(BulletSprites.knife.purple)
                                                cir.kinematicState.speed=speedRef/3*(0.5+0.3*math.sin(index/2))
                                                Event.EaseEvent{obj=cir.kinematicState,aims={speed=speedRef/3},duration=120}
                                            else
                                                cir:changeSprite(BulletSprites.stone.purple)
                                                cir.kinematicState.dir=cir.kinematicState.dir-sign*math.pi*flip
                                                cir.kinematicState.speed=speedRef/2
                                                wait(140)
                                                cir.kinematicState.dir=G.runInfo.geometry:to(cir.kinematicState.pos,G.runInfo.player.kinematicState.pos)+edge*sign*0.03
                                                cir.kinematicState.speed=400
                                                -- Event.EaseEvent{obj=cir.kinematicState,aims={speed=speedRef/2},duration=120}
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
            require 'stages.stage1.spellcards.swallow',
        }},
    }
}
---@type BossSegment[]
return {
    midboss,
    finalBoss
}