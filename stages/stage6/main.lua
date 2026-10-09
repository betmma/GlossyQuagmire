---@type OneStageDataRaw
return{
    init=function(stageKey)
        -- G:replaceBackgroundPatternIfNot(BackgroundPattern.SphericalGrid)
        StageManager.commonStageInit(stageKey)
    end,
    segments={
        {
            key='6-1',
            type='midStage',
            func=function() -- 20s
                local geo=G.runInfo.geometry
                local player=G.runInfo.player
                local sign=math.randomSign()
                local extraUpdate2={Action.FadeOut(10,true),Action.Trail(12,4),function(self)
                    local t=math.sin(self.frame/5)*0.2+0.6
                    self.spriteColor={1,t,t,1}
                end}
                local function swirl(self)
                    SFX:play('enemyPowerfulShot')
                    local dir0=geo:to(self.kinematicState.pos,player.kinematicState.pos)
                    local period=5
                    BulletSpawner{kinematicState={pos=copyTable(self.kinematicState.pos),dir=self.kinematicState.dir,speed=self.kinematicState.speed},lifeFrame=240,bulletSize=2,firstPeriod=1,period=period,bulletNumber=15,range=math.pi,angle=dir0,bulletSprite=BulletSprites.scaleDark.white,bulletSpeed=100,bulletLifeFrame=360,bulletExtraUpdate={Action.FadeOut(10,true),function(self)
                        if self.any then
                            if self.frame==math.ceil(self.lifeFrame/2) then
                                self.kinematicState.dir=geo:to(self.kinematicState.pos,player.kinematicState.pos)
                                self.lifeFrame=self.frame+180
                                self.kinematicState.speed=200
                                self.extraUpdate=extraUpdate2
                                SFX:play('enemyShot')
                                return
                            end
                        end
                        self.kinematicState.dir=self.kinematicState.dir+math.pi/self.lifeFrame*sign
                    end},bulletEvents={function (cir,args,self)
                        local index=args.index
                        if index==1 then
                            self.angle=self.angle-math.pi/24*period/10*sign
                            self.bulletSpeed=self.bulletSpeed+period*2
                            self.bulletLifeFrame=self.bulletLifeFrame-period
                        end
                        if (index-self.spawnTimes%2)%self.bulletNumber==0 and DIFF()>G.LUNATIC then -- it's too complex for lunatic so leave for overdrive lol
                            cir.any=true
                        end
                    end}}
                end
                local function dieEffect(self)
                    local n=80
                    ---@cast geo Spherical
                    local antipode=geo:rThetaGo(self.kinematicState.pos,geo.radius*math.pi,0)
                    Bullet{kinematicState={pos=antipode,dir=0,speed=0},safe=true,highlight=true,sprite=BulletSprites.cross.red,spriteColor={1,0.2,0.2,1},extraUpdate={Action.FadeIn(20,false),Action.FadeOut(20,false)},lifeFrame=690*60/200,size=4}
                    BulletSpawner{kinematicState={pos=copyTable(self.kinematicState.pos),dir=0,speed=0},lifeFrame=3,firstPeriod=1,period=9,bulletNumber=n,range=math.pi*2*n/DSWITCH{3,5,7,5^0.5},angle='player',bulletSprite=BulletSprites.bigStar.white,bulletSpeed=200,bulletLifeFrame=360,bulletExtraUpdate={Action.ZoomIn(10),Action.FadeOut(10,true),},bulletEvents={function (cir,args,self)
                        local index=args.index
                        if index%2==0 then
                            cir:changeSpriteColor('black')
                        end
                        cir.kinematicState.speed=cir.kinematicState.speed+index*3
                        cir.size=0.8+index/n
                        cir.spriteRotationSpeed=0.08
                        cir.lifeFrame=690*60/cir.kinematicState.speed+10
                        cir.spriteColor={0.8,0.8,1,1}
                    end}}
                end
                local function spawnFairy(pos,dir,speed)
                    local fairy=Enemy{kinematicState=copyTable{pos=pos,dir=dir or 0,speed=speed or 0},maxhp=20,sprite=Asset.fairySprites.large.black,lifeFrame=300,extraUpdate={Enemy.presetActions.fadeAndHint,Action.Finale(20)},dropItems={powerSmall=10,point=5},extraDieEffects={dieEffect}}
                    fairy:addHPProtection(180,99)
                    swirl(fairy)
                end
                local init=geo:init()
                local pos1,dir1=geo:rThetaGo(player.kinematicState.pos,300,player.viewDirection-math.pi/2)
                spawnFairy(pos1)
                wait(300)
                pos1,dir1=geo:rThetaGo(player.kinematicState.pos,300,player.viewDirection-math.pi/2)
                spawnFairy(pos1,math.eval(dir1,1.5),100)
                wait(300)
                pos1,dir1=geo:rThetaGo(player.kinematicState.pos,300,player.viewDirection-math.pi/2)
                spawnFairy(pos1,math.eval(dir1,1.5),150)
                wait(300)
                DynamicUIObjs.showStageTitle('stage6')
                wait(300)
            end
        }
    }
}