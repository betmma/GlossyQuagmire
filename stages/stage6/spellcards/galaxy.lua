---@return SpellcardPhase
return BossManager.SpellcardPhase{
    key='enri-galaxy',
    bonusScore=50000,
    time=2400,
    hp=4000,
    dropItems={powerSmall=30,point=15},
    func=function(self, boss)
        boss:addHPProtection(300,5)
        local geo=G.runInfo.geometry
        ---@cast geo Spherical
        local radius=geo.radius
        ---@cast geo GeometryBase
        local colors={'red','green','magenta','yellow','blue'}
        local omega=0.01
        local sentry=DanmakuFuncs.sentry()
        local bulletExtraUpdate={Action.ZoomIn(20),Action.FadeOut(10,false),function(self)
            if self.frame==self.any.stopTime then
                self:changeSpriteColor('gray')
            end
            if self.frame>=self.any.stopTime then
                return
            end
            local slowDown=math.clamp(-(self.frame-self.any.stopTime)/20,0,1)
            self.any.angle=self.any.angle+self.any.omega*slowDown
            self.any.ovalAngle=self.any.ovalAngle-self.any.omega*0.3
            local r=self.any.r
            local x,y=math.rTheta2xy(r,self.any.angle-self.any.ovalAngle)
            x=x*0.7
            local r2,theta2=math.xy2rTheta(x,y)
            self.any.r2=r2
            theta2=theta2+self.any.ovalAngle
            self.kinematicState.pos,self.kinematicState.dir=geo:rThetaGo(self.any.center,r2,theta2)
        end}
        local outwardBulletsExtraUpdate={Action.ZoomIn(20),Action.ZoomOut(10),function(self)
            if self.frame==self.any.stopTime then
                self:changeSpriteColor('gray')
                self.kinematicState.speed=150
                self.size=1
                self.spriteExtraDirection=math.pi/2
            end
        end}
        local stickExtraUpdate={Action.ZoomIn(15),Action.ZoomOut(10),function (self)
            local bullet,other=self.any.bullet.kinematicState.pos,self.any.other.kinematicState.pos
            local distance,to=geo:rThetaTo(bullet,other)
            self.kinematicState.pos,self.kinematicState.dir=geo:rThetaGo(bullet,distance*self.any.ratio,to)
        end}
        local function spawnLaser(pos1,pos2)
            local time=10
            local life=25
            local distance=geo:distance(pos1,pos2)
            local rayAngle0=0.05
            local angle=distance/2/radius
            local n=math.clamp(distance/50,2,6)
            local lase=GeoLaser{kinematicState={pos=copyTable(pos1),dir=geo:to(pos1,pos2),speed=0},sprite=BulletSprites.laser.gray,size=1.3*math.cos(angle),rayAngle=rayAngle0*math.sin(angle),spriteTransparency=0.3,safe=false,invincible=true,lifeFrame=life,meshBudget={capNum=1,step=distance/n,num=n},extraUpdate={GeoLaser.presetActions.laserZoomIn(10),GeoLaser.presetActions.laserZoomOut(10)}}
        end
        local function mirror(r,bulletNum,groupNum,colorNum,sign)
            local stopTime=240
            local groupColors={}
            for i=1,groupNum do
                local colorIndex=i%colorNum+1
                groupColors[#groupColors+1]=colorIndex
            end
            for i=1,groupNum-2,3 do -- less and nearer swaps to reduce lasers with few vertices between
                local j=math.random(i+1,math.min(groupNum,i+3))
                groupColors[i],groupColors[j]=groupColors[j],groupColors[i]
            end
            local colorGroups={}
            for i=1,colorNum do
                colorGroups[i]={}
            end
            for i=1,groupNum do
                local colorIndex=groupColors[i]
                table.insert(colorGroups[colorIndex],i)
            end
            local bulletPerGroup=math.ceil(bulletNum/groupNum-0.5)
            local midIndex=math.floor(bulletPerGroup/2)
            local midBullets={}
            local playerPos=copyTable(G.runInfo.player.kinematicState.pos)
            local ovalAngle=math.eval(0,math.pi)
            for i=1,bulletNum do
                local groupIndex=math.ceil(i/bulletPerGroup)
                local colorIndex=groupColors[groupIndex]
                local color=colors[colorIndex]
                local isMid=(i-1)%bulletPerGroup==midIndex
                local angle=math.pi*2/bulletNum*i
                local pos,dir=geo:rThetaGo(playerPos,r,angle)
                local bullet=Bullet{kinematicState={pos=pos,dir=dir,speed=0},sprite=BulletSprites[isMid and 'bigRound' or 'round'][color],lifeFrame=stopTime+30,extraUpdate=bulletExtraUpdate,invincible=true}
                bullet.any={r=r,angle=angle,ovalAngle=ovalAngle,center=playerPos,stopTime=stopTime,omega=omega*sign}
                -- decorative safe bullets to add colors inside the mirror
                local decorative=Bullet{kinematicState={pos=pos,dir=dir,speed=0},sprite=BulletSprites.explosion[color],lifeFrame=stopTime+30,extraUpdate=bulletExtraUpdate,invincible=true,safe=true,forceQuad=true,highlight=true,spriteTransparency=DSWITCH{0.15,'<',0.1,'<'},size=1.2}
                local ratio=(i*0.707*sign)%1
                decorative.spriteRotationSpeed=0.03*sign
                decorative.any={r=r*(1-ratio^2),angle=angle,ovalAngle=ovalAngle,center=playerPos,stopTime=stopTime,omega=omega*sign}
                -- laser warnings (mimicked with sticks)
                if isMid then
                    midBullets[groupIndex]=bullet
                    Event{obj=bullet,action=function ()
                        local waitTime=colorIndex*10+60
                        wait(waitTime)
                        SFX:play('enemyShot4')
                        -- outward bullets
                        local distance=radius*math.pi*2-bullet.any.r2 -- remaining distance till the center of oval
                        distance=distance-bullet.any.r2
                        BulletSpawner{lifeFrame=3,period=9,firstPeriod=1,useRelativeAngle=true,angle=0,bulletLifeFrame=360,bulletSpeed=distance*60/(stopTime-waitTime),bulletNumber=1,bulletSize=3,bulletSprite=BulletSprites.ellipse[color],bulletExtraUpdate=outwardBulletsExtraUpdate,bulletEvents={function (cir,args,self)
                            cir.any={stopTime=stopTime-waitTime}
                            -- cir.forceQuad=true
                        end}}:bindState(bullet)
                        local sameColorGroups=colorGroups[colorIndex]
                        for index, value in ipairs(sameColorGroups) do
                            if value>=groupIndex-2 then -- >=groupIndex is to exclude repeated reversed edge. -i can exclude edges with <=(i-1) vertices between that are not threat to reduce lasers
                                break
                            end
                            local otherBullet=midBullets[value]
                            local midPoints,midDirs=DanmakuFuncs.midPoints(bullet.kinematicState.pos,otherBullet.kinematicState.pos,10,10)
                            for j=2,#midPoints-1 do
                                local midPos,midDir=midPoints[j],midDirs[j]
                                Bullet{kinematicState={pos=midPos,dir=midDir,speed=0},sprite=BulletSprites.stick[color],size=5,safe=true,invincible=true,highlight=true,spriteTransparency=0.2,extraUpdate=stickExtraUpdate,lifeFrame=stopTime-waitTime,forceQuad=true}.any={ratio=(j-1)/(#midPoints-1),time=stopTime-waitTime,bullet=bullet,other=otherBullet,aim=otherBullet}
                            end
                        end
                        wait(stopTime-waitTime)
                        for index, value in ipairs(sameColorGroups) do
                            if value>=groupIndex-2 then -- >=groupIndex is to exclude repeated reversed edge. -i can exclude edges with <=(i-1) vertices between that are not threat to reduce lasers
                                break
                            end
                            local otherBullet=midBullets[value]
                            spawnLaser(bullet.kinematicState.pos,otherBullet.kinematicState.pos)
                        end
                    end}
                end
                Event{obj=sentry,action=function ()
                    wait(stopTime-60)
                    SFX:play('enemyCharge')
                    wait(60)
                    SFX:play('enemyPowerfulShot')
                end}
            end
        end
        for i=1,10 do
            SFX:play('enemyShot')
            if DIFF()>=G.HARD then
                local num=DSWITCH{'>','>',10,15}
                mirror(300,num*4,num,5,math.mod2Sign(i))
                mirror(200,30,10,5,-math.mod2Sign(i))
            else
                local num=DSWITCH{10,15,'<','<'}
                mirror(300,num*4,num,5,math.mod2Sign(i))
            end
            wait(240)
            omega=math.min(0.02,omega+0.005) -- easier for early rounds
        end
    end
}