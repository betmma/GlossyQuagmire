--[[
    a shot type should be what?
    if it equals the options seen in game (like reimu A), then it should include:
    main shot
    options
    - arrangement for each power level (both focused and unfocused. and, could involve state and player's movement like angle is opposite to player's movement) 
    - option sprite
    spellcard
    for main shot and each option (focused/unfocused), it should include:
        - bullet sprite
        - frequency
        - damage (could be a function of power level)
        - speed
        - angle (fixed or relative to option's direction)
        - mode (straight, aimed)

    make a ShootingPattern class, which includes the above information.
    make a OptionsArrangement class.
    main shot can be considered as a ShootingPattern.
    Option class, including OptionsArrangement (need to handle both focused and unfocused) and 2 ShootingPatterns (one for focused and one for unfocused).
    A ShotType includes a main shot (a ShootingPattern), 1 Option, and a spellcard (need extra design)
    All main shots: 2 rows of straight bullets
    Reimu A option:
    - unfocused: straight needle
    - focused: aimed bills
    Reimu B option:
    - unfocused: spread large amulets, large hitbox
    - focused: little spread large amulets, large hitbox
    Marisa A option:
    - unfocused: lasers turn 90 degrees after some time
    - focused: straight focusing lasers
    Marisa B option:
    - unfocused: 360 degree explosives
    - focused: spread explosives
    Kotoba A option:
    - unfocused: spread shots that stop and scatter a little
    - focused: same shots that aimed at forward (mid-range)
    Kotoba B option:
    - unfocused: papers that stop and last long time (not very useful :c)
    - focused: paper planes that move straight forward after a while
]]
---@enum fadeMode
local fadeMode={
    TRANSPARENT=1, -- change transparency to fade out
    PLAY_GIF=2, -- the sprite is the fade out GIF, and before hitting it's at first frame
    CHANGE_SPRITE=3, -- switch to a different sprite of fade out animation
}

---@class fadeStrategy
---@field mode fadeMode
---@field changeTo nil|table<color,Sprite> Sprite only for CHANGE_SPRITE mode
---@type table<string,fadeStrategy>
local fadeStrategies={
    amuletMid={mode=fadeMode.CHANGE_SPRITE,changeTo=Asset.playerShotSprites.amuletFade},
    amuletNarrow={mode=fadeMode.CHANGE_SPRITE,changeTo=Asset.playerShotSprites.amuletFade},
    amuletWide={mode=fadeMode.CHANGE_SPRITE,changeTo=Asset.playerShotSprites.amuletFade},
    poker={mode=fadeMode.CHANGE_SPRITE,changeTo=Asset.playerShotSprites.pokerFade},
    burst={mode=fadeMode.TRANSPARENT},
    laser={mode=fadeMode.TRANSPARENT},
    explosive={mode=fadeMode.PLAY_GIF},
    amuletHuge={mode=fadeMode.PLAY_GIF},
    beachBall={mode=fadeMode.PLAY_GIF},
    paper={mode=fadeMode.PLAY_GIF},
    paperPlane={mode=fadeMode.PLAY_GIF},
}

--- due to player shots move at very high speed and player will not focus on them, only a few will need mesh for high precision.
local useMesh={
    amuletHuge=true
}

-- class for player's shot (bullet)
---@class PlayerShot:Bullet
---@field hitEffect fun(self: PlayerShot, enemy: Enemy): nil called when hit an enemy. effects like switching to a fade out animation
---@field fadeStrategy fadeStrategy
PlayerShot=Bullet:extend()

PlayerShot.meshDrawQuad=Shape.meshDrawQuad

function PlayerShot:new(args)
    PlayerShot.super.new(self, args)
    self.fromPlayer=true
    self.fadeStrategy=fadeStrategies[args.sprite.data.key]
    if self.sprite then
        local data=self.sprite.data
        if data.isGIF then
            self.sprite--[[@as GIFSprite]]:reset() -- Bullet.new randomizes gif frame. for player shot, we want all bullets to start from the first frame, since it's a fade out animation
        end
    end
end

-- doesn't hit player
function PlayerShot:checkHitPlayer()
end

function PlayerShot:hitEffect(enemy)
    self.safe=true
    self.hasHitEnemy=true
    self.homing=false
    if not self.fadeStrategy then 
        self:remove()
        return
    end
    if self.fadeStrategy.mode==fadeMode.TRANSPARENT then
        self.extraUpdate=self.extraUpdate or {}
        table.insert(self.extraUpdate,Action.FadeOut(10,false))
        self.lifeFrame=self.frame+10
    elseif self.fadeStrategy.mode==fadeMode.CHANGE_SPRITE then
        local color=self.sprite.data.color
        local newSprite=self.fadeStrategy.changeTo[color]
        self:changeSprite(newSprite)
        if self.sprite.data.isGIF then
            local sprite=self.sprite
            ---@cast sprite GIFSprite
            sprite:reset()
            local loopTime=sprite:getDuration()
            self.extraUpdate=self.extraUpdate or {}
            table.insert(self.extraUpdate,Action.FadeOut(loopTime,false))
            self.lifeFrame=self.frame+loopTime
        end
    elseif self.fadeStrategy.mode==fadeMode.PLAY_GIF then
        local sprite=self.sprite
        ---@cast sprite GIFSprite
        sprite:reset()
        self.extraUpdate=self.extraUpdate or {}
        table.insert(self.extraUpdate,Action.FadeOut(sprite:getDuration(),false))
        self.lifeFrame=self.frame+sprite:getDuration()
    end
    self.kinematicState.speed=200
end

function PlayerShot:updateSprite()
    self.spriteExtraDirection=self.spriteExtraDirection+self.spriteRotationSpeed*Shape.timeSpeed
    if self.hasHitEnemy then
        if self.sprite.data.isGIF then
            self.sprite--[[@as GIFSprite]]:countDown()
        end
    end
end

---@enum HOMING_MODE
local HOMING_MODE={
    ABRUPT=1, -- directly change direction to aim at target. ignore arg
    PORTION=2, -- change direction by a portion of the angle to target
    CLAMP=3, -- change direction by a max angle towards the target
}

local function findClosestEnemy(bullet)
    local closestDistance=bullet.homingDistance or 9e9
    local closestEnemy
    local enemyClasses={Enemy, Boss}
    for _, enemyClass in pairs(enemyClasses) do
        for _, value in ipairs(enemyClass.objects) do
            ---@cast value Enemy
            local dis=G.runInfo.geometry:distance(bullet.kinematicState.pos,value.kinematicState.pos)
            if dis<closestDistance then
                closestDistance=dis
                closestEnemy=value
            end
        end
    end
    return closestEnemy
end

---@param bullet PlayerShot
---@param mode HOMING_MODE
---@param arg number
local function addHoming(bullet,mode,arg)
    mode=mode or HOMING_MODE.ABRUPT
    if mode==HOMING_MODE.PORTION then
        arg=arg or 0.1
    elseif mode==HOMING_MODE.CLAMP then
        arg=arg or 0.1
    end
    bullet.homing=true
    local closestEnemy=findClosestEnemy(bullet)
    Event.LoopEvent{
        obj=bullet,
        period=1,
        executeFunc=function(self,times)
            if not bullet.homing then -- some level effect removing homing
                return
            end
            if times%15==1 then -- only update target every 15 frames for performance
                closestEnemy=findClosestEnemy(bullet)
            end
            if closestEnemy and not closestEnemy.removed then
                local aim=math.modClamp(G.runInfo.geometry:to(bullet.kinematicState.pos,closestEnemy.kinematicState.pos),bullet.kinematicState.dir)
                if mode==HOMING_MODE.ABRUPT then
                    bullet.kinematicState.dir=aim
                elseif mode==HOMING_MODE.PORTION then
                    bullet.kinematicState.dir=(1-arg)*bullet.kinematicState.dir+arg*aim
                elseif mode==HOMING_MODE.CLAMP then
                    local da=arg
                    bullet.kinematicState.dir=math.clamp(aim,bullet.kinematicState.dir-da,bullet.kinematicState.dir+da)
                end
            end
        end
    }
end

---@class ShootingPattern:Object
---@field sprite Sprite
---@field size number
---@field frequency integer
---@field damage fun(self: ShootingPattern, powerLevel: integer): number
---@field lifeFrame integer
---@field speed number
---@field angle number|string will be fed to math.eval(). can be 'a+b'
---@field isHoming boolean whether the bullet is homing. if true, addHoming will be called on the bullet after it's created
---@field homingMode HOMING_MODE the mode for homing. Only works when isHoming is true
---@field homingArg number the argument for homingMode. Only works when isHoming is true
---@field update fun(self: ShootingPattern, dt: number): boolean whether call shoot
---@field frame integer
---@field shotCount integer
---@field transformShootState fun(self: ShootingPattern, shooter: KinematicState): KinematicState get the position and direction to shoot based on shooter state, used for main shot to spawn at front of player instead of center. defaults to returning shooter.
---@field shoot fun(self: ShootingPattern, shooter: KinematicState, powerLevel: integer, optionIndex:integer): nil
---@overload fun(args: ShootingPatternArgs): ShootingPattern
local ShootingPattern=Object:extend()

---@class ShootingPatternArgs
---@field sprite Sprite
---@field size number|nil
---@field frequency integer|nil
---@field damage number|fun(self: ShootingPattern, powerLevel: integer): number
---@field lifeFrame integer|nil
---@field speed number|nil
---@field angle number|string
---@field isHoming boolean|nil
---@field homingMode HOMING_MODE|nil
---@field homingArg number|nil
---@field transformShootState nil|fun(self: ShootingPattern, shooter: KinematicState): KinematicState
---@field fadeIn boolean|nil
---@field extraUpdate function|nil

function ShootingPattern:new(args)
    self.sprite=args.sprite
    self.size=args.size or 1.5
    self.frequency=args.frequency or 3
    self.damage=args.damage
    self.lifeFrame=args.lifeFrame or 60
    self.speed=args.speed or 1200
    self.angle=args.angle
    self.isHoming=args.isHoming
    self.homingMode=args.homingMode
    self.homingArg=args.homingArg
    self.transformShootState=args.transformShootState or function(self, shooter) return shooter end
    self.fadeIn=args.fadeIn~=false
    self.extraUpdate=args.extraUpdate
    self.frame=0
    self.shotCount=0
end

function ShootingPattern:reset()
    self.frame=0
    self.shotCount=0
end

function ShootingPattern:update(dt)
    self.frame=self.frame+1
    if self.frame>=self.frequency then
        self.frame=0
        self.shotCount=self.shotCount+1
        return true
    end
    return false
end

function ShootingPattern:shoot(shooter, powerLevel, optionIndex)
    local shootState=self:transformShootState(shooter)
    local direction=shootState.dir
    direction=direction+math.eval(self.angle)
    local useMesh=useMesh[self.sprite.data.key]
    local bullet=PlayerShot{kinematicState={pos=copyTable(shootState.pos), speed=self.speed, dir=direction},sprite=self.sprite,size=self.size,damage=self:damage(powerLevel),lifeFrame=self.lifeFrame,batch=Asset.playerBulletBatch,meshBatch=Asset.playerBulletMeshes,extraUpdate={Action.FadeOut(2,false),self.fadeIn and Action.FadeIn(1,false) or nil},forceQuad=not useMesh}
    bullet.shotCount=self.shotCount
    bullet.optionIndex=optionIndex
    if self.sprite.data.key=='amuletHuge' then
        bullet.spriteRotationSpeed=math.pi/10
        bullet.spriteExtraDirection=math.eval(0,999)
        bullet.extraUpdate[2].params.fadeTransparency=0.5
    end
    if self.extraUpdate then
        bullet.extraUpdate[#bullet.extraUpdate+1] = self.extraUpdate
    end
    if self.isHoming then
        addHoming(bullet, self.homingMode, self.homingArg)
    end
end

---@alias OptionArrangement fun(powerLevel: integer, isFocused: boolean, playerState: KinematicState, frame:integer): KinematicState[] positions and directions of options. normally options number equals powerLevel
---@alias PlayerSpellcardFunc fun(playerState: KinematicState, isFocused: boolean): nil -- spellcard is kinda complex so just make it a function. though not planned to have different spellcards for focused/unfocused, the param is there
---@class PlayerSpellcard
---@field duration integer duration of spellcard in frames. used for player to set duringBomb state.
---@field canShoot boolean whether player can shoot during spellcard.
---@field func PlayerSpellcardFunc the actual spellcard function

---@class ShotType:Object
---@field mainShot ShootingPattern[]
---@field optionSprite Sprite
---@field optionArrangement OptionArrangement
---@field optionShot {focused: ShootingPattern[], unfocused: ShootingPattern[]}
---@field spellcard PlayerSpellcard
---@field update fun(self: ShotType, playerState: KinematicState, isFocused: boolean, isShooting: boolean, powerLevel: integer, frame: integer, dt: number, options: Bullet[], optionTransparency: number): nil update options position and shoot with optionShot
---@overload fun(args: ShotTypeArgs): ShotType
local ShotType=Object:extend()

---@class ShotTypeArgs
---@field mainShot ShootingPattern[]
---@field optionSprite Sprite
---@field optionArrangement OptionArrangement
---@field optionShot {focused: ShootingPattern[], unfocused: ShootingPattern[]}
---@field spellcard PlayerSpellcard
function ShotType:new(args)
    self.mainShot=args.mainShot
    self.optionSprite=args.optionSprite
    self.optionArrangement=args.optionArrangement
    self.optionShot=args.optionShot
    self.spellcard=args.spellcard
end

function ShotType:reset()
    for i,shot in ipairs(self.mainShot) do
        shot:reset()
    end
    for i,shot in ipairs(self.optionShot.focused) do
        shot:reset()
    end
    for i,shot in ipairs(self.optionShot.unfocused) do
        shot:reset()
    end
end

function ShotType:update(playerState, isFocused, isShooting, powerLevel, frame, dt, options, optionTransparency)
    -- main shot
    if isShooting then
        for i, pattern in ipairs(self.mainShot) do
            if pattern:update(dt) then
                pattern:shoot(playerState, powerLevel, i)
            end
        end
    end
    -- spawn or remove options based on power level
    local existingOptions=#options
    if existingOptions>powerLevel then
        for i=existingOptions, powerLevel+1, -1 do
            options[i]:remove()
            options[i]=nil
        end
    elseif existingOptions<powerLevel then
        for i=existingOptions,powerLevel do
            local newOption=Bullet{kinematicState={pos=playerState.pos,dir=0,speed=0},sprite=self.optionSprite,lifeFrame=99999,safe=true,invincible=true,fromPlayer=true,batch=Asset.playerBulletBatch,meshBatch=Asset.playerBulletMeshes}
            newOption.spriteRotationSpeed=0.1
            table.insert(options, newOption)
        end
    end
    -- update options position and shoot with optionShot
    if powerLevel==0 then
        return
    end
    for i, option in ipairs(options) do
        option.spriteTransparency=optionTransparency
    end
    local optionStates=self.optionArrangement(powerLevel, isFocused, playerState, frame)
    for i, optionState in pairs(optionStates) do
        local nowPos=options[i].kinematicState.pos
        local aimPos=optionState.pos
        local distance=G.runInfo.geometry:distance(nowPos, aimPos)
        local dir=G.runInfo.geometry:to(nowPos, aimPos)
        options[i].kinematicState.pos=G.runInfo.geometry:rThetaGo(nowPos, distance*0.3, dir)
        options[i].kinematicState.dir=optionState.dir
    end
    if isShooting then
        local optionPatterns=isFocused and self.optionShot.focused or self.optionShot.unfocused
        for j, pattern in ipairs(optionPatterns) do
            if pattern:update(dt) then
                for i, option in ipairs(options) do
                    pattern:shoot(option.kinematicState, powerLevel, i)
                end
            end
        end
    end
end

---@param isLeft boolean whether it's left or right row, used for main shot transform
local function mainShotTransform(isLeft)
    ---@type fun(self: ShootingPattern, shooter: KinematicState): KinematicState
    return function(self, shooter)
        local forwardPos,forwardDir=G.runInfo.geometry:rThetaGo(shooter.pos, -10, shooter.dir)
        local deltaDir=math.pi/2*(isLeft and -1 or 1)
        local turnDir=forwardDir+deltaDir
        local sidePos,sideDir=G.runInfo.geometry:rThetaGo(forwardPos, 8, turnDir)
        return {pos=sidePos,dir=sideDir-deltaDir,speed=0}
    end
end

---@type ShootingPatternArgs
local mainShotArgsTemplate={
    sprite=Asset.playerShotSprites.amuletMid.red,
    frequency=5,
    damage=function(self, powerLevel) return 10-powerLevel end,
    angle=0,
}

local function applyTemplate(template,args)
    local newArgs=copyTable(template)
    for k,v in pairs(args) do
        newArgs[k]=v
    end
    return newArgs
end

local function buildMainShot(args)
    local leftArgs=applyTemplate(mainShotArgsTemplate,args)
    leftArgs.transformShootState=mainShotTransform(true)
    local rightArgs=applyTemplate(mainShotArgsTemplate,args)
    rightArgs.transformShootState=mainShotTransform(false)
    return {ShootingPattern(leftArgs), ShootingPattern(rightArgs)}
end

---@type PlayerSpellcardFunc
local function reimuSpellcardFunc(playerState, isFocused)
    Event{obj=G.runInfo.player,action=function()
        local bigAmulet=PlayerShot{kinematicState={pos=copyTable(playerState.pos), speed=0, dir=0},sprite=Asset.playerShotSprites.amuletHuge,size=0,damage=12,lifeFrame=300,batch=Asset.playerBulletBatch,meshBatch=Asset.playerBulletMeshes,extraUpdate={Action.FadeIn(10,false),Action.ZoomIn(30,5),function(self)
            -- create shockwave regularly to clear bullets (ughh lame)
            if self.frame%10==1 then
                Effect.Shockwave{kinematicState=self.kinematicState,animationFrame=10,size=self.size/2,growSpeed=0.3,spriteTransparency=0.5,color='red',canRemove={bullet=true,invincible=false,safe=true,bulletSpawner=false}}
            end
            if self.frame>265 then
                self.sprite:countDown() -- start fade out animation when about to end
                self.spriteTransparency=self.spriteTransparency-0.01
            end
        end},forceMesh=true}
        bigAmulet.hitEffect=function(self, enemy) -- override hit effect to prevent it from disappearing. it will keep damaging
        end
        
        bigAmulet.spriteRotationSpeed=math.pi/10
        bigAmulet.spriteExtraDirection=math.eval(0,999)
        bigAmulet.extraUpdate[2].params.fadeTransparency=0.5
        wait(60)
        -- starting to aim for enemies
        addHoming(bigAmulet, HOMING_MODE.ABRUPT, 0.2)
        bigAmulet.kinematicState.speed=300
    end}
end

local reimuSpellcard={duration=300, canShoot=true, func=reimuSpellcardFunc}

---@type table<SHOT_TYPE, ShotType>
local ShotTypes={
    REIMUA=ShotType{
        mainShot=buildMainShot{
            sprite=Asset.playerShotSprites.amuletMid.red,
            damage=function(self, powerLevel) return 10-powerLevel end
        },
        optionSprite=Asset.playerShotSprites.yinyangOrb.red,
        optionArrangement=function(powerLevel, isFocused, playerState, frame)
            local radius=30
            local angle=playerState.dir
            ---@type KinematicState[]
            local returnStates={}
            for i=1,powerLevel do
                local optionAngle
                if isFocused then
                    optionAngle=math.pi/9*(i-powerLevel/2-0.5)
                else
                    optionAngle=math.pi*2/powerLevel*(i-1)+frame*math.pi/25
                end
                local optionPos,optionAngle2=G.runInfo.geometry:rThetaGo(playerState.pos, radius, angle+optionAngle)
                optionAngle2=optionAngle2-optionAngle -- let it face upward (bullets move upward)
                table.insert(returnStates,{pos=optionPos, dir=optionAngle2, speed=0})
            end
            return returnStates
        end,
        optionShot={focused={ShootingPattern{
            sprite=Asset.playerShotSprites.amuletNarrow.purple,
            frequency=5,
            damage=function(self, powerLevel) return 3 end,
            angle=0,
            isHoming=true,
            homingMode=HOMING_MODE.PORTION,
            homingArg=0.2,
        }}, unfocused={ShootingPattern{
            sprite=Asset.playerShotSprites.burst.orange,
            frequency=5,
            damage=function(self, powerLevel) return 4 end,
            angle=0,
        }}},
        spellcard=reimuSpellcard
    }
}
ShotTypes.REIMUB=ShotType{
    mainShot=ShotTypes.REIMUA.mainShot,
    optionSprite=Asset.playerShotSprites.yinyangOrb.blue,
        optionArrangement=function(powerLevel, isFocused, playerState, frame)
            local radius=30
            local angle=playerState.dir
            ---@type KinematicState[]
            local returnStates={}
            for i=1,powerLevel do
                local optionAngle
                if isFocused then
                    optionAngle=math.pi/9*(i-powerLevel/2-0.5)
                else
                    optionAngle=math.pi/4*(i-powerLevel/2-0.5)
                end
                local optionPos,optionAngle2=G.runInfo.geometry:rThetaGo(playerState.pos, radius, angle+optionAngle)
                if isFocused then 
                    optionAngle2=optionAngle2-optionAngle*0.5 -- still scatters (bullets move away from center, not upward)
                end
                table.insert(returnStates,{pos=optionPos, dir=optionAngle2, speed=0})
            end
            return returnStates
        end,
    optionShot={focused={ShootingPattern{
        sprite=Asset.playerShotSprites.amuletHuge,
        frequency=8,
        damage=function(self, powerLevel) return 6 end,
        angle=0,
        size=0.75
    }}, unfocused={ShootingPattern{
        sprite=Asset.playerShotSprites.amuletHuge,
        frequency=8,
        damage=function(self, powerLevel) return 8 end,
        angle='0+0.1',
        size=0.75
    }}},
    spellcard=reimuSpellcard
}


---@type PlayerSpellcardFunc
local function marisaSpellcardFunc(playerState, isFocused)
    Event{obj=G.runInfo.player,action=function()
        for i=1,80 do
            if i%5==0 then
                local num=math.floor(i/5)
                local colors=BulletSprites.shockwave.blue.data.possibleColors or {'red'}
                local color=colors[num%#colors+1]
                Effect.Shockwave{kinematicState=copyTable(G.runInfo.player.kinematicState),animationFrame=20,size=1,growSpeed=0.15,spriteTransparency=0.5,color=color,canRemove={bullet=true,invincible=false,safe=true,bulletSpawner=false}}
            end
            local dirBase=G.runInfo.player.viewDirection-math.pi/2+math.mod2Sign(i)*0.2*(i%5/5)
            local star=PlayerShot{kinematicState={pos=copyTable(G.runInfo.player.kinematicState.pos), speed=900, dir=dirBase},sprite=BulletSprites.bigStar.blue,size=0,damage=3,lifeFrame=30,batch=Asset.bulletBatch,meshBatch=Asset.bigBulletMeshes,extraUpdate={Action.FadeIn(3,false),Action.ZoomIn(8,2),Action.Trail(9,2)}}
            star.i=i
            star:changeSpriteColor()
            star.hitEffect=function(self, enemy) -- override hit effect to prevent it from disappearing. it will keep damaging
            end
            star.spriteRotationSpeed=math.pi/5
            wait(3)
        end
    end}
end

local marisaSpellcard={duration=300, canShoot=true, func=marisaSpellcardFunc}

ShotTypes.MARISAA=ShotType{
    mainShot=buildMainShot{
        size=1,
        sprite=Asset.playerShotSprites.explosive.green,
        damage=function(self, powerLevel) return 10-powerLevel end
    },
    optionSprite=Asset.playerShotSprites.hakkero.green,
    optionArrangement=function(powerLevel, isFocused, playerState, frame)
        local radius=30
        local angle=playerState.dir
        ---@type KinematicState[]
        local returnStates={}
        if isFocused then -- evenly scatter on the line radius distance to player
            local pos1,dir1=G.runInfo.geometry:rThetaGo(playerState.pos, radius, angle)
            dir1=dir1+math.pi/2
            local posAim=G.runInfo.geometry:rThetaGo(playerState.pos, 250, angle)
            for i=1,powerLevel do
                local distance=40*(i-powerLevel/2-0.5)
                local optionPos=G.runInfo.geometry:rThetaGo(pos1, distance, dir1)
                local optionAngle=G.runInfo.geometry:to(optionPos, posAim)
                table.insert(returnStates,{pos=optionPos, dir=optionAngle, speed=0})
            end
            return returnStates
        end
        for i=1,powerLevel do
            local optionAngle
            optionAngle=math.pi/4*(i-powerLevel/2-0.5)
            local optionPos,optionAngle2=G.runInfo.geometry:rThetaGo(playerState.pos, radius, angle+optionAngle)
            optionAngle2=optionAngle2-optionAngle*0.5 -- still scatters (away from center, not upward)
            table.insert(returnStates,{pos=optionPos, dir=optionAngle2, speed=0})
        end
        return returnStates
    end,
    optionShot={focused={ShootingPattern{
        sprite=Asset.playerShotSprites.laser,
        frequency=2,
        damage=function(self, powerLevel) return 2 end, -- straight shot similar to reimu b but with higher dps (note freq is 4x of reimu b) due to laser smaller than big amulet
        angle=0,
        size=1.5,fadeIn=false
    }}, unfocused={ShootingPattern{
        sprite=Asset.playerShotSprites.laser,
        frequency=2,
        damage=function(self, powerLevel) return 1.5 end,
        angle=0,
        size=1.5,fadeIn=false,extraUpdate=function(self)
            if self.frame==15 then
                self.kinematicState.dir=self.kinematicState.dir+math.pi/2
            end
        end
        },ShootingPattern{
        sprite=Asset.playerShotSprites.laser,
        frequency=2,
        damage=function(self, powerLevel) return 1.5 end,
        angle=0,
        size=1.5,fadeIn=false,extraUpdate=function(self)
            if self.frame==15 then
                self.kinematicState.dir=self.kinematicState.dir-math.pi/2
            end
        end
    }}},
    spellcard=marisaSpellcard
}

local marisabOption=function(angle,damage,freq)
    local func=damage
    if type(damage)=="number" then
        func=function(self, powerLevel) return damage end
    end
    return ShootingPattern{
        sprite=Asset.playerShotSprites.explosive.blue,
        frequency=freq or 8,
        damage=func,
        angle=angle,
        size=1.5
    }
end
local marisabOptionUnfocusedDmg=function(self, powerLevel)
    local values={10,7,6,5}
    return values[powerLevel] or 5
end
local mOUD=marisabOptionUnfocusedDmg
ShotTypes.MARISAB=ShotType{
    mainShot=ShotTypes.MARISAA.mainShot,
    optionSprite=Asset.playerShotSprites.hakkero.cyan,
    optionArrangement=function(powerLevel, isFocused, playerState, frame)
        local radius=30
        local angle=playerState.dir
        ---@type KinematicState[]
        local returnStates={}
        for i=1,powerLevel do
            local optionAngle
            if isFocused then
                optionAngle=math.pi/9*(i-powerLevel/2-0.5)
            else
                optionAngle=math.pi*2/powerLevel*(i-1)+frame*math.pi/25
            end
            local optionPos,optionAngle2=G.runInfo.geometry:rThetaGo(playerState.pos, radius, angle+optionAngle)
            if isFocused then 
                optionAngle2=optionAngle2-optionAngle -- let it face upward (bullets move upward)
            end
            table.insert(returnStates,{pos=optionPos, dir=optionAngle2, speed=0})
        end
        return returnStates
    end,
    optionShot={focused={marisabOption(-0.2,2),marisabOption(0,2),marisabOption(0.2,2),},
    unfocused={marisabOption(-0.2,mOUD,6),marisabOption(0,mOUD,6),marisabOption(0.2,mOUD,6),}},
    spellcard=marisaSpellcard
}


---@type PlayerSpellcardFunc
local function kotobaSpellcardFunc(playerState, isFocused)
    Event{obj=G.runInfo.player,action=function()
        local beachBall=PlayerShot{kinematicState={pos=copyTable(playerState.pos), speed=0, dir=0},sprite=Asset.playerShotSprites.beachBall,size=0,damage=0,safe=true,lifeFrame=300,batch=Asset.playerBulletBatch,meshBatch=Asset.playerBulletMeshes,extraUpdate={Action.FadeIn(10,false),Action.ZoomIn(30,5),function(self)
            self.kinematicState.pos=G.runInfo.player.kinematicState.pos -- follow player. not using bindState is because its dir will be changed by player's moving direction
            if self.frame>265 then
                self.sprite:countDown() -- start fade out animation when about to end
                self.spriteTransparency=self.spriteTransparency-0.01
            end
        end},forceMesh=true}
        local reflectShockwave=Effect.Shockwave{kinematicState=copyTable(beachBall.kinematicState),animationFrame=300,size=0,growSpeed=0.09,spriteTransparency=0.5,color='red',canRemove={bullet=true,invincible=false,safe=true,bulletSpawner=false},effectFunc=function(self,bullet)
            -- cannot actually reflect and make it damage enemy. create a new PlayerShot bullet instead.
            if bullet.reflectedFlag then
                return
            end
            bullet.reflectedFlag=true
            local enemy=findClosestEnemy(bullet)
            local dir
            if enemy then
                dir=G.runInfo.geometry:to(bullet.kinematicState.pos,enemy.kinematicState.pos)
                local playerShot=PlayerShot{kinematicState={pos=copyTable(bullet.kinematicState.pos), speed=800, dir=dir},sprite=bullet.sprite,size=bullet.size,damage=2,lifeFrame=120,batch=bullet.batch,meshBatch=bullet.meshBatch,extraUpdate={Action.FadeOut(5,false)},forceQuad=bullet.forceQuad,forceMesh=bullet.forceMesh,fromPlayer=true,invincible=true}
                bullet:remove()
            else
                local dirTouch=G.runInfo.geometry:to(bullet.kinematicState.pos, self.kinematicState.pos)+math.pi
                local bulletDir=math.modClamp(bullet.kinematicState.dir,dirTouch)
                dir=dirTouch*2-bulletDir
                bullet.kinematicState.dir=dir
            end
        end}
        reflectShockwave:bindState(G.runInfo.player)
        beachBall.hitEffect=function(self, enemy) -- override hit effect to prevent it from disappearing. though safe=true means this wont be called
        end
        for i=1,180 do
            wait()
            beachBall.spriteRotationSpeed=math.pi/3600*i
            if i==30 then
                reflectShockwave.growSpeed=0
            end
        end
        wait(60)
    end}
end

local kotobaSpellcard={duration=300, canShoot=true, func=kotobaSpellcardFunc}

local kotobaAAimDistance=300
local scatterExtraUpdate=function(self)
    if self.frame==0 then
        self.aim=G.runInfo.geometry:rThetaGo(self.kinematicState.pos, kotobaAAimDistance, self.kinematicState.dir)
        self.kinematicState.dir=self.kinematicState.dir+math.eval(0,1.5)
    elseif not self.flag then
        local aimdir=math.modClamp(G.runInfo.geometry:to(self.kinematicState.pos, self.aim),self.kinematicState.dir)
        self.kinematicState.dir=math.clamp(aimdir, self.kinematicState.dir-math.pi/10, self.kinematicState.dir+math.pi/10)
        if G.runInfo.geometry:distance(self.kinematicState.pos, self.aim)<30 then
            self.flag=true
        end
    elseif not self.flag2 then
        self.kinematicState.dir=self.kinematicState.dir+self.shotCount*1+self.optionIndex*math.pi/4
        self.kinematicState.speed=400
        self.flag2=true
        self.lifeFrame=self.frame+5
    end
end
ShotTypes.KOTOBAA=ShotType{
    mainShot=buildMainShot{
        size=1,
        sprite=Asset.playerShotSprites.poker.purple,
        damage=function(self, powerLevel) return 10-powerLevel end
    },
    optionSprite=Asset.playerShotSprites.ball.purple,
    optionArrangement=function(powerLevel, isFocused, playerState, frame)
        local radius=30
        local angle=playerState.dir
        ---@type KinematicState[]
        local returnStates={}
        if isFocused then -- rotating and aimed at a far point
            local posAim=G.runInfo.geometry:rThetaGo(playerState.pos, kotobaAAimDistance, angle)
            for i=1,powerLevel do
                local optionAngle=math.pi*2/powerLevel*(i-1)+frame*math.pi/25
                local optionPos,dir1=G.runInfo.geometry:rThetaGo(playerState.pos, radius, optionAngle)
                local optionAngle=G.runInfo.geometry:to(optionPos, posAim)
                table.insert(returnStates,{pos=optionPos, dir=optionAngle, speed=0})
            end
            return returnStates
        end
        for i=1,powerLevel do
            local optionAngle
            optionAngle=math.pi/4*(i-powerLevel/2-0.5)
            local optionPos,optionAngle2=G.runInfo.geometry:rThetaGo(playerState.pos, radius, angle+optionAngle)
            optionAngle2=optionAngle2-optionAngle*0.5 -- still scatters (away from center, not upward)
            table.insert(returnStates,{pos=optionPos, dir=optionAngle2, speed=0})
        end
        return returnStates
    end,
    optionShot={focused={ShootingPattern{
        sprite=Asset.playerShotSprites.poker.blue,
        frequency=2,
        damage=function(self, powerLevel) return 3 end,
        angle=0,
        size=1,extraUpdate=scatterExtraUpdate
    }}, unfocused={ShootingPattern{
        sprite=Asset.playerShotSprites.poker.blue,
        frequency=2,
        damage=function(self, powerLevel) return 2 end,
        angle=0,
        size=1,extraUpdate=scatterExtraUpdate
    }}},
    spellcard=kotobaSpellcard
}

ShotTypes.KOTOBAB=ShotType{
    mainShot=ShotTypes.KOTOBAA.mainShot,
    optionSprite=Asset.playerShotSprites.ball.red,
    optionArrangement=ShotTypes.KOTOBAA.optionArrangement,
    optionShot={focused={ShootingPattern{
        sprite=Asset.playerShotSprites.paperPlane,
        frequency=6,
        damage=function(self, powerLevel) return 6 end,
        angle=0,
        lifeFrame=180,
        speed=0,
        fadeIn=false,
        size=1,extraUpdate=function (self)
            if self.frame==0 then
                self.spriteTransparency=0.2
            end
            if self.frame==120 then
                self.spriteTransparency=1
                self.kinematicState.speed=1200
            end
        end
    }}, unfocused={ShootingPattern{
        sprite=Asset.playerShotSprites.paper,
        frequency=6,
        damage=function(self, powerLevel) return 7.5 end,
        angle=0,
        lifeFrame=600,
        size=1,extraUpdate=function (self)
            if self.frame==30 then
                self.kinematicState.speed=0
            end
        end
    }}},
    spellcard=kotobaSpellcard
}

return ShotTypes