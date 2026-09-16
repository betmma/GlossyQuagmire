---@type OneStageDataRaw
return{
    init=function()
        G:replaceBackgroundPatternIfNot(BackgroundPattern.Stage5S2R)
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
            func=function() -- 11s. mid boss needs to appear at 51s
                local geo=G.runInfo.geometry
                ---@cast geo Cylinder
                local pos0=geo:init().pos
                local pos1=geo:rThetaGo(pos0,300,-math.pi/2)
                local pos2=geo:rThetaGo(pos1,geo.a/2,0)
                for i=1,20 do
                    local fairy=Enemy{kinematicState=copyTable{pos=pos2,dir=math.pi*(i%2),speed=180},maxhp=50,sprite=Asset.fairySprites.small.purple,lifeFrame=600,extraUpdate={Enemy.presetActions.fadeAndHint},dropItems={powerSmall=2}}
                    BulletSpawner{
                        period=DSWITCH{90,90,45,45},firstPeriod=60-(i%3)*15,lifeFrame=470,bulletNumber=DSWITCH{1,3,3,5},bulletSpeed=150+i*10,bulletSize=1,angle='player',range=math.pi/2,bulletSprite=BulletSprites.round.purple,bulletLifeFrame=540,visible=false,bulletExtraUpdate={Action.FadeOut(20,true)}
                    }:bindState(fairy)
                    wait(15)
                end
                DynamicUIObjs.showStageTitle('stage5')
                wait(360)
                -- wait(24000)
            end
        },
        {
            key='5-2',
            type='midStage',
            func=function() -- 25s
                -- bpm is 160, so a beat is 22.5 frames. 630 frames would be 28 beats
                local geo=G.runInfo.geometry
                ---@cast geo Cylinder
                local pos0=geo:init().pos
                pos0.x=G.runInfo.player.kinematicState.pos.x -- same angle
                local radius=geo.r0*0.8
                local pos1=geo:rThetaGo(pos0,250+radius-geo.r0,-math.pi/2)
                local posh=geo:rThetaGo(pos0,600,-math.pi/2)
                local rotateSpeedRatio=DSWITCH{1,1.2,0.6,-1.2}
                local bindFunc=function (self, centerObj)
                    local t=centerObj.frame
                    return {r=self.any.r*math.min(1,t/60),theta=self.any.angle+t*(centerObj.kinematicState.speed/geo.r0/60)*rotateSpeedRatio*-math.mod2Sign(self.any.index)*math.min(1,t/60)}
                end
                local slow=function(self)
                    self.kinematicState.speed=math.lerp(self.kinematicState.speed,150,0.03)
                end
                local sentry=DanmakuFuncs.sentry()
                local refreshGraze=function(self)
                    if self.frame%4==0 and sentry.frame<1260 then -- simulate laser grazing on big stars. also player can collect items from small fairies by grazing them
                        self.grazed=false
                    end
                end
                local diff=DIFF()
                local afterCenterRemove=function(self)
                    if diff==G.EASY or (diff==G.NORMAL and self.any.index==1) then
                        self.lifeFrame=self.frame+20
                    end
                    self.extraUpdate[#self.extraUpdate+1] = slow
                end
                local colors={'red','yellow','teal','blue','purple'}
                for i=1,2 do
                    local pos2=geo:rThetaGo(pos1,geo.a/4*math.mod2Sign(i),0)
                    local bigFairy=Enemy{kinematicState=copyTable{pos=pos2,dir=math.pi*(i%2),speed=0},maxhp=500,sprite=Asset.fairySprites.large.red,lifeFrame=600,extraUpdate={Enemy.presetActions.fadeAndHint},dropItems={powerSmall=5,point=5}}
                    BulletSpawner{
                        period=240,firstPeriod=60,lifeFrame=90,bulletNumber=2,bulletSpeed=geo.a/2*60/315,bulletSize=1,angle=math.pi/2,bulletSprite=BulletSprites.round.red,bulletLifeFrame=1260,bulletExtraUpdate={Action.FadeOut(20,true)},bulletEvents={function (cir,args,self)
                            SFX:play('enemyPowerfulShot')
                            cir.lifeFrame=cir.lifeFrame-(i-1)*630
                            -- flower shape
                            local n=5
                            local colorIndex=math.random(1,5)
                            for j=1,n do
                                local color=colors[(j+colorIndex)%5+1]
                                local angleBase=j/n*math.pi*2
                                local n2=21
                                for k=1,n2 do
                                    local ratio=((k-0.5)/n2-0.5)*2
                                    local angle=math.sign(ratio)*math.abs(ratio)^2*math.pi/2
                                    local r0=math.max(math.log(math.tan(math.pi/2-0.03-math.abs(angle))*2+1),0) -- maps angle from -pi/2 to pi/2 to a petal shape
                                    local rmax=math.log(math.tan(math.pi/2-0.03)*2+1)
                                    local r=radius/rmax*r0
                                    local bullet=Bullet{lifeFrame=cir.lifeFrame+300,sprite=BulletSprites.bigStar[color],extraUpdate={Action.FadeIn(20,true),Action.FadeOut(20,true),refreshGraze},size=1}
                                    bullet.any={r=r,angle=angleBase+angle,index=args.index}
                                    DanmakuFuncs.orbitBind(bullet,cir,bindFunc,afterCenterRemove)
                                end
                                -- decorative laser. currently due to "side to line" undefined in cylinder, laser cannot calculate checkHitPlayer normally so set it to safe
                                local laser=GeoLaser{sprite=BulletSprites.laser[color],size=9*radius/geo.r0,rayAngle=-0.1,spriteTransparency=1,safe=true,invincible=true,lifeFrame=cir.lifeFrame,meshBudget={capNum=3,step=30,num=math.floor(9*radius/geo.r0)},extraUpdate={GeoLaser.presetActions.laserZoomIn(20),GeoLaser.presetActions.laserZoomOut(20),function(self)
                                end}}
                                laser.any={r=0,angle=angleBase,index=args.index}
                                DanmakuFuncs.orbitBind(laser,cir,bindFunc,function (self)
                                    self.lifeFrame=self.frame+30
                                end)
                            end
                        end}
                    }:bindState(bigFairy)
                    Event{action=function ()
                        wait(165)
                        for j=1,20 do
                            local posh2=geo:rThetaGo(posh,geo.a/4/20*j*math.mod2Sign(i),0)
                            local fairy=Enemy{kinematicState=copyTable{pos=posh2,dir=math.pi/2,speed=120},maxhp=50,sprite=Asset.fairySprites.small.white,lifeFrame=600,extraUpdate={Enemy.presetActions.fadeAndHint},dropItems={powerSmall=1,point=1}}
                            BulletSpawner{
                                period=DSWITCH{90,90,45,45},firstPeriod=105,lifeFrame=300,bulletNumber=DSWITCH{1,3,3,5},bulletSpeed=300,bulletSize=1,angle='player',range=math.pi/9,bulletSprite=BulletSprites.round.white,bulletLifeFrame=600,bulletExtraUpdate={Action.FadeOut(20,true),slow}
                            }:bindState(fairy)
                            wait(11+(j%4==0 and 1 or 0)) -- average 11.25
                        end
                    end}
                    wait(630)
                end
                wait(60)
                SFX:play('enemyPowerfulShot')
                wait(180)
            end
        },
        {
            key='5-3',
            type='midStage',
            func=function() -- 15s
                local geo=G.runInfo.geometry
                ---@cast geo Cylinder
                local pos0=geo:init().pos
                local posh=geo:rThetaGo(pos0,250,-math.pi/2)
                local sentry=DanmakuFuncs.sentry()
                local speed=140
                for j=1,10 do
                    local posh2=geo:rThetaGo(posh,geo.a/10*j*7-(sentry.frame*speed/60),0)
                    local fairy=Enemy{kinematicState=copyTable{pos=posh2,dir=math.pi,speed=speed},maxhp=200,sprite=Asset.fairySprites.medium.blue,lifeFrame=900-sentry.frame,extraUpdate={Enemy.presetActions.fadeAndHint},dropItems={powerSmall=3,point=3}}
                    fairy:addHPProtection(180,5)
                    BulletSpawner{
                        period=DSWITCH{27,18,18,9},firstPeriod=60,lifeFrame=900-sentry.frame,bulletNumber=DSWITCH{2,2,4,4},bulletSpeed=300,bulletSize=1,angle=math.pi,range=math.pi/3,bulletSprite=BulletSprites.turret.blue,bulletLifeFrame=500,bulletExtraUpdate={Action.FadeOut(20,true)},bulletEvents={function (cir,args,self)
                            cir.spriteRotationSpeed=math.mod2Sign(args.index)*0.1
                            cir.spriteExtraDirection=math.eval(0,99)
                            local mid=math.ceil(math.abs(args.index-self.bulletNumber/2-0.5))
                            local sign=math.sign(args.index-self.bulletNumber/2-0.5)
                            if mid==2 then
                                cir:changeSpriteColor('cyan')
                                cir.lifeFrame=300
                                if DIFF()==G.LUNATIC and (self.spawnTimes-1)%8>=4 then
                                    cir.kinematicState.dir=cir.kinematicState.dir+math.pi/12*sign
                                end
                            end
                        end}
                    }:bindState(fairy)
                    wait(22+(j%2)) -- average 22.5
                end
                wait(225)
                wait(450)
            end
        },
        {
            key='5-4',
            type='midStage',
            func=function() -- 42s
            -- second half add some fairies. finale shoot aimed bullets. need to make them vertical as possible to prevent lingering on the board
                -- BGM.data[BGM.currentAudio]:seek(51,'seconds')
                local geo=G.runInfo.geometry
                ---@cast geo Cylinder
                local pos0=geo:init().pos
                pos0.x=G.runInfo.player.kinematicState.pos.x -- same angle as player
                local pos1=geo:rThetaGo(pos0,250,-math.pi/2)
                local function cloudPartOnCoreRemove(self)
                    self.kinematicState.speed=200
                end
                local function easeSpeed(self)
                    self.kinematicState.speed=math.lerp(self.kinematicState.speed,150,0.03)
                end
                local count=0
                local current=1
                local criticals={{0,8+3/4},{15+1/4,22+1/4},{28,36+3/4},{43+1/4,50+1/4},{56,56}}
                local function cloud(core)
                    -- several random giant bullets
                    local n=6
                    local r,g,b=math.hsvToRgb(math.eval(0,1),math.eval(0.8,0.2),math.eval(0.35,0.05))
                    for i=1,n do
                        local ra=math.eval(40,20)
                        local theta=math.pi*2/n*i+math.eval(0,0.4)
                        local x,y=math.rTheta2xy(ra,theta)
                        y=y/2 -- oval shape
                        local r2,theta2=math.xy2rTheta(x,y)
                        local size=math.eval(2,0.5)
                        local giant=Bullet{lifeFrame=1260,sprite=BulletSprites.lightRound.white,size=size,extraUpdate={Action.FadeIn(20,true),Action.FadeOut(20,true)},highlight=true,spriteTransparency=1,spriteColor={r,g,b,1},forceQuad=true}
                        DanmakuFuncs.orbitBind(giant,core,{r=r2,theta=theta2},cloudPartOnCoreRemove)
                        -- Event.LoopEvent{obj=giant,period=180,firstPeriod=120,times=6,executeFunc=function (self, index, total)
                        -- end}
                    end
                    count=count+1
                    return r,g,b
                end
                local function getNoiseF()
                    local rands={math.eval(0,1),math.eval(0,0.7),math.eval(0,0.5)}
                    local freq=math.random(2,4)
                    local noiseF=function(angle)
                        local ans=0
                        local freqi=freq
                        for i=1,3 do
                            ans=ans+math.sin(angle*freqi+rands[i]*9)*rands[i]
                            freqi=freqi*2
                        end
                        return ans
                    end
                    return noiseF
                end
                local function explosion(core,r,g,b)
                    local noiseF=getNoiseF()
                    local cycles=4
                    BulletSpawner{bulletNumber=DSWITCH{160,200,240,300},period=10,firstPeriod=1,lifeFrame=3,angle='0+99',range=math.pi*2*cycles,bulletSprite=BulletSprites.ellipse.white,highlight=true,bulletSpeed=150,bulletLifeFrame=1260,bulletEvents={function (cir,args,self)
                        local cycle=math.ceil(args.index/(self.bulletNumber/cycles))-1
                        local angle=math.modClamp(cir.kinematicState.dir)
                        cir.lifeFrame=math.abs(1/math.clamp(math.tan(angle),0.2,10))*200+200
                        cir.kinematicState.speed=cir.kinematicState.speed+50*noiseF(angle)+80*cycle
                        cir.spriteColor=math.lerpTable({r,g,b,1},{1,1,1,1},cycle/10)
                    end},bulletExtraUpdate={Action.FadeOut(20,true),easeSpeed}}:bindState(core)
                end
                local function explosion2(core,r,g,b)
                    local noiseF=getNoiseF()
                    local cycles=2
                    BulletSpawner{bulletNumber=DSWITCH{40,60,80,100},period=10,firstPeriod=1,lifeFrame=3,angle='0+99',range=math.pi*2*cycles,bulletSprite=BulletSprites.giant.white,highlight=true,bulletSpeed=150,bulletLifeFrame=1260,bulletEvents={function (cir,args,self)
                        cir.forceQuad=true
                        local cycle=math.ceil(args.index/(self.bulletNumber/cycles))-1
                        local angle=math.modClamp(cir.kinematicState.dir)
                        cir.lifeFrame=math.abs(1/math.clamp(math.tan(angle),0.2,10))*200+200
                        cir.kinematicState.speed=cir.kinematicState.speed+50*noiseF(angle)+50*cycle
                        cir.spriteColor=math.lerpTable({r,g,b,1},{1,1,1,1},cycle/10)
                    end},bulletExtraUpdate={Action.FadeOut(20,true),easeSpeed}}:bindState(core)
                    local data=criticals[current]
                    local time=math.floor((criticals[current+1][1]-data[1])*60*60/160)-60
                    local fairyDieEffect=function(self)
                        BulletSpawner{kinematicState={pos=self.kinematicState.pos,speed=0,dir=0},lifeFrame=5,firstPeriod=3,period=10,bulletSprite=BulletSprites.bullet.white,range=0,bulletNumber=10,highlight=true,bulletSpeed=300,bulletLifeFrame=600,angle=geo:to(self.kinematicState.pos,G.runInfo.player.kinematicState.pos),bulletEvents={function(cir,args,self)
                            local mid=args.index-0.5-self.bulletNumber/2
                            cir.kinematicState.pos=geo:rThetaGo(cir.kinematicState.pos,mid*10,cir.kinematicState.dir+math.pi/2)
                            cir.kinematicState.dir=geo:to(cir.kinematicState.pos,G.runInfo.player.kinematicState.pos)
                            cir.kinematicState.speed=cir.kinematicState.speed-math.abs(mid)*20
                            local angle=math.modClamp(cir.kinematicState.dir)
                            cir.lifeFrame=math.abs(1/math.clamp(math.tan(angle),0.2,10))*DSWITCH{100,120,150,200}+200
                        end},bulletExtraUpdate={Action.ZoomIn(20,1,3),Action.FadeOut(20,true),easeSpeed},fogEffect=true,fogTime=10}
                    end
                    for i=1,5 do
                        local r1=math.eval(50,30)
                        local angle=math.eval(0,math.pi)
                        local posi=geo:rThetaGo(core.kinematicState.pos,r1,angle)
                        local dir=math.sign(math.modClamp(geo:to(posi,G.runInfo.player.kinematicState.pos)-math.pi/2))*math.pi/2+math.pi/2
                        local fairy=Enemy{kinematicState={pos=posi,dir=dir,speed=math.eval(200,50)},maxhp=50,sprite=Asset.fairySprites.medium.white,lifeFrame=time,extraUpdate={Enemy.presetActions.fadeAndHint,Action.Finale(3)},dropItems={powerSmall=4,point=4},extraDieEffects={fairyDieEffect}}
                        local warningBullet=Bullet{invincible=true,lifeFrame=fairy.lifeFrame,sprite=BulletSprites.lightRound.red,spriteColor={1,0,0,1},safe=true,forceQuad=true,highlight=true,size=1,extraUpdate={Action.FadeOut(20,false)}}
                        warningBullet:bindState(fairy)
                        -- DanmakuFuncs.orbitBind(fairy,core,{r=r1,theta=angle})
                    end
                end
                local function laser(core,r,g,b)
                    local data=criticals[current]
                    local time=math.floor((data[2]-data[1])*60*60/160)-60
                    local side=count%4<2 and 1 or -1
                    local laserDir=side*math.pi/2
                    -- directly move core towards laserDir to reduce chance of undodgable wall
                    core.kinematicState.pos=geo:rThetaGo(core.kinematicState.pos,DSWITCH{100,90,80,70},laserDir)
                    GeoLaser{kinematicState=copyTable(core.kinematicState),sprite=BulletSprites.laser.white,size=3,rayAngle=0,spriteTransparency=0.3,safe=true,invincible=true,lifeFrame=1250,meshBudget={capNum=2,step=80,num=10},spriteColor={r*1.5,g*1.5,b*1.5,1},extraUpdate={GeoLaser.presetActions.laserZoomIn(time),GeoLaser.presetActions.laserZoomOut(20),function(self)
                        self.kinematicState.pos=copyTable(core.kinematicState.pos)
                        self.kinematicState.dir=laserDir
                        if core.removed and not self.removeFlag then
                            self.removeFlag=true
                            self.lifeFrame=self.frame+20
                        end
                        if self.frame==time+50 then
                            Event.EaseEvent{obj=self,duration=20,aims={size=0.1},progressFunc=Event.sineBackProgressFunc}
                        end
                        if self.frame==time+60 then
                            SFX:play('enemyPowerfulShot',nil,0.3)
                            self.safe=false
                        end
                        if time+60<=self.frame and self.frame<time+70 then
                            self.spriteTransparency=self.spriteTransparency+(1-0.3)/10
                        end
                    end}}
                    return side
                end
                local function getPos()
                    return{x=G.runInfo.player.kinematicState.pos.x+geo.a*math.eval(0.5,0.25),y=0}
                end
                local function bigbang(pos,round2)
                    pos=pos or getPos()
                    SFX:play('enemyPowerfulShot')
                    for side=0,1 do
                        local angle0=math.pi*side
                        local offset=math.eval(0,0.2)
                        local n=1
                        local period=math.eval(120,30)
                        for i=1,n do
                            local mid=i-0.5-n/2
                            local extraAngle=mid*math.pi/9+offset
                            local angle=angle0+extraAngle
                            local core=Bullet{kinematicState={pos=copyTable(pos),dir=angle,speed=math.eval(100,30)},sprite=BulletSprites.round.red,spriteTransparency=0,lifeFrame=1260,safe=true,extraUpdate={function(self)
                                self.kinematicState.dir=math.cos(self.frame/period)*self.any.extraAngle+self.any.angle0
                            end}}
                            core.any={angle0=angle0,extraAngle=extraAngle}
                            local r,g,b=cloud(core)
                            if not round2 and count%2==0 then
                                explosion(core,r,g,b)
                            end
                            local laserDir=laser(core,r,g,b)
                            if laserDir==-1 and round2 then
                                explosion2(core,r,g,b)
                            end
                        end
                    end
                end
                for index=1,#criticals-1 do
                    current=index
                    bigbang()
                    wait(math.ceil((criticals[index+1][1]-criticals[index][1])*60*60/160-0.5))
                end
                for index=1,#criticals-1 do
                    current=index
                    bigbang(nil,true)
                    wait(math.ceil((criticals[index+1][1]-criticals[index][1])*60*60/160-0.5))
                end
            end
        },
        {
            key='5-5',
            type='midStage',
            func=function() -- 25.5s
                BGM.data[BGM.currentAudio]:seek(93,'seconds')
                local geo=G.runInfo.geometry
                ---@cast geo Cylinder
                local pos0=geo:init().pos
                local player=G.runInfo.player
                wait(22) -- a beat before 16 3-3-2s
                local function getNoiseF()
                    local rands={math.eval(0,1),math.eval(0,0.7),math.eval(0,0.5)}
                    local freq=math.random(2,4)
                    local noiseF=function(angle)
                        local ans=0
                        local freqi=freq
                        for i=1,3 do
                            ans=ans+math.sin(angle*freqi+rands[i]*9)*rands[i]
                            freqi=freqi*2
                        end
                        return ans
                    end
                    return noiseF
                end
                local sentry=DanmakuFuncs.sentry()
                local counts={0,0,0,0}
                local countN=#counts
                local function rand()
                    local min=math.min(unpack(counts))
                    local pool={}
                    for i=1,countN do
                        if counts[i]==min then
                            pool[#pool+1]=i
                        end
                    end
                    local index=pool[math.random(1,#pool)]
                    counts[index]=counts[index]+1
                    return index
                end
                local function spawnFairy(angle)
                    local pos={x=angle*geo.r0+player.kinematicState.pos.x,y=0}
                    local level=rand()
                    local fairy=Enemy{kinematicState={pos=pos,dir=math.pi/2,speed=(level-0.5-countN/2)*180},maxhp=150,sprite=Asset.fairySprites.medium.blue,lifeFrame=600,extraUpdate={Enemy.presetActions.fadeAndHint},dropItems={powerSmall=3,point=3}}
                    local warningBullet=Bullet{invincible=true,lifeFrame=fairy.lifeFrame,sprite=BulletSprites.lightRound.red,spriteColor={1,0.2,0.7,1},safe=true,forceQuad=true,highlight=true,size=1.5,extraUpdate={Action.FadeOut(20,false)}}
                    warningBullet:bindState(fairy)
                    fairy:addHPProtection(60,3)
                    SFX:play('enemyShot')
                    Event{obj=fairy,action=function()
                        Event.EaseEvent{obj=fairy,easeObj=fairy.kinematicState,aims={speed=0},duration=90}
                        wait(90)
                        SFX:play('enemyShot')
                        local period=6
                        local lifeFrame=60
                        local num=lifeFrame/period
                        local noiseF=getNoiseF()
                        local oscillatePeriod=180
                        BulletSpawner{period=period,lifeFrame=lifeFrame,bulletNumber=DSWITCH{2,2,4,4},angle=0,range=0,bulletLifeFrame=600,bulletSpeed=DSWITCH{150,200,150,200},bulletSprite=BulletSprites.giant.blue,highlight=true,bulletExtraUpdate={Action.ZoomIn(20),Action.ZoomOut(20),function(self)
                            local phase=self.any.deltaPhase+sentry.frame/oscillatePeriod*math.pi
                            self.kinematicState.pos.y=self.any.y0+70*math.sin(phase)*math.min(1,self.frame/30)*self.any.ratio
                        end},bulletEvents={function(cir,args,self)
                            cir.forceQuad=true
                            local index=args.index
                            local deltaPhase=(index%2)*math.pi
                            if index>2 then
                                cir.kinematicState.dir=cir.kinematicState.dir+math.pi
                                deltaPhase=deltaPhase+math.pi/2
                            end
                            local ratio0=(self.spawnTimes-1)/(num-1)
                            local ratio=(noiseF(ratio0*math.pi/2)*0.4+1)*(1-(ratio0*2-1)^2)^0.5
                            cir.any={index=self.spawnTimes*period,deltaPhase=deltaPhase,y0=cir.kinematicState.pos.y,ratio=ratio}
                        end}}:bindState(fairy)
                        Event.EaseEvent{obj=warningBullet,aims={size=1},duration=20,progressFunc=Event.sineOProgressFunc}
                        Event.EaseEvent{obj=warningBullet,easeObj=warningBullet.spriteColor,aims={[2]=0,[3]=0},duration=20,progressFunc=Event.sineOProgressFunc}
                        wait(90)
                        local dirp=math.sign(math.modClamp(geo:to(fairy.kinematicState.pos,player.kinematicState.pos)-math.pi/2))*math.pi/2+math.pi/2
                        fairy.kinematicState.dir=dirp
                        Event.EaseEvent{obj=fairy,easeObj=fairy.kinematicState,aims={speed=150},duration=90}
                    end}
                end
                for i=1,8 do
                    local angle0=math.mod2Sign(i)*math.pi/3
                    spawnFairy(angle0+math.mod2Sign(i)*math.pi*4/3)
                    wait(34)
                    spawnFairy(angle0+math.mod2Sign(i)*math.pi*2/3)
                    wait(34)
                    spawnFairy(angle0)
                    wait(22)
                    wait(90)
                end
                wait(78) -- 3 more beats after 16 3-3-2s, overall 17 bars = 25.5s
            end
        }
    }
}
