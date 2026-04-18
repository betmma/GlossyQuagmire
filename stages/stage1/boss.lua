
---@type BossSegment
return BossManager.BossSegment{
    bossName='test',
    key='1-mid',
    getBossSpawnPos=function(self)
        local geometry=G.runInfo.geometry
        local pos,dir=geometry:rThetaGo(geometry:init().pos,200,-math.pi/2)
        return pos
    end,
    rounds={
        BossManager.BossRound{phases={
            BossManager.NonSpellPhase{
                time=600,
                hp=600,
                func=function(self, boss)
                    local spawner=BulletSpawner{
                        period=30,firstPeriod=30,lifeFrame=570,bulletNumber=1,bulletSpeed=150,bulletSize=1,angle='player',bulletSprite=BulletSprites.round.red,bulletLifeFrame=600
                    }:bindState(boss)
                end
            },
            BossManager.SpellcardPhase{
                id=1,
                bonusScore=10000,
                time=900,
                hp=900,
                dropItems={life=1},
                name='Test Spell',
                func=function(self, boss)
                    local spawner=BulletSpawner{
                        period=20,firstPeriod=20,lifeFrame=880,bulletNumber=5,bulletSpeed=150,bulletSize=1,angle='player',bulletSprite=BulletSprites.round.blue,bulletLifeFrame=600
                    }:bindState(boss)
                end
            }
        }}
    }
}