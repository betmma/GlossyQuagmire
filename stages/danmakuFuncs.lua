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