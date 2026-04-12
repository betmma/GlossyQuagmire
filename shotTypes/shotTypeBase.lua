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
    Reimu main shot: 2 rows of homing bills
    Reimu A option:
    - unfocused: straight needle
    - focused: aimed bills, half of them have weaker aiming
    Reimu B option:
    - unfocused: angle waving large bullets
    - focused: straight large bullets, large hitbox
    Marisa main shot: 2 rows of straight bullets
    Marisa A option:
    - unfocused: straight piercing lasers
    - focused: straight explosive bullets
    Marisa B option:
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
}

-- class for player's shot (bullet)
---@class PlayerShot:Bullet
---@field hitEffect fun(self: PlayerShot, enemy: Enemy): nil called when hit an enemy. effects like switching to a fade out animation
---@field fadeStrategy fadeStrategy
PlayerShot=Bullet:extend()

function PlayerShot:new(args)
    PlayerShot.super.new(self, args)
    self.fadeStrategy=fadeStrategies[args.sprite.data.key]
    if self.sprite then
        local data=self.sprite.data
        if data.isGIF then
            self.sprite:reset() -- Bullet.new randomizes gif frame. for player shot, we want all bullets to start from the first frame, since it's a fade out animation
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
    if self.fadeStrategy.mode==fadeMode.TRANSPARENT then
        self.extraUpdate=self.extraUpdate or {}
        table.insert(self.extraUpdate,Bullet.FadeOut(10,false))
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
            table.insert(self.extraUpdate,Bullet.FadeOut(loopTime,false))
            self.lifeFrame=self.frame+loopTime
        end
    end
    self.kinematicState.speed=200
end

function PlayerShot:updateSprite()
    self.spriteExtraDirection=self.spriteExtraDirection+self.spriteRotationSpeed*Shape.timeSpeed
    if self.hasHitEnemy then
        if self.sprite.data.isGIF then
            self.sprite:countDown()
        end
    end
end

---@enum HOMING_MODE
local HOMING_MODE={
    ABRUPT=1, -- directly change direction to aim at target
    PORTION=2, -- change direction by a portion of the angle to target
    CLAMP=3, -- change direction by a max angle towards the target
}

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
    local closestEnemy
    Event.LoopEvent{
        obj=bullet,
        period=1,
        executeFunc=function(self,times)
            if not bullet.homing then -- some level effect removing homing
                return
            end
            local closestDistance=bullet.homingDistance or 9e9
            if times%15==1 then -- only update target every 15 frames for performance
                local enemyClasses={Enemy, Boss}
                for _, enemyClass in pairs(enemyClasses) do
                    for key, value in pairs(enemyClass.objects) do
                        ---@cast value Enemy
                        local dis=G.runInfo.geometry:distance(bullet.kinematicState.pos,value.kinematicState.pos)
                        if dis<closestDistance then
                            closestDistance=dis
                            closestEnemy=value
                        end
                    end
                end
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
---@field speed number
---@field angle number|string will be fed to math.eval(). can be 'a+b'
---@field isHoming boolean whether the bullet is homing. if true, addHoming will be called on the bullet after it's created
---@field homingMode HOMING_MODE the mode for homing. Only works when isHoming is true
---@field homingArg number the argument for homingMode. Only works when isHoming is true
---@field update fun(self: ShootingPattern, dt: number): boolean whether call shoot
---@field frame integer
---@field transformShootState fun(self: ShootingPattern, shooter: KinematicState): KinematicState get the position and direction to shoot based on shooter state, used for main shot to spawn at front of player instead of center. defaults to returning shooter.
---@field shoot fun(self: ShootingPattern, shooter: KinematicState, powerLevel: integer): nil
---@overload fun(args: ShootingPatternArgs): ShootingPattern
local ShootingPattern=Object:extend()

---@class ShootingPatternArgs
---@field sprite Sprite
---@field size number|nil
---@field frequency integer|nil
---@field damage number|fun(self: ShootingPattern, powerLevel: integer): number
---@field speed number|nil
---@field angle number|string
---@field isHoming boolean|nil
---@field homingMode HOMING_MODE|nil

function ShootingPattern:new(args)
    self.sprite=args.sprite
    self.size=args.size or 1.5
    self.frequency=args.frequency or 3
    self.damage=args.damage
    self.speed=args.speed or 1200
    self.angle=args.angle
    self.isHoming=args.isHoming
    self.homingMode=args.homingMode
    self.homingArg=args.homingArg
    self.transformShootState=args.transformShootState or function(self, shooter) return shooter end
    self.frame=0
end

function ShootingPattern:update(dt)
    self.frame=self.frame+1
    if self.frame>=self.frequency then
        self.frame=0
        return true
    end
    return false
end

function ShootingPattern:shoot(shooter, powerLevel)
    local shootState=self:transformShootState(shooter)
    local direction=shootState.dir
    direction=direction+math.eval(self.angle)
    local bullet=PlayerShot{kinematicState={pos=copy_table(shootState.pos), speed=self.speed, dir=direction},sprite=self.sprite,size=self.size,damage=self:damage(powerLevel),lifeFrame=60,batch=Asset.playerBulletBatch,meshBatch=Asset.playerBulletMeshes,extraUpdate={Bullet.FadeIn(1,false)}}
    if self.isHoming then
        addHoming(bullet, self.homingMode, self.homingArg)
    end
end

---@alias OptionArrangement fun(powerLevel: integer, isFocused: boolean, playerState: KinematicState, frame:integer): KinematicState[] positions and directions of options. normally options number equals powerLevel

---@class ShotType:Object
---@field mainShot ShootingPattern[]
---@field optionSprite Sprite
---@field optionArrangement OptionArrangement
---@field optionShot {focused: ShootingPattern[], unfocused: ShootingPattern[]}
---@field spellcard any -- to be designed
---@field update fun(self: ShotType, playerState: KinematicState, isFocused: boolean, isShooting: boolean, powerLevel: integer, frame: integer, dt: number, options: Bullet[], optionTransparency: number): nil update options position and shoot with optionShot
---@overload fun(args: ShotTypeArgs): ShotType
local ShotType=Object:extend()

---@class ShotTypeArgs
---@field mainShot ShootingPattern[]
---@field optionSprite Sprite
---@field optionArrangement OptionArrangement
---@field optionShot {focused: ShootingPattern[], unfocused: ShootingPattern[]}
---@field spellcard any -- to be designed
function ShotType:new(args)
    self.mainShot=args.mainShot
    self.optionSprite=args.optionSprite
    self.optionArrangement=args.optionArrangement
    self.optionShot=args.optionShot
    self.spellcard=args.spellcard
end

function ShotType:update(playerState, isFocused, isShooting, powerLevel, frame, dt, options, optionTransparency)
    -- main shot
    if isShooting then
        for _, pattern in pairs(self.mainShot) do
            if pattern:update(dt) then
                pattern:shoot(playerState, powerLevel)
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
            local newOption=Bullet{kinematicState={pos=playerState.pos,dir=0,speed=0},sprite=self.optionSprite,lifeFrame=99999,safe=true,invincible=true,batch=Asset.playerBulletBatch,meshBatch=Asset.playerBulletMeshes}
            table.insert(options, newOption)
        end
    end
    -- update options position and shoot with optionShot
    if powerLevel==0 then
        return
    end
    for i, option in pairs(options) do
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
        for i, option in pairs(options) do
            for j, pattern in pairs(optionPatterns) do
                if pattern:update(dt) then
                    pattern:shoot(option.kinematicState, powerLevel)
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
    local newArgs=copy_table(template)
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
                    optionAngle=math.pi/10*(i-powerLevel/2-0.5)
                else
                    optionAngle=math.pi*2/powerLevel*(i-1)+frame*math.pi/150
                end
                local optionPos,optionAngle2=G.runInfo.geometry:rThetaGo(playerState.pos, radius, angle+optionAngle)
                optionAngle2=optionAngle2-optionAngle -- let it face upward
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
            damage=function(self, powerLevel) return 3 end,
            angle=0,
        }}},
    }
}

return ShotTypes