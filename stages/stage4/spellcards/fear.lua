---@return SpellcardPhase
return BossManager.SpellcardPhase{
    key='shouji-fear',
    bonusScore=25000,
    time=2400,
    hp=3000,
    dropItems={powerSmall=15,point=15},
    func=function(self, boss)
        SFX:play('enemyPowerfulShot')
        boss.showHexagram=false
        boss:addHPProtection(300,3)
        local geo=G.runInfo.geometry
        ---@cast geo PortalGeometryBase
        local posp=copyTable(G.runInfo.player.kinematicState.pos)
        local dir0=G.runInfo.player.viewDirection
        local posb,posd=geo:rThetaGo(posp,250,dir0-math.pi/2)
        Portal.setOuterPortals(posb)
        DanmakuFuncs.moveToInTime(boss,posb,60)
        --- create a bullet square
        local halfN=7
        local smallSquare=DIFF()<=G.NORMAL
        local gap=smallSquare and 15 or 700/(2*halfN+1)
        local centerPos,centerDir=geo:rThetaGo(posb,smallSquare and -100 or 0,dir0-math.pi/2)
        -- centerDir=centerDir+math.pi/4
        local spawnIJ
        local cellDir=-math.pi*3/4
        local function update(self)
            local lastPos=self.lastPos or self.kinematicState.pos
            if self.aimCompleted and not self.zoomFlag then
                self.zoomFlag=true
                Event.EaseEvent{obj=self,easeObj=self.kinematicState,aims={dir=math.modClamp(cellDir,self.kinematicState.dir)},duration=60,progressFunc=Event.sineIOProgressFunc}
                Event.EaseEvent{obj=self,aims={size=smallSquare and 1 or 2,spriteTransparency=1},duration=60,afterFunc=function()
                    self.safe=false
                end}
            end
            if self.kinematicState.teleportedPortal and self.aimCompleted and not self.flag then -- teleported
                --- exclude outer portals (without any)
                local portal
                for i=1,#self.kinematicState.teleportedPortal do
                    local p=Portal.objects[self.kinematicState.teleportedPortal[i]]
                    if p and p.any and p.any.sentry then
                        portal=p
                        break
                    end
                end
                if not portal then
                    self:remove()
                    return
                end
                SFX:play('enemyShot')
                self:changeSpriteColor('red')
                self.kinematicState.speed=portal.any.sentry.kinematicState.speed
                self.kinematicState.dir=portal.linked.any.sentry.kinematicState.dir
                self.lifeFrame=self.frame+DSWITCH{240,360,240,360}
                self.spriteColor={1,1,1,1}
                self.flag=true
                spawnIJ(self.any.i,self.any.j)
            end
            self.lastPos=copyTable(self.kinematicState.pos)
        end
        spawnIJ=function(i,j)
            local posi,diri=geo:rThetaGoRef(centerPos,i*gap,centerDir)
            local posj,dirj=geo:rThetaGoRef(posi,j*gap,diri+math.pi/2)
            local color={1,1,1,1}
            if smallSquare then
                if i*i+j*j>halfN*halfN then
                    return
                end
                -- some 3d shade
                local r,angle=(i*i+j*j)^0.5/halfN,math.atan2(j,i)
                local shade=math.sign(math.cos(angle-math.pi*3/4))*0.5
                local strength=r<0.6 and 0 or 0.2
                if 0.6<r and r<0.8 then
                    strength=-0.6
                end
                color={0.7+strength*shade,0.7+strength*shade,0.7+strength*shade,1}
            elseif geo:distanceRef(posj,boss.kinematicState.pos)<100 then
                return
            end
            local bullet=Bullet{kinematicState={pos=copyTable(boss.kinematicState.pos),dir=math.eval(posd,1),speed=280},sprite=BulletSprites.scale.gray,size=0.4,lifeFrame=9999,extraUpdate={Action.AimAt(posj),Action.FadeOut(20,true),update},highlight=false,invincible=true,safe=true,spriteTransparency=0.3,spriteColor=color}
            bullet.any={i=i,j=j}
        end
        for i=-halfN,halfN do
            for j=-halfN,halfN do
                spawnIJ(i,j)
                if j%5==0 then
                    wait()
                end
            end
        end
        wait(120)
        for i=1,30 do
            local length=smallSquare and 20 or 50
            local playerPos=G.runInfo.player.kinematicState.pos
            local sliceCenter=geo:rThetaGoRef(smallSquare and centerPos or playerPos,math.eval(0,30),math.eval(0,99))
            local sliceDir=math.eval(0,99)
            local sliceStartPos=geo:rThetaGoRef(sliceCenter,-150,sliceDir)
            SFX:play('enemyPowerfulShot')
            local sliceSentry=DanmakuFuncs.PortalOnSentry(sliceStartPos,sliceDir,length,20,false,30,{draw=true,width=10,color={0.3,0.3,1,1},lifeFrame=180},{sprite=BulletSprites.round.blue,size=1,lifeFrame=180,extraUpdate={Action.FadeIn(60,true),Action.FadeOut(60,true)},invincible=true},15)
            sliceSentry.kinematicState.speed=-20
            sliceSentry.extraUpdate={function (self)
                if self.frame>60 then
                    self.kinematicState.speed=math.lerp(self.kinematicState.speed,300,0.05)
                end
            end}

            local outCenter=geo:rThetaGoRef(smallSquare and playerPos or posb,math.eval(0,30),math.eval(0,99))
            local outDir=geo:toRef(outCenter,playerPos)
            local outStartPos=geo:rThetaGoRef(outCenter,smallSquare and -100 or 30,outDir)
            local outSentry=DanmakuFuncs.PortalOnSentry(outStartPos,outDir,length,20,true,30,{draw=true,width=10,color={1,0.3,0.3,1},lifeFrame=180},{sprite=BulletSprites.round.red,size=1,lifeFrame=180,extraUpdate={Action.FadeIn(60,true),Action.FadeOut(60,true)},invincible=true},15)
            -- outSentry.kinematicState.speed=-200
            -- outSentry.extraUpdate={function (self)
            --     self.kinematicState.speed=math.lerp(self.kinematicState.speed,0,0.05)
            -- end}

            sliceSentry.any.portal:link(outSentry.any.portal)
            wait(DSWITCH{120,90,120,120})
        end
    end
}