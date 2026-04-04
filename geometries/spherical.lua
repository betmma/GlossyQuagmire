---@type GeometryBase
local GeometryBase = ...

---@class SphericalCircleConfig
---@field center ScreenPosition
---@field radius number

---@class SphericalViewConfig:ViewConfig
---@field sourceCircleRadius number projection radius used by toScreen, independent from final display circles.
---@field sourceCutoffZ number cutoff for toScreen/source projection generation.
---@field shaderCutoffZ number cutoff passed to shader for final keep/remap. 0 means each circle contains a hemisphere. larger value means more overlap.
---@field sourcePrimaryCenter ScreenPosition
---@field sourceSecondaryCenter ScreenPosition
---@field primaryCircle SphericalCircleConfig
---@field secondaryCircle SphericalCircleConfig

---@class Spherical
local Spherical = GeometryBase:extend()

Spherical.radius = 220
Spherical.EPS = 1e-8
local CUTOFF_Z = math.sqrt(0.5) -- 45 deg latitude on a unit sphere.

---@type SphericalViewConfig
Spherical.viewConfig = {
    following = true,
    screenCenter = { x = WINDOW_HEIGHT / 2 - WINDOW_WIDTH / 40, y = WINDOW_HEIGHT / 2 },
    sourceCircleRadius = WINDOW_WIDTH * 0.16,
    sourceCutoffZ = CUTOFF_Z,
    shaderCutoffZ = 0,
    sourcePrimaryCenter = { x = WINDOW_WIDTH * 0.33, y = WINDOW_HEIGHT * 0.50 },
    sourceSecondaryCenter = { x = WINDOW_WIDTH * 0.67, y = WINDOW_HEIGHT * 0.50 },
    primaryCircle = {
        center = { x = WINDOW_HEIGHT / 2 - WINDOW_WIDTH / 40, y = WINDOW_HEIGHT / 2 },
        radius = WINDOW_HEIGHT * 7/15,
    },
    secondaryCircle = {
        center = { x = WINDOW_WIDTH * 0.8, y = WINDOW_HEIGHT * 0.8 },
        radius = WINDOW_HEIGHT * 0.16,
    },
}

local function clamp(value, low, high)
    if value < low then
        return low
    end
    if value > high then
        return high
    end
    return value
end

local function vec3(x, y, z)
    return { x = x, y = y, z = z }
end

local function dot(a, b)
    return a.x * b.x + a.y * b.y + a.z * b.z
end

local function cross(a, b)
    return {
        x = a.y * b.z - a.z * b.y,
        y = a.z * b.x - a.x * b.z,
        z = a.x * b.y - a.y * b.x,
    }
end

local function length3(v)
    return math.sqrt(dot(v, v))
end

local function normalize(v)
    local m = length3(v)
    if m < Spherical.EPS then
        return vec3(0, 0, 1)
    end
    return vec3(v.x / m, v.y / m, v.z / m)
end

local function scale(v, s)
    return vec3(v.x * s, v.y * s, v.z * s)
end

local function add(a, b)
    return vec3(a.x + b.x, a.y + b.y, a.z + b.z)
end

local function sub(a, b)
    return vec3(a.x - b.x, a.y - b.y, a.z - b.z)
end

local function copy_pos(p)
    return { x = p.x, y = p.y, z = p.z }
end

local function basis_at(unitPos)
    local northAxis = vec3(0, 0, 1)
    local east = cross(northAxis, unitPos)
    if length3(east) < Spherical.EPS then
        east = cross(vec3(0, 1, 0), unitPos)
    end
    east = normalize(east)
    local north = normalize(cross(unitPos, east))
    return east, north
end

local function to_unit(pos)
    return normalize(vec3(pos.x, pos.y, pos.z))
end

local function from_unit(unitPos)
    return scale(unitPos, Spherical.radius)
end

local function projection_limit_radius(c)
    return (2 * Spherical.radius * math.sqrt(1 - c * c)) / (1 - c)
end

local function source_projection_limit_radius()
    local c = clamp(Spherical.viewConfig.sourceCutoffZ, 0, 0.999999)
    return projection_limit_radius(c)
end

local function source_hemisphere_radius_pixels()
    local sourceLimit = source_projection_limit_radius()
    local hemisphereLimit = projection_limit_radius(0)
    return Spherical.viewConfig.sourceCircleRadius * hemisphereLimit / sourceLimit
end

local function project_from_north(unitPos)
    local denom = 1 - unitPos.z
    if denom < Spherical.EPS then
        return nil
    end
    local k = (2 * Spherical.radius) / denom
    return { x = k * unitPos.x, y = k * unitPos.y }
end

local function project_from_south(unitPos)
    local denom = 1 + unitPos.z
    if denom < Spherical.EPS then
        return nil
    end
    local k = (2 * Spherical.radius) / denom
    return { x = k * unitPos.x, y = k * unitPos.y }
end

local function map_to_source_circle(proj, center)
    local limitR = source_projection_limit_radius()
    local normalizedX = proj.x / limitR
    local normalizedY = proj.y / limitR
    return {
        x = center.x + normalizedX * Spherical.viewConfig.sourceCircleRadius,
        y = center.y + normalizedY * Spherical.viewConfig.sourceCircleRadius,
    }
end

function Spherical:init()
    local start = normalize(vec3(0.35, 0.0, 0.93))
    local p = from_unit(start)
    return { pos = { x = p.x, y = p.y, z = p.z }, speed = 0, dir = 0 }
end

function Spherical:update(state, dt)
    dt = dt or (1 / 60)
    local newPos, newDir = self:rThetaGo(state.pos, state.speed * dt, state.dir)
    for key,value in pairs(newPos) do
        state.pos[key] = value
    end
    state.dir = newDir
end

function Spherical:rThetaGo(position, length, direction)
    if length == 0 then
        return copy_pos(position), direction
    end

    local backward = length < 0
    if backward then
        length = -length
        direction = direction + math.pi
    end

    local u = to_unit(position)
    local east, north = basis_at(u)
    local tangent = normalize(add(scale(east, math.cos(direction)), scale(north, math.sin(direction))))

    local alpha = length / Spherical.radius
    local newUnit = normalize(add(scale(u, math.cos(alpha)), scale(tangent, math.sin(alpha))))

    local axis = normalize(cross(u, tangent))
    local transportedTangent = normalize(cross(axis, newUnit))

    local east2, north2 = basis_at(newUnit)
    local newDir = math.atan2(dot(transportedTangent, north2), dot(transportedTangent, east2))

    if backward then
        newDir = newDir + math.pi
    end

    local p = from_unit(newUnit)
    return { x = p.x, y = p.y, z = p.z }, newDir
end

function Spherical:distance(position1, position2)
    local u = to_unit(position1)
    local v = to_unit(position2)
    local c = clamp(dot(u, v), -1, 1)
    return Spherical.radius * math.acos(c)
end

function Spherical:to(position, target)
    local u = to_unit(position)
    local v = to_unit(target)

    local normal = cross(u, v)
    if length3(normal) < Spherical.EPS then
        return 0
    end
    normal = normalize(normal)

    local tangent = normalize(cross(normal, u))
    if dot(tangent, sub(v, u)) < 0 then
        tangent = scale(tangent, -1)
    end

    local east, north = basis_at(u)
    return math.atan2(dot(tangent, north), dot(tangent, east))
end

function Spherical:sideToLine(position, linePoint1, linePoint2)
    local u = to_unit(position)
    local a = to_unit(linePoint1)
    local b = to_unit(linePoint2)
    local normal = cross(a, b)
    if length3(normal) < Spherical.EPS then
        return false
    end
    return dot(u, normal) > 0
end

function Spherical:toScreen(position)
    local u = to_unit(position)
    ---@type (Dummy|ScreenPosition)[]
    local ret = { GeometryBase.Dummy, GeometryBase.Dummy }
    local sourceCutoff = clamp(Spherical.viewConfig.sourceCutoffZ, 0, 0.999999)

    -- Primary map: project from viewer (north pole), cover 45N to 90S.
    if u.z <= sourceCutoff then
        local p = project_from_north(u)
        if p then
            ret[1] = map_to_source_circle(p, Spherical.viewConfig.sourcePrimaryCenter)
            ret[1].rotation = -math.atan2(p.y,p.x)+math.pi/2
            ret[1].flip = true
        end
    end

    -- Secondary map: project from south pole, cover 90N to 45S.
    if u.z >= -sourceCutoff then
        local p = project_from_south(u)
        if p then
            ret[2] = map_to_source_circle(p, Spherical.viewConfig.sourceSecondaryCenter)
            ret[2].rotation = math.atan2(p.y,p.x)+math.pi/2
        end
    end

    return ret
end

function Spherical:canSimpleDraw(position, radius)
    local ratio = radius / Spherical.radius
    if ratio < 0.08 then
        return true, 8
    end
    local sides = math.clamp(math.ceil(ratio * GeometryBase.MESH_MAX_SIDES), 8, GeometryBase.MESH_MAX_SIDES)
    return false, sides
end

Spherical.sphericalShader = ShaderScan:load_shader("shaders/sphericalDual.glsl")

function Spherical:applyVertexShader(viewer)
    local shader = Spherical.sphericalShader

    shove.clearEffects('main')
    shove.addEffect('main',shader)
    -- love.graphics.setShader(shader)

    shader:send("source_primary_center", {
        Spherical.viewConfig.sourcePrimaryCenter.x,
        Spherical.viewConfig.sourcePrimaryCenter.y,
    })
    shader:send("source_secondary_center", {
        Spherical.viewConfig.sourceSecondaryCenter.x,
        Spherical.viewConfig.sourceSecondaryCenter.y,
    })
    shader:send("source_hemisphere_radius", source_hemisphere_radius_pixels())

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
    shader:send("cutoff_z", clamp(Spherical.viewConfig.shaderCutoffZ, 0, 0.999999))

    local viewerLat, viewerLon = 0.0, 0.0

    if Spherical.viewConfig.following then
        local u = to_unit(viewer.kinematicState.pos)
        viewerLat = math.asin(clamp(u.z, -1, 1))
        viewerLon = math.atan2(u.y, u.x)
    end
    shader:send("viewer_lat_lon", { viewerLat, viewerLon })
end

function Spherical:applyForegroundShader()
    G.CONSTANTS.USE_FOREGROUND_SHADER("TWO_CIRCLES", { centerXY = { Spherical.viewConfig.primaryCircle.center.x, Spherical.viewConfig.primaryCircle.center.y }, radius = Spherical.viewConfig.primaryCircle.radius, centerXY2 = { Spherical.viewConfig.secondaryCircle.center.x, Spherical.viewConfig.secondaryCircle.center.y }, radius2 = Spherical.viewConfig.secondaryCircle.radius })
end

function Spherical:zoomFactorToScreen(position)
    local u = to_unit(position)
    local factors = { 0, 0 }
    local sourceCutoff = Spherical.viewConfig.sourceCutoffZ
    local sourceLimitR = source_projection_limit_radius()

    if u.z <= sourceCutoff then
        local denom = 1 - u.z
        local stereoScale = (2 * Spherical.radius) / denom
        factors[1] = (stereoScale / Spherical.radius) * (Spherical.viewConfig.sourceCircleRadius / sourceLimitR)
    end

    if u.z >= -sourceCutoff then
        local denom = 1 + u.z
        local stereoScale = (2 * Spherical.radius) / denom
        factors[2] = (stereoScale / Spherical.radius) * (Spherical.viewConfig.sourceCircleRadius / sourceLimitR)
    end

    return factors
end

return Spherical
