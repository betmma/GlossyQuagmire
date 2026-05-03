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
---@field init fun() to initialize the stage, like setting player border.
---@field segments Segment[]

---@alias StageKey 'stage1'|'stage2'|'stage3'|'stage4'|'stage5'|'stage6'|'stageEX'

---@class StageManager
---@field currentStageData OneStageData
---@field currentSegmentIndex number
---@field currentCoroutine thread
---@field callback function|nil to be called after stage is finished
local StageManager={}
StageManager.allStageKeys={'stage1','stage2','stage3','stage4','stage5','stage6','stageEX'}

---@type table<StageKey,OneStageData>
local StageData={}
local currentStageKeys={'stage1'} -- currently existing stages.
local function loadStageData()
    for _,stageKey in pairs(currentStageKeys) do
        StageData[stageKey]=require('stages.'..stageKey..'.main')
    end
end
require 'stages.bossManager'
loadStageData()

---@param item StageKey
---@param callback function|nil to be called after stage is finished
function StageManager:load(item,callback)
    self.currentStageData=StageData[item]
    self.currentSegmentIndex=0 -- after init finishes it will increment to 1 and start the first segment
    self.callback=callback
    self.currentCoroutine=coroutine.create(self.currentStageData.init)
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

---@class SpellcardCollectionItem:strict
---@field ID integer auto increments. only used for in game menu, must not use it in save data
---@field key string same as SpellcardPhase.key
---@field stage StageKey the stage this spellcard belongs to
---@field difficulty DIFFICULTY every item in SpellcardPhase.difficulties
---@field players table<PLAYER,true> same as SpellcardPhase.players

---@class SpellcardCollectionItemCombineDifficulty:strict
---@field ID integer auto increments. only used for in game menu, must not use it in save data
---@field key string same as SpellcardPhase.key
---@field stage StageKey the stage this spellcard belongs to
---@field difficulties table<DIFFICULTY,true> same as SpellcardPhase.difficulties
---@field players table<PLAYER,true> same as SpellcardPhase.players

---@class SpellcardCollection to store all spellcards for spellcard practice and history
---@field all SpellcardCollectionItem[] flat table of all spellcards
---@field byStage table<StageKey, SpellcardCollectionItemCombineDifficulty[]> spellcards grouped by stage
---@type SpellcardCollection
SpellcardCollection={
    all={},
    byStage={},
}

function StageManager:buildSpellcardCollection()
    local nextID = 1
    for _, stageKey in ipairs(currentStageKeys) do
        local data = StageData[stageKey]
        if not (data and data.segments) then goto continue_stage end
        for _, segment in ipairs(data.segments) do
            if segment.type ~= 'boss' then goto continue_segment end
            ---@cast segment BossSegment
            for _, round in ipairs(segment.rounds) do
                if not round.phases then goto continue_round end
                for _, phase in ipairs(round.phases) do
                    if phase.type ~= 'spellcard' then goto continue_phase end
                    ---@cast phase SpellcardPhase
                    -- Create entry for every supported difficulty
                    for diff, active in pairs(phase.difficulties) do
                        local item={
                            ID = nextID,
                            key = phase.key,
                            stage = stageKey,
                            difficulty = diff,
                            players = phase.players,
                            phaseObj = phase -- Useful for jumping directly to the phase in practice
                        }
                        table.insert(SpellcardCollection.all, item)
                        nextID = nextID + 1
                    end
                    local item={
                        key = phase.key,
                        stage = stageKey,
                        difficulties = phase.difficulties,
                        players = phase.players,
                        phaseObj = phase -- Useful for jumping directly to the phase in practice
                    }
                    if not SpellcardCollection.byStage[stageKey] then
                        SpellcardCollection.byStage[stageKey] = {}
                    end
                    table.insert(SpellcardCollection.byStage[stageKey], item)
                    ::continue_phase::
                end
                ::continue_round::
            end
            ::continue_segment::
        end
        ::continue_stage::
    end
end
StageManager:buildSpellcardCollection()

return StageManager