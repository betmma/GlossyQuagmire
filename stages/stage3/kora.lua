local midboss=BossManager.BossSegment{
    bossName='kora',
    key='3-mid',
    getBossSpawnPos=function(self)
        local geo=G.runInfo.geometry
        local pos,dir=geo:rThetaGo(geo:init().pos,250,G.runInfo.player.viewDirection-math.pi/2)
        return pos
    end,
    rounds={
        BossManager.BossRound{phases={
            BossManager.NonSpellPhase{
                key='3-mid-kora-non-1',
                time=1200,
                hp=2400,
                dropItems={point=15,powerSmall=10},
                func=function(self, boss)
                    local geo=G.runInfo.geometry
                    local pos0=boss.kinematicState.pos
                    local sentry=DanmakuFuncs.sentry(pos0)
                    local extraUpdate=function(self)
                        if self.frame<30 then
                            self.kinematicState.speed=self.kinematicState.speed*0.9
                        end
                        if self.frame>=30 and self.frame<81 then
                            self.kinematicState.dir=self.kinematicState.dir+math.pi/51*math.mod2Sign(self.index)
                            self.safe=true
                            if self.mirrored then
                                self.spriteTransparency=math.clamp(1-(self.frame-30)/51,0.5,1)
                            end
                        end
                        if self.frame==90 then
                            self.spriteTransparency=1
                            self.safe=false
                        end
                        if self.frame>90 then
                            self.kinematicState.speed=math.lerp(self.kinematicState.speed,100,0.03)
                        end
                    end
                    for i=1,6 do
                        local pos1=geo:rThetaGo(pos0,math.eval(30,30),math.eval(0,99))
                        DanmakuFuncs.moveToInTime(boss,pos1,60)
                        local bullets={}
                        SFX:play('enemyShot')
                        local n1,n2=DSWITCH{4,4,8,8},DSWITCH{4,8,8,16}
                        BulletSpawner{period=100,firstPeriod=23,lifeFrame=24,bulletNumber=n2,bulletSpeed=600,range=math.pi*2*n2/n1,angle='player',bulletSprite=BulletSprites.arrow.black,bulletLifeFrame=400,bulletEvents={function(cir,args,self)
                            cir.index=args.index
                            local l=math.floor((cir.index-1)/n1)
                            cir.kinematicState.speed=cir.kinematicState.speed*(1+l*0.2)
                            if DIFF()==G.LUNATIC and l==1 and cir.index%2~=i%2 then -- remove second layer of big rings to reduce bullet count
                                cir:remove()
                                return
                            end
                            table.insert(bullets,cir)
                        end},bulletExtraUpdate={extraUpdate}}:bindState(boss)
                        local posm,dirm=geo:rThetaGo(geo:init().pos,200,G.runInfo.player.viewDirection-math.pi/2)
                        local function getPoses(t)
                            local angle=(t*math.pi-math.pi/4)*math.mod2Sign(i-1)
                            local pos1=geo:rThetaGo(posm,400,angle+dirm-math.pi/2)
                            local pos2=geo:rThetaGo(posm,400,angle+dirm+math.pi/2)
                            local posin=geo:rThetaGo(posm,200,angle+dirm)
                            return pos1,pos2,posin
                        end
                        local p10,p20,pin=getPoses(0)
                        local mirror=Mirror(p10,p20,pin,{extraUpdate={Action.FadeIn(52,false,0.7),Action.FadeOut(30,false),function (self)
                            local t=math.clamp(self.frame-52,0,51)/51
                            self.pos1,self.pos2,self.posIn=getPoses(t)
                            if t>0 and t<1 then
                                Mirror.setHSV({t*math.mod2Sign(i-1),0.5,1},0)
                                if sentry.removed then
                                    return
                                end
                                for i,bullet in ipairs(bullets) do
                                    Mirror.spawnReflections(bullet,1,nil,{index=true})
                                end
                            end
                        end},lifeFrame=133})
                        wait(206)
                    end
                end
            },
            require('stages.stage3.spellcards.cosmos')
        }}
    }
}

local boss=BossManager.BossSegment{
    bossName='kora',
    key='3-boss',
    getBossSpawnPos=function(self)
        local geometry=G.runInfo.geometry
        local pos,dir=geometry:rThetaGo(geometry:init().pos,300,G.runInfo.player.viewDirection-math.pi/2)
        return pos
    end,
    rounds={
        BossManager.BossRound{phases={
            BossManager.NonSpellPhase{
                key='3-boss-kora-non-1',
                time=1500,
                hp=2600,
                func=function(self, boss)
                    local geo=G.runInfo.geometry
                    local basePos=geo:init().pos
                    local pos0=boss.kinematicState.pos
                    local sentry=DanmakuFuncs.sentry(pos0)
                    local extraUpdate=function(self)
                        if self.mirrored then
                            if not self.t0 then
                                self.spriteTransparency=0.5
                                self.t0=self.frame
                                self.aimDir=math.modClamp(self.kinematicState.dir+math.pi*99*math.pseudoRandom(math.ceil(self.t0/12))*math.mod2Sign(self.i),self.kinematicState.dir)
                            end
                            if self.frame<80 then
                                self.safe=true
                                self.kinematicState.speed=0
                                self.kinematicState.dir=math.lerp(self.kinematicState.dir,self.aimDir,0.05)
                            elseif self.frame==80 then
                                self.spriteTransparency=1
                                self.safe=false
                                self.kinematicState.dir=self.aimDir
                                if geo:distance(self.kinematicState.pos,G.runInfo.player.kinematicState.pos)<50 then
                                    self.safe=true
                                    self.spriteTransparency=0.5
                                    Event.EaseEvent{obj=self,aims={spriteTransparency=0},duration=20}
                                    self.lifeFrame=self.frame+20
                                end
                            else
                                self.kinematicState.speed=math.lerp(self.kinematicState.speed,100,0.03)
                            end
                        end
                        if self.frame%50==0 and geo:distance(self.kinematicState.pos,basePos)>700 then
                            self:remove()
                        end
                    end
                    for i=1,6 do
                        local pos1=geo:rThetaGo(pos0,math.eval(30,30),math.eval(0,99))
                        DanmakuFuncs.moveToInTime(boss,pos1,60)
                        local bullets={}
                        SFX:play('enemyShot')
                        local n1,n2=4,DSWITCH{2,4,6,10}
                        BulletSpawner{period=100,firstPeriod=23,lifeFrame=24,bulletNumber=n2,bulletSpeed=200,range=math.pi/2,angle=math.pi/2,bulletSprite=BulletSprites.arrow.black,bulletLifeFrame=600,bulletEvents={function(cir,args,self)
                            cir.index=args.index
                            cir.i=i
                            local sign=cir.index>self.bulletNumber/2 and 1 or -1
                            cir.kinematicState.dir=cir.kinematicState.dir+sign*math.pi/8
                            table.insert(bullets,cir)
                        end},bulletExtraUpdate={extraUpdate}}:bindState(boss)
                        local posm,dirm=geo:rThetaGo(geo:init().pos,200,G.runInfo.player.viewDirection-math.pi/2)
                        local function getPoses(t,i)
                            local angle=0
                            local posm2,dirm2=geo:rThetaGo(posm,300*t-50+100*i,angle+dirm)
                            local pos1=geo:rThetaGo(posm2,400,dirm2-math.pi/2)
                            local pos2=geo:rThetaGo(posm2,400,dirm2+math.pi/2)
                            local posin=geo:rThetaGo(posm2,200,dirm2+math.pi*i)
                            return pos1,pos2,posin
                        end
                        for j=0,1 do
                            local p10,p20,pin=getPoses(0,j)
                            Mirror.setHSV({math.mod2Sign(i-1)/4,0.5,1},0.3)
                            local mirror=Mirror(p10,p20,pin,{extraUpdate={Action.FadeIn(52,false,0.3),Action.FadeOut(30,false),function (self)
                                local t=math.clamp(self.frame-52,0,51)/51
                                -- self.pos1,self.pos2,self.posIn=getPoses(t)
                                if t>0 and t<1 then
                                    if sentry.removed or self.frame%3~=0 or j~=0 then
                                        return
                                    end
                                    for i,bullet in ipairs(bullets) do
                                        if not bullet.removed then
                                            Mirror.spawnReflections(bullet,5,nil,{index=true,i=true})
                                        end
                                    end
                                end
                            end},lifeFrame=133})
                        end
                        wait(206)
                    end
                end
            },
            require('stages.stage3.spellcards.manifest')
        }},
        BossManager.BossRound{phases={
            BossManager.NonSpellPhase{
                key='3-boss-kora-non-2',
                time=1500,
                hp=2600,
                func=function(self, boss)
                    local geo=G.runInfo.geometry
                    local basePos=geo:init().pos
                    local pos0=geo:rThetaGo(basePos,250,G.runInfo.player.viewDirection-math.pi/2)
                    local sentry=DanmakuFuncs.sentry(pos0)
                    local extraUpdate=function(self)
                        if self.mirrored then
                            if not self.t0 then
                                self.spriteTransparency=0.5
                                self.t0=self.frame
                                self.aimDir=math.modClamp(self.kinematicState.dir+math.pi*0.5*math.mod2Sign(math.ceil(self.t0/DSWITCH{16,16,10,6}))*math.mod2Sign(self.i),self.kinematicState.dir)
                            end
                            if self.frame<82 then
                                self.safe=true
                                self.kinematicState.speed=0
                                self.kinematicState.dir=math.lerp(self.kinematicState.dir,self.aimDir,0.05)
                            else
                                self.spriteTransparency=1
                                self.safe=false
                                self.kinematicState.dir=self.aimDir
                                self.kinematicState.speed=math.lerp(self.kinematicState.speed,100,0.03)
                            end
                        end
                        if self.frame%50==0 and geo:distance(self.kinematicState.pos,basePos)>700 then
                            self:remove()
                        end
                    end
                    for i=1,6 do
                        local pos1=geo:rThetaGo(pos0,math.eval(30,30),math.eval(0,99))
                        DanmakuFuncs.moveToInTime(boss,pos1,60)
                        local bullets={}
                        SFX:play('enemyShot')
                        local n1,n2=4,2
                        local angle=geo:to(boss.kinematicState.pos,G.runInfo.player.kinematicState.pos)-math.pi/2
                        angle=math.clamp(angle,-0.1,0.1)
                        BulletSpawner{period=99,firstPeriod=60,lifeFrame=61,bulletNumber=n2,bulletSpeed=320,angle=angle,bulletSprite=BulletSprites.arrow.black,bulletLifeFrame=600,bulletEvents={function(cir,args,self)
                            cir.index=args.index
                            cir.i=i
                            -- local sign=cir.index>self.bulletNumber/2 and 1 or -1
                            -- cir.kinematicState.dir=cir.kinematicState.dir+sign*math.pi/8
                            table.insert(bullets,cir)
                            -- warnings
                            for i=1,20 do
                                local dist=500*i/20
                                local pos=geo:rThetaGo(cir.kinematicState.pos,dist,cir.kinematicState.dir)
                                local warning=Bullet{kinematicState={pos=copyTable(pos),speed=0,dir=0},sprite=BulletSprites.cross.white,lifeFrame=dist*60/cir.kinematicState.speed,invincible=true,safe=true,size=2,spriteColor={0.5,0,0,0.5},extraUpdate={Action.ZoomIn(10),Action.FadeOut(10,false)}}
                            end
                        end},bulletExtraUpdate={extraUpdate}}:bindState(boss)
                        local posm,dirm=geo:rThetaGo(geo:init().pos,200,G.runInfo.player.viewDirection-math.pi/2)
                        local function getPoses(t,i)
                            local angle=math.pi/2
                            local posm2,dirm2=geo:rThetaGo(posm,300*t-50+100*i,angle+dirm)
                            local pos1=geo:rThetaGo(posm2,400,dirm2-math.pi/2)
                            local pos2=geo:rThetaGo(posm2,400,dirm2+math.pi/2)
                            local posin=geo:rThetaGo(posm2,200,dirm2+math.pi*i)
                            return pos1,pos2,posin
                        end
                        for j=0,1 do
                            local p10,p20,pin=getPoses(0,j)
                            Mirror.setHSV({math.mod2Sign(i-1)/4,0.5,1},0.3)
                            local mirror=Mirror(p10,p20,pin,{extraUpdate={Action.FadeIn(62,false,0.7),Action.FadeOut(30,false),function (self)
                                local t=math.clamp(self.frame-62,0,81)/81
                                -- self.pos1,self.pos2,self.posIn=getPoses(t)
                                if t>0 and t<1 then
                                    if sentry.removed or self.frame%1~=0 or j~=0 then
                                        return
                                    end
                                    for i,bullet in ipairs(bullets) do
                                        if not bullet.removed then
                                            Mirror.spawnReflections(bullet,DSWITCH{4,6,6,6},nil,{index=true,i=true})
                                        end
                                    end
                                end
                            end},lifeFrame=173})
                        end
                        wait(230)
                    end
                end
            },
            require('stages.stage3.spellcards.self')
        }},
        BossManager.BossRound{phases={
            BossManager.NonSpellPhase{
                key='3-boss-kora-non-3',
                time=1500,
                hp=2600,
                func=function(self, boss)
                    local geo=G.runInfo.geometry
                    local basePos=geo:init().pos
                    local pos0=geo:rThetaGo(basePos,250,G.runInfo.player.viewDirection-math.pi/2)
                    local sentry=DanmakuFuncs.sentry(pos0)
                    local extraUpdate=function(self)
                        if self.mirrored then
                            self.lifeFrame=600
                            if not self.t0 then
                                self.spriteTransparency=0.5
                                self.t0=self.frame
                                self.aimDir=math.modClamp(self.kinematicState.dir+math.pi*0.5*math.mod2Sign(math.ceil(self.t0/DSWITCH{16,16,10,6}))*math.mod2Sign(self.i),self.kinematicState.dir)
                            end
                            if self.frame<82 then
                                self.safe=true
                                self.kinematicState.speed=0
                                self.kinematicState.dir=math.lerp(self.kinematicState.dir,self.aimDir,0.05)
                            else
                                self.spriteTransparency=1
                                self.safe=false
                                self.kinematicState.dir=self.aimDir
                                self.kinematicState.speed=math.lerp(self.kinematicState.speed,150,0.02)
                            end
                        end
                        if self.frame%50==0 and geo:distance(self.kinematicState.pos,basePos)>700 then
                            self:remove()
                        end
                    end
                    for i=1,6 do
                        local pos1=geo:rThetaGo(pos0,math.eval(30,30),math.eval(0,99))
                        DanmakuFuncs.moveToInTime(boss,pos1,60)
                        local bullets={}
                        SFX:play('enemyShot')
                        local n1,n2=4,2
                        local angle=geo:to(boss.kinematicState.pos,G.runInfo.player.kinematicState.pos)-math.pi/2
                        angle=math.clamp(angle,-0.1,0.1)
                        BulletSpawner{period=99,firstPeriod=60,lifeFrame=61,bulletNumber=n2,bulletSpeed=320,angle=angle,bulletSprite=BulletSprites.arrow.black,bulletLifeFrame=600,bulletEvents={function(cir,args,self)
                            cir.index=args.index
                            cir.i=i
                            table.insert(bullets,cir)
                            if cir.index==1 then
                                cir.lifeFrame=44
                            end
                            -- warnings
                            for i=1,20 do
                                local dist=500*i/20
                                local pos=geo:rThetaGo(cir.kinematicState.pos,dist,cir.kinematicState.dir)
                                local warning=Bullet{kinematicState={pos=copyTable(pos),speed=0,dir=0},sprite=BulletSprites.cross.white,lifeFrame=dist*60/cir.kinematicState.speed,invincible=true,safe=true,size=2,spriteColor={0.5,0,0,0.5},extraUpdate={Action.ZoomIn(10),Action.FadeOut(10,false)}}
                            end
                        end},bulletExtraUpdate={extraUpdate}}:bindState(boss)
                        local posm,dirm=pos1,angle+math.pi/2
                        local function getPoses(t,i)
                            local angle=math.pi/2
                            local posm2,dirm2=geo:rThetaGo(posm,(-50+100*i)*math.clamp(1-t,0.1,1),angle+dirm)
                            local pos1=geo:rThetaGo(posm2,400,dirm2-math.pi/2)
                            local pos2=geo:rThetaGo(posm2,400,dirm2+math.pi/2)
                            local posin=geo:rThetaGo(posm2,200,dirm2+math.pi*i)
                            return pos1,pos2,posin
                        end
                        for j=0,1 do
                            local p10,p20,pin=getPoses(0,j)
                            Mirror.setHSV({math.mod2Sign(i-1)/4,0.5,1},0.3)
                            local mirror=Mirror(p10,p20,pin,{extraUpdate={Action.FadeIn(62,false,0.7),Action.FadeOut(30,false),function (self)
                                local t=math.clamp(self.frame-62,0,81)/81
                                self.pos1,self.pos2,self.posIn=getPoses(t,j)
                                if t>0 and t<1 then
                                    if sentry.removed or self.frame%2~=0 or j~=0 then
                                        return
                                    end
                                    for i,bullet in ipairs(bullets) do
                                        if not bullet.removed then
                                            Mirror.spawnReflections(bullet,DSWITCH{6,8,10,12},nil,{index=true,i=true})
                                        end
                                    end
                                end
                            end},lifeFrame=173})
                        end
                        wait(230)
                    end
                end
            },
            require('stages.stage3.spellcards.tear'),
        }}
    }
}

return {
    boss=boss,
    midboss=midboss,
}