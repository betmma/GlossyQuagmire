-- a crude spherical grid background pattern for spherical geometry.

local BackgroundPattern=...

local Geometries=require('geometries.geometryBase')
local SphericalShape=Geometries.Spherical

local sphericalGridShader=ShaderScan:load_shader('shaders/backgrounds/sphericalGrid.glsl')
local SphericalGrid=BackgroundPattern.Shader:extend()

local function normalize3(x,y,z)
    local len=math.sqrt(x*x+y*y+z*z)
    if len<1e-9 then
        return {1,0,0}
    end
    return {x/len,y/len,z/len}
end

local function cross3(a,b)
    return {
        a[2]*b[3]-a[3]*b[2],
        a[3]*b[1]-a[1]*b[3],
        a[1]*b[2]-a[2]*b[1],
    }
end

local function sphericalBasisFromInit()
    local init=SphericalShape:init()
    local pos=init.pos
    local pole=normalize3(pos.x,pos.y,pos.z)
    local east=normalize3(-pole[2],pole[1],0)
    local northCross=cross3(pole,east)
    local north=normalize3(northCross[1],northCross[2],northCross[3])
    local dir=init.dir-math.pi/2
    local c,s=math.cos(dir),math.sin(dir)
    local prime=normalize3(
        east[1]*c+north[1]*s,
        east[2]*c+north[2]*s,
        east[3]*c+north[3]*s
    )
    local splitCross=cross3(pole,prime)
    local split=normalize3(splitCross[1],splitCross[2],splitCross[3])
    local equatorPole=split
    local equatorPrime=prime
    local equatorSplitCross=cross3(equatorPole,equatorPrime)
    local equatorSplit=normalize3(equatorSplitCross[1],equatorSplitCross[2],equatorSplitCross[3])
    return equatorPole,equatorPrime,equatorSplit
end

local function sphericalSourceHemisphereRadius()
    local viewConfig=SphericalShape.viewConfig
    local c=math.clamp(viewConfig.sourceCutoffZ or 0,0,0.999999)
    local sourceLimit=(2*SphericalShape.radius*math.sqrt(1-c*c))/(1-c)
    return viewConfig.sourceCircleRadius*(2*SphericalShape.radius)/sourceLimit
end

local function installSphericalGridCanvasHook()
    if not Asset or not Asset.bossEffectMeshes or not Asset.batchExtraActions then
        return false
    end
    local actions=Asset.batchExtraActions[Asset.bossEffectMeshes]
    if not actions then
        return false
    end
    if actions.sphericalGridHookInstalled then
        return true
    end
    local before=actions.before
    actions.before=function()
        if before then
            before()
        end
        local pattern=G.backgroundPattern
        if pattern and pattern.drawInSphericalCanvas and not pattern.removed then
            pattern:drawInSphericalCanvas()
        end
    end
    actions.sphericalGridHookInstalled=true
    return true
end

local function sphericalViewerState()
    local kinematicState=G.runInfo.player and G.runInfo.player.kinematicState or SphericalShape:init()
    local pos=kinematicState.pos
    local posDir=normalize3(pos.x,pos.y,pos.z)
    return posDir,kinematicState.dir or 0
end

local function rotateEquatorBasis(prime,split,angle)
    local c,s=math.cos(angle),math.sin(angle)
    return normalize3(
        prime[1]*c+split[1]*s,
        prime[2]*c+split[2]*s,
        prime[3]*c+split[3]*s
    ),normalize3(
        split[1]*c-prime[1]*s,
        split[2]*c-prime[2]*s,
        split[3]*c-prime[3]*s
    )
end

function SphericalGrid:new(args)
    args=args or {}
    args.shader=sphericalGridShader
    SphericalGrid.super.new(self,args)
    self.autoDark=false
    self.poleDir,self.primeDir,self.splitDir=sphericalBasisFromInit()
    self.rotation=0
    self.paramSendFunction=function(self,shader)
        local viewConfig=SphericalShape.viewConfig
        local viewerPos,viewerDir=sphericalViewerState()
        local primeDir,splitDir=rotateEquatorBasis(self.primeDir,self.splitDir,self.rotation)
        shader:send("source_primary_center",{viewConfig.sourcePrimaryCenter.x,viewConfig.sourcePrimaryCenter.y})
        shader:send("source_secondary_center",{viewConfig.sourceSecondaryCenter.x,viewConfig.sourceSecondaryCenter.y})
        shader:send("source_hemisphere_radius",sphericalSourceHemisphereRadius())
        shader:send("viewer_pos",viewerPos)
        shader:send("viewer_dir",viewerDir)
        shader:send("pole_dir",self.poleDir)
        shader:send("prime_dir",primeDir)
        shader:send("split_dir",splitDir)
    end
end

function SphericalGrid:update(dt)
    SphericalGrid.super.update(self,dt)
    self.rotation=(self.rotation-(SphericalShape.viewConfig.rotateSpeed or 0)*(dt or 1/60)*60)%(math.pi*2)
end

function SphericalGrid:drawInSphericalCanvas()
    local colorref={love.graphics.getColor()}
    love.graphics.setColor(self.color[1],self.color[2],self.color[3])
    love.graphics.setShader(self.shader)
    self:paramSendFunction(self.shader)
    love.graphics.rectangle('fill',0,0,CANVAS_WIDTH,CANVAS_HEIGHT)
    love.graphics.setShader()
    love.graphics.setColor(colorref[1],colorref[2],colorref[3],colorref[4])
end

function SphericalGrid:draw()
    if G.runInfo.geometry==SphericalShape and installSphericalGridCanvasHook() then
        return
    end
    self:drawInSphericalCanvas()
end

return SphericalGrid
