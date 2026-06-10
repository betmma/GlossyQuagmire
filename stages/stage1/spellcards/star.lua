---@return SpellcardPhase
return BossManager.SpellcardPhase{
    key='marisa-star',SKIP_INCLUDE=true,
    bonusScore=10000,
    time=1800,
    hp=2400,
    dropItems={point=15,powerSmall=10},
    func=function(self, boss)
        local center=G.runInfo.geometry:init().pos
        local function star(cir,sign,color)
            for side=1,6 do
                local angle=(side-1)*math.pi/3
                local num=15
                local r=300
                local pos1=G.runInfo.geometry:rThetaGo(center,r,angle)
                local pos2=G.runInfo.geometry:rThetaGo(center,r,angle+math.pi/3*2)
                local dir=G.runInfo.geometry:to(pos1,pos2)
                local distance=G.runInfo.geometry:distance(pos1,pos2)
                for i=1,num do
                    local pos=G.runInfo.geometry:rThetaGo(pos1,distance*i/num,dir)
                    local angle2=G.runInfo.geometry:to(center,pos)
                    local r0=G.runInfo.geometry:distance(pos,center)
                    local bullet=Bullet{kinematicState={pos=copyTable(center),speed=0,dir=angle2},sprite=BulletSprites.bigStar[color],lifeFrame=600,invincible=true,size=2,forceQuad=true,extraUpdate={Action.FadeIn(30,false),Action.FadeOut(30,true)}}
                    DanmakuFuncs.orbitBind(bullet,cir,function(self,centerObj)
                        return {r=r0*math.min(1,self.frame/120),theta=angle2+0.01*self.frame*sign}
                    end)
                    if i==num and DIFF()==G.NORMAL then
                        local bulletSpawner=BulletSpawner{lifeFrame=240,kinematicState={pos=copyTable(center),speed=0,dir=0},period=1,firstPeriod=60,bulletNumber=1,bulletSpeed=180,angle=0,bulletSprite=BulletSprites.star[color],bulletLifeFrame=400,visible=true,fogEffect=true,fogTime=20,bulletEvents={function(cir,args,self)
                            cir.kinematicState.dir=bullet.kinematicState.dir
                        end},bulletExtraUpdate={Action.ZoomIn(20,1,2),Action.FadeIn(10,true),Action.FadeOut(20,true)}}
                        bulletSpawner:bindState(bullet)
                        Event.LoopEvent{obj=bulletSpawner,period=1,executeFunc=function()
                            local period=8
                            if bulletSpawner.frame%period>=4 then
                                bulletSpawner.bulletNumber=0
                            else
                                bulletSpawner.bulletNumber=1
                            end
                        end}
                    end
                end
            end
        end
        if DIFF()>=G.HARD then
            local spawner=BulletSpawner{lifeFrame=1800,kinematicState={pos=copyTable(boss.kinematicState.pos),speed=0,dir=0},period=6,firstPeriod=20,bulletNumber=12,bulletSpeed=180,angle=0,bulletSprite=BulletSprites.starDark.red,bulletSize=2,bulletLifeFrame=300,visible=true,bulletEvents={function(cir,args,self)
                local period=120
                cir:changeSpriteColor()
                cir.spriteRotationSpeed=0.05*math.mod2Sign(args.index)
                if args.index>1 then return end
                if self.frame%period>period/2 then
                    self.angle=self.angle+1/9
                else
                    self.angle=self.angle-1/8
                end
            end},bulletExtraUpdate={Action.FadeOut(30,true)}}
        end
        local toPlayer=G.runInfo.geometry:to(center,G.runInfo.player.kinematicState.pos)
        for i=1,10 do
            local close=i%3==2
            local d=160-DSWITCH{70,60,60,70}*(close and 1 or 0)
            local side=math.mod2Sign(i)
            -- for side=-1,1,2 do
                local angle=toPlayer+math.pi/2*side
                local pos1,dir1=G.runInfo.geometry:rThetaGo(center,d,angle)
                dir1=dir1-math.pi/2*side
                local pos2,dir2=G.runInfo.geometry:rThetaGo(pos1,-300,dir1)
                local core=Bullet{kinematicState={pos=pos2,dir=dir2,speed=0},sprite=BulletSprites.bigStar.red,lifeFrame=600,invincible=true,safe=true,spriteTransparency=0,}
                Event.EaseEvent{
                    obj=core,duration=120,easeObj=core.kinematicState,aims={speed=100}
                }
                SFX:play('enemyPowerfulShot')
                star(core, side, close and 'orange' or 'red')
            -- end
            wait(200)
        end
    end
}