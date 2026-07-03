local function setZoomSpeed(value,duration)
    local geo=G.runInfo.geometry
    ---@cast geo MovingGeometryBase
    if geo.setZoomSpeed then
        geo:setZoomSpeed(value,duration)
    end
    if duration==0 then
        G.backgroundPattern.autoForwardSpeed=value*60
        return
    end
    if G.backgroundPattern.autoForwardSpeed then
        Event.EaseEvent{
            easeObj=G.backgroundPattern,aims={autoForwardSpeed=value*60},duration=duration
        }
    end
end

return setZoomSpeed