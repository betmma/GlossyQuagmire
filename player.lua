---@class Player:Shape
local Player = Shape:extend()


Player.moveModes={
    Euclid='Euclid',
    Natural='Natural'
}


function Player:new(args)
    args=args or {}
    Player.super.new(self, args)
    self.direction=0
    -- in natural move mode, the direction of the right-hand-side. initially it's 0, means without moving, the right to player is the same as the right to the screen. (it's not the "up" direction where player's sprite faces.)
    self.viewDirection=0
    self.lifeFrame=9999999
    self.speed=0
    self.moveSpeed=args.moveSpeed or 240
    self.diagonalSpeedAddition=false -- if false, speed is always moveSpeed. if true, speed is the addition of 2 vectors of U/D and L/R. (Vanilla game is false but dunno why I implemented true from very beginning (^^;))
    self.focusFactor=0.4444
    self.focusPointTransparency=0
    self.radius = 0.5
    -- orientation determines extra rotation of player sprite and focus sprite. since player sprite faces up, orientation is normally 0. It's not 0 in rare cases, like when calculating mirrored player sprite in 7-4.
    self.orientation=0

    if args.noBorder then
        self.border=nil
    else
        -- rectangle border, only used in level 1 and 2. very spaghetti i know
        self.border=args.border or {
            inside=function(_,x,y)
                return x>=150 and x<=650 and y>=0 and y<=600
            end,
            default=true,
            remove=function()end
        }
    end

    self.hitInvincibleFrame=300
    self.invincibleTime=0
    self.grazeRadiusFactor=15

    self.moveMode=args.moveMode or Player.moveModes.Natural
    self.dieShockwaveRadius=2

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

    self:moveUpdate(dt)

    -- handle invincible time from hit
    self.invincibleTime=self.invincibleTime-dt
    if self.invincibleTime<=0 then
        self.invincibleTime=0
    end

    self:calculateMovingTransitionSprite()
    self:calculateFocusPointTransparency()
end


function Player:calculateShoot()
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

    local rightAmount=self:isDownInt("right")-self:isDownInt("left")
    local downAmount=self:isDownInt("down")-self:isDownInt("up")

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
    self.kinematicState.speed, self.kinematicState.direction=self:getKeyboardMoveSpeed()
    local kinematicStateRef=copy_table(self.kinematicState)

    self.super.update(self,dt) -- actually move

    -- limit player in border
    self:limitInBorder()

    if self.moveMode==Player.moveModes.Natural then
        local dtheta=self.kinematicState.direction-kinematicStateRef.direction
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
    local right=self:isDownInt("right")-self:isDownInt("left")
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
    local orientation=(self.orientation or 0)+(G.UseHypRotShader and self.viewDirection or 0)
    
    local focusOrientation=self.time*4+orientation
    local drawColor={1,1,1,(self.focusPointTransparency or 1)*color[4]}
    local focalSizeFactor=1
    self:drawQuad(BulletSprites.playerFocus.quad,Asset.bulletImage,focusOrientation,focalSizeFactor,Asset.playerFocusBatch,Asset.playerFocusMeshes,drawColor)
    local sizeFactor=1
    if self.sprite then
        self:drawQuad(self.sprite,nil,orientation,sizeFactor,Asset.playerBatch,nil,color)
    end
end

-- this function draws which keys are pressed. The keys are arranged as:
--[[
                U
Shift Z X C   L D R 
]]
function Player:displayKeysPressed()
    local x0,y0=520,400
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
end

return Player