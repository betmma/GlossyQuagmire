---@diagnostic disable: inject-field
local function lineOrbit(base,pos1,pos2,gap,includePos1,includePos2,bulletArgs)
    local r,theta=G.runInfo.geometry:rThetaTo(pos1,pos2)
    local num=math.ceil(r/gap)
    gap=r/num
    local start=includePos1 and 0 or 1
    local finish=(includePos2 and num or num-1)
    for i=start,finish do
        local pos,dir=G.runInfo.geometry:rThetaGo(pos1,gap*i,theta)
        bulletArgs.kinematicState={pos=pos,dir=dir,speed=0}
        local cir=Bullet(copyTable(bulletArgs))
        local r2,theta2=G.runInfo.geometry:rThetaTo(base.kinematicState.pos,pos)
        DanmakuFuncs.orbitBind(cir,base,{r=r2,theta=theta2})
    end
end
local life=360
local function speed(self)
    if self.frame==10*self.index then
        self.kinematicState.speed=self.speedRef
    end
end
local function redDotShotUpdate(self)
    if self.frame==1 then
        BulletSpawner{bulletSprite=BulletSprites.rain.red,bulletSpeed=50,bulletNumber=DSWITCH{1,2,4,4},angle=0,bulletLifeFrame=life,period=DSWITCH{6,6,6,4},firstPeriod=250,lifeFrame=self.lifeFrame,bulletEvents={function(cir,args,bs)
            cir.kinematicState.dir=self.kinematicState.dir+math.pi/4*math.mod2Sign(bs.spawnTimes)
            local speedRef=cir.kinematicState.speed
            cir.speedRef=speedRef
            cir.index=args.index
            cir.kinematicState.speed=0
        end},bulletExtraUpdate={Action.FadeOut(20,true),speed}}:bindState(self)
    end
end
local function signCore(cir,boss,r0,dangle)
    local side=math.mod2Sign(cir.index)
    local args={sprite=BulletSprites.rim.gray,size=2,invincible=true,highlight=true,lifeFrame=life,extraUpdate={Action.FadeIn(30,true),Action.FadeOut(10,true)},spriteColor={0.8,0.8,0.8}}
    -- make an arrow shape
    local halfWidth=30
    local halfLength=150
    local tipAddWidth=40
    local tipLength=100
    local pos=cir.kinematicState.pos
    local dir=cir.kinematicState.dir-side*math.pi/2
    local gap=30
    local pos2s={}
    local postip=G.runInfo.geometry:rThetaGo(pos,halfLength,dir)
    for side=-1,1,2 do
        local pos1,dir1=G.runInfo.geometry:rThetaGo(pos,halfWidth,dir+side*math.pi/2)
        dir1=dir1-side*math.pi/2
        local pos2,dir2=G.runInfo.geometry:rThetaGo(pos1,-halfLength,dir1)
        table.insert(pos2s,pos2)
        local pos3,dir3=G.runInfo.geometry:rThetaGo(pos1,halfLength-tipLength,dir1)
        lineOrbit(cir,pos2,pos3,gap,false,true,args)
        local postipside=G.runInfo.geometry:rThetaGo(pos3,tipAddWidth,dir3+side*math.pi/2)
        lineOrbit(cir,pos3,postipside,gap,false,true,args)
        lineOrbit(cir,postipside,postip,gap,false,side==-1,args)
        args.sprite=BulletSprites.rimDark.red
        args.size=1
        -- some decorative dots
        local pos4,dir4=G.runInfo.geometry:rThetaGo(pos,halfWidth-20,dir+side*math.pi/2)
        dir4=dir4-side*math.pi/2
        local pos6,dir6=G.runInfo.geometry:rThetaGo(pos4,halfLength-tipLength+20,dir4)
        local postipside2=G.runInfo.geometry:rThetaGo(pos6,tipAddWidth-20,dir6+side*math.pi/2)
        args.extraUpdate[3]=redDotShotUpdate
        lineOrbit(cir,pos6,postipside2,gap*2,false,true,args)
        args.extraUpdate[3]=nil
        args.sprite=BulletSprites.rim.gray
        args.size=2
    end
    lineOrbit(cir,pos2s[1],pos2s[2],gap,true,true,args)
    args.sprite=BulletSprites.rimDark.red
    args.size=1
    -- decorative dots
    local backPos=G.runInfo.geometry:rThetaGo(pos,-halfLength+20,dir)
    local frontPos=G.runInfo.geometry:rThetaGo(pos,halfLength-40,dir)
    lineOrbit(cir,backPos,frontPos,gap*2,false,true,args)
    args.sprite=BulletSprites.rim.gray
    args.size=2
    -- cir's orbiting
    local theta0=G.runInfo.geometry:to(boss.kinematicState.pos,G.runInfo.player.kinematicState.pos)
    theta0=theta0+side*math.pi/2+dangle
    local r,theta=0,0
    cir.r0=r0
    local thetaFunc=function(self)
        self.theta=self.theta or 0
        self.omega=self.omega or 0
        local t=self.frame-60
        if self.theta<math.pi/2 then
            self.omega=self.omega+math.pi/540*(math.min(1,t/30))
        else
            self.omega=self.omega*DSWITCH{'>','>',0.9,0.92}
        end
        self.theta=self.theta+self.omega/60
    end
    -- simulate what theta will the cir end, to generate warning bullets
    local mock={}
    for i=1,life do
        mock.frame=i
        thetaFunc(mock)
    end
    local finalTheta=-mock.theta*side+theta0
    local warningPos,warningDir=G.runInfo.geometry:rThetaGo(pos,r0,finalTheta)
    Bullet{kinematicState={pos=warningPos,dir=warningDir,speed=0},sprite=BulletSprites.explosion.red,size=2,invincible=true,safe=true,spriteColor={0.4,0.4,0.4,0.6},lifeFrame=life,extraUpdate={Action.FadeIn(30,false),Action.FadeOut(20,false)}}
    Bullet{kinematicState={pos=warningPos,dir=warningDir-math.pi/2*side,speed=0},sprite=BulletSprites.arrow.red,size=5,invincible=true,safe=true,spriteColor={1,0.2,0.2,0.6},lifeFrame=life,extraUpdate={Action.FadeIn(30,false),Action.FadeOut(20,false)}}
    local rthetaFunc=function(self,boss)
        r=self.r0*(1-0.5^(self.frame/60))
        thetaFunc(self)
        theta=-self.theta*side+theta0
        return {r=r,theta=theta,absolute=true}
    end
    DanmakuFuncs.orbitBind(cir,boss,rthetaFunc)
    -- a chain connecting cir and boss
    local spawnedChains=0
    local gap=25
    Event.Event{obj=cir,action=function()
        while 1 do
            if r>spawnedChains*gap then
                local chain=Bullet{sprite=BulletSprites.rimDark.gray,size=1,invincible=true,safe=true,spriteTransparency=0.3,lifeFrame=life-cir.frame,extraUpdate={Action.FadeIn(30,false),Action.FadeOut(20,false)}}
                local num=spawnedChains
                DanmakuFuncs.orbitBind(chain,boss,function()
                    local rChain=gap*num
                    return {r=rChain,theta=theta}
                end)
                spawnedChains=spawnedChains+1
            end
            wait()
        end
    end}
end


---@return SpellcardPhase
return BossManager.SpellcardPhase{
            SKIP_INCLUDE=true,
    key='kotoba-lead',
    difficulties={HARD=true,LUNATIC=true},
    bonusScore=10000,
    time=2400,
    hp=2400,
    dropItems={point=15,powerSmall=10},
    func=function(self,boss)
        for i=1,16 do
            local aimPos=G.runInfo.geometry:rThetaGo(G.runInfo.player.kinematicState.pos,math.eval(250,50),G.runInfo.player.viewDirection-math.pi/2)
            DanmakuFuncs.moveToInTime(boss,aimPos,120,Event.sineOProgressFunc)
            Effect.Charge{obj=boss}
            local endpoint=Bullet{kinematicState=copyTable(boss.kinematicState),sprite=BulletSprites.rim.red,size=2,invincible=true,safe=true,spriteTransparency=0,lifeFrame=life+200}
            for j=DSWITCH{3,3,3,4},1,-1 do
                local core=Bullet{kinematicState=copyTable(boss.kinematicState),sprite=BulletSprites.rim.red,size=2,invincible=true,safe=true,spriteTransparency=0,lifeFrame=life}
                core.index=i
                signCore(core,endpoint,50+150*j,math.eval(0,DSWITCH{0,0.1,0.2,0.2}))
                SFX:play('enemyPowerfulShot',true)
                wait(20)
            end
            wait(DSWITCH{300,260,230,230})
        end
    end
}