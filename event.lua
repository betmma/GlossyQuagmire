---@class Event:GameObject
---@field obj GameObject the object that the event is attached to.
---@field coroutine thread
local Event = GameObject:extend()

Event.Event = Event

---@class EventArgs
---@field obj GameObject the object that the event is attached to.
---@field action fun(self:Event) the function to be executed. it will be wrapped in a coroutine.
---@field afterFunc function|nil the function to be executed after the action is done. not useful in basic Event, but can be used in LoopEvent and EaseEvent.

---@param args EventArgs
function Event:new(args)
    -- self.frame=args.frame or 0
    self.obj=args.obj
    local action=args.action or function(_)end
    local afterFunc=args.afterFunc or function(_) end
    self.coroutine=coroutine.create(function()
        action(self)
        afterFunc(self)
    end)
end

wait=function(frames)
    for i=1,frames do
        coroutine.yield()
    end
end

function Event:update(dt)
    -- If the object is dead, kill the event
    if self.obj and self.obj.removed then
        self:remove()
        return
    end
    if self.coroutine and coroutine.status(self.coroutine)~='dead' then
        local success, message=coroutine.resume(self.coroutine)
        if not success then
            error(message)
        end
    else
        self:remove()
    end
end

---@class LoopEvent:Event
local LoopEvent = Event:extend()

---@class LoopEventArgs:EventArgs
---@field period number number of frames between each execution of the function. default is 60.
---@field firstPeriod number number of frames before the first execution of the function. default is period.
---@field times number the number of times to execute the function. default is math.huge.
---@field executeFunc fun(self:Event, index:number, total:number) the function to be executed.

---@param args LoopEventArgs
function LoopEvent:new(args)
    local period = args.period or 60
    local firstPeriod = args.firstPeriod or period
    local times = args.times or math.huge
    local executeFunc = args.executeFunc or function(event, index, total) end

    args.action = function(_self)
        wait(firstPeriod)
        for i = 1, times do
            if i>1 then
                wait(period)
            end
            executeFunc(self, i, times)
        end
    end

    LoopEvent.super.new(self, args)
end
Event.LoopEvent = LoopEvent


Event.sineIOProgressFunc = function(x) return math.sin((x - 0.5) * math.pi) * 0.5 + 0.5 end
Event.sineOProgressFunc = function(x) return math.sin(x * math.pi / 2) end
Event.sineBackProgressFunc = function(x) return math.sin(x * math.pi) end

---@class EaseEvent:Event
local EaseEvent = Event:extend()

---@enum EaseMode
EaseEvent.easeMode={
    soft='soft',
    hard='hard',
}

---@class EaseEventArgs:EventArgs
---@field duration number duration of the easing in frames.
---@field aims table<string, number> the target values to be eased to. the keys should be the same as the keys in the obj that you want to ease.
---@field easeObj table|nil if the object to be eased is not the obj of the event, you can provide it here.
---@field progressFunc nil|fun(x:number):number the function to determine the progress of the easing. it takes a number between 0 and 1 and normally returns a number between 0 and 1. default is function(x) return x end.
---@field easeMode EaseMode|nil the mode of easing. 'soft' means obj.key is added by d(progressFunc())*(target-initial) each frame and can be simultaneously changed by other sources, while 'hard' means the value is set to certain value each frame and won't be changed by other sources. default is 'soft'.

---@param args EaseEventArgs
function EaseEvent:new(args)
    local duration = args.duration or 60
    local aims = args.aims or {}
    local easeObj = args.easeObj or args.obj
    local progressFunc = args.progressFunc or function(x) return x end
    local easeMode = args.easeMode or EaseEvent.easeMode.soft

    local initialValues = {}
    for key, target in pairs(aims) do
        initialValues[key] = easeObj[key]
    end

    args.action = function(_self)
        local lastProgress = progressFunc(0)
        for frame = 1, duration do
            wait(1)
            local progress = progressFunc(frame / duration)
            for key, target in pairs(aims) do
                if easeMode == EaseEvent.easeMode.soft then
                    easeObj[key] = easeObj[key] + (target - initialValues[key]) * (progress-lastProgress)
                elseif easeMode == EaseEvent.easeMode.hard then
                    easeObj[key] = initialValues[key] + (target - initialValues[key]) * progress
                end
            end
            lastProgress = progress
        end
    end

    EaseEvent.super.new(self, args)
end

Event.EaseEvent = EaseEvent

return Event