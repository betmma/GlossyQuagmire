---@return SpellcardPhase
return BossManager.SpellcardPhase{
    key='enri-final',
    bonusScore=100000,
    time=7200,
    hp=10000,
    -- dropItems={powerSmall=30,point=15}, -- no need for items for final spell
    func=function(self, boss)
        -- what if a big nuke -> giants -> return to a big nuke, and later phases add more transformations in the middle, like giants -> big stars -> giants, big stars -> rounds -> big stars. each smaller bullet moves a cycle, returns and becomes bigger one
        boss.extraHitRadius=128
        local bpm=170
        local barFrame=60/bpm*4*60 -- 84.7 frames
        local barFrameInt=math.ceil(barFrame)
        local doubleBarFrame=barFrame*2 -- 169.4 frames
        local doubleBarFrameInt=math.floor(doubleBarFrame)
        local geo=G.runInfo.geometry
        ---@cast geo Spherical
        local radius=geo.radius
        ---@cast geo GeometryBase
        boss.hpSegments={0.85,0.7,0.55}
        local maxLayers=DSWITCH{5,5,6,6}
        local activateLayers=DSWITCH{2,2,3,3}
        local pendingActivateLayers=activateLayers
        boss.hpSegmentsFunc=function (self,hplevel)
            pendingActivateLayers=math.min(maxLayers,pendingActivateLayers+1)
            self:addHPProtection(hplevel==3 and 1200 or 600,10)
        end
        local player=G.runInfo.player
        --- [time] is half of this layer bullet's move time. so after spawn, [time] to move, then call func, disappear. at lifeFrame-[time], appear and move. extraUpdate is each layer's unique extraUpdate
        ---@type {time:integer,func:fun(self),extraUpdate:fun(self)|nil}[]
        local layers
        local layerExtraUpdates={}
        --- double of sum of times of layers>=i
        ---@type integer[]
        local lifeFrames={0}
        local fadeFrame=15
        local function shift(frame,layer,lifeFrame)
            local time=layers[layer].time
            if frame<=time then
                return frame
            end
            if frame<lifeFrame-time then
                return -1
            end
            return frame-(lifeFrame-time)+time
        end
        local function getLifeFrame(layer)
            return lifeFrames[layer]-lifeFrames[activateLayers+1]
        end
        local sentry=DanmakuFuncs.sentry()
        local function reviveLater(obj)
            local any=obj.any
            local t0=obj.frame
            local t=obj.lifeFrame-obj.frame*2
            local args={size=obj.size,sprite=obj.sprite,batch=obj.batch,spriteTransparency=obj.spriteTransparency,lifeFrame=obj.lifeFrame,frame=t+t0,extraUpdate=obj.extraUpdate,spriteRotationSpeed=obj.spriteRotationSpeed,spriteColor=obj.spriteColor}
            obj:remove()
            Event{obj=sentry,action=function ()
                wait(t)
                local new=Bullet(args)
                new.any=any
            end}
        end
        local extraUpdate={Action.FadeIn(15,true),Action.FadeOut(15,true),function(self)
            local layer=self.any.layer
            if layer==activateLayers or layer==#layers then
                return -- wont call func and spawn next layer bullets
            end
            local time=layers[layer].time
            if self.frame==time then
                self.safe=true
                self.any.antipode,self.any.dir=geo:rThetaGo(self.kinematicState.pos,math.pi*radius*((activateLayers-layer)%2),self.kinematicState.dir)
                layers[layer].func(self)
            elseif self.frame>time and self.frame<=time+fadeFrame then
                local ratio=1-(self.frame-time)/fadeFrame
                self.spriteTransparency=ratio
            end
            if self.frame==time+fadeFrame and layer>1 then
                reviveLater(self)
            end
            local remaining=self.lifeFrame-self.frame
            if remaining==time then
                self.safe=false
            end
            if remaining<time+fadeFrame and remaining>=time then
                self.kinematicState.pos,self.kinematicState.dir=copyTable(self.any.antipode),self.any.dir
                local ratio=(time+fadeFrame-remaining)/fadeFrame
                self.spriteTransparency=ratio
            end
        end}
        local function playSFX(first)
            Event{obj=sentry,action=function ()
                local layer=1
                while layer<=activateLayers do -- not for i=1,activateLayers, because activateLayers could change during waiting
                    local time=layers[layer].time
                    if layer==1 and not first then
                        time=time-fadeFrame
                    end
                    wait(time-60)
                    if layer<activateLayers then
                        SFX:play('enemyCharge')
                    end
                    wait(60)
                    if layer<activateLayers then
                        SFX:play('enemyPowerfulShot')
                    end
                    layer=layer+1
                end
                for i=activateLayers,2,-1 do
                    local time=layers[i].time
                    if i==1 then
                        time=time-fadeFrame
                    end
                    wait(time-60)
                    SFX:play('enemyCharge')
                    wait(60)
                    SFX:play('enemyPowerfulShot')
                end
            end}
        end
        layers={
            -- nuke
            {time=barFrameInt+fadeFrame,func=function (self)
                local layer=self.any.layer+1
                local n=DSWITCH{15,20,30,40}
                n=math.min(n,15+5*activateLayers)
                local angle0=math.eval(0,math.pi)
                local averageSpeed=radius*math.pi/layers[layer].time*60/2
                for i=1,n do
                    local angle=angle0+math.pi*(3-5^0.5)*i
                    local multi=(i-0.5)/n*4-1
                    local bullet=Bullet{kinematicState={pos=copyTable(self.kinematicState.pos),dir=angle,speed=averageSpeed*multi},sprite=BulletSprites.giant.orange,size=3,forceQuad=true,highlight=true,invincible=true,lifeFrame=getLifeFrame(layer),extraUpdate=layerExtraUpdates[layer],spriteColor={1,0.8,0.8,1}}
                    bullet.any={layer=layer,averageSpeed=averageSpeed,multi=multi,index=i,ratio=(i-0.5)/n}
                end
            end,extraUpdate=function (self)
                -- restore frame and lifeFrame. it won't disppear
                if self.frame==self.lifeFrame-fadeFrame then
                    self.frame=fadeFrame
                    activateLayers=pendingActivateLayers
                    self.lifeFrame=getLifeFrame(1)
                    playSFX(false)
                end
            end},
            -- giants with different speed
            {time=doubleBarFrameInt,func=function (self)
                local layer=self.any.layer+1
                local n=2
                local angle0=self.kinematicState.dir
                local averageSpeed=radius*math.pi/(layers[layer].time*2-fadeFrame)*60 -- -fadeFrame due to speed up and slow down
                for i=0,n-1 do
                    local angle=angle0+math.pi/3*self.any.ratio+math.pi*i--*math.mod2Sign(i)
                    local bullet=Bullet{kinematicState={pos=copyTable(self.kinematicState.pos),dir=angle,speed=averageSpeed},sprite=BulletSprites.bigStar.yellow,size=3,forceQuad=true,highlight=true,invincible=true,lifeFrame=getLifeFrame(layer),extraUpdate=layerExtraUpdates[layer],spriteColor={0.9,0.85+i*0.1,0.75+i*0.1,0.85},spriteRotationSpeed=0.07*math.mod2Sign(i)}
                    bullet.any={layer=layer,averageSpeed=averageSpeed,index=self.any.index*n+i}
                end
            end,extraUpdate=function (self)
                local t=shift(self.frame,self.any.layer,self.lifeFrame)
                if t~=-1 then
                    local ratio=t/layers[self.any.layer].time
                    self.kinematicState.speed=self.any.averageSpeed*math.lerp(self.any.multi,2-self.any.multi,ratio/2)
                end
            end},
            -- stars that move simply, just with speed up and slow down
            {time=doubleBarFrameInt+1,func=function (self)
                local layer=self.any.layer+1
                local n=DSWITCH{3,3,2,2}
                local distance,angle0=geo:rThetaTo(self.kinematicState.pos,player.kinematicState.pos)
                angle0=angle0+math.max(0,distance/radius-0.3)
                local averageSpeed=radius*math.pi/(layers[layer].time)*60
                for i=1,n do
                    local angle=angle0+math.pi/12*((i-0.5)/n-0.5)
                    local bullet=Bullet{kinematicState={pos=copyTable(self.kinematicState.pos),dir=angle,speed=averageSpeed},sprite=BulletSprites.flame.green,size=2,forceQuad=true,highlight=true,invincible=true,lifeFrame=getLifeFrame(layer),extraUpdate=layerExtraUpdates[layer],spriteColor={0.8,1,0.8,0.8}}
                    bullet.any={layer=layer,averageSpeed=averageSpeed,index=self.any.index*n+i-1}
                end
            end,extraUpdate=function (self)
                local t=shift(self.frame,self.any.layer,self.lifeFrame)
                if t~=-1 then
                    t=math.min(t,layers[self.any.layer].time*2-t)
                    self.kinematicState.speed=self.any.averageSpeed*math.min(t/fadeFrame,1)
                end
            end},
            -- flames scattered in small range. 
            {time=doubleBarFrameInt,func=function (self)
                local layer=self.any.layer+1
                local index=self.any.index
                local pos=player.kinematicState.pos
                local dir=player.viewDirection
                local pos2=geo:rThetaGo(pos,math.pi/2*radius,dir-math.pi/2)
                local angle0,angle1
                local id=math.ceil(index/2)
                if index%2==0 then
                    angle0=math.pi/4*(id%4+0.5)
                    angle1=math.ceil(id/4)*math.pi*(3-5^0.5)/2
                else
                    angle1=math.pi/3*(id%6)
                    angle0=math.ceil(id/6)*math.pi*(3-5^0.5)/2
                end
                local pos3=geo:rThetaGo(pos2,radius*angle0,angle1)
                local distance,angle4=geo:rThetaTo(self.kinematicState.pos,pos3)
                local speed0=distance/layers[layer].time*60
                local averageSpeed=radius*math.pi/(layers[layer].time*2)*60
                local n=1
                for i=1,n do
                    local angle=angle4
                    local bullet=Bullet{kinematicState={pos=copyTable(self.kinematicState.pos),dir=angle,speed=speed0/2},sprite=BulletSprites.bird.blue,size=2,forceQuad=true,highlight=true,invincible=true,lifeFrame=getLifeFrame(layer),extraUpdate=layerExtraUpdates[layer],spriteColor={0.8,0.8,1,0.8}}
                    bullet.any={layer=layer,speed0=speed0,averageSpeed=averageSpeed,index=index,pole=pos2}
                end
            end,extraUpdate=function (self)
                local t=shift(self.frame,self.any.layer,self.lifeFrame)
                if t~=-1 then
                    local ratio=t/layers[self.any.layer].time
                    ratio=math.min(ratio,2-ratio)
                    self.kinematicState.speed=self.any.averageSpeed*ratio
                end
            end},
            -- birds forming a globe (strangely similar to internet icon especially with blue color)
            {time=doubleBarFrameInt+1,func=function (self)
                local layer=self.any.layer+1
                local index=self.any.index
                local pole=self.any.pole
                local pos=player.kinematicState.pos
                -- local dangle1=geo:to(pos,pos2)-geo:to(pos2,pos)+math.pi
                local angle0,angle1=geo:rThetaTo(pole,self.kinematicState.pos)
                angle0=angle0/radius
                local div0=math.pi/4
                local div1=math.pi/3
                local angle0d=angle0-(angle0)%div0+div0/2 -- angle0d is div0*(integer+0.5) while angle1d is div1*integer
                local angle1d=angle1-(angle1+div1/2)%div1+div1/2
                local center=geo:rThetaGo(pole,angle0d*radius,angle1d)
                local dc,tc=geo:rThetaTo(center,self.kinematicState.pos)
                -- local center=geo:rThetaGo(pos2,angle0d*radius,angle1d)
                local n=2
                for i=1,n do
                    local newCenter=geo:rThetaGo(pole,(angle0d+math.pi/3*math.mod2Sign(i))*radius,angle1d+math.pi/4*math.mod2Sign(i))
                    local pos3=newCenter--geo:rThetaGo(newCenter,dc,tc)
                    local distance,angle4=geo:rThetaTo(self.kinematicState.pos,pos3)
                    local speed0=distance/layers[layer].time*60
                    local averageSpeed=radius*math.pi/(layers[layer].time*2)*60
                    local bullet=Bullet{kinematicState={pos=copyTable(self.kinematicState.pos),dir=angle4,speed=speed0/2},sprite=BulletSprites.knife.purple,size=1.5,forceQuad=true,highlight=true,invincible=true,lifeFrame=getLifeFrame(layer),extraUpdate=layerExtraUpdates[layer],spriteColor={0.8,1,1,0.8}}
                    bullet.any={layer=layer,speed0=speed0,averageSpeed=averageSpeed,index=index,pole=pole}
                end
            end,extraUpdate=function (self)
                local t=shift(self.frame,self.any.layer,self.lifeFrame)
                if t~=-1 then
                    local ratio=t/layers[self.any.layer].time
                    local t2=math.min(ratio,2-ratio)
                    local speed=ratio<=1 and self.any.speed0 or self.any.averageSpeed*2-self.any.speed0
                    self.kinematicState.speed=speed--*(1-t2)*2
                end
            end},
            -- knives
            {time=doubleBarFrameInt,func=function (self)
                
            end,extraUpdate=function (self)
                local t=shift(self.frame,self.any.layer,self.lifeFrame)
                if t~=-1 then
                    local ratio=t/layers[self.any.layer].time
                    local t2=math.min(ratio,2-ratio)
                    local speed=ratio<=1 and self.any.speed0 or self.any.averageSpeed*2-self.any.speed0
                    self.kinematicState.speed=speed*(t2)*2
                end
            end},
        }
        for i=1,#layers do
            local value=copyTable(extraUpdate)
            table.insert(value,layers[i].extraUpdate)
            layerExtraUpdates[i]=value
        end
        for i=#layers,1,-1 do
            local accumulate=lifeFrames[1]
            accumulate=accumulate+layers[i].time*2
            table.insert(lifeFrames,1,accumulate)
        end
        local t=boss.frame-fadeFrame -- because first nuke loop doesn't skip first fadeFrame frames
        wait((-t)%barFrameInt)
        local nuke=Bullet{kinematicState={pos=copyTable(boss.kinematicState.pos),dir=geo:to(boss.kinematicState.pos,player.kinematicState.pos)+math.randomSign()*1.5,speed=150},invincible=true,sprite=BulletSprites.nuke,lifeFrame=getLifeFrame(1),extraUpdate=layerExtraUpdates[1]}
        nuke.any={layer=1}
        playSFX(true)
        wait(4200)
        pendingActivateLayers=maxLayers
    end
}