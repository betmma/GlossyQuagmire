--[[
a stage mainly includes 4 waves of fairies, midboss, another 4 waves and boss. should be able to jump to every segment for stage practice. phase of boss is accessed in spellcard practice.
wave can simply be a coroutine. bosses should have their own structure, and their apperance to stageManager is also a coroutine.
complex behaviours:
different routes (a y branching point in the middle of the stage, leading to different second half of the stage)
extra wave after mid-boss to sync stage (concrete code in the extra wave is not executed if mid-boss is alive, but wait functions need to proceed)

additional things to include in stageManager:
provide a function to display stage title text

]]
---@alias SegmentType 'midStage'|'boss'

---@class Segment
---@field key string stage practice will be able to start from any segment, and segments will be listed. names like '1-1' '1-mid' '2-5A' are enough and do not need localization.
---@field type SegmentType
---@field func fun() the content of the segment. like spawn some fairies or a boss

---@class OneStageData
---@field segments Segment[]

---@alias StageKey 'stage1'|'stage2'|'stage3'|'stage4'|'stage5'|'stage6'|'stageEX'

---@class StageManager
---@field currentStageData OneStageData
---@field currentSegmentIndex number
---@field currentCoroutine thread
---@field callback function|nil to be called after stage is finished
local StageManager={}

---@type table<StageKey,OneStageData>
local StageData={}

local function loadStageData()
    for _,stageKey in pairs({'stage1'}) do
        StageData[stageKey]=require('stages.'..stageKey..'.main')
    end
end
require 'stages.bossManager'
loadStageData()

---@param item StageKey
---@param callback function|nil to be called after stage is finished
function StageManager:load(item,callback)
    self.currentStageData=StageData[item]
    self.currentSegmentIndex=1
    self.callback=callback
    self.currentCoroutine=coroutine.create(self.currentStageData.segments[self.currentSegmentIndex].func)
end

function StageManager:update(dt)
    if self.currentCoroutine and coroutine.status(self.currentCoroutine)~='dead' then
        local success, message=coroutine.resume(self.currentCoroutine,self.currentStageData.segments[self.currentSegmentIndex])
        if not success then
            error(message)
        end
    elseif self.currentSegmentIndex and self.currentStageData and self.currentSegmentIndex<#self.currentStageData.segments then
        self.currentSegmentIndex=self.currentSegmentIndex+1
        self.currentCoroutine=coroutine.create(self.currentStageData.segments[self.currentSegmentIndex].func)
    elseif self.callback then
        self.callback()
        self.callback=nil
    end
end

return StageManager