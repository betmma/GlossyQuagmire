---@type GeometryBase
local GeometryBase=...

---@class Cylinder
local Cylinder=GeometryBase:extend()

-- (x,y) -> (r=r0*exp(y/r0-1),theta=x/r0). cylinder's width a=r0*(math.pi*2).

Cylinder.r0=280
Cylinder.a=Cylinder.r0*math.pi*2

---@type ViewConfig
Cylinder.viewConfig={
    following=true,
    screenCenter={x=WINDOW_HEIGHT/2-WINDOW_WIDTH/40,y=WINDOW_HEIGHT/2},
}

function Cylinder:init()
    return {pos={x=-self.a/4,y=250},speed=0,dir=0}
end

function Cylinder:update(state,dt)
    dt=dt or (1/60)
    state.pos.x=(state.pos.x+state.speed*math.cos(state.dir)*dt)%self.a
    state.pos.y=state.pos.y+state.speed*math.sin(state.dir)*dt
end

function Cylinder:distance(position1,position2)
    local dx=math.abs(math.modClamp(position2.x-position1.x,0,self.a/2))
    local dy=position2.y-position1.y
    return math.sqrt(dx*dx+dy*dy)
end

function Cylinder:to(position,target)
    local dx=math.modClamp(target.x-position.x,0,self.a/2)
    local dy=target.y-position.y
    return math.atan2(dy,dx)
end

function Cylinder:nearestToLine(position,linePoint1,linePoint2)
    local lineDX=linePoint2.x-linePoint1.x
    local lineDY=linePoint2.y-linePoint1.y
    -- calculate the horizontal intersection point
    if math.abs(lineDY)<1e-5 then
        return {x=position.x,y=linePoint1.y}
    end
    local intersectionX=linePoint1.x+(position.y-linePoint1.y)/lineDY*lineDX
    local x=math.modClamp(position.x,intersectionX,self.a/2)
    local lineLengthSquared=lineDX*lineDX+lineDY*lineDY
    local t=((x-linePoint1.x)*lineDX+(position.y-linePoint1.y)*lineDY)/lineLengthSquared
    return {
        x=linePoint1.x+t*lineDX,
        y=linePoint1.y+t*lineDY,
    }
end

function Cylinder:toScreen(position)
    local r=self.r0*math.exp(position.y/self.r0-1)
    local theta=-position.x/self.r0
    if self.viewConfig.following then
        theta=theta+G.runInfo.player.kinematicState.pos.x/self.r0+math.pi/2
    end
    local x2,y2=r*math.cos(theta),r*math.sin(theta)
    local screenCenter=self.viewConfig.screenCenter
    return {{x=x2+screenCenter.x,y=y2+screenCenter.y,rotation=theta-math.pi/2}}
end

function Cylinder:canSimpleDraw(position,radius)
    local ratio=radius/self.r0
    if ratio<0.1 then
        return true,8
    end
    return false,math.ceil(ratio*40)+6
end

function Cylinder:applyVertexShader(viewer)
end

function Cylinder:zoomFactorToScreen(position)
    return {math.exp(position.y/self.r0-1)}
end

function Cylinder:applyForegroundShader()
    local radius=self.r0
    G.CONSTANTS.USE_FOREGROUND_SHADER('RING',{centerXY={self.viewConfig.screenCenter.x,self.viewConfig.screenCenter.y},radius=radius,innerRadius=self.r0*math.exp(-2)})
end

return Cylinder