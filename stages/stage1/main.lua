
---@type OneStageData
return{
    segments={
        {
            key='1-1',
            type='midStage',
            func=function()
                local border=Border.CircleBorder{center=G.runInfo.geometry:init().pos,radius=400}
                G.runInfo.player.border=border
                DynamicUIObjs.showSoundtrack()
                local basePos=G.runInfo.geometry:init().pos
                local pos1,dir1=G.runInfo.geometry:rThetaGo(basePos,200,-math.pi/2)
                local pos2,dir2=G.runInfo.geometry:rThetaGo(pos1,-400,dir1+math.pi/2)
                local kstate={pos=pos2,dir=dir2,speed=160}
                for i=1,10 do
                    local fairy=Enemy{kinematicState=copyTable(kstate),maxhp=10,sprite=Asset.fairySprites.small.red,lifeFrame=300,spriteTransparency=0,extraUpdate={Action.FadeIn(30,true),Action.FadeOut(30,true),Action.AppearingHint()},dropItems={lifePiece=1,powerSmall=20}}
                    BulletSpawner{
                        period=30,firstPeriod=i*3+30,lifeFrame=270,bulletNumber=1,bulletSpeed=150,bulletSize=1,angle='player',bulletSprite=BulletSprites.round.red,bulletLifeFrame=600,visible=false
                    }:bindState(fairy)
                    wait(30)
                end
                DynamicUIObjs.showStageTitle('stage1')
                wait(300)
            end
        },
        
        require('stages.stage1.boss'),
    }
}