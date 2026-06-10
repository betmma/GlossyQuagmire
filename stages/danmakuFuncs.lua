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

---add an extraUpdate function to [shape] to make it orbit around [centerObj] with radius and angle determined by [rtheta]. it will not set position if centerObj is removed.
---@param shape Shape
---@param centerObj Shape
---@param rtheta rThetaRet|fun(self:Shape, centerObj:Shape): rThetaRet
---@param onCenterRemoved fun(self:Shape)|nil a function to be called when the centerObj is removed. can choose to remove the shape or do something else. if nil does nothing
function DanmakuFuncs.orbitBind(shape, centerObj, rtheta, onCenterRemoved)
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
        local centerPos=centerObj.kinematicState.pos
        self.kinematicState.pos,self.kinematicState.dir=G.runInfo.geometry:rThetaGo(centerPos,rthetanew.r,rthetanew.theta+(rthetanew.absolute and 0 or centerObj.kinematicState.dir))
        if rthetanew.extraTheta then
            self.kinematicState.dir=self.kinematicState.dir+rthetanew.extraTheta
        end
    end
end