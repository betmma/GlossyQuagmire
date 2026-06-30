--[[
a stage mainly includes 4 waves of fairies, midboss, another 4 waves and boss. should be able to jump to every segment for stage practice. phase of boss is accessed in spellcard practice.
wave can simply be a coroutine. bosses should have their own structure, and their apperance to stageManager is also a coroutine.
complex behaviours:
different routes (a y branching point in the middle of the stage, leading to different second half of the stage)
extra wave after mid-boss to sync stage (concrete code in the extra wave is not executed if mid-boss is alive, but wait functions need to proceed)

usages:
full game: run segments in order. some segments are only for specific difficulty / player (skipped if not matching). a segment can decide the next segment as a branch (based on player's action). a segment can decide stage's end.
SKIP MODE: dev mode to skip to the end of the stage, but still run segments with SKIP_INCLUDE=true to test certain segments.
stage practice: jump to specific segment, and only run one segment / keep going like in full game. the skipped segments' init and skip will still be called to make sure the stage is properly set up, but their func will be skipped. cannot jump to a segment with unmatching player or difficulty (as continuing from here will cause error). there is a problem: if the target segment is after a branching point, how to ensure the correct branch is taken when jumping to it?
spell practice: jump to specific boss segment, and only run the spellcard phase with specific difficulty. less complex as only one segment is run. bossManager does the job to jump to the specific phase.
]]
---@alias SegmentType 'midStage'|'boss'
---@alias SegmentKey string

---@class SegmentRaw:strict
---@field key string stage practice will be able to start from any segment, and segments will be listed. names like '1-1' '1-mid' '2-5A' are enough and still need localization. segments in different stages cannot have the same key.
---@field SKIP_INCLUDE boolean|nil if true, when SKIP_MODE is on, stage practice will still include this segment. for testing middle segments. only for dev testing.
---@field type SegmentType
---@field init fun(self,segmentFuncArgs)|nil when jumping to later segment like in practice mode, init of all previous segments will be called while func of previous segments will be skipped, so init should include things like setting player border, while func should include things like spawning bullets.
---@field skip fun(self,segmentFuncArgs)|nil only called when it's skipped. called after init()
---@field difficulties nil|HasDifficulty
---@field players nil|HasPlayer

---@class SegmentRawNoNext:SegmentRaw
---@field func fun(self,segmentFuncArgs):nil the next segment will be the next one in the segments table.
---@field next nil

---@class SegmentRawWithNext:SegmentRaw
---@field func fun(self,segmentFuncArgs):SegmentKey|nil the return value must be one of the values in next, which decides the next segment. "end" means end of stage. if only one possible next segment, func can also return nil, which will be considered as going to the only possible next segment.
---@field next SegmentKey[] list of keys of possible next segments. unless including the next segment, the next segment in the segments table is not considered as a possible segment.

---@class Segment:SegmentRaw
---@field func fun(self,segmentFuncArgs):nil|SegmentKey the content of the segment. like spawn some fairies or a boss.
---@field next SegmentKey[]|nil
---@field difficulties HasDifficulty
---@field players HasPlayer

---@class OneStageDataRaw the raw data in stages/stageX/main.lua. after loading, StageManager will add other fields and do some processing
---@field init fun() to initialize the stage, like setting player border.
---@field segments (SegmentRawNoNext|SegmentRawWithNext|BossSegment)[]

---@class OneStageData:OneStageDataRaw
---@field segments Segment[]
---@field key2Index table<SegmentKey,integer> to find segment index by its key, used for jumping
---@field findPathToSegment fun(targetSegmentKey: SegmentKey): SegmentKey[] to find the path of segments from first segment to the target segment, used for jumping. use dfs. if cannot find, throw error.

---@alias StageManagerCallback 'nextStage'|'end'

---@class StageManager
---@field currentStageData OneStageData
---@field currentCoroutine thread
---@field callback StageManagerCallback what to do after stage is finished
---@field previousStagesData fullGameReplayOneStageData[] to build full game replay data
---@field args {stageKey: StageKey, skipToSegmentKey: SegmentKey|nil, onlyRunOneSegment: boolean|nil, segmentFuncArgs: BossSegmentFuncArgs|nil} to build stage / spell practice replay data
local StageManager={}

ALL_DIFFICULTIES={}
for diff,_ in pairs(G.CONSTANTS.DIFFICULTIES_DATA) do
    ALL_DIFFICULTIES[diff]=true
end
ALL_PLAYERS={}
for player,_ in pairs(G.CONSTANTS.PLAYERS_DATA) do
    ALL_PLAYERS[player]=true
end

---@type table<StageKey,OneStageData>
local StageData={}
local currentStageKeys={'stage1','stage2'} -- currently existing stages.
local function loadStageData()
    for _,stageKey in pairs(currentStageKeys) do
        StageData[stageKey]=require('stages.'..stageKey..'.main')
        StageData[stageKey].key2Index={}
        for i,segment in ipairs(StageData[stageKey].segments) do
            if segment.key=='end' then
                error('segment key cannot be "end" as it is used to indicate the end of the stage. found in stage '..stageKey)
            end
            segment.difficulties=segment.difficulties or ALL_DIFFICULTIES
            segment.players=segment.players or ALL_PLAYERS
            StageData[stageKey].key2Index[segment.key]=i
        end
        local stageData=StageData[stageKey]
        local findPathToSegment=function(targetSegmentKey)
            local visited={}
            local path={}
            local function dfs(currentSegmentKey)
                if visited[currentSegmentKey] then return false end
                visited[currentSegmentKey]=true
                table.insert(path,currentSegmentKey)
                if currentSegmentKey==targetSegmentKey then
                    return true
                end
                local currentSegment=stageData.segments[stageData.key2Index[currentSegmentKey]]
                local nextSegments=currentSegment.next or {stageData.segments[stageData.key2Index[currentSegmentKey]+1] and stageData.segments[stageData.key2Index[currentSegmentKey]+1].key}
                for _,nextSegmentKey in ipairs(nextSegments) do
                    if dfs(nextSegmentKey) then
                        return true
                    end
                end
                table.remove(path)
                return false
            end
            if not stageData.key2Index[targetSegmentKey] then
                error('cannot find segment with key '..targetSegmentKey..' in '..stageKey)
            end
            dfs(stageData.segments[1].key) -- start from the first segment
            return path
        end
        StageData[stageKey].findPathToSegment=findPathToSegment
    end
end
require 'stages.bossManager'
loadStageData()

---@type table<StageKey,SegmentKey[]> what segments are in each stage
local byStage={}
local bySegment={}

for stageKey,stageData in pairs(StageData) do
    byStage[stageKey]={}
    for _,segment in ipairs(stageData.segments) do
        table.insert(byStage[stageKey],segment.key)
        bySegment[segment.key]=segment
    end
end

---@type {byStage: table<StageKey,SegmentKey[]>, bySegment: table<SegmentKey,Segment>}
SegmentsData={byStage=byStage,bySegment=bySegment}

function StageManager:markSegmentReached(stageKey, segmentKey)
    if G.runInfo.replay then
        return
    end
    local gameType=G.runInfo.gameType
    if gameType~=G.CONSTANTS.GAME_TYPES.FULL_GAME and gameType~=G.CONSTANTS.GAME_TYPES.STAGE_PRACTICE then
        return
    end
    G.save.reachedSegments[stageKey][segmentKey]=true
    G:saveData()
end

---@param stageKey StageKey
---@param skipToSegmentKey SegmentKey|nil if not nil, will skip all segments before the segment with this key. used for stage practice to jump directly to a segment.
---@param onlyRunOneSegment boolean|nil if true, will only run the segment with key [skipToSegmentKey]. used for spellcard practice on midboss that would otherwise be followed with second half of the stage
---@param callback StageManagerCallback|nil to be called after stage is finished. like run next stage for full game
---@param segmentFuncArgs BossSegmentFuncArgs|nil if not nil, will be passed to segment func as args when calling segment:func(args). used for spellcard practice to pass specific phase to func to jump directly to a phase.
---@param nextStaging boolean|nil true when called by nextStage callback. wont reset previousStagesData
function StageManager:load(stageKey, skipToSegmentKey, onlyRunOneSegment, callback, segmentFuncArgs, nextStaging)
    self.currentStageData=StageData[stageKey]
    self.callback=callback or 'end'
    segmentFuncArgs=segmentFuncArgs or {}
    if not skipToSegmentKey then
        if DEV_MODE and SKIP_MODE then
            skipToSegmentKey=self.currentStageData.segments[#self.currentStageData.segments].key -- skip to the end of the stage for testing
        else
            skipToSegmentKey=self.currentStageData.segments[1].key -- first segment equals to not skipping any
        end
    end
    self.args={
        stageKey=stageKey,
        skipToSegmentKey=skipToSegmentKey,
        onlyRunOneSegment=onlyRunOneSegment,
        segmentFuncArgs=segmentFuncArgs
    }
    local func=function()
        self.currentStageData.init()
        local PC=1
        local reachedSkipSegment=false
        local pathToSkipSegment=self.currentStageData.findPathToSegment(skipToSegmentKey)
        local pathIndex=1
        -- besides PC and func returns next segment key, the skip logic is also there so this looks messy
        while PC<=#self.currentStageData.segments do
            local segment=self.currentStageData.segments[PC]
            if segment.init then
                segment:init(segmentFuncArgs)
            end
            local skipping=not reachedSkipSegment
            if segment.SKIP_INCLUDE and SKIP_MODE then -- during skipping, still run SKIP_INCLUDE segment
                skipping=false
            end
            if not segment.difficulties[G.runInfo.difficulty] or not segment.players[G.runInfo.playerType] then -- skip nonmatch segment
                skipping=true
            end
            if segment.key==skipToSegmentKey then -- for the intended skipToSegment, still run even if not matching (from spell practice, where can ignore player requirement. though build spellcard collection code has spellcard phase.player considered, the boss segment.player is not recorded.)
                reachedSkipSegment=true
                skipping=false
            end
            local funcRet
            if skipping then
                if segment.skip then
                    segment:skip(segmentFuncArgs)
                end
            else
                self:markSegmentReached(stageKey, segment.key)
                funcRet=segment:func(segmentFuncArgs)
                if onlyRunOneSegment then
                    break
                end
            end
            if not reachedSkipSegment then
                PC=self.currentStageData.key2Index[pathToSkipSegment[pathIndex+1]]
                pathIndex=pathIndex+1
            else
                if segment.next then
                    funcRet=funcRet or segment.next[1] -- if func returns nil, will go to the first next segment
                    if funcRet=='end' then
                        break
                    end
                    if not self.currentStageData.key2Index[funcRet] then
                        error('segment '..segment.key..' in stage '..stageKey..' returns invalid next segment key '..funcRet)
                    end
                    PC=self.currentStageData.key2Index[funcRet]
                else
                    PC=PC+1
                end
            end
        end
    end
    self.currentCoroutine=coroutine.create(func)
    GameObject:removeAll()
    DynamicUIObjs.reset()
    -- set geometry should be before creating player, since player's initial position is determined by geometry:init(). and player's creation should be before player:setReplaying. 
    if G.runInfo.replay then
        if G.runInfo.gameType==G.CONSTANTS.GAME_TYPES.FULL_GAME then
            local replayData=G.runInfo.replay.data
            ---@cast replayData fullGameReplayData
            local stagesData=replayData.stages
            for i,stageData in ipairs(stagesData) do
                if stageData.stageKey==stageKey then
                    G.runInfo.geometry=G.geometries[stageData.geometry]
                    break
                end
            end
        else
            local replayData=G.runInfo.replay.data
            ---@cast replayData stagePracticeReplayData|spellPracticeReplayData
            G.runInfo.geometry=G.geometries[replayData.geometry]
        end
    else
        G.runInfo.geometry=G.geometries[G.CONSTANTS.STAGE_TO_DEFAULT_GEOMETRY_NAME[stageKey] or 'Hyperbolic']
    end
    G.runInfo.player=Player{shotType=ShotTypes[G.runInfo.shotType]}
    ShotTypes[G.runInfo.shotType]:reset()
    if G.runInfo.replay then
        if G.runInfo.gameType==G.CONSTANTS.GAME_TYPES.FULL_GAME then
            local replayData=G.runInfo.replay.data
            ---@cast replayData fullGameReplayData
            local stagesData=replayData.stages
            for i,stageData in ipairs(stagesData) do
                if stageData.stageKey==stageKey then
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
                    break
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
    local highScoreTable,key=G:getHighScoreTableAndKey()
    G.runInfo.hiScore=highScoreTable[key]
    math.randomseed(G.runInfo.seed)
    if G.runInfo.gameType~=G.CONSTANTS.GAME_TYPES.FULL_GAME then
        G.runInfo.power=G.CONSTANTS.PRACTICE_START_POWER[stageKey]
    end
    if not nextStaging then
        self.previousStagesData={}
    end
end

-- is called when finishing a stage in StageManager:update, and called in gameEnd for dying in middle of a stage.
function StageManager:addStageData()
    self.previousStagesData[#self.previousStagesData+1] = {
        stageKey=self.args.stageKey,
        geometry=G.runInfo.geometry.name,
        keyRecord=G.runInfo.player.keyRecord,
        seed=G.runInfo.seed,
        score=G.runInfo.score,
        lives=G.runInfo.lives,
        bombs=G.runInfo.bombs,
        power=G.runInfo.power,
        grazes=G.runInfo.grazes
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
        self:addStageData()
        -- find next stage
        local stages=G.CONSTANTS.DIFFICULTIES_TO_STAGES[G.runInfo.difficulty]
        local currentStageIndex=-1
        for i,stageKey in ipairs(stages) do
            if stageKey==self.args.stageKey then
                currentStageIndex=i
                break
            end
        end
        local nextStageKey=stages[currentStageIndex+1]
        if not nextStageKey or not StageData[nextStageKey] then
            self.callback='end'
        else
            -- todo: need an image transition during switching stage
            self:load(nextStageKey,nil,nil,'nextStage',nil,true) -- wont need skip for full game
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
