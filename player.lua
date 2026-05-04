---@class Player:Shape
---@field sprite MovingSprite
---@field viewDirection number in natural move mode, the direction of the right-hand-side.
---@field moveSpeed number
---@field diagonalSpeedAddition boolean if true, when moving diagonally, the speed is the addition of 2 vectors of U/D and L/R.
---@field focusFactor number speed factor when holding focus key
---@field focusPointTransparency number between 0 and 1, the transparency of the focus point
---@field orientation number extra rotation of player sprite and focus sprite
---@field hitInvincibleFrame number how many frames player will be invincible after hit
---@field invincibleFrame number how many frames player is still invincible
---@field grazeRadiusFactor number the factor multiplied to radius to get graze radius
---@field moveMode PlayerMoveMode
---@field dieShockwaveRadius number
---@field shotType ShotType
---@field options Bullet[]
---@field duringDeathbombWindow boolean whether player is in deathbomb window, which is a short time after hit where player can still bomb to avoid death.
---@field duringDeath boolean whether player is in death animation.
---@field duringBomb boolean whether player is in bomb animation. if true, player cannot bomb again. 
---@field border Border|nil
local Player = Shape:extend()

---@enum PlayerMoveMode
Player.moveModes={
    Euclid='Euclid',
    Natural='Natural'
}


function Player:new(args)
    args=args or {}
    Player.super.new(self, args)
    self.sprite=args.sprite or Asset.playerSprites[G.runInfo.playerType]
    -- in natural move mode, the direction of the right-hand-side. initially it's 0, means without moving, the right to player is the same as the right to the screen. (it's not the "up" direction where player's sprite faces.)
    self.viewDirection=0
    self.lifeFrame=9999999
    self.moveSpeed=args.moveSpeed or 240
    self.diagonalSpeedAddition=false -- if false, speed is always moveSpeed. if true, speed is the addition of 2 vectors of U/D and L/R.
    self.focusFactor=0.4444
    self.transparency=1
    self.focusPointTransparency=0
    self.radius = 3.0 -- hitbox
    -- orientation determines extra rotation of player sprite and focus sprite. since player sprite faces up, orientation is normally 0.
    self.orientation=0
    self.border=nil

    self.hitInvincibleFrame=300
    self.invincibleFrame=0
    self.hitImmobileFrame=120
    self.immobileFrame=0
    self.grazeRadiusFactor=5

    self.moveMode=args.moveMode or Player.moveModes.Natural
    self.dieShockwaveRadius=2

    self.shotType=args.shotType
    self.options={}

    self.duringDeath=false
    self.duringBomb=false

    -- for replay system. could be moved elsewhere
    self.keyRecord={}
    self.replaying=args.replaying or false
    if self.replaying then
        self:setReplaying()
    end
    self.key2Value={up=1,right=2,down=4,left=8,lshift=16,z=32,x=64,c=128}
    self.keyIsDown=love.keyboard.isDown
    self.keyIsPressed=isPressed -- check if current frame is the first frame that key be pressed down. only used for switching hyperbolic model (C key)
    self.realCreatedTime=os.date('%Y-%m-%d %H:%M:%S')
end


function Player:setReplaying()
    self.replaying=true
    self.keyIsDown=function(key,frame)
        local record=self.keyRecord[(frame or self.frame)+1] --this is because when recording keys first frame is stored at index 1 (by table.insert), while when playing at first frame key value is loaded from keyRecord before update, so self.frame=0
        local val=self.key2Value[key]
        if record and val then
            return record%(val*2)>=val
        end
        return false
    end
    self.keyIsPressed=function(key)
        local currentDown=self.keyIsDown(key)
        local lastDown=self.keyIsDown(key,self.frame-1)
        return currentDown and not lastDown
    end
end

function Player:isDownInt(keyname)
    return self.keyIsDown(keyname)and 1 or 0
end

function Player:update(dt)
    if not self.replaying then -- record keys pressed
        local keyVal=0
        for key, value in pairs(self.key2Value) do
            if self.keyIsDown(key)then
                keyVal=keyVal+value
            end
        end
        table.insert(self.keyRecord,keyVal)
    end
    self:calculateShoot()

    self.immobileFrame=math.max(0,self.immobileFrame-1)
    if self.immobileFrame<=0 and not self.duringDeathbombWindow then
        self:moveUpdate(dt)
    end

    -- handle invincible time from hit
    self.invincibleFrame=self.invincibleFrame-1
    if self.invincibleFrame<=0 then
        self.invincibleFrame=0
    end

    self:calculateMovingTransitionSprite()
    self:calculateFocusPointTransparency()
end


function Player:calculateShoot(dt)
    if DEV_MODE then
        if love.keyboard.isDown(',') then
            G.runInfo.power=G.runInfo.power-2
        elseif love.keyboard.isDown('.') then
            G.runInfo.power=G.runInfo.power+2
        end
    end
    if not self.shotType then
        return
    end
    local powerLevel=math.floor(G.runInfo.power/100)
    local kinematicState={pos=self.kinematicState.pos,dir=self.viewDirection-math.pi/2, speed=0} -- note that the dir must not be self.kinematicState.dir, because that value is the moving direction, not the shooting (facing) direction. viewDirection is the right hand side direction, so shooting direction is viewDirection-math.pi/2
    local shooting=self.keyIsDown(KEYS.SELECT) and not self.duringDeath and (not self.duringBomb or self.shotType.spellcard.canShoot)
    self.shotType:update(kinematicState, self.keyIsDown(KEYS.SLOW), shooting, powerLevel, self.frame, dt, self.options, self.transparency)
    if not self.duringBomb and not self.duringDeath and self.keyIsDown(KEYS.CANCEL) and G.runInfo.bombs>=1 then
        EventManager.post(EventManager.EVENTS.PLAYER_BOMB)
        self.duringDeathbombWindow=false -- exit deathbomb window to prevent death
        self.invincibleFrame=self.shotType.spellcard.duration
        self.transparency=0.5 -- make player semi-transparent during bomb invincibility
        G.runInfo.bombs=G.runInfo.bombs-1
        SFX:play('enemyPowerfulShot',true)
        self.shotType.spellcard.func(kinematicState, self.keyIsDown(KEYS.SLOW))
        self.duringBomb=true
        Event{obj=self,action=function()
            wait(self.shotType.spellcard.duration-30)
            Event.EaseEvent{obj=self,duration=30,aims={transparency=1},progressFunc=function(x)
                return math.sin(x*math.pi*8)*0.5+x
            end}
            wait(30)
            self.duringBomb=false
            self.transparency=1
        end}
    end
end


-- return vx, vy from keyboard input. normally this will directly be player's move speed, but in some levels simulating platformer (with gravity) more calculation is needed.
function Player:getKeyboardMoveSpeed()
    local rightDirOffset,downDirOffset
    if self.moveMode==Player.moveModes.Euclid then
        rightDirOffset,downDirOffset=0,0
    elseif self.moveMode==Player.moveModes.Natural then
        rightDirOffset=self.viewDirection
        downDirOffset=self.viewDirection
    end
    local rightx,righty=math.rTheta2xy(1,rightDirOffset)
    local downx,downy=math.rTheta2xy(1,downDirOffset+math.pi/2)

    local rightAmount=self:isDownInt(KEYS.DIRECTIONS.RIGHT)-self:isDownInt(KEYS.DIRECTIONS.LEFT)
    local downAmount=self:isDownInt(KEYS.DIRECTIONS.DOWN)-self:isDownInt(KEYS.DIRECTIONS.UP)

    local vxunit,vyunit=rightx*rightAmount+downx*downAmount, righty*rightAmount+downy*downAmount
    local vlen,dir=math.xy2rTheta(vxunit,vyunit)
    local speed=vlen>0 and self.moveSpeed or 0 -- if vlen==0, then player is not moving, so speed is 0.
    if rightAmount~=0 and downAmount~=0 and self.diagonalSpeedAddition then
        speed=speed*math.sqrt(vxunit^2+vyunit^2) -- it means when moving diagonally, the speed is the addition of 2 vectors of U/D and L/R. Not multiplying by sqrt(2) is because U/D vector and L/R vector could be not orthogonal.
    end
    if self.keyIsDown(KEYS.SLOW) then
        speed=speed*self.focusFactor
    end
    return speed, dir
end

function Player:limitInBorder()
    if not self.border then
        return
    end
    local pos=self.kinematicState.pos
    local limitedPos=self.border:findInside(pos)
    if limitedPos==pos then
        return
    end
    self.kinematicState.pos=limitedPos
    -- cannot only set pos to limitedPos, due to the geometry can change direction during the move. without adding that change, moving towards the border perpendicularly can cause player to rotate, as the forward movement in self.super.update adds to viewDirection (though not directly, through updateViewDirection), but directly set pos back does not cancel the rotation.
    local moveDir=G.runInfo.geometry:to(pos,limitedPos)
    local moveDistance=G.runInfo.geometry:distance(pos,limitedPos)
    local kinematicState={pos=pos,dir=moveDir,speed=moveDistance*60}
    G.runInfo.geometry:update(kinematicState,1/60)
    local dirDelta=kinematicState.dir-moveDir
    self.kinematicState.dir=self.kinematicState.dir+dirDelta
end

---@param kstateRef KinematicState
---@param kstateAfter KinematicState
function Player:updateViewDirection(kstateRef,kstateAfter)
    if self.moveMode==Player.moveModes.Natural then
        local dtheta=math.modClamp(kstateAfter.dir-kstateRef.dir)
        if DEV_MODE and love.keyboard.isDown('[') then --debug use
            self.viewDirection=self.viewDirection-0.03
        elseif DEV_MODE and love.keyboard.isDown(']') then
            self.viewDirection=self.viewDirection+0.03
        end
        self.viewDirection=(self.viewDirection+dtheta)%(math.pi*2)
    end
end

function Player:moveUpdate(dt)
    self.kinematicState.speed, self.kinematicState.dir=self:getKeyboardMoveSpeed()
    local kinematicStateRef=copyTable(self.kinematicState)

    self.super.update(self,dt) -- actually move

    -- limit player in border
    self:limitInBorder()
    self:updateViewDirection(kinematicStateRef,self.kinematicState)
end


-- calculate which player sprite to use (normal, moveTransition and moving). Specifically, when not moving, loop through 8 normal sprites for each 8 frames. when moving, loop through 4 moveTransition sprites for each 2 frames, and after it loop through 8 moving sprites for each 8 frames. Use [tilt] to record.
function Player:calculateMovingTransitionSprite()
    if Shape.timeSpeed==0 then
        return -- stop sprite transition when time is stopped
    end
    self.sprite:countDown(self:isDownInt(KEYS.DIRECTIONS.LEFT)>0,self:isDownInt(KEYS.DIRECTIONS.RIGHT)>0)
end

function Player:calculateFocusPointTransparency()
    local focus=self.keyIsDown(KEYS.SLOW)
    self.focusPointTransparency=self.focusPointTransparency or 0
    local add=0.2
    if focus then
        self.focusPointTransparency=math.min(1,self.focusPointTransparency+add)
    else
        self.focusPointTransparency=math.max(0,self.focusPointTransparency-add)
    end
end


function Player:draw()
    local color={love.graphics.getColor()}
    local orientation=(self.orientation or 0)+self.viewDirection
    local focusOrientation=self.time*4+orientation
    local drawColor={1,1,1,self.transparency*color[4]}
    local drawFocusColor={1,1,1,self.transparency*self.focusPointTransparency*color[4]}
    local focalSizeFactor=1
    self:drawQuad{quad=BulletSprites.playerFocus.quad,rotation=focusOrientation,zoom=focalSizeFactor,meshBatch=Asset.playerFocusMeshes,color=drawFocusColor
        ,normalBatch=nil} -- force mesh
    local sizeFactor=1
    if self.sprite then
        self:drawQuad{quad=self.sprite.quad,rotation=orientation,zoom=sizeFactor,normalBatch=Asset.playerBatch,meshBatch=nil,color=drawColor}
    end
end

-- this function draws which keys are pressed. The keys are arranged as:
--[[
                U
Shift Z X C   L D R 
]]
function Player:displayKeysPressed()
    local x0,y0=600,320
    local gridSize=15
    local keysPoses={up={6,0},down={6,1},left={5,1},right={7,1},lshift={0,1},z={1,1},x={2,1},c={3,1}}
    local keysText={up={text='↑',offset={0,0}},down={text='↓',offset={0,0}},left={text='←',offset={0,1}},right={text='→',offset={0,1}},lshift={text='⇧',offset={-0.5,0}},z={text='Z',offset={1,0}},x={text='X',offset={1,0}},c={text='C',offset={1,0}}}
    local color={love.graphics.getColor()}
    for key, value in pairs(keysPoses) do
        local x,y=x0+value[1]*gridSize,y0+value[2]*gridSize
        if self.keyIsDown(key) then
            love.graphics.setColor(1,1,1)
            love.graphics.rectangle("fill",x,y,gridSize,gridSize)
        end
        love.graphics.setColor(0,0,0)
        love.graphics.rectangle("line",x,y,gridSize,gridSize)
        SetFont(10,Fonts.zh_cn)
        love.graphics.print(keysText[key].text,x+3+keysText[key].offset[1],y+2+keysText[key].offset[2])
    end
    love.graphics.setColor(color[1],color[2],color[3])
end


function Player:drawText()
    self:displayKeysPressed()
    -- if DEV_MODE then 
    --     love.graphics.print('X='..string.format("%.2f", self.kinematicState.pos.x)..'\nY='..string.format("%.2f", self.kinematicState.pos.y)..'\nView Direction='..string.format("%.2f", self.viewDirection),30,140)
    -- end
end

-- spawn a white dot to show the graze effect. 
function Player:grazeEffect(amount)
    amount=amount or 1
    SFX:play('graze')
    G.runInfo.grazes=G.runInfo.grazes+amount
    -- non-random graze effect
    -- Effect.Larger{x=self.x,y=self.y,speed=50+30*math.sin(self.x*51323.35131+self.y*46513.1333+self.frame*653.13),direction=9999*math.sin(self.x*513.35131+self.y*413.1333+self.frame*6553.13),sprite=Asset.shards.dot,radius=1.25,growSpeed=1,animationFrame=20}
end
EventManager.listenTo(EventManager.EVENTS.PLAYER_GRAZE,Player.grazeEffect)

function Player:hitEffect(damage)
    if self.invincibleFrame>0 then
        return
    end
    damage=damage or 1
    self.hitFrame=self.frame
    G.runInfo.lives=G.runInfo.lives-damage
    G.runInfo.power=math.max(0,G.runInfo.power-100)
    G.runInfo.bombs=math.max(3,G.runInfo.bombs)
    ---@type DropItems
    local dropItems={powerSmall=20}
    if G.runInfo.lives<0 then
        dropItems={powerFull=3}
        -- G:lose()
    end
    
    for itemType,num in pairs(dropItems) do
        for i=1,num do
            local angle=self.viewDirection-math.pi/2+math.eval(0,1)
            local speed=math.eval(200,50)
            local pos,angle2=G.runInfo.geometry:rThetaGo(self.kinematicState.pos,80,angle)
            local kinematicState={pos=pos,dir=angle2,speed=speed}
            Item{kinematicState=kinematicState,type=itemType}
        end
    end
    self.invincibleFrame=self.invincibleFrame+self.hitInvincibleFrame
    self.immobileFrame=self.immobileFrame+self.hitImmobileFrame
    Effect.Shockwave{kinematicState={pos=copyTable(self.kinematicState.pos),speed=0,dir=0},size=self.dieShockwaveRadius,growSpeed=1.1,animationFrame=30,spriteTransparency=0.8,sprite=BulletSprites.shockwave.gray}
    self.duringDeath=true
    Event.EaseEvent{
        obj=self,duration=self.hitInvincibleFrame,aims={transparency=0},progressFunc=function(x)
            if x==0 then return 0 end
            local flash=math.abs(math.cos(x*math.pi*30))
            local maxTransparency=math.clamp(x*3-1,0,1) -- oscillate range: 0 to maxTransparency (invisible first, then maximum value increases to 1 and keeps 1)
            return 1-flash*maxTransparency -- note that transparency=1-returned value
        end,afterFunc=function()
            self.duringDeath=false
        end
    }
end

function Player:enterDeathbombing(damage)
    SFX:play('playerHit',true,3)
    self.duringDeathbombWindow=true
    -- should have some visual effect here
    Event{obj=self,action=function()
        wait(8)
        if self.duringDeathbombWindow then
            self.duringDeathbombWindow=false
            self:hitEffect(damage)
        end
    end}
end
EventManager.listenTo(EventManager.EVENTS.PLAYER_HIT,Player.enterDeathbombing)

return Player