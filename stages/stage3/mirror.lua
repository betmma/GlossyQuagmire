---@class Mirror:GameObject
---@field pos1 Position
---@field pos2 Position
---@field posIn Position
---@field args MirrorExtraArgs
---@field extraUpdate ExtraUpdate
---@field frame number
---@field lifeFrame number
---@field spriteTransparency number
---@overload fun(pos1:Position,pos2:Position,posIn:Position,args:MirrorExtraArgs):Mirror
Mirror=GameObject:extend()

---@class MirrorExtraArgs:strict
---@field lifeFrame number after which the mirror will be removed, default 1000
---@field extraUpdate ExtraUpdate|nil

function Mirror:new(pos1,pos2,posIn,args)
    self.pos1=pos1
    self.pos2=pos2
    self.posIn=posIn
    self.args=args
    
    self.extraUpdate=args.extraUpdate or {}
    if type(self.extraUpdate)=='function' then
        self.extraUpdate={self.extraUpdate--[[@as function]]}
    end
    self.frame=0 -- managing frame and lifeFrame is Shape's duplicate, but I dont want to split Shape into two classes for Mirror which is for a specific stage. Mirror cannot inherit Shape cuz it don't have a sprite.
    self.lifeFrame=args.lifeFrame or 1000
    self.spriteTransparency=args.spriteTransparency or 1
    Action.init(self, self.extraUpdate)
end

function Mirror:update(dt)
    self.frame=self.frame+1
    if self.frame>self.lifeFrame then
        self:remove()
    end
    Action.executeExtraUpdate(self,self.extraUpdate,dt)
end

function Mirror:draw()
    MeshFuncs.polylineMesh({self.pos1,self.pos2},9,BulletSprites.laser.black.quad,{1,1,1,self.spriteTransparency},nil,10,Asset.bigBulletMeshes)
end

function Mirror:inside(pos)
    local geo=G.runInfo.geometry
    return geo:sideToLine(pos,self.pos1,self.pos2)==geo:sideToLine(self.posIn,self.pos1,self.pos2)
end

---@class reflection
---@field pos Position
---@field deltaDir number calculate new dir by deltaDir+oldDir*(rotateReverse and -1 or 1)
---@field rotateReverse boolean
---@field reflectionCount integer
---@field color rgbColor

---@return reflection[]
function Mirror.getReflections(pos,maxNum)
    local mirrors=Mirror.objects
    ---@cast mirrors Mirror[]
    local geo=G.runInfo.geometry
    for i,mirror in ipairs(mirrors) do
        if not mirror:inside(pos) then
           return {}
        end
    end
    local ret={}
    ---@type {[1]:reflection,[2]:(Mirror|nil)}[]
    local queue={{{pos=pos,deltaDir=0,rotateReverse=false,color={1,1,1},reflectionCount=0},nil}}
    local current=1
    while #queue>=current and #ret<maxNum do
        local currentRef,currentMirror=queue[current][1],queue[current][2]
        current=current+1
        for i,mirror in ipairs(mirrors) do
            if mirror~=currentMirror and mirror:inside(currentRef.pos) then
                local reflectedPos, deltaDir=geo:reflect(currentRef.pos,mirror.pos1,mirror.pos2)
                if reflectedPos then
                    local reflection={pos=reflectedPos,deltaDir=deltaDir-currentRef.deltaDir,rotateReverse=not currentRef.rotateReverse,reflectionCount=currentRef.reflectionCount+1,color={math.hsvToRgb((Mirror.hsv[1]+(currentRef.reflectionCount+1)*Mirror.dh)%1,Mirror.hsv[2],Mirror.hsv[3])},}
                    table.insert(ret,reflection)
                    table.insert(queue,{reflection,mirror})
                end
            end
        end
    end
    return ret
end

local shaders={
    Euclidean=ShaderScan:load_shader('shaders/effects/euclideanMirror.glsl'),
}

local geo2Shader=function()
    if G.runInfo.geometry==G.geometries.Euclidean then
        return shaders.Euclidean
    end
end

Mirror.hsv={0,0,1}
Mirror.dh=0.3

Mirror.mainEffect={
    name='Mirror',
}

function Mirror.mainEffect:active()
    if #Mirror.objects>0  then
        local shader=geo2Shader()
        if shader then 
            self.shader=shader
            return true
        end
    end
    return false
end

function Mirror.mainEffect:sendArgs()
    local mirrors=Mirror.objects
    local numMirrors=#mirrors
    self.shader:send('numMirrors',numMirrors)
    local pos1s,pos2s,posIns={}, {}, {}
    local transparency=1
    for i,mirror in ipairs(mirrors) do
        ---@cast mirror Mirror
        pos1s[i]={mirror.pos1.x,mirror.pos1.y}
        pos2s[i]={mirror.pos2.x,mirror.pos2.y}
        posIns[i]={mirror.posIn.x,mirror.posIn.y}
        transparency=math.min(transparency,mirror.spriteTransparency)
    end
    self.shader:send('pos1s',unpack(pos1s))
    self.shader:send('pos2s',unpack(pos2s))
    self.shader:send('posIns',unpack(posIns))
    self.shader:send('transparency',transparency)
    self.shader:send('hsv',Mirror.hsv)
    self.shader:send('dh',Mirror.dh)
end

function Mirror.setHSV(hsv,dh)
    Mirror.hsv=hsv
    Mirror.dh=dh
end