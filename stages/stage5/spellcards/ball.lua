---@return SpellcardPhase
return BossManager.SpellcardPhase{
    key='tatsu-ball',SKIP_INCLUDE=true,
    bonusScore=40000,
    time=1800,
    hp=2200,
    dropItems={powerSmall=20,point=20},
    func=function(self, boss)
        local geo=G.runInfo.geometry
        ---@cast geo Cylinder
        local ball=boss.any.getBall(boss)
        local function laser(pos,dir,color,time,life)
            time=time or 60
            life=life or 120
            local lase=GeoLaser{kinematicState={pos=copyTable(pos),dir=dir,speed=0},sprite=BulletSprites.laser[color],size=3,rayAngle=0.04,spriteTransparency=0.3,safe=true,invincible=true,lifeFrame=life,meshBudget={capNum=2,step=80,num=10},spriteColor={1,0.7,0.7,1},extraUpdate={GeoLaser.presetActions.laserZoomIn(22),GeoLaser.presetActions.laserZoomOut(20),function(self)
                if self.frame==time-10 then
                    Event.EaseEvent{obj=self,duration=20,aims={size=0.1},progressFunc=Event.sineBackProgressFunc}
                end
                if self.frame==time then
                    SFX:play('enemyPowerfulShot',nil,0.3)
                    self.safe=false
                end
                if time<=self.frame and self.frame<time+10 then
                    self.spriteTransparency=self.spriteTransparency+(1-0.3)/10
                end
            end}}
        end
        local limit=250
        local speed0=900
        local dangle=DSWITCH{0.2,0.2,math.atan(math.pi/2.5),math.atan(math.pi/5.5)}
        -- bounce
        ball.extraUpdate[#ball.extraUpdate+1] = function (self)
            for sign=-1,1,2 do
                local vx,vy=math.rTheta2xy(self.kinematicState.speed,self.kinematicState.dir)
                if math.sign(self.kinematicState.pos.y-limit*sign)==sign and math.sign(vy)==sign then -- out of range, and moving outward
                    local color=sign>0 and 'red' or 'blue'
                    vy=-vy
                    self.kinematicState.speed,self.kinematicState.dir=math.xy2rTheta(vx,vy)
                    self.kinematicState.pos.y=(limit*sign*2)-self.kinematicState.pos.y
                    if DIFF()<=G.NORMAL then
                        self.kinematicState.speed=math.lerp(self.kinematicState.speed,speed0,0.15)
                    end
                    self.spriteRotationSpeed=-self.spriteRotationSpeed
                    -- visual effect
                    Effect.Larger{kinematicState={pos=copyTable(self.kinematicState.pos),dir=0,speed=0},sprite=BulletSprites.shockwave[color],size=0,growSpeed=0.1,animationFrame=30,spriteTransparency=0.8}
                    -- bounce bullets
                    local dir=-sign*math.pi/2
                    local pos=geo:rThetaGo({x=self.kinematicState.pos.x,y=limit*sign},50,-dir)
                    if DIFF()<=G.NORMAL then
                        laser(pos,dir,color)
                    else
                        for side=-1,1,2 do
                            laser(pos,dir+dangle*side/2,color)
                        end
                    end
                    BulletSpawner{kinematicState={pos=pos,dir=0,speed=0},period=9,lifeFrame=2,firstPeriod=1,bulletNumber=30,angle=dir+math.eval(0,0.1),range=math.pi,bulletSpeed=100,bulletSprite=BulletSprites.round[color],bulletExtraUpdate={Action.ZoomIn(20),Action.ZoomOut(20),function (self)
                        self.kinematicState.speed=self.kinematicState.speed+0.3
                    end},bulletLifeFrame=300,bulletEvents={function (cir,args,self)
                        local index=args.index
                        local m=(index-1)%3-1
                        cir.kinematicState.dir=cir.kinematicState.dir-m*self.range/self.bulletNumber*0.9
                        local group=math.ceil(index/3)
                        if (m==0)==(false) then
                            cir.kinematicState.speed=cir.kinematicState.speed*0.97
                        end
                        local angle=math.modClamp(cir.kinematicState.dir)
                        cir.lifeFrame=math.abs(1/math.clamp(math.tan(angle),0.5,10))*150+100
                    end}}
                end
            end
        end
        local sign=math.randomSign()
        for i=1,8 do
            local pos1={x=G.runInfo.player.kinematicState.pos.x,y=0}
            DanmakuFuncs.moveToInTime(ball,pos1,120,Event.sineOProgressFunc)
            wait(120)
            SFX:play('enemyCharge')
            local speed=DSWITCH{2000,3500,3000,3000}
            local dir=math.mod2Sign(i)*sign*dangle-math.pi/2
            local time=400
            if DIFF()>=G.HARD then
                -- hint the trace
                local dist=speed*time/60
                local pos=copyTable(pos1)
                Event{obj=ball,action=function ()
                    local n=200
                    for j=1,n do
                        local p=geo:rThetaGo(pos,dist/n*j,dir)
                        local v=p.y+limit
                        local div,mod=math.ceil(v/(limit*2)),v%(limit*2)
                        mod=mod-limit
                        local dirj=dir
                        if div%2==0 then
                            mod=-mod
                            dirj=-dirj
                        end
                        Bullet{kinematicState={pos={x=p.x,y=mod},dir=dirj,speed=0},safe=true,lifeFrame=time/n*j-j+60,spriteColor={1,0.3,0.3,0.5},sprite=BulletSprites.stick.red,size=4,forceQuad=true,extraUpdate={Action.FadeIn(5,false)}}
                        wait()
                    end
                end}
            end
            wait(60)
            SFX:play('enemyPowerfulShot')
            ball.kinematicState.speed=speed
            ball.kinematicState.dir=dir
            boss:addHPProtection(300,3)
            wait(time)
            ball.kinematicState.speed=0
        end
    end
}