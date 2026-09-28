---@return SpellcardPhase
return BossManager.SpellcardPhase{
    key='tatsu-cloud',SKIP_INCLUDE=true,
    bonusScore=40000,
    time=2400,
    hp=5600,
    dropItems={powerSmall=20,point=20},
    func=function(self, boss)
        boss:addHPProtection(120,3)
        local geo=G.runInfo.geometry
        ---@cast geo Cylinder
        local ball=boss.any.getBall(boss)
        local sign=math.randomSign()
        local time=420
        local player=G.runInfo.player
        local playerPos
        local function reverse(xv,yv,xwrap)
            local r,theta=math.xy2rTheta(xv,yv)
            theta=theta-(playerPos.x/geo.r0+math.pi/2)
            local x=-theta*geo.r0
            local y=geo.r0*(1+math.log(r/geo.r0))
            return x,y,1/(r/geo.r0)
        end
        local moveFlag
        local function update(self)
            if moveFlag then
                self.kinematicState.speed=math.lerp(self.kinematicState.speed,150,0.02)
                self.kinematicState.dir=self.kinematicState.dir+(self.any and self.any.omega or 0)
            end
        end
        local extraUpgrades={Action.FadeIn(20,true),Action.ZoomIn(20,1,2,true),Action.ZoomOut(10),update}
        local function hexagram()
            local r=270
            local angle0=math.eval(math.pi/2,2)
            for i=1,2 do
                local n=DSWITCH{60,90,90,120}
                for j=1,n do
                    local angle=math.pi*2/n*j+math.pi/3*i
                    local r2,angle2=math.polygonize(3,angle,r,math.pi/3*i)
                    local xv,yv=math.rTheta2xy(r2,angle2)
                    local x,y,size=reverse(xv,yv)
                    local pos={x=x,y=y}
                    local dir=math.pi/2+angle2*3+angle0
                    dir=math.modClamp(dir,geo:to(pos,ball.kinematicState.pos),1)
                    Bullet{kinematicState={pos=pos,speed=0,dir=dir},lifeFrame=600,sprite=BulletSprites.round.blue,size=size,extraUpdate=extraUpgrades,highlight=true}.any={omega=0.002*math.mod2Sign(i)}
                    if j%4==0 then
                        wait()
                    end
                end
            end
            if DIFF()>=G.HARD then
                local n=120
                for j=1,n do
                    local angle=math.pi*2/n*j+math.pi/2*1.02 -- start at just past player
                    local xv,yv=math.rTheta2xy(r,angle)
                    local x,y,size=reverse(xv,yv)
                    Bullet{kinematicState={pos={x=x,y=y},speed=0,dir=math.pi/2+angle*3+angle0},lifeFrame=600,sprite=BulletSprites.round.cyan,size=size,extraUpdate=extraUpgrades,highlight=true}.any={omega=0.002*math.mod2Sign(j)}
                    if j%4==0 then
                        wait()
                    end
                end
            end
        end
        local function rays()
            local angle0=math.eval(0,0.1)
            local n=12
            local posb=ball.kinematicState.pos
            local posv=geo:toScreen(posb)[1]
            local screenCenter=geo.viewConfig.screenCenter
            posv.x=posv.x-screenCenter.x
            posv.y=posv.y-screenCenter.y
            for i=1,n do
                local n2=DSWITCH{8,12,16,20}
                for j=1,n2 do
                    local ratio=j/n2
                    local posix,posiy=math.rTheta2xy(geo.r0,(i-0.5)/n*math.pi*2)
                    local vi=math.lerpTable({posix,posiy},{posv.x,posv.y},ratio)
                    local x,y,size=reverse(vi[1],vi[2])
                    local pos={x=x,y=y}
                    local dir=-math.pi/2+(ratio*math.pi/2+math.pi/3)*math.mod2Sign(j)+angle0
                    Bullet{kinematicState={pos=pos,speed=0,dir=dir},lifeFrame=600,sprite=BulletSprites.round.blue,size=size,extraUpdate=extraUpgrades,highlight=true}
                    if j%4==0 then
                        wait()
                    end
                end
            end
        end
        local function nine()
            local angle0=math.eval(0,99)
            local n=DSWITCH{12,18,24,30}
            local span=280
            for row=1,9 do
                local yv=(row-5.5)*40
                for i=1,n do
                    local ratio=((i-0.5)/n-0.5)*2
                    local xv=ratio*span
                    local x,y,size=reverse(xv,yv)
                    local pos={x=x,y=y}
                    local dir=-math.pi/2+ratio*math.pi*math.mod2Sign(row)+angle0
                    dir=math.modClamp(dir,geo:to(pos,ball.kinematicState.pos),1)
                    Bullet{kinematicState={pos=pos,speed=0,dir=dir},lifeFrame=600,sprite=BulletSprites.round.blue,size=size,extraUpdate=extraUpgrades,highlight=true}
                    if i%4==0 then
                        wait()
                    end
                end
            end
        end
        local function squares()
            local r=200
            local angle0=math.eval(0,0.1)
            local anglei=math.pi/12*math.randomSign()
            local ratio=math.cos(math.pi/4)/math.cos(math.pi/4-math.abs(anglei))
            local n0=40
            for i=1,DSWITCH{3,5,7,9} do
                local n=math.ceil(n0)
                for j=1,n do
                    local angle=math.pi*2/n*j+anglei*i
                    local r2,angle2=math.polygonize(4,angle,r,anglei*i)
                    local xv,yv=math.rTheta2xy(r2,angle2)
                    local x,y,size=reverse(xv,yv)
                    local pos={x=x,y=y}
                    local dir=math.pi/2+angle0--+anglei*i
                    Bullet{kinematicState={pos=pos,speed=0,dir=dir},lifeFrame=600,sprite=BulletSprites.round.blue,size=size,extraUpdate=extraUpgrades,highlight=true}.any={omega=0.002*math.mod2Sign(i)}
                    if j%4==0 then
                        wait()
                    end
                end
                r=r*ratio
                n0=n0*ratio
            end
        end
        local patterns={hexagram,rays,DIFF()<=G.NORMAL and squares or nine}
        local index=math.random(1,#patterns)
        local function cloudUpdate(self)
            self.spriteTransparency=math.lerp(self.spriteTransparency,0.15,0.03)
            self.kinematicState.pos.y=math.lerp(self.kinematicState.pos.y,self.any.targetY,0.03)
        end
        local function cloud()
            BulletSpawner{period=2,lifeFrame=120,bulletNumber=4,angle=math.pi/2,range=math.pi*4,bulletLifeFrame=240,bulletSpeed='750+500',highlight=true,bulletSprite=BulletSprites.darkLotus.gray,bulletExtraUpdate={Action.ZoomIn(60,9,nil,true),Action.ZoomOut(30),cloudUpdate},bulletEvents={function (cir,args,self)
                cir.spriteColor={0.5,0.5,1,1}
                cir.forceQuad=true
                cir.safe=true
                cir.any={targetY=math.eval(60,450)}
                cir.lifeFrame=cir.lifeFrame-self.frame
                cir.size=math.eval(1,0.5)
            end}}:bindState(boss)
        end
        for i=1,8 do
            local pos1={x=G.runInfo.player.kinematicState.pos.x,y=0}
            DanmakuFuncs.moveToInTime(ball,pos1,120,Event.sineOProgressFunc)
            cloud()
            SFX:play('enemyCharge')
            wait(60)
            wait(60)
            SFX:play('enemyPowerfulShot')
            Event.LoopEvent{obj=ball,period=1,times=240,executeFunc=function(self,times,maxTimes)
                local x=ball.kinematicState.pos.x
                local aimx=G.runInfo.player.kinematicState.pos.x
                aimx=math.modClamp(aimx,x,geo.a/2)
                local maxSpeed=math.min(12,times/10)
                local lerpSpeed=math.abs(aimx-x)*0.03
                local speed=math.min(maxSpeed,lerpSpeed)
                ball.kinematicState.pos.x=x+speed*math.sign(aimx-x)
            end}
            Event{obj=ball,action=function ()
                playerPos=player.kinematicState.pos
                patterns[index]()
            end}
            index=index%#patterns+1
            wait(120)
            SFX:play('enemyPowerfulShot')
            moveFlag=true
            wait(360)
            moveFlag=false
        end
    end
}