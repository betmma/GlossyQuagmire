---@return SpellcardPhase
return BossManager.LastSpellcardPhase{
    key='kora-spotlight',
    bonusScore=40000,
    time=2400,
    hp=3600,
    dropItems={lifePiece=2,bombPiece=2},
    func=function(self, boss)
        boss:addHPProtection(300,5)
        local geo=G.runInfo.geometry
        local basePos=geo:init().pos
        local sentry=DanmakuFuncs.sentry()
        local posb,dirb=geo:rThetaGo(basePos,250,G.runInfo.player.viewDirection-math.pi/2)
        local posb2,dirb2=geo:rThetaGo(basePos,DSWITCH{200,200,400,300},G.runInfo.player.viewDirection-math.pi/2)
        local function sidepos(side,distance)
            local angle=math.pi/2*side
            local pos,dir=geo:rThetaGo(posb,distance or 200,angle+dirb)
            return pos,dir
        end
        wait(60)
        local extraUpdate=function (self)
            if self.mirrored then
                if not self.t0 then
                    self.kinematicState.speed=0
                    self.kinematicState.dir=self.kinematicState.dir+math.pi
                    self.t0=self.frame
                end
                if self.frame>=300 and self.frame<400 then
                    self.kinematicState.speed=math.lerp(self.kinematicState.speed,120,0.02)
                end
            end
            if self.frame%50==1 and geo:distance(self.kinematicState.pos,posb)>500 then
                self:remove()
            end
        end
        local extraUpdate2=function (self)
            if self.mirrored then
                if not self.t0 then
                    self.kinematicState.speed=0
                    self.kinematicState.dir=self.kinematicState.dir+math.pi
                    local r,g,b=self.spriteColor[1],self.spriteColor[2],self.spriteColor[3]
                    local h,s,v=math.rgbToHSV(r,g,b)
                    s=s+0.2
                    self.spriteColor[1],self.spriteColor[2],self.spriteColor[3]=math.hsvToRgb(h,s,v)
                    self.t0=self.frame
                end
                if self.frame>=420 and self.frame<520 then
                    self.kinematicState.speed=math.lerp(self.kinematicState.speed,240,0.02)
                end
            end
            if self.frame%50==1 and geo:distance(self.kinematicState.pos,posb)>500 then
                self:remove()
            end
        end
        for i=1,5 do
            Mirror.setHSV({math.mod2Sign(i-1)/4,0.5,1},0.3)
            local side=math.mod2Sign(i)
            local pos,dir=sidepos(side)
            local bullet=Bullet{kinematicState={pos=pos,dir=dir+math.pi*4/5*side,speed=0},lifeFrame=700,sprite=BulletSprites.ellipse.white,extraUpdate={Action.FadeIn(20,true),Action.FadeOut(20,true),extraUpdate}}
            local bullet2
            local bullets={bullet}
            if DIFF()>=G.HARD then
                local pos2,dir2=sidepos(-side)
                bullet2=Bullet{kinematicState={pos=pos2,dir=dir2-math.pi*4/5*side,speed=0},lifeFrame=700,sprite=BulletSprites.bigRound.white,extraUpdate={Action.FadeIn(20,true),Action.FadeOut(20,true),extraUpdate2}}
                bullets[2]=bullet2
                DanmakuFuncs.moveToInTime(boss,sidepos(side,120),60,Event.sineOProgressFunc)
            end
            SFX:play('coraMirror')
            local pos10,dir1=geo:rThetaGo(posb2,-150,dirb2+math.pi/2*side)
            if DIFF()>=G.HARD then
                dir1=dir1+math.pi/2*side
            end
            local pos1Sentry=Bullet{kinematicState={pos=pos10,dir=dir1,speed=60},lifeFrame=600,sprite=BulletSprites.ellipse.white,safe=true,invincible=true,spriteTransparency=0}
            local function getPos2(j,t)
                local angle=j*math.pi*(1/3-math.sin(t*math.pi)*1/4)
                local pos1=pos1Sentry.kinematicState.pos
                local angles={}
                for i=1,#bullets do
                    local anglei=geo:to(pos1,bullets[i].kinematicState.pos)
                    if angles[1] then
                        anglei=math.modClamp(anglei,angles[i])
                    end
                    table.insert(angles,anglei)
                end
                local anglej
                if j==1 then
                    anglej=math.max(unpack(angles))
                else
                    anglej=math.min(unpack(angles))
                end
                if DIFF()>=G.HARD then
                    angle=anglej+angle/2
                else
                    angle=geo:to(pos1,bullet.kinematicState.pos)+angle
                end
                return geo:rThetaGo(pos1,700,angle)
            end
            for j=-1,1,2 do
                local pos2=getPos2(j,0)
                local mirror=Mirror(pos10,pos2,copyTable(bullet.kinematicState.pos), {lifeFrame=300,extraUpdate={Action.FadeIn(20,false,0.5),Action.FadeOut(20,false),function(self)
                    if sentry.removed and not self.flag then
                        self.flag=true
                        self.lifeFrame=self.frame+20
                    end
                    self.pos1=pos1Sentry.kinematicState.pos
                    self.pos2=getPos2(self.any.j,self.frame/300)
                    self.posIn=getPos2(0,self.frame)
                end}})
                mirror.any={j=j}
            end
            for i,bulleti in ipairs(bullets) do
                Event.EaseEvent{obj=bulleti,easeObj=bulleti.kinematicState,aims={speed=120},duration=60}
            end
            wait(60)
            for i,bulleti in ipairs(bullets) do
                Event.LoopEvent{obj=bulleti,period=5,times=48,executeFunc=function ()
                    Mirror.spawnReflections(bulleti,12)
                end}
            end
            wait(360)
            if DIFF()>=G.HARD then
                wait(240)
            end
        end
    end
}