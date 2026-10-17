
local function getBossSpawnPos(self)
    local geo=G.runInfo.geometry
    local playerPos=G.runInfo.player.kinematicState.pos
    local pos,dir=geo:rThetaGo(playerPos,220*math.pi/2,G.runInfo.player.viewDirection-math.pi/2)
    return pos
end
local boss=BossManager.BossSegment{
    bossName='enri',
    key='6-boss',
    BGM='level6b',
    getBossSpawnPos=getBossSpawnPos,
    -- beforeDialogueKey=function ()
    --     return G.runInfo.playerType..'S6BossBefore'
    -- end,
    -- afterDialogueKey=function ()
    --     return G.runInfo.playerType..'S6BossAfter'
    -- end,
    rounds={
        BossManager.BossRound{phases={
            BossManager.NonSpellPhase{
                key='6-boss-enri-non-1',
                time=1800,
                hp=4000,
                func=function(self, boss)
                    local geo=G.runInfo.geometry
                    ---@cast geo Spherical
                    local radius=geo.radius
                    ---@cast geo GeometryBase
                    local fogCenter,fogRadius
                    local signal=false
                    local player=G.runInfo.player
                    local coreExtraUpdate={Action.ZoomIn(20),Action.FadeIn(20,true),Action.FadeOut(20,true),function(self)
                        if signal and not self.flag and self.frame%5==0 and math.abs(fogRadius-geo:distance(fogCenter,self.kinematicState.pos))<25 then
                            self:changeSpriteColor('white')
                            self.flag=true
                            self.kinematicState.speed=0
                            self.kinematicState.dir=geo:to(self.kinematicState.pos,player.kinematicState.pos)
                        end
                        if not self.flag then
                            self.kinematicState.speed=self.kinematicState.speed*0.995
                        else
                            self.kinematicState.speed=math.lerp(self.kinematicState.speed,100,0.01)
                        end
                    end}
                    local petalExtraUpdate={Action.ZoomIn(20),Action.FadeIn(20,true),Action.FadeOut(20,true),function(self)
                        local t=self.frame
                        if signal and not self.flag and t%5==0 and math.abs(fogRadius-geo:distance(fogCenter,self.kinematicState.pos))<25 then
                            self:changeSpriteColor('white')
                            self.flag=true
                            self.kinematicState.speed=50
                            local pos1=boss.kinematicState.pos
                            local pos2=geo:rThetaGo(pos1,radius*math.pi,0)
                            local aim=pos1
                            local distance=geo:distance(self.kinematicState.pos,pos1)
                            local distance2=geo:distance(self.kinematicState.pos,pos2)
                            if distance2>distance then
                                aim=pos2
                            end
                            self.any.aim=aim
                        end
                        if not self.flag then
                            local r,angle,core=self.any.r,self.any.angle,self.any.core
                            if core.flag then
                                return
                            end
                            r=r*(1-math.exp(-t/30))
                            angle=angle+t/60+core.kinematicState.dir
                            self.kinematicState.pos,self.kinematicState.dir=geo:rThetaGo(core.kinematicState.pos,r,angle)
                        elseif not self.flag2 then
                            local aim=self.any.aim
                            local distance=geo:distance(self.kinematicState.pos,aim)
                            local to=geo:to(self.kinematicState.pos,aim)
                            to=math.modClamp(to,self.kinematicState.dir)
                            self.kinematicState.speed=math.lerp(self.kinematicState.speed,math.clamp(9000/distance,100,300),0.01)
                            self.kinematicState.dir=math.lerp(self.kinematicState.dir,to,0.02)
                            if distance<30 then
                                self.lifeFrame=self.frame+10
                                self.flag2=true
                            end
                        end
                    end}
                    local function flower(pos,dir,speed)
                        SFX:play('enemyShot')
                        local core=Bullet{kinematicState={pos=copyTable(pos),dir=dir,speed=speed},sprite=BulletSprites.round.yellow,lifeFrame=600,extraUpdate=coreExtraUpdate,highlight=true}
                        local n=DSWITCH{4,4,4,5}
                        for i=1,n do
                            local angle=i/n*math.pi*2
                            local petal=Bullet{sprite=BulletSprites.egg.red,lifeFrame=600,extraUpdate=petalExtraUpdate,highlight=true}
                            petal.any={core=core,r=20,angle=angle}
                        end
                    end
                    local sentry=DanmakuFuncs.sentry()
                    local function wave()
                        local pos=boss.kinematicState.pos
                        local angle0=math.eval(0,99)
                        local n=DSWITCH{25,30,35,40}
                        Event{obj=sentry,action=function ()
                            for i=1,n do
                                local angle=math.pi*2/n*(i)
                                local r,angle2=math.polygonize(5,angle)
                                local posi=geo:rThetaGo(pos,r*100,angle2+angle0)
                                flower(posi,angle+angle0,(r-0.8)*1200)
                                SFX:play('enemyShot')
                                wait(3)
                            end
                            SFX:play('enemyCharge')
                            wait(60)
                            SFX:play('enemyPowerfulShot')
                            fogCenter=copyTable(boss.kinematicState.pos)
                            fogRadius=0
                            signal=true
                            local fogn=50
                            local speed=250
                            local time=radius*math.pi*60/speed
                            local playerAngle=geo:to(fogCenter,player.kinematicState.pos)
                            for i=1,fogn do
                                local angle=math.pi*2*Event.sineIOProgressFunc(i/fogn)+playerAngle -- more fog at player
                                local speedi=speed*math.eval(1,0.3)
                                Bullet{kinematicState={pos=copyTable(fogCenter),dir=angle,speed=speedi},sprite=BulletSprites.darkLotus.gray,highlight=true,size=math.eval(2.5,1),lifeFrame=time*speed/speedi,extraUpdate={Action.ZoomIn(20),Action.ZoomOut(20)},safe=true,forceQuad=true,spriteTransparency=0.7}.spriteRotationSpeed=math.eval(0,0.07)
                            end
                            for i=1,math.ceil(time) do
                                fogRadius=speed*i/60
                                wait()
                            end
                        end}
                    end
                    for i=1,8 do
                        signal=false
                        wave()
                        wait(500)
                    end
                end
            },
            require('stages.stage6.spellcards.military'),
            require('stages.stage6.spellcards.wind'),
            require('stages.stage6.spellcards.dipper'),
            require('stages.stage6.spellcards.galaxy'),
        }},
    }
}

return boss