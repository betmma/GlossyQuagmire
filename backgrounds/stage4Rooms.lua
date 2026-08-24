local WalkerShader=...

local stage4RoomsShader=ShaderScan:load_shader('shaders/backgrounds/stage4Rooms.glsl')
local Stage4Rooms=WalkerShader:extend()

local ROOM_HALF_WIDTH=3.2
local ROOM_HALF_HEIGHT=2.2
local ROOM_HALF_LENGTH=4.0
local ROOM_WALL_THICKNESS=0.14
local PORTAL_ZOOM_RANGE=1.5
local DOOR_OPEN_RANGE=8.0
-- Keep this fixed projected-room value synchronized with the corresponding
-- constant in shaders/backgrounds/stage4Rooms.glsl.
local PROJECTED_CAMERA_Z=-3.9

local NORMAL_SLOW_Z=2.0
local FORWARD_DECELERATION=2.5
local TURN_DURATION=3.0

local function portalZoomLog(distance,linkedSizeRatio)
    local F=math.log(linkedSizeRatio)*-0.5
    local proximity=2*math.smoothstep(0.5-0.5*distance/PORTAL_ZOOM_RANGE)
    return F*proximity
end

local function doorOpenAmount(distance)
    return math.smoothstep((DOOR_OPEN_RANGE-distance)/DOOR_OPEN_RANGE)
end

local function rotatePlane(x,y,angle)
    local cosine=math.cos(angle)
    local sine=math.sin(angle)
    return x*cosine-y*sine,x*sine+y*cosine
end

local function wrapCoordinate(value,halfRange)
    local range=halfRange*2
    return (value+halfRange)%range-halfRange
end

function Stage4Rooms:new(args)
    Stage4Rooms.super.new(self)
    self.shader=stage4RoomsShader
    self.lightColor={0.82,0.82,0.82}
    self.darkColor={0.42,0.42,0.42}

    self.cam_translation={0,0,-2.0}
    self.camMoveRange={3.2,2.2}
    self.baseCamMoveSpeed=0.5
    self.camMoveSpeed=self.baseCamMoveSpeed
    self.reverseX=false
    self.cameraSpeed=1.5
    self.cam_roll=0.0
    self.rollPerRoom=0.0

    self.portalZoomBase=1.0
    self.previousPortalRatio=1.0
    self.zoomFactor=1.0
    self.frontDoorOpen=0.0
    self.backDoorOpen=0.0

    local sendWalkerParams=self.paramSendFunction
    self.paramSendFunction=function(self,shader)
        sendWalkerParams(self,shader)
        local translatedX,translatedY=rotatePlane(self.cam_translation[1],self.cam_translation[2],self.cam_roll)
        shader:send('translation',{translatedX,translatedY,self.cam_translation[3]})
        local screenCenter=G.runInfo.geometry.viewConfig.screenCenter
        shader:send('screenCenter',{screenCenter.x,screenCenter.y})
        shader:send('roll_per_room',self.rollPerRoom)
        shader:send('zoom_factor',self.zoomFactor)
        shader:send('portal_zoom_base',self.portalZoomBase)
        shader:send('front_door_open',self.frontDoorOpen)
        shader:send('back_door_open',self.backDoorOpen)
        shader:send('snapshot',self.snapshotCanvas)
    end

    self.snapshotCanvas=love.graphics.newCanvas(800,600)
    self.snapshotCanvas:setFilter('linear','linear')
    love.graphics.setCanvas(self.snapshotCanvas)
    love.graphics.clear(0,0,0,0)
    love.graphics.setCanvas()
    self.captureCanvas=love.graphics.newCanvas(800,600)
    self.captureCanvas:setFilter('linear','linear')
    self.projectionEnabled=false
    self.projectedRoom=false
    self.projectionState='normal'
    self.capturePending=false
    self.forwardSpeed=self.cameraSpeed
    self.turnStartYaw=0
    self.turnStartPitch=0
    self.turnTargetYaw=0
    self.turnTargetPitch=0
    self.turnProgress=0
end

function Stage4Rooms:setRoomChanges(rollPerRoom,portalZoomBase)
    self.rollPerRoom=rollPerRoom
    self.portalZoomBase=portalZoomBase
end

function Stage4Rooms:setProjectionMode(enabled)
    self.projectionEnabled=enabled
    self.projectedRoom=false
    self.projectionState=enabled and 'normal' or 'disabled'
    self.capturePending=false
    self.forwardSpeed=self.cameraSpeed
    if enabled then
        self.cam_roll=0
        self.cam_yaw=0
        self.cam_pitch=0
    end
end

function Stage4Rooms:beginTurn()
    self.projectionState='turning'
    self.forwardSpeed=0
    self.turnStartYaw=self.cam_yaw
    self.turnStartPitch=self.cam_pitch
    self.turnTargetYaw=(math.pseudoRandom(self.frame)*2-1)*math.pi*2/3
    self.turnTargetPitch=(math.pseudoRandom(self.frame,99)*2-1)*math.pi/3
    self.turnProgress=0
end

function Stage4Rooms:updateProjectionState(dt)
    if not self.projectionEnabled then
        self.forwardSpeed=self.cameraSpeed
        return
    end

    if self.projectionState=='normal' and self.cam_translation[3]>=NORMAL_SLOW_Z then
        self.projectionState='slowing'
    end

    if self.projectionState=='slowing' then
        self.forwardSpeed=math.max(0,self.forwardSpeed-FORWARD_DECELERATION*dt)
        if self.forwardSpeed==0 then
            self:beginTurn()
        end
    elseif self.projectionState=='turning' then
        self.turnProgress=math.min(1,self.turnProgress+dt/TURN_DURATION)
        local progress=Event.sineIOProgressFunc(self.turnProgress)
        self.cam_yaw=math.interpolate(self.turnStartYaw,self.turnTargetYaw,progress)
        self.cam_pitch=math.interpolate(self.turnStartPitch,self.turnTargetPitch,progress)
        if self.turnProgress>=1 then
            self.projectionState='capture'
            self.capturePending=true
        end
    elseif self.projectionState=='projected' then
        self.forwardSpeed=math.min(self.cameraSpeed,self.forwardSpeed+FORWARD_DECELERATION*dt)
    end
end

function Stage4Rooms:calculateZoomFactor()
    local cameraZ=self.cam_translation[3]
    local distanceToBack=cameraZ+ROOM_HALF_LENGTH
    local distanceToFront=ROOM_HALF_LENGTH-cameraZ
    local backRatio=1/self.previousPortalRatio
    local zoomLog=portalZoomLog(distanceToBack,backRatio)
    zoomLog=zoomLog+portalZoomLog(distanceToFront,self.portalZoomBase)
    return math.exp(zoomLog)
end

function Stage4Rooms:enterNextRoom()
    local crossedRatio=self.portalZoomBase
    local trans=self.cam_translation
    local remainder=trans[3]-ROOM_HALF_LENGTH
    local newRoll=self.cam_roll+self.rollPerRoom
    local localX,localY=rotatePlane(trans[1],trans[2],newRoll)
    localX=wrapCoordinate(localX*crossedRatio,ROOM_HALF_WIDTH+ROOM_WALL_THICKNESS)
    localY=wrapCoordinate(localY*crossedRatio,ROOM_HALF_HEIGHT+ROOM_WALL_THICKNESS)
    trans[1],trans[2]=rotatePlane(localX,localY,-newRoll)
    trans[3]=-ROOM_HALF_LENGTH+remainder*crossedRatio

    self.cam_roll=newRoll

    self.previousPortalRatio=crossedRatio

    if self.projectionEnabled and self.projectedRoom then
        self.projectedRoom=false
        self.projectionState='normal'
        self.forwardSpeed=self.cameraSpeed
        self.cam_yaw=0
        self.cam_pitch=0
        local previousCanvas=love.graphics.getCanvas()
        love.graphics.setCanvas(self.snapshotCanvas)
        love.graphics.clear(0,0,0,0)
        love.graphics.setCanvas(previousCanvas)
    end
end

function Stage4Rooms:update(dt)
    self.zoomFactor=self:calculateZoomFactor()
    self.camMoveSpeed=self.baseCamMoveSpeed*self.zoomFactor
    Stage4Rooms.super.update(self,dt)
    self:updateProjectionState(dt)

    self.zoomFactor=self:calculateZoomFactor()
    self.cam_translation[3]=self.cam_translation[3]+self.forwardSpeed*dt*self.zoomFactor
    while self.cam_translation[3]>=ROOM_HALF_LENGTH do
        self:enterNextRoom()
    end

    self.zoomFactor=self:calculateZoomFactor()
    self.frontDoorOpen=doorOpenAmount(ROOM_HALF_LENGTH-self.cam_translation[3])
    self.backDoorOpen=doorOpenAmount(self.cam_translation[3]+ROOM_HALF_LENGTH)

    local bulletNum=#Bullet.objects
    local brightness=math.clamp(1-bulletNum/3000,0.62,0.82)
    self.lightColor={brightness,brightness,brightness}
end

function Stage4Rooms:drawPass(canvas,drawColor)
    local previousCanvas=love.graphics.getCanvas()
    if canvas then
        love.graphics.setCanvas(canvas)
        love.graphics.clear(0,0,0,1)
    end
    local previousColor={love.graphics.getColor()}
    local color=drawColor or self.color
    love.graphics.setColor(color[1],color[2],color[3],color[4] or 1)
    love.graphics.setShader(self.shader)
    self:paramSendFunction(self.shader)
    love.graphics.rectangle('fill',0,0,800,600)
    love.graphics.setShader()
    love.graphics.setColor(previousColor[1],previousColor[2],previousColor[3],previousColor[4])
    if canvas then
        love.graphics.setCanvas(previousCanvas)
    end
end

function Stage4Rooms:draw()
    if G.save.options.reduceVisualQuality then
        return
    end
    if self.capturePending then
        local previousCanvas=love.graphics.getCanvas()
        love.graphics.setCanvas(self.snapshotCanvas)
        love.graphics.clear(0,0,0,0)
        love.graphics.setCanvas(previousCanvas)
        self:drawPass(self.captureCanvas,{1,1,1,1})
        previousCanvas=love.graphics.getCanvas()
        love.graphics.setCanvas(self.snapshotCanvas)
        love.graphics.clear(0,0,0,1)
        love.graphics.setColor(1,1,1,1)
        love.graphics.draw(self.captureCanvas,0,0)
        love.graphics.setCanvas(previousCanvas)
        self.capturePending=false
        self.projectedRoom=true
        self.projectionState='projected'
        self.forwardSpeed=0
        self.cam_translation[1]=0
        self.cam_translation[2]=0
        self.cam_translation[3]=PROJECTED_CAMERA_Z
        self.cam_roll=0
        self.cam_yaw=0
        self.cam_pitch=0
        self.frontDoorOpen=doorOpenAmount(ROOM_HALF_LENGTH-self.cam_translation[3])
        self.backDoorOpen=doorOpenAmount(self.cam_translation[3]+ROOM_HALF_LENGTH)
    end
    self:drawPass(nil)
end

return Stage4Rooms
