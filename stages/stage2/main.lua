local function setZoomSpeed(value,duration)
    if G.runInfo.geometry~=G.geometries.MovingHyperbolic then
        return
    end
    if duration==0 then
        G.runInfo.geometry.viewConfig.zoomRatio=math.exp(value)
        G.backgroundPattern.autoForwardSpeed=value*60
        return
    end
    Event.EaseEvent{
        easeObj=G.runInfo.geometry.viewConfig,aims={zoomRatio=math.exp(value)},duration=duration
    }
    Event.EaseEvent{
        easeObj=G.backgroundPattern,aims={autoForwardSpeed=value*60},duration=duration
    }
end

---@type OneStageDataRaw
return{
    init=function()
        if G.runInfo.geometry==G.geometries.Hyperbolic then
            local border=Border.CircleBorder{center=G.runInfo.geometry:init().pos,radius=400}
            G.runInfo.player.border=border
            G:replaceBackgroundPatternIfNot(BackgroundPattern.Honeycomb)
        elseif G.runInfo.geometry==G.geometries.MovingHyperbolic then
            local border=Border.XYBorder{minx=20,maxx=500,miny=20,maxy=560}
            G.runInfo.player.border=border
            G:replaceBackgroundPatternIfNot(BackgroundPattern.Planes)
        else
        end
        BGM:play('level1')
        DynamicUIObjs.showSoundtrack()
        G.runInfo.player.kinematicState.skipZoom=true
        setZoomSpeed(0,0)
    end,
    segments={
        {
            key='2-1',
            type='midStage',
            skip=function ()
                setZoomSpeed(0.005,0)
            end,
            func=function() -- 14s
                wait(30)
                local basePos=G.runInfo.geometry:init().pos
                local pos1,dir1=G.runInfo.geometry:rThetaGo(basePos,300,-math.pi/2)
                dir1=dir1+math.pi/2
                local pos2,dir2=G.runInfo.geometry:rThetaGo(basePos,400,-math.pi/2)
                dir2=dir2+math.pi/2
                for i=1,30 do
                    local sign=math.mod2Sign(i)
                    if sign==1 then
                        local kstate={pos=copyTable(pos1),speed=30*(i-15.5),dir=dir1}
                        local fairy=Enemy{kinematicState=copyTable(kstate),maxhp=30,sprite=Asset.fairySprites.small.orange,lifeFrame=600,spriteTransparency=0,extraUpdate={Enemy.presetActions.fadeAndHint,function(self)
                            self.kinematicState.speed=self.kinematicState.speed*0.98
                        end},dropItems={powerSmall=2}}
                        BulletSpawner{
                            period=DSWITCH{120,120,60,60},firstPeriod=5,lifeFrame=570,bulletNumber=DSWITCH{1,1,3,3},range=math.pi/12,bulletSpeed=150,bulletSize=1,angle='player',bulletSprite=BulletSprites.rice.orange,bulletLifeFrame=600,visible=false
                        }:bindState(fairy)
                    else
                        local kstate={pos=copyTable(pos2),speed=200,dir=dir2-math.pi/2*(i)/15}
                        local fairy=Enemy{kinematicState=copyTable(kstate),maxhp=50,sprite=Asset.fairySprites.small.purple,lifeFrame=700,spriteTransparency=0,extraUpdate={Enemy.presetActions.fadeAndHint,function(self)
                            self.kinematicState.speed=self.kinematicState.speed*0.98
                        end},dropItems={point=1}}
                        BulletSpawner{
                            period=60,firstPeriod=5,lifeFrame=600,bulletNumber=DSWITCH{1,2,3,4},bulletSpeed=100,bulletSize=1,angle='0+999',bulletSprite=BulletSprites.rice.purple,bulletLifeFrame=600,visible=false
                        }:bindState(fairy)
                    end
                    wait(3)
                end
                wait(60)
                SFX:play('enemyCharge')
                setZoomSpeed(0.005,60)
                wait(400)
                DynamicUIObjs.showStageTitle('stage2')
                wait(260)
            end
        },
        {
            key='2-2',
            type='midStage',
            func=function() -- 10s
                local basePos=G.runInfo.geometry:init().pos
                local pos1,dir1=G.runInfo.geometry:rThetaGo(basePos,300,-math.pi/2)
                dir1=dir1+math.pi/2
                local function spawnFairy(side,extra)
                    local pos2,dir2=G.runInfo.geometry:rThetaGo(pos1,200*side,dir1)
                    dir2=dir2+math.pi/2
                    local fairy=Enemy{kinematicState={pos=copyTable(pos2),speed=20,dir=dir2+math.pi*0.6*side},maxhp=300,sprite=Asset.fairySprites.large.blue,lifeFrame=600,spriteTransparency=0,extraUpdate={Enemy.presetActions.fadeAndHint},dropItems={point=10}}
                    local spawner=BulletSpawner{
                        period=DSWITCH{12,8,4,4},firstPeriod=30,lifeFrame=120,bulletNumber=DSWITCH{1,1,1,3},range=math.pi*2,bulletSpeed=300,angle=dir2,bulletSprite=BulletSprites.round.blue,bulletLifeFrame=600,visible=false,bulletExtraUpdate=function(self)
                            self.kinematicState.speed=self.kinematicState.speed*0.98
                        end
                    }
                    spawner:bindState(fairy)
                    Event.EaseEvent{
                        obj=spawner,aims={angle=dir2+math.pi/2*side},duration=120
                    }
                    if extra then
                        local fairy2=Enemy{kinematicState={pos=copyTable(pos2),speed=100,dir=dir2+math.pi*0.4*side},maxhp=100,sprite=Asset.fairySprites.medium.red,lifeFrame=600,spriteTransparency=0,extraUpdate={Enemy.presetActions.fadeAndHint},dropItems={powerSmall=10}}
                        local spawner2=BulletSpawner{
                            period=DSWITCH{8,8,6,4},firstPeriod=30,lifeFrame=90,bulletNumber=DSWITCH{4,6,8,10},range=0.3,bulletSpeed=150,angle=dir2+math.pi*0.4*side,bulletSprite=BulletSprites.roundDark.purple,bulletLifeFrame=300,bulletExtraUpdate={Action.FadeOut(30,true)},visible=false
                        }
                        spawner2:bindState(fairy2)
                        Event.EaseEvent{
                            obj=spawner2,aims={range=math.pi*2,bulletSpeed=50},duration=90
                        }
                    end
                end
                local extra=DIFF()>=G.HARD
                spawnFairy(1,extra)
                wait(180)
                spawnFairy(-1,extra)
                wait(180)
                extra=DIFF()>=G.NORMAL
                spawnFairy(1,extra)
                wait(180)
                spawnFairy(-1,extra)
                wait(60)
            end
        },
        {
            key='2-3',
            type='midStage',
            func=function() -- 9s
                local basePos=G.runInfo.geometry:init().pos
                for i=1,8 do
                    local n=DSWITCH{4,4,6,8}
                    for j=1,n do
                        local pos3,dir3=G.runInfo.geometry:rThetaGo(basePos,200*(j-n/2-1/2)/n*2,0)
                        dir3=dir3-math.pi/2
                        local pos4,dir4=G.runInfo.geometry:rThetaGo(pos3,500,dir3)
                        -- dir4=dir4+math.pi
                        local fairy=Enemy{kinematicState={pos=copyTable(pos4),speed=50,dir=G.runInfo.geometry:to(pos4,basePos)},maxhp=30,sprite=Asset.fairySprites.small.green,lifeFrame=600,spriteTransparency=0,extraUpdate={Enemy.presetActions.fadeAndHint},dropItems={powerSmall=1}}
                        local spawner=BulletSpawner{
                            period=300,firstPeriod=30,lifeFrame=120,bulletNumber=DSWITCH{6,8,12,16},range=math.pi*2,bulletSpeed=100,angle=dir4+i,bulletSprite=BulletSprites.rice.green,bulletLifeFrame=600,visible=false,bulletEvents={function(cir,args,self)
                                cir.kinematicState.speed=cir.kinematicState.speed+math.eval(0,50)
                            end}
                        }:bindState(fairy)
                    end
                    wait(30)
                end
                wait(300)
            end
        },
        {
            key='2-branch',
            type='midStage',
            func=function() -- 15s till music turn point (48s total). this segment is 14s long
                -- there's no boss phase so doesn't use bossSegment
                local geo=G.runInfo.geometry
                local basePos=geo:init().pos
                local bossPos=geo:rThetaGo(basePos,200,-math.pi/2)
                Effect.Shockwave{kinematicState={pos=copyTable(bossPos),dir=0,speed=0},lifeFrame=20,radius=20,growSpeed=1.2,spriteTransparency=1,color='yellow',canRemove={bullet=true,invincible=true,safe=true,bulletSpawner=true}}
                Effect.Charge{obj={kinematicState={pos=copyTable(bossPos),dir=0,speed=0}}}
                wait(60)
                local bossName='tooshi'
                local boss=Boss{
                    kinematicState={pos=bossPos,dir=0,speed=0,skipZoom=true},
                    sprite=Asset.boss[bossName],maxhp=999999,revivable=true
                }
                DialogueController{key='S2Branch1'}:block() -- 11s
                local left=G.runInfo.player.kinematicState.pos.x<basePos.x
                if left then
                    DialogueController{key='S2BranchLeft'}:block() -- 2s
                else
                    DialogueController{key='S2BranchRight'}:block() -- 2s
                end
            end
        },
        {
            key='2-A',
            type='midStage',
            skip=function()
                setZoomSpeed(0.015,0)
            end,
            func=function()
                setZoomSpeed(0.015,1200)
                local geo=G.runInfo.geometry
                local basePos=geo:init().pos
                local pos0=geo:rThetaGo(basePos,200,-math.pi/2)
                local function pullTowardsCenterUpdate(self)
                    if geo:distance(self.kinematicState.pos,pos0)>200 and not self.flag then
                        self.flag=true
                        self.kinematicState.dir=geo:to(self.kinematicState.pos,pos0)
                        Event.EaseEvent{
                            obj=self,easeObj=self.kinematicState,aims={speed=300},duration=120,progressFunc=Event.sineBackProgressFunc
                        }
                        -- DanmakuFuncs.moveToInTime(self,pos0,120)
                        Event{obj=self,action=function()
                            wait(240)
                            self.flag=false
                        end}
                    end
                end
                local spawnSmallFairy=function(color,life,largeFairy,angle0,r0,alt)
                    local smallFairy=Enemy{maxhp=50,sprite=Asset.fairySprites.small[color],lifeFrame=life,spriteTransparency=0,extraUpdate={Enemy.presetActions.fadeAndHint},dropItems={powerSmall=1,point=1}}
                    DanmakuFuncs.orbitBind(smallFairy,largeFairy,function(self, centerObj)
                        local rat=math.min(1,self.frame/60)
                        return {r=rat*r0,theta=angle0+centerObj.frame*0.02}
                    end)
                    -- spawner:bindState(smallFairy)
                    smallFairy.dieEffect=function(self)
                        Enemy.dieEffect(self)
                        if largeFairy.removed then -- do not shoot bullets if it has fallen down (due to largeFairy has died)
                            return
                        end
                        for i=1,4 do
                            if not alt then
                                local spawner=BulletSpawner{
                                    kinematicState=copyTable(self.kinematicState),period=5,lifeFrame=20,bulletNumber=1,bulletSpeed=80,angle=angle0+i*math.pi/2,bulletSprite=BulletSprites.rain[color],bulletLifeFrame=600,bulletExtraUpdate={Action.FadeOut(30,true)},visible=false,bulletEvents={function(cir,args,self)
                                        if args.index==1 then
                                            self.bulletNumber=self.bulletNumber+1
                                            self.range=self.bulletNumber*0.1
                                        end
                                    end}
                                }
                            else
                                local spawner=BulletSpawner{
                                    kinematicState=copyTable(self.kinematicState),period=5,lifeFrame=6,bulletNumber=10,bulletSpeed=0,angle=angle0+i*math.pi/2,bulletSprite=BulletSprites.rain[color],bulletLifeFrame=600,bulletExtraUpdate={Action.FadeOut(30,true),function(self)
                                        self.kinematicState.speed=self.kinematicState.speed+0.2
                                    end},visible=false
                                }
                            end
                        end
                    end
                    return smallFairy
                end
                local function spawnLarge(ratio,color,alt)
                    local life=800
                    local pos1,dir1=geo:rThetaGo(basePos,ratio*200,0)
                    dir1=dir1-math.pi/2
                    local pos2,dir2=geo:rThetaGo(pos1,200,dir1)
                    dir2=dir2+math.pi*(1+ratio*0.3)
                    color=color or 'red'
                    local largeFairy=Enemy{kinematicState={pos=copyTable(pos2),speed=0,dir=dir2,skipZoom=true},maxhp=80,sprite=Asset.fairySprites.large[color],lifeFrame=life,spriteTransparency=0,extraUpdate={Enemy.presetActions.fadeAndHint,pullTowardsCenterUpdate},dropItems={point=5,powerSmall=5}}
                    largeFairy:addHPProtection(120,15)
                    largeFairy.dieEffect=function(self)
                        Enemy.dieEffect(self)
                        Effect.Shockwave{kinematicState={pos=copyTable(self.kinematicState.pos),dir=0,speed=0},lifeFrame=20,radius=10,growSpeed=0.4,spriteTransparency=1,color=color,canRemove={bullet=true}}
                    end
                    local spawner=BulletSpawner{
                        period=15,firstPeriod=50,lifeFrame=life,bulletNumber=6,bulletSpeed=200,angle=-math.pi/2,range=math.pi/2,bulletSprite=BulletSprites.lightRound[color],bulletLifeFrame=600,highlight=true,visible=false,bulletEvents={function(cir,args,self)
                            cir.forceQuad=true
                            cir.dird=math.mod2Sign(args.index)*0.01
                        end},bulletExtraUpdate={Action.FadeIn(60,false),Action.ZoomIn(20,nil,2),Action.FadeOut(30,true),function(self)
                            self.kinematicState.dir=self.kinematicState.dir+self.dird
                        end}
                    }
                    Event.EaseEvent{
                        obj=spawner,aims={angle=spawner.angle+math.pi/4},duration=life,progressFunc=function(x)
                            return 0.5*(1-math.cos(math.pi*x*4))
                        end
                    }
                    local spawner2=BulletSpawner{
                        period=2,firstPeriod=50,lifeFrame=life,bulletNumber=5,bulletSpeed=180,angle=dir2,bulletSprite=BulletSprites.rimDark[color],bulletLifeFrame=600,bulletExtraUpdate={Action.FadeOut(30,true),function(self)
                            self.kinematicState.speed=self.kinematicState.speed*0.99
                        end},visible=false
                    }
                    Event.EaseEvent{
                        obj=spawner2,aims={angle=dir2+math.pi},duration=life,progressFunc=function(x)
                            return 0.5*(1-math.cos(math.pi*x*5))
                        end
                    }
                    Event.LoopEvent{obj=spawner2,period=1,executeFunc=function()
                        if spawner2.frame%50>10 then
                            spawner2.bulletNumber=0
                        else
                            spawner2.bulletNumber=6
                        end
                    end}
                    spawner:bindState(largeFairy)
                    spawner2:bindState(largeFairy)
                    for i=1,9 do
                        Event{obj=largeFairy,action=function()
                            wait(i*5)
                            local smallFairy
                            local spawnCount=0
                            while spawnCount<3 and largeFairy.frame<600 do
                                if not smallFairy or smallFairy.removed then
                                    spawnCount=spawnCount+1
                                    local angle0=i*math.pi*2/9
                                    local r0=50
                                    if alt then
                                        local a,b=math.ceil(i/3),i%3
                                        r0=r0*a
                                        angle0=math.pi*2/3*b
                                    end
                                    smallFairy=spawnSmallFairy(color,life,largeFairy,angle0,r0,alt)
                                    wait(60)
                                end
                                wait()
                            end
                        end}
                    end
                end
                spawnLarge(1,'orange')
                wait(300)
                spawnLarge(-1,'green')
                wait(300)
                pos0=geo:rThetaGo(basePos,300,-math.pi/2)
                spawnLarge(1,'purple',true)
                wait(300)
                spawnLarge(-1,'blue',true)
                wait(300) -- 20s
                wait(600)
            end
        }
    }
}