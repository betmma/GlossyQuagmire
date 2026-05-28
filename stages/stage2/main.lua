local function setZoomSpeed(value,duration)
    if G.runInfo.geometry~=G.geometries.MovingHyperbolic then
        return
    end
    if duration==0 then
        G.runInfo.geometry.viewConfig.zoomRatio=math.exp(value)
        return
    end
    Event.EaseEvent{
        easeObj=G.runInfo.geometry.viewConfig,aims={zoomRatio=math.exp(value)},duration=duration
    }
end

---@type OneStageData
return{
    init=function()
        if G.runInfo.geometry==G.geometries.Hyperbolic then
            local border=Border.CircleBorder{center=G.runInfo.geometry:init().pos,radius=400}
            G.runInfo.player.border=border
            G:replaceBackgroundPatternIfNot(BackgroundPattern.Honeycomb)
        elseif G.runInfo.geometry==G.geometries.MovingHyperbolic then
            local border=Border.XYBorder{minx=20,maxx=500,miny=20,maxy=560}
            G.runInfo.player.border=border
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
            func=function()
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
                wait(300)
            end
        }
    }
}