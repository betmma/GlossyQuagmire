--- random functions that are commonly used in stage scripts but not basic enough to be in GeometryBase (as has no value to implement a special version for subclasses) and not general enough to be in misc.lua.

DanmakuFuncs={}

---move [shape] to [targetPos] in [duration] frames, with optional [progressFunc] to control the easing and [updateDir] to update the shape's direction to align with the movement. this movement is hard as it sets position and dir (if updateDir) directly each frame.
---@param shape Shape
---@param targetPos Position
---@param duration integer
---@param progressFunc nil|fun(x:number):number
---@param updateDir boolean|nil whether to update kinematicState.dir to align with geometry
function DanmakuFuncs.moveToInTime(shape, targetPos, duration, progressFunc, updateDir)
    Event{obj=shape, action=function()
        local startPos=copyTable(shape.kinematicState.pos)
        local shapeDir=shape.kinematicState.dir
        local startDir=G.runInfo.geometry:to(startPos,targetPos)
        local distance=G.runInfo.geometry:distance(startPos,targetPos)
        for i=1,duration do
            local progress=(progressFunc and progressFunc(i/duration) or i/duration)
            local newPos,newDir=G.runInfo.geometry:rThetaGo(startPos,distance*progress,startDir)
            shape.kinematicState.pos=newPos
            if updateDir then
                shape.kinematicState.dir=newDir-startDir+shapeDir
            end
            wait()
        end
    end}
end

---@class rThetaRet
---@field r number
---@field theta number
---@field absolute boolean|nil whether the theta is absolute or relative to centerObj's direction. default false (relative)
---@field extraTheta number|nil an extra value to be added to shape.kinematicState.dir
---@field ref boolean|nil whether to use rThetaGoRef or rThetaGo. default false (use rThetaGo)

---add an extraUpdate function to [shape] to make it orbit around [centerObj] with radius and angle determined by [rtheta]. it will not set position if centerObj is removed.
---@param shape Shape
---@param centerObj Shape
---@param rtheta rThetaRet|fun(self:Shape, centerObj:Shape): rThetaRet
---@param onCenterRemoved fun(self:Shape)|nil a function to be called when the centerObj is removed. can choose to remove the shape or do something else. if nil does nothing
---@param zoomInProgressFunc nil|fun(x:integer):number a multiplier to the radius. function input is frame
function DanmakuFuncs.orbitBind(shape, centerObj, rtheta, onCenterRemoved, zoomInProgressFunc)
---@diagnostic disable-next-line: inject-field
    shape.centerObj=centerObj
    local rthetaRef=rtheta
    rtheta=type(rtheta)=="function" and rtheta or function ()
        return rthetaRef
    end
    shape.extraUpdate[#shape.extraUpdate+1] = function(self, dt)
        if centerObj.removed then
            if not self.calledOnCenterRemoved then
                if onCenterRemoved then
                    onCenterRemoved(self)
                end
                self.calledOnCenterRemoved=true
            end
            return
        end
        local rthetanew=rtheta(self, centerObj)
        local r=rthetanew.r
        if zoomInProgressFunc then
            r=r*zoomInProgressFunc(self.frame)
        end
        local centerPos=centerObj.kinematicState.pos
        local geo=G.runInfo.geometry
        local func=geo.rThetaGo
        if rthetanew.ref then
            ---@cast geo PortalGeometryBase
            func=geo.rThetaGoRef
        end
        self.kinematicState.pos,self.kinematicState.dir=func(geo,centerPos,r,rthetanew.theta+(rthetanew.absolute and 0 or centerObj.kinematicState.dir))
        if rthetanew.extraTheta then
            self.kinematicState.dir=self.kinematicState.dir+rthetanew.extraTheta
        end
    end
end

---create a sentry bullet (invisible, invincible, safe) at pos that is used to check if current boss phase ends (the end shockwave removes this bullet)
---@param pos Position
---@return Bullet
function DanmakuFuncs.sentry(pos)
    local sentry=Bullet{kinematicState={pos=copyTable(pos),speed=0,dir=0},sprite=BulletSprites.round.red,lifeFrame=99999,invincible=true,safe=true,spriteTransparency=0}
    sentry.removeEffect=function()end
    return sentry
end

---@param pos1 Position
---@param pos2 Position
---@param maxDist? number
---@param maxNum? integer
---@return Position[], number[]
function DanmakuFuncs.midPoints(pos1,pos2,maxDist,maxNum)
    maxNum=maxNum or 100
    maxDist=maxDist or 1
    local geo=G.runInfo.geometry
    local dist=geo:distance(pos1,pos2)
    local dir=geo:to(pos1,pos2)
    local num=math.min(maxNum,math.ceil(dist/maxDist))
    local points={}
    local dirs={}
    for i=0,num do
        local progress=i/(num)
        local pos,dirnew=geo:rThetaGo(pos1,dist*progress,dir)
        table.insert(points,pos)
        table.insert(dirs,dirnew)
    end
    return points,dirs
end

---@class PortalSentry:Bullet
---@field any {portal:Portal, length:number, width:number, ratio:number} ratio stores the ratio of the portal length to halfLength, for zoom in animation.

---return a sentry with a portal and possible back bullets bind to it
---@param pos Position initial pos
---@param dir number
---@param length number half length of the portal
---@param width number half width of the portal. consider this shape: [|
---@param reverse boolean whether to flip portal vertices. false maps to sign=1, true maps to sign=-1. though, posIn is always at the direction of dir.
---@param zoomInTime integer|nil
---@param portalArgs PortalArgs|nil will auto set range and add an extraUpdate that removes the portal when sentry is removed
---@param backBulletArgs BulletArgs|nil invincible defaults to true.
---@param backBulletGap number|nil the gap between back bullets. default 10
---@return PortalSentry
function DanmakuFuncs.PortalOnSentry(pos,dir,length,width,reverse,zoomInTime,portalArgs,backBulletArgs,backBulletGap)
    portalArgs=copyTable(portalArgs)
    local geo=G.runInfo.geometry--[[@as PortalGeometryBase]]
    if not geo.portal then
        error("calling DanmakuFuncs.PortalOnSentry but current geometry is not portal")
    end
    local sentry=DanmakuFuncs.sentry(pos)
    sentry.kinematicState.skipPortal=true
    sentry.kinematicState.dir=dir
    sentry.any={length=length,width=width,ratio=0.1}
    if zoomInTime then
        Event.EaseEvent{obj=sentry,easeObj=sentry.any,aims={ratio=1},duration=zoomInTime}
        if portalArgs and portalArgs.lifeFrame then
            Event{obj=sentry,action=function()
                wait(portalArgs.lifeFrame-zoomInTime)
                Event.EaseEvent{obj=sentry,easeObj=sentry.any,aims={ratio=0.1},duration=zoomInTime}
            end}
        end
    else
        sentry.any.ratio=1
    end
    local function getPos()
        local posnow,dirnow=sentry.kinematicState.pos,sentry.kinematicState.dir
        local width=sentry.any.width
        local pos2,dir2=geo:rThetaGoRef(posnow,width,dirnow)
        local length=sentry.any.length*sentry.any.ratio
        local posa,posb=Portal.segment(pos2,dir2,length)
        if reverse then
            posa,posb=posb,posa
        end
        return posa,posb
    end
    local posa,posb=getPos()
    portalArgs=portalArgs or {}
    portalArgs.range=portalArgs.range or width
    portalArgs.extraUpdate=portalArgs.extraUpdate or {}
    portalArgs.extraUpdate[#portalArgs.extraUpdate+1]=function(self)
        if sentry.removed then
            self:remove()
        else
            local posa,posb=getPos()
            self:set(posa,posb)
        end
    end
    local portal=Portal(posa,posb,reverse and -1 or 1,portalArgs)
    portal.any={sentry=sentry}
    sentry.any.portal=portal
    if backBulletArgs then
        if not backBulletArgs.invincible then
            backBulletArgs.invincible=true
        end
        local gap=backBulletGap or 10
        local lengthN=math.ceil(length/gap)
        for j=-lengthN,lengthN do
            local bullet=Bullet(copyTable(backBulletArgs))
            DanmakuFuncs.orbitBind(bullet,sentry,function (self, centerObj)
                local x=-sentry.any.width
                local y=j/lengthN*sentry.any.length*sentry.any.ratio
                return {r=math.sqrt(x*x+y*y),theta=math.atan2(y,x),ref=true}
            end)
        end
        local widthN=math.ceil(sentry.any.width/gap)
        for side=-1,1,2 do
            for j=-widthN,widthN do
                local bullet=Bullet(copyTable(backBulletArgs))
                DanmakuFuncs.orbitBind(bullet,sentry,function (self, centerObj)
                    local x=sentry.any.width*j/widthN
                    local y=side*sentry.any.length*sentry.any.ratio*(1+1/lengthN)
                    return {r=math.sqrt(x*x+y*y),theta=math.atan2(y,x),ref=true}
                end)
            end
        end
    end
    return sentry
end