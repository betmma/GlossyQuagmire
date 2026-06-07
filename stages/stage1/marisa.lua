local function starTweak(cir,num)
    num=num or math.floor(math.random(1,7.999999))
    cir.extraUpdate=copyTable(cir.extraUpdate)
    if num==1 then
        cir:changeSpriteColor('red')
        cir.extraUpdate[#cir.extraUpdate+1]=function(self)
            self.kinematicState.speed=self.kinematicState.speed+0.5
        end
    elseif num==2 then
        cir:changeSpriteColor('blue')
        cir.extraUpdate[#cir.extraUpdate+1]=function(self)
            self.kinematicState.speed=self.kinematicState.speed*0.99
        end
    elseif num==3 then
        cir:changeSpriteColor('yellow')
        cir.extraUpdate[#cir.extraUpdate+1]=function(self)
            self.kinematicState.dir=self.kinematicState.dir+0.01
        end
    elseif num==4 then
        cir:changeSpriteColor('orange')
        cir.extraUpdate[#cir.extraUpdate+1]=function(self)
            self.kinematicState.dir=self.kinematicState.dir-0.01
        end
    elseif num==5 then
        cir:changeSpriteColor('green')
        cir.extraUpdate[#cir.extraUpdate+1]=function(self)
            self.kinematicState.dir=self.kinematicState.dir+0.02*math.sin(self.frame/10)
        end
    elseif num==6 then
        cir:changeSpriteColor('purple')
        local speedRef=cir.kinematicState.speed
        cir.extraUpdate[#cir.extraUpdate+1]=function(self)
            self.kinematicState.speed=self.kinematicState.speed*0.95
            if self.kinematicState.speed<speedRef*0.1 then
                self.kinematicState.speed=speedRef
            end
        end
    elseif num==7 then
        cir:changeSpriteColor('white')
    end
end
local marisaBoss=BossManager.BossSegment{
    bossName='marisa',
    players={KOTOBA=true},
    key='1-boss-marisa',
    -- BGM='',
    -- beforeDialogueKey=function ()
    --     return G.runInfo.playerType..'S1BossBefore'
    -- end,
    -- afterDialogueKey=function ()
    --     return G.runInfo.playerType..'S1BossAfter'
    -- end,
    getBossSpawnPos=function(self)
        local geometry=G.runInfo.geometry
        local pos,dir=geometry:rThetaGo(geometry:init().pos,30,G.runInfo.player.viewDirection-math.pi/2)
        return pos
    end,
    rounds={
        BossManager.BossRound{SKIP_INCLUDE=true,phases={
            BossManager.NonSpellPhase{SKIP_INCLUDE=true,
                key='1-boss-marisa-non-1',
                time=1500,
                hp=2000,
                func=function(self, boss)
                    local function spawner(r,angle,rotateSpeed)
                        local prepTime=100
                        local bigStar=Bullet{kinematicState={pos=copyTable(boss.kinematicState.pos),speed=0,dir=0},sprite=BulletSprites.bigStar.red,lifeFrame=1800,invincible=true,safe=true,size=2,spriteTransparency=0.5,extraUpdate={function(self)
                            if self.frame%15==0 then
                                self:changeSpriteColor()
                            end
                        end}}
                        bigStar.spriteRotationSpeed=0.05
                        local bulletSpawner=BulletSpawner{lifeFrame=1800,kinematicState={pos=copyTable(boss.kinematicState.pos),speed=0,dir=0},period=2,firstPeriod=prepTime+20,bulletNumber=3,bulletSpeed=80,angle=0,bulletSprite=BulletSprites.star.red,bulletLifeFrame=600,visible=true,bulletEvents={function(cir,args,self)
                            starTweak(cir)
                        end},bulletExtraUpdate={Action.FadeOut(30,true)}}
                        Event.LoopEvent{obj=bulletSpawner,period=1,executeFunc=function()
                            local ratio=Event.sineOProgressFunc(math.min(bulletSpawner.frame/prepTime,1))
                            local r1=r*ratio
                            local angle1=(angle+rotateSpeed*bulletSpawner.frame)*ratio
                            local pos,dir=G.runInfo.geometry:rThetaGo(boss.kinematicState.pos,r1,angle1)
                            bulletSpawner.kinematicState.pos=pos
                            bulletSpawner.angle=dir
                            if bulletSpawner.frame%120>12 then
                                bulletSpawner.bulletNumber=0
                            else
                                bulletSpawner.bulletNumber=3
                            end
                        end}
                        bigStar:bindState(bulletSpawner)
                    end
                    local function circle(r,num,rotateSpeed,angle)
                        angle=angle or 0
                        for i=1,num do
                            spawner(r,math.pi*2/num*(i-1)+angle,rotateSpeed)
                        end
                    end
                    if DIFF()<=G.NORMAL then
                        circle(100,DSWITCH{3,6,'<','<'},0.02)
                    else -- a hexagram
                        circle(150,6,0.02)
                        circle(150/3^0.5,6,0.02,math.pi/6)
                    end
                    if DIFF()==G.LUNATIC then
                        circle(430,6,-0.01)
                    else
                        circle(300,3,-0.01)
                    end
                end
            }
        }},
    }
}

return marisaBoss