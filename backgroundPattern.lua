local BackgroundPattern=GameObject:extend()

-- BackgroundPattern is an abstract class that needs implementation of:
-- 1. new(args): initialize the background pattern.
-- 2. update(dt): update the background pattern, called in love.update(dt)
-- 3. draw(): draw the background pattern, called in love.draw()
-- It will be bound to G and called in G.update and G.draw.
function BackgroundPattern:new(args)
    self.notRespondToDrawAll=true -- Since background should be drawn before everything else, it should not be drawn by Object:drawAll but directly called in G.draw before Object:drawAll.
end

local Empty=BackgroundPattern:extend()
function Empty:new(args)
    Empty.super.new(self,args)
end
BackgroundPattern.Empty=Empty

local ShapeF=require('geometries.geometryBase').Hyperbolic

--- Calculates the coordinates of the vertices of a Schwarz triangle (p,q,r)
--- in the Upper Half-Plane model. vertices are ordered in counter-clockwise direction.
---@param p integer Reciprocal of the angle at vertex v0 (angle = pi/p).
---@param q integer Reciprocal of the angle at vertex v1 (angle = pi/q).
---@param r integer Reciprocal of the angle at vertex v2 (angle = pi/r).
---@param v0_coord table Coordinates of the first vertex, e.g., {x=0, y=1} or {0,1}.
---                     It's assumed y-coordinate is > ShapeF.axisY.
---@param dir_v0v1_angle number Hyperbolic angle (in radians) of the side v0-v1 at v0,
---                             as expected by ShapeF.rThetaGo.
---@return table v0_out {x, y} coordinates of the first vertex.
---@return table v1_out {x, y} coordinates of the second vertex.
---@return table v2_out {x, y} coordinates of the third vertex.
function ShapeF.schwarzTriangleVertices(p, q, r, v0_coord, dir_v0v1_angle)
    -- 1. Extract v0 coordinates
    local v0x = v0_coord.x or v0_coord[1]
    local v0y = v0_coord.y or v0_coord[2]
  
    if v0x == nil or v0y == nil then
      error("v0_coord must contain recognizable x and y parts (e.g., {x=val, y=val} or {val1,val2}).")
    end
    if v0y <= ShapeF.axisY then
      error(string.format("The y-coordinate of v0_coord (%.2f) must be greater than ShapeF.axisY (%.2f) in the Upper Half-Plane model.", v0y, ShapeF.axisY))
    end
    
    local v0_out = {v0x, v0y}
  
    -- 2. Calculate internal angles of the triangle (A at v0, B at v1, C at v2)
    local angle_A = math.pi / p
    local angle_B = math.pi / q
    local angle_C = math.pi / r
  
    -- 3. Calculate model-scaled hyperbolic side lengths
    --    The hyperbolic law of cosines gives d_intrinsic = acosh(...).
    --    The distance used by ShapeF.rThetaGo should be d_model = ShapeF.curvature * d_intrinsic.
    local cos_A = math.cos(angle_A)
    local cos_B = math.cos(angle_B)
    local cos_C = math.cos(angle_C)
    local sin_A = math.sin(angle_A)
    local sin_B = math.sin(angle_B)
    local sin_C = math.sin(angle_C) -- Used for side b
  
    -- Check for valid denominators to prevent division by zero or issues with acosh input
    local den_c = sin_A * sin_B
    if math.abs(den_c) < 1e-9 then 
      error("Degenerate triangle geometry for side c (p or q too large, or invalid). sin(A) or sin(B) is near zero.")
    end
    local cosh_c_val = (cos_A * cos_B + cos_C) / den_c
    local dist_v0v1_intrinsic = math.acosh(cosh_c_val) -- math.acosh is assumed to be defined
    local dist_v0v1_model = ShapeF.curvature * dist_v0v1_intrinsic
  
    local den_b = sin_A * sin_C
    if math.abs(den_b) < 1e-9 then
      error("Degenerate triangle geometry for side b (p or r too large, or invalid). sin(A) or sin(C) is near zero.")
    end
    local cosh_b_val = (cos_A * cos_C + cos_B) / den_b
    local dist_v0v2_intrinsic = math.acosh(cosh_b_val)
    local dist_v0v2_model = ShapeF.curvature * dist_v0v2_intrinsic
  
    -- 4. Calculate v1 using ShapeF.rThetaGo
    local v1 = ShapeF:rThetaGo({x=v0x,y=v0y}, dist_v0v1_model, dir_v0v1_angle)
    local v1_out = {v1.x, v1.y}
  
    -- 5. Calculate v2 using ShapeF.rThetaGo
    --    Angle at v0 is angle_A. For CCW order (v0,v1,v2), turn from v0v1 to v0v2 is -angle_A.
    local dir_v0v2_angle = dir_v0v1_angle - angle_A 
    local v2 = ShapeF:rThetaGo({x=v0x,y=v0y}, dist_v0v2_model, dir_v0v2_angle)
    local v2_out = {v2.x, v2.y}
  
    return v0_out, v1_out, v2_out
end

local sideLengthCache={}
-- calculate {the side length} and {radius of circumcircle} of a polygon with [sideNum] sides and each angle 2pi/[angleNum] in hyperbolic geometry. The result is cached.
local calculateSideLength=function(sideNum,angleNum)
    if sideLengthCache[sideNum] and sideLengthCache[sideNum][angleNum] then
        return sideLengthCache[sideNum][angleNum][1],sideLengthCache[sideNum][angleNum][2]
    end
    local centerToVertex=(math.sqrt((math.tan(math.pi/2-math.pi/angleNum)-math.tan(math.pi/sideNum))/(math.tan(math.pi/2-math.pi/angleNum)+math.tan(math.pi/sideNum)))) -- reference: https://www.malinc.se/noneuclidean/en/poincaretiling.php. sideNum->p, angleNum->q. actually this radius is on a poincare disk
    local x1,y1=centerToVertex,0
    local x2,y2=centerToVertex*math.cos(math.pi*2/sideNum),centerToVertex*math.sin(math.pi*2/sideNum) -- two points on a side, on a poincare disk
    local d=2*math.distance(x1,y1,x2,y2)^2/(1-centerToVertex^2)^2
    local sideLength= math.acosh(1+d)*ShapeF.curvature -- distance formula of poincare disk. reference: https://en.wikipedia.org/wiki/Poincar%C3%A9_disk_model
    local circumcircleRadius=2*math.atanh(centerToVertex)*ShapeF.curvature -- distance formula when 1 point is at center. 
    sideLengthCache[sideNum]=sideLengthCache[sideNum] or {}
    sideLengthCache[sideNum][angleNum]={sideLength,circumcircleRadius}
    return sideLength,circumcircleRadius
end
BackgroundPattern.calculateSideLength=calculateSideLength

local function getCenterOfPolygonWithSide(x1,y1,x2,y2,sideNum,angleNum)
    local direction=ShapeF:to({x=x2,y=y2}, {x=x1,y=y1})
    local toCenterDirection=direction+math.pi*2/angleNum/2
    local _,centerRadius=calculateSideLength(sideNum,angleNum)
    local x,y=ShapeF:rThetaGo({x=x2,y=y2}, centerRadius, toCenterDirection)
    return x,y
end
BackgroundPattern.getCenterOfPolygonWithSide=getCenterOfPolygonWithSide

--[[
params: 
[point]: where pattern begins. [angle]: direction of first line. [sideNum]: how many sides do each polygon have. [angleNum]: how many sides are connected to each point. [iteCount]: input 0, currently only to check if it's first point. [centerPoint]: input nil. [toDrawNum]: how many lines to draw. If only draw sides, a few hundred to merely above 1000 is a reasonable number. If draw faces <400 is recommended.
returns: 
adjacentPoints,angles,sidesTable. [adjacentPoints]: adjacent points to centerPoint (inputted point). [angles]: angles from each adjacent point to center point. I knew it's only used to update center point while keeping the pattern same, so angle should be to center point. [sidesTable]: all sides that are drawn. Each side is a table {point1,point2,index}. index is the index of the side in the sidesTable.
the way to find tesselation points is rather simple: from a point, extend angleNum lines, and only keep points that are farther away from the center point. This is because the closer points are already drawn by the previous lines. However when sideNum is odd (especially 3) some lines' two ends have same distance to the center point, so another check (polar angle) is added to prevent the side drawn 0 or 2 times.
pointsQueue is a queue that stores points that are not drawn yet, drawedPointsNum being the pointer. If drawedPointsNum is more than toDrawNum/angleNum, clear the queue to stop the tesselation. So that you shouldn't try getting points information from pointsQueue since it's always cleared when function ends.]]
local drawedPointsNum=0
local pointsQueue={}
-- key format: key:int = ceil(distance to centerPoint)*1000+floor(angle*1000)
local visitedPoints={}
local function tesselation(point,angle,sideNum,angleNum,iteCount, centerPoint, toDrawNum, sidesTable, skipInRangeLimit)
    centerPoint=centerPoint or point
    if iteCount==0 then
        drawedPointsNum=0
        pointsQueue={}
        visitedPoints={}
    end
    local iteCount=(iteCount or 0)+1
    local adjacentPoints={}
    local r=calculateSideLength(sideNum,angleNum)
    local begin=1
    local en=angleNum--iteCount>1 and angleNum-2 or angleNum
    sidesTable=sidesTable or {}

    drawedPointsNum=drawedPointsNum+1
    local distance0=ShapeF:distance(point,centerPoint)
    for i=begin,en do
        if not skipInRangeLimit and not math.inRange(point.x,point.y,-400,1200,-5,4000) then
            break
        end
        local alpha=angle+math.pi*2/angleNum*(i)
        local ret={ShapeF:rThetaGo(point,r,alpha)}
        local newpoint={x=ret[1],y=ret[2]}
        local distance=ShapeF:distance(newpoint,centerPoint)
        -- these two ifs fully exclude duplicate sides, but points still can duplicate (two points connect to same further point)
        local centerAngle=ShapeF:to(centerPoint,newpoint)
        if distance<distance0-ShapeF.EPS*10 then
            goto continue
        elseif distance<distance0+ShapeF.EPS*10 then -- same distance on both ends: check angle
            if ShapeF:to(centerPoint,point)>centerAngle then
                goto continue
            end
        end
        local centerDistance=ShapeF:distance(centerPoint,newpoint)
        local key=math.ceil(centerDistance)*1000+math.floor(centerAngle*1000)
        if not visitedPoints[key] then -- skip redundant new point
            adjacentPoints[#adjacentPoints+1]=newpoint
            visitedPoints[key]=true
        end
        local len=#sidesTable
        sidesTable[len+1]={point,newpoint,index=len+1}
        if len+1>=toDrawNum then
            break
        end
        ::continue::
    end
    local angles={}
    for i=1,#adjacentPoints do
        local newpoint=adjacentPoints[i]
        local newangle=ShapeF:to(newpoint,point)
        table.insert(angles,newangle)
        pointsQueue[#pointsQueue+1]={newpoint,newangle,iteCount}
        -- tesselation(newpoint,newangle,sideNum,angleNum,iteCount,color,i==1,centerPoint)
    end
    if #sidesTable<toDrawNum and pointsQueue[drawedPointsNum]then 
        tesselation(pointsQueue[drawedPointsNum][1],pointsQueue[drawedPointsNum][2],sideNum,angleNum,pointsQueue[drawedPointsNum][3],centerPoint,toDrawNum,sidesTable, skipInRangeLimit)
    else
        pointsQueue={}
    end

    return adjacentPoints,angles,sidesTable
end

BackgroundPattern.tesselation=tesselation

local shader=ShaderScan:load_shader('shaders/flipTessellation.glsl')

-- a tesselation that moves and rotates. It's used in main menu.
local MainMenuTesselation=BackgroundPattern:extend()
function MainMenuTesselation:new(args)
    MainMenuTesselation.super.new(self,args)
    -- self.name='Tesselation'
    args=args or {}
    self.p=args.p or 2
    self.q=args.q or 5
    self.r=args.r or 5
    self.shader=shader
    self.uvPoses={{265/800,376/600},{534/800,376/600},{399/800,140/600}}
    -- self.uvPoses={{0.5-3^0.5/4,1},{0.5+3^0.5/4,1},{0.5,0}}
    self.frame=0
end

function MainMenuTesselation:update(dt)
    self.frame=self.frame+1
end

function MainMenuTesselation:randomize()
    local rand=math.random(1,3)
    self.uvPoses[rand],self.uvPoses[rand%3+1]=self.uvPoses[rand%3+1],self.uvPoses[rand] -- swap 2 random uvPoses
    local tried=0
    while tried<20 do
        local p=math.random(3,14)/2
        local q=math.random(3,14)/2
        local r=math.random(3,14)/2
        if 1/p+1/q+1/r<1 then
            self.p=p
            self.q=q
            self.r=r
            return
        end
        tried=tried+1
    end
end

-- local testImage = love.graphics.newImage( "assets/test.png" )
-- testImage:setWrap("repeat", "repeat") -- set texture to repeat so that it can be used in shader
function MainMenuTesselation:draw()
    local ay=ShapeF.axisY
    ShapeF.axisY=-2
    local width=love.graphics.getLineWidth()
    love.graphics.setLineWidth(10)
    love.graphics.setShader(self.shader)
    local uvPoses=self.uvPoses
    local t=self.frame/551
    local x,y=400+50*math.sin(t),300+220*math.cos(t)
    local V0,V1,V2=ShapeF.schwarzTriangleVertices(self.p,self.q,self.r,{x,y},self.frame/131)
    -- local V0 = {400, 300}
    -- local V1 = {500, 300}
    -- local V2 = {400, 400}
    shader:send("V0", V0)
    shader:send("V1", V1)
    shader:send("V2", V2)
    shader:send("tex_uv_V0", uvPoses[1])
    shader:send("tex_uv_V1", uvPoses[2])
    shader:send("tex_uv_V2", uvPoses[3])
    shader:send("shape_axis_y", ShapeF.axisY)
    -- love.graphics.draw(testImage, 0,0)
    love.graphics.draw(Asset.backgroundImage, 0,0)
    love.graphics.setShader()
    -- love.graphics.circle("fill",V0[1],V0[2],25)
    -- love.graphics.circle("fill",V1[1],V1[2],25)
    -- love.graphics.circle("fill",V2[1],V2[2],25)
    love.graphics.setLineWidth(width)
    ShapeF.axisY=ay
end
BackgroundPattern.MainMenuTesselation=MainMenuTesselation

-- -- love2d draws a white rectangle then shader draws pattern.
-- local Shader=BackgroundPattern:extend()
-- ---@class ShaderBackground
-- ---@class love.Shader
-- ---@class ShaderBackgroundArgs
-- ---@field shader love.Shader the shader to use for drawing the background
-- ---@field paramSendFunction fun(self:ShaderBackground,shader:love.Shader):nil a function to send parameters to the shader, called in Shader:draw()

-- ---@param args ShaderBackgroundArgs
-- function Shader:new(args)
--     Shader.super.new(self,args)
--     args=args or {}
--     self.shader=args.shader
--     self.frame=0
--     self.paramSendFunction=args.paramSendFunction or function(self,shader) end
--     self.color={1,1,1}
--     self.lightColor={1,1,1}
--     self.darkColor={0.5,0.5,0.5}
--     self.autoDark=false -- if true, color will be lerped to darkColor when not G.preWin (enemy exists, during spellcard) (for very bright shaders)
-- end
-- function Shader:update(dt)
--     self.frame=self.frame+1
--     if self.autoDark then
--         local ratio=0.02
--         if G.preWin then
--             self.color={self.color[1]*(1-ratio)+self.lightColor[1]*ratio,self.color[2]*(1-ratio)+self.lightColor[2]*ratio,self.color[3]*(1-ratio)+self.lightColor[3]*ratio}
--         else
--             self.color={self.color[1]*(1-ratio)+self.darkColor[1]*ratio,self.color[2]*(1-ratio)+self.darkColor[2]*ratio,self.color[3]*(1-ratio)+self.darkColor[3]*ratio}
--         end
--     end
-- end
-- function Shader:draw()
--     local colorref={love.graphics.getColor()}
--     love.graphics.setColor(self.color[1],self.color[2],self.color[3])
--     -- love.graphics.rectangle('fill',0,0,800,600)
--     love.graphics.setShader(self.shader)
--     self:paramSendFunction(self.shader) -- send parameters to shader
--     local translateX,translateY,scale=G:followModeTransform(true)
--     love.graphics.rectangle('fill',-translateX/scale,-translateY/scale,800/scale,600/scale)
--     love.graphics.setShader()
--     love.graphics.setColor(colorref[1],colorref[2],colorref[3],colorref[4])
-- end

-- BackgroundPattern.Shader=Shader

-- local build_lorentz_mat4=require('import.H3math').build_lorentz_mat4
-- -- tessellation on H^2 is calculated similar to main menu tessellation: calculate schwarz triangle vertices and send this fundamental triangle to shader. after flip, flip count and barycenter coordinates are used to calculate color and height.
-- -- due to high computation cost, this could only fit ending / credits
-- local H3TerrainShader=ShaderScan:load_shader('shaders/backgrounds/H3Terrain2.glsl')
-- local H3Terrain=Shader:extend()
-- function H3Terrain:new()
--     H3Terrain.super.new(self)
--     self.autoDark=true
--     self.shader=H3TerrainShader
--     self.cam_translation={0,1.5,0.5}
--     self.cam_pitch=-0.9
--     self.cam_yaw=0
--     self.cam_roll=0
--     self.camMoveRange={0.3,0.0}
--     self.camMoveSpeed=0.2
--     self.p,self.q,self.r=3,6,6
--     local V0,V1,V2=ShapeF.schwarzTriangleVertices(self.p,self.q,self.r,{0,ShapeF.axisY+100-1},0)
--     local length01=ShapeF.distance(V0[1],V0[2],V1[1],V1[2])
--     local length02=ShapeF.distance(V0[1],V0[2],V2[1],V2[2])
--     local length12=ShapeF.distance(V1[1],V1[2],V2[1],V2[2])
--     self.tesseLoopLength=length01*2 -- based on pqr, the loop length has many possibilities. other possible values include (L01+L02+L12)*2, (L01+L02)*2
--     self.tesseDistance=0.01 -- distance of tessellation moved along the path. not camera
--     self.tesseMoveSpeed=0.3
--     local autoMove=false
--     self.paramSendFunction=function(self,shader)
--         local l=length01-self.tesseDistance
--         local x,y,dir=ShapeF.rThetaGoT(0,ShapeF.axisY+1,l,0)
--         -- dir=dir+(l>0 and math.pi or 0)
--         local V0,V1,V2=ShapeF.schwarzTriangleVertices(self.p,self.q,self.r,{x,y},dir)
--         local axisY=ShapeF.axisY
--         V0[2]=V0[2]-axisY
--         V1[2]=V1[2]-axisY
--         V2[2]=V2[2]-axisY
--         shader:send("V0", V0)
--         shader:send("V1", V1)
--         shader:send("V2", V2)
--         shader:send("time", self.frame/60*1.8)
--         local trans=self.cam_translation or {0,0,0}
--         if autoMove then
--             trans[3]=math.cos(self.frame/200)*-0.5+1.5
--         end
--         shader:send("cam_translation", trans)
--         local pitch=self.cam_pitch or 0
--         if autoMove then
--             pitch=math.cos(self.frame/200)*-0.3-0.3
--         end
--         shader:send("cam_pitch", pitch)
--         shader:send("cam_yaw", self.cam_yaw or 0)
--         local roll=self.cam_roll or 0
--         shader:send("cam_roll", roll)
--     end
-- end
-- H3Terrain.update=function(self,dt)
--     H3Terrain.super.update(self,dt)
--     local xRange,yRange=self.camMoveRange[1],self.camMoveRange[2]
--     if not self.camMoveCenter then
--         self.camMoveCenter={self.cam_translation[1],self.cam_translation[2]}
--     end
--     local xCenter,yCenter=self.camMoveCenter[1],self.camMoveCenter[2]
--     local xyStep=self.camMoveSpeed*dt
--     self.tesseDistance=(self.tesseDistance+self.tesseMoveSpeed/(1+self.cam_translation[1]^2))%(self.tesseLoopLength)
--     self.frame=self.frame+1
--     local keyIsDown=love.keyboard.isDown
--     if keyIsDown("n") then
--         self.cam_pitch = self.cam_pitch - dt
--     end
--     if keyIsDown("m") then
--         self.cam_pitch = self.cam_pitch + dt
--     end
--     if keyIsDown("h") then
--         self.cam_yaw = self.cam_yaw - dt
--     end
--     if keyIsDown("j") then
--         self.cam_yaw = self.cam_yaw + dt
--     end
--     if keyIsDown("y") then
--         self.cam_roll = self.cam_roll - dt
--     end
--     if keyIsDown("u") then
--         self.cam_roll = self.cam_roll + dt
--     end
--     if keyIsDown("i") then
--         self.cam_translation[3] = self.cam_translation[3] + dt
--     end
--     if keyIsDown("k") then
--         self.cam_translation[3] = self.cam_translation[3] - dt
--     end
--     if Player.objects[1] then
--         keyIsDown=Player.objects[1].keyIsDown -- nmhjyuik aren't recorded in player, so these keys use love.keyboard.isDown. arrow keys use player to restore in replay
--     end
--     if keyIsDown("right") then
--         self.cam_translation[1] = math.clamp(self.cam_translation[1] + xyStep,-xRange+xCenter,xRange+xCenter)
--     end
--     if keyIsDown("left") then
--         self.cam_translation[1] = math.clamp(self.cam_translation[1] - xyStep,-xRange+xCenter,xRange+xCenter)
--     end
--     if keyIsDown("up") then
--         self.cam_translation[2] = math.clamp(self.cam_translation[2] - xyStep,-yRange+yCenter,yRange+yCenter)
--     end
--     if keyIsDown("down") then
--         self.cam_translation[2] = math.clamp(self.cam_translation[2] + xyStep,-yRange+yCenter,yRange+yCenter)
--     end
-- end
-- BackgroundPattern.H3Terrain=H3Terrain


-- local honeycombShader=ShaderScan:load_shader('shaders/backgrounds/honeycomb.glsl')
-- local Honeycomb=H3Terrain:extend()
-- function Honeycomb:new(args)
--     Honeycomb.super.new(self,args)
--     self.shader=honeycombShader
--     self.inverse=args and args.inverse or false
--     if not self.inverse then
--         self.darkColor={0.3,0.3,0.3}
--     end
--     self.cam_translation={0.0001,0.4,0.3} -- when inverse, y=0.4 to avoid moving into ball at origin
--     self.cam_pitch=self.inverse and -math.pi/2 or 0
--     self.cam_yaw=-math.pi/2
--     self.camMoveRange={0.45,0.0}
--     self.autoMove=true
--     self.autoForwardSpeed=0.15
--     self.autoForwardWrap=1.06 -- currently should be distance from center to center of a side. 
--     self.autoForwardValue=self.cam_translation[3]
--     self.manualForwardOffset=0.0
--     self.manualForwardLimit=0.3
--     self.reflectCount=0
--     self.paramSendFunction=function(self,shader)
--         shader:send("time", self.frame/60)
--         local trans=self.cam_translation
--         local pitch,yaw,roll=self.cam_pitch,self.cam_yaw,self.cam_roll
--         local changed=self.inverse and {trans[3], trans[1], trans[2]} or {trans[3], trans[2], trans[1]} -- auto move component must be first. rest two order is to let fixed component moving away from ball at origin or edge
--         local mat4=build_lorentz_mat4(pitch, yaw, roll, changed)
--         shader:send("cam_mat4", mat4)
--         shader:send("inverse",self.inverse)
--         shader:send("SHELL_RATIO",self.inverse and 2 or 0.5)
--         shader:send("reflect_count",self.reflectCount)
--     end
-- end

-- function Honeycomb:update(dt)
--     Honeycomb.super.update(self,dt)
--     if not self.autoMove then
--         return
--     end
--     local wrap = self.autoForwardWrap
--     local manualOffset = math.clamp(self.cam_translation[3] - self.autoForwardValue, -self.manualForwardLimit, self.manualForwardLimit)
--     self.manualForwardOffset = manualOffset
--     self.autoForwardValue = self.autoForwardValue + (self.autoForwardSpeed or 0.0) * dt
--     local span = wrap * 2.0
--     if self.autoForwardValue > wrap then
--         self.autoForwardValue = self.autoForwardValue - span
--         self.reflectCount = self.reflectCount + 1
--     elseif self.autoForwardValue < -wrap then
--         self.autoForwardValue = self.autoForwardValue + span
--         self.reflectCount = self.reflectCount + 1
--     end
--     self.cam_translation[3] = self.autoForwardValue + self.manualForwardOffset
-- end

-- BackgroundPattern.Honeycomb=Honeycomb

return BackgroundPattern
