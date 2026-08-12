local midboss=BossManager.BossSegment{
    bossName='shouji',
    key='4-mid',
    getBossSpawnPos=function(self)
        local geo=G.runInfo.geometry
        local playerPos=G.runInfo.player.kinematicState.pos
        Portal.setOuterPortals(playerPos)
        local pos,dir=geo:rThetaGo(playerPos,200,G.runInfo.player.viewDirection-math.pi/2)
        return pos
    end,
    rounds={
        BossManager.BossRound{phases={
            BossManager.NonSpellPhase{
                key='4-mid-shouji-non-1',
                time=1500,
                hp=1800,
                dropItems={point=15,powerSmall=15},
                func=function(self, boss)
                    boss.showHexagram=false
                    boss:addHPProtection(600,10)
                    -- BGM.data[BGM.currentAudio]:seek(52.2,'seconds')
                    local geo=G.runInfo.geometry
                    ---@cast geo PortalGeometryBase
                    local pos0=boss.kinematicState.pos
                    local posp=G.runInfo.player.kinematicState.pos
                    local sentry=DanmakuFuncs.sentry(pos0)
                    local function releaseUpdate(self)
                        local t=self.frame-self.release
                        if t==0 then
                            self.size=self.size*2
                            self.kinematicState.speed=100
                            self:changeSprite(BulletSprites.kunai[self.sprite.data.color])
                            self.safe=false
                        elseif t>0 and t<30 then
                            self.size=self.size*0.97
                        elseif t>100 and t<180 then
                            self.kinematicState.speed=self.kinematicState.speed*0.98
                        end
                        if t>0 and t<60 then
                            self.kinematicState.speed=self.kinematicState.speed+7
                        end
                    end
                    local function slash(pos1,pos2,releaseFrame,color,side)
                        local dist=geo:distanceRef(pos1,pos2)
                        local step=15
                        local n=math.floor(dist/step)
                        local dir0=geo:toRef(pos1,pos2)
                        for i=1,n do
                            local progress=i/n
                            local pos,dir=geo:rThetaGoRef(pos1,dist*progress,dir0+progress*side*0.3)
                            local size=Event.sineBackProgressFunc(progress)+0.5
                            local deltadir=progress*0.3+math.ceil(progress*4)*0.1
                            local bullet=Bullet{kinematicState={pos=pos,dir=dir+side*deltadir,speed=0},sprite=BulletSprites.round[color],size=size,lifeFrame=540,extraUpdate={Action.ZoomIn(math.ceil(i/n*10)),Action.FadeIn(20,false),Action.FadeOut(20,true),releaseUpdate},highlight=true,safe=true}
                            bullet.release=releaseFrame
                        end
                    end
                    local function slashBatch(pos1,pos2,releaseFrame,color,side,num)
                        local dir=geo:toRef(pos1,pos2)+math.pi/2
                        local dist=geo:distanceRef(pos1,pos2)
                        for i=1,num do
                            local d=25*(i-0.5-num/2)
                            local posa,dir2=geo:rThetaGoRef(pos1,d,dir)
                            dir2=dir2-math.pi/2
                            local offset=math.eval(0,0.2)*dist
                            local posb=geo:rThetaGoRef(posa,offset/2,dir2)
                            local posc=geo:rThetaGoRef(posa,dist-offset/2,dir2)
                            slash(posb,posc,releaseFrame,color,side)
                        end
                    end
                    local function slashAtDir(dir,dir2,releaseFrame,color,side,num)
                        local posa,dira=geo:rThetaGoRef(posp,100,dir)
                        local pos1=geo:rThetaGoRef(posa,150,dira+dir2)
                        local pos2=geo:rThetaGoRef(posa,-150,dira+dir2)
                        slashBatch(pos1,pos2,releaseFrame,color,side,num)
                    end
                    local colors={'red','orange','purple','magenta'}
                    for i=1,8 do
                        for j=1,4 do
                            SFX:play('enemyShot')
                            slashAtDir(i%2*(-math.pi/2)+math.pi*math.ceil(j/2-1),math.pi/7*math.mod2Sign(j),(11-j+(j>3 and 1 or 0)+(i+1)%2)*9,colors[(i-1)%4+1],math.mod2Sign(j),2)
                            wait(9)
                            if j~=3 then
                                wait(9)
                            end
                        end
                        wait((3+(i+1)%2)*9)
                        for j=1,4 do
                            SFX:play('enemyShot')
                            wait(9)
                        end
                    end
                end
            },
            require('stages.stage4.spellcards.bridge'),
        }}
    }
}

local boss=BossManager.BossSegment{
    bossName='shouji',
    key='4-boss',
    getBossSpawnPos=function(self)
        local geo=G.runInfo.geometry
        local playerPos=G.runInfo.player.kinematicState.pos
        local outerPortals=Portal.setOuterPortals(playerPos,350)
        outerPortals[1]:link(outerPortals[3])
        outerPortals[2]:link(outerPortals[4])
        local pos,dir=geo:rThetaGo(playerPos,200,G.runInfo.player.viewDirection-math.pi/2)
        return pos
    end,
    rounds={
        BossManager.BossRound{phases={
            require('stages.stage4.spellcards.death'),
        }}
    }
}

return {midboss=midboss, boss=boss}