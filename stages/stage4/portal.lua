---@class Portal:GameObject
---@field pos1 Position
---@field pos2 Position
---@field size number distance between pos1 and pos2
---@field side boolean
---@field sign 1|-1 whether pos1 to posIn is larger or smaller than pos1 to pos2. for convenience.
---@field linked Portal
---@overload fun(pos1:Position,pos2:Position,posInOrSign:Position|1|-1):Portal
Portal=GameObject:extend()

Portal.range=20
Portal.MAX_SEGMENTS=16
Portal.shader=ShaderScan:load_shader('shaders/effects/euclideanPortal.glsl')
Portal.canvas=love.graphics.newCanvas(WINDOW_WIDTH,WINDOW_HEIGHT)

---Enable the Euclidean portal post-process on a geometry instance. This is
---done when the first portal is constructed so stage setup does not have to
---own any rendering details.
---@param geo PortalGeometryBase
function Portal.enableShader(geo)
    geo.hasPixelShader=true
    geo.canvas=Portal.canvas
    geo.pixelShaderCanvasClearColor={0,0,0,0}
    geo.applyPixelShader=Portal.applyPixelShader
end

---@param pos1 Position
---@param pos2 Position
---@param posInOrSign Position|1|-1
function Portal:new(pos1,pos2,posInOrSign)
    self:set(pos1,pos2,posInOrSign)
    Portal.enableShader(G.runInfo.geometry)
end

---@param pos1 Position|nil
---@param pos2 Position|nil
---@param posInOrSign Position|1|-1|nil
function Portal:set(pos1,pos2,posInOrSign)
    pos1=pos1 or self.pos1
    pos2=pos2 or self.pos2
    self.pos1=pos1
    self.pos2=pos2
    local geo=G.runInfo.geometry
    ---@cast geo PortalGeometryBase
    self.size=geo:distanceRef(pos1,pos2)
    if not posInOrSign then
        return
    end
    if type(posInOrSign)=='number' then
        self.sign=posInOrSign
        local posIn=geo:rThetaGoRef(pos1,30,geo:toRef(pos1,pos2)+self.sign*math.pi/2)
        self.side=geo:sideToLine(posIn,pos1,pos2)
    else
        local posIn=posInOrSign
        self.side=geo:sideToLine(posIn,pos1,pos2)
        local sign=math.sign(math.modClamp(geo:toRef(pos1,posIn)-geo:toRef(pos1,pos2)))
        if sign==0 then
            error("posIn is on the line of pos1 and pos2, cannot determine which side it is on.")
        end
        ---@cast sign 1|-1
        self.sign=sign
    end
end

function Portal:link(otherPortal)
    self.linked=otherPortal
    otherPortal.linked=self
end

--- teleportation of all portals. if the object is at pos, where will it land (after possible teleportation) and what's the delta angle (or delta viewDirection for player). since it's decided that every portal has range of back side that must be empty to make exceeding sprite work, so does not need to know previous pos. if the object is near the back side, consider it just crossed the portal.
---@param pos Position
---@return Position newPos
---@return number deltaAngle
function Portal.considerTeleport(pos)
    local deltaAngle=0
    local geo=G.runInfo.geometry
    ---@cast geo PortalGeometryBase
    local teleported=true
    while teleported do
        teleported=false
        for i,portal in ipairs(Portal.objects) do
            ---@cast portal Portal
            if geo:sideToLine(pos,portal.pos1,portal.pos2)~=portal.side then
                local distance, onSegment=geo:distanceToLine(pos,portal.pos1,portal.pos2)
                if distance<Portal.range and onSegment then
                    teleported=true
                    local nearest=geo:nearestToLine(pos,portal.pos1,portal.pos2)
                    local r=geo:distanceRef(nearest,pos)
                    local size=portal.size
                    local ratio=geo:distanceRef(portal.pos1,nearest)/size
                    local linkedPortal=portal.linked
                    local linkedSize=linkedPortal.size
                    local linkedBasePoint,linkedDir=geo:rThetaGoRef(linkedPortal.pos1,linkedSize*ratio,geo:toRef(linkedPortal.pos1,linkedPortal.pos2))
                    linkedDir=linkedDir+linkedPortal.sign*math.pi/2
                    r=r/size*linkedSize
                    local newPos,newDir=geo:rThetaGoRef(linkedBasePoint,r,linkedDir)
                    deltaAngle=deltaAngle+(newDir-geo:toRef(pos,nearest)-math.pi)
                    pos=newPos
                    break
                end
            end
        end
    end
    return pos,deltaAngle
end

---@return number smoothZoomFactor
function Portal.zoomFactor(pos)
    local geo=G.runInfo.geometry
    ---@cast geo PortalGeometryBase
    -- calculate zoom factor. Π(F^-sigmoid(-distance/C))
    local C=50
    local smoothZoomFactor=1
    for i,portal in ipairs(Portal.objects) do
        ---@cast portal Portal
        local distance=geo:distanceToSegment(pos,portal.pos1,portal.pos2)
        local size=portal.size
        local linkedPortal=portal.linked
        local linkedSize=linkedPortal.size
        local F=linkedSize/size
        smoothZoomFactor=smoothZoomFactor*F^(-math.smoothstep(0.5-0.5*distance/C))
    end
    return smoothZoomFactor
end

function Portal:draw()
    local size=self.size
    MeshFuncs.polylineMesh({self.pos1,self.pos2},size/20,BulletSprites.laser.black.quad,{1,1,1,1},nil,10,Asset.bigBulletMeshes)
end

local function positionToShaderScreen(position,viewer,geo,zoom)
    local viewPosition=viewer.kinematicState.pos
    local dx=position.x-viewPosition.x
    local dy=position.y-viewPosition.y
    local angle=-viewer.viewDirection
    local cosine=math.cos(angle)
    local sine=math.sin(angle)
    local center=geo.viewConfig.screenCenter
    return {
        center.x+(dx*cosine-dy*sine)*zoom,
        center.y+(dx*sine+dy*cosine)*zoom,
    }
end

---Send portal segments after applying the same camera transform used by the
---stage's geo.applyVertexShader. The pixel shader can therefore work entirely
---in screen coordinates.
---@param geo PortalGeometryBase
---@param viewer Viewer
function Portal.applyPixelShader(geo,viewer)
    local shader=Portal.shader
    love.graphics.setShader(shader)

    local portals=Portal.objects
    ---@cast portals Portal[]
    local numSegments=math.min(#portals,Portal.MAX_SEGMENTS)
    local center=geo.viewConfig.screenCenter
    local zoom=1/Portal.zoomFactor(viewer.kinematicState.pos)

    shader:send('screenCenter',{center.x,center.y})
    shader:send('numSegments',numSegments)
    shader:send('range',Portal.range*zoom)

    if numSegments==0 then
        return
    end

    local indexes={}
    for i=1,numSegments do
        indexes[portals[i]]=i
    end

    local pos1s,pos2s,signs,linkeds={},{},{},{}
    for i=1,numSegments do
        local portal=portals[i]
        pos1s[i]=positionToShaderScreen(portal.pos1,viewer,geo,zoom)
        pos2s[i]=positionToShaderScreen(portal.pos2,viewer,geo,zoom)
        signs[i]=portal.sign
        linkeds[i]=indexes[portal.linked] or i
    end

    shader:send('pos1s',unpack(pos1s))
    shader:send('pos2s',unpack(pos2s))
    shader:send('signs',unpack(signs))
    shader:send('linkeds',unpack(linkeds))
end
