--[[
a stage mainly includes 4 waves of fairies, midboss, another 4 waves and boss. should be able to jump to every segment for stage practice. phase of boss is accessed in spellcard practice.
wave can simply be a coroutine. bosses should have their own structure, and their apperance to stageManager is also a coroutine.
complex behaviours:
different routes (a y branching point in the middle of the stage, leading to different second half of the stage)
extra wave after mid-boss to sync stage (concrete code in the extra wave is not executed if mid-boss is alive, but wait functions need to proceed)
]]
---@alias SegmentType 'midStage'|'boss'

---@class Segment
---@field key string stage practice will be able to start from any segment, and segments will be listed. names like '1-1' '1-mid' '2-5A' are enough and do not need localization.
---@field SKIP_INCLUDE boolean|nil if true, when SKIP_MODE is on, stage practice will still include this segment. for testing middle segments. only for dev testing.
---@field type SegmentType
---@field init fun(self,segmentFuncArgs)|nil when jumping to later segment like in practice mode, init of all previous segments will be called while func of previous segments will be skipped, so init should include things like setting player border, while func should include things like spawning bullets.
---@field skip fun(self,segmentFuncArgs)|nil only called when it's skipped. called after init()
---@field func fun(self,segmentFuncArgs) the content of the segment. like spawn some fairies or a boss

---@class OneStageData
---@field init fun() to initialize the stage, like setting player border.
---@field segments Segment[]

---@alias StageManagerCallback 'nextStage'|'end'

---@class StageManager
---@field currentStageData OneStageData
---@field currentCoroutine thread
---@field callback StageManagerCallback what to do after stage is finished
---@field previousStagesData fullGameReplayOneStageData[] to build full game replay data
---@field args {item: StageKey, skipToSegmentKey: string|nil, onlyRunOneSegment: boolean|nil, segmentFuncArgs: BossSegmentFuncArgs|nil} to build stage / spell practice replay data
local StageManager={}

---@type table<StageKey,OneStageData>
local StageData={}
local currentStageKeys={'stage1',} -- currently existing stages.
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
---@param callback StageManagerCallback|nil to be called after stage is finished. like run next stage for full game
---@param segmentFuncArgs BossSegmentFuncArgs|nil if not nil, will be passed to segment func as args when calling segment:func(args). used for spellcard practice to pass specific phase to func to jump directly to a phase.
---@param nextStaging boolean|nil true when called by nextStage callback. wont reset previousStagesData
function StageManager:load(item, skipToSegmentKey, onlyRunOneSegment, callback, segmentFuncArgs, nextStaging)
    self.currentStageData=StageData[item]
    self.callback=callback or 'end'
    segmentFuncArgs=segmentFuncArgs or {}
    if not skipToSegmentKey then
        if DEV_MODE and SKIP_MODE then
            skipToSegmentKey=self.currentStageData.segments[#self.currentStageData.segments].key -- skip to the end of the stage for testing
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
                if segment.SKIP_INCLUDE then
                    segment:func(segmentFuncArgs)
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
    GameObject:removeAll()
    G.runInfo.player=Player{shotType=ShotTypes[G.runInfo.shotType]}
    DynamicUIObjs.reset()
    if G.runInfo.replay then
        if G.runInfo.gameType==G.CONSTANTS.GAME_TYPES.FULL_GAME then
            local replayData=G.runInfo.replay.data
            ---@cast replayData fullGameReplayData
            local stagesData=replayData.stages
            for i,stageData in ipairs(stagesData) do
                if stageData.stage==item then
                    G.runInfo.seed=stageData.seed
                    G.runInfo.player.keyRecord=stageData.keyRecord
                    G.runInfo.player:setReplaying()
                    if i>1 then -- get data from previous stage
                        local lastStageData=stagesData[i-1]
                        G.runInfo.score=lastStageData.score
                        G.runInfo.lives=lastStageData.lives
                        G.runInfo.bombs=lastStageData.bombs
                        G.runInfo.power=lastStageData.power
                        G.runInfo.grazes=lastStageData.grazes
                    end
                end
            end
        else
            local replayData=G.runInfo.replay.data
            ---@cast replayData stagePracticeReplayData|spellPracticeReplayData
            G.runInfo.seed=replayData.seed
            G.runInfo.player.keyRecord=replayData.keyRecord
            G.runInfo.player:setReplaying()
        end
    else
        G.runInfo.seed=math.floor(os.time()+os.clock()*1337)
    end
    if G.runInfo.gameType~=G.CONSTANTS.GAME_TYPES.FULL_GAME then
        G.runInfo.power=G.CONSTANTS.PRACTICE_START_POWER[item]
    end
    if not nextStaging then
        self.previousStagesData={}
    end
    self.args={
        item=item,
        skipToSegmentKey=skipToSegmentKey,
        onlyRunOneSegment=onlyRunOneSegment,
        segmentFuncArgs=segmentFuncArgs
    }
end

function StageManager:update(dt)
    if self.currentCoroutine and coroutine.status(self.currentCoroutine)~='dead' then
        local success, message=coroutine.resume(self.currentCoroutine)
        if not success then
            error(message)
        end
        return
    end
    -- below only runs when self.currentCoroutine ends
    if self.callback=='nextStage' then
        self.previousStagesData[#self.previousStagesData+1] = {
            stageKey=self.args.item,
            keyRecord=G.runInfo.player.keyRecord,
            seed=G.runInfo.seed,
            score=G.runInfo.score,
            lives=G.runInfo.lives,
            bombs=G.runInfo.bombs,
            power=G.runInfo.power,
            grazes=G.runInfo.grazes
        }
        -- find next stage
        local stages=G.CONSTANTS.DIFFICULTIES_TO_STAGES[G.runInfo.difficulty]
        local currentStageIndex=-1
        for i,stageKey in ipairs(stages) do
            if stageKey==self.args.item then
                currentStageIndex=i
                break
            end
        end
        local nextStageKey=stages[currentStageIndex+1]
        if not nextStageKey then
            self.callback='end'
        else
            -- todo: need an image transition during switching stage
            self:load(nextStageKey,nil,nil,'nextStage',nil) -- wont need skip for full game
        end
    end
    if self.callback=='end' then
        G:switchState(G.STATES.GAME_END)
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
---@field byPhaseKeyAndDiff table<string, table<DIFFICULTY,integer>> difficulty to ID in SpellcardCollection.all, indexed by phase key. used for replay info line
---@type SpellcardCollection
SpellcardCollection={
    all={},
    byStage={},
    byPhaseKeyAndDiff={},
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
                    SpellcardCollection.byPhaseKeyAndDiff[phase.key] = diffToID
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

-- for conveniently picking numbers or paths based on difficulty
---@return integer
DIFF=function()
    local difficulty=G.runInfo.difficulty
    return G[difficulty]--[[@as integer]] -- luals ???
end

---@alias ENHLValue number|'<'|'>'
---@param ENHLValues {[1]:ENHLValue, [2]:ENHLValue, [3]:ENHLValue, [4]:ENHLValue} normal use: 4 elements mapping to easy normal hard lunatic. '<' means refering to the value of the previous difficulty, and '>' means refering to the next difficulty. 
---@return number
DSWITCH=function(ENHLValues)
    local diff=DIFF()
    local count=0
    local value=ENHLValues[diff]
    while value=='<' or value=='>' do
        count=count+1
        if count>#ENHLValues then
            error('infinite loop in DSWITCH with values '..pprint(ENHLValues))
        end
        if value=='<' then
            diff=diff-1
        elseif value=='>' then
            diff=diff+1
        end
        if diff<1 or diff>#ENHLValues then
            error('difficulty out of range in DSWITCH with values '..pprint(ENHLValues))
        end
        value=ENHLValues[diff]
    end
    ---@cast value number
    return value
end

require 'stages.danmakuFuncs'

return StageManager