---@return SpellcardPhase
return BossManager.SpellcardPhase{
    key='tooshi-lantern',SKIP_INCLUDE=true,
    bonusScore=15000,
    time=1800,
    hp=2800,
    dropItems={point=15,powerSmall=10},
    func=function(self, boss)
        local geo=G.runInfo.geometry
        local basePos=geo:init().pos
        local dir=geo:to(boss.kinematicState.pos,basePos)
        local laserBase=Bullet{kinematicState={pos=copyTable(boss.kinematicState.pos),dir=dir-0.4,speed=0},sprite=BulletSprites.giant.orange,size=2,lifeFrame=1800,invincible=true,highlight=true,extraUpdate={function(self)
            local aim=math.modClamp(G.runInfo.geometry:to(boss.kinematicState.pos,G.runInfo.player.kinematicState.pos),dir)
            dir=math.lerp(dir,aim,0.004)
        end,Action.ZoomIn(20),Action.ZoomOut(20)}}
        DanmakuFuncs.orbitBind(laserBase,boss,function (self, centerObj)
            local r=170*(1-math.exp(-self.frame/120))
            local theta=-0.4*math.cos(self.frame/120)
            return {r=r,theta=dir+theta}
        end)
        local outer=Bullet{sprite=BulletSprites.darkLotus.red,lifeFrame=laserBase.lifeFrame,invincible=true,highlight=true,safe=true,spriteTransparency=1,size=3,extraUpdate={Action.ZoomIn(20),Action.ZoomOut(20)}}
        outer:bindState(laserBase)
        local function ovalRTheta(frame,i,n)
            local r=90*(1.5-0.5*math.cos(frame/150)^3)
            local extraTheta=math.sin(frame/300)*15
            local ovalAngle=-frame/60
            local angle=math.pi*2/n*i-ovalAngle
            local x=r*math.cos(angle)
            local y=r*math.sin(angle)
            local ovalRatio=math.sin(frame/110)*0.15+0.8
            x=x*ovalRatio
            return (x^2+y^2)^0.5,math.atan2(y,x)+ovalAngle+extraTheta
        end
        local speedUpdate=function(self)
            self.kinematicState.speed=math.lerp(self.kinematicState.speed,120,0.05)
        end
        local n=DSWITCH{3,4,4,5}
        for i=1,n do
            local laser=GeoLaser{kinematicState={pos=copyTable(boss.kinematicState.pos),dir=geo:to(boss.kinematicState.pos,G.runInfo.player.kinematicState.pos)+math.pi*2/n*i,speed=0},sprite=BulletSprites.laser.yellow,size=3,rayAngle=0,spriteTransparency=1,safe=false,invincible=true,lifeFrame=laserBase.lifeFrame,meshBudget={capNum=3,step=25,num=6},extraUpdate={GeoLaser.presetActions.laserZoomIn(20),GeoLaser.presetActions.laserZoomOut(20),function(self)
                if laserBase.removed then
                    self:remove()
                    return
                end
                self.kinematicState.pos=copyTable(laserBase.kinematicState.pos)
                local r,theta=ovalRTheta(self.frame,i,n)
                self.kinematicState.dir=theta
                self.meshBudget.step=r/self.meshBudget.num
                self.rayAngle=self:getHitboxRadius()/r*0.3
                if self.frame%(n*DSWITCH{4,2,1.5,1})==i%n then
                    local pos,dir1=geo:rThetaGo(self.kinematicState.pos,r,theta)
                    Bullet{kinematicState={pos=pos,dir=dir1,speed=-10},sprite=BulletSprites.cross.yellow,size=2,lifeFrame=300,highlight=true,forceQuad=true,extraUpdate={Action.FadeIn(10,true),Action.ZoomIn(20,nil,4),Action.ZoomOut(20),speedUpdate}}
                end
            end}}
            laser.checkHitPlayer=function(self)
                local r,theta=ovalRTheta(self.frame,i,n)
                if geo:distance(self.kinematicState.pos,G.runInfo.player.kinematicState.pos)>=r then
                    return
                end
                GeoLaser.checkHitPlayer(self)
            end
        end
    end
}