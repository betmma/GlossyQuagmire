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
        local skip=kinematicState.skipPortal
        local zoomFromPortal=Portal.zoomFactor(kinematicState.pos)
        updateRef(self,kinematicState,dt*zoomFromPortal)
        if skip then return end
        local pos,delta,teleportedPortal=Portal.considerTeleport(kinematicState.pos)
        kinematicState.pos=pos
        kinematicState.dir=kinematicState.dir+delta
        kinematicState.teleportedPortal=teleportedPortal
    end
    local rThetaGoRef=geo.rThetaGo
    geo.rThetaGoRef=rThetaGoRef
    local rThetaGo=function(self,position,length,direction)
        if length==0 then
            return copyTable(position),direction
        end
        local segment=math.ceil(math.abs(length)/Portal.getMinimumRange())
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
    Portal.enableShader(geo)
end

-- player can escape two portals forming an angle by moving towards the vertex, due to the point on exterior angle bisector does not fall into either portal's teleportation range. the fix is to extend portals past the vertex.

local portalR=350
local outerPortals={}
local basePos
local function outerPortalPoses(basePos)
    local geo=G.runInfo.geometry
    ---@cast geo PortalGeometryBase
    local poses={}
    for i=1,4 do
        local posc,dirc=geo:rThetaGoRef(basePos,portalR,i*math.pi/2+G.runInfo.player.viewDirection)
        local pos1=geo:rThetaGoRef(posc,portalR*3,dirc+math.pi/2)
        local pos2=geo:rThetaGoRef(posc,portalR*3,dirc-math.pi/2)
        if i>2 then
            pos1,pos2=pos2,pos1
        end
        table.insert(poses,{pos1=pos1,pos2=pos2})
    end
    return poses
end
local function setOuterPortals(newBasePos,newPortalR)
    if newPortalR then
        portalR=newPortalR
    end
    basePos=copyTable(newBasePos)
    local poses=outerPortalPoses(newBasePos)
    if #outerPortals==0 then
        for i=1,4 do
            local pos1,pos2=poses[i].pos1,poses[i].pos2
            local portal=Portal(pos1,pos2,newBasePos,{draw=false,range=999})
            table.insert(outerPortals,portal)
        end
        outerPortals[1]:link(outerPortals[3])
        outerPortals[2]:link(outerPortals[4])
    else
        for i=1,4 do
            local pos1,pos2=poses[i].pos1,poses[i].pos2
            outerPortals[i]:set(pos1,pos2,newBasePos)
        end
    end
    return outerPortals
end
Portal.setOuterPortals=setOuterPortals

local shouji=require"stages.stage4.shouji"

---@type OneStageDataRaw
return{
    init=function()
        outerPortals={}
        G:replaceBackgroundPatternIfNot(BackgroundPattern.Stage4Rooms)
        G.backgroundPattern:setRoomChanges(0,1)
        if G.runInfo.geometry==G.geometries.Euclidean then
            injectGeometry()
            local base=G.runInfo.geometry:init()
            setOuterPortals(base.pos,350)
            -- local border=Border.CircleBorder{center=base.pos,radius=400}
            -- G.runInfo.player.border=border
            -- G:replaceBackgroundPatternIfNot(BackgroundPattern.Corridor)
        end
        BGM:play('level4',true)
        DynamicUIObjs.showSoundtrack()
    end,
    segments={
        {
            key='4-1',
            type='midStage',
            init=function()
                G.backgroundPattern:setRoomChanges(0,1)
            end,
            func=function() -- 20s. midboss should appear at 52.2s
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
            init=function()
                G.backgroundPattern:setRoomChanges(math.pi/12,1)
            end,
            func=function() -- 19.15s
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
                wait(819)
                wait(90)
            end
        },
        {
            key='4-3',
            type='midStage',
            init=function()
                G.backgroundPattern:setRoomChanges(math.pi/12,4)
            end,
            func=function() -- 12.05s
                -- BGM.data[BGM.currentAudio]:seek(39.15,'seconds')
                local geo=G.runInfo.geometry
                ---@cast geo PortalGeometryBase
                local pos=G.runInfo.player.kinematicState.pos
                pos=geo:rThetaGo(pos,100,math.eval(0,99))
                setOuterPortals(pos) -- so the shrouding bullets are ensured to not touch portals
                local sentry=DanmakuFuncs.sentry(pos)
                --- shrouding bullets
                local r0={r=400,size=1}
                local function shrinkR(delta,duration)
                    SFX:play('hit2',true,2)
                    r0.size=1.5
                    Event.EaseEvent{duration=duration,obj=sentry,easeObj=r0,aims={r=r0.r-delta,size=1},progressFunc=Event.sineOProgressFunc}
                end
                local rthetaf=function (self, centerObj, dir)
                    local r=r0.r
                    local theta=dir
                    local t=centerObj.frame
                    if t>90 then
                        theta=theta+math.smoothstep((t-90)/30)*(t-90)/300
                    end
                    r,theta=math.polygonize(4,theta,r,math.pi/4)
                    return r,theta
                end
                Event{action=function()
                    for j=1,4 do
                        SFX:play('hit2',true,2)
                        for i=j,200,4 do
                            local dir=math.pi*2*i/200
                            local pos1,dir1=geo:rThetaGo(pos,r0.r,dir)
                            local bullet=Bullet{kinematicState={pos=pos1,speed=0,dir=dir1},sprite=BulletSprites.kunaiDark.red,lifeFrame=820-18*(j-1),extraUpdate={Action.ZoomIn(30),Action.FadeIn(20,true),Action.FadeOut(30,true),function(self)
                                local r,theta=rthetaf(self,sentry,dir)
                                self.kinematicState.pos,self.kinematicState.dir=geo:rThetaGoRef(sentry.kinematicState.pos,r,theta)
                                self.kinematicState.dir=self.kinematicState.dir+math.pi
                                self.size=r0.size
                                if self.frame%261==99 then -- every 11, 12, 13, 14th beat
                                    if i<5 then
                                        SFX:play('enemyShot',true)
                                    end
                                    if math.ceil(i/4)%DSWITCH{7,5,3,2}==0 then 
                                        Bullet{kinematicState={pos=copyTable(self.kinematicState.pos),speed=150,dir=self.kinematicState.dir},sprite=BulletSprites.kunai.red,lifeFrame=r*60/150+30,extraUpdate={Action.ZoomIn(30),Action.FadeOut(30,true)}}
                                    end
                                end
                            end},invincible=true,size=1}
                        end
                        wait(18)
                    end
                    wait(9)
                end}
                Event{action=function()
                    wait(171) -- 42s, at 9+19/29 bar
                    for i=1,3 do
                        shrinkR(50,25)
                        wait(27) -- 27 frames = 0.45s = 3/29 bars
                    end
                    wait(9)
                    -- portals appear
                    local dir=geo:to(sentry.kinematicState.pos,G.runInfo.player.kinematicState.pos)+math.pi/4
                    dir=dir-dir%(math.pi/2)
                    local color={1,0.5,0.5,1}
                    local function segment(pos,dir,len)
                        return geo:rThetaGoRef(pos,len,dir+math.pi/2),geo:rThetaGoRef(pos,len,dir-math.pi/2)
                    end
                    local t=54
                    local l={l=0.1}
                    local deltal=0.3
                    local posm,dirm=geo:rThetaGoRef(sentry.kinematicState.pos,-150,dir)
                    local args={}
                    local portals={}
                    local portalArgs={draw=true,color={0,0,0,0},range=50}
                    for i=1,4 do
                        local diri=dirm+(i-1)*math.pi/2
                        local dist=i%2==1 and 100 or 55
                        local length=i%2==1 and 50 or 105
                        local posi,diri2=geo:rThetaGoRef(posm,dist,diri)
                        if i>2 then
                            diri2=diri2+math.pi
                        end
                        local posOut=geo:rThetaGoRef(posm,dist+30,diri)
                        if i%2==0 then
                            for j=-10,10 do
                                local pos,dir=geo:rThetaGoRef(posi,length*j/10,diri2+math.pi/2)
                                Bullet{kinematicState={pos=pos,speed=0,dir=dir},sprite=BulletSprites.kunaiDark.green,lifeFrame=400,extraUpdate={Action.ZoomIn(30),Action.FadeIn(20,false),Action.ZoomOut(30)},invincible=true,size=1,}
                            end
                        else
                            local pos1,pos2=segment(posi,diri2,length*0.1)
                            table.insert(args,{posi,diri2,length})
                            table.insert(portals,Portal(pos1,pos2,posOut,portalArgs))
                        end
                    end
                    portals[1]:link(portals[2])
                    -- portals[2]:link(portals[4])
                    for j=1,t do
                        if j%18==1 then
                            SFX:play('hit2',true,2)
                            Event.EaseEvent{duration=17,obj=sentry,easeObj=l,aims={l=l.l+deltal},progressFunc=Event.sineOProgressFunc}
                        end
                        for i,portal in ipairs(portals) do
                            local pos1,pos2=segment(args[i][1],args[i][2],args[i][3]*l.l)
                            local colori={color[1],color[2],color[3],j/t}
                            portal:set(pos1,pos2)
                            portal.args.color=colori
                        end
                        wait()
                    end
                    wait(27)
                    -- hint arrow
                    local function arrow(pos,size,num,dir,part,args)
                        part=part or 0
                        if part==0 or part==1 then
                            for i=-num,num do
                                local pos,dir=geo:rThetaGoRef(pos,size*i,dir)
                                Bullet(table.update(args,{kinematicState={pos=pos,speed=0,dir=dir}}))
                            end
                        end
                        local posHead,dirHead=geo:rThetaGoRef(pos,size*num,dir)
                        local side2part={[-1]=2,[1]=3}
                        for side=-1,1,2 do
                            if part==0 or part==side2part[side] then
                                local dir2=dirHead+side*math.pi/4+math.pi
                                for i=1,num do
                                    local pos,dir=geo:rThetaGoRef(posHead,i*size,dir2)
                                    Bullet(table.update(args,{kinematicState={pos=pos,speed=0,dir=dir}}))
                                end
                            end
                        end
                    end
                    local size,num=8,5
                    local arrowArgs={sprite=BulletSprites.rimDark.green,lifeFrame=320,extraUpdate={Action.ZoomIn(20),Action.FadeIn(20,false,0.4),Action.FadeOut(30,false)},invincible=true,safe=true,spriteTransparency=0.4}
                    local arrowDir=dir+math.pi
                    for i=1,3 do
                        SFX:play('hit2',true,2)
                        arrow(sentry.kinematicState.pos,size,num,arrowDir,i,arrowArgs)
                        wait(9)
                        arrowArgs.lifeFrame=arrowArgs.lifeFrame-9
                    end
                    local arrow2Pos,arrow2Dir=geo:rThetaGoRef(sentry.kinematicState.pos,400,arrowDir)
                    wait(9)
                    arrowArgs.lifeFrame=arrowArgs.lifeFrame-9
                    for i=1,3 do
                        SFX:play('hit2',true,2)
                        arrow(arrow2Pos,size,num,arrow2Dir,i,arrowArgs)
                        wait(18)
                        arrowArgs.lifeFrame=arrowArgs.lifeFrame-18
                    end
                    for i=1,3 do
                        shrinkR(15,25)
                        wait(27)
                    end
                    wait(9) -- end of 11th bar
                    for i=1,4 do
                        SFX:play('hit2',true,2)
                        shrinkR(10,17)
                        wait(18)
                    end
                    wait(9)
                    t=27
                    for j=1,t do
                        if j%9==1 then
                            SFX:play('hit2',true,2)
                            Event.EaseEvent{duration=7,obj=sentry,easeObj=l,aims={l=l.l-deltal},progressFunc=Event.sineOProgressFunc}
                        end
                        for i,portal in ipairs(portals) do
                            local pos1,pos2=segment(args[i][1],args[i][2],args[i][3]*l.l)
                            local colori={color[1],color[2],color[3],1-j/t}
                            portal:set(pos1,pos2)
                            portal.args.color=colori
                        end
                        wait()
                    end
                    for i,portal in ipairs(portals) do
                        portal:remove()
                    end
                    wait(9)
                    for i=1,3 do
                        shrinkR(i*20,17)
                        wait(18)
                    end
                end}
                wait(723)
            end
        },
        shouji.midboss,
        {
            key='4-4',
            type='midStage',
            init=function()
                G.backgroundPattern:setRoomChanges(math.pi/12,4)
                G.backgroundPattern:setProjectionMode(true)
                local pos=G.runInfo.player.kinematicState.pos
                portalR=200
                setOuterPortals(pos)
                outerPortals[1]:link(outerPortals[4])
                outerPortals[2]:link(outerPortals[3])
            end,
            func=function() -- 15s
            -- wait(999999)
                local geo=G.runInfo.geometry
                ---@cast geo PortalGeometryBase
                local pos=G.runInfo.player.kinematicState.pos
                local pos1,dir1=geo:rThetaGo(pos,50,-math.pi/2)
                local pos2,dir2=geo:rThetaGo(pos1,-350,dir1-math.pi/2)
                local extraUpdate=function(self)
                    local aimSpeed=150
                    if self.frame+60>self.lifeFrame then
                        aimSpeed=0
                    end
                    self.kinematicState.speed=math.lerp(self.kinematicState.speed,aimSpeed,0.05)
                end
                local n=DSWITCH{3,3,4,5}
                local bulletNumber=DSWITCH{4,6,8,12}
                for i=-(n-1),n do
                    local pos2,dir2=geo:rThetaGo(pos1,-40*i+20,dir1-math.pi/2)
                    local fairy=Enemy{kinematicState=copyTable{pos=pos2,dir=dir2+math.pi/2,speed=0},maxhp=200,sprite=Asset.fairySprites.medium.blue,lifeFrame=500,extraUpdate={Enemy.presetActions.fadeAndHint,function (self)
                        self.kinematicState.speed=math.lerp(self.kinematicState.speed,150,0.04)
                    end},dropItems={powerSmall=3,point=3}}
                    fairy:addHPProtection(120,5)
                    local BulletSpawner=BulletSpawner{useRelativeAngle=true,period=72,firstPeriod=90,lifeFrame=430,bulletSpeed=250,bulletNumber=bulletNumber,angle=dir2+math.pi/2,range=math.pi*bulletNumber,bulletSprite=BulletSprites.scale.blue,bulletLifeFrame=300,bulletExtraUpdate={Action.ZoomOut(30),Action.FadeOut(30,true),extraUpdate},highlight=true,bulletEvents={function(cir,args,self)
                        cir.index=self.spawnTimes
                        cir.kinematicState.speed=cir.kinematicState.speed-args.index*20
                        -- cir.kinematicState.dir=cir.kinematicState.dir+(math.abs(cir.index%10-5))*0.01
                    end}}
                    BulletSpawner:bindState(fairy)
                    -- wait(10)
                end
                wait(120)
                for i=-(n-1),n do
                    local skipCondition
                    if DIFF()>=G.HARD then
                        skipCondition=math.abs(i-0.5)<3
                    else
                        skipCondition=math.abs(i-0.5)>1
                    end
                    if skipCondition then
                        goto continue
                    end
                    local pos2,dir2=geo:rThetaGo(pos1,-40*i+20,dir1-math.pi/2)
                    local fairy=Enemy{kinematicState=copyTable{pos=pos2,dir=dir2+math.pi/2,speed=150},maxhp=200,sprite=Asset.fairySprites.medium.orange,lifeFrame=500,extraUpdate={Enemy.presetActions.fadeAndHint},dropItems={powerSmall=3,point=3}}
                    fairy:addHPProtection(120,5)
                    local BulletSpawner=BulletSpawner{period=96,firstPeriod=90,lifeFrame=430,bulletSpeed=50,bulletNumber=bulletNumber,angle='player',range=math.pi*bulletNumber,bulletSprite=BulletSprites.flame.red,bulletLifeFrame=300,bulletExtraUpdate={Action.FadeOut(30,true),extraUpdate},highlight=true,bulletEvents={function(cir,args,self)
                        cir.index=self.spawnTimes
                        cir.kinematicState.speed=cir.kinematicState.speed-args.index*20
                        cir.kinematicState.dir=cir.kinematicState.dir+math.pi/2
                    end}}
                    BulletSpawner:bindState(fairy)
                    -- wait(60)
                    ::continue::
                end
                wait(780)
            end
        },
        {
            key='4-5',
            type='midStage',
            func=function() -- 18s
                local geo=G.runInfo.geometry
                ---@cast geo PortalGeometryBase
                local pos=basePos
                local function extraUpdate(self)
                    if self.frame>=60 and self.frame<150 then
                        self.kinematicState.speed=self.kinematicState.speed+1.5
                    end
                    if self.frame+90>self.lifeFrame then
                        self.kinematicState.speed=math.lerp(self.kinematicState.speed,0,0.05)
                    end
                end
                local count=0
                local function stretch(pos)
                    count=count+1
                    BulletSpawner{kinematicState={pos=copyTable(pos),speed=0,dir=0},period=999,firstPeriod=1,lifeFrame=2,bulletSpeed=count*10-50,bulletNumber=100,angle='player',range=math.pi*2,bulletSprite=BulletSprites.bullet.green,bulletLifeFrame=240,bulletExtraUpdate={Action.FadeOut(20,true),extraUpdate}}
                end
                local time=720
                local function spawnFairy(pos)
                    local fairy=Enemy{kinematicState=copyTable{pos=pos,dir=0,speed=0},maxhp=200,sprite=Asset.fairySprites.large.green,lifeFrame=time,extraUpdate={Enemy.presetActions.fadeAndHint},dropItems={powerSmall=5,point=5}}
                    fairy:addHPProtection(60,99)
                    Event{obj=fairy,action=function()
                        wait(time-30)
                        SFX:play('enemyPowerfulShot')
                        stretch(fairy.kinematicState.pos)
                        fairy:addHPProtection(120,9999)
                    end}
                    fairy.dieEffect=function (self)
                        Enemy.dieEffect(self)
                        SFX:play('enemyPowerfulShot')
                        stretch(self.kinematicState.pos)
                    end
                    return fairy
                end
                local sentry=DanmakuFuncs.sentry(pos)
                local thetaFunc=function(frame)
                    local x=frame/60
                    local theta=(x+math.exp(-x)-1)
                    return theta
                end
                for i=1,8 do
                    local pos1,dir1=geo:rThetaGo(pos,100,math.pi*2*i/8)
                    local fairy=spawnFairy(pos1)
                    DanmakuFuncs.orbitBind(fairy,sentry,function (self, centerObj)
                        local r=100
                        local theta=thetaFunc(centerObj.frame)+math.pi*2*i/8
                        return {r=r,theta=theta}
                    end)
                    --- hakke spawners
                    local hakkes={4,5,6,7,3,2,1,0}
                    local hakke=hakkes[i]
                    for j=1,3 do -- inner to outer
                        local value=bit.rshift(hakke,3-j)%2
                        local bulletNumber=value==0 and 6 or 9
                        local speedUnit=20
                        local BulletSpawner=BulletSpawner{period=240,firstPeriod=120-i*10,lifeFrame=time,bulletSpeed=speedUnit*5,bulletNumber=bulletNumber,angle=-value*math.pi/2,useRelativeAngle=true,range=math.pi*bulletNumber,bulletSprite=BulletSprites.bill[value==0 and 'white' or 'black'],bulletLifeFrame=300,bulletExtraUpdate={Action.FadeOut(30,true)},bulletEvents={function(cir,args,self)
                            local index=args.index
                            local side=math.mod2Sign(index)
                            local n=math.ceil(index/2)
                            cir.kinematicState.speed=cir.kinematicState.speed-n*speedUnit
                            cir.spriteTransparency=0.5
                            cir.safe=true
                            Event{obj=cir,action=function()
                                wait(25)
                                cir.kinematicState.speed=0
                                wait(30)
                                cir.spriteTransparency=1
                                cir.safe=false
                                cir.kinematicState.dir=cir.kinematicState.dir-side*math.pi/2
                                cir.kinematicState.speed=50
                                for i=1,60 do
                                    cir.kinematicState.speed=cir.kinematicState.speed+1
                                    wait()
                                end
                            end}
                        end}}
                        local spawnerSentry=DanmakuFuncs.sentry(pos1)
                        BulletSpawner:bindState(spawnerSentry)
                        DanmakuFuncs.orbitBind(spawnerSentry,sentry,function (self, centerObj)
                            local r=100+(j-2)*20
                            local theta=thetaFunc(centerObj.frame)+math.pi*2*i/8
                            return {r=r,theta=theta}
                        end)
                    end
                    wait(10)
                end
                wait(1000)
            end
        },
        shouji.boss
    }
}
