---@return SpellcardPhase
return BossManager.LastSpellcardPhase{
    key='marisa-spark',
    bonusScore=20000,
    time=1800,
    hp=2400,
    dropItems={lifePiece=2,bombPiece=2},
    func=function(self, boss)
        -- easier to hit.
        boss.extraHitRadius=64
        local center=G.runInfo.geometry:init().pos
        local geo=G.runInfo.geometry
        ---@type Player
        local player=G.runInfo.player
        local sentry=DanmakuFuncs.sentry()
        sentry.remove=function (self)
            Bullet.remove(sentry)
            boss.kinematicState.speed=0
        end
        local update=function (self)
            self.kinematicState.speed=math.lerp(self.kinematicState.speed,DSWITCH{40,30,20,10},0.01)
        end
        local function shot(dir)
            boss.kinematicState.dir=dir
            local laser=GeoLaser{kinematicState={pos=copyTable(boss.kinematicState.pos),dir=dir,speed=0},sprite=BulletSprites.laser.yellow,size=1,rayAngle=0.3,spriteTransparency=1,safe=true,invincible=true,lifeFrame=300,meshBudget={capNum=12,step=80,num=16},extraUpdate={GeoLaser.presetActions.laserZoomIn(30),GeoLaser.presetActions.laserZoomOut(30),GeoLaser.presetActions.laserPrep(60,0.3)}}
            laser:bindState(boss)
            Event{obj=sentry,action=function ()
                SFX:play('enemyCharge')
                wait(60)
                SFX:play('enemyPowerfulShot')
                local speed=DSWITCH{120,120,140,160}
                Event.EaseEvent{obj=sentry,easeObj=boss.kinematicState,aims={speed=-speed},duration=240,progressFunc=Event.sineBackProgressFunc}
                local spawner=BulletSpawner{period=10,bulletNumber=DSWITCH{9,10,11,12},useRelativeAngle=true,angle='0+0.1',range=math.pi*0.5,lifeFrame=240,bulletSprite=BulletSprites.bigStar.red,highlight=true,bulletSpeed=600,bulletLifeFrame=600,bulletEvents={function (cir,args,self)
                    cir:changeSpriteColor()
                    cir.spriteRotationSpeed=math.randomSign()*.02
                end},bulletExtraUpdate={Action.FadeOut(20,true),update}}
                spawner:bindState(boss)
                Event.EaseEvent{obj=spawner,aims={range=math.pi,bulletSpeed=DSWITCH{220,200,180,150}},duration=240,}
                wait(240)
                Event.EaseEvent{obj=sentry,easeObj=boss.kinematicState,aims={speed=speed*3},duration=90,progressFunc=Event.sineBackProgressFunc}
            end}
        end
        for i=1,10 do
            local dir=geo:to(boss.kinematicState.pos,G.runInfo.player.kinematicState.pos)
            shot(dir+math.mod2Sign(i)*math.pi/DSWITCH{2,3,4,5})
            wait(390)
        end
    end
}