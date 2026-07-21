---@return SpellcardPhase
return BossManager.SpellcardPhase{
    key='kora-self',SKIP_INCLUDE=true,
    bonusScore=20000,
    time=1800,
    hp=4200,
    dropItems={powerSmall=15,point=15},
    func=function(self, boss)
        local geo=G.runInfo.geometry
        local basePos=geo:init().pos
        local player=G.runInfo.player
        ---@cast player Player
        local sentry=Bullet{kinematicState={pos=copyTable(basePos),speed=0,dir=0},sprite=BulletSprites.round.red,lifeFrame=99999,invincible=true,safe=true,spriteTransparency=0}
        Event.LoopEvent{obj=sentry,period=80,executeFunc=function (self, index, total)
            local dir=player.viewDirection-math.pi/2
            local pos=geo:rThetaGo(player.kinematicState.pos,250,dir)
            DanmakuFuncs.moveToInTime(boss,pos,60,Event.sineOProgressFunc)
        end}
        SFX:play('enemyCharge')
        Mirror.setHSV({0,0,1},0)
        local mirrorn=4
        local r0=600
        local r1=DSWITCH{150,100,80,60}
        for i=1,mirrorn do
            local angle=math.pi*2/mirrorn*i+player.viewDirection
            local pos1=geo:rThetaGo(player.kinematicState.pos,r0,angle-math.pi/mirrorn)
            local pos2=geo:rThetaGo(player.kinematicState.pos,r0,angle+math.pi/mirrorn)
            Mirror(pos1,pos2,player.kinematicState.pos,{lifeFrame=99999,extraUpdate={Action.FadeIn(20,false,1),Action.FadeOut(20,false),function(self)
                local r=math.lerp(r0,r1,1-math.exp(-self.frame/30))
                local playerPos=player.kinematicState.pos
                if G.runInfo.geometry==G.geometries.Euclidean then
                    playerPos=copyTable(playerPos)
                    local edge=r1/2+20
                    playerPos.x=math.clamp(playerPos.x,edge,500-edge)
                    playerPos.y=math.clamp(playerPos.y,edge,600-edge)
                end
                angle=math.pi*2/mirrorn*i+player.viewDirection
                self.pos1,self.pos2,self.posIn=geo:rThetaGo(playerPos,r,angle-math.pi/mirrorn),geo:rThetaGo(playerPos,r,angle+math.pi/mirrorn),playerPos
                if sentry.removed and not self.flag then
                    self.flag=true
                    self.lifeFrame=self.frame+20
                end
            end}})
        end
        local bias=math.random(1,99)
        Event.LoopEvent{obj=sentry,period=DSWITCH{120,100,80,60},firstPeriod=10,executeFunc=function (self, index, total)
            SFX:play('enemyShot')
            local pos0,dir0=geo:rThetaGo(basePos,500,player.viewDirection-math.pi/2)
            local tiltN=4
            local a,b=math.ceil(index/tiltN),DSWITCH{0,2,4,6}
            local side=math.mod2Sign(a)
            dir0=dir0+side*math.pi/2
            local m,n=8,2
            bias=bias+math.ceil(math.eval(m/2,m/4))
            for i=-20,20 do
                local pos,dir=geo:rThetaGo(pos0,i*15,dir0)
                dir=dir+side*math.pi/2
                local f=i*b+50
                if (i+bias)%m<n then
                    goto continue
                end
                local bullet=Bullet{kinematicState={pos=pos,speed=0,dir=dir},sprite=BulletSprites.bigRound[side==1 and 'red' or 'blue'],lifeFrame=f+400,extraUpdate={function(self)
                    if self.frame==f then
                        self.kinematicState.speed=400
                    elseif self.frame>f then
                        self.kinematicState.speed=math.lerp(self.kinematicState.speed,50,0.02)
                    end
                end,Action.ZoomIn(20)}}
                ::continue::
            end
        end}
    end
}