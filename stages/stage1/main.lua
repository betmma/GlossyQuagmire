
local function smallFairyFunc(basePos,flip,r,shooting)
    r=r or 400
    local sign=flip and -1 or 1
    local dir0=G.runInfo.player.viewDirection
    for i=1,30 do
        wait(10)
        local dir1=dir0+math.pi/30*i*sign
        local pos2,dir2=G.runInfo.geometry:rThetaGo(basePos,r,dir1)
        local fairy=Enemy{kinematicState={pos=pos2,dir=dir2+math.pi,speed=200},maxhp=10,sprite=Asset.fairySprites.small.orange,lifeFrame=300,spriteTransparency=0,extraUpdate={Enemy.presetActions.fadeAndHint,function(self)
            local ratio=1-2*self.frame/self.lifeFrame
            self.kinematicState.dir=G.runInfo.geometry:to(self.kinematicState.pos,basePos)+math.pi*(0.5-ratio*0.3)*sign
        end},dropItems={powerSmall=1}}
        if shooting~=false then
            BulletSpawner{
                period=60,firstPeriod=120,lifeFrame=270,bulletNumber=2,bulletSpeed=150,range=math.pi*0.5,bulletSize=1,angle='player',bulletSprite=BulletSprites.rim.orange,bulletLifeFrame=600,visible=false
            }:bindState(fairy)
        end
    end
end
---@type OneStageData
return{
    init=function()
        local border=Border.CircleBorder{center=G.runInfo.geometry:init().pos,radius=400}
        G.runInfo.player.border=border
    end,
    segments={
        {
            key='1-1',
            type='midStage',
            func=function()
                DynamicUIObjs.showSoundtrack()
                wait(30)
                local basePos=G.runInfo.geometry:init().pos
                local pos1,dir1=G.runInfo.geometry:rThetaGo(basePos,200,-math.pi/2)
                local pos2,dir2=G.runInfo.geometry:rThetaGo(pos1,-400,dir1+math.pi/2)
                local pos3,dir3=G.runInfo.geometry:rThetaGo(pos1,-400,dir1-math.pi/2)
                local kstate={pos=pos2,dir=dir2,speed=160}
                local kstate2={pos=pos3,dir=dir3,speed=160}
                for i=1,10 do
                    local fairy=Enemy{kinematicState=copyTable(kstate),maxhp=10,sprite=Asset.fairySprites.small.red,lifeFrame=300,spriteTransparency=0,extraUpdate={Enemy.presetActions.fadeAndHint},dropItems={powerSmall=1}}
                    BulletSpawner{
                        period=30,firstPeriod=i*3+30,lifeFrame=270,bulletNumber=1,bulletSpeed=150,bulletSize=1,angle='player',bulletSprite=BulletSprites.round.red,bulletLifeFrame=600,visible=false
                    }:bindState(fairy)
                    wait(15)
                    fairy=Enemy{kinematicState=copyTable(kstate2),maxhp=10,sprite=Asset.fairySprites.small.orange,lifeFrame=300,spriteTransparency=0,extraUpdate={Enemy.presetActions.fadeAndHint},dropItems={powerSmall=1}}
                    BulletSpawner{
                        period=60,firstPeriod=i*3+30,lifeFrame=270,bulletNumber=1,bulletSpeed=150,bulletSize=1,angle='player',bulletSprite=BulletSprites.round.orange,bulletLifeFrame=600,visible=false
                    }:bindState(fairy)
                end
                wait(60)
                for i=1,20 do
                    local flag=i%4<=1
                    local pos3,dir3=G.runInfo.geometry:rThetaGo(pos1,400,dir1+math.mod2Sign(i)*0.6)
                    local fairy=Enemy{kinematicState={pos=copyTable(pos3),dir=dir3+math.pi,speed=160},maxhp=10,sprite=Asset.fairySprites.small[flag and 'blue' or 'green'],lifeFrame=300,spriteTransparency=0,extraUpdate={Enemy.presetActions.fadeAndHint},dropItems={powerSmall=flag and 1 or 0, point=flag and 0 or 1}}
                    BulletSpawner{
                        period=30,firstPeriod=i*3+30,lifeFrame=210,bulletNumber=1,bulletSpeed=150,bulletSize=1,angle='player',bulletSprite=BulletSprites.round[flag and 'blue' or 'green'],bulletLifeFrame=600,visible=false
                    }:bindState(fairy)
                    wait(15)
                end
                wait(60)
                DynamicUIObjs.showStageTitle('stage1')
                wait(300)
            end
        },
        {
            key='1-2',
            type='midStage',
            func=function()
                local basePos=G.runInfo.geometry:init().pos
                local function largeFairyFunc(flip)
                    local sign=flip and -1 or 1
                    local pos1,dir1=G.runInfo.geometry:rThetaGo(basePos,400,G.runInfo.player.viewDirection-math.pi/2-math.pi*0.4*sign)
                    local largeFairy=Enemy{kinematicState={pos=copyTable(pos1),dir=dir1+math.pi*0.5*sign,speed=240},maxhp=400,sprite=Asset.fairySprites.large.red,lifeFrame=900,spriteTransparency=0,extraUpdate={Enemy.presetActions.fadeAndHint,function(self)
                        if self.frame<=600 then 
                            self.kinematicState.dir=self.kinematicState.dir+math.pi/140*sign
                        else
                            self.kinematicState.speed=math.lerp(self.kinematicState.speed,120,0.02)
                        end
                    end},dropItems={powerSmall=10,point=5}}
                    BulletSpawner{
                        period=25,firstPeriod=50,lifeFrame=500,bulletNumber=100,bulletSpeed=150,bulletSize=1,visible=false,range=math.pi*1.8,angle=0,bulletSprite=BulletSprites.rice.red,bulletLifeFrame=600,bulletEvents={
                            function(cir,args,self)
                                cir.kinematicState.dir=cir.kinematicState.dir+largeFairy.kinematicState.dir+math.pi/2
                                local index=args.index
                                cir.kinematicState.dir=cir.kinematicState.dir+math.pi*0.05*(index>50 and 1 or -1)
                                cir.kinematicState.speed=cir.kinematicState.speed*(1+math.abs(math.sin(index/100*math.pi*2)))
                            end
                        }
                    }:bindState(largeFairy)
                end
                Event.Event{action=function()
                    largeFairyFunc(false)
                    wait(600)
                    largeFairyFunc(true)
                end}
                wait(120)
                smallFairyFunc(basePos,false)
                wait(300)
                smallFairyFunc(basePos,true)
                wait(300)
            end
        },
        require('stages.stage1.boss'),
        {
            key='1-3',
            type='midStage',
            --[[large fairy has small fairies rounding. small fairies shoot small bullets forming a circle (rounding a hidden center)]]
            func=function()
                local basePos=G.runInfo.geometry:init().pos
                for i=1,4 do
                    local color=({'red','green','blue','purple'})[i]
                    Event{action=function()
                        local r=math.eval(300,100)
                        local angle=math.pi/2*i+math.eval(0,math.pi/4)
                        local pos,dir=G.runInfo.geometry:rThetaGo(basePos,r,angle)
                        local bigFairy=Enemy{kinematicState={pos=pos,dir=dir,speed=0},maxhp=400,sprite=Asset.fairySprites.large[color],lifeFrame=600,spriteTransparency=0,extraUpdate={Enemy.presetActions.fadeAndHint,function(self)
                            local pos,dir=G.runInfo.geometry:rThetaGo(basePos,r*(0.6+0.4*math.cos(self.frame/300)),angle+self.frame/300*math.mod2Sign(i))
                            self.kinematicState.pos=pos
                            self.kinematicState.dir=dir+math.pi/2
                        end},dropItems={powerSmall=20,point=10}}
                        local firstSpawner
                        local cores={}
                        for j=1,10 do
                            local function bulletevent(cir,args,self)
                                cir.spriteTransparency=0
                                local index=args.index
                                if not cores[index] or math.abs(cores[index].frame-cir.frame)>20 then -- the j=1 spawner could have died so the first spawner finding current core doesnt exist should create one. and, every index has its own core so cores is a table
                                    cores[index]=Bullet{kinematicState={pos=copyTable(bigFairy.kinematicState.pos),dir=cir.kinematicState.dir,speed=150},sprite=Asset.bulletSprites.round[color],lifeFrame=600,safe=true,invincible=true,spriteTransparency=0,extraUpdate=function(self)
                                        self.kinematicState.speed=self.kinematicState.speed+1
                                    end}
                                end
                                Event{obj=cir,action=function()
                                    local r,dir
                                    while true do
                                        wait()
                                        if cores[index] then
                                            cir.core=cores[index]
                                            r=G.runInfo.geometry:distance(cir.kinematicState.pos,cores[index].kinematicState.pos)
                                            dir=G.runInfo.geometry:to(cores[index].kinematicState.pos,cir.kinematicState.pos)
                                            break
                                        end
                                    end
                                    cir.spriteTransparency=1
                                    while not cir.core.removed do
                                        dir=dir+1/60
                                        local pos=G.runInfo.geometry:rThetaGo(cir.core.kinematicState.pos,r,dir)
                                        cir.kinematicState.pos=pos
                                        wait()
                                    end
                                end}
                            end
                            wait(5)
                            local smallFairy=Enemy{kinematicState={pos=copyTable(pos),dir=dir+math.pi,speed=0},maxhp=40,sprite=Asset.fairySprites.small[color],lifeFrame=600-j*5,spriteTransparency=0,extraUpdate={Enemy.presetActions.fadeAndHint,function(self)
                                local pos,dir=G.runInfo.geometry:rThetaGo(bigFairy.kinematicState.pos,50*math.clamp(self.frame/60,0,1),angle+bigFairy.frame/60*math.mod2Sign(i)+math.pi*2*j/10)
                                self.kinematicState.pos=pos
                                self.kinematicState.dir=dir+math.pi/2
                            end},dropItems={powerSmall=1}}
                            local spawner=BulletSpawner{
                                period=60,firstPeriod=120-j*5,lifeFrame=540-j*5,bulletNumber=4,bulletSpeed=0,bulletSize=1,angle='0+999',bulletSprite=BulletSprites.round[color],bulletLifeFrame=600,visible=false,bulletEvents={bulletevent
                                }
                            }
                            spawner:bindState(smallFairy)
                            if j==1 then
                                firstSpawner=spawner
                            end
                            spawner.firstSpawner=firstSpawner
                        end
                    end}
                    wait(150)
                end
                wait(500)
            end
        },
        {
            key='1-4',
            type='midStage',
            func=function()
                local basePos=G.runInfo.geometry:init().pos
                local colors={{1,0.1,0.1},{0.1,1,0.1},{0.1,0.1,1},{1,0.1,1}}
                local count=0
                local function wallFairy(angle,sign)
                    sign=sign or 1
                    local color=colors[count%4+1]
                    count=count+1
                    local pos,dir=G.runInfo.geometry:rThetaGo(basePos,350,angle)
                    local pos2,dir2=G.runInfo.geometry:rThetaGo(pos,-600,dir+math.pi/2*sign)
                    local fairy=Enemy{kinematicState={pos=pos2,dir=dir2,speed=600},maxhp=120,sprite=Asset.fairySprites.medium.black,lifeFrame=120,spriteTransparency=0,extraUpdate={Enemy.presetActions.fadeAndHint},dropItems={powerSmall=2}}
                    BulletSpawner{
                        period=2,firstPeriod=30,lifeFrame=80,bulletNumber=1,bulletSpeed=150,bulletSize=1,angle=0,bulletSprite=BulletSprites.rim.white,bulletLifeFrame=500,visible=false,bulletEvents={
                            function(cir,args,self)
                                cir.safe=true
                                cir.spriteTransparency=0
                                cir.kinematicState.speed=cir.kinematicState.speed+50*(self.spawnTimes%4)
                                Event.EaseEvent{
                                    obj=cir,easeObj=cir.kinematicState,duration=80,aims={speed=-200},progressFunc=Event.sineBackProgressFunc
                                }
                                cir.kinematicState.dir=fairy.kinematicState.dir+math.pi/2*sign-0.1*(self.spawnTimes%4)*sign
                                cir.shade=math.interpolateTable({1,1,1},color,(self.spawnTimes%4+0.5)/4)
                            end
                        },bulletExtraUpdate={function(self)
                            if self.frame%8==7 and self.frame<40 then
                                self.count=(self.count or -1)+1
                                for i=-1,1,2 do
                                    local numRef=self.count
                                    local follower=Bullet{kinematicState=copyTable(self.kinematicState),sprite=BulletSprites.rim.white,lifeFrame=900,spriteTransparency=0.5,spriteColor={1,1,1,1},extraUpdate={
                                        function(cirF)
                                            if self.removed then
                                                if not cirF.flag then
                                                    cirF.flag=true
                                                    cirF.kinematicState.dir=math.eval(math.pi,1)+self.kinematicState.dir
                                                end
                                                return
                                            end
                                            cirF.spriteTransparency=math.clamp(cirF.spriteTransparency+0.05,0,1)
                                            if cirF.frame>100 then
                                                cirF.spriteColor=math.lerpTable(cirF.spriteColor,self.shade,0.02)
                                            end
                                            cirF.kinematicState.dir=self.kinematicState.dir
                                            local smooth=math.clamp(cirF.frame/8,0,1)
                                            cirF.kinematicState.pos=G.runInfo.geometry:rThetaGo(self.kinematicState.pos,10*i*math.max(0.01,numRef+smooth-1),self.kinematicState.dir+math.pi*(1/2))
                                        end
                                    }}
                                end
                            end
                        end}
                    }:bindState(fairy)
                end
                Event{action=function()
                    smallFairyFunc(basePos,false,200,false)
                end}
                wait(60)
                wallFairy(0)
                wallFairy(0,-1)
                wait(100)
                wallFairy(math.pi)
                wallFairy(math.pi,-1)
                wait(200)
                local angle=math.eval(0,999)
                Event{action=function()
                    wait(120)
                    smallFairyFunc(basePos,true,200,false)
                end}
                for i=1,4 do
                    wallFairy(angle-math.pi/2*i)
                    wait(60)
                end
                wait(400)
            end
        },
        -- require('stages.stage1.boss'),
    }
}