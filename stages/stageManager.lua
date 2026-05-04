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
---@field init fun(self,segmentFuncArgs)|nil when jumping to later segment like in practice mode, init of all previous segments will be called while func of previous segments will be skipped, so init should include things like setting player border, while func should include things like spawning bullets.
---@field skip fun(self,segmentFuncArgs)|nil only called when it's skipped. called after init()
---@field func fun(self,segmentFuncArgs) the content of the segment. like spawn some fairies or a boss

---@class OneStageData
---@field init fun() to initialize the stage, like setting player border.
---@field segments Segment[]


---@class StageManager
---@field currentStageData OneStageData
---@field currentSegmentIndex number
---@field currentCoroutine thread
---@field callback function|nil to be called after stage is finished
local StageManager={}

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
---@param skipToSegmentKey string|nil if not nil, will skip all segments before the segment with this key. used for stage practice to jump directly to a segment.
---@param onlyRunOneSegment boolean|nil if true, will only run the segment with key [skipToSegmentKey]. used for spellcard practice on midboss that would otherwise be followed with second half of the stage
---@param callback function|nil to be called after stage is finished. like run next stage for full game
---@param segmentFuncArgs BossSegmentFuncArgs|nil if not nil, will be passed to segment func as args when calling segment:func(args). used for spellcard practice to pass specific phase to func to jump directly to a phase.
function StageManager:load(item, skipToSegmentKey, onlyRunOneSegment, callback, segmentFuncArgs)
    self.currentStageData=StageData[item]
    self.currentSegmentIndex=0 -- after init finishes it will increment to 1 and start the first segment
    self.callback=callback
    segmentFuncArgs=segmentFuncArgs or {}
    if not skipToSegmentKey then
        if DEV_MODE and SKIP_MODE then
            skipToSegmentKey=self.currentStageData.segments[#self.currentStageData.segments].key -- skip to the end of the stage for testing, but not the last segment which is usually the ending
        else
            skipToSegmentKey=self.currentStageData.segments[1].key -- first segment equals to not skipping any
        end
    end
    local func=function()
        self.currentStageData.init()
        local reachedSkipSegment=false
        for i,segment in pairs(self.currentStageData.segments) do
            if segment.init then
                segment:init(segmentFuncArgs)
            end
            if segment.key==skipToSegmentKey then
                reachedSkipSegment=true
            end
            if not reachedSkipSegment then
                if segment.skip then
                    segment:skip(segmentFuncArgs)
                end
            else
                segment:func(segmentFuncArgs)
                if onlyRunOneSegment then
                    break
                end
            end
        end
    end
    self.currentCoroutine=coroutine.create(func)
end

function StageManager:update(dt)
    if self.currentCoroutine and coroutine.status(self.currentCoroutine)~='dead' then
        local success, message=coroutine.resume(self.currentCoroutine,self.currentStageData.segments[self.currentSegmentIndex])
        if not success then
            error(message)
        end
    elseif self.callback then
        self.callback()
        self.callback=nil
    end
end

-- used for spellcard history and jumping to specific phase in spellcard practice. it will pass skipToSegmentKey and onlyRunOneSegment to StageManager:load to jump to and only run the boss segment, and pass segmentFuncArgs to StageManager:load then to BossSegment:func to only create one round with the specific phase.
---@class SpellcardCollectionItem:strict
---@field ID integer auto increments. only used for in game menu, must not use it in save data
---@field stage StageKey the stage this spellcard belongs to
---@field segmentKey string the segment this spellcard belongs to, like '1-mid'. passed as skipToSegmentKey to StageManager:load to jump to the segment
---@field phaseKey string same as SpellcardPhase.key
---@field difficulty DIFFICULTY every item in SpellcardPhase.difficulties
---@field players table<PLAYER,true> same as SpellcardPhase.players
---@field phase SpellcardPhase the original phase object for this spellcard

-- used for spellcard practice menu. the menu has stage-spellcard-difficulty structure
---@class SpellcardCollectionItemCombineDifficulty:strict
---@field phaseKey string same as SpellcardPhase.key
---@field stage StageKey the stage this spellcard belongs to
---@field difficulties table<DIFFICULTY,integer> difficulty to ID in SpellcardCollection.all
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
                    local diffToID={}
                    -- Create entry for every supported difficulty
                    for i,diff in ipairs(G.CONSTANTS.STAGE_TO_DIFFICULTIES[stageKey]) do
                        if phase.difficulties[diff] then
                            ---@type SpellcardCollectionItem
                            local item={
                                ID = nextID,
                                segmentKey = segment.key,
                                phaseKey = phase.key,
                                stage = stageKey,
                                difficulty = diff,
                                players = phase.players,
                                phase = phase -- Useful for jumping directly to the phase in practice
                            }
                            table.insert(SpellcardCollection.all, item)
                            diffToID[diff] = item.ID
                            nextID = nextID + 1
                        end
                    end
                    ---@type SpellcardCollectionItemCombineDifficulty
                    local item={
                        phaseKey = phase.key,
                        stage = stageKey,
                        difficulties = diffToID,
                        players = phase.players,
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