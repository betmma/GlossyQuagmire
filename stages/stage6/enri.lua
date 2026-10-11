
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
                hp=2000,
                func=function(self, boss)
                    local geo=G.runInfo.geometry
                end
            },
            require('stages.stage6.spellcards.wind')
        }},
    }
}

return boss