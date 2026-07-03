local setZoomSpeed=require('stages.stage2.setZoomSpeed')

---@return SpellcardPhase
return BossManager.SpellcardPhase{
    key='tooshi-dance',SKIP_INCLUDE=true,
    bonusScore=15000,
    time=1800,
    hp=2800,
    dropItems={point=15,powerSmall=10},
    func=function(self, boss)
        boss.kinematicState.skipZoom=true
        local geo=G.runInfo.geometry
        local basePos=geo:init().pos
        local sentry=Bullet{kinematicState={pos=copyTable(basePos),speed=0,dir=0},sprite=BulletSprites.round.red,lifeFrame=99999,invincible=true,safe=true,spriteTransparency=0}
        local scrolling=false
        local spawner=BulletSpawner{angle='0+999',range=math.pi*2,bulletNumber=21,lifeFrame=1800,period=9999,bulletLifeFrame=600,bulletSize=1,bulletSpeed=50,bulletSprite=BulletSprites.note.orange,highlight=true,bulletEvents={function(cir,args,self)
            if args.index==1 then
                self.polygonN=math.ceil(math.eval(5,2.5))
                self.polygonAngle=math.eval(0,9)
            end
            local angle=cir.kinematicState.dir-self.polygonAngle
            local angle2=angle%(math.pi*2/self.polygonN)-(math.pi/self.polygonN)
            cir.kinematicState.speed=cir.kinematicState.speed/math.cos(angle2)
        end},bulletExtraUpdate={function(self)
            if scrolling then
                if not self.flag then
                    self:changeSpriteColor('purple')
                    self.flag=true
                end
                if self.frame%3==0 then
                    local lifeFrame=8
                    Bullet{kinematicState={pos=copyTable(self.kinematicState.pos),dir=self.kinematicState.dir,speed=0,skipZoom=true},sprite=self.sprite,size=self.size,batch=self.batch,spriteTransparency=self.spriteTransparency,lifeFrame=lifeFrame,spriteColor=self.spriteColor,safe=true,invincible=true,extraUpdate={Action.ZoomOut(lifeFrame)}}
                end
            end
            if self.flag and not scrolling then
                self:changeSpriteColor('orange')
                self.flag=false
            end
        end}}
        spawner:bindState(boss)
        local scrollAmount=DSWITCH{0.01,0.02,0.03,0.04}
        local bpm=130
        local beat=60/bpm*60
        local beatCount=0
        -- imitating foxtrot: 6 beat loop, 1 -> first loop left, other scroll background, 2 -> middle, 3 -> right, 4 -> scroll background, 5 -> middle, 6 -> left
        -- should sync with the music. should ensure the boss music starts at the last line of dialogue and that line's auto forward time is multiple of beat.
        Event.LoopEvent{obj=sentry,period=1,executeFunc=function(self,times)
            times=boss.frame
            if math.ceil(times/beat)==math.ceil((times-1)/beat) then
                return
            end
            beatCount=beatCount+1
            local shoot=true
            if beatCount%3==1 and beatCount>1 then -- scroll. two half beats
                scrolling=true
                local sign=math.mod2Sign(beatCount)
                SFX:play('hit')
                setZoomSpeed(sign*scrollAmount,0)
                setZoomSpeed(0,math.ceil(beat/2))
                Event{obj=sentry,action=function(self)
                    wait(math.ceil(beat/2))
                    SFX:play('hit')
                    setZoomSpeed(sign*scrollAmount,0)
                    setZoomSpeed(0,math.ceil(beat/2))
                    wait(math.ceil(beat/2))
                    scrolling=false
                end}
                shoot=false
            end
            -- boss moving
            local xmap={-1,0,1,1,0,-1}
            local sign=xmap[(beatCount-1)%6+1] -- -1,0,1 maps to left,middle,right
            local ymap={150,150,150,100,100,100}
            local y=ymap[(beatCount-1)%6+1]
            local pos1,dir1=geo:rThetaGo(basePos,y,-math.pi/2)
            dir1=dir1+math.pi/2*sign
            local jumpPos=geo:rThetaGo(pos1,100,dir1)
            if sign==0 then
                jumpPos=pos1
            end
            DanmakuFuncs.moveToInTime(boss,jumpPos,beat*0.8,Event.sineOProgressFunc)
            if shoot then
                spawner.bulletSpeed=math.eval(70,20)
                spawner:spawnBatchFunc()
            end
        end}
    end
}