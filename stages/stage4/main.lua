local function injectGeometry()
    G.runInfo.geometry=copyRecursiveTable(G.runInfo.geometry)
    local geo=G.runInfo.geometry
    ---@cast geo PortalGeometryBase
    geo.portal=true
    geo.viewConfig.following=true
    local applyVertexShaderRef=geo.applyVertexShader
    geo.applyVertexShader=function(self,viewer)
        local vx,vy=viewer.kinematicState.pos.x,viewer.kinematicState.pos.y
        local zoom=Portal.zoomFactor(viewer.kinematicState.pos)
        zoom=1/zoom
        local x,y=geo.viewConfig.screenCenter.x,geo.viewConfig.screenCenter.y
        love.graphics.translate(x,y)
        love.graphics.rotate(-viewer.viewDirection)
        love.graphics.scale(zoom,zoom)
        love.graphics.translate(-vx,-vy)
    end
    local zoomFactorToScreenRef=geo.zoomFactorToScreen
    geo.zoomFactorToScreen=function(self,position)
        local ret={1}--zoomFactorToScreenRef(self,position) -- anyway, the overall method doesn't work for hyperbolic and spherical geometry, as cannot "zoom" the view at all. about the original zoomFactorToScreen, there is a problem that it calls update that is portal version but should be original one. once that is fixed, actually does not need to override.
        local zoomFactorFromPortal=Portal.zoomFactor(position)--/Portal.zoomFactor(G.runInfo.player.kinematicState.pos)
        for i=1,#ret do
            ret[i]=ret[i]*zoomFactorFromPortal
        end
        return ret
    end
    local updateRef=geo.update
    geo.update=function(self,kinematicState,dt)
        local zoomFromPortal=Portal.zoomFactor(kinematicState.pos)
        updateRef(self,kinematicState,dt*zoomFromPortal)
        local pos,delta=Portal.considerTeleport(kinematicState.pos)
        kinematicState.pos=pos
        kinematicState.dir=kinematicState.dir+delta
    end
    local rThetaGoRef=geo.rThetaGo
    geo.rThetaGoRef=rThetaGoRef
    local rThetaGo=function(self,position,length,direction)
        if length==0 then
            return copyTable(position),direction
        end
        local segment=math.ceil(length/Portal.getMinimumRange())
        local stepLength=length/segment
        for i=1,segment do
            position, direction=rThetaGoRef(self,position,stepLength,direction)
            position, delta=Portal.considerTeleport(position)
            direction=direction+delta
        end
        return position,direction
    end
    local toRef=geo.to
    geo.toRef=toRef
    local distanceRef=geo.distance
    geo.distanceRef=distanceRef
    local rThetaToRef=geo.rThetaTo
    geo.rThetaToRef=rThetaToRef
    --- compare direct distance and distances through every portal. ignore zoom effect.
    local rThetaTo=function(self,position,target)
        local bestDistance=distanceRef(self,position,target)
        local bestDirection=toRef(self,position,target)
        for i,portal in ipairs(Portal.objects) do
            ---@cast portal Portal
            local pos1,pos2=portal.pos1,portal.pos2
            local posIn=geo:nearestToLine(position,pos1,pos2)
            local sizeIn=portal.size
            local linkedPortal=portal.linked
            local linkedSize=linkedPortal.size
            local pos3,pos4=linkedPortal.pos1,linkedPortal.pos2
            local posOut=geo:nearestToLine(target,pos3,pos4)
            local distanceIn=geo:distanceRef(position,posIn)
            local distanceOut=geo:distanceRef(posOut,target)
            if distanceIn+distanceOut>bestDistance then
                goto continue
            end
            local ratioIn=geo:distanceRef(pos1,posIn)/sizeIn
            local ratioOut=geo:distanceRef(pos3,posOut)/linkedSize
            local ratio=math.interpolate(ratioIn,ratioOut,distanceOut/(distanceIn+distanceOut))
            if ratio<0 or ratio>1 then
                ratio=math.clamp(ratio,0,1)
            end
            local posIn2=geo:rThetaGoRef(pos1,sizeIn*ratio,geo:toRef(pos1,pos2))
            local posOut2=geo:rThetaGoRef(pos3,linkedSize*ratio,geo:toRef(pos3,pos4))
            local totalDistance=geo:distanceRef(position,posIn2)+geo:distanceRef(posOut2,target)
            if totalDistance<bestDistance then
                bestDistance=totalDistance
                bestDirection=geo:toRef(position,posIn2)
            end
            ::continue::
        end
        return bestDistance,bestDirection
    end
    local distance=function(self,position1,position2)
        local distance,direction=geo:rThetaTo(position1,position2)
        return distance
    end
    local to=function(self,position,target)
        local distance,direction=geo:rThetaTo(position,target)
        return direction
    end
    geo.enterPhase=function(self,phase)
        if phase=='update' then
            self.rThetaGo=rThetaGo
            self.to=to
            self.distance=distance
            self.rThetaTo=rThetaTo
        elseif phase=='draw' then
            self.rThetaGo=rThetaGoRef
            self.to=toRef
            self.distance=distanceRef
            self.rThetaTo=rThetaToRef
        end
    end
end

---@type OneStageDataRaw
return{
    init=function()
        if G.runInfo.geometry==G.geometries.Euclidean then
            injectGeometry()
            local base=G.runInfo.geometry:init()
            local portals={}
            local r=350
            for i=1,4 do
                local posc,dirc=G.runInfo.geometry:rThetaGo(base.pos,r,i*math.pi/2)
                local pos1=G.runInfo.geometry:rThetaGo(posc,r*3,dirc+math.pi/2)
                local pos2=G.runInfo.geometry:rThetaGo(posc,r*3,dirc-math.pi/2)
                if i>2 then
                    pos1,pos2=pos2,pos1
                end
                local portal=Portal(pos1,pos2,base.pos,{draw=false,range=999})
                table.insert(portals,portal)
            end
            portals[1]:link(portals[3])
            portals[2]:link(portals[4])
            -- local border=Border.CircleBorder{center=base.pos,radius=400}
            -- G.runInfo.player.border=border
            -- G:replaceBackgroundPatternIfNot(BackgroundPattern.Corridor)
        end
        BGM:play('level3',true)
        DynamicUIObjs.showSoundtrack()
    end,
    segments={
        {
            key='4-1',
            type='midStage',
            func=function() -- 20s. midboss should appear at 52.5s
                local geo=G.runInfo.geometry
                ---@cast geo PortalGeometryBase
                local pos0=geo:init().pos
                local pos1,dir1=geo:rThetaGo(pos0,200,-math.pi/2)
                local pos2,dir2=geo:rThetaGo(pos1,-400,dir1+math.pi/2)
                local pos3,dir3=geo:rThetaGo(pos1,-400,dir1-math.pi/2)
                local types={'dot','round','bigRound','giant'}
                local rand=math.eval(50,39)
                for i=1,20 do
                    local type=types[(i-1)%#types+1]
                    local dir=math.pseudoRandom(math.ceil(i/#types))*math.pi*2*rand
                    local fairy=Enemy{kinematicState=copyTable{pos=pos2,dir=dir2,speed=180},maxhp=15,sprite=Asset.fairySprites.small.purple,lifeFrame=300,extraUpdate={Enemy.presetActions.fadeAndHint},dropItems={powerSmall=1}}
                    local fairy2=Enemy{kinematicState=copyTable{pos=pos3,dir=dir3,speed=180},maxhp=15,sprite=Asset.fairySprites.small.orange,lifeFrame=300,extraUpdate={Enemy.presetActions.fadeAndHint},dropItems={point=1}}
                    local period=DSWITCH{120,100,90,80}
                    local bulletNumber=DSWITCH{1,2,3,3}
                    BulletSpawner{
                        period=period,firstPeriod=i+30,lifeFrame=270,bulletSpeed=150,bulletNumber=bulletNumber,angle=dir,range=math.pi*2,bulletSprite=BulletSprites[type].purple,bulletLifeFrame=600,bulletExtraUpdate={Action.ZoomIn(30),Action.FadeOut(30,true)},highlight=true,
                    }:bindState(fairy)
                    BulletSpawner{
                        period=period,firstPeriod=i+30,lifeFrame=270,bulletSpeed=150,bulletNumber=bulletNumber,angle=dir,range=math.pi*2,bulletSprite=BulletSprites[type].orange,bulletLifeFrame=600,bulletExtraUpdate={Action.ZoomIn(30),Action.FadeOut(30,true)},highlight=true,
                    }:bindState(fairy2)
                    wait(10)
                end
                wait(180)
                local sign=DSWITCH{1,1,-1,-1}
                for i=1,20 do
                    local fairy=Enemy{kinematicState=copyTable{pos=pos2,dir=dir2,speed=180},maxhp=15,sprite=Asset.fairySprites.small.red,lifeFrame=300,extraUpdate={Enemy.presetActions.fadeAndHint},dropItems={powerSmall=1}}
                    local fairy2=Enemy{kinematicState=copyTable{pos=pos3,dir=dir3,speed=180},maxhp=15,sprite=Asset.fairySprites.small.blue,lifeFrame=300,extraUpdate={Enemy.presetActions.fadeAndHint},dropItems={point=1}}
                    if i%DSWITCH{5,4,3,3}==0 then
                        BulletSpawner{
                            period=DSWITCH{12,6,6,6},firstPeriod=i*3%30+30,lifeFrame=270,bulletSpeed=150,bulletNumber=3,angle=dir2+math.pi/2*sign,range=math.pi/4,bulletSprite=BulletSprites.round.red,bulletLifeFrame=600,bulletExtraUpdate={Action.FadeOut(30,true)}
                        }:bindState(fairy)
                        BulletSpawner{
                            period=DSWITCH{12,6,6,6},firstPeriod=i*3%30+30,lifeFrame=270,bulletSpeed=150,bulletNumber=3,angle=dir3-math.pi/2*sign,range=math.pi/4,bulletSprite=BulletSprites.round.blue,bulletLifeFrame=600,bulletExtraUpdate={Action.FadeOut(30,true)}
                        }:bindState(fairy2)
                    end
                    wait(10)
                end
                wait(200)
                DynamicUIObjs.showStageTitle('stage4')
                wait(420)
            end
        },
        {
            key='4-2',
            type='midStage',
            func=function() -- 20s
                local geo=G.runInfo.geometry
                ---@cast geo PortalGeometryBase
                local pos0=geo:init().pos
                local pos1,dir1=geo:rThetaGo(pos0,200,-math.pi/2)
                local pos2,dir2=geo:rThetaGo(pos1,-175,dir1+math.pi/2)
                local pos3,dir3=geo:rThetaGo(pos1,-175,dir1-math.pi/2)
                local poses={pos2,pos3}
                Event{action=function()
                    for i,pos in ipairs(poses) do
                        local warning=Bullet{kinematicState={pos=copyTable(pos),speed=0,dir=0},sprite=BulletSprites.giant.red,lifeFrame=120,invincible=true,safe=true,spriteColor={1,0,0,0.5},extraUpdate={Action.FadeIn(30,false),Action.FadeOut(30,false)},size=4}
                        wait(120)
                    end
                end}
                local layer3Update=function(self)
                    if self.frame%20==0 then
                        self.grazed=false
                    end
                end
                local function circledFairy(fairy,layer,color)
                    local sprites={'rim','ellipse','lightRound'}
                    for i=1,layer do
                        local randDir=math.eval(0,99)
                        local r=120*(i-1)+DSWITCH{10,20,30,30}
                        local n=math.ceil(r/5)+DSWITCH{6,4,6,14}
                        for j=1,n do
                            local angle=j/n*math.pi*2
                            local bullet=Bullet{kinematicState={pos=copyTable(fairy.kinematicState.pos),speed=150,dir=angle},sprite=BulletSprites[sprites[i]][color],lifeFrame=fairy.lifeFrame,extraUpdate={Action.ZoomIn(30),Action.FadeOut(30,true),i==3 and layer3Update or nil},highlight=true,invincible=true,spriteTransparency=i<=2 and 0.3 or 1,safe=i<=2}
                            DanmakuFuncs.orbitBind(bullet,fairy,function (self, centerObj)
                                local r1=r*(math.smoothstep(self.frame/r/2+0.5)*2-1)
                                local theta=angle+self.frame/r*3
                                if layer==1 then
                                    r1,theta=math.polygonize(4,theta,r1,self.frame/r*3)
                                end
                                return {r=r1,theta=theta}
                            end,function(self)
                                self.spriteTransparency=1
                                self.safe=false
                                if i~=layer then
                                    -- self.kinematicState.dir=randDir
                                    self.lifeFrame=self.frame+120
                                else
                                    if not self.centerObj.flag then
                                        self.kinematicState.dir=fairy.kinematicState.dir
                                    end
                                end
                            end)
                        end
                    end
                end
                local function wave(num,n,hp,c,pos,life)
                    Event{action=function()
                        local fairyTypes={'small','medium','large'}
                        local fairyType=fairyTypes[n]
                        local randDir=math.eval(0,99)
                        local t=0
                        local sfx=n==3 and 'enemyPowerfulShot' or 'enemyShot'
                        local sentry
                        if n==1 then
                            sentry=pos
                            pos=sentry.kinematicState.pos
                        end
                        for i=1,num do
                            SFX:play(sfx)
                            local ddir=math.pi*2/num*i
                            local fairy=Enemy{kinematicState=copyTable{pos=pos,dir=dir2+ddir+randDir,speed=100},maxhp=hp,sprite=Asset.fairySprites[fairyType][c],lifeFrame=life-t,extraUpdate={Enemy.presetActions.fadeAndHint},dropItems={powerSmall=n*5-3}}
                            circledFairy(fairy,n,c)
                            if n==3 then
                                local sentry=DanmakuFuncs.sentry(pos)
                                sentry.kinematicState.dir=fairy.kinematicState.dir
                                sentry.kinematicState.speed=fairy.kinematicState.speed
                                fairy:addHPProtection(240,5)
                                wait(300)
                                wave(10,1,20,c,sentry,life-300)
                            else
                                fairy:addHPProtection(120,5)
                                DanmakuFuncs.orbitBind(fairy,sentry,function (self, centerObj)
                                    local r=200*math.sigmoid(self.frame/30)
                                    return {r=r,theta=centerObj.frame/60+ddir}
                                end)
                                if DIFF()==G.LUNATIC and n==1 then
                                    fairy.lifeFrame=fairy.lifeFrame-120
                                    Event{action=function()
                                        wait(fairy.lifeFrame-1)
                                        if not fairy.removed then
                                            fairy.flag=true
                                            SFX:play('enemyPowerfulShot')
                                        end
                                    end}
                                end
                            end
                            wait(15)
                            t=t+15
                        end
                    end}
                end
                wait(120)
                wave(1,3,300,'red',pos2,900)
                wait(120)
                wave(1,3,300,'blue',pos3,780)
                wait(300)
                wait(660)
            end
        }
    }
}
