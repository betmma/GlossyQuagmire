---@return SpellcardPhase
return BossManager.SpellcardPhase{
    key='kotoba-swallow',
    bonusScore=10000,
    time=1800,
    hp=2400,
    func=function(self,boss)
        local bossPos=boss.kinematicState.pos
        local base=G.runInfo.geometry:init().pos
        local bossAim=G.runInfo.geometry:rThetaGo(base,200,G.runInfo.player.viewDirection-math.pi/2)
        local aim=G.runInfo.geometry:rThetaGo(base,200,G.runInfo.player.viewDirection+math.pi/2)
        ---@type Player
        local player=G.runInfo.player
        local mouthBase=Bullet{kinematicState={pos=copyTable(aim),speed=0,dir=player.viewDirection},sprite=BulletSprites.scale.red,invincible=true,safe=true,lifeFrame=1800,spriteTransparency=0}
        mouthBase.openness=1
        local xmax=400
        local y=0
        local swallowing=false
        local teethUpdate=function(self)
            if mouthBase.removed then
                self:remove()
                return
            end
            local angle=self.i/50*math.pi/2
            local x=math.sin(angle)*xmax
            y=(mouthBase.openness+0.1)*400+0.001
            local pos1,dir1=G.runInfo.geometry:rThetaGo(mouthBase.kinematicState.pos,x,mouthBase.kinematicState.dir)
            dir1=dir1-self.side*math.pi/2
            local targetPos,targetDir=G.runInfo.geometry:rThetaGo(pos1,y,dir1)
            targetDir=targetDir-math.pi
            self.kinematicState.pos,self.kinematicState.dir=targetPos,targetDir
            Bullet{kinematicState={pos=copyTable(self.kinematicState.pos),dir=self.kinematicState.dir,speed=0},sprite=BulletSprites.scale.red,size=2,invincible=true,safe=true,highlight=true,lifeFrame=5,extraUpdate={Action.FadeOut(5,false)}} -- visual trail
        end
        for i=-50,50 do
            for side=-1,1,2 do
                local teeth=Bullet{kinematicState=copyTable(mouthBase.kinematicState),sprite=BulletSprites.scale.red,size=2,invincible=true,safe=false,highlight=true,lifeFrame=1800,spriteTransparency=0,extraUpdate={teethUpdate,Action.FadeIn(60,true)}}
                teeth.i=i
                teeth.side=side
            end
        end
        Event{obj=mouthBase,action=function()
            while true do
                wait(120)
                SFX:play('enemyCharge',true)
                swallowing=true
                for i=1,60 do
                    local r=i/60
                    mouthBase.openness=1-r^2
                    wait()
                end
                swallowing=false
                SFX:play('enemyCharge',true)
                wait(60)
                SFX:play('enemyPowerfulShot',true)
                Event{obj=mouthBase,action=function()
                    wait(20)
                    local direction=G.runInfo.geometry:to(mouthBase.kinematicState.pos,aim)+math.eval(0,1)
                    local dist=math.eval(100,50)
                    local pos0=copyTable(mouthBase.kinematicState.pos)
                    local dirOffset=math.eval(0,0.5)
                    local lastr=0
                    for i=1,120 do
                        local r=Event.sineIOProgressFunc(i/120)
                        mouthBase.kinematicState.pos=G.runInfo.geometry:rThetaGo(pos0,dist*r,direction)
                        mouthBase.kinematicState.dir=mouthBase.kinematicState.dir+dirOffset*(r-lastr)
                        lastr=r
                        wait()
                    end
                end}
                for i=1,60 do
                    local r=i/60
                    mouthBase.openness=r
                    wait()
                end
            end
        end}
        local function speedup(self)
            if self.kinematicState.speed<100 then
                self.kinematicState.speed=self.kinematicState.speed+1
            end
        end
        local function birdUpdate(self)
            if not swallowing then
                return
            end
            local point=G.runInfo.geometry:rThetaGo(mouthBase.kinematicState.pos,100,mouthBase.kinematicState.dir)
            local nearestToLine=G.runInfo.geometry:nearestToLine(self.kinematicState.pos,point,mouthBase.kinematicState.pos)
            local distx=G.runInfo.geometry:distance(nearestToLine,mouthBase.kinematicState.pos)
            local disty=G.runInfo.geometry:distance(nearestToLine,self.kinematicState.pos)
            if distx<xmax and math.abs(disty-y)<20 then
                self:remove()
                local dir=math.eval(0,999)
                local spawner=BulletSpawner{kinematicState={pos=copyTable(self.kinematicState.pos),dir=self.kinematicState.dir,speed=0},period=3,lifeFrame=7,bulletNumber=6,bulletSpeed=20,range=math.pi*2,angle=dir,bulletSprite=BulletSprites.ellipse.black,bulletLifeFrame=600,highlight=true,bulletEvents={function(cir,args)
                    cir.forceQuad=true
                end},bulletExtraUpdate={speedup}}
                Event{obj=spawner,action=function()
                    wait(4)
                    spawner.bulletSprite=BulletSprites.arrow.black
                    spawner.bulletSize=2
                end}
            end
        end
        BulletSpawner{kinematicState=boss.kinematicState,period=120,firstPeriod=30,lifeFrame=6000,bulletNumber=2,bulletSpeed=200,range=math.pi*0.7,bulletSize=1,angle='player',bulletSprite=BulletSprites.bigRound.black,bulletLifeFrame=120,bulletExtraUpdate={Action.FadeOut(30,false)},bulletEvents={function(cir,args)
            cir.spriteColor={0.3,0.3,0.3}
            BulletSpawner{kinematicState=cir.kinematicState,period=20,lifeFrame=100,bulletNumber=4,bulletSpeed=200,range=math.pi*1.2,angle='player',bulletSprite=BulletSprites.bird.black,bulletLifeFrame=600,bulletExtraUpdate={birdUpdate}}:bindState(cir)
        end}}
    end
}