---@return SpellcardPhase
return BossManager.SpellcardPhase{
    key='marisa-light',SKIP_INCLUDE=true,
    bonusScore=10000,
    time=1800,
    hp=2800,
    dropItems={point=15,powerSmall=10},
    func=function(self, boss)
        local center=G.runInfo.geometry:init().pos
        ---@type Player
        local player=G.runInfo.player
        local spinRatio=1
        local laserBase=Bullet{kinematicState={pos=copyTable(player.kinematicState.pos),speed=0,dir=player.viewDirection},sprite=BulletSprites.scale.red,invincible=true,safe=true,lifeFrame=1800,spriteTransparency=0,extraUpdate={function(self)
            local dir=G.runInfo.geometry:to(self.kinematicState.pos,player.kinematicState.pos)
            dir=math.modClamp(dir,self.kinematicState.dir)
            self.kinematicState.dir=self.kinematicState.dir-math.pi/360*spinRatio--math.lerp(self.kinematicState.dir,dir,0.003)
            local dis=G.runInfo.geometry:distance(self.kinematicState.pos,player.kinematicState.pos)
            self.kinematicState.pos=G.runInfo.geometry:rThetaGo(self.kinematicState.pos,dis/150,dir)
        end}}
        local colors={'red','orange','yellow','green','cyan','blue','purple'}
        local function lasers()
            for i=-4,5,1 do
                for side=-1,1,2 do
                    local r=(i-0.5)*DSWITCH{100,85,70,50}
                    local am=math.floor(math.abs(i-0.5))
                    local laser=GeoLaser{sprite=BulletSprites.laser[colors[am+2]],size=1,rayAngle=0.03,spriteTransparency=1,safe=true,invincible=true,lifeFrame=1800,meshBudget={capNum=3,step=60,num=16-am},extraUpdate={GeoLaser.presetActions.laserZoomIn(120),GeoLaser.presetActions.laserZoomOut(30),Action.FadeIn(60,true)}}
                    DanmakuFuncs.orbitBind(laser, laserBase, {r=r,theta=0,extraTheta=math.pi/2*side}, function(self)
                        ---@cast self GeoLaser
                        self:shrinkAndRemove()
                    end)
                end
            end
        end
        Event{obj=laserBase,action=function()
            SFX:play('enemyCharge')
            wait(60)
            SFX:play('enemyPowerfulShot')
            lasers()
        end}
        local spawnerIndex=-1
        local function spawner(r,angle,rotateSpeed)
            spawnerIndex=spawnerIndex+1
            local prepTime=100
            local bigStar=Bullet{kinematicState={pos=copyTable(boss.kinematicState.pos),speed=0,dir=0},sprite=BulletSprites.bigStar.red,lifeFrame=1800,invincible=true,safe=true,size=4,forceQuad=true,spriteTransparency=0.5,extraUpdate={function(self)
                if self.frame%15==0 then
                    self:changeSpriteColor()
                end
            end}}
            bigStar.spriteRotationSpeed=0.05
            local bulletSpawner=BulletSpawner{lifeFrame=1800,kinematicState={pos=copyTable(boss.kinematicState.pos),speed=0,dir=0},period=DSWITCH{18,14,14,14},firstPeriod=prepTime+20,bulletNumber=3,bulletSize=2,bulletSpeed=180,angle=0,bulletSprite=BulletSprites.star[colors[spawnerIndex%#colors+1]],bulletLifeFrame=300,visible=true,bulletEvents={function(cir,args,self)
                local to1,to2=G.runInfo.geometry:to(cir.kinematicState.pos,laserBase.kinematicState.pos),G.runInfo.geometry:to(laserBase.kinematicState.pos,cir.kinematicState.pos)
                cir.kinematicState.dir=to1-to2+laserBase.kinematicState.dir-math.pi/2+self.spin
                cir.forceQuad=true
                local index=args.index-1
                cir.kinematicState.speed=cir.kinematicState.speed-index*10
                local targetSize=cir.size-index*0.5
                cir.size=5
                Event.EaseEvent{obj=cir,aims={size=targetSize},duration=20,progressFunc=Event.sineOProgressFunc}
                local toCenter=G.runInfo.geometry:to(cir.kinematicState.pos,center)
                if math.angleDiff(toCenter, cir.kinematicState.dir)>math.pi/2 then
                    cir.lifeFrame=cir.lifeFrame/2 -- if it's going outward, reduce its life to make it disappear sooner
                end
            end},bulletExtraUpdate={Action.FadeOut(30,true)}}
            bulletSpawner.spin=0
            Event.LoopEvent{obj=bulletSpawner,period=1,executeFunc=function()
                local ratio=Event.sineOProgressFunc(math.min(bulletSpawner.frame/prepTime,1))
                local r1=r*ratio
                local angle1=(angle+rotateSpeed*bulletSpawner.frame)*ratio
                local pos,dir=G.runInfo.geometry:rThetaGo(boss.kinematicState.pos,r1,angle1)
                bulletSpawner.kinematicState.pos=pos
                bulletSpawner.angle=dir
                bulletSpawner.spin=bulletSpawner.spin+math.pi/180*spinRatio
            end}
            bigStar:bindState(bulletSpawner)
        end
        local function circle(r,num,rotateSpeed,angle)
            angle=angle or 0
            for i=1,num do
                spawner(r,math.pi*2/num*(i-1)+angle,rotateSpeed)
            end
        end
        circle(430,DSWITCH{7,7,14,14},-0.01,math.eval(0,3.14))
        if DIFF()>=G.HARD then
            Event{obj=laserBase,action=function()
                for i=1,6 do
                    wait(240)
                    local spinRatioRef=spinRatio
                    for i=1,120 do
                        spinRatio=math.lerp(spinRatioRef,-spinRatioRef,i/120)
                        wait()
                    end
                end
            end}
        end
    end
}