local midboss=BossManager.BossSegment{
    bossName='kora',
    key='3-mid',
    getBossSpawnPos=function(self)
        local geometry=G.runInfo.geometry
        local pos,dir=geometry:rThetaGo(geometry:init().pos,250,G.runInfo.player.viewDirection-math.pi/2)
        return pos
    end,
    rounds={
        BossManager.BossRound{phases={
            BossManager.NonSpellPhase{
                key='3-mid-kora-non-1',
                time=1200,
                hp=2400,
                dropItems={point=15,powerSmall=10},
                func=function(self, boss)
                    local geo=G.runInfo.geometry
                    local pos0=boss.kinematicState.pos
                    local extraUpdate=function(self)
                        if self.frame<30 then
                            self.kinematicState.speed=self.kinematicState.speed*0.9
                        end
                        if self.frame>=30 and self.frame<90 then
                            self.kinematicState.dir=self.kinematicState.dir+math.pi/60*math.mod2Sign(self.index)
                            self.safe=true
                            self.spriteTransparency=math.clamp(1-(self.frame-30)/60,0.5,1)
                        end
                        if self.frame==90 then
                            self.spriteTransparency=1
                            self.safe=false
                        end
                        if self.frame>90 then
                            self.kinematicState.speed=math.lerp(self.kinematicState.speed,100,0.03)
                        end
                    end
                    for i=1,6 do
                        local pos1=geo:rThetaGo(pos0,math.eval(30,30),math.eval(0,99))
                        DanmakuFuncs.moveToInTime(boss,pos1,60)
                        local bullets={}
                        SFX:play('enemyShot')
                        local n1,n2=DSWITCH{4,4,8,8},DSWITCH{8,12,8,16}
                        BulletSpawner{period=100,firstPeriod=1,lifeFrame=2,bulletNumber=n2,bulletSpeed=600,range=math.pi*2*n2/n1,angle='player',bulletSprite=BulletSprites.arrow.black,bulletLifeFrame=400,bulletEvents={function(cir,args,self)
                            cir.index=args.index
                            local l=math.floor((cir.index-1)/n1)
                            cir.kinematicState.speed=cir.kinematicState.speed*(1+l*0.2)
                            if DIFF()==G.LUNATIC and l==1 and cir.index%2~=i%2 then -- remove second layer of big rings to reduce bullet count
                                cir:remove()
                                return
                            end
                            table.insert(bullets,cir)
                        end},bulletExtraUpdate={extraUpdate}}:bindState(boss)
                        local posm,dirm=geo:rThetaGo(geo:init().pos,200,G.runInfo.player.viewDirection-math.pi/2)
                        local function getPoses(t)
                            local angle=(t*math.pi-math.pi/4)*math.mod2Sign(i-1)
                            local pos1=geo:rThetaGo(posm,400,angle+dirm-math.pi/2)
                            local pos2=geo:rThetaGo(posm,400,angle+dirm+math.pi/2)
                            local posin=geo:rThetaGo(posm,200,angle+dirm)
                            return pos1,pos2,posin
                        end
                        local p10,p20,pin=getPoses(0)
                        local mirror=Mirror(p10,p20,pin,{extraUpdate={Action.FadeIn(30,false,0.7),Action.FadeOut(30,false),function (self)
                            local t=math.clamp(self.frame-30,0,60)/60
                            self.pos1,self.pos2,self.posIn=getPoses(t)
                            if t>0 and t<1 then
                                Mirror.setHSV({t*math.mod2Sign(i-1),0.5,1},0)
                                for i,bullet in ipairs(bullets) do
                                    Mirror.spawnReflections(bullet,1,nil,{index=true})
                                end
                            end
                        end},lifeFrame=120})
                        wait(180)
                    end
                end
            },
            require('stages.stage3.spellcards.cosmos')
        }}
    }
}

return {
    midboss=midboss,
}