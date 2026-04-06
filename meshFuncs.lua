local MeshFuncs={}

---@param poses Position[]
---@param width number
---@param quad love.Quad "quad of sprite"
---@param color number[]|nil
---@param gap number|nil the gap of interpolated points between two positions
---@param maxMiddlePoints number|nil the max number of interpolated points between two positions, to prevent too many points when the distance is long
---@param meshBatch MeshBatch adds the generated meshes to this batch
---@return nil
function MeshFuncs.polylineMesh(poses,width,quad,color,gap,maxMiddlePoints,meshBatch)
    local x,y,w,h=quad:getViewport()
    local imgW,imgH=meshBatch.image:getDimensions()
    x,y,w,h=x/imgW,y/imgH,w/imgW,h/imgH
    color=color or {1,1,1,1}
    gap=gap or 10
    maxMiddlePoints=maxMiddlePoints or 30
    local vertices={}
    for i=1,#poses-1 do
        local pos1,pos2=poses[i],poses[i+1]
        local distance=G.runInfo.geometry:distance(pos1,pos2)
        local direction=G.runInfo.geometry:to(pos1,pos2)
        local middleNum=math.min(math.ceil(distance/gap),maxMiddlePoints)
        for j=0,middleNum do
            local middleDistance=j/middleNum*distance
            local middlePos,middleDir=G.runInfo.geometry:rThetaGo(pos1,middleDistance,direction)
            local side1Pos=G.runInfo.geometry:rThetaGo(middlePos,width/2,middleDir+math.pi/2)
            local side1ScreenPoses=G.runInfo.geometry:toScreen(side1Pos)
            for k,side1ScreenPos in ipairs(side1ScreenPoses) do
                if not side1ScreenPos.dummy then
                    if not vertices[k] then
                        vertices[k]={}
                    end
                    ---@cast side1ScreenPos ScreenPosition
                    table.insert(vertices[k],{side1ScreenPos.x,side1ScreenPos.y,x,y,color[1],color[2],color[3],color[4]})
                end
            end
            local side2Pos=G.runInfo.geometry:rThetaGo(middlePos,width/2,middleDir-math.pi/2)
            local side2ScreenPoses=G.runInfo.geometry:toScreen(side2Pos)
            for k,side2ScreenPos in ipairs(side2ScreenPoses) do
                if not side2ScreenPos.dummy then
                    if not vertices[k] then
                        vertices[k]={}
                    end
                    ---@cast side2ScreenPos ScreenPosition
                    table.insert(vertices[k],{side2ScreenPos.x,side2ScreenPos.y,x+w,y+h,color[1],color[2],color[3],color[4]})
                end
            end
        end
    end
    for si,v in pairs(vertices) do
        if v and #v>=3 then
            meshBatch:add(v,'strip')
        end
    end
end


-- calculate fan mesh for drawing large sprite to reduce distortion
---@param position Position position of the center of the sprite in geometry space
---@param posR number "radius of object"
---@param quad love.Quad "quad of sprite"
---@param n integer "number of vertices on the circle"
---@param color number[]|nil "color RGBA, each in [0,1]"
---@param square boolean|nil "if true, vertices are calculated on a square instead of a circle (for square sprites)"
---@param meshBatch MeshBatch adds the generated meshes to this batch
function MeshFuncs.fanMesh(position,posR,orientation,quad,n,color,square,meshBatch)
    color=color or {1,1,1,1}
    local x,y,w,h=quad:getViewport() -- like 100, 100, 50, 50 so needs to divide width and height
    local imgW,imgH=meshBatch.image:getDimensions()
    x,y,w,h=x/imgW,y/imgH,w/imgW,h/imgH
    local vertices={} -- multiple possible meshes
    local coreScreenPoses=G.runInfo.geometry:toScreen(position)
    for si,coreScreenPos in ipairs(coreScreenPoses) do
        if not coreScreenPos.dummy then -- if center is dummy, this fan mesh cannot be formed
            ---@cast coreScreenPos ScreenPosition
            vertices[si]={{coreScreenPos.x,coreScreenPos.y,x+w/2,y+h/2,color[1],color[2],color[3],color[4]}}
        end
    end
    for i=0,n do
        local angle=math.pi*2/n*i
        local rRatio=1
        if square then
            rRatio=1/math.cos((angle+math.pi/4)%(math.pi/2)-math.pi/4)
        end
        local poses=G.runInfo.geometry:toScreen(G.runInfo.geometry:rThetaGo(position,posR*rRatio,angle+orientation))
        for si,screenPos in ipairs(poses) do
            if not screenPos.dummy then
                ---@cast screenPos ScreenPosition
                local x2,y2=screenPos.x,screenPos.y
                local u,v=(math.cos(angle)*rRatio+1)/2,(math.sin(angle)*rRatio+1)/2
                if vertices[si] then
                    table.insert(vertices[si], {x2,y2,x+u*w,y+v*h,color[1],color[2],color[3],color[4]})
                end
            end
        end
    end
    for si,v in pairs(vertices) do
        if v and #v>=3 then
            meshBatch:add(v,'fan')
        end
    end
end


-- calculate double layered ring+fan mesh for drawing large sprite to reduce distortion. generally, innerR is hitbox radius and outerR is sprite radius, to ensure that hitbox size and overall size are all accurate.
---@param position Position position of the center of the sprite in geometry space
---@param innerR number "inner radius of ring"
---@param outerR number "outer radius of ring"
---@param orientation angle "orientation of object"
---@param quad love.Quad "quad of sprite"
---@param n integer "number of vertices on the circle"
---@param color number[]|nil "color RGBA, each in [0,1]"
---@param meshBatch MeshBatch adds the generated meshes to this batch
function MeshFuncs.ringFanMesh(position,innerR,outerR,orientation,quad,n,color,meshBatch)
    color = color or {1, 1, 1, 1}
    local x, y, w, h = quad:getViewport()
    local imgW, imgH = meshBatch.image:getDimensions()
    x, y, w, h = x/imgW, y/imgH, w/imgW, h/imgH
    
    local ratio = innerR / outerR
    local ringVertices = {} -- Table of vertex arrays for 'strip' meshes
    local fanVertices = {}  -- Table of vertex arrays for 'fan' meshes
    
    -- 1. Get Screen positions for the center (for the Fan meshes)
    local coreScreenPoses = G.runInfo.geometry:toScreen(position)
    for si, coreScreenPos in ipairs(coreScreenPoses) do
        if not coreScreenPos.dummy then
            fanVertices[si] = {
                {coreScreenPos.x, coreScreenPos.y, x + w/2, y + h/2, color[1], color[2], color[3], color[4]}
            }
            ringVertices[si] = {}
        end
    end

    -- 2. Calculate vertices for the circles
    for i = 0, n do
        local angle = math.pi * 2 / n * i
        local cosA, sinA = math.cos(angle), math.sin(angle)
        
        -- Geometric positions
        local posOuter = G.runInfo.geometry:rThetaGo(position, outerR, angle + orientation)
        local posInner = G.runInfo.geometry:rThetaGo(position, innerR, angle + orientation)
        
        -- Screen positions
        local outerScreens = G.runInfo.geometry:toScreen(posOuter)
        local innerScreens = G.runInfo.geometry:toScreen(posInner)
        
        -- UV coordinates
        -- Outer: radius 1.0 (relative to outerR)
        local uO, vO = (cosA + 1) / 2, (sinA + 1) / 2
        -- Inner: radius = ratio
        local uI, vI = (cosA * ratio + 1) / 2, (sinA * ratio + 1) / 2

        for si = 1, #coreScreenPoses do
            if fanVertices[si] then -- only process if this screen instance is valid
                local pO = outerScreens[si]
                local pI = innerScreens[si]
                
                if pO and not pO.dummy and pI and not pI.dummy then
                    ---@cast pO ScreenPosition
                    ---@cast pI ScreenPosition
                    
                    -- Add to Ring (Strip) - Order: Outer, Inner, Outer, Inner...
                    table.insert(ringVertices[si], {pO.x, pO.y, x + uO*w, y + vO*h, color[1], color[2], color[3], color[4]})
                    table.insert(ringVertices[si], {pI.x, pI.y, x + uI*w, y + vI*h, color[1], color[2], color[3], color[4]})
                    
                    -- Add to Fan - Extends from center to Inner Radius
                    table.insert(fanVertices[si], {pI.x, pI.y, x + uI*w, y + vI*h, color[1], color[2], color[3], color[4]})
                end
            end
        end
    end

    -- 3. Add Mesh objects

    for si, v in pairs(ringVertices) do
        if #v >= 4 then -- Minimum 2 pairs for a strip
            meshBatch:add(v, 'strip')
        end
    end

    for si, v in pairs(fanVertices) do
        if #v >= 3 then -- Center + 2 points for a fan
            meshBatch:add(v, 'fan')
        end
    end
end

return MeshFuncs