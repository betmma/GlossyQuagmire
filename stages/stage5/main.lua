---@type OneStageDataRaw
return{
    init=function()
        G:replaceBackgroundPatternIfNot(BackgroundPattern.Stage5S2R)
        if G.runInfo.geometry==G.geometries.Cylinder then
            local border=Border.XYBorder{minx=-20,maxx=2500,miny=-G.geometries.Cylinder.r0+20,maxy=G.geometries.Cylinder.r0-20}
            G.runInfo.player.border=border
        end
        BGM:play('level5',true)
        DynamicUIObjs.showSoundtrack()
    end,
    segments={
        {
            key='5-1',
            type='midStage',
            func=function() -- 11s. mid boss needs to appear at 51s
                local geo=G.runInfo.geometry
                ---@cast geo Cylinder
                local pos0=geo:init().pos
                local pos1=geo:rThetaGo(pos0,300,-math.pi/2)
                local pos2=geo:rThetaGo(pos1,geo.a/2,0)
                for i=1,20 do
                    local fairy=Enemy{kinematicState=copyTable{pos=pos2,dir=math.pi*(i%2),speed=180},maxhp=50,sprite=Asset.fairySprites.small.purple,lifeFrame=600,extraUpdate={Enemy.presetActions.fadeAndHint},dropItems={powerSmall=2}}
                    BulletSpawner{
                        period=DSWITCH{90,90,45,45},firstPeriod=60-(i%3)*15,lifeFrame=470,bulletNumber=DSWITCH{1,3,3,5},bulletSpeed=150+i*10,bulletSize=1,angle='player',range=math.pi/2,bulletSprite=BulletSprites.round.purple,bulletLifeFrame=540,visible=false,bulletExtraUpdate={Action.FadeOut(20,true)}
                    }:bindState(fairy)
                    wait(15)
                end
                DynamicUIObjs.showStageTitle('stage5')
                wait(360)
                -- wait(24000)
            end
        },
        {
            key='5-2',
            type='midStage',
            func=function() -- 25s
                -- bpm is 160, so a beat is 22.5 frames. 630 frames would be 28 beats
                local geo=G.runInfo.geometry
                ---@cast geo Cylinder
                local pos0=geo:init().pos
                pos0.x=G.runInfo.player.kinematicState.pos.x -- same angle
                local radius=geo.r0*0.8
                local pos1=geo:rThetaGo(pos0,250+radius-geo.r0,-math.pi/2)
                local posh=geo:rThetaGo(pos0,600,-math.pi/2)
                local rotateSpeedRatio=DSWITCH{1,1.2,0.6,-1.2}
                local bindFunc=function (self, centerObj)
                    local t=centerObj.frame
                    return {r=self.any.r*math.min(1,t/60),theta=self.any.angle+t*(centerObj.kinematicState.speed/geo.r0/60)*rotateSpeedRatio*-math.mod2Sign(self.any.index)*math.min(1,t/60)}
                end
                local slow=function(self)
                    self.kinematicState.speed=math.lerp(self.kinematicState.speed,150,0.03)
                end
                local sentry=DanmakuFuncs.sentry()
                local refreshGraze=function(self)
                    if self.frame%4==0 and sentry.frame<1260 then -- simulate laser grazing on big stars. also player can collect items from small fairies by grazing them
                        self.grazed=false
                    end
                end
                local diff=DIFF()
                local afterCenterRemove=function(self)
                    if diff==G.EASY or (diff==G.NORMAL and self.any.index==1) then
                        self.lifeFrame=self.frame+20
                    end
                    self.extraUpdate[#self.extraUpdate+1] = slow
                end
                local colors={'red','yellow','teal','blue','purple'}
                for i=1,2 do
                    local pos2=geo:rThetaGo(pos1,geo.a/4*math.mod2Sign(i),0)
                    local bigFairy=Enemy{kinematicState=copyTable{pos=pos2,dir=math.pi*(i%2),speed=0},maxhp=500,sprite=Asset.fairySprites.large.red,lifeFrame=600,extraUpdate={Enemy.presetActions.fadeAndHint},dropItems={powerSmall=5,point=5}}
                    BulletSpawner{
                        period=240,firstPeriod=60,lifeFrame=90,bulletNumber=2,bulletSpeed=geo.a/2*60/315,bulletSize=1,angle=math.pi/2,bulletSprite=BulletSprites.round.red,bulletLifeFrame=1260,bulletExtraUpdate={Action.FadeOut(20,true)},bulletEvents={function (cir,args,self)
                            SFX:play('enemyPowerfulShot')
                            cir.lifeFrame=cir.lifeFrame-(i-1)*630
                            -- flower shape
                            local n=5
                            local colorIndex=math.random(1,5)
                            for j=1,n do
                                local color=colors[(j+colorIndex)%5+1]
                                local angleBase=j/n*math.pi*2
                                local n2=21
                                for k=1,n2 do
                                    local ratio=((k-0.5)/n2-0.5)*2
                                    local angle=math.sign(ratio)*math.abs(ratio)^2*math.pi/2
                                    local r0=math.max(math.log(math.tan(math.pi/2-0.03-math.abs(angle))*2+1),0) -- maps angle from -pi/2 to pi/2 to a petal shape
                                    local rmax=math.log(math.tan(math.pi/2-0.03)*2+1)
                                    local r=radius/rmax*r0
                                    local bullet=Bullet{lifeFrame=cir.lifeFrame+300,sprite=BulletSprites.bigStar[color],extraUpdate={Action.FadeIn(20,true),Action.FadeOut(20,true),refreshGraze},size=1}
                                    bullet.any={r=r,angle=angleBase+angle,index=args.index}
                                    DanmakuFuncs.orbitBind(bullet,cir,bindFunc,afterCenterRemove)
                                end
                                -- decorative laser. currently due to "side to line" undefined in cylinder, laser cannot calculate checkHitPlayer normally so set it to safe
                                local laser=GeoLaser{sprite=BulletSprites.laser[color],size=9*radius/geo.r0,rayAngle=-0.1,spriteTransparency=1,safe=true,invincible=true,lifeFrame=cir.lifeFrame,meshBudget={capNum=3,step=30,num=math.floor(9*radius/geo.r0)},extraUpdate={GeoLaser.presetActions.laserZoomIn(20),GeoLaser.presetActions.laserZoomOut(20),function(self)
                                end}}
                                laser.any={r=0,angle=angleBase,index=args.index}
                                DanmakuFuncs.orbitBind(laser,cir,bindFunc,function (self)
                                    self.lifeFrame=self.frame+30
                                end)
                            end
                        end}
                    }:bindState(bigFairy)
                    Event{action=function ()
                        wait(165)
                        for j=1,20 do
                            local posh2=geo:rThetaGo(posh,geo.a/4/20*j*math.mod2Sign(i),0)
                            local fairy=Enemy{kinematicState=copyTable{pos=posh2,dir=math.pi/2,speed=120},maxhp=50,sprite=Asset.fairySprites.small.white,lifeFrame=600,extraUpdate={Enemy.presetActions.fadeAndHint},dropItems={powerSmall=1,point=1}}
                            BulletSpawner{
                                period=DSWITCH{90,90,45,45},firstPeriod=105,lifeFrame=300,bulletNumber=DSWITCH{1,3,3,5},bulletSpeed=300,bulletSize=1,angle='player',range=math.pi/9,bulletSprite=BulletSprites.round.white,bulletLifeFrame=600,bulletExtraUpdate={Action.FadeOut(20,true),slow}
                            }:bindState(fairy)
                            wait(11+(j%4==0 and 1 or 0)) -- average 11.25
                        end
                    end}
                    wait(630)
                end
                wait(60)
                SFX:play('enemyPowerfulShot')
                wait(180)
            end
        },
        {
            key='5-3',
            type='midStage',
            func=function() -- 15s
                local geo=G.runInfo.geometry
                ---@cast geo Cylinder
                local pos0=geo:init().pos
                local posh=geo:rThetaGo(pos0,250,-math.pi/2)
                local sentry=DanmakuFuncs.sentry()
                local speed=140
                for j=1,10 do
                    local posh2=geo:rThetaGo(posh,geo.a/10*j*7-(sentry.frame*speed/60),0)
                    local fairy=Enemy{kinematicState=copyTable{pos=posh2,dir=math.pi,speed=speed},maxhp=200,sprite=Asset.fairySprites.medium.blue,lifeFrame=900-sentry.frame,extraUpdate={Enemy.presetActions.fadeAndHint},dropItems={powerSmall=3,point=3}}
                    fairy:addHPProtection(180,5)
                    BulletSpawner{
                        period=DSWITCH{27,18,18,9},firstPeriod=60,lifeFrame=900-sentry.frame,bulletNumber=DSWITCH{2,2,4,4},bulletSpeed=300,bulletSize=1,angle=math.pi,range=math.pi/3,bulletSprite=BulletSprites.turret.blue,bulletLifeFrame=500,bulletExtraUpdate={Action.FadeOut(20,true)},bulletEvents={function (cir,args,self)
                            cir.spriteRotationSpeed=math.mod2Sign(args.index)*0.1
                            cir.spriteExtraDirection=math.eval(0,99)
                            local mid=math.ceil(math.abs(args.index-self.bulletNumber/2-0.5))
                            local sign=math.sign(args.index-self.bulletNumber/2-0.5)
                            if mid==2 then
                                cir:changeSpriteColor('cyan')
                                cir.lifeFrame=300
                                if DIFF()==G.LUNATIC and (self.spawnTimes-1)%8>=4 then
                                    cir.kinematicState.dir=cir.kinematicState.dir+math.pi/12*sign
                                end
                            end
                        end}
                    }:bindState(fairy)
                    wait(22+(j%2)) -- average 22.5
                end
                wait(225)
                wait(450)
            end
        },
    }
}
