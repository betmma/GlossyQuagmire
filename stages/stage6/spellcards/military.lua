---@return SpellcardPhase
return BossManager.SpellcardPhase{
    key='enri-military',
    bonusScore=50000,
    time=3600,
    hp=40000,
    dropItems={powerSmall=30,point=15},
    func=function(self, boss)
        boss:addHPProtection(600,10)
        local geo=G.runInfo.geometry
        ---@cast geo Spherical
        local radius=geo.radius
        ---@cast geo GeometryBase
        local player=G.runInfo.player
        local playerPos=copyTable(player.kinematicState.pos)
        local antipode=geo:rThetaGo(playerPos,radius*math.pi,0)
        DanmakuFuncs.moveToInTime(boss,antipode,60)
        local r0,re,r1=150,100,50
        local minPathLength=30
        local nodes={{pos=playerPos,radius=r0},{pos=antipode,radius=re}}
        local playerNode=nodes[1]
        local enemyNode=nodes[2]
        local paths={}
        local playerPathCount=DSWITCH{3,3,4,4,5}
        local enemyPathCount=3
        -- only paths that have at least one random generated node as vertex could be controllable
        local rdNodePaths={}
        local function addNode(pos)
            table.insert(nodes,{pos=pos,radius=r1})
            return #nodes
        end
        local function addPath(i,j)
            if not paths[i] then
                paths[i]={}
            end
            for _,to in ipairs(paths[i]) do
                if to==j then -- has been added
                    return
                end
            end
            if not paths[j] then
                paths[j]={}
            end
            if i>2+playerPathCount+enemyPathCount or j>2+playerPathCount+enemyPathCount then
                table.insert(rdNodePaths,{math.min(i,j),math.max(i,j)})
            end
            table.insert(paths[i],j)
            table.insert(paths[j],i)
        end
        local function pathCrossCheck(i,j)
            local posi=nodes[i].pos
            local posj=nodes[j].pos
            local lenij=geo:distance(posi,posj)
            for x=1,#nodes do
                if paths[x] then
                    local posx=nodes[x].pos
                    for _,y in ipairs(paths[x]) do
                        local posy=nodes[y].pos
                        -- print(pprint(posi),pprint(posj),pprint(posx),pprint(posy))
                        -- test cross: 2 points of both segment are at different side of the other segment. excluding sharing a vertex, and excluding distance of posi and posx greater then sum of lengths (two antipodar-ish segments can be considered cross with the different side test)
                        if not (i==x or i==y or j==x or j==y) and (geo:sideToLine(posi,posx,posy)~=geo:sideToLine(posj,posx,posy) and geo:sideToLine(posx,posi,posj)~=geo:sideToLine(posy,posi,posj)) and not (geo:distance(posi,posx)>geo:distance(posx,posy)+lenij) then
                            return false
                        end
                    end
                end
            end
            return true
        end
        -- determines the width of path. since paths take up arc of connected nodes and they cannot overlap, it affects how many paths can a node have
        local pathHalfWidth=20
        -- check if an angle falls in the paths connected to node i. if anotherPath is true, it considers if a new path collides with existing paths by doubling pathHalfAngle.
        local function pathAngleCheck(i,angle,anotherPath)
            local node=nodes[i]
            local pos,size=node.pos,node.radius
            local pathHalfAngle=math.asin(math.sin(pathHalfWidth/radius)/math.sin(size/radius))*(anotherPath and 2 or 1)
            local pathAngles={}
            if paths[i] then
                for j,toIndex in ipairs(paths[i]) do
                    local posTo=nodes[toIndex].pos
                    local to=geo:to(pos,posTo)
                    table.insert(pathAngles,to)
                end
            end
            for _,pathAngle in ipairs(pathAngles) do
                pathAngle=math.modClamp(pathAngle,angle)
                if angle>pathAngle-pathHalfAngle and angle<pathAngle+pathHalfAngle then
                    return false
                end
            end
            return true
        end
        local function newPathCheck(i,j)
            local posi=nodes[i].pos
            local posj=nodes[j].pos
            return pathCrossCheck(i,j) and pathAngleCheck(i,geo:to(posi,posj),true) and pathAngleCheck(j,geo:to(posj,posi),true)
        end
        -- generate equally distributed paths from player node
        for i=1,playerPathCount do
            local angle=math.pi*2/playerPathCount*i
            local distance=math.eval(r0+r1+minPathLength+25,25)
            local pos=geo:rThetaGo(playerNode.pos,distance,angle)
            addPath(1,addNode(pos))
        end
        for i=1,enemyPathCount do
            local angle=math.pi*2/enemyPathCount*i
            local distance=math.eval(re+r1+minPathLength+25,25)
            local pos=geo:rThetaGo(enemyNode.pos,distance,angle)
            addPath(2,addNode(pos))
        end
        -- some random nodes
        local rdn=DSWITCH{5,5,6,7}
        for i=1,rdn do
            local try=0
            while try<50 do
                try=try+1
                local minr=r0+r1+minPathLength
                local maxr=radius*math.pi-re-r1-minPathLength
                local r=math.eval((minr+maxr)/2,(maxr-minr)/2)
                local angle=math.eval(math.pi*2/rdn*i,math.pi/50*try)
                local pos=geo:rThetaGo(playerPos,r,angle)
                -- at least 2*r1+minPathLength away from all nodes (excluding 1 and 2)
                local failed=false
                for index=3,#nodes do
                    local node=nodes[index]
                    local distance=geo:distance(node.pos,pos)
                    if distance<2*r1+minPathLength then
                        failed=true
                        break
                    end
                end
                if not failed then
                    local newIndex=addNode(pos)
                    break
                end
            end
        end
        -- add paths
        for i=3+playerPathCount+enemyPathCount,#nodes do
            local node=nodes[i]
            local pos,size=node.pos,node.radius
            local nearests={}
            local nearestKeep=6
            for index=3,#nodes do
                if index==i then
                    goto continue
                end
                local nodei=nodes[index]
                local distance=geo:distance(nodei.pos,pos)
                if distance<size+nodei.radius+minPathLength then
                    goto continue
                end
                local insertPos=1
                while nearests[insertPos] and distance>nearests[insertPos][1] do
                    insertPos=insertPos+1
                end
                if insertPos<=nearestKeep then
                    table.insert(nearests,insertPos,{distance,index})
                    nearests[nearestKeep]=nil
                end
                ::continue::
            end
            local picked=nearests--math.randomSample(nearests,4)
            for j=1,#picked do
                if newPathCheck(i,picked[j][2]) then
                    addPath(i,picked[j][2])
                end
            end
        end
        -- decide controllable paths
        local controllablePaths=math.randomSample(rdNodePaths,8)
        ---@type table<integer,integer> hashed value to controllableIndex
        local hash2controlIndex={}
        local function hash(i,j)
            return i*(#nodes+1)+j
        end
        for index,value in ipairs(controllablePaths) do
            local i,j=value[1],value[2]
            local val=hash(i,j)
            hash2controlIndex[val]=index
        end
        local controllablePathSprites={BulletSprites.orb.black,BulletSprites.knife.purple,BulletSprites.bigStar.blue,BulletSprites.ellipse.cyan,BulletSprites.heart.green,BulletSprites.butterfly.yellow,BulletSprites.flame.orange,BulletSprites.haniwa.white}
        local controllablePathSpriteSizes={1.05,1.7,1.25,1.45,1.25,1.25,1.45,1.45}
        local controllablePathsOn={}
        -- draw nodes and paths using bullets
        -- nodes
        local gap=30
        local wallExtraUpdate={Action.ZoomIn(20)}
        for i,node in ipairs(nodes) do
            local pos,size=node.pos,node.radius
            local pathHalfAngle=math.asin(math.sin(pathHalfWidth/radius)/math.sin(size/radius))
            local length=radius*math.sin(size/radius)*math.pi*2
            local n=math.ceil(length/gap)
            local pathAngles={}
            if paths[i] then
                for j,toIndex in ipairs(paths[i]) do
                    local posTo=nodes[toIndex].pos
                    local to=geo:to(pos,posTo)
                    table.insert(pathAngles,to)
                end
            end
            for j=1,n do
                local angle=math.pi*2/n*j
                for _,pathAngle in ipairs(pathAngles) do
                    pathAngle=math.modClamp(pathAngle,angle)
                    if angle>pathAngle-pathHalfAngle and angle<pathAngle+pathHalfAngle then
                        goto continue
                    end
                end
                local posj=geo:rThetaGo(pos,size,angle)
                Bullet{kinematicState={pos=posj,dir=0,speed=0},sprite=BulletSprites.bigRound.black,lifeFrame=9999,invincible=true,extraUpdate=wallExtraUpdate,highlight=true,size=1.2}
                ::continue::
            end
        end
        -- paths
        local controllableExtraUpdate={Action.ZoomIn(20),function (self)
            local index=self.any.index
            self.spriteTransparency=math.lerpCondition(self.spriteTransparency,controllablePathsOn[index],1,0,0.2)
        end}
        local function drawPath(pos1,pos2,controllableIndex,isMid)
            local sprite=BulletSprites.bigRound.black
            local highlight=true
            if controllableIndex then
                sprite=controllablePathSprites[controllableIndex]
                highlight=false
            end
            local midPoints,midDirs=DanmakuFuncs.midPoints(pos1,pos2,gap*(controllableIndex and 1.4 or 1))
            for i,pos in ipairs(midPoints) do
                local bullet=Bullet{kinematicState={pos=pos,dir=midDirs[i],speed=0},sprite=sprite,lifeFrame=9999,invincible=true,extraUpdate=(controllableIndex and isMid) and controllableExtraUpdate or wallExtraUpdate,highlight=highlight,size=1.2*(controllableIndex and controllablePathSpriteSizes[controllableIndex] or 1),safe=isMid}
                if controllableIndex then
                    bullet.any={index=controllableIndex}
                end
            end
        end
        for x=1,#nodes do
            if paths[x] then
                local posx,rx=nodes[x].pos,nodes[x].radius
                for _,y in ipairs(paths[x]) do
                    if x>y then
                        goto continue
                    end
                    local posy,ry=nodes[y].pos,nodes[y].radius
                    local pathHalfAngleX=math.asin(math.sin(pathHalfWidth/radius)/math.sin(rx/radius))
                    local pathHalfAngleY=math.asin(math.sin(pathHalfWidth/radius)/math.sin(ry/radius))
                    local x2y=geo:to(posx,posy)
                    local y2x=geo:to(posy,posx)
                    local posx1=geo:rThetaGo(posx,rx,x2y-pathHalfAngleX)
                    local posx2=geo:rThetaGo(posx,rx,x2y+pathHalfAngleX)
                    local posy1=geo:rThetaGo(posy,ry,y2x+pathHalfAngleY)
                    local posy2=geo:rThetaGo(posy,ry,y2x-pathHalfAngleY)
                    local index=hash2controlIndex[hash(x,y)]
                    drawPath(posx1,posy1,index)
                    drawPath(posx2,posy2,index)
                    if index then
                        drawPath(geo:rThetaGo(posx,rx,x2y),geo:rThetaGo(posy,ry,y2x),index,true)
                    end
                    ::continue::
                end
            end
        end
        -- red inner barrier
        local redBarrierHalfWidth=math.pi/5
        local redBarrierAngle=math.eval(0,math.pi)
        local redBarrierSentry=DanmakuFuncs.sentry(playerPos)
        redBarrierSentry.kinematicState.dir=redBarrierAngle
        local redBarrierN=4
        for i=-redBarrierN,redBarrierN do
            local angle=redBarrierHalfWidth/redBarrierN*i
            local r=r0-20
            local bullet=Bullet{sprite=BulletSprites.stone.red,lifeFrame=9999,extraUpdate={Action.ZoomIn(20)},invincible=true}
            DanmakuFuncs.orbitBind(bullet,redBarrierSentry,{r=r,theta=angle})
        end
        -- controllable path button preset
        local function buttonBindExtraUpdate(self)
            self.spriteTransparency=self.any.buttonSentry.on and 0.9 or 0.5
        end
        local function controllablePathButton(pos,dir,r,index)
            local buttonSentry=DanmakuFuncs.sentry(pos)
            buttonSentry.extraUpdate = {function (self)
                local on=geo:distance(player.kinematicState.pos,pos)<r
                controllablePathsOn[index]=on
                self.on=on
            end}
            local buttonBullet=Bullet{kinematicState={pos=pos,dir=dir,speed=0},sprite=BulletSprites.giant[controllablePathSprites[index].data.color],lifeFrame=9999,extraUpdate={buttonBindExtraUpdate},safe=true,size=0.7,highlight=true}
            buttonBullet.any={buttonSentry=buttonSentry}
            local symbolBullet=Bullet{kinematicState={pos=pos,dir=dir,speed=0},sprite=controllablePathSprites[index],lifeFrame=9999,extraUpdate={buttonBindExtraUpdate},safe=true}
            symbolBullet.any={buttonSentry=buttonSentry}
            return buttonSentry
        end
        local playerViewDirection=player.viewDirection
        local rin=75
        local rout=125
        for i=1,#controllablePaths do
            local angle=playerViewDirection-math.pi/2+(i-#controllablePaths/2-0.5)/#controllablePaths*math.pi
            local pos,dir=geo:rThetaGo(playerPos,(rout+rin)/2,angle)
            controllablePathButton(pos,dir,25,i)
        end
        -- buttons to rotate red inner barrier
        for sign=-1,1,2 do
            -- fan shape
            local halfWidth=math.pi/4*7/8
            local angle=math.pi*(sign/4+0.5)+playerViewDirection
            local buttonSentry=DanmakuFuncs.sentry(playerPos)
            buttonSentry.extraUpdate = {function (self)
                local distance=geo:distance(player.kinematicState.pos,playerPos)
                local to=geo:to(playerPos,player.kinematicState.pos)
                self.on=math.angleDiff(to,angle)<halfWidth and rin<distance and distance<rout
                if self.on then
                    redBarrierAngle=redBarrierAngle+0.04*sign
                    redBarrierSentry.kinematicState.dir=redBarrierAngle
                end
            end}
            local function buttonBullet(pos,dir,sprite)
                dir=dir or 0
                sprite=sprite or BulletSprites.round.red
                local bullet=Bullet{kinematicState={pos=pos,dir=dir,speed=0},sprite=sprite,lifeFrame=9999,extraUpdate={buttonBindExtraUpdate},safe=true,invincible=true,highlight=true}
                bullet.any={buttonSentry=buttonSentry}
            end
            -- draw edge
            local nin=3
            for i=-nin,nin do
                local anglei=angle+halfWidth/nin*i
                buttonBullet(geo:rThetaGo(playerPos,rin,anglei))
            end
            local nout=4
            for i=-nout,nout do
                local anglei=angle+halfWidth/nout*i
                buttonBullet(geo:rThetaGo(playerPos,rout,anglei))
            end
            local posin1=geo:rThetaGo(playerPos,rin,angle-halfWidth)
            local posin2=geo:rThetaGo(playerPos,rin,angle+halfWidth)
            local posout1=geo:rThetaGo(playerPos,rout,angle-halfWidth)
            local posout2=geo:rThetaGo(playerPos,rout,angle+halfWidth)
            local midPoints1=DanmakuFuncs.midPoints(posin1,posout1,20)
            for i=2,#midPoints1-1 do
                buttonBullet(midPoints1[i])
            end
            local midPoints2=DanmakuFuncs.midPoints(posin2,posout2,20)
            for i=2,#midPoints2-1 do
                buttonBullet(midPoints2[i])
            end
            -- arrow
            local nmid=3
            for i=-nmid,nmid do
                local anglei=angle+halfWidth/nmid/2*i
                buttonBullet(geo:rThetaGo(playerPos,(rin+rout)/2,anglei),nil,BulletSprites.dot.red)
            end
            -- arrow head
            for i=1,2 do
                local pos1,dir1=geo:rThetaGo(playerPos,(rin+rout)/2+6*i,angle+halfWidth*sign*(1/2-1/nmid/4*i))
                buttonBullet(pos1,nil,BulletSprites.dot.red)
                pos1,dir1=geo:rThetaGo(playerPos,(rin+rout)/2-6*i,angle+halfWidth*sign*(1/2-1/nmid/4*i))
                buttonBullet(pos1,nil,BulletSprites.dot.red)
            end
        end
        wait(60)
        -- enemy unit logic
        local previousFirstMoveTarget
        local leakCount=0
        -- called when a unit arrives at a node. it picks the next node and calls MoveTowardsInTime
        local function unitMove(self,nodeIndex,previousNodeIndex,firstMove)
            local tos=paths[nodeIndex]
            local choices={}
            local pos,r=nodes[nodeIndex].pos,nodes[nodeIndex].radius
            for _,to in ipairs(tos) do
                local node=nodes[to]
                if to==previousNodeIndex or to==previousFirstMoveTarget then -- wont go back, and the group won't choose same first target as previous group
                    goto continue
                end
                local pos2,r2=node.pos,node.radius
                local distance,dir=geo:rThetaTo(pos,pos2)
                local toPlayer=geo:to(pos,playerPos)
                local diff=math.angleDiff(dir,toPlayer)
                if diff<math.pi/2 then -- move towards player, more chance to become a choice
                    table.insert(choices,to)
                    table.insert(choices,to)
                elseif to==1 then -- enters player node, even more chance
                    table.insert(choices,to)
                    table.insert(choices,to)
                    table.insert(choices,to)
                    table.insert(choices,to)
                else
                    table.insert(choices,to)
                end
                ::continue::
            end
            local random=(math.sin(self.any.seed*nodeIndex*previousNodeIndex)*99)%1
            local choice=choices[math.ceil(random*#choices)]
            -- print(#choices,random,choice)
            if not choice then -- if dead end, has to go back
                choice=previousNodeIndex
            end
            if self.any.isLast and firstMove then
                previousFirstMoveTarget=choice
            end
            local node=nodes[choice]
            local pos2,r2=node.pos,node.radius
            local distance=geo:distance(pos,pos2)
            local unitSpeed=self.any.speed
            DanmakuFuncs.moveToInTime(self,pos2,math.ceil(distance/unitSpeed*60))
            self.nodeIndex=nodeIndex
            self.nextNodeIndex=choice
            Event{obj=self,action=function ()
                wait(math.ceil(r/unitSpeed*60))
                self.onPath=true
                wait(math.ceil((distance-r-r2)/unitSpeed*60))
                self.onPath=false
                wait(math.ceil(r2/unitSpeed*60))
                unitMove(self,choice,nodeIndex,false)
            end}
            if nodeIndex==1 then -- reached player node, shoot bullets
                leakCount=leakCount+1
                local sprite='bigRound'
                if leakCount>10 then
                    sprite='giant'
                end
                BulletSpawner{lifeFrame=120,period=20,bulletNumber=leakCount>5 and 3 or 1,range=leakCount>10 and math.pi/3 or math.pi/6,angle='player',bulletSprite=BulletSprites[sprite].red,bulletSpeed=100,bulletExtraUpdate={Action.ZoomIn(20),Action.ZoomOut(20),function (self)
                    self.kinematicState.speed=math.lerp(self.kinematicState.speed,300,0.01)
                end},bulletLifeFrame=300}:bindState(self)
            end
        end
        local sentry=DanmakuFuncs.sentry()
        local function unitUpdate(self)
            -- die from red barrier
            local distance=geo:distance(self.kinematicState.pos,playerPos)
            if distance<r0 and distance>r0-20 then
                local dir=geo:to(playerPos,self.kinematicState.pos)
                if math.angleDiff(dir,redBarrierAngle)<redBarrierHalfWidth then
                    self:die()
                end
            end
            -- die from controllable path
            local i,j=self.nodeIndex,self.nextNodeIndex
            i,j=math.min(i,j),math.max(i,j)
            local controllableIndex=hash2controlIndex[hash(i,j)]
            if controllableIndex and controllablePathsOn[controllableIndex] and self.onPath then
                self:die()
            end
            if sentry.removed then
                self:remove()
            end
        end
        local function unitDieEffect(self)
            Event.EaseEvent{obj=sentry,easeObj=boss,aims={hp=boss.hp-self.maxhp},duration=30,progressFunc=Event.sineOProgressFunc}
        end
        local eliteHintUpdate=function(self)
            local t=self.frame
            local sin=math.sin(t/20)
            self.spriteColor={1,sin,sin,1}
        end
        local function spawnUnits(num,speed,color)
            local elite=color=='red'
            local seed=math.random(101,999)
            Event{obj=sentry,action=function ()
                for i=1,num do
                    SFX:play(elite and 'enemyShot2' or'enemyShot3')
                    local fairy=Enemy{kinematicState={pos=copyTable(boss.kinematicState.pos),dir=0,speed=0},maxhp=DSWITCH{1000,800,800,800},sprite=Asset.fairySprites.large[color],lifeFrame=9000,extraUpdate={Enemy.presetActions.fadeAndHint,unitUpdate},dropItems={},extraDieEffects={unitDieEffect}}
                    fairy.any={seed=seed,speed=speed,isLast=i==num}
                    if elite then
                        Bullet{sprite=BulletSprites.lightRound.red,lifeFrame=9999,highlight=true,extraUpdate={Action.FadeIn(20,true),eliteHintUpdate}}:bindState(fairy)
                    end
                    unitMove(fairy,2,2,true)
                    wait(15)
                end
            end}
        end
        DynamicUIObjs.showNotice('enriMilitarySpellHint')
        wait(180)
        if DIFF()>=G.LUNATIC then
            BulletSpawner{kinematicState={pos=copyTable(antipode),speed=0,dir=0},bulletNumber=1,bulletSprite=BulletSprites.giant.red,period=DSWITCH{600,480,360,240},firstPeriod=1200,lifeFrame=9999,angle='0+999',bulletExtraUpdate={Action.ZoomIn(20),Action.ZoomOut(20)},bulletLifeFrame=1200,bulletSpeed=radius*math.pi*2/1200*60,highlight=true}
        end
        for i=1,50 do
            local speed,color=DSWITCH{50,55,60,65},'white'
            if DIFF()>=G.HARD and i%3==0 then
                speed,color=speed*2,'red'
            end
            spawnUnits(DSWITCH{6,6,5,5},speed,color)
            local waitTime=300
            if i>10 then
                waitTime=180
            elseif i>5 then
                waitTime=210
            elseif i>2 then
                waitTime=240
            end
            waitTime=math.ceil(waitTime*DSWITCH{1,0.95,0.9,0.85})
            wait(waitTime)
        end
    end
}