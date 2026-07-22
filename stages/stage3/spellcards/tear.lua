---@return SpellcardPhase
return BossManager.SpellcardPhase{
    key='kora-tear',SKIP_INCLUDE=true,
    bonusScore=20000,
    time=1201,
    isTimeout=true,
    hp=4200,
    dropItems={powerSmall=15,point=15},
    func=function(self, boss)
        Event.EaseEvent{obj=boss,aims={spriteTransparency=0},duration=60}
        boss.safe=true
        local geo=G.runInfo.geometry
        local basePos=geo:init().pos
        local player=G.runInfo.player
        ---@cast player Player
        local sentry=DanmakuFuncs.sentry(basePos)
        local time=120
        local followTime=60
        local update={Action.ZoomIn(20),Action.FadeOut(20,true)}
        local warningupdate=function (self)
            if self.frame<followTime then
                self.kinematicState.pos=geo:rThetaGo(player.kinematicState.pos,self.j*(self.frame*DSWITCH{0.8,0.7,0.6,0.5}),self.dir2+player.viewDirection)
            end
            self.kinematicState.dir=math.pseudoRandom(self.frame)*math.pi*2
            self.kinematicState.speed=self.frame*0.5
            if self.frame==self.lifeFrame-1 and geo:distance(basePos,self.kinematicState.pos)<550 then
                local sign=-1
                if math.angleDiff(self.dir2+player.viewDirection+math.pi/2,geo:to(self.kinematicState.pos,player.kinematicState.pos))<math.pi/2 then
                    sign=1
                end
                local angle=self.dir2+player.viewDirection+sign*(math.pi/2-math.pi/60*self.j)
                for i=1,math.min(math.ceil(sentry.frame/60/5),DSWITCH{1,2,3,4}) do
                    Bullet{kinematicState={pos=copyTable(self.kinematicState.pos),speed=(i-0.5)*30,dir=angle},sprite=BulletSprites.stick[self.color],lifeFrame=600,highlight=true,extraUpdate=update}
                end
            end
        end
        local colors={'red', 'yellow', 'green', 'cyan', 'blue', 'purple'}
        for i=1,19 do
            local color=colors[i%#colors+1]
            local pos=player.kinematicState.pos
            local dir=math.eval(0,999)
            SFX:play('enemyCharge')
            -- warning
            Event{action=function()
                for x=1,time do
                    Mirror.setHSV({(i-1+x/time)/6,1,1},1/6)
                    wait()
                end
            end}
            for j=-20,20 do
                local pos2,dir2=pos,dir
                local warning=Bullet{kinematicState={pos=copyTable(pos2),speed=0,dir=dir2},sprite=BulletSprites.cross.white,lifeFrame=time,size=2,invincible=true,safe=true,spriteColor={1,0.3,0.3,0.5},extraUpdate={Action.ZoomIn(20,nil,4),Action.FadeIn(20,false),warningupdate}}
                warning.dir2=dir2
                warning.j=j
                warning.color=color
            end
            wait(followTime)
            pos=player.kinematicState.pos
            SFX:play('enemyCharge')
            wait(time-followTime)
            SFX:play('enemyPowerfulShot')
            local pos1=geo:rThetaGo(pos,-600,dir)
            local pos2=geo:rThetaGo(pos,600,dir)
            local mirror=Mirror(pos1,pos2,copyTable(player.kinematicState.pos), {lifeFrame=479,extraUpdate={function(self)
                if sentry.removed then
                    self:remove()
                end
            end}})
        end
    end
}