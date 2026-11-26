---@return SpellcardPhase
return BossManager.LastSpellcardPhase{
    key='kotoba-round',
    bonusScore=20000,
    time=1800,
    hp=3200,
    dropItems={lifePiece=2,bombPiece=2},
    func=function(self, boss)
        boss:addHPProtection(300,5)
        local geo=G.runInfo.geometry
        local center=G.runInfo.geometry:init().pos
        DanmakuFuncs.moveToInTime(boss,center,60,Event.sineOProgressFunc)
        wait(60)
        local period=10
        local time=480
        local bulletNumber=DSWITCH{10,10,10,9,9}
        local powerMap={}
        local bits={}
        local mergeTimes=4
        local num=2^mergeTimes
        for i=1,num do
            local iref=i
            local i2=i-1
            local bit={}
            local acc=2
            for j=1,mergeTimes do
                table.insert(bit,{i2%2,acc})
                i2=math.floor(i2/2)
                acc=acc+6
            end
            bits[i]=bit
            local value=1
            while i%2==0 do
                i=i/2
                value=value*2
            end
            powerMap[iref]=value
        end
        --[[
        t0  10 20 30 40 50 60 70
         0  1  2  3  4  5  6  7
        t40    60    80    100  
         01    23    45    67
        t80          120
         0123        4567
        t160
         01234567
        ]]
        local speed=DSWITCH{60,60,60,80,80}
        local function progressFunc(x)
            return math.min(x*2,2-x*2)
        end
        local dir=0
        local function update(self)
            local index=self.any.index
            local completion=self.any.completion
            if completion<mergeTimes then
                local bit,acc=bits[index][completion+1][1],bits[index][completion+1][2]
                if self.frame==acc*period+self.any.delay then
                    local time=6*period
                    Event.EaseEvent{obj=self,aims={size=self.size+0.25},duration=time}
                    self.any.frame=self.frame
                    if bit==dir then
                        self.any.completion=completion+1
                        return
                    end
                    local distance=math.mod2Sign(dir)*speed*2^(completion+1)*period
                    Event.EaseEvent{obj=self,easeObj=self.kinematicState,aims={speed=self.kinematicState.speed+distance/time},progressFunc=progressFunc,duration=time}
                    SFX:play('enemyShot2')
                    -- self.frame=self.frame+math.ceil(acc*period/2)*math.mod2Sign(dir) -- catch up with the bit=0 group, they are acc*period/2 frames ahead
                    self.any.completion=completion+1
                end
            end
            if completion==mergeTimes and self.frame>self.any.frame+60 then
                self.kinematicState.speed=math.lerp(self.kinematicState.speed,500,0.02)
                local to=geo:to(self.kinematicState.pos,boss.kinematicState.pos)
                to=math.modClamp(to+math.pi/2*(self.any.sign==0 and 1 or self.any.sign),self.kinematicState.dir)
                self.kinematicState.dir=math.lerp(self.kinematicState.dir,to,0.1)
            else
                self.kinematicState.dir=self.kinematicState.dir+self.any.sign*self.kinematicState.speed/10000
            end
        end
        local multiple=DSWITCH{1,1,2,2,3}
        for i=1,10 do
            local to=geo:to(boss.kinematicState.pos,G.runInfo.player.kinematicState.pos)
            local pos=geo:rThetaGo(boss.kinematicState.pos,math.eval(150,35),to+math.mod2Sign(i)*math.eval(math.pi/2,0.5))
            SFX:play('enemyPowerfulShot')
            local color=i%2==1 and 'purple' or 'magenta'
            Bullet{kinematicState={pos=pos,dir=0,speed=0},lifeFrame=1+period*(num-0.5),sprite=BulletSprites.giant[color],extraUpdate={Action.ZoomIn(30),Action.ZoomOut(30),},size=2,highlight=true}
            local spawner=BulletSpawner{kinematicState={pos=pos,dir=0,speed=0},
                period=period,firstPeriod=1,lifeFrame=1+period*(num-0.5),bulletNumber=bulletNumber*multiple,range=math.pi*2*multiple,bulletSpeed=speed,bulletSize=0.5,angle=math.eval(0,99),bulletSprite=BulletSprites.ellipse[color],bulletLifeFrame=time,spawnSFXVolume=2,bulletExtraUpdate={Action.ZoomIn(20,1,3,true),Action.FadeOut(30,true),update},bulletEvents={
                    function(cir,args,self)
                        local i1=args.index
                        local i2=math.ceil(i1/bulletNumber)-multiple/2-0.5
                        if i2~=0 then
                            cir.kinematicState.speed=cir.kinematicState.speed+20*i2
                            Event.EaseEvent{obj=cir,easeObj=cir.kinematicState,aims={speed=cir.kinematicState.speed-20*i2},duration=time/4}
                        end
                        local index=self.spawnTimes
                        local power=powerMap[(index-1)%#powerMap+1]
                        if args.index==1 then
                            self.angle=self.angle+math.pi/bulletNumber/power
                        end
                        cir.lifeFrame=cir.lifeFrame+(num-index)*period
                        cir.any={index=index,completion=0,delay=(num-index)*period,sign=DIFF()<=G.HARD and 0 or math.mod2Sign(math.ceil(i/2))}
                    end
                }
            }
            if DIFF()<=G.HARD or i%2==0 then
                wait(300)
            else
                wait(DSWITCH{60,60,60,60,30})
            end
        end
    end
}