---@class GeometryBase:Object base class for all geometries. is actually euclidean geometry as an example (and also because lua annotation doesnt support abstract classes). should not be instantiated as only its methods are used.
---@field init fun(self):KinematicState returns a default kinematic state. objects in game will have kinematic states.
---@field update fun(self,state:KinematicState,dt:number):nil updates the kinematic state. Note that, this may choose not to use the precise rThetaGo. from previous experience, approximation is good enough.
---@field rThetaGo fun(self,position:Position,length:number,direction:number):Position,number from the [position], facing the [direction] and go [length] units forward, return the new position and the new direction facing.
---@field distance fun(self,position1:Position,position2:Position):number returns the distance between two positions.
---@field to fun(self,position:Position,target:Position):number from the [position], the direction facing the [target] (if multiple directions are possible, return the one along which the distance is shortest)
---@field sideToLine fun(self,position:Position,linePoint1:Position,linePoint2:Position):boolean returns which side of the line formed by linePoint1 and linePoint2 the position is on. it doesn't important which side is true or false.
-------- below are related to drawing
---@field toScreen fun(self,position:Position):PossiblePosition[] convert the position in geometry space to screen space. it's possible to return multiple positions for later shader processing, and the draw function needs to handle that. if returns multiple positions (like to two circles), ensure the order (first element goes to the first circle. if does not map to first circle, first element should be Dummy). it could consider the viewConfig (and like following in it).
---@field canSimpleDraw fun(self,position:Position,radius:number):boolean returns whether an object at the position with the radius (in geometry space) can be drawn with a simple quad within acceptable distortion. if false, the object should be drawn with a custom mesh.
---@field applyDrawShader fun(self,viewer:Viewer):nil apply shader for drawing objects in this geometry if needed. the viewer is usually the player, and the shader will need the viewer's position and direction to do correct projection.
---@field applyForegroundShader fun(self):nil apply shader for drawing foreground. like make a rectangle hole to show the gameplay area.
---@field public viewConfig ViewConfig
--------below are methods defaulted to be composed by using the above methods, but you can override them for better performance if you want.
---@field rThetaTo fun(self,position:Position,target:Position):number,number from the [position], the distance to the target and the direction facing the [target] (if multiple values are possible, return the shortest distance and the corresponding direction)
---@field zoomFactorToScreen fun(self,position:Position):number[] returns the zoom factors at the screen space of the position (one for each toScreen results). it's used to draw quads (only a square) where distortion is negligible (and with prerequisite that the geometry is conformal). the default implementation calls toScreen on position and position+small value to estimate.
local GeometryBase=Object:extend()
function GeometryBase:new()
    error("Geometry cannot be instantiated.")
end

---@class Dummy
---@field dummy true
GeometryBase.Dummy={dummy=true} -- for toScreen to return when there is no corresponding screen position

---@class ViewConfig
---@field following boolean whether the view will follow the player.
---@field screenCenter Position if following is true, the view will put player at this position on screen.

---@class Position
---@field x number
---@field y number

---@alias PossiblePosition Position|Dummy

---@class Viewer
---@field viewDirection number note that it doesn't need to be the same as the direction of movement.
---@field kinematicState KinematicState

---@class KinematicState:Position
---@field speed number
---@field direction number

GeometryBase.viewConfig={
    following=false,
    screenCenter={x=WINDOW_WIDTH/2,y=WINDOW_HEIGHT/2},
}

function GeometryBase:init()
    return {x=250,y=500,speed=0,direction=0}
end

function GeometryBase:update(state,dt)
    dt=dt or (1/60)
    state.x=state.x+state.speed*math.cos(state.direction)*dt
    state.y=state.y+state.speed*math.sin(state.direction)*dt
end

function GeometryBase:rThetaGo(position,length,direction)
    local newPosition={
        x=position.x+length*math.cos(direction),
        y=position.y+length*math.sin(direction),
    }
    local newDirection=direction
    return newPosition,newDirection
end

function GeometryBase:distance(position1,position2)
    local dx=position2.x-position1.x
    local dy=position2.y-position1.y
    return math.sqrt(dx*dx+dy*dy)
end

function GeometryBase:to(position,target)
    local dx=target.x-position.x
    local dy=target.y-position.y
    return math.atan2(dy,dx)
end

function GeometryBase:sideToLine(position,linePoint1,linePoint2)
    local value=(linePoint2.x-linePoint1.x)*(position.y-linePoint1.y)-(linePoint2.y-linePoint1.y)*(position.x-linePoint1.x)
    return value>0
end

function GeometryBase:toScreen(position)
    return {position}
end

function GeometryBase:canSimpleDraw(position,radius)
    return true
end

function GeometryBase:applyDrawShader(viewer)
    -- needs translation if viewConfig.following is true.
    if GeometryBase.viewConfig.following then
        love.graphics.translate(GeometryBase.viewConfig.screenCenter.x-viewer.kinematicState.x,GeometryBase.viewConfig.screenCenter.y-viewer.kinematicState.y)
    end
end

function GeometryBase:applyForegroundShader()
    G.CONSTANTS.USE_FOREGROUND_SHADER('RECTANGLE',{xywh={20,20,480,560}}) -- in official games, screen is divided into 40*30 grid. gameplay area is 25*30 with border taking up 1 block on up, left and down sides.
end

--- below are default implementations of some methods that can be composed by using the above methods.

function GeometryBase:rThetaTo(position,target)
    return self:distance(position,target),self:to(position,target)
end

function GeometryBase:zoomFactorToScreen(position)
    local screenPos=self:toScreen(position)
    local kinematicState={x=position.x,y=position.y,speed=60,direction=0}
    self:update(kinematicState,1/60) -- use update to move a small step in geometry space (1 unit)
    local screenPos2=self:toScreen({x=kinematicState.x,y=kinematicState.y})
    local screenDistance={}
    for i=1,#screenPos do
        screenDistance[i]=math.distance(screenPos[i].x,screenPos[i].y,screenPos2[i].x,screenPos2[i].y)
    end
    return screenDistance
end

local geometries={
    GeometryBase=GeometryBase,
    Euclidean=GeometryBase,
---@type Hyperbolic
    Hyperbolic=love.filesystem.load("geometries/hyperbolic.lua")(GeometryBase),
}
return geometries