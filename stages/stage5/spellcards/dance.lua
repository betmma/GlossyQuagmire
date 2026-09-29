---@return SpellcardPhase
return BossManager.SpellcardPhase{
    key='tatsu-dance',SKIP_INCLUDE=true,
    bonusScore=40000,
    time=3000,
    hp=5600,
    dropItems={powerSmall=20,point=20},
    func=function(self, boss)
        boss:addHPProtection(120,3)
        local player=G.runInfo.player
        local geo=G.runInfo.geometry
        ---@cast geo Cylinder
        local pos={x=math.modClamp(player.kinematicState.pos.x+geo.a/2,boss.kinematicState.pos.x,geo.a/2),y=boss.kinematicState.pos.y}
        DanmakuFuncs.moveToInTime(boss,pos,60,Event.sineOProgressFunc)
        wait(60)
        local period=300
        local inhaleTime=75
        local wavePeriod=60
        local amplitude=72
        local speed=DSWITCH{210,240,270,300}
        local bodyLife=math.floor(geo.a*0.7/speed*60)
        local spacing=3
        local baseY=boss.kinematicState.pos.y
        local startY,targetY=baseY,baseY
        local phase=0
        boss.kinematicState.speed=0

        -- Cubic curves
        local curves={
            {-48,0,-70,-20,-46,-48,-24,-30},
            {-24,-30,-30,-68,26,-68,26,-32},
            {26,-32,52,-52,76,-16,52,0},
            {52,0,30,14,2,4,-12,18},
            {-12,18,-40,48,-72,28,-54,12},
            {-54,12,-40,0,-28,18,-42,22},
        }
        -- Staggered rounded bars joined by short necks
        local cloudBars={
            {-14,-38,63,-38},
            {-44,-25,-1,-25},
            {10,-20,54,-20},
            {-62,-8,25,-8},
            {-30,10,15,10},
            {17,21,61,21},
            {-41,28,2,28},
            {8,39,51,39},
            {35,-38,35,-20},
            {-20,-25,-20,-8},
            {-10,-8,-10,10},
            {-18,10,-18,28},
            {32,21,32,39},
        }

        local function cloudOrbitZoomIn(frame)
            return math.min(frame/120,1)
        end
        local sentry=DanmakuFuncs.sentry()
        local cloudCount=0
        local cloudExtraUpdate={Action.FadeIn(24,true),Action.FadeOut(20,true)}
        local function cloud(pos,dir)
            cloudCount=cloudCount+1
            local angular=cloudCount%2==0
            local samples=4
            local cloudSpeed=DSWITCH{95,110,125,140}
            local base=DanmakuFuncs.sentry(pos)
            local finalSpeed=cloudSpeed*math.eval(1,0.3)
            base.kinematicState.speed=speed+finalSpeed*4
            base.extraUpdate={function (self)
                self.kinematicState.speed=math.lerp(self.kinematicState.speed,finalSpeed,0.02)
                self.kinematicState.dir=math.lerp(self.kinematicState.dir,0.2*math.sin(sentry.frame/90*math.pi),0.02)
            end}
            base.kinematicState.dir=math.modClamp(dir)
            base.lifeFrame=600
            SFX:play('enemyShot')
            Effect.Larger{kinematicState={pos=base.kinematicState.pos,dir=0,speed=0},sprite=BulletSprites.shockwave.blue,size=3,growSpeed=-0.1,animationFrame=30,spriteTransparency=0.8,shareKinematicState=true}
            local cloudSize=math.eval(1,0.3)
            local function cloudPoint(x,y)
                -- Keep the existing orientation and orbit animation for both motifs.
                local dx=x*math.cos(dir-math.pi/2)+y*math.cos(dir)
                local dy=x*math.sin(dir-math.pi/2)+y*math.sin(dir)
                local r,theta=math.xy2rTheta(dx,dy)
                local sprite=angular and BulletSprites.bigRound.teal or BulletSprites.bigRound.cyan
                local bullet=Bullet{kinematicState={pos={x=pos.x+dx,y=pos.y+dy},dir=dir,speed=0},sprite=sprite,lifeFrame=600,highlight=true,extraUpdate=copyTable(cloudExtraUpdate),size=cloudSize*(angular and 0.4 or 1)}
                DanmakuFuncs.orbitBind(bullet,base,{r=r*cloudSize,theta=theta+math.pi/2},nil,cloudOrbitZoomIn)
            end
            if angular then
                local emitted={}
                for _,bar in ipairs(cloudBars) do
                    local length=math.abs(bar[3]-bar[1])+math.abs(bar[4]-bar[2])
                    local n=math.ceil(length/12)
                    for j=0,n do
                        local x=math.lerp(bar[1],bar[3],j/n)
                        local y=math.lerp(bar[2],bar[4],j/n)
                        local key=string.format('%.4f,%.4f',x,y)
                        if not emitted[key] then
                            emitted[key]=true
                            cloudPoint(x,y)
                        end
                    end
                end
            else
                for _,c in ipairs(curves) do
                    for j=0,samples-1 do
                        local t=j/samples
                        local u=1-t
                        local x=u^3*c[1]+3*u*u*t*c[3]+3*u*t*t*c[5]+t^3*c[7]
                        local y=u^3*c[2]+3*u*u*t*c[4]+3*u*t*t*c[6]+t^3*c[8]
                        cloudPoint(x,y)
                    end
                end
            end
        end
        local count=0
        local function body()
            count=count+1
            local pos=copyTable(boss.kinematicState.pos)
            local birthPhase=phase
            local birthBase=baseY
            local distance=48
            local colors={'yellow','green','teal','yellow'}
            local row=count%#colors+1
            local color=colors[row]
            local edge=row-0.5-#colors/2
            -- sticks form the overall shape
            local segment=Bullet{kinematicState={pos={x=pos.x,y=pos.y+edge*distance},dir=0,speed=speed*0.12},
                sprite=BulletSprites.stick[color],
                lifeFrame=bodyLife,size=5,forceQuad=true,highlight=false,safe=true,spriteTransparency=1,
                extraUpdate={function(cir)
                    -- The cloth body continues undulating after the head passes.
                    local p=birthPhase+cir.frame/wavePeriod*math.pi*2*0.5
                    local taper=math.min(1,(cir.lifeFrame-cir.frame)/60)
                    cir.kinematicState.pos.y=birthBase+amplitude*math.sin(p)+edge*distance*taper
                    cir.spriteExtraDirection=math.atan2(amplitude*math.pi*2/wavePeriod*math.cos(p),speed/60)
                end,Action.FadeIn(20,false),Action.FadeOut(40,true)}}

            -- Overlay bullets on the segment.
            local function ornament(sprite,x,y,size,angle,alpha,unsafe)
                -- if 1 then return end
                size=size*2
                Bullet{kinematicState={pos={x=pos.x+x,y=pos.y+edge*distance+y},dir=0,speed=0},
                    sprite=sprite,lifeFrame=bodyLife,size=size,forceQuad=true,
                    safe=not unsafe,highlight=false,spriteTransparency=alpha,
                    extraUpdate={function(cir)
                        if segment.removed then
                            cir:remove()
                            return
                        end
                        local p=birthPhase+segment.frame/wavePeriod*math.pi*2*0.5
                        local taper=math.min(1,(segment.lifeFrame-segment.frame)/60)
                        -- Tilt the plates with the wave without turning their velocity.
                        local tilt=math.atan2(amplitude*math.pi*2/wavePeriod*math.cos(p),speed/60)*0.35
                        local dx=(x*math.cos(tilt)-y*math.sin(tilt))*taper
                        local dy=(x*math.sin(tilt)+y*math.cos(tilt))*taper
                        cir.kinematicState.pos={x=(segment.kinematicState.pos.x+dx)%geo.a,y=segment.kinematicState.pos.y+dy}
                        cir.spriteExtraDirection=tilt+angle
                        cir.size=size*(0.35+0.65*taper)
                    end,Action.FadeIn(20,false),Action.FadeOut(40,true)}}
            end
            if row==1 or row==4 then
                -- red spikes. only these are not safe
                local sign=(row==1 and -1 or 1)
                ornament(BulletSprites.largeMagatama.red,-5,10*sign,1.2,-math.pi/4*sign-math.pi/6,0.6,true)
            else
                -- overlapping scales
                local scaleColor=row==3 and 'teal' or 'green'
                for i=-1,1 do
                    ornament(BulletSprites.scale[scaleColor],i*15,(i%2)*9-4,2.1,math.pi,0.65)
                end
            end
            if count%8==0 then -- add binded fairies so player can hit dragon body
                local fairy=Enemy{sprite=Asset.fairySprites.small.red,lifeFrame=bodyLife-40,spriteTransparency=0,maxhp=9999}
                fairy.size=16
                fairy.safe=true
                fairy:bind(boss)
                fairy:bindState(segment)
                if boss.hp<boss.maxhp/2 then
                    BulletSpawner{lifeFrame=bodyLife-40,period=6,bulletNumber=2,bulletSprite=BulletSprites.flame.red,bulletSpeed=150,bulletLifeFrame=300,angle=0,range=0,bulletExtraUpdate={Action.FadeOut(20,true),function(self)
                        if self.frame==1 then
                            self.kinematicState.speed=self.kinematicState.speed+150
                        end
                        if self.frame<30 then
                            self.kinematicState.speed=self.kinematicState.speed-5
                        end
                    end},highlight=true,bulletEvents={function (cir,args,self)
                        local index=args.index
                        cir.kinematicState.speed=cir.kinematicState.speed+index*8
                        cir.kinematicState.dir=segment.spriteExtraDirection*DSWITCH{0,0.05,0.1,0.12}+math.mod2Sign(index)*math.pi/2
                        local vy=cir.kinematicState.speed*math.sign(cir.kinematicState.dir)
                        local sign=math.sign(vy)
                        local dist=300-cir.kinematicState.pos.y*sign
                        cir.lifeFrame=20+dist*60/math.abs(vy)
                    end}}:bindState(segment)
                end
            end
        end

        for frame=1,self.time do
            local beat=(frame-1)%period
            if beat==0 then
                startY=baseY
                targetY=math.clamp(player.kinematicState.pos.y,-210,210)
                if frame==1 then
                    targetY=0
                end
                SFX:play('enemyCharge')
            end
            if beat<150 then
                local t=(beat+1)/150
                baseY=math.lerp(startY,targetY,Event.sineIOProgressFunc(t))
            end
            if beat<inhaleTime then
                local radius=500
                -- Harmless wisps contract into the moving head during inhalation.
                for i=1,2 do
                    local angle=math.eval(0,0.3)
                    Bullet{kinematicState={pos=geo:rThetaGo(boss.kinematicState.pos,radius,angle),dir=0,speed=0},
                        sprite=BulletSprites.darkLotus.blue,highlight=true,size=math.eval(1,0.5),spriteTransparency=0.8,forceQuad=true,safe=true,lifeFrame=30,
                        extraUpdate={function(cir)
                            local r=radius*(1-cir.frame/cir.lifeFrame)
                            cir.kinematicState.pos=geo:rThetaGo(boss.kinematicState.pos,r,angle)
                        end,Action.ZoomOut(30),Action.FadeIn(30,false)}}
                end
            end
            phase=frame/wavePeriod*math.pi*2
            local pos=boss.kinematicState.pos
            pos.x=(pos.x+speed/60)%geo.a
            pos.y=baseY+amplitude*math.sin(phase)
            if frame%spacing==0 then
                body()
            end
            if beat==inhaleTime then
                SFX:play('enemyPowerfulShot')
                Event.LoopEvent{obj=sentry,period=12,times=DSWITCH{3,4,4,5},executeFunc=function ()
                    local tangent=math.atan2(amplitude*math.pi*2/wavePeriod*60*math.cos(phase),speed)
                    cloud(copyTable(pos),tangent/4)
                end}
            end
            wait()
        end
    end
}
