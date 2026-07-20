---@return SpellcardPhase
return BossManager.SpellcardPhase{
    key='kora-manifest',SKIP_INCLUDE=true,
    bonusScore=20000,
    time=1800,
    hp=3600,
    dropItems={powerSmall=15,point=15},
    func=function(self, boss)
        local geo=G.runInfo.geometry
        local basePos=geo:init().pos
        local sentry=Bullet{kinematicState={pos=copyTable(basePos),speed=0,dir=0},sprite=BulletSprites.round.red,lifeFrame=99999,invincible=true,safe=true,spriteTransparency=0}
        local posm,dirm=geo:rThetaGo(basePos,600,G.runInfo.player.viewDirection-math.pi/2)
        local posm2,dirm2=geo:rThetaGo(basePos,-200,G.runInfo.player.viewDirection-math.pi/2)
        local posb,dirb=geo:rThetaGo(basePos,300,G.runInfo.player.viewDirection-math.pi/2)
        local function sidepos(side)
            local angle=math.pi/2*side
            local pos,dir=geo:rThetaGo(posb,120,angle+dirb)
            return pos,dir
        end
        local sixColors=DIFF()>=G.HARD
        local h=math.random(1,3)/(sixColors and 6 or 3)
        local function gethsingle() -- if h is red or green or blue (1 channel is 1)
            return math.cos((h*3%1)*math.pi*2)*0.5+0.5
        end
        local hsingle=gethsingle()
        local player=G.runInfo.player
        Mirror.setHSV({h,1,1},0)
        for i=1,5 do
            local side=math.mod2Sign(i)
            local pos,dir=sidepos(side)
            DanmakuFuncs.moveToInTime(boss,pos,60,Event.sineOProgressFunc)
            SFX:play('enemyCharge')
            local mirror=Mirror(posm,posm2,pos, {lifeFrame=350,extraUpdate={Action.FadeIn(20,false,1),Action.FadeOut(20,false),}})
            Event.LoopEvent{obj=sentry,period=80,times=3,executeFunc=function (self, index, total)
                Event{action=function()
                    local dh=(sixColors and math.random(1,2)/6 or 1/3)*math.randomSign()/20
                    for i=1,20 do
                        h=h+dh
                        hsingle=gethsingle()
                        Mirror.setHSV({h,1,1},0)
                        wait()
                    end
                end}
            end}
            local speed=DSWITCH{150,200,220,250}
            local dspeed=DSWITCH{0,20,40,60}
            local spawner=BulletSpawner{lifeFrame=270,period=30,firstPeriod=60,bulletNumber=DSWITCH{40,60,80,100},bulletSprite=BulletSprites.lightRound.white,highlight=true,bulletLifeFrame=240,bulletSpeed={speed,dspeed},angle='0+999',bulletEvents={function(cir,args,self)
                local real=args.index%3==0
                if not real then
                    cir.safe=true
                end
                cir.real=real
                local dh=math.eval(0,1/6)
                cir.dh,cir.s,cir.v=dh,math.eval(0.9,0.1),1
            end},bulletExtraUpdate={function(cir)
                local dhratio=cir.real and 1 or hsingle
                local r,g,b=math.hsvToRgb(cir.dh*dhratio+h+(cir.real and 0 or 0.5),cir.s,cir.v)
                cir.spriteColor={r,g,b,1}
                if cir.frame>math.min(mirror.frame*0.4-20+i*5,100)*200/speed and not cir.real then
                    cir.spriteTransparency=math.clamp(cir.spriteTransparency-0.05,0,1)
                end
            end}}:bindState(boss)
            wait(360)
        end
    end
}