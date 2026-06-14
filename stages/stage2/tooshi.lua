local tooshiBoss=BossManager.BossSegment{
    bossName='tooshi',
    key='2-boss',
    BGM='level2b',
    getBossSpawnPos=function(self)
        local geo=G.runInfo.geometry
        local basePos=geo:init().pos
        local pos,dir=geo:rThetaGo(basePos,200,-math.pi/2)
        return pos
    end,
    rounds={
        BossManager.BossRound{SKIP_INCLUDE=true,phases={
            BossManager.NonSpellPhase{SKIP_INCLUDE=true,
                key='2-boss-tooshi-non-1',
                time=1500,
                hp=2000,
                func=function()
                    wait(120)
                end
            }
        }}
    }
}
return tooshiBoss