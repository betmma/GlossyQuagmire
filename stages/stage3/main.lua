---@type OneStageDataRaw
return{
    init=function()
        if G.runInfo.geometry==G.geometries.Euclidean then
            local border=Border.XYBorder{minx=20,maxx=500,miny=30,maxy=560}
            G.runInfo.player.border=border
            G:replaceBackgroundPatternIfNot(BackgroundPattern.Corridor)
        end
        BGM:play('level2',true)
        DynamicUIObjs.showSoundtrack()
    end,
    segments={
        {
            key='3-1',
            type='midStage',
            func=function() -- 15s. midboss should appear at 41s
                wait(30)
                local geo=G.runInfo.geometry
                local base=geo:init().pos
                local pos1,dir1=geo:rThetaGo(base,600,-math.pi/2)
                local fairy=Enemy{kinematicState={pos=pos1,dir=dir1+math.pi,speed=400},sprite=Asset.fairySprites.medium.white,maxhp=800,lifeFrame=300,dropItems={powerSmall=10,point=10},extraUpdate={Enemy.presetActions.fadeAndHint}}
                fairy:addHPProtection(60,3)
                Event.EaseEvent{obj=fairy,easeObj=fairy.kinematicState,aims={speed=0},duration=60}
                local slowDown=function(self)
                    self.kinematicState.speed=math.lerp(self.kinematicState.speed,50,0.08)
                end
                local spawner
                spawner=BulletSpawner{period=999,firstPeriod=999,lifeFrame=240,bulletNumber=2,range=math.pi*3,bulletSpeed=800,bulletSize=1,angle=dir1+math.pi,bulletSprite=BulletSprites.lightRound.white,bulletLifeFrame=300,visible=false,bulletEvents={function(cir,args,self)
                    cir.index=self.spawnTimes
                end},bulletExtraUpdate={Action.FadeIn(10,false),function (self)
                    self.kinematicState.speed=self.kinematicState.speed*0.9
                    if not self.flagt and (fairy.hp<fairy.maxhp*0.4 or fairy.frame>=180) then
                        self.flagt=self.frame
                    end
                    if not self.flagt then
                        return
                    end
                    local t=self.frame-self.flagt
                    if t<=30 then
                        local val=math.clamp(1-t/40,0,1)
                        self.spriteColor={1,val,val,1}
                    end
                    if t==30+self.index*3 then
                        SFX:play('enemyPowerfulShot')
                        BulletSpawner{kinematicState={pos=copyTable(self.kinematicState.pos),dir=self.kinematicState.dir,speed=0},period=999,firstPeriod=1,lifeFrame=2,bulletNumber=49,range=math.pi*1.5,bulletSpeed=900,bulletSize=1,angle='player',bulletSprite=BulletSprites.rice.white,bulletLifeFrame=600,bulletExtraUpdate=slowDown}
                        self:remove()
                    end
                end}}
                spawner:bindState(fairy)
                Event{obj=spawner,action=function ()
                    wait(60)
                    for i=1,1 do
                        spawner.range=math.pi*3
                        spawner.bulletSpeed=800
                        Event.EaseEvent{obj=spawner,aims={range=math.pi*0.5,bulletSpeed=600},duration=200}
                        for i=1,6 do
                            if fairy.hp<fairy.maxhp*0.4 then
                                return
                            end
                            spawner:spawnBatchFunc()
                            wait(30)
                        end
                        wait(40)
                    end
                end}
                local mirrorPatternHappened=false
                local function mirrorPattern()
                    Mirror.setHSV({0,0.5,1},0.3)
                    if mirrorPatternHappened then
                        return
                    end
                    mirrorPatternHappened=true
                    SFX:play('enemyCharge')
                    local pos=fairy.kinematicState.pos
                    local extra=function(self)
                        local t=self.t or 0
                        self.t=t+1
                        if t<60 then
                            self.kinematicState.speed=self.kinematicState.speed*0.95
                        elseif t>90 then
                            self.kinematicState.speed=math.lerp(self.kinematicState.speed,self.speedRef/4,0.03)
                        end
                    end
                    local spawner2=BulletSpawner{kinematicState={pos=pos,dir=0,speed=0},period=999,firstPeriod=1,lifeFrame=2,bulletNumber=10,bulletSpeed=50,angle='player',bulletSprite=BulletSprites.round.white,bulletLifeFrame=600,bulletExtraUpdate={Action.FadeIn(10,false),extra},bulletEvents={function(cir,args,self)
                        cir.kinematicState.speed,cir.kinematicState.dir=math.rThetaAdd(cir.kinematicState.speed,cir.kinematicState.dir,300,fairy.kinematicState.dir)
                        cir.speedRef=cir.kinematicState.speed
                        Event{obj=cir,action=function()
                            wait(60)
                            local reflections=Mirror.getReflections(cir.kinematicState.pos,48)
                            for i,reflection in ipairs(reflections) do
                                local newDir=reflection.deltaDir+cir.kinematicState.dir*(reflection.rotateReverse and -1 or 1)
                                local newPos=reflection.pos
                                local newKinematicState={pos=newPos,dir=newDir,speed=cir.kinematicState.speed}
                                local cir2=Bullet{kinematicState=newKinematicState,sprite=cir.sprite,size=cir.size,batch=cir.batch,spriteTransparency=cir.spriteTransparency,lifeFrame=cir.lifeFrame,spriteColor=reflection.color,extraUpdate={Action.FadeIn(30,true),extra}}
                                cir2.t=cir.t
                                cir2.speedRef=cir.speedRef
                            end
                        end}
                    end}}
                    local angle=math.eval(0,999)
                    local posb=geo:rThetaGo(pos,100,fairy.kinematicState.dir)
                    for i=1,3 do
                        local pos1=geo:rThetaGo(posb,60,angle+math.pi*2/3*(i-1))
                        local pos2=geo:rThetaGo(posb,60,angle+math.pi*2/3*(i))
                        local mirror=Mirror(pos1,pos2,posb,{extraUpdate={Action.FadeIn(60,false,0.7),Action.FadeOut(30,false)},lifeFrame=120})
                    end
                end
                fairy.dieEffect=function(self)
                    mirrorPattern()
                    Enemy.dieEffect(self)
                end
                Event{obj=fairy,action=function ()
                    wait(240)
                    if not fairy.removed then
                        Event.EaseEvent{obj=fairy,easeObj=fairy.kinematicState,aims={speed=-600},duration=60}
                        mirrorPattern()
                    end
                end}
                wait(540)
                DynamicUIObjs.showStageTitle('stage3')
                wait(330)
            end
        },
    }
}