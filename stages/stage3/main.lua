--[[some tricks
2 fairies, if one dies, mirror appears to revive the dead one by reflecting the alive one. must control hp to kill them in a short time.
midboss drops 1 item but uses mirror to copy many
spellcard have one bullet inside rotating mirrors and keep spawing reflections
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
        kora.midboss
    }
}