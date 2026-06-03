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
                SFX:play('enemyCharge',true)
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
            func=function()
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
        }
    }
}