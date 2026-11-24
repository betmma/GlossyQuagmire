local setZoomSpeed=require('stages.stage2.setZoomSpeed')

---@return SpellcardPhase
return BossManager.LastSpellcardPhase{
    key='tooshi-scroll',SKIP_INCLUDE=true,
    bonusScore=30000,
    time=1800,
    hp=2800,
    dropItems={lifePiece=2,bombPiece=2},
    func=function(self, boss)
        boss.kinematicState.skipZoom=true
        local geo=G.runInfo.geometry
        local basePos=geo:init().pos
        local sentry=DanmakuFuncs.sentry()
        sentry.remove=function (self)
            setZoomSpeed(0,60)
            Bullet.remove(sentry)
        end
        local scroll=0
        wait(60)
        local spawners={}
        local function getBulletSpawner(pos)
            local spawner=BulletSpawner{kinematicState={pos=pos,dir=0,speed=0,skipZoom=true},angle='player',range=math.pi,bulletNumber=DSWITCH{7,7,7,7,5},lifeFrame=1800,period=DSWITCH{6,6,5,6,9},bulletLifeFrame=400,bulletSize=1,bulletSpeed=200,bulletSprite=BulletSprites.egg.orange,highlight=true,bulletEvents={function(cir,args,self)
                if args.index==1 then
                    self.polygonN=3
                    self.polygonAngle=(self.polygonAngle or math.eval(0,1))+0.1
                end
                local angle=cir.kinematicState.dir-self.polygonAngle
                local angle2=angle%(math.pi*2/self.polygonN)-(math.pi/self.polygonN)
                cir.kinematicState.speed=(cir.kinematicState.speed-scroll*12000)/math.cos(angle2)
                local v=math.clamp(200/cir.kinematicState.speed,0,1)
                cir.spriteColor={1,v,v,1}
            end},bulletExtraUpdate={Action.ZoomIn(30),Action.ZoomOut(15)}}
            table.insert(spawners,spawner)
            return spawner
        end
        if DIFF()<=G.LUNATIC then
            getBulletSpawner(copyTable(boss.kinematicState.pos))
        else
            for i=-1,1,2 do
                local pos=geo:rThetaGo(boss.kinematicState.pos,100,geo:to(boss.kinematicState.pos,basePos)+math.pi/4*i)
                getBulletSpawner(pos)
            end
        end
        local scrollMult=DSWITCH{0.008,0.010,0.012,0.015}
        local val=DSWITCH{0,0.05,0.15,0.2}
        Event.LoopEvent{obj=sentry,period=1,executeFunc=function(self,times)
            times=boss.frame
            local sin=math.sin(times/30)
            scroll=sin*scrollMult
            setZoomSpeed(scroll,0)
            for index, value in ipairs(spawners) do
                value.range=math.pi*(1-val-val*sin)
            end
        end}
    end
}