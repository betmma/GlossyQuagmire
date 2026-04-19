--- method annotations are in meta/geometries.d.lua.

---@class GeometryBase
local GeometryBase=Object:extend()
function GeometryBase:new()
    error("Geometry cannot be instantiated.")
end

---@class Dummy
---@field dummy true
GeometryBase.Dummy={dummy=true} -- for toScreen to return when there is no corresponding screen position

GeometryBase.viewConfig={
    following=false,
    screenCenter={x=WINDOW_WIDTH/2,y=WINDOW_HEIGHT/2},
}

function GeometryBase:init()
    return {pos={x=250,y=500},speed=0,dir=0}
end

function GeometryBase:update(state,dt)
    dt=dt or (1/60)
    state.pos.x=state.pos.x+state.speed*math.cos(state.dir)*dt
    state.pos.y=state.pos.y+state.speed*math.sin(state.dir)*dt
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
    return true,8
end

GeometryBase.MESH_MAX_SIDES=64

function GeometryBase:applyVertexShader(viewer)
    -- needs translation if viewConfig.following is true.
    if GeometryBase.viewConfig.following then
        love.graphics.translate(GeometryBase.viewConfig.screenCenter.x-viewer.kinematicState.pos.x,GeometryBase.viewConfig.screenCenter.y-viewer.kinematicState.pos.y)
    end
end

function GeometryBase:applyPixelShader(viewer)
    -- default does nothing
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
    local kinematicState={pos=copyTable(position),speed=60,dir=0}
    self:update(kinematicState,1/60) -- use update to move a small step in geometry space (1 unit)
    local screenPos2=self:toScreen(kinematicState.pos)
    local screenDistance={}
    for i=1,#screenPos do
        screenDistance[i]=math.distance(screenPos[i].x,screenPos[i].y,screenPos2[i].x,screenPos2[i].y)
    end
    return screenDistance
end

local geometries={
    -- GeometryBase=GeometryBase,
    Euclidean=GeometryBase,
---@type Hyperbolic
    Hyperbolic=love.filesystem.load("geometries/hyperbolic.lua")(GeometryBase),
---@type Spherical
    -- Spherical=love.filesystem.load("geometries/spherical.lua")(GeometryBase),
}
return geometries