
local midboss=BossManager.BossSegment{
    bossName='kotoba',
    players={REIMU=true,MARISA=true},
    key='1-mid-kotoba',
    getBossSpawnPos=function(self)
        local geometry=G.runInfo.geometry
        local pos,dir=geometry:rThetaGo(geometry:init().pos,100,G.runInfo.player.viewDirection-math.pi/2)
        return pos
    end,
    rounds={
        BossManager.BossRound{phases={
            BossManager.NonSpellPhase{
                key='1-mid-kotoba-non-1',
                time=1200,
                hp=1800,
                dropItems={point=15,powerSmall=10},
                func=function(self, boss)
                    local num=12
                    local eventFunc=function(self)
                        local cir=self.obj
                        local i,j=cir.i,cir.j
                        local index=cir.index
                        local edge=math.abs(i-math.floor(num/2))
                        wait(30)
                        local speedRef=cir.kinematicState.speed
                        for i=1,30 do
                            cir.kinematicState.speed=cir.kinematicState.speed*0.8
                        end
                        wait(30)
                        if index<3 then
                            cir.kinematicState.dir=math.eval(cir.kinematicState.dir,1.1)+math.pi
                            cir.kinematicState.speed=speedRef*2
                            cir.lifeFrame=cir.frame+60
                            return
                        end
                        local sign=math.sign(i-num/2+0.01)
                        if i%3<2 then
                            BulletSpawner.wrapFogEffect({fogTime=10,kinematicState=copyTable(cir.kinematicState),sprite=BulletSprites.fog.purple},function()end)
                            cir.kinematicState.dir=cir.kinematicState.dir-math.pi*(0.5)*cir.flip*math.mod2Sign(edge%3)
                            cir:changeSprite(BulletSprites.knife.purple)
                            cir.kinematicState.speed=speedRef/2*(0.9+0.3*math.sin(index/2))
                            Event.EaseEvent{obj=cir.kinematicState,aims={speed=speedRef/2},duration=240}
                        else
                            cir:changeSprite(BulletSprites.stone.purple)
                            cir.kinematicState.dir=cir.kinematicState.dir--sign*math.pi/8*flip
                            cir.kinematicState.speed=speedRef/2
                            if DIFF()==G.EASY then
                                cir.lifeFrame=cir.frame+60
                            end
                            -- Event.EaseEvent{obj=cir.kinematicState,aims={speed=speedRef/2},duration=120}
                        end
                    end
                    for j=1,6 do
                        local flip=math.mod2Sign(j)
                        local angle=G.runInfo.geometry:to(boss.kinematicState.pos,G.runInfo.player.kinematicState.pos)+math.eval(0,0.2)
                        for i=0,num-1 do
                            local dangle=math.pi/num*0.5*(i-num/2-i%3)*flip
                            local ovalangle=dangle-math.pi/2*flip
                            local r=((math.sin(ovalangle)*80)^2+(math.cos(ovalangle)*120)^2)^0.5
                            local pos,dir=G.runInfo.geometry:rThetaGo(boss.kinematicState.pos,r,angle+dangle)
                            for k=-1,1,2 do
                                local warningBullet=Bullet{kinematicState={pos=copyTable(pos),dir=dir+math.pi/2*k,speed=500},sprite=BulletSprites.ellipse.red,spriteColor={1,0.3,0.3,0.8},safe=true,invincible=true,lifeFrame=50,extraUpdate={Action.Trail(30,3)}}
                            end
                            local spawner=BulletSpawner{
                                kinematicState={pos=pos,dir=dir,speed=0},
                                period=1,firstPeriod=30,lifeFrame=DSWITCH{38,40,50,55},bulletNumber=2,bulletSpeed=90,range=math.pi*2,bulletSize=1,angle=dir,bulletSprite=BulletSprites.ellipse.gray,bulletLifeFrame=500,bulletExtraUpdate={Action.FadeOut(30,true)},bulletEvents={
                                    function(cir,args,self)
                                        cir.index=self.spawnTimes
                                        self.bulletSpeed=self.bulletSpeed+10
                                        cir.i,cir.j=i,j
                                        cir.flip=flip
                                        Event{obj=cir,action=eventFunc}
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
            -- },
        }}
    }
}
local addFollow=function(boss)
    local event=Event{obj=boss,action=function()
        while true do
            wait(121)
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
local finalBoss=BossManager.BossSegment{SKIP_INCLUDE=true,
    bossName='kotoba',
    key='1-boss-kotoba',
    BGM='level1b',
    players={REIMU=true,MARISA=true},
    beforeDialogueKey=function ()
        return G.runInfo.playerType..'S1BossBefore'
    end,
    afterDialogueKey=function ()
        return G.runInfo.playerType..'S1BossAfter'
    end,
    getBossSpawnPos=function(self)
        local geometry=G.runInfo.geometry
        local pos,dir=geometry:rThetaGo(geometry:init().pos,200,G.runInfo.player.viewDirection-math.pi/2)
        return pos
    end,
    rounds={
        BossManager.BossRound{phases={
            BossManager.NonSpellPhase{
                key='1-boss-kotoba-non-1',
                time=1500,
                hp=2000,
                func=function(self, boss)
                    addFollow(boss)
                    for j=1,6 do
                        local flip=math.mod2Sign(j)
                        local angle=G.runInfo.geometry:to(boss.kinematicState.pos,G.runInfo.player.kinematicState.pos)+math.eval(0,0.1)
                        local num=18
                        for i=1,num do
                            local dangle=math.pi/num*0.8*(i-num/2-0.5-(i-1)%3)*flip
                            local ovalangle=dangle-math.pi/4*flip
                            local r=((math.sin(ovalangle)*80)^2+(math.cos(ovalangle)*120)^2)^0.5
                            local pos,dir=G.runInfo.geometry:rThetaGo(boss.kinematicState.pos,r,angle+dangle)
                            local extraUpdate={Action.FadeOut(30,true),function(self)
                                if self.frame<100 then
                                    self.kinematicState.dir=self.kinematicState.dir+0.05*flip*math.mod2Sign(i)*self.kinematicState.speed/1000
                                end
                            end}
                            local warningBullet=Bullet{kinematicState={pos=copyTable(pos),dir=dir,speed=500},sprite=BulletSprites.ellipse.red,spriteColor={1,0.3,0.3,0.8},safe=true,invincible=true,lifeFrame=200,extraUpdate={extraUpdate[1],extraUpdate[2],Action.Trail(30,3)}}
                            local period=DSWITCH{2,2,1,1}
                            local spawner=BulletSpawner{
                                kinematicState={pos=pos,dir=dir,speed=0},
                                period=period,firstPeriod=30,lifeFrame=60,bulletNumber=1,bulletSpeed=0,range=math.pi/4,bulletSize=1,angle=dir,bulletSprite=BulletSprites.ellipse.gray,bulletLifeFrame=600,bulletExtraUpdate=extraUpdate,bulletEvents={
                                    function(cir,args,self)
                                        local index=self.spawnTimes
                                        -- self.angle=self.angle+math.pi/500*flip*math.mod2Sign(i)
                                        self.bulletSpeed=self.bulletSpeed+16*period
                                        Event{obj=cir,action=function()
                                            local edge=math.abs(i-math.floor(num/2))
                                            wait(120)
                                            local speedRef=cir.kinematicState.speed
                                            for i=1,60 do
                                                cir.kinematicState.speed=cir.kinematicState.speed*0.9
                                            end
                                            wait((32-index*period)*5)
                                            local sign=math.sign(i-num/2+0.01)
                                            if edge%3<2 then
                                                BulletSpawner.wrapFogEffect({fogTime=10,kinematicState=copyTable(cir.kinematicState),sprite=BulletSprites.fog.purple},function()end)
                                                cir.kinematicState.dir=cir.kinematicState.dir-math.pi*(0.95)*flip*math.mod2Sign(edge%3)
                                                cir:changeSprite(BulletSprites.knife.purple)
                                                local div=DSWITCH{'>','>',3,2}
                                                cir.kinematicState.speed=speedRef/div*(0.5+0.3*math.sin(index/2))
                                                Event.EaseEvent{obj=cir.kinematicState,aims={speed=speedRef/div},duration=120}
                                            else
                                                cir:changeSprite(BulletSprites.stone.purple)
                                                cir.kinematicState.dir=cir.kinematicState.dir-sign*math.pi*flip
                                                cir.kinematicState.speed=speedRef/2
                                                if DIFF()==G.EASY then
                                                    cir.lifeFrame=cir.frame+60
                                                end
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
            require 'stages.stage1.spellcards.swallow',
        }},
        BossManager.BossRound{SKIP_INCLUDE=true,phases={
            BossManager.NonSpellPhase{SKIP_INCLUDE=true,
                key='1-boss-kotoba-non-2',
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
                            local warningBullet=Bullet{kinematicState={pos=copyTable(pos),dir=dir,speed=500},sprite=BulletSprites.ellipse.red,spriteColor={1,0.3,0.3,0.8},safe=true,invincible=true,lifeFrame=200,extraUpdate={Action.Trail(30,3)}}
                            local period=DSWITCH{3,2,1,1}
                            local spawner=BulletSpawner{
                                kinematicState={pos=pos,dir=dir,speed=0},
                                period=period,firstPeriod=30,lifeFrame=60,bulletNumber=1,bulletSpeed=40,range=math.pi/4,bulletSize=1,angle=dir,bulletSprite=BulletSprites.ellipse.gray,bulletLifeFrame=600,bulletExtraUpdate={Action.FadeOut(30,true)},bulletEvents={
                                    function(cir,args,self)
                                        local index=self.spawnTimes
                                        -- self.angle=self.angle+math.pi/500*flip*math.mod2Sign(i)
                                        self.bulletSpeed=self.bulletSpeed+30*period
                                        Event{obj=cir,action=function()
                                            local edge=math.abs(i-math.floor(num/2))
                                            wait(60)
                                            local speedRef=cir.kinematicState.speed
                                            for i=1,60 do
                                                cir.kinematicState.speed=cir.kinematicState.speed*0.9
                                            end
                                            wait((32-index*period)*5)
                                            local sign=math.sign(i-num/2+0.01)
                                            if edge%3<2 then
                                                BulletSpawner.wrapFogEffect({fogTime=10,kinematicState=copyTable(cir.kinematicState),sprite=BulletSprites.fog.purple},function()end)
                                                cir.kinematicState.dir=cir.kinematicState.dir-math.pi*(0.95)*flip*math.mod2Sign(edge%3)
                                                cir:changeSprite(BulletSprites.knife.purple)
                                                local div=4
                                                cir.kinematicState.speed=speedRef/div*(0.5+0.5*math.sin(index/2))
                                                Event.EaseEvent{obj=cir.kinematicState,aims={speed=speedRef/div},duration=120}
                                            else
                                                cir:changeSprite(BulletSprites.stone.purple)
                                                cir.kinematicState.dir=cir.kinematicState.dir-sign*math.pi*flip
                                                cir.kinematicState.speed=speedRef/2
                                                wait(140)
                                                cir.kinematicState.dir=G.runInfo.geometry:to(cir.kinematicState.pos,G.runInfo.player.kinematicState.pos)+edge*sign*DSWITCH{0.07,0.05,0.05,0.03}
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
            require 'stages.stage1.spellcards.pupil',
            require 'stages.stage1.spellcards.lead',
        }},
    }
}
---@type BossSegment[]
return {
    midboss,
    finalBoss
}