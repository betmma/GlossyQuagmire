local midboss=BossManager.BossSegment{
    bossName='reimu',
    players={KOTOBA=true},
    key='1-mid-reimu',
    getBossSpawnPos=function(self)
        local geometry=G.runInfo.geometry
        local pos,dir=geometry:rThetaGo(geometry:init().pos,100,G.runInfo.player.viewDirection-math.pi/2)
        return pos
    end,
    rounds={
        BossManager.BossRound{phases={
            BossManager.SpellcardPhase{
                key='reimu-dream-seal',
                bonusScore=10000,
                time=1200,
                hp=1200,
                dropItems={point=15,powerSmall=10},
                func=function(self, boss)
                    local function largeOrb(dir)
                        local largeOrbLife=60
                        local orb=Bullet{kinematicState={pos=copyTable(boss.kinematicState.pos),speed=500,dir=dir},sprite=BulletSprites.lightRound.red,lifeFrame=largeOrbLife,}
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
                        local spawner2=BulletSpawner{period=largeOrbLife-1,lifeFrame=largeOrbLife,bulletNumber=16,range=0,bulletSpeed=70,angle='player',bulletSize=2,bulletSprite=BulletSprites.billDark.red,bulletLifeFrame=600,visible=false,bulletEvents={function(cir,args,self)
                            SFX:play('enemyShot')
                            local m,n=args.index%8,math.ceil(args.index/8)
                            cir.kinematicState.speed=cir.kinematicState.speed*(1+m*0.5)
                            cir.kinematicState.dir=cir.kinematicState.dir+math.pi/16*(n-1.5)
                        end}}
                        spawner2:bindState(orb)
                    end
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