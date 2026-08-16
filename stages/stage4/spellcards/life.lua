---@return SpellcardPhase
return BossManager.SpellcardPhase{
    key='shouji-life',
    bonusScore=25000,
    time=2400,
    hp=3000,
    dropItems={powerSmall=15,point=15},
    func=function(self, boss)
        SFX:play('enemyPowerfulShot')
        boss.showHexagram=false
        boss:addHPProtection(960,10)
        local geo=G.runInfo.geometry
        ---@cast geo PortalGeometryBase
        local posp=copyTable(G.runInfo.player.kinematicState.pos)
        Portal.setOuterPortals(posp)
        local dir0=G.runInfo.player.viewDirection
        local posb=geo:rThetaGo(posp,200,dir0-math.pi/2)
        DanmakuFuncs.moveToInTime(boss,posb,60)
        local pos1,dir1=geo:rThetaGo(posp,-190,dir0-math.pi/2)
        local function getHousePoints(r)
            local ret={}
            for i=1,2 do
                local pos,dir=geo:rThetaGo(pos1,r/2^0.5,dir1+(i-0.5)*math.pi)
                table.insert(ret, pos)
            end
            for i=1,5 do
                local pos,dir=geo:rThetaGo(pos1,r,dir1+(i-3)*math.pi/8)
                table.insert(ret, pos)
            end
            return ret
        end
        -- the points forming the house. 4 portals are inside it
        local rOuter=150
        local houseOuterPoints=getHousePoints(rOuter)
        -- the points for sprouting to check if touches the house. slightly inside the houseOuterPoints
        local rSprout=140
        local houseSproutingPoints=getHousePoints(rSprout)
        local insideHousePoint=geo:rThetaGoRef(pos1,30,dir1)
        local sentry=DanmakuFuncs.sentry(pos1)
        Event{obj=sentry,action=function ()
            for i=1,#houseOuterPoints do
                local posa,posb=houseOuterPoints[i],houseOuterPoints[(i%#houseOuterPoints)+1]
                local midPoints=DanmakuFuncs.midPoints(posa,posb,15)
                for j=1,#midPoints-1 do
                    local posm=midPoints[j]
                    Bullet{kinematicState={pos=copyTable(pos1),dir=math.eval(0,99),speed=100,skipPortal=true},sprite=BulletSprites.rim.yellow,size=1,lifeFrame=9999,extraUpdate={function (self)
                        local dir=self.kinematicState.dir
                        local to=math.modClamp(geo:toRef(self.kinematicState.pos,posm),dir)
                        local dist=geo:distanceRef(self.kinematicState.pos,posm)
                        if dist<2 then
                            self.kinematicState.pos=copyTable(posm)
                            self.kinematicState.speed=0
                            self.extraUpdate={}
                            return
                        end
                        self.kinematicState.dir=math.clamp(to,dir-0.1,dir+0.1)
                        self.kinematicState.speed=math.lerp(self.kinematicState.speed,dist*1.5,0.05)
                    end,Action.Trail(20,5),}}
                    if j%3==0 then
                        wait()
                    end
                end
            end
        end}
        local portalLength=25
        local portalWidth=15
        local portalRatio=0.1
        local draw=true
        wait(60)
        -- 4 pairs of portals, 4 form half a house shape at pos1, 4 can move
        local housePortalData={}
        local housePortals={}
        for i=1,4 do
            local pos,dir=geo:rThetaGo(pos1,120,dir1+(i-2.5)*math.pi/8)
            table.insert(housePortalData, {pos=pos, dir=dir})
            local function getPoses()
                local posa,posb=Portal.segment(pos,dir,portalLength*portalRatio)
                return posa,posb
            end
            local posa,posb=getPoses()
            local portal=Portal(posa,posb,-1,{range=portalWidth,draw=draw,extraUpdate={function (self)
                if sentry.removed then
                    self:remove()
                end
                local posa,posb=getPoses()
                self:set(posa,posb)
            end}})
            table.insert(housePortals, portal)
        end
        local freePortalSentries={}
        local freePortals={}
        for i=1,4 do
            local ds={-250,-150,150,250}
            local pos,dir=geo:rThetaGoRef(pos1,ds[i],dir1+math.pi/2)
            dir=dir-math.pi/2
            local sentryi=DanmakuFuncs.PortalOnSentry(pos,dir,portalLength,portalWidth,false,30,{draw=draw},{sprite=BulletSprites.round.blue,size=1,lifeFrame=9999,extraUpdate={Action.ZoomIn(30)}},20)
            freePortalSentries[i]=sentryi
            local portal=sentryi.any.portal
            portal:link(housePortals[i])
            table.insert(freePortals, portal)
        end
        for i=1,30 do
            portalRatio=i*0.03+0.1
            wait()
        end
        local function speedUpdate(self)
            if self.frame+40>self.lifeFrame then
                self.kinematicState.speed=math.lerp(self.kinematicState.speed,0,0.05)
            else
                self.kinematicState.speed=math.lerp(self.kinematicState.speed,400,0.01)
            end
        end
        local function flower(pos,dir)
            Event{obj=sentry,action=function ()
                for i=1,5 do
                    local diri=dir+math.pi*2/5*i
                    local warning=Bullet{kinematicState={pos=copyTable(pos),dir=diri,speed=400},sprite=BulletSprites.scale.white,lifeFrame=120,invincible=true,safe=true,size=3,extraUpdate={Action.FadeIn(30,false),Action.FadeOut(30,false),Action.Trail(30,5),function (self)
                        if self.frame+20>self.lifeFrame then
                            self.kinematicState.speed=math.lerp(self.kinematicState.speed,0,0.1)
                        end
                    end},spriteColor={1,0.3,0.3,0.5},highlight=true}
                end
                SFX:play('enemyCharge')
                wait(60)
                SFX:play('enemyPowerfulShot')
                for j=1,3 do
                    local r,g,b=math.hsvToRgb((j-2)*0.05,0.8,1)
                    for i=1,5 do
                        local diri=dir+math.pi*2/5*i
                        local posj,dirj=geo:rThetaGo(pos,j*5,diri)
                        Bullet{kinematicState={pos=posj,dir=dirj,speed=0},sprite=BulletSprites.scale.white,spriteColor={r,g,b,1},size=3,lifeFrame=200,extraUpdate={Action.ZoomIn(30),Action.FadeOut(20,true),speedUpdate}}
                        -- for k=-2,2 do
                        --     local dirk=dirj+math.pi/6*math.sign(k)
                        --     local posk,dirk2=geo:rThetaGo(posj,-10*math.abs(k),dirk)
                        --     Bullet{kinematicState={pos=posk,dir=dirj,speed=0},sprite=BulletSprites.scale.white,spriteColor={r,g,b,1},size=1,lifeFrame=200,extraUpdate={Action.ZoomIn(30),Action.FadeOut(20,true),speedUpdate}}
                        -- end
                    end
                    wait(10)
                end
            end}
        end
        local overallBranchCount=0
        local overallBigFlowerCount=0
        local function branch(pos,dir,depth)
            if not depth then
                overallBranchCount=0
                overallBigFlowerCount=0
            end
            depth=depth or 1
            local life=math.ceil(math.eval(depth*60-20,20))
            local branchCount=0
            local chance=depth==1 and 0.1 or depth==2 and 0.03 or 0.01
            local base=Bullet{kinematicState={pos=copyTable(pos),dir=dir,speed=80},sprite=BulletSprites.crystalDark.green,lifeFrame=life,extraUpdate={Action.FadeOut(20,true),function (self)
                if self.frame%5==0 then
                    -- check if touches the house
                    local touchesHouse=false
                    for i=-1,2 do
                        local posa,posb=houseSproutingPoints[((i-1)%#houseSproutingPoints)+1],houseSproutingPoints[(i%#houseSproutingPoints)+1]
                        local posNow,posForward=copyTable(self.kinematicState.pos),geo:rThetaGoRef(self.kinematicState.pos,10, self.kinematicState.dir)
                        if geo:sideToLine(posNow,posa,posb)~=geo:sideToLine(posForward,posa,posb) then
                            local nearest=geo:nearestToLine(posNow,posa,posb)
                            local onSegment=math.angleDiff(geo:toRef(nearest,posa),geo:toRef(nearest,posb))>math.pi/2
                            if onSegment then
                                touchesHouse=true
                                break
                            end
                        end
                    end
                    if touchesHouse then
                        self:remove()
                    end
                end
                if self.frame%9==0 then
                    -- branch bullet
                    Bullet{kinematicState={pos=copyTable(self.kinematicState.pos),dir=self.kinematicState.dir,speed=0,skipPortal=true},sprite=BulletSprites.crystalDark.orange,lifeFrame=300,extraUpdate={Action.ZoomIn(30),Action.FadeOut(20,true)}}
                    if math.random()<0.3 then -- flower
                        local bigFlower=false
                        if depth>=4 and math.random()<0.5 and overallBigFlowerCount<5 then
                            bigFlower=true
                            overallBigFlowerCount=overallBigFlowerCount+1
                        end
                        local dist=math.eval(0,10)
                        local pos2,dir2=geo:rThetaGo(self.kinematicState.pos,dist,self.kinematicState.dir+math.pi/2*math.randomSign())
                        Bullet{kinematicState={pos=pos2,dir=dir2+math.eval(0,1),speed=0},sprite=BulletSprites.flower[bigFlower and 'magenta' or 'red'],size=bigFlower and 2 or 1,lifeFrame=DSWITCH{300,400,500,600},extraUpdate={Action.ZoomIn(30),Action.FadeOut(20,true),function (self)
                            if bigFlower then
                                if self.frame>100 then
                                    local ratio=1-math.clamp((self.frame-100)/60,0,1)
                                    self.spriteColor={1,ratio,ratio,1}
                                end
                                if self.frame==190 then
                                    flower(self.kinematicState.pos,self.kinematicState.dir)
                                    self.lifeFrame=240
                                end
                            else
                                if self.frame>100 and self.frame<200 then
                                    self.kinematicState.speed=math.lerp(self.kinematicState.speed,200,0.01)
                                end
                            end
                        end}}
                    end
                end
                if (math.random()<chance or (branchCount==0 and self.frame==self.lifeFrame-1)) and depth<4 and branchCount<3 and overallBranchCount<20 then
                    local pos,dir=self.kinematicState.pos,self.kinematicState.dir
                    -- branch(pos,dir+math.eval(0,0.1),depth+1)
                    branch(pos,dir+math.eval(0.5,0.2)*math.randomSign(),depth+1)
                    branchCount=branchCount+1
                    overallBranchCount=overallBranchCount+1
                end
            end}}
        end
        local function getFreeTargets(index)
            local targets={}
            index=(index-1)%4+1
            if index<=2 then
                for i=1,4 do
                    local pos,dir
                    local ds={-250,-150,150,250}
                    pos,dir=geo:rThetaGoRef(pos1,ds[i],dir1+math.pi/2)
                    dir=dir+math.pi/2*math.mod2Sign(index+1)
                    table.insert(targets, {pos=pos, dir=dir})
                end
            elseif index==3 then
                for i=1,2 do
                    local r=100*i
                    local pos2,dir2=geo:rThetaGoRef(pos1,r,dir1+math.pi)
                    local pos2a,pos2b=Portal.segment(pos2,dir2,100)
                    table.insert(targets, {pos=pos2a, dir=dir2+math.pi/2})
                    table.insert(targets, {pos=pos2b, dir=dir2-math.pi/2})
                end
            elseif index==4 then
                for i=1,4 do
                    local posp,dirp=G.runInfo.player.kinematicState.pos,G.runInfo.player.viewDirection
                    local pos,dir=geo:rThetaGoRef(posp,math.eval(150,50),dirp+math.pi/2*i)
                    table.insert(targets, {pos=pos, dir=dir})
                end
            end
            return targets
        end
        for i=1,5 do
            -- branches
            wait(60)
            SFX:play('enemyPowerfulShot')
            local pos1up,dir1up=geo:rThetaGo(pos1,5,dir1)
            branch(pos1up,dir1up+math.eval(0,0.2))
            wait(200)
            -- targets of free portals
            local targets=getFreeTargets(i+2)
            for j=1,4 do
                local target=targets[j]
                local sentryi=freePortalSentries[j]
                local pos0=copyTable(sentryi.kinematicState.pos)
                local dir,dist=geo:toRef(pos0,target.pos),geo:distanceRef(pos0,target.pos)
                Event.LoopEvent{obj=sentryi,period=1,times=300,executeFunc=function (self,times,maxTimes)
                    local progress=Event.sineIOProgressFunc((times+1)/maxTimes)
                    sentryi.kinematicState.pos=geo:rThetaGoRef(pos0,dist*progress,dir)
                end}
                Event.EaseEvent{obj=sentryi,easeObj=sentryi.kinematicState,aims={dir=math.modClamp(target.dir,sentryi.kinematicState.dir)},duration=300,progressFunc=Event.sineIOProgressFunc}
            end
            wait(340)
        end
    end
}