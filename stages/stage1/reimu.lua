local midboss=BossManager.BossSegment{SKIP_INCLUDE=true,
    bossName='reimu',
    players={KOTOBA=true},
    key='1-mid-reimu',
    getBossSpawnPos=function(self)
        local geometry=G.runInfo.geometry
        local pos,dir=geometry:rThetaGo(geometry:init().pos,100,G.runInfo.player.viewDirection-math.pi/2)
        return pos
    end,
    rounds={
        BossManager.BossRound{SKIP_INCLUDE=true,phases={
            BossManager.NonSpellPhase{SKIP_INCLUDE=true,
                key='1-mid-reimu-non-1',
                time=1200,
                hp=1200,
                dropItems={point=15,powerSmall=10},
                func=function(self, boss)
                    local pos0=copyTable(boss.kinematicState.pos)
                    local center=G.runInfo.geometry:init().pos
                    local dummy=Bullet{kinematicState={pos=copyTable(boss.kinematicState.pos),speed=0,dir=0},sprite=BulletSprites.bill.red,lifeFrame=1200,invincible=true,safe=true,spriteTransparency=0}
                    Event.LoopEvent{obj=dummy,period=120,executeFunc=function()
                        local tocenter=G.runInfo.geometry:to(boss.kinematicState.pos,pos0)
                        local aim=G.runInfo.geometry:rThetaGo(boss.kinematicState.pos,math.eval(80,40),math.eval(tocenter,1))
                        DanmakuFuncs.moveToInTime(boss,aim,60,Event.sineOProgressFunc)
                    end}
                    local n=DSWITCH{10,16,17,21}
                    local spawner=BulletSpawner{period=5,firstPeriod=30,lifeFrame=1200,bulletNumber=n,angle='player',bulletSpeed=DSWITCH{180,210,240,270},bulletLifeFrame=240,bulletSprite=BulletSprites.bill.red}
                    Event.LoopEvent{obj=spawner,period=1,executeFunc=function()
                        if (spawner.frame-30)%60>40 then
                            spawner.bulletNumber=0
                        else
                            spawner.bulletNumber=n
                        end
                    end}
                    spawner:bindState(boss)
                    local spawner2=BulletSpawner{period=DSWITCH{120,90,120,90},lifeFrame=1200,firstPeriod=30,bulletNumber=1,angle=0,bulletSpeed=200,bulletLifeFrame=120,bulletSprite=BulletSprites.largeOrb.red,bulletEvents={function(cir,args,self)
                        cir.spriteRotationSpeed=0.05
                        local toPlayer=G.runInfo.geometry:to(cir.kinematicState.pos,G.runInfo.player.kinematicState.pos)
                        cir.kinematicState.dir=toPlayer+math.eval(math.pi/2,0.3)*math.randomSign()
                        Event.EaseEvent{obj=cir,easeObj=cir.kinematicState,aims={speed=0},duration=100,progressFunc=Event.sineOProgressFunc,afterFunc=function()
                            SFX:play('enemyPowerfulShot')
                            local n1=DSWITCH{40,60,70,80}
                            BulletSpawner{kinematicState=copyTable(cir.kinematicState),period=1,lifeFrame=2,bulletNumber=n1/2,angle='0+999',bulletSpeed=180,bulletSize=1.5,bulletLifeFrame=300,bulletSprite=BulletSprites.bigRound.red,visible=false,bulletExtraUpdate={Action.FadeOut(20,true)},bulletEvents={function(cir,args,self)
                                cir.kinematicState.speed=cir.kinematicState.speed*math.eval(1,0.1)
                            end}}
                            BulletSpawner{kinematicState=copyTable(cir.kinematicState),period=1,lifeFrame=2,bulletNumber=n1,angle='0+999',bulletSpeed=180,bulletLifeFrame=300,bulletSprite=BulletSprites.bill.gray,visible=false,bulletExtraUpdate={Action.FadeOut(20,true)}}
                            cir:remove()
                        end}
                    end},bulletExtraUpdate={Action.FadeOut(20,true)}}
                    spawner2:bindState(boss)
                end
            },
            BossManager.SpellcardPhase{SKIP_INCLUDE=true,
                key='reimu-dream-seal',
                difficulties={HARD=true,LUNATIC=true},
                bonusScore=10000,
                time=1200,
                hp=1200,
                dropItems={point=15},
                func=function(self, boss)
                    local function largeOrb(dir)
                        local largeOrbLife=60
                        local orb=Bullet{kinematicState={pos=copyTable(boss.kinematicState.pos),speed=500,dir=dir},sprite=BulletSprites.largeOrb.red,lifeFrame=largeOrbLife,extraUpdate={Action.FadeOut(10,true)}}
                        local spawner=BulletSpawner{period=8,lifeFrame=largeOrbLife,bulletNumber=DSWITCH{1,2,3,4},range=0,bulletSpeed=100,angle='player',bulletSprite=BulletSprites.bill.red,bulletLifeFrame=600,visible=true,bulletEvents={function(cir,args,self)
                            local waitFrame=orb.lifeFrame-orb.frame
                            local speedRatio=(1+(args.index-1)*0.5)
                            cir.kinematicState.speed=cir.kinematicState.speed*speedRatio
                            Event.Event{obj=cir,action=function()
                                wait(waitFrame+1)
                                for i=1,3 do
                                    local dir=G.runInfo.geometry:to(cir.kinematicState.pos,G.runInfo.player.kinematicState.pos)
                                    cir.kinematicState.dir=dir
                                    cir.kinematicState.speed=120*speedRatio
                                    local colors={'purple','blue','white'}
                                    local color=colors[i]
                                    cir:changeSpriteColor(color)
                                    SFX:play('enemyShot')
                                    if i==3 then
                                        cir.flag=true
                                    end
                                    wait(60)
                                end
                            end}
                        end},bulletExtraUpdate={function(self)
                            if self.flag then return end
                            self.kinematicState.speed=self.kinematicState.speed*0.95
                        end}}
                        spawner:bindState(orb)
                        if DIFF()<=G.NORMAL then
                            return
                        end
                        local spawner2=BulletSpawner{period=largeOrbLife-1,lifeFrame=largeOrbLife,bulletNumber=16,range=0,bulletSpeed=70,angle='player',bulletSize=2,bulletSprite=BulletSprites.billDark.red,bulletLifeFrame=600,visible=false,bulletEvents={function(cir,args,self)
                            if args.index%4>=2 then
                                cir:changeSprite(BulletSprites.bill.red)
                            end
                            if args.index%2==0 then
                                cir:changeSpriteColor('blue')
                            end
                            SFX:play('enemyShot')
                            local m,n=args.index%8,math.ceil(args.index/8)
                            cir.kinematicState.speed=cir.kinematicState.speed*(1+m*0.5)
                            cir.kinematicState.dir=cir.kinematicState.dir+math.pi/16*(n-1.5)
                        end}}
                        spawner2:bindState(orb)
                    end
                    wait(60)
                    for i=1,4 do
                        local dir=G.runInfo.geometry:to(boss.kinematicState.pos,G.runInfo.player.kinematicState.pos)
                        for j=1,3 do
                            largeOrb(dir+math.pi/6*j)
                            wait(20)
                        end
                        wait(120)
                        for j=1,3 do
                            largeOrb(dir-math.pi/6*j)
                            wait(20)
                        end
                        wait(120)
                        for j=1,3 do
                            largeOrb(dir+math.pi/6*j)
                            largeOrb(dir-math.pi/6*j)
                            wait(10)
                        end
                        wait(120)
                        for j=1,3 do
                            largeOrb(dir+math.pi+math.pi/6*j)
                            largeOrb(dir+math.pi-math.pi/6*j)
                            wait(10)
                        end
                        wait(120)
                    end
                end
            },
        }}
    }
}

---@return BossSegment
return midboss