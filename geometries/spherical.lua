---@type GeometryBase
local GeometryBase = ...

---@class SphericalCircleConfig
---@field center ScreenPosition
---@field radius number

---@class SphericalViewConfig:ViewConfig
---@field sourceCutoffZ number overlap for drawing sprites whose centers are beyond the hemisphere rim.
---@field sourcePrimaryCenter ScreenPosition
---@field sourceSecondaryCenter ScreenPosition
---@field primaryCircle SphericalCircleConfig
---@field secondaryCircle SphericalCircleConfig
---@field rotateSpeed number

---@class Spherical
local Spherical = GeometryBase:extend()

Spherical.radius = 220
Spherical.EPS = 1e-8
local mainRadius = WINDOW_HEIGHT * 7/15
local miniRadius = WINDOW_HEIGHT * 0.16
Spherical.CANVAS_WIDTH = math.ceil(4 * (mainRadius + miniRadius))
Spherical.CANVAS_HEIGHT = WINDOW_HEIGHT
local CANVAS_WIDTH, CANVAS_HEIGHT = Spherical.CANVAS_WIDTH, Spherical.CANVAS_HEIGHT
Spherical.canvas=love.graphics.newCanvas(CANVAS_WIDTH, CANVAS_HEIGHT)
local CUTOFF_Z = math.sqrt(0.5) -- 45 deg latitude on a unit sphere.
---@type SphericalViewConfig
Spherical.viewConfig = {
    following = true,
    screenCenter = { x = WINDOW_HEIGHT / 2 - WINDOW_WIDTH / 40, y = WINDOW_HEIGHT / 2 },
    sourceCutoffZ = CUTOFF_Z,
    sourcePrimaryCenter = { x = mainRadius, y = CANVAS_HEIGHT / 2 },
    sourceSecondaryCenter = { x = CANVAS_WIDTH - miniRadius, y = CANVAS_HEIGHT / 2 },
    primaryCircle = {
        center = { x = WINDOW_HEIGHT / 2 - WINDOW_WIDTH / 40, y = WINDOW_HEIGHT / 2 },
        radius = mainRadius,
    },
    secondaryCircle = {
        center = { x = WINDOW_WIDTH * 0.8, y = WINDOW_HEIGHT * 0.8 },
        radius = miniRadius,
    },
    rotateSpeed=0,
}

-- Rows of the world-to-camera rotation. This default matches the old shader
-- with latitude, longitude, and view direction all zero (following disabled).
local camera = { 0, 1, 0, 0, 0, 1, 1, 0, 0 }

local function world_to_camera(x, y, z)
    return
        camera[1] * x + camera[2] * y + camera[3] * z,
        camera[4] * x + camera[5] * y + camera[6] * z,
        camera[7] * x + camera[8] * y + camera[9] * z
end

local function tangent_basis(ux, uy, uz)
    local eastX = -uy
    local eastY = ux
    local eastZ = 0
    local eastLen = math.sqrt(eastX * eastX + eastY * eastY + eastZ * eastZ)
    eastX = eastX / eastLen
    eastY = eastY / eastLen
    eastZ = eastZ / eastLen

    local northX = uy * eastZ - uz * eastY
    local northY = uz * eastX - ux * eastZ
    local northZ = ux * eastY - uy * eastX
    local northLen = math.sqrt(northX * northX + northY * northY + northZ * northZ)
    northX = northX / northLen
    northY = northY / northLen
    northZ = northZ / northLen

    return eastX, eastY, eastZ, northX, northY, northZ
end

function Spherical:enterPhase(phase)
    if phase ~= 'draw' then
        return
    end

    -- Called by G.draw before objects add their vertices to the batches.
    local fx, fy, fz, direction = 1, 0, 0, 0
    local viewer = G.runInfo.player
    if self.viewConfig.following and viewer then
        local pos = viewer.kinematicState.pos
        local invLen = 1 / math.sqrt(pos.x * pos.x + pos.y * pos.y + pos.z * pos.z)
        fx, fy, fz = pos.x * invLen, pos.y * invLen, pos.z * invLen
        direction = viewer.viewDirection
    end

    local ex, ey, ez, nx, ny, nz = tangent_basis(fx, fy, fz)
    local c, s = math.cos(direction), math.sin(direction)
    ex, ey, ez = ex * c + nx * s, ey * c + ny * s, ez * c + nz * s
    nx, ny, nz = fy * ez - fz * ey, fz * ex - fx * ez, fx * ey - fy * ex
    camera[1], camera[2], camera[3] = ex, ey, ez
    camera[4], camera[5], camera[6] = nx, ny, nz
    camera[7], camera[8], camera[9] = fx, fy, fz
end

local function direction_to_tangent(ux, uy, uz, direction)
    local eastX, eastY, eastZ, northX, northY, northZ = tangent_basis(ux, uy, uz)
    local dirCos = math.cos(direction)
    local dirSin = math.sin(direction)

    return
        eastX * dirCos + northX * dirSin,
        eastY * dirCos + northY * dirSin,
        eastZ * dirCos + northZ * dirSin
end

local function tangent_to_direction(ux, uy, uz, tangentX, tangentY, tangentZ)
    local eastX, eastY, eastZ, northX, northY, northZ = tangent_basis(ux, uy, uz)
    return math.atan2(
        tangentX * northX + tangentY * northY + tangentZ * northZ,
        tangentX * eastX + tangentY * eastY + tangentZ * eastZ
    )
end

local function rotate_position_and_direction(position, direction, angle)
    local posLen = math.sqrt(position.x * position.x + position.y * position.y + position.z * position.z)
    if posLen < Spherical.EPS then
        return position.x, position.y, position.z, direction
    end

    local ux = position.x / posLen
    local uy = position.y / posLen
    local uz = position.z / posLen
    local tangentX, tangentY, tangentZ = direction_to_tangent(ux, uy, uz, direction)

    local c = math.cos(angle)
    local s = math.sin(angle)
    local rotatedX = position.x * c - position.z * s
    local rotatedY = position.y
    local rotatedZ = position.x * s + position.z * c
    local rotatedTangentX = tangentX * c - tangentZ * s
    local rotatedTangentY = tangentY
    local rotatedTangentZ = tangentX * s + tangentZ * c

    local rotatedLen = math.sqrt(rotatedX * rotatedX + rotatedY * rotatedY + rotatedZ * rotatedZ)
    local rotatedDir = tangent_to_direction(
        rotatedX / rotatedLen,
        rotatedY / rotatedLen,
        rotatedZ / rotatedLen,
        rotatedTangentX,
        rotatedTangentY,
        rotatedTangentZ
    )

    return rotatedX, rotatedY, rotatedZ, rotatedDir
end

function Spherical:init()
    local len = math.sqrt(0.35 * 0.35 + 0.93 * 0.93)
    return { pos = { x = 0.35 / len * Spherical.radius, y = 0, z = 0.93 / len * Spherical.radius }, speed = 0, dir = 0 }
end

function Spherical:setZoomSpeed(value,duration)
    if duration==0 then
        self.viewConfig.rotateSpeed=value
        return
    end
    Event.EaseEvent{
        easeObj=self.viewConfig,aims={rotateSpeed=value},duration=duration
    }
end

function Spherical:update(state, dt)
    dt = dt or (1 / 60)
    local newPos, newDir = self:rThetaGo(state.pos, state.speed * dt, state.dir)
    for key,value in pairs(newPos) do
        state.pos[key] = value
    end
    state.dir = newDir
    if self.viewConfig.rotateSpeed~=0 and not state.skipZoom then
        local angle = self.viewConfig.rotateSpeed * dt *60
        state.pos.x, state.pos.y, state.pos.z, state.dir = rotate_position_and_direction(state.pos, state.dir, angle)
    end
end

function Spherical:rThetaGo(position, length, direction)
    if length == 0 then
        return { x = position.x, y = position.y, z = position.z }, direction
    end

    local backward = length < 0
    if backward then
        length = -length
        direction = direction + math.pi
    end

    -- Work on the unit sphere with scalar components to avoid hot-path vector tables.
    local posLen = math.sqrt(position.x * position.x + position.y * position.y + position.z * position.z)
    local ux = position.x / posLen
    local uy = position.y / posLen
    local uz = position.z / posLen

    -- Local tangent basis at the start point: east = z-axis cross u, north = u cross east.
    local eastX = -uy
    local eastY = ux
    local eastZ = 0
    local eastLen = math.sqrt(eastX * eastX + eastY * eastY + eastZ * eastZ)
    eastX = eastX / eastLen
    eastY = eastY / eastLen
    eastZ = eastZ / eastLen

    local northX = uy * eastZ - uz * eastY
    local northY = uz * eastX - ux * eastZ
    local northZ = ux * eastY - uy * eastX
    local northLen = math.sqrt(northX * northX + northY * northY + northZ * northZ)
    northX = northX / northLen
    northY = northY / northLen
    northZ = northZ / northLen

    local dirCos = math.cos(direction)
    local dirSin = math.sin(direction)
    local tangentX = eastX * dirCos + northX * dirSin
    local tangentY = eastY * dirCos + northY * dirSin
    local tangentZ = eastZ * dirCos + northZ * dirSin
    local tangentLen = math.sqrt(tangentX * tangentX + tangentY * tangentY + tangentZ * tangentZ)
    tangentX = tangentX / tangentLen
    tangentY = tangentY / tangentLen
    tangentZ = tangentZ / tangentLen

    -- Advance along the great circle by alpha radians.
    local alpha = length / Spherical.radius
    local alphaCos = math.cos(alpha)
    local alphaSin = math.sin(alpha)
    local newX = ux * alphaCos + tangentX * alphaSin
    local newY = uy * alphaCos + tangentY * alphaSin
    local newZ = uz * alphaCos + tangentZ * alphaSin
    local newLen = math.sqrt(newX * newX + newY * newY + newZ * newZ)
    newX = newX / newLen
    newY = newY / newLen
    newZ = newZ / newLen

    -- Parallel-transport the heading around the same great-circle rotation axis.
    local axisX = uy * tangentZ - uz * tangentY
    local axisY = uz * tangentX - ux * tangentZ
    local axisZ = ux * tangentY - uy * tangentX
    local axisLen = math.sqrt(axisX * axisX + axisY * axisY + axisZ * axisZ)
    axisX = axisX / axisLen
    axisY = axisY / axisLen
    axisZ = axisZ / axisLen

    local transportedX = axisY * newZ - axisZ * newY
    local transportedY = axisZ * newX - axisX * newZ
    local transportedZ = axisX * newY - axisY * newX
    local transportedLen = math.sqrt(transportedX * transportedX + transportedY * transportedY + transportedZ * transportedZ)
    transportedX = transportedX / transportedLen
    transportedY = transportedY / transportedLen
    transportedZ = transportedZ / transportedLen

    -- Express the transported tangent in the destination's east/north basis.
    local east2X = -newY
    local east2Y = newX
    local east2Z = 0
    local east2Len = math.sqrt(east2X * east2X + east2Y * east2Y + east2Z * east2Z)
    east2X = east2X / east2Len
    east2Y = east2Y / east2Len
    east2Z = east2Z / east2Len

    local north2X = newY * east2Z - newZ * east2Y
    local north2Y = newZ * east2X - newX * east2Z
    local north2Z = newX * east2Y - newY * east2X
    local north2Len = math.sqrt(north2X * north2X + north2Y * north2Y + north2Z * north2Z)
    north2X = north2X / north2Len
    north2Y = north2Y / north2Len
    north2Z = north2Z / north2Len

    local newDir = math.atan2(
        transportedX * north2X + transportedY * north2Y + transportedZ * north2Z,
        transportedX * east2X + transportedY * east2Y + transportedZ * east2Z
    )

    if backward then
        newDir = newDir + math.pi
    end

    return { x = newX * Spherical.radius, y = newY * Spherical.radius, z = newZ * Spherical.radius }, newDir
end

function Spherical:distance(position1, position2)
    local len1 = math.sqrt(position1.x * position1.x + position1.y * position1.y + position1.z * position1.z)
    local len2 = math.sqrt(position2.x * position2.x + position2.y * position2.y + position2.z * position2.z)
    local c = math.clamp(
        (position1.x / len1) * (position2.x / len2) +
        (position1.y / len1) * (position2.y / len2) +
        (position1.z / len1) * (position2.z / len2),
        -1,
        1
    )
    return Spherical.radius * math.acos(c)
end

function Spherical:to(position, target)
    local posLen = math.sqrt(position.x * position.x + position.y * position.y + position.z * position.z)
    local ux = position.x / posLen
    local uy = position.y / posLen
    local uz = position.z / posLen

    local targetLen = math.sqrt(target.x * target.x + target.y * target.y + target.z * target.z)
    local vx = target.x / targetLen
    local vy = target.y / targetLen
    local vz = target.z / targetLen

    -- Great-circle plane normal, then tangent direction at the current point.
    local normalX = uy * vz - uz * vy
    local normalY = uz * vx - ux * vz
    local normalZ = ux * vy - uy * vx
    local normalLen = math.sqrt(normalX * normalX + normalY * normalY + normalZ * normalZ)
    normalX = normalX / normalLen
    normalY = normalY / normalLen
    normalZ = normalZ / normalLen

    local tangentX = normalY * uz - normalZ * uy
    local tangentY = normalZ * ux - normalX * uz
    local tangentZ = normalX * uy - normalY * ux
    local tangentLen = math.sqrt(tangentX * tangentX + tangentY * tangentY + tangentZ * tangentZ)
    tangentX = tangentX / tangentLen
    tangentY = tangentY / tangentLen
    tangentZ = tangentZ / tangentLen

    -- Choose the tangent orientation that points toward the target.
    if tangentX * (vx - ux) + tangentY * (vy - uy) + tangentZ * (vz - uz) < 0 then
        tangentX = -tangentX
        tangentY = -tangentY
        tangentZ = -tangentZ
    end

    -- Convert the tangent vector back into a local heading angle.
    local eastX = -uy
    local eastY = ux
    local eastZ = 0
    local eastLen = math.sqrt(eastX * eastX + eastY * eastY + eastZ * eastZ)
    eastX = eastX / eastLen
    eastY = eastY / eastLen
    eastZ = eastZ / eastLen

    local northX = uy * eastZ - uz * eastY
    local northY = uz * eastX - ux * eastZ
    local northZ = ux * eastY - uy * eastX
    local northLen = math.sqrt(northX * northX + northY * northY + northZ * northZ)
    northX = northX / northLen
    northY = northY / northLen
    northZ = northZ / northLen

    return math.atan2(
        tangentX * northX + tangentY * northY + tangentZ * northZ,
        tangentX * eastX + tangentY * eastY + tangentZ * eastZ
    )
end

function Spherical:sideToLine(position, linePoint1, linePoint2)
    local posLen = math.sqrt(position.x * position.x + position.y * position.y + position.z * position.z)
    local ux = position.x / posLen
    local uy = position.y / posLen
    local uz = position.z / posLen

    local aLen = math.sqrt(linePoint1.x * linePoint1.x + linePoint1.y * linePoint1.y + linePoint1.z * linePoint1.z)
    local ax = linePoint1.x / aLen
    local ay = linePoint1.y / aLen
    local az = linePoint1.z / aLen

    local bLen = math.sqrt(linePoint2.x * linePoint2.x + linePoint2.y * linePoint2.y + linePoint2.z * linePoint2.z)
    local bx = linePoint2.x / bLen
    local by = linePoint2.y / bLen
    local bz = linePoint2.z / bLen

    -- Side is the sign of position dot the great-circle plane normal.
    local normalX = ay * bz - az * by
    local normalY = az * bx - ax * bz
    local normalZ = ax * by - ay * bx
    return ux * normalX + uy * normalY + uz * normalZ > 0
end

function Spherical:nearestToLine(position, linePoint1, linePoint2)
    local posLen = math.sqrt(position.x * position.x + position.y * position.y + position.z * position.z)
    local ux = position.x / posLen
    local uy = position.y / posLen
    local uz = position.z / posLen

    local aLen = math.sqrt(linePoint1.x * linePoint1.x + linePoint1.y * linePoint1.y + linePoint1.z * linePoint1.z)
    local ax = linePoint1.x / aLen
    local ay = linePoint1.y / aLen
    local az = linePoint1.z / aLen

    local bLen = math.sqrt(linePoint2.x * linePoint2.x + linePoint2.y * linePoint2.y + linePoint2.z * linePoint2.z)
    local bx = linePoint2.x / bLen
    local by = linePoint2.y / bLen
    local bz = linePoint2.z / bLen

    -- The normal vector to the plane containing the Great Circle
    local normalX = ay * bz - az * by
    local normalY = az * bx - ax * bz
    local normalZ = ax * by - ay * bx
    local len = math.sqrt(normalX * normalX + normalY * normalY + normalZ * normalZ)

    -- If linePoint1 and linePoint2 are the same or antipodal, the line is undefined.
    if len < Spherical.EPS then
        return { x = linePoint1.x, y = linePoint1.y, z = linePoint1.z }
    end
    normalX = normalX / len
    normalY = normalY / len
    normalZ = normalZ / len

    -- Project the point u onto the plane: proj = u - (u dot normal) * normal.
    local distToPlane = ux * normalX + uy * normalY + uz * normalZ
    local projX = ux - normalX * distToPlane
    local projY = uy - normalY * distToPlane
    local projZ = uz - normalZ * distToPlane

    -- If the point is exactly at the "pole" of the great circle, 
    -- all points on the circle are equidistant. Return a default.
    local projLen = math.sqrt(projX * projX + projY * projY + projZ * projZ)
    if projLen < Spherical.EPS then
        return { x = linePoint1.x, y = linePoint1.y, z = linePoint1.z }
    end

    -- Normalize the projection to move it to the sphere's surface and scale to radius
    return {
        x = projX / projLen * Spherical.radius,
        y = projY / projLen * Spherical.radius,
        z = projZ / projLen * Spherical.radius,
    }
end

function Spherical:toScreen(position)
    local posLen = math.sqrt(position.x * position.x + position.y * position.y + position.z * position.z)
    local ux = position.x / posLen
    local uy = position.y / posLen
    local uz = position.z / posLen
    -- Rotate world east along with the center to preserve the sprite's heading.
    -- Its length does not matter when finding the projected angle.
    local tx, ty, tz = -uy, ux, 0
    tx, ty, tz = world_to_camera(tx, ty, tz)
    ux, uy, uz = world_to_camera(ux, uy, uz)
    ---@type (Dummy|ScreenPosition)[]
    local ret = { GeometryBase.Dummy, GeometryBase.Dummy }
    local sourceCutoff = Spherical.viewConfig.sourceCutoffZ

    -- Main circle: forward hemisphere, projected from the camera's south pole.
    -- The hemisphere rim has exactly the foreground circle's pixel radius.
    if uz >= -sourceCutoff then
        local denom = 1 + uz
        local px, py = ux / denom, uy / denom
        local radius = Spherical.viewConfig.primaryCircle.radius
        local center = Spherical.viewConfig.sourcePrimaryCenter
        ret[1] = {
            x = center.x + px * radius,
            y = center.y + py * radius,
            rotation = math.atan2(ty - py * tz, tx - px * tz),
        }
    end

    -- Mini circle: opposite hemisphere, projected from the camera's north pole.
    if uz <= sourceCutoff then
        local denom = 1 - uz
        local px, py = ux / denom, uy / denom
        local radius = Spherical.viewConfig.secondaryCircle.radius
        local center = Spherical.viewConfig.sourceSecondaryCenter
        ret[2] = {
            x = center.x + px * radius,
            y = center.y + py * radius,
            -- Shape.drawQuad negates both rotation and X scale for a flip.
            rotation = math.pi - math.atan2(ty + py * tz, tx + px * tz),
            flip = true,
        }
    end

    return ret
end

function Spherical:canSimpleDraw(position, radius)
    local ratio = radius / Spherical.radius
    if ratio < 0.2 then
        return true, 6
    end
    local sides = math.clamp(math.ceil(ratio * GeometryBase.MESH_MAX_SIDES/3), 6, GeometryBase.MESH_MAX_SIDES)
    return false, sides
end

function Spherical:applyVertexShader()
    -- do nothing. the geometry base performs a flat translation that is not needed
end

Spherical.sphericalShader = ShaderScan:load_shader("shaders/sphericalDual.glsl")

Spherical.hasPixelShader = true

function Spherical:applyPixelShader(viewer)
    local shader = Spherical.sphericalShader
    love.graphics.setShader(shader)

    shader:send("source_primary_center", {
        Spherical.viewConfig.sourcePrimaryCenter.x,
        Spherical.viewConfig.sourcePrimaryCenter.y,
    })
    shader:send("source_secondary_center", {
        Spherical.viewConfig.sourceSecondaryCenter.x,
        Spherical.viewConfig.sourceSecondaryCenter.y,
    })

    shader:send("main_center", {
        Spherical.viewConfig.primaryCircle.center.x,
        Spherical.viewConfig.primaryCircle.center.y,
    })
    shader:send("main_radius", Spherical.viewConfig.primaryCircle.radius)
    shader:send("mini_center", {
        Spherical.viewConfig.secondaryCircle.center.x,
        Spherical.viewConfig.secondaryCircle.center.y,
    })
    shader:send("mini_radius", Spherical.viewConfig.secondaryCircle.radius)
    shader:send("canvas_size",{CANVAS_WIDTH,CANVAS_HEIGHT})
end

function Spherical:applyForegroundShader()
    G.CONSTANTS.USE_FOREGROUND_SHADER("TWO_CIRCLES", { centerXY = { Spherical.viewConfig.primaryCircle.center.x, Spherical.viewConfig.primaryCircle.center.y }, radius = Spherical.viewConfig.primaryCircle.radius, centerXY2 = { Spherical.viewConfig.secondaryCircle.center.x, Spherical.viewConfig.secondaryCircle.center.y }, radius2 = Spherical.viewConfig.secondaryCircle.radius })
end

function Spherical:zoomFactorToScreen(position)
    local posLen = math.sqrt(position.x * position.x + position.y * position.y + position.z * position.z)
    local uz = (camera[7] * position.x + camera[8] * position.y + camera[9] * position.z) / posLen
    local factors = { 0, 0 }
    local sourceCutoff = Spherical.viewConfig.sourceCutoffZ

    if uz >= -sourceCutoff then
        factors[1] = Spherical.viewConfig.primaryCircle.radius / (Spherical.radius * (1 + uz))
    end

    if uz <= sourceCutoff then
        factors[2] = Spherical.viewConfig.secondaryCircle.radius / (Spherical.radius * (1 - uz))
    end

    return factors
end

return Spherical
