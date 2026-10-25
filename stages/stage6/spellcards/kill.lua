---@return SpellcardPhase
return BossManager.SpellcardPhase{
    key='enri-kill',
    bonusScore=50000,
    time=2400,
    hp=4000,
    dropItems={powerSmall=30,point=15},
    func=function(self, boss)
        boss:addHPProtection(300,5)
        local geo=G.runInfo.geometry
        ---@cast geo Spherical
        local radius=geo.radius
        ---@cast geo GeometryBase
        local n2=5
        local n1=DSWITCH{10,20,30,40}
        local group1=5
        --- the classic rearrange. bullets start with many small circles, then become overlapping big 8 shapes that rotate fast forcing player to follow the rotation, then become small circles again.
        local function getLayerUpdate(r1,r2,rperiod,rphase,omega,halfFlip)
            local function ret(self)
                local parent,angle=self.any.parent,self.any.angle
                local t=self.frame
                local r1a,r2a=self.any.r1a or 0,self.any.r2a or 0
                local phase=t/rperiod*math.pi*2+rphase
                local sin=math.sin(phase)
                local r=math.lerp(r1+r1a,r2+r2a,sin/2+0.5)
                r=r*(1-math.exp(-t/60))
                local flip=math.sign(math.sin(phase/2))
                if halfFlip then
                    if sin>0 and self.any.index%2==1 then
                        flip=-flip
                    end
                end
                self.any.angle=self.any.angle+omega*math.abs(sin)*flip
                local angle0=angle+parent.kinematicState.dir
                local pos,dir=geo:rThetaGo(parent.kinematicState.pos,r,angle0)
                self.kinematicState.pos,self.kinematicState.dir=pos,dir-angle0
                -- if self.any.i then
                --     self.kinematicState.dir=dir
                -- end
            end
            return ret
        end
        local r1=math.pi/2*radius
        -- local colors={'red','green','blue'}
        local period=900
        local phase=math.pi/2-0.25
        local layerUpdates={getLayerUpdate(400,r1,period,phase,math.pi/450,DIFF()>=G.HARD)}
        local bulletUpdate={Action.FadeIn(60,true),Action.FadeOut(20,true),getLayerUpdate(r1,15,period,phase,-0.019,false),function (self)
            local t=self.frame
            local sin=math.sin(t/period*math.pi*2+phase)
            local i,j=self.any.i,self.any.index
            local r1,g1,b1
            if sin>0 then
                r1,g1,b1=math.hsvToRgb((i%group1+0.5)/group1-0.5,0.5,1)
            else
                r1,g1,b1=math.hsvToRgb((j+0.5)/n2-0.5,0.3,1)
            end
            local sinabs=math.abs(sin)
            local color=math.lerpTable({1,1,1,1},{r1,g1,b1,1},sinabs)
            self.spriteColor=color
        end}
        local function spawn()
            local spawner=BulletSpawner{lifeFrame=9999,period=9999,bulletNumber=5,angle='player',range=math.pi*1.2,bulletSpeed=100,bulletSprite=BulletSprites.lightRound.white,highlight=true,bulletLifeFrame=200,bulletExtraUpdate={Action.ZoomIn(15),Action.ZoomOut(15)},bulletEvents={function (cir,args,self)
                local t=self.frame
                local sin=math.sin(t/period*math.pi*2+phase)
                local speed=525-375*sin
                cir.kinematicState.speed=speed
                cir.lifeFrame=10+radius*math.pi/speed*60
                Bullet{lifeFrame=cir.lifeFrame-10,sprite=BulletSprites.darkLotus.gray,highlight=true,size=-sin*1.0+1.7,forceQuad=true,safe=true,spriteRotationSpeed=0.07,spriteTransparency=0.5}:bindState(cir)
            end}}
            spawner:bindState(boss)
            local accumulate=0.01
            Event.LoopEvent{obj=spawner,period=1,executeFunc=function (self, index, total)
                local sin=math.sin(index/period*math.pi*2+phase)
                local newAccumulate=accumulate+DSWITCH{0,0,0.17,0.34}/(5+sin*4)^2
                if math.ceil(newAccumulate)~=math.ceil(accumulate) then
                    spawner.range=math.pi*(1.5+0.5*sin)
                    spawner:spawnBatchFunc()
                end
                accumulate=newAccumulate
                -- difficult to hit the boss, so turn player's view angle towards boss to let player hit
                if sin<-0.5 then
                    local to=geo:to(G.runInfo.player.kinematicState.pos,boss.kinematicState.pos)+math.pi/2
                    if DIFF()>=G.LUNATIC then -- add some shakes (i'm evil c:)
                        to=to+math.sin(index/20)*(-sin-0.5)*DSWITCH{'>','>','>',1.3,1.7}
                    end
                    local viewDirection=G.runInfo.player.viewDirection
                    to=math.modClamp(to,viewDirection)
                    G.runInfo.player.viewDirection=math.lerp(viewDirection,to,(-sin-0.5)*0.1)
                end
            end}
            SFX:play('enemyPowerfulShot')
            local pos=copyTable(boss.kinematicState.pos)
            local core=DanmakuFuncs.sentry(pos)
            local angle1=math.eval(0,math.pi)
            local angle2=math.eval(0,math.pi)
            for i=1,n1 do
                local anglei1=angle1+math.pi*2/n1*i
                local sentry1=DanmakuFuncs.sentry(pos)
                --Bullet{kinematicState={pos=pos,dir=0,speed=0},sprite=BulletSprites.scale.white,lifeFrame=9999}
                sentry1.any={parent=core,angle=anglei1,r2a=((i%group1+0.5)/group1-0.5)*600,index=i}
                sentry1.extraUpdate={layerUpdates[1]}
                for j=1,n2 do
                    local anglei2=angle2+math.pi*2/n2*j
                    local sentry2=Bullet{kinematicState={pos=pos,dir=0,speed=0},sprite=BulletSprites.round.black,lifeFrame=9999,extraUpdate=bulletUpdate}
                    sentry2.any={parent=sentry1,angle=anglei2,r2a=0,index=j,i=i} --(math.pseudoRandom(i)*2-1)*1
                    -- sentry2.extraUpdate=bulletUpdate
                end
            end
        end
        wait(60)
        spawn()
    end
}