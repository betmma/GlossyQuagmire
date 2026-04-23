local MeshFuncs={}

local MeshHelper = {}

-- 1. Extract UV and Color setup
function MeshHelper.getUVsAndColor(quad, meshBatch, color)
    color = color or {1, 1, 1, 1}
    local x, y, w, h = quad:getViewport()
    local imgW, imgH = meshBatch.image:getDimensions()
    return x/imgW, y/imgH, w/imgW, h/imgH, color
end

-- 2. Vertex Accumulator Class
-- This handles the complex logic of multi-screen instances (`si`), 
-- breaking meshes on dummy points, and flushing to the batch.
local Accumulator = {}
Accumulator.__index = Accumulator

function MeshHelper.newAccumulator(meshBatch, mode)
    local self = setmetatable({}, Accumulator)
    self.batch = meshBatch
    self.mode = mode
    self.vertices = {}
    self.prefixes = {} -- Used to store the center point of 'fan' meshes
    return self
end

-- Sets a base vertex that should be at the start of every new mesh for this `si`
-- (Highly useful for 'fan' mode where the center point must always be vertex #1)
function Accumulator:setPrefix(si, vertex)
    self.prefixes[si] = vertex
    self.vertices[si] = {vertex}
end

-- Adds one or more vertices to the specific screen instance mesh
function Accumulator:add(si, ...)
    if not self.vertices[si] then self.vertices[si] = {} end
    local verts = {...}
    for _, v in ipairs(verts) do
        table.insert(self.vertices[si], v)
    end
end

-- Breaks the current mesh (used when hitting a dummy point)
function Accumulator:breakMesh(si)
    local verts = self.vertices[si]
    if verts and #verts >= 3 then
        self.batch:add(verts, self.mode)
    end
    -- Reset the table. If there's a prefix (like a fan center), keep it!
    self.vertices[si] = self.prefixes[si] and {self.prefixes[si]} or {}
end

-- Final flush at the end of the function
function Accumulator:flushAll()
    for si, verts in pairs(self.vertices) do
        if verts and #verts >= 3 then
            self.batch:add(verts, self.mode)
        end
    end
end

---@param poses Position[]
---@param width number
---@param quad love.Quad "quad of sprite"
---@param color number[]|nil
---@param gap number|nil the gap of interpolated points between two positions
---@param maxMiddlePoints number|nil the max number of interpolated points between two positions, to prevent too many points when the distance is long
---@param meshBatch MeshBatch adds the generated meshes to this batch
---@return nil
function MeshFuncs.polylineMesh(poses,width,quad,color,gap,maxMiddlePoints,meshBatch)
    local x, y, w, h, c = MeshHelper.getUVsAndColor(quad, meshBatch, color)
    gap = gap or 10
    maxMiddlePoints = maxMiddlePoints or 30
    local acc = MeshHelper.newAccumulator(meshBatch, 'strip')

    for i = 1, #poses - 1 do
        local pos1, pos2 = poses[i], poses[i+1]
        local distance = G.runInfo.geometry:distance(pos1, pos2)
        local direction = G.runInfo.geometry:to(pos1, pos2)
        local middleNum = math.min(math.ceil(distance / gap), maxMiddlePoints)
        for j = 0, middleNum do
            local middleDistance = j / middleNum * distance
            local middlePos, middleDir = G.runInfo.geometry:rThetaGo(pos1, middleDistance, direction)
            local side1Pos = G.runInfo.geometry:rThetaGo(middlePos, width/2, middleDir + math.pi/2)
            local side1ScreenPoses = G.runInfo.geometry:toScreen(side1Pos)
            local side2Pos = G.runInfo.geometry:rThetaGo(middlePos, width/2, middleDir - math.pi/2)
            local side2ScreenPoses = G.runInfo.geometry:toScreen(side2Pos)
            for si = 1, #side1ScreenPoses do
                local p1, p2 = side1ScreenPoses[si], side2ScreenPoses[si]
                if not p1.dummy and not p2.dummy then
                    acc:add(si,
                        {p1.x, p1.y, x, y, c[1], c[2], c[3], c[4]},
                        {p2.x, p2.y, x+w, y+h, c[1], c[2], c[3], c[4]}
                    )
                else
                    acc:breakMesh(si)
                end
            end
        end
    end
    acc:flushAll()
end


-- calculate fan mesh for drawing large sprite to reduce distortion. note that, since sprite is always in euclidean geometry, there is still distortion. this function ensures the rim of circle (or oval, square, rectangle) is accurate to preserve the shape, but the inner part is still distorted. this is achieved by calculating the polar position of vertices in euclidean geometry, then use geometry:rThetaGo to find the actual position in current geometry.
---@param position Position position of the center of the sprite in geometry space
---@param objW number "width of object"
---@param objH number height of object
---@param quad love.Quad "quad of sprite"
---@param n integer "number of vertices on the circle"
---@param color number[]|nil "color RGBA, each in [0,1]"
---@param square boolean|nil "if true, vertices are calculated on a square instead of a circle (for square sprites)"
---@param meshBatch MeshBatch adds the generated meshes to this batch
function MeshFuncs.fanMesh(position,objW,objH,orientation,quad,n,color,square,meshBatch)
    local x, y, w, h, c = MeshHelper.getUVsAndColor(quad, meshBatch, color)
    local acc = MeshHelper.newAccumulator(meshBatch, 'fan')
    -- Setup Center point (Prefix)
    local coreScreenPoses = G.runInfo.geometry:toScreen(position)
    for si, corePos in ipairs(coreScreenPoses) do
        if not corePos.dummy then
            acc:setPrefix(si, {corePos.x, corePos.y, x+w/2, y+h/2, c[1], c[2], c[3], c[4]})
        end
    end

    for i = 0, n do
        local angle = math.pi * 2 / n * i
        local rRatio = square and (1 / math.cos((angle + math.pi/4) % (math.pi/2) - math.pi/4)) or 1
        -- 1. Calculate the local X and Y relative to the center before rotation
        -- We apply rRatio here so that if 'square' is true, it becomes a rectangle
        local localX = (objW / 2) * math.cos(angle) * rRatio
        local localY = (objH / 2) * math.sin(angle) * rRatio
        
        -- 2. Calculate the distance (radius) from center to this specific point
        local dist = math.sqrt(localX^2 + localY^2)
        
        -- 3. Calculate the actual angle of this point relative to the local center
        local angleOffset = math.atan2(localY, localX)
        
        -- 4. Use rThetaGo with the calculated distance and the combined angle
        local poses = G.runInfo.geometry:toScreen(G.runInfo.geometry:rThetaGo(position, dist, angleOffset + orientation))
        for si, screenPos in ipairs(poses) do
            if not screenPos.dummy then
                local u, v = (math.cos(angle)*rRatio + 1)/2, (math.sin(angle)*rRatio + 1)/2
                acc:add(si, {screenPos.x, screenPos.y, x + u*w, y + v*h, c[1], c[2], c[3], c[4]})
            else
                acc:breakMesh(si)
            end
        end
    end
    acc:flushAll()
end

-- this function isn't for large circle sprite, but for ring shape. The difference is, the texture is stretched and loops around the ring, instead of the ring part in a circle sprite like in ringFanMesh. 
---@param position Position position of the center of the sprite in geometry space
---@param innerR number "inner radius of ring"
---@param outerR number "outer radius of ring"
---@param orientation angle "orientation of object"
---@param quad love.Quad "quad of sprite"
---@param n integer "number of vertices on the circle"
---@param color number[]|nil "color RGBA, each in [0,1]"
---@param loopNum integer|nil "number of times the texture loops around the ring, default 1"
---@param meshBatch MeshBatch adds the generated meshes to this batch
function MeshFuncs.ringMesh(position,innerR,outerR,orientation,quad,n,color,loopNum,meshBatch)
    local x, y, w, h, c = MeshHelper.getUVsAndColor(quad, meshBatch, color)
    local acc = MeshHelper.newAccumulator(meshBatch, 'strip')
    loopNum = loopNum or 2
    local oneLoopVertices = math.floor(n / loopNum)
    n = n - n % loopNum -- make sure it's multiple of loopNum, or can't loop properly
    for i = 0, n do
        local angle = math.pi * 2 / n * i
        local loopRatio = math.abs(i % (oneLoopVertices*2) / oneLoopVertices-1)*0.8 -- triangle wave. boss hexagram uses laserDark.red, if max loopRatio=1 this causes strange fade at the loop point. it looks like the sprite below is leaking but it should not happen. snake.red doesn't leak when max is 1.
        -- Geometric positions
        local posOuter = G.runInfo.geometry:rThetaGo(position, outerR, angle + orientation)
        local posInner = G.runInfo.geometry:rThetaGo(position, innerR, angle + orientation)
        -- Screen positions
        local outerScreens = G.runInfo.geometry:toScreen(posOuter)
        local innerScreens = G.runInfo.geometry:toScreen(posInner)
        for si = 1, #outerScreens do
            local pO = outerScreens[si]
            local pI = innerScreens[si]
            if not pO.dummy and not pI.dummy then
                ---@cast pO ScreenPosition
                ---@cast pI ScreenPosition
                acc:add(si,
                    {pO.x, pO.y, x, y + h * loopRatio, c[1], c[2], c[3], c[4]},
                    {pI.x, pI.y, x + w, y + h * loopRatio, c[1], c[2], c[3], c[4]}
                )
            else
                acc:breakMesh(si)
            end
        end
    end

    acc:flushAll()
end

-- calculate double layered ring+fan mesh for drawing large sprite to reduce distortion. generally, innerR is hitbox radius and outer W and H are sprite size, to ensure that hitbox size and overall size are all accurate.
---@param position Position position of the center of the sprite in geometry space
---@param innerR number "inner radius of ring (hitbox circle)"
---@param outerWidth number "outer width of ring (sprite width)"
---@param outerHeight number "outer height of ring (sprite height)"
---@param orientation angle "orientation of object"
---@param quad love.Quad "quad of sprite"
---@param n integer "number of vertices on the circle"
---@param color number[]|nil "color RGBA, each in [0,1]"
---@param meshBatch MeshBatch adds the generated meshes to this batch
function MeshFuncs.ringFanMesh(position,innerR,outerWidth,outerHeight,orientation,quad,n,color,meshBatch)
    local x, y, w, h, c = MeshHelper.getUVsAndColor(quad, meshBatch, color)
    
    local ringAcc = MeshHelper.newAccumulator(meshBatch, 'strip')
    local fanAcc = MeshHelper.newAccumulator(meshBatch, 'fan')
    local coreScreenPoses = G.runInfo.geometry:toScreen(position)
    
    -- Half dimensions for ellipse calculations
    local hw, hh = outerWidth / 2, outerHeight / 2

    for si, corePos in ipairs(coreScreenPoses) do
        if not corePos.dummy then
            fanAcc:setPrefix(si, {corePos.x, corePos.y, x+w/2, y+h/2, c[1], c[2], c[3], c[4]})
        end
    end

    for i = 0, n do
        local angle = math.pi * 2 / n * i
        local cosA, sinA = math.cos(angle), math.sin(angle)

        -- 1. Calculate Outer Position (Ellipse)
        local localOuterX = hw * cosA
        local localOuterY = hh * sinA
        local distOuter = math.sqrt(localOuterX^2 + localOuterY^2)
        local angleOuter = math.atan2(localOuterY, localOuterX)
        
        local posOuter = G.runInfo.geometry:rThetaGo(position, distOuter, angleOuter + orientation)
        local outerScreens = G.runInfo.geometry:toScreen(posOuter)

        -- 2. Calculate Inner Position (Perfect Circle)
        local posInner = G.runInfo.geometry:rThetaGo(position, innerR, angle + orientation)
        local innerScreens = G.runInfo.geometry:toScreen(posInner)

        -- 3. UV Mapping
        -- Outer UVs are simple normalized cos/sin
        local uO, vO = (cosA + 1)/2, (sinA + 1)/2
        -- Inner UVs must be scaled based on how innerR relates to the outer dimensions
        local uI, vI = ( (innerR * cosA) / hw + 1 ) / 2, ( (innerR * sinA) / hh + 1 ) / 2

        for si = 1, #coreScreenPoses do
            local pO, pI = outerScreens[si], innerScreens[si]
            if not pO.dummy and not pI.dummy then
                ringAcc:add(si, 
                    {pO.x, pO.y, x + uO*w, y + vO*h, c[1], c[2], c[3], c[4]},
                    {pI.x, pI.y, x + uI*w, y + vI*h, c[1], c[2], c[3], c[4]}
                )
                fanAcc:add(si, {pI.x, pI.y, x + uI*w, y + vI*h, c[1], c[2], c[3], c[4]})
            else
                ringAcc:breakMesh(si)
                fanAcc:breakMesh(si)
            end
        end
    end
    ringAcc:flushAll()
    fanAcc:flushAll()
end

return MeshFuncs