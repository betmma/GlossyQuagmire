---@return SpellcardPhase
return BossManager.SpellcardPhase{
    key='kora-world',SKIP_INCLUDE=true,
    bonusScore=20000,
    time=3000,
    hp=7200,
    dropItems={powerSmall=15,point=15},
    func=function(self, boss)
        Event.EaseEvent{obj=boss,aims={spriteTransparency=1},duration=60,afterFunc=function()
            boss.safe=false
        end}
        local geo=G.runInfo.geometry
        local basePos=geo:init().pos
        local pos1,dir1=geo:rThetaGo(basePos,300,G.runInfo.player.viewDirection-math.pi/2)
        DanmakuFuncs.moveToInTime(boss,pos1,60,Event.sineOProgressFunc)
        local pos2,dir2=geo:rThetaGo(basePos,200,G.runInfo.player.viewDirection-math.pi/2)
        local player=G.runInfo.player
        ---@cast player Player
        local sentry=DanmakuFuncs.sentry(basePos)
        wait(60)
        local bullets={}
        local sprites={BulletSprites.scale.black,BulletSprites.rimDark.white,BulletSprites.bigRound.black}
        local rand=math.eval(0,99)
        for i=1,3 do
            local bullet=Bullet{kinematicState={pos=copyTable(pos2),speed=0,dir=0},sprite=sprites[i],lifeFrame=99999,invincible=true,extraUpdate={Action.FadeOut(20,true),function(self)
                if self.mirrored then
                    if not self.flag then
                        self.safe=true
                        self.spriteTransparency=0.5
                        self.lifeFrame=self.frame+600
                        self.flag=self.frame
                    elseif self.frame>self.flag+120 then
                        self.safe=false
                        if self.frame==self.flag+121 then
                           self.spriteTransparency=1 
                        end
                        self.kinematicState.speed=math.lerp(self.kinematicState.speed,90-i*10,0.01)
                    else
                        -- self.kinematicState.dir=self.kinematicState.dir+rand%0.01
                    end
                end
                if self.frame%50==1 and geo:distance(self.kinematicState.pos,pos2)>500 then
                    self:remove()
                end
            end}}
            table.insert(bullets, bullet)
        end
        local bulletPosFunctions={
            function(t)
                local r=10
                local angle=rand*2+t*math.pi/2*(rand%1>0.5 and 1 or -1)
                local ret={}
                for i=1,3 do
                    local pos=geo:rThetaGo(pos2,(r+i*10)*(1-t*t),angle+math.pi*2/3*(i-1))
                    table.insert(ret,pos)
                end
                return ret
            end,
            function(t)
                local angle=rand*2
                local ret={}
                for i=1,3 do
                    local r=30*math.sin(math.pi*2*t+math.pi*2/3*(i-1))
                    local pos=geo:rThetaGo(pos2,r,angle+math.pi*2/3*(i-1))
                    table.insert(ret,pos)
                end
                return ret
            end,
            function(t)
                local r=50
                local angle=rand*2+t*math.pi*2*(rand%1>0.5 and 1 or -1)
                local ret={}
                for i=-1,1 do
                    local pos=geo:rThetaGo(pos2,r*i,angle)
                    table.insert(ret,pos)
                end
                return ret
            end,
        }
        local mirrorPointFunctions={
            function(t)
                local r=300*(1-Event.sineOProgressFunc(t)*0.92)
                local angle=rand+t*math.pi/2*(rand%1>0.5 and 1 or -1)
                local ret={}
                for i=1,3 do
                    local pos=geo:rThetaGo(pos2,r,angle+math.pi*2/3*(i-1))
                    table.insert(ret,pos)
                end
                return ret
            end,
            function(t)
                local r=100
                local angle=rand
                local ret={}
                for i=1,3 do
                    local pos=geo:rThetaGo(pos2,r,angle+math.pi*2/3*(i-1)+math.pi/4*math.clamp(t*3-i+1,0,1))
                    table.insert(ret,pos)
                end
                return ret
            end,
            function(t)
                local r=100*(1+t)
                local angle=rand
                local posa,dira=geo:rThetaGo(pos2,r,angle+math.pi)
                local posb,dirb=geo:rThetaGo(pos2,r/2,angle)
                local ret={posa}
                local r2=100/1.73*(1-t*0.6)
                for i=1,2 do
                    local pos=geo:rThetaGo(posb,r2,dirb+math.pi/2*math.mod2Sign(i))
                    table.insert(ret,pos)
                end
                return ret
            end,
            function(t)
                local r=100*(1-t*0.6)
                local angle=rand
                local posa,dira=geo:rThetaGo(pos2,r,angle+math.pi)
                local posb,dirb=geo:rThetaGo(pos2,r/2,angle)
                local ret={posa}
                local r2=100/1.73*(1+t)
                for i=1,2 do
                    local pos=geo:rThetaGo(posb,r2,dirb+math.pi/2*math.mod2Sign(i))
                    table.insert(ret,pos)
                end
                return ret
            end
        }
        local t=600
        local tm=180
        for i=1,30 do
            rand=math.eval(0,99)
            local mirrorFunction=mirrorPointFunctions[math.random(1,#mirrorPointFunctions)]
            local pos0s=mirrorFunction(0)
            Mirror.setHSV({math.eval(0,1),0.4,1},0.2)
            for i=1,#pos0s do
                local p1,p2=pos0s[i],pos0s[(i%#pos0s)+1]
                Mirror(p1,p2,pos2, {lifeFrame=tm+20,extraUpdate={Action.FadeIn(90,false,0.5),Action.FadeOut(20,false),function(self)
                    local poses=mirrorFunction(math.min(self.frame/tm,1))
                    self.pos1,self.pos2=poses[i],poses[(i%#poses)+1]
                    if sentry.removed and not self.flag then
                        self.flag=true
                        self.lifeFrame=self.frame+20
                    end
                end}})
            end
            local bulletFunction=bulletPosFunctions[math.random(1,#bulletPosFunctions)]
            Event.LoopEvent{obj=sentry,period=1,times=tm+20,executeFunc=function (self, index, total)
                local poses=bulletFunction(index/tm)
                for i=1,#poses do
                    local currentPos=bullets[i].kinematicState.pos
                    local targetPos=poses[i]
                    if index>tm then
                        targetPos=pos2
                    end
                    local dir=geo:to(currentPos,targetPos)
                    local newPos,newDir=geo:rThetaGo(currentPos,math.min(geo:distance(currentPos,targetPos),math.min(5,index/5)),dir)
                    bullets[i].kinematicState.pos=newPos
                    bullets[i].kinematicState.dir=newDir
                    if index>DSWITCH{150,110,100,20} and index%60>=40 and (index+1)%(i*4)==0 then
                        Mirror.spawnReflections(bullets[i],39)
                        SFX:play('enemyShot')
                    end
                end
            end}
            wait(t)
        end
    end
}