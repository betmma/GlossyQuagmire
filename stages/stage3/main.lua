--[[some tricks
2 fairies, if one dies, mirror appears to revive the dead one by reflecting the alive one. must control hp to kill them in a short time.
midboss drops 1 item but uses mirror to copy many
spellcard have one bullet inside rotating mirrors and keep spawing reflections
use reflection as visual block
mirrors around player
]]

local kora=require"stages.stage3.kora"

---@type OneStageDataRaw
return{
    init=function()
        if G.runInfo.geometry==G.geometries.Euclidean then
            local border=Border.XYBorder{minx=20,maxx=500,miny=30,maxy=560}
            G.runInfo.player.border=border
            G:replaceBackgroundPatternIfNot(BackgroundPattern.Corridor)
        end
        BGM:play('level3',true)
        DynamicUIObjs.showSoundtrack()
    end,
    segments={
        {
            key='3-1',
            type='midStage',
            func=function() -- 13s. midboss should appear at 41s
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
                        BulletSpawner{kinematicState={pos=copyTable(self.kinematicState.pos),dir=self.kinematicState.dir,speed=0},period=999,firstPeriod=1,lifeFrame=2,bulletNumber=DSWITCH{9,19,29,49},range=math.pi*1.5,bulletSpeed=900,bulletSize=1,angle='player',bulletSprite=BulletSprites.rice.white,bulletLifeFrame=600,bulletExtraUpdate=slowDown}
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
                    Mirror.setHSV({0,0.7,1},0.3)
                    if mirrorPatternHappened then
                        return
                    end
                    mirrorPatternHappened=true
                    SFX:play('enemyCharge')
                    local pos=fairy.kinematicState.pos
                    local extra=function(self)
                        local t=self.frame
                        if t<60 then
                            self.kinematicState.speed=self.kinematicState.speed*0.95
                        elseif t>90 then
                            self.kinematicState.speed=math.lerp(self.kinematicState.speed,self.speedRef/4,0.03)
                        end
                    end
                    local bulletSprite=BulletSprites.lightRound.white
                    if DIFF()>=G.NORMAL then
                        bulletSprite=BulletSprites.round.black
                    end
                    local spawner2=BulletSpawner{kinematicState={pos=pos,dir=0,speed=0},period=999,firstPeriod=1,lifeFrame=2,bulletNumber=DSWITCH{1,3,6,10},bulletSpeed=50,angle='player',bulletSprite=bulletSprite,bulletLifeFrame=600,bulletExtraUpdate={Action.FadeIn(10,false),extra},bulletEvents={function(cir,args,self)
                        cir.kinematicState.speed,cir.kinematicState.dir=math.rThetaAdd(cir.kinematicState.speed,cir.kinematicState.dir,300,fairy.kinematicState.dir)
                        cir.speedRef=cir.kinematicState.speed
                        Event{obj=cir,action=function()
                            wait(60)
                            Mirror.spawnReflections(cir,48,{extraUpdate={Action.FadeIn(30,true),extra}},{speedRef=true})
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
                wait(480)
                DynamicUIObjs.showStageTitle('stage3')
                wait(270)
            end
        },
        {
            key='3-2',
            type='midStage',
            func=function() -- 15s
                local geo=G.runInfo.geometry
                local base=geo:init().pos
                local pos1,dir1=geo:rThetaGo(base,600,-math.pi/2)
                local function spawn(mode)
                    local fairy
                    local color=mode==0 and 'white' or 'black'
                    fairy=Enemy{kinematicState={pos=copyTable(pos1),dir=dir1+math.pi,speed=400},sprite=Asset.fairySprites.small[color],maxhp=40,lifeFrame=600,dropItems={point=1},extraUpdate={Enemy.presetActions.fadeAndHint,function(self)
                        if self.frame==120 then
                            self:addHPProtection(30,999)
                            local sign=math.randomSign()
                            self.sign=sign
                            if self~=fairy then
                                self.kinematicState.dir=geo:to(self.kinematicState.pos,fairy.kinematicState.pos)+mode*math.pi/4*sign
                            end
                        end
                        if self.frame>=120 and self.frame<240 then
                            self.kinematicState.speed=self.kinematicState.speed+0.8
                        end
                        local extraCond=DIFF()>G.NORMAL or self.frame%120<60
                        if self.frame>=120 and self.frame<=400 and self.frame%15==0 and extraCond then
                            for i=-1,1,2 do
                                Bullet{kinematicState={pos=copyTable(self.kinematicState.pos),dir=self.kinematicState.dir-mode*math.pi/2*self.sign+DSWITCH{0,0.1,0.1,0.2}*i,speed=100},sprite=BulletSprites.kunai[color],lifeFrame=300,spriteColor=self.spriteColor,extraUpdate={Action.FadeOut(30,true)}}
                            end
                        end
                    end}}
                    fairy.dieEffect=function (self)
                        Enemy.dieEffect(self)
                        if geo:to(base,self.kinematicState.pos)>0 then -- if lower than base skip death bullets
                            return
                        end
                        BulletSpawner{kinematicState={pos=copyTable(self.kinematicState.pos),dir=self.kinematicState.dir,speed=0},period=999,firstPeriod=1,lifeFrame=2,bulletNumber=DSWITCH{3,4,6,8},bulletSpeed=DSWITCH{150,150,200,200},bulletSize=1,angle='0+999',bulletSprite=BulletSprites.bigRound[color],bulletLifeFrame=300,bulletEvents={function(cir,args,self_)
                            cir.spriteColor=self.spriteColor
                        end},bulletExtraUpdate={}}
                    end
                    fairy:addHPProtection(120,999)
                    Event.EaseEvent{obj=fairy,easeObj=fairy.kinematicState,aims={speed=0},duration=60}
                    Event{obj=fairy,action=function ()
                        wait(45)
                        SFX:play('enemyCharge')
                        local posb=fairy.kinematicState.pos
                        local angle=math.eval(0,999)
                        for i=1,3 do
                            local pos1=geo:rThetaGo(posb,60,angle+math.pi*2/3*(i-1))
                            local pos2=geo:rThetaGo(posb,60,angle+math.pi*2/3*(i))
                            local mirror=Mirror(pos1,pos2,posb,{extraUpdate={Action.FadeIn(60,false,0.7),Action.FadeOut(30,false)},lifeFrame=120})
                        end
                        wait(70)
                        Mirror.setHSV({0.5,0.7,1},0.3)
                        Mirror.spawnReflections(fairy,29)
                    end}
                end
                spawn(0)
                wait(300)
                spawn(1)
                wait(600)
            end
        },
        {
            key='3-3',
            type='midStage',
            func=function() -- 12s
                local geo=G.runInfo.geometry
                local base=geo:init().pos
                local pos1,dir1=geo:rThetaGo(base,400,-math.pi/2)
                local function speedadd(self)
                    self.kinematicState.speed,self.kinematicState.dir=math.rThetaAdd(self.kinematicState.speed,self.kinematicState.dir,1,self.dirAim)
                end
                local extraUpdate={Action.FadeIn(30,true),Action.FadeOut(10,true),speedadd}
                local fairyList={}
                local function fairies(lr,rotate)
                    local n=lr*2+(rotate>0 and 1 or 0)
                    local colors={'red','blue','green','yellow'}
                    local color=colors[n+1]
                    local rdir=rotate*0.1
                    local pos2,dir2=geo:rThetaGo(pos1,300,dir1-math.pi/2+math.pi*lr+rdir)
                    dir2=dir2+math.pi-rdir
                    local period=DSWITCH{240,180,140,120}
                    Event{action=function ()
                        for i=1,10 do
                            local fairy=Enemy{kinematicState={pos=copyTable(pos2),dir=dir2,speed=70},sprite=Asset.fairySprites.small[Asset.spectrum1MapFairySpectrum[color]],maxhp=80,lifeFrame=400,dropItems={powerSmall=2},extraUpdate={Enemy.presetActions.fadeAndHint,function (self)
                                if self.frame%3==0 and (self.frame-i*17+rotate*100)%period<15 then
                                    SFX:play('enemyShot',true,0.5)
                                    local dir=self.kinematicState.dir+(math.pi/2*(lr==0 and 1 or -1))*(self.mirrored and -1 or 1)
                                    Bullet{kinematicState={pos=copyTable(self.kinematicState.pos),dir=dir+(lr==0 and 1 or -1)*0.3,speed=-60-n*5},sprite=BulletSprites[self.mirrored and 'starDark' or 'star'][color],lifeFrame=DSWITCH{240,240,360,360},extraUpdate=extraUpdate}.dirAim=dir
                                end
                            end}}
                            table.insert(fairyList,fairy)
                            wait(20)
                        end
                    end}
                end
                fairies(0,1)
                wait(30)
                fairies(1,-1)
                wait(30)
                fairies(0,-1)
                wait(30)
                fairies(1,1)
                wait(30)
                local pos2,dir2=geo:rThetaGo(base,200,-math.pi/2)
                local posl=geo:rThetaGo(pos2,300,dir2-math.pi/2)
                local posr=geo:rThetaGo(pos2,300,dir2+math.pi/2)
                SFX:play('enemyCharge')
                Mirror.setHSV({0.5,0,0.7},0)
                local mirror=Mirror(posl,posr,pos1,{extraUpdate={Action.FadeIn(60,false,0.7),Action.FadeOut(30,false)},lifeFrame=120})
                wait(90)
                for i,fairy in ipairs(fairyList) do
                    if not fairy.removed then
                        Mirror.spawnReflections(fairy,1)
                    end
                end
                wait(510)
            end
        },
        kora.midboss,
        {
            key='3-4',
            type='midStage',
            func=function () -- 34s
                local geo=G.runInfo.geometry
                local base=geo:init().pos
                local pos1,dir1=geo:rThetaGo(base,600,-math.pi/2)
                dir1=dir1+math.pi
                local function smallFairy(pos,dir,sign,color)
                    local fairy=Enemy{kinematicState={pos=copyTable(pos),dir=dir,speed=150},sprite=Asset.fairySprites.small[color],maxhp=50,lifeFrame=600,dropItems={powerSmall=1,point=1},extraUpdate={Enemy.presetActions.fadeAndHint}}
                    fairy:addHPProtection(60,3)
                    local spawner=BulletSpawner{firstPeriod=100,period=DSWITCH{40,30,20,20},lifeFrame=9999,bulletNumber=1,range=math.pi/2,angle=dir,bulletSpeed=150,bulletSprite=BulletSprites.giant[color],highlight=true,bulletLifeFrame=300,bulletExtraUpdate={Action.ZoomIn(20),Action.FadeIn(20,true),Action.FadeOut(10,true)}}
                    spawner:bindState(fairy)
                    Event.LoopEvent{obj=spawner,period=1,executeFunc=function ()
                        spawner.angle=fairy.kinematicState.dir
                        -- spawner.range=math.pi/2--+math.sin(fairy.frame/60*math.pi)*0.5
                        -- spawner.bulletNumber=(spawner.frame%60<40)and 1 or 0
                        if spawner.frame>60 and spawner.frame<200 then
                            fairy.kinematicState.speed=math.lerp(fairy.kinematicState.speed,30,0.015)
                        end
                        if spawner.frame>200 and spawner.frame<300 then
                            fairy.kinematicState.speed=math.lerp(fairy.kinematicState.speed,150,0.015)
                        end
                        if spawner.frame>200 then
                            fairy.kinematicState.dir=fairy.kinematicState.dir+sign*0.02
                        end
                    end}
                end
                local function smallwave(n,color)
                    color=color or 'black'
                    for i=1,n do
                        local d=450*((i-0.5)/n-0.5)
                        local pos,dir=geo:rThetaGo(pos1,d,dir1-math.pi/2)
                        dir=dir+math.pi/2
                        Event{action=function ()
                            wait(math.abs(i-n/2-0.5)*40)
                            smallFairy(pos,dir,(i-0.5)>n/2 and 1 or -1,color)
                        end}
                    end
                end
                local function bigFairy(color,pos,dir,id)
                    local extraUpdate=function(self)
                        local rd1,rd2=self.rd1,self.rd2
                        self.kinematicState.dir=self.kinematicState.dir+(math.sin(self.frame/(30+30*rd1)+rd2*99)*0.005+math.sin(self.frame/(50+40*rd2)+rd1*99)*0.005)*math.mod2Sign(self.index)
                    end
                    local lifeFrame=1200
                    if color=='white' then
                        lifeFrame=360
                    end
                    local flag=color~='white'
                    local fairy=Enemy{kinematicState={pos=copyTable(pos),dir=dir,speed=400},sprite=Asset.fairySprites.large[color],maxhp=flag and 400 or 700,lifeFrame=lifeFrame,dropItems={powerSmall=flag and 5 or 10,point=flag and 5 or 10},extraUpdate={Enemy.presetActions.fadeAndHint,function (self)
                        if self.frame<60 then
                            self.kinematicState.speed=self.kinematicState.speed*0.95
                        elseif self.frame==60 then
                            self.kinematicState.speed=0
                        end
                        if self.frame==self.lifeFrame-30 then
                            SFX:play('enemyPowerfulShot')
                            self:addHPProtection(30,999)
                            BulletSpawner{period=999,firstPeriod=1,lifeFrame=2,bulletNumber=DSWITCH{29,49,69,89},bulletSpeed=200,bulletSize=1.5,angle='player',bulletSprite=BulletSprites.bigStar[color],bulletLifeFrame=600,bulletExtraUpdate={Action.FadeIn(10,true)},bulletEvents={function (cir,args,self_)
                                cir.spriteRotationSpeed=0.01
                                cir.spriteColor=self.spriteColor
                                cir.kinematicState.speed=cir.kinematicState.speed*(1-(args.index*math.mod2Sign(self.index))%3*0.1)
                            end}}:bindState(self)
                        end
                        if self.frame==60 or self.mirrored then
                            self.mirrored=false
                            local spawner=BulletSpawner{period=5,lifeFrame=9999,bulletNumber=DSWITCH{4,6,8,10},range=math.pi*2,angle=math.eval(0,9),bulletSpeed=130,bulletSprite=BulletSprites.bigStar[color],bulletLifeFrame=DSWITCH{200,200,260,260},bulletExtraUpdate={Action.FadeIn(10,true),Action.FadeOut(10,true),extraUpdate},bulletEvents={function(cir,args,self_)
                                if (self_.spawnTimes)%10>4 then
                                    cir.lifeFrame=30
                                end
                                cir.index=args.index
                                if cir.index%2==0 then
                                    cir.kinematicState.dir=-cir.kinematicState.dir
                                end
                                cir.rd1,cir.rd2=math.pseudoRandom(self.index),math.pseudoRandom(self.index,2)
                                cir.spriteColor=self.spriteColor
                            end}}
                            Event.EaseEvent{obj=spawner,aims={bulletSpeed=250},duration=1200}
                            Event.EaseEvent{obj=spawner,aims={angle=spawner.angle+18*math.mod2Sign(self.index)},duration=1200}
                            spawner:bindState(self)
                        end
                    end}}
                    fairy:addHPProtection(60,3)
                    fairy.dieEffect=function(self)
                        Enemy.dieEffect(self)
                        Effect.Shockwave{kinematicState={pos=copyTable(self.kinematicState.pos),dir=0,speed=0},lifeFrame=20,radius=10,growSpeed=0.4,spriteTransparency=1,color=color,canRemove={bullet=true}}
                    end
                    fairy.index=id
                    return fairy
                end
                smallwave(5)
                wait(120)
                bigFairy('white',pos1,dir1,0)
                smallwave(6)
                wait(120)
                smallwave(5)
                wait(300)
                local posl,dirl=geo:rThetaGo(pos1,100,dir1+math.pi/2)
                dirl=dirl-math.pi/2
                local posr,dirr=geo:rThetaGo(pos1,100,dir1-math.pi/2)
                dirr=dirr+math.pi/2
                local posd=geo:rThetaGo(base,200,math.pi/2)
                local fairyl=bigFairy('black',posl,dirl,1)
                local fairyr=bigFairy('black',posr,dirr,2)
                Event.Event{action=function()
                    local h=math.eval(0,1)
                    local id=3
                    while not (fairyl.removed and fairyr.removed) do
                        local live
                        if fairyl.removed or fairyr.removed and (fairyl.frame<fairyl.lifeFrame-60) then
                            live=fairyl.removed and fairyr or fairyl
                            SFX:play('enemyCharge')
                            Mirror.setHSV({h,0.7,1},0)
                            h=h-0.3
                            wait(90)
                            Mirror(posd,pos1,live.kinematicState.pos,{extraUpdate={Action.FadeIn(30,false,0.5),Action.FadeOut(30,false)},lifeFrame=120})
                            wait(30)
                            if not live.removed then
                                local new=Mirror.spawnReflections(live,1,nil,nil,true)[1]
                                new.hp=new.maxhp
                                if live==fairyl then
                                    fairyr=new
                                else
                                    fairyl=new
                                end
                                new.index=id
                                id=id+1
                                wait(30)
                            end
                        end
                        wait()
                    end
                end}
                Event.Event{action=function()
                    local t=0
                    while not (fairyl.removed and fairyr.removed) do
                        wait()
                        t=t+1
                        if t%180==1 then
                            smallwave(math.ceil(t/180)%2+5)
                        end
                    end
                    SFX:play('enemyPowerfulShot')
                    local colors={'red','blue','green','orange'}
                    while t<1140 do
                        wait()
                        t=t+1
                        if t%90==1 then
                            smallwave(math.ceil(t/90)%2+5, colors[math.ceil(t/90)%4 + 1])
                        end
                    end
                end}
                wait(1500)
            end
        },
        {
            key='3-5',
            type='midStage',
            func=function() -- 15s
                local geo=G.runInfo.geometry
                local base=geo:init().pos
                local pos1,dir1=geo:rThetaGo(base,350,-math.pi/2)
                local function group(pos,dir,sign)
                    local bigFairy=Enemy{kinematicState={pos=copyTable(pos),dir=dir,speed=0},sprite=Asset.fairySprites.large.white,maxhp=400,lifeFrame=900,dropItems={powerSmall=10,point=10},extraUpdate={Enemy.presetActions.fadeAndHint,function (self)
                        if self.frame>=self.lifeFrame-60 then
                            self.kinematicState.speed=self.kinematicState.speed+5
                        end
                    end}}
                    local spawner=BulletSpawner{firstPeriod=100,period=DSWITCH{120,90,60,60},lifeFrame=9999,bulletNumber=DSWITCH{1,1,3,3},angle='player',bulletSpeed=100,bulletSprite=BulletSprites.giant.white,highlight=true,bulletLifeFrame=600,bulletExtraUpdate={Action.FadeIn(20,true),Action.FadeOut(10,true)}}
                    spawner:bindState(bigFairy)
                    bigFairy:addHPProtection(200,3)
                    local n=3
                    for i=1,n do
                        local angle=dir+math.pi*2/n*(i-1)
                        local smallFairy=Enemy{sprite=Asset.fairySprites.small.white,maxhp=350,lifeFrame=900,dropItems={powerSmall=1,point=1},extraUpdate={Enemy.presetActions.fadeAndHint}}
                        smallFairy:addHPProtection(200,3)
                        DanmakuFuncs.orbitBind(smallFairy,bigFairy,function (self, centerObj)
                            return {r=math.min(50,self.frame),theta=self.frame/20*sign+angle}
                        end)
                        local spawner=BulletSpawner{lifeFrame=9999,period=4,bulletNumber=3,range=math.pi/15,angle=0,bulletSpeed=60,bulletSprite=BulletSprites.rice.white,bulletLifeFrame=600,bulletExtraUpdate={Action.FadeIn(10,true),Action.FadeOut(10,true)}}
                        spawner:bindState(smallFairy)
                        Event.LoopEvent{obj=spawner,period=1,executeFunc=function ()
                            spawner.angle=geo:to(spawner.kinematicState.pos,bigFairy.kinematicState.pos)+math.pi/6*sign
                            spawner.bulletNumber=spawner.frame%120<20 and DSWITCH{1,2,3,4} or 0
                        end}
                    end
                    return bigFairy
                end
                local bigFairies={}
                for i=-1,1,2 do
                    local pos,dir=geo:rThetaGo(pos1,100,dir1+i*math.pi/2)
                    local bigFairy=group(pos,dir,i)
                    table.insert(bigFairies, bigFairy)
                end
                Event.LoopEvent{period=180,times=4,executeFunc=function ()
                    local posc,dirc=geo:rThetaGo(base,200,-math.pi/2)
                    local mirrorData={
                        {{pos1=geo:rThetaGo(posc,300,dirc-math.pi/2),pos2=geo:rThetaGo(posc,300,dirc+math.pi/2),posin=pos1},},
                        {{pos1=posc,pos2=geo:rThetaGo(posc,400,dirc+math.pi/4),posin=pos1},
                        {pos1=posc,pos2=geo:rThetaGo(posc,400,dirc-math.pi/4),posin=pos1}}
                    }
                    for i=1,2 do
                        if not bigFairies[i].removed then
                            local posin=bigFairies[i].kinematicState.pos
                            table.insert(mirrorData, {{pos1=posc,pos2=geo:rThetaGo(posc,300,dirc+math.pi/2*(i-1)),posin=posin},
                            {pos1=posc,pos2=geo:rThetaGo(posc,300,dirc+math.pi/2*(i-2)),posin=posin}})
                        end
                    end
                    local id=math.random(1,#mirrorData)
                    Mirror.setHSV({math.eval(0,1),0.7,1},0.3)
                    for i=1,#mirrorData[id] do
                        local data=mirrorData[id][i]
                        Mirror(data.pos1,data.pos2,data.posin,{extraUpdate={Action.FadeIn(60,false,0.5),Action.FadeOut(30,false)},lifeFrame=120})
                    end
                    Event{action=function()
                        wait(85)
                        for i,bullet in ipairs(Bullet.objects) do
                            if not bullet.mirrored and not bullet.fromPlayer and geo:distance(bullet.kinematicState.pos, posc) < 400 then
                                Mirror.spawnReflections(bullet,3)
                            end
                        end
                    end}
                end}
                wait(900)
            end
        },
        kora.boss
    }
}