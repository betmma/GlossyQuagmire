---@class GeometryBase:Object base class for all geometries. is actually euclidean geometry as an example (and also because lua annotation doesnt support abstract classes). should not be instantiated as only its methods are used.
---@field init fun():KinematicState returns a default kinematic state. objects in game will have kinematic states.
---@field update fun(state:KinematicState,dt:number):nil updates the kinematic state. Note that, this may choose not to use the precise rThetaGo. from previous experience, approximation is good enough.
---@field rThetaGo fun(position:Position,length:number,direction:number):Position,number from the [position], facing the [direction] and go [length] units forward, return the new position and the new direction facing.
---@field distance fun(position1:Position,position2:Position):number returns the distance between two positions.
---@field to fun(position:Position,target:Position):number from the [position], the direction facing the [target] (if multiple directions are possible, return the one along which the distance is shortest)
---@field sideToLine fun(position:Position,linePoint1:Position,linePoint2:Position):boolean returns which side of the line formed by linePoint1 and linePoint2 the position is on. it doesn't important which side is true or false.
-------- below are related to drawing
---@field toScreen fun(position:Position):Position[] convert the position in geometry space to screen space. it's possible to return multiple positions for later shader processing, and the draw function needs to handle that. it should not consider the viewConfig (and like following in it). viewConfig should only affect applyDrawShader.
---@field canSimpleDraw fun(position:Position,radius:number):boolean returns whether an object at the position with the radius (in geometry space) can be drawn with a simple quad within acceptable distortion. if false, the object should be drawn with a custom mesh.
---@field applyDrawShader fun(viewer:Viewer):nil apply shader for drawing objects in this geometry if needed. the viewer is usually the player, and the shader will need the viewer's position and direction to do correct projection.
---@field public viewConfig ViewConfig
--------below are methods defaulted to be composed by using the above methods, but you can override them for better performance if you want.
---@field rThetaTo fun(position:Position,target:Position):number,number from the [position], the distance to the target and the direction facing the [target] (if multiple values are possible, return the shortest distance and the corresponding direction)
---@field zoomFactorToScreen fun(position:Position):number returns the zoom factor at the screen space of the position. it's used to draw quads (only a square) where distortion is negligible (and with prerequisite that the geometry is conformal). the default implementation calls toScreen on position and position+small value to estimate.
local GeometryBase=Object:extend()
function GeometryBase:new()
    error("Geometry cannot be instantiated.")
end

---@class ViewConfig
---@field following boolean whether the view will follow the player.
---@field screenCenter Position if following is true, the view will put player at this position on screen.

---@class Position
---@field x number
---@field y number

---@class Viewer:Position
---@field viewDirection number note that it doesn't need to be the same as the direction of movement.

---@class KinematicState:Position
---@field speed number
---@field direction number

GeometryBase.viewConfig={
    following=false,
    screenCenter={x=WINDOW_WIDTH/2,y=WINDOW_HEIGHT/2},
}

function GeometryBase.init()
    return {x=0,y=0,speed=0,direction=0}
end

function GeometryBase.update(state,dt)
    state.x=state.x+state.speed*math.cos(state.direction)*dt
    state.y=state.y+state.speed*math.sin(state.direction)*dt
end

function GeometryBase.rThetaGo(position,length,direction)
    local newPosition={
        x=position.x+length*math.cos(direction),
        y=position.y+length*math.sin(direction),
    }
    local newDirection=direction
    return newPosition,newDirection
end

function GeometryBase.distance(position1,position2)
    local dx=position2.x-position1.x
    local dy=position2.y-position1.y
    return math.sqrt(dx*dx+dy*dy)
end

function GeometryBase.to(position,target)
    local dx=target.x-position.x
    local dy=target.y-position.y
    return math.atan2(dy,dx)
end

function GeometryBase.sideToLine(position,linePoint1,linePoint2)
    local value=(linePoint2.x-linePoint1.x)*(position.y-linePoint1.y)-(linePoint2.y-linePoint1.y)*(position.x-linePoint1.x)
    return value>0
end

function GeometryBase.toScreen(position)
    return position
end

function GeometryBase.canSimpleDraw(position,radius)
    return true
end

function GeometryBase.applyDrawShader(viewer)
    -- needs translation if viewConfig.following is true.
    if GeometryBase.viewConfig.following then
        love.graphics.translate(GeometryBase.viewConfig.screenCenter.x-viewer.x,GeometryBase.viewConfig.screenCenter.y-viewer.y)
    end
end

--- below are default implementations of some methods that can be composed by using the above methods.

function GeometryBase.rThetaTo(position,target)
    return GeometryBase.distance(position,target),GeometryBase.to(position,target)
end

local geometries={
    GeometryBase=GeometryBase,
    Euclidean=GeometryBase,
---@type Hyperbolic
    Hyperbolic=love.filesystem.load("geometries/hyperbolic.lua")(GeometryBase),
}
return geometries