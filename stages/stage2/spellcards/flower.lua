---@return SpellcardPhase
return BossManager.SpellcardPhase{
    key='tooshi-flower',SKIP_INCLUDE=true,
    bonusScore=15000,
    time=1800,
    hp=2800,
    dropItems={point=15,powerSmall=10},
    func=function(self, boss)
        local geo=G.runInfo.geometry
        local basePos=geo:init().pos
        local dir=geo:to(boss.kinematicState.pos,basePos)
        local choose=false
        local function generalBind(cir,sprite,size,color,r,theta,sign)
            local chooseRef=choose
            local pos,dir=geo:rThetaGo(cir.kinematicState.pos,r,theta)
            local new=Bullet{kinematicState={pos=pos,dir=dir,speed=0},sprite=sprite,size=size,lifeFrame=cir.lifeFrame+300,highlight=false,forceQuad=true,spriteColor=color,extraUpdate={Action.ZoomIn(20),Action.ZoomOut(20)}}
            DanmakuFuncs.orbitBind(new,cir,function (self, centerObj)
                local rt=1+math.exp(-self.frame/DSWITCH{90,90,90,120})*6
                rt=math.lerp(0,rt,1-math.exp(-self.frame/30))
                return {r=rt*r,theta=theta+self.frame/60*sign}
            end,function(self)
                if chooseRef==true then
                    self.lifeFrame=self.frame+21
                    return
                end
                self.kinematicState.speed=60
            end)
        end
        local c1={196/255,96/255,239/255,1}
        local c2={242/255,129/255,247/255,1}
        local function flowerWrap(cir,angle,size,sign)
            size=size or 1
            sign=sign or 1
            local color=choose and c1 or c2
            for i=1,8 do
                generalBind(cir,BulletSprites.egg.white,3*size,color,50*size,angle+i*math.pi/4,sign)
            end
            -- -- 3 egg shaped petals
            -- for i=-1,1,2 do
            --     generalBind(cir,BulletSprites.egg.white,3*size,{196/255,96/255,239/255,1},50*size,angle+i*math.pi*0.3)
            -- end
            -- generalBind(cir,BulletSprites.egg.white,2*size,{196/255,96/255,239/255,1},30*size,angle)
            -- -- keel
            -- generalBind(cir,BulletSprites.ellipse.white,2*size,{213/255,58/255,245/255,1},15*size,angle+math.pi)
            -- -- sepals
            -- for i=-1,1 do
            --     generalBind(cir,BulletSprites.ellipse.white,1.2*size,{123/255,129/255,50/255,1},60*size,angle+i*math.pi*0.1)
            -- end
        end
        local spawner=BulletSpawner{angle=0,range=math.pi*2,bulletNumber=1,lifeFrame=1800,period=300,firstPeriod=6000,bulletLifeFrame=400,bulletSize=1,bulletSpeed=90,bulletSprite=BulletSprites.round.yellow,highlight=true,bulletEvents={function(cir,args,self)
            local angle=math.eval(0,99)
            flowerWrap(cir,angle,0.5,self.sign)
            cir.dangle=self.dangle
        end},bulletExtraUpdate={function(self)
            self.kinematicState.dir=self.kinematicState.dir-self.dangle
        end}}
        spawner:bindState(boss)
        for _=1,6 do
            choose=true
            local angle=geo:to(boss.kinematicState.pos,G.runInfo.player.kinematicState.pos)+math.eval(0,0.1)
            spawner.bulletNumber=1
            for sign=-1,1,2 do
                spawner.sign=sign
                for i=-5,5 do
                    spawner.dangle=sign*i*0.003
                    spawner.angle=angle-math.pi/30*sign*(i*DSWITCH{1.5,1,0.5,0}+1)
                    spawner:spawnBatchFunc()
                    wait(6)
                end
                wait(60)
            end
            wait(60)
            choose=false
            spawner.angle=math.eval(0,99)
            spawner.bulletNumber=10
            for sign=-1,1,2 do
                spawner.sign=sign
                spawner.dangle=-sign*DSWITCH{0.016,0.015,0.013,'<'}
                spawner:spawnBatchFunc()
                wait(120)
            end
        end
    end
}