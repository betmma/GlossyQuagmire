---@class Player:Shape
---@field viewDirection number in natural move mode, the direction of the right-hand-side.
---@field moveSpeed number
---@field diagonalSpeedAddition boolean if true, when moving diagonally, the speed is the addition of 2 vectors of U/D and L/R.
---@field focusFactor number speed factor when holding focus key
---@field focusPointTransparency number between 0 and 1, the transparency of the focus point
---@field orientation number extra rotation of player sprite and focus sprite
---@field border any not implemented now
---@field hitInvincibleFrame number how many frames player will be invincible after hit
---@field invincibleFrame number how many frames player is still invincible
---@field grazeRadiusFactor number the factor multiplied to radius to get graze radius
---@field moveMode PlayerMoveMode
---@field dieShockwaveRadius number
---@field shotType ShotType
---@field options Bullet[]
local Player = Shape:extend()

---@enum PlayerMoveMode
Player.moveModes={
    Euclid='Euclid',
    Natural='Natural'
}


function Player:new(args)
    args=args or {}
    Player.super.new(self, args)
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

    if args.noBorder then
        self.border=nil
    else
        -- rectangle border. border is not implemented
        self.border=args.border or {
            inside=function(_,x,y)
                return x>=150 and x<=650 and y>=0 and y<=600
            end,
            default=true,
            remove=function()end
        }
    end

    self.hitInvincibleFrame=300
    self.invincibleFrame=0
    self.hitImmobileFrame=120
    self.immobileFrame=0
    self.grazeRadiusFactor=3

    self.moveMode=args.moveMode or Player.moveModes.Natural
    self.dieShockwaveRadius=2

    self.shotType=args.shotType
    self.options={}

    -- for replay system. could be moved elsewhere
    self.keyRecord={}
    self.replaying=args.replaying or false
    if self.replaying then
        self:setReplaying()
    end
    self.key2Value={up=1,right=2,down=4,left=8,lshift=16,z=32,x=64,c=128}
    self.keyIsDown=love.keyboard.isDown
    self.keyIsPressed=isPressed -- check if current frame is the first frame that key be pressed down. only used for switching hyperbolic model (X key)
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

    self.immobileFrame=self.immobileFrame-1
    if self.immobileFrame<=0 then
        self.immobileFrame=0
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
            G.runInfo.power=G.runInfo.power-1
        elseif love.keyboard.isDown('.') then
            G.runInfo.power=G.runInfo.power+1
        end
    end
    if not self.shotType then
        return
    end
    local powerLevel=math.floor(G.runInfo.power/100)
    local kinematicState={pos=self.kinematicState.pos,dir=self.viewDirection-math.pi/2, speed=0} -- note that the dir must not be self.kinematicState.dir, because that value is the moving direction, not the shooting (facing) direction. viewDirection is the right hand side direction, so shooting direction is viewDirection-math.pi/2
    self.shotType:update(kinematicState, self.keyIsDown('lshift'), self.keyIsDown('z'), powerLevel, self.frame, dt, self.options)
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
    if self.keyIsDown('lshift') then
        speed=speed*self.focusFactor
    end
    return speed, dir
end

function Player:limitInBorder()
end


function Player:moveUpdate(dt)
    self.kinematicState.speed, self.kinematicState.dir=self:getKeyboardMoveSpeed()
    local kinematicStateRef=copy_table(self.kinematicState)

    self.super.update(self,dt) -- actually move

    -- limit player in border
    self:limitInBorder()

    if self.moveMode==Player.moveModes.Natural then
        local dtheta=math.modClamp(self.kinematicState.dir-kinematicStateRef.dir)
        if DEV_MODE and love.keyboard.isDown('[') then --debug use
            self.viewDirection=self.viewDirection-0.03
        elseif DEV_MODE and love.keyboard.isDown(']') then
            self.viewDirection=self.viewDirection+0.03
        end
        self.viewDirection=(self.viewDirection+dtheta)%(math.pi*2)
    end
end


-- calculate which player sprite to use (normal, moveTransition and moving). Specifically, when not moving, loop through 8 normal sprites for each 8 frames. when moving, loop through 4 moveTransition sprites for each 2 frames, and after it loop through 8 moving sprites for each 8 frames. Use [tilt] to record.
function Player:calculateMovingTransitionSprite()
    if Shape.timeSpeed==0 then
        return -- stop sprite transition when time is stopped
    end
    local lingerFrame={normal=8,moveTransition=2,moving=8}
    local tiltMax=#Asset.player.moveTransition.left*lingerFrame.moveTransition
    local right=self:isDownInt(KEYS.DIRECTIONS.RIGHT)-self:isDownInt(KEYS.DIRECTIONS.LEFT)
    local tilt=self.tilt or 0
    local keptFrame=self.keptFrame or 0 -- how long player has been keeping unmove or moving at the same direction (after transition of tiltMax frames)
    if tilt==0 then
        if right==0 then
            keptFrame=keptFrame+1 -- at current frame keeping unmove
        else
            keptFrame=0 -- start moving
            tilt=tilt+right
        end
    elseif math.abs(tilt)==tiltMax then
        if math.sign(right)==math.sign(tilt) then -- keep moving at the same direction
            keptFrame=keptFrame+1
        else
            keptFrame=0
            tilt=tilt-math.sign(tilt) -- reduce tilt as not moving at the same direction
        end
    else
        keptFrame=0
        tilt=tilt+(right==0 and -math.sign(tilt) or right) -- if do move, change tilt to the moving direction. if not moving, reduce tilt towards 0.
    end
    self.tilt=tilt
    self.keptFrame=keptFrame
    local direction=tilt>0 and 'right' or 'left'
    local sprite
    if tilt==0 then
        sprite=Asset.player.normal[math.ceil(keptFrame/lingerFrame.normal)%#Asset.player.normal+1]
    elseif math.abs(tilt)==tiltMax then
        sprite=Asset.player.moving[direction][math.ceil(keptFrame/lingerFrame.moving)%#Asset.player.moving[direction]+1]
    else
        sprite=Asset.player.moveTransition[direction][math.ceil(math.abs(tilt)/lingerFrame.moveTransition)]
    end
    self.sprite=sprite
end

function Player:calculateFocusPointTransparency()
    local focus=self.keyIsDown('lshift')
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
    self:drawQuad{quad=BulletSprites.playerFocus.quad,image=Asset.bulletImage,rotation=focusOrientation,zoom=focalSizeFactor,meshBatch=Asset.playerFocusMeshes,color=drawFocusColor
        ,normalBatch=nil} -- force mesh
    local sizeFactor=1
    if self.sprite then
        self:drawQuad{quad=self.sprite,image=nil,rotation=orientation,zoom=sizeFactor,normalBatch=Asset.playerBatch,meshBatch=nil,color=drawColor}
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
    if DEV_MODE then 
        love.graphics.print('X='..string.format("%.2f", self.kinematicState.pos.x)..'\nY='..string.format("%.2f", self.kinematicState.pos.y)..'\nView Direction='..string.format("%.2f", self.viewDirection),30,140)
    end
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
    if G.runInfo.lives<0 then
        -- G:lose()
    end
    self.invincibleFrame=self.invincibleFrame+self.hitInvincibleFrame
    self.immobileFrame=self.immobileFrame+self.hitImmobileFrame
    Effect.Shockwave{kinematicState={pos=copy_table(self.kinematicState.pos),speed=0,dir=0},size=self.dieShockwaveRadius,growSpeed=1.1,animationFrame=30,spriteTransparency=0.8,sprite=BulletSprites.shockwave.gray}
    SFX:play('playerHit',true)
    Event.EaseEvent{
        obj=self,duration=self.hitInvincibleFrame,aims={transparency=0},progressFunc=function(x)
            if x==0 then return 0 end
            local flash=math.abs(math.cos(x*math.pi*30))
            local maxTransparency=math.clamp(x*3-1,0,1) -- oscillate range: 0 to maxTransparency (invisible first, then maximum value increases to 1 and keeps 1)
            return 1-flash*maxTransparency -- note that transparency=1-returned value
        end
    }
end
-- EventManager.listenTo(EventManager.EVENTS.PLAYER_HIT,Player.hitEffect)

return Player