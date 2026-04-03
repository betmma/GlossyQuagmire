---@type GeometryBase
local GeometryBase=...

---@class HyperbolicViewConfig:ViewConfig
---@field hyperbolicModel HYPERBOLIC_MODEL which hyperbolic model to use
---@field diskRadiusBase table<HYPERBOLIC_MODEL,number> size of disks (window height is 1). value for UHP is ignored.

---@enum HYPERBOLIC_MODEL
local HYPERBOLIC_MODEL={ -- use number is because it will be sent to shader
    UHP=0,
    P_DISK=1,
    K_DISK=2
}

---@class Hyperbolic
local Hyperbolic=GeometryBase:extend()
Hyperbolic.curvature=200
Hyperbolic.axisY=0
Hyperbolic.EPS=1e-8
Hyperbolic.HYPERBOLIC_MODELS=HYPERBOLIC_MODEL
---@type HyperbolicViewConfig
Hyperbolic.viewConfig={
    following=true,
    screenCenter={x=WINDOW_HEIGHT/2-WINDOW_WIDTH/40,y=WINDOW_HEIGHT/2},
    hyperbolicModel=Hyperbolic.HYPERBOLIC_MODELS.P_DISK,
    diskRadiusBase={
        [Hyperbolic.HYPERBOLIC_MODELS.P_DISK]=14/15,
        [Hyperbolic.HYPERBOLIC_MODELS.K_DISK]=14/15
    },
}

------- internal helper functions
---@alias coordinate number
---@alias angle number
---@param x coordinate
---@param y coordinate
---@param r number
function Hyperbolic:getCircle(x,y,r)
    return x, (y-Hyperbolic.axisY)*math.cosh(r/Hyperbolic.curvature)+Hyperbolic.axisY, (y-Hyperbolic.axisY)*math.sinh(r/Hyperbolic.curvature)
end

-- get X coordinate and radius of center point of line x1,y1 to x2,y2
---@return coordinate centerX X coordinate of center point
---@return number radius (Euclidean) radius of line
function Hyperbolic:lineCenter(x1,y1,x2,y2)
    local x0=(x1+x2)/2
    local y0=(y1+y2)/2
    if x1==x2 then -- vertical 
        return 0,1e308
    end
    local k=(y2-y1)/(x2-x1)
    local centerX=x0+(y0-Hyperbolic.axisY)*k
    return centerX,math.distance(centerX,Hyperbolic.axisY,x1,y1)
end


-- calculate the SIGNED ON-SCREEN distance a point xc,yc to line [x1,y1 to x2,y2] (positive when in/out the semicircle if angle p1 to p2 is negative/positive // left to a vertical line)
function Hyperbolic:onscreenDistanceToLineSigned(xc,yc,x1,y1,x2,y2)
    if math.abs(x1-x2)<Hyperbolic.EPS then -- vertical
        if y2<y1 then -- the line goes upward
            return x1-xc
        end
        return xc-x1
    end
    local centerX,radius=Hyperbolic:lineCenter(x1,y1,x2,y2)
    local theta1=math.atan2(y1-Hyperbolic.axisY,x1-centerX)
    local theta2=math.atan2(y2-Hyperbolic.axisY,x2-centerX)
    if theta1>theta2 then
        return radius-math.distance(centerX,Hyperbolic.axisY,xc,yc)
    end
    return math.distance(centerX,Hyperbolic.axisY,xc,yc)-radius
end

--- hyperbolic rotate a point (x1,y1) around (ox,oy) by angle. Uses inlined mobius transformation.
---@param x1 coordinate
---@param y1 coordinate
---@param angle angle
---@param ox coordinate
---@param oy coordinate
---@return coordinate "x2"
---@return coordinate "y2"
function Hyperbolic:rotateAround(x1, y1, angle, ox, oy)
    -- S_d_im: imaginary part of S_d. Real part of S_d is -ox.
    local S_d_im = oy - 2*Hyperbolic.axisY

    -- U_a = cos(angle) + i*sin(angle)
    local U_a_re, U_a_im = math.cos(angle), math.sin(angle)

    local T_tmp_a_re = -ox * U_a_re - S_d_im * U_a_im
    local T_tmp_a_im = -ox * U_a_im + S_d_im * U_a_re

    local T_final_a_re = T_tmp_a_re + ox
    local T_final_a_im = T_tmp_a_im + oy

    local T_final_b_re = -T_tmp_a_re * ox + T_tmp_a_im * oy - ox * ox - oy * S_d_im
    local T_final_b_im = -T_tmp_a_re * oy - T_tmp_a_im * ox + ox * S_d_im - oy * ox

    -- T_final_c = T_tmp_c + 1 (where T_tmp_c = -U_a)
    local T_final_c_re = -U_a_re + 1
    local T_final_c_im = -U_a_im

    local T_final_d_re = U_a_re * ox - U_a_im * oy - ox
    local T_final_d_im = U_a_re * oy + U_a_im * ox + S_d_im

    -- Numerator = T_final_a * z + T_final_b
    local num_re = T_final_a_re * x1 - T_final_a_im * y1 + T_final_b_re
    local num_im = T_final_a_re * y1 + T_final_a_im * x1 + T_final_b_im

    -- Denominator = T_final_c * z + T_final_d
    local den_re = T_final_c_re * x1 - T_final_c_im * y1 + T_final_d_re
    local den_im = T_final_c_re * y1 + T_final_c_im * x1 + T_final_d_im

    -- Division: num / den = num * conj(den) / |den|^2
    local den_mod_sq = den_re * den_re + den_im * den_im

    -- if den_mod_sq == 0 then error("Division by zero in Mobius apply") end

    local common_divisor = 1.0 / den_mod_sq
    local result_re = (num_re * den_re + num_im * den_im) * common_divisor
    local result_im = (num_im * den_re - num_re * den_im) * common_divisor

    return result_re, result_im
end
-------

function Hyperbolic:update(state,dt)
    dt=dt or (1/60)
    local metric=(state.pos.y-Hyperbolic.axisY)/Hyperbolic.curvature
    local moveDistance=state.speed*dt*metric
    if state.speed*dt<2 then
        state.pos.x=state.pos.x+moveDistance*math.cos(state.dir)
        state.pos.y=state.pos.y+moveDistance*math.sin(state.dir)
        local moveRadius=(state.pos.y-Hyperbolic.axisY)/math.cos(state.dir)
        state.dir=state.dir-moveDistance/moveRadius
    else
        local newPos,newDir=self:rThetaGo(state.pos,state.speed*dt,state.dir)
        state.pos.x=newPos.x
        state.pos.y=newPos.y
        state.dir=newDir
    end
end

function Hyperbolic:rThetaGo(position,length,direction)
    if length==0 then
        return copy_table(position),direction
    end
    local rLT0=length<0
    if rLT0 then
        length=-length
        direction=direction+math.pi
    end
    local x2,y2,r2=Hyperbolic:getCircle(position.x,position.y,length)
    local xp,yp=x2,y2+r2 -- theta=pi/2
    local retX,retY=Hyperbolic:rotateAround(xp,yp,direction-math.pi/2,position.x,position.y)
    local newPos={x=retX,y=retY}
    return newPos,Hyperbolic:to(newPos,position)+(rLT0 and 0 or math.pi) -- if r>0 add pi
end

function Hyperbolic:distance(position1,position2)
    local x1,y1,x2,y2=position1.x,position1.y,position2.x,position2.y
    local ay=Hyperbolic.axisY
    return 2*Hyperbolic.curvature*math.log((math.distance(x1,y1,x2,y2)+math.distance(x1,y1,x2,2*ay-y2))/(2*((y1-ay)*(y2-ay))^0.5))
end

function Hyperbolic:to(position,target)
    local x1,y1,x2,y2=position.x,position.y,target.x,target.y
    if math.abs(x1-x2)<Hyperbolic.EPS then -- vertical 
        return y1<y2 and math.pi/2 or -math.pi/2
    end
    local centerX=Hyperbolic:lineCenter(x1,y1,x2,y2)
    local theta1=math.atan2(y1-Hyperbolic.axisY,x1-centerX)
    local theta2=math.atan2(y2-Hyperbolic.axisY,x2-centerX)
    if theta1<theta2 then
        return theta1+math.pi/2
    end
    return theta1-math.pi/2
end

function Hyperbolic:sideToLine(position,linePoint1,linePoint2)
    local x1,y1=position.x,position.y
    local x2,y2=linePoint1.x,linePoint1.y
    local x3,y3=linePoint2.x,linePoint2.y
    return Hyperbolic:onscreenDistanceToLineSigned(x1,y1,x2,y2,x3,y3)>0
end

function Hyperbolic:toScreen(position)
    return {position}
end

function Hyperbolic:canSimpleDraw(position,radius)
    local ratio=radius/Hyperbolic.curvature
    if ratio<0.1 then
        return true,8
    end
    local sides=math.clamp(math.ceil(ratio*GeometryBase.MESH_MAX_SIDES),8,GeometryBase.MESH_MAX_SIDES)
    return false,sides
end

Hyperbolic.hyperbolicRotateShader=ShaderScan:load_shader("shaders/hyperbolicRotateM.glsl")

function Hyperbolic:applyDrawShader(viewer)
    local shader=Hyperbolic.hyperbolicRotateShader
    love.graphics.setShader(shader)
    local center={Hyperbolic.viewConfig.screenCenter.x,Hyperbolic.viewConfig.screenCenter.y}
    if Hyperbolic.viewConfig.following then
        shader:send("player_pos", {viewer.kinematicState.pos.x, viewer.kinematicState.pos.y})
        shader:send("rotation_angle",-viewer.viewDirection)
    else
        shader:send("player_pos", center)
        shader:send("rotation_angle",0)
    end
    shader:send("aim_pos", center)
    shader:send("shape_axis_y", Hyperbolic.axisY)
    shader:send("hyperbolic_model", Hyperbolic.viewConfig.hyperbolicModel)
    shader:send("r_factor", Hyperbolic.viewConfig.diskRadiusBase[Hyperbolic.viewConfig.hyperbolicModel] or 1)
end

function Hyperbolic:applyForegroundShader()
    if Hyperbolic.viewConfig.hyperbolicModel==Hyperbolic.HYPERBOLIC_MODELS.UHP then
        G.CONSTANTS.USE_FOREGROUND_SHADER('RECTANGLE',{xywh={20,20,480,560}})
    else
        local radius=Hyperbolic.viewConfig.diskRadiusBase[Hyperbolic.viewConfig.hyperbolicModel]*WINDOW_HEIGHT*0.5
        G.CONSTANTS.USE_FOREGROUND_SHADER('CIRCLE',{centerXY={Hyperbolic.viewConfig.screenCenter.x,Hyperbolic.viewConfig.screenCenter.y},radius=radius})
    end

end

function Hyperbolic:zoomFactorToScreen(position)
    return {(position.y-Hyperbolic.axisY)/Hyperbolic.curvature}
end

return Hyperbolic