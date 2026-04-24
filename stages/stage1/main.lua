
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
                local function smallFairyFunc(flip)
                    local sign=flip and -1 or 1
                    local dir0=G.runInfo.player.viewDirection
                    for i=1,30 do
                        wait(10)
                        local dir1=dir0+math.pi/30*i*sign
                        local pos2,dir2=G.runInfo.geometry:rThetaGo(basePos,400,dir1)
                        local fairy=Enemy{kinematicState={pos=pos2,dir=dir2+math.pi,speed=200},maxhp=10,sprite=Asset.fairySprites.small.orange,lifeFrame=300,spriteTransparency=0,extraUpdate={Enemy.presetActions.fadeAndHint,function(self)
                            local ratio=1-2*self.frame/self.lifeFrame
                            self.kinematicState.dir=G.runInfo.geometry:to(self.kinematicState.pos,basePos)+math.pi*(0.5-ratio*0.3)*sign
                        end},dropItems={powerSmall=1}}
                        BulletSpawner{
                            period=60,firstPeriod=120,lifeFrame=270,bulletNumber=2,bulletSpeed=150,range=math.pi*0.5,bulletSize=1,angle='player',bulletSprite=BulletSprites.rim.orange,bulletLifeFrame=600,visible=false
                        }:bindState(fairy)
                    end
                end
                wait(120)
                smallFairyFunc(false)
                wait(300)
                smallFairyFunc(true)
                wait(300)
            end
        },
        require('stages.stage1.boss'),
    }
}