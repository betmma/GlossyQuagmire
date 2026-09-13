---@type OneStageDataRaw
return{
    init=function()
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
            func=function() -- 10s
                local geo=G.runInfo.geometry
                ---@cast geo Cylinder
                local pos0=geo:init().pos
                local pos1=geo:rThetaGo(pos0,300,-math.pi/2)
                local pos2=geo:rThetaGo(pos1,geo.a/2,0)
                for i=1,20 do
                    fairy=Enemy{kinematicState=copyTable{pos=pos2,dir=math.pi*(i%2),speed=180},maxhp=50,sprite=Asset.fairySprites.small.purple,lifeFrame=600,extraUpdate={Enemy.presetActions.fadeAndHintCompat},dropItems={powerSmall=2}}
                    BulletSpawner{
                        period=DSWITCH{90,70,50,30},firstPeriod=i*3+30,lifeFrame=570,bulletNumber=DSWITCH{1,3,3,3},bulletSpeed=150+i*10,bulletSize=1,angle='player',range=math.pi/2,bulletSprite=BulletSprites.round.purple,bulletLifeFrame=600,visible=false,bulletExtraUpdate={Action.FadeOut(20,true)}
                    }:bindState(fairy)
                    wait(12)
                end
                DynamicUIObjs.showStageTitle('stage5')
                wait(360)
                wait(240)
            end
        }
    }
}