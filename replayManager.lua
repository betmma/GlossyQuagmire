--[[
consider replay system, possible contents are: full game, stage practice (start from arbitrary segment), spell practice
a replay needs to store keyRecord, seed, difficulty, shot type, player name, time, version
for full game replay, keyRecord and seed need to be stored separately for each stage as can play from any stage. also need score, lives, bombs, power, graze at the end of each stage
for stage practice, need stage, segment key, whether continue or only one segment
for spell practice, need spellcard key

interactions with replay system:
saving replay: user chooses a slot and name. read G.runInfo to form a replay and save to file. during choosing, also needs to show existing replays
loading replay: in replays menu, user views existing replays and load one
replayManager needs to expose 3 interfaces:
saveToSlot(slot, name)
getDisplayLine(slot)
runReplay(slot)
]]

local lume=require"import.lume"
if IS_WEB then
    -- using standard Lua.
    bit = require("import.bit")
else
    bit = require("bit")
end

HASH_LENGTH=128 -- 64 integers * 2 hex char per integer
---hash a string into 64 integers array
---@param input string
---@return integer[]
function Hash64(input)
    local hash_table = {}
    local seed = 0xABCDEF  -- Seed value to initialize the hashing process
    -- Initialize the hash table with 64 default values
    for i = 1, 64 do
        hash_table[i] = (seed * i) % 256
    end
    -- Iterate through each character in the input string
    for i = 1, #input do
        local byte = string.byte(input, i)
        local index = (i % 64) + 1 
        -- Use bitwise operations to modify the hash table
        local temp = hash_table[index]
        temp = bit.bxor(temp, byte)
        temp = bit.rol(temp, 3)  -- Rotate left 3 bits
        temp = (temp + seed) % 256
        hash_table[index] = temp
        -- Update the seed based on the character value
        seed = bit.bxor(seed, byte)
        seed = bit.ror(seed, 5)  -- Rotate right 5 bits
    end
    -- Further diffusion across the hash table
    for i = 1, 64 do
        local index = (i % 64) + 1
        hash_table[i] = bit.bxor(hash_table[i], hash_table[index])
        hash_table[i] = (hash_table[i] + seed) % 256
    end
    return hash_table
end

---@param t integer[] each value cannot exceed 255 and will become 2 chars
---@return string
local function intTableToHexString(t)
    local hexParts = {}
    for i = 1, #t do
        -- %02x: 
        -- 0 means pad with leading zeros
        -- 2 means minimum width of 2 characters
        -- x means format as lowercase hexadecimal
        hexParts[i] = string.format("%02x", t[i])
    end
    return table.concat(hexParts)
end

---@param hex string
---@return integer[]
local function hexStringToIntTable(hex)
    local t = {}
    local count = 1
    for i = 1, #hex, 2 do
        -- Extract two characters
        local byteString = string.sub(hex, i, i + 1)
        -- Convert from hex (base 16) to integer
        local num = tonumber(byteString, 16)
        
        if num then
            t[count] = num
            count = count + 1
        end
    end
    return t
end

---@class replayDataBase:strict
---@field difficulty DIFFICULTY
---@field shotType SHOT_TYPE
---@field name string The name user typed in save replay menu
---@field time string The time when the run started.
---@field version string game version of the run.
---@field type GAME_TYPE The type of the replay.

---@class replayBase:Object
---@field data replayDataBase
---@field getDisplayLine fun(self: replayBase): string does not include No. aaa part
---@field getReplayFromCurrentGame fun(self:replayBase, name: string): replayBase called when saving replay. can consider it another new()
---@field protected getBasicReplayDataFromCurrentGame fun(self:replayBase): {difficulty: DIFFICULTY, shotType: SHOT_TYPE, time: string, version: string, type: GAME_TYPE} helper function for subclasses
---@field protected getBaseHashString fun(self:replayBase, data:replayDataBase): string include common fields in replayData for hash
---@field protected getExtraHashString fun(self:replayBase, data:replayDataBase): string subclasses need to override it to include additional fields in the hash
---@field toSaveFormat fun(self: replayBase):table transform to save format, mainly: replace keyRecord with more compact hex strings and add hash value. replayBase.toSaveFormat is only for subclasses with keyRecord in self.data and should not be used on replayBase
---@field fromSaveFormat fun(self: replayBase, data: table): replayBase|nil takes save format and tries to load. if hash doesnt match returns nil, otherwise returns an instance like new()
---@overload fun(data: replayDataBase): replayBase
local replayBase=Object:extend(true)
function replayBase:new(data)
    self.data=data
end

replayBase.SLOT_WIDTH=6
replayBase.MAX_NAME_LENGTH=20
replayBase.DATE_WIDTH=19 -- "2023-10-11 18:30:20" (fixed format)
replayBase.SHOT_TYPE_LENGTH=7 -- longest like MARISAA
replayBase.IDENTIFIER_LENGTH=7 -- full stage L All or Ex, stage practice longest L St. 6, spell practice longest No. 999
replayBase.OVERALL_WIDTH=replayBase.SLOT_WIDTH+1+replayBase.MAX_NAME_LENGTH+1+replayBase.DATE_WIDTH+1+replayBase.SHOT_TYPE_LENGTH+1+replayBase.IDENTIFIER_LENGTH -- +1 are spaces between sections. sum=63
replayBase.OVERALL_WIDTH_WITHOUT_SLOT=replayBase.OVERALL_WIDTH-replayBase.SLOT_WIDTH-1

function replayBase:getDisplayLine()
    local nameStr = string.format("%-" .. replayBase.MAX_NAME_LENGTH .. "s", self.data.name):sub(1, replayBase.MAX_NAME_LENGTH) -- Pad or truncate name (though truncate wont happen)
    local dateStr = self.data.time
    local shotTypeStr = string.format("%-" .. replayBase.SHOT_TYPE_LENGTH .. "s", self.data.shotType):sub(1, replayBase.SHOT_TYPE_LENGTH) -- Pad or truncate shot type
    return string.format("%s %s %s", nameStr, dateStr, shotTypeStr)
end

function replayBase:getReplayFromCurrentGame(name)
    error("getReplayFromCurrentGame not implemented for replayBase")
end

function replayBase:getBasicReplayDataFromCurrentGame()
    return {
        difficulty=G.runInfo.difficulty,
        shotType=G.runInfo.shotType,
        time=os.date('%Y-%m-%d %H:%M:%S'),
        version=VERSION,
        type=G.runInfo.gameType,
    }
end

function replayBase:getBaseHashString(data)
    return data.difficulty..data.shotType..data.time..data.version..data.type
end

function replayBase:getExtraHashString(data)
    return ""
end

---@param keyRecord integer[]
---@param hashPrefix string
---@return string
function replayBase:transformKeyRecord(keyRecord,hashPrefix)
    local hexKeyRecord=intTableToHexString(keyRecord)
    local hashResult=Hash64(hashPrefix..hexKeyRecord)
    local hashResultString=intTableToHexString(hashResult)
    return hexKeyRecord..hashResultString
end

---@param hexKeyRecordWithHash string
---@param hashPrefix string
---@return boolean, integer[]
function replayBase:testSavedKeyRecord(hexKeyRecordWithHash, hashPrefix)
    local hexKeyRecord,hash=string.sub(hexKeyRecordWithHash,1,-HASH_LENGTH-1),string.sub(hexKeyRecordWithHash,-HASH_LENGTH)
    local calculatedHash=Hash64(hashPrefix..hexKeyRecord)
    local calculatedHashString=intTableToHexString(calculatedHash)
    return calculatedHashString==hash, hexStringToIntTable(hexKeyRecord)
end

function replayBase:toSaveFormat()
    local data=copyTable(self.data)
    local baseHashString=self:getBaseHashString(data)
    local extraHashString=self:getExtraHashString(data)
---@diagnostic disable-next-line: param-type-mismatch
    data.keyRecord=self:transformKeyRecord(data.keyRecord, baseHashString..extraHashString)
    return data
end

function replayBase:fromSaveFormat(data)
---@diagnostic disable-next-line: param-type-mismatch
    local baseHashString=self:getBaseHashString(data)
---@diagnostic disable-next-line: param-type-mismatch
    local extraHashString=self:getExtraHashString(data)
    local isValid,keyRecord=self:testSavedKeyRecord(data.keyRecord--[[@as string]], baseHashString..extraHashString)
    if not isValid then
        return nil
    end
    data.keyRecord=keyRecord
    return self(data)
end

---@type table<StageKey, string>
replayBase.STAGE_SHORT_FORMS={
    stage1='1',
    stage2='2',
    stage3='3',
    stage4='4',
    stage5='5',
    stage6='6',
    stageEX='EX',
}

---@class emptyReplay:replayBase
local emptyReplay=replayBase:extend()
function emptyReplay:getDisplayLine()
    return string.rep('-', replayBase.OVERALL_WIDTH_WITHOUT_SLOT)
end

---@class fullGameReplayOneStageData:strict
---@field stageKey StageKey
---@field keyRecord integer[] The key record of the replay.
---@field seed number The seed used for RNG.
---@field score integer The score at the end of the stage.
---@field lives integer The number of lives remaining at the end of the stage.
---@field bombs integer The number of bombs remaining at the end of the stage.
---@field power integer The power level at the end of the stage.
---@field grazes integer The graze count at the end of the stage.

---@class fullGameReplayData:replayDataBase
---@field stages fullGameReplayOneStageData[]

---@class fullGameReplay:replayBase
---@field data fullGameReplayData
---@field getReplayFromCurrentGame fun(self:fullGameReplay, name: string): fullGameReplay
---@field toSaveFormat fun(self: fullGameReplay):table
---@field fromSaveFormat fun(self: fullGameReplay, data: table): fullGameReplay|nil
---@overload fun(data: fullGameReplayData): fullGameReplay
local fullGameReplay=replayBase:extend()
function fullGameReplay:getDisplayLine()
    local leftParts=replayBase.getDisplayLine(self)
    local identifier=string.format("%-3s",G.CONSTANTS.DIFFICULTIES_DATA[self.data.difficulty].shortForm)..'ALL'
    return string.format("%s %s", leftParts, identifier)
end

function fullGameReplay:getReplayFromCurrentGame(name)
    local data=self:getBasicReplayDataFromCurrentGame()
    return fullGameReplay{
        difficulty=data.difficulty,shotType=data.shotType,time=data.time,version=data.version,type=data.type,
        name=name,
        stages=StageManager.previousStagesData,
    }
end

---@param stageData fullGameReplayOneStageData
function fullGameReplay:stageDataString(stageData)
    return string.format('%s_%d_%d_%d_%d_%d_%d', stageData.stageKey, stageData.score, stageData.lives, stageData.bombs, stageData.power, stageData.grazes, stageData.seed)
end

function fullGameReplay:toSaveFormat()
    local data=copyTable(self.data)
    local baseHashString=self:getBaseHashString(data)
    for level, stageData in ipairs(data.stages) do
        local stageDataString=self:stageDataString(stageData)
---@diagnostic disable-next-line: assign-type-mismatch
        stageData.keyRecord=self:transformKeyRecord(stageData.keyRecord, baseHashString..stageDataString)
    end
    return data
end

function fullGameReplay:fromSaveFormat(data)
    local baseHashString=self:getBaseHashString(data--[[@as replayDataBase]])
    for level, stageData in ipairs(data.stages) do
        local stageDataString=self:stageDataString(stageData)
        local isValid,keyRecord=self:testSavedKeyRecord(stageData.keyRecord--[[@as string]], baseHashString..stageDataString)
        if not isValid then
            return nil
        end
        stageData.keyRecord=keyRecord
    end
    return fullGameReplay(data--[[@as fullGameReplayData]])
end

---@class stagePracticeReplayData:replayDataBase
---@field keyRecord integer[] The key record of the replay.
---@field seed number The seed used for RNG.
---@field score integer
---@field stage StageKey
---@field segmentKey string start from which segment 
---@field onlyRunOneSegment boolean

---@class stagePracticeReplay:replayBase
---@field data stagePracticeReplayData
---@field getReplayFromCurrentGame fun(self:stagePracticeReplay, name: string): stagePracticeReplay
---@overload fun(data: stagePracticeReplayData): stagePracticeReplay
local stagePracticeReplay=replayBase:extend()
function stagePracticeReplay:getDisplayLine()
    local leftParts=replayBase.getDisplayLine(self)
    local identifier=string.format("%-3s",G.CONSTANTS.DIFFICULTIES_DATA[self.data.difficulty].shortForm)..'St '..replayBase.STAGE_SHORT_FORMS[self.data.stage]
    return string.format("%s %s", leftParts, identifier)
end

function stagePracticeReplay:getReplayFromCurrentGame(name)
    local data=self:getBasicReplayDataFromCurrentGame()
    return stagePracticeReplay{
        difficulty=data.difficulty,shotType=data.shotType,time=data.time,version=data.version,type=data.type,
        name=name,
        stage=StageManager.args.item,
        keyRecord=G.runInfo.player.keyRecord,
        seed=G.runInfo.seed,
        score=G.runInfo.score,
        segmentKey=StageManager.args.skipToSegmentKey,
        onlyRunOneSegment=StageManager.args.onlyRunOneSegment,
    }
end

function stagePracticeReplay:getExtraHashString(data)
    return string.format('%d_%d_%s_%s', data.seed, data.score, data.segmentKey, data.stage)
end

---@class spellPracticeReplayData:replayDataBase
---@field keyRecord integer[] The key record of the replay.
---@field score integer
---@field seed number The seed used for RNG.
---@field spellcardKey string The key of the spellcard being practiced.

---@class spellPracticeReplay:replayBase
---@field data spellPracticeReplayData
---@field getReplayFromCurrentGame fun(self:spellPracticeReplay, name: string): spellPracticeReplay
---@field overload fun(data: spellPracticeReplayData): spellPracticeReplay
local spellPracticeReplay=replayBase:extend()
function spellPracticeReplay:getDisplayLine()
    local leftParts=replayBase.getDisplayLine(self)
    local spellcardIndex=SpellcardCollection.byPhaseKeyAndDiff[self.data.spellcardKey][self.data.difficulty]
    local identifier='Sp '..spellcardIndex
    return string.format("%s %s", leftParts, identifier)
end

function spellPracticeReplay:getReplayFromCurrentGame(name)
    local data=self:getBasicReplayDataFromCurrentGame()
    return spellPracticeReplay{
        difficulty=data.difficulty,shotType=data.shotType,time=data.time,version=data.version,type=data.type,
        name=name,
        keyRecord=G.runInfo.player.keyRecord,
        seed=G.runInfo.seed,
        score=G.runInfo.score,
        spellcardKey=SpellcardCollection.byPhaseKeyAndDiff[StageManager.args.segmentFuncArgs.practicePhase][G.runInfo.difficulty],
    }
end

function spellPracticeReplay:getExtraHashString(data)
    return string.format("%d_%d_%s", data.seed, data.score, data.spellcardKey)
end

local GAME_TYPE_TO_REPLAY_CLASS={
    [G.CONSTANTS.GAME_TYPES.FULL_GAME]=fullGameReplay,
    [G.CONSTANTS.GAME_TYPES.STAGE_PRACTICE]=stagePracticeReplay,
    [G.CONSTANTS.GAME_TYPES.SPELL_PRACTICE]=spellPracticeReplay,
}

---@class ReplayManager:strict
---@field private replays replayBase[]
---@field private readDataAtSlot fun(self:ReplayManager, slot: integer): replayBase read from disk
---@field readAllReplays fun(self:ReplayManager) read all replays from disk to ReplayManager.replays, called at launch and entering save / load replay menus, not at switch pages in save / load replay menus
---@field getPendingReplay fun(self:ReplayManager, name: string): replayBase in save replay enter name menu, to generate the pending replay for this run
---@field saveToSlot fun(self:ReplayManager, slot: integer, name: string)
---@field getDisplayLineOfReplay fun(self:ReplayManager, replay:replayBase, slot:integer): string concat No.aaa with replay:getDisplayLine
---@field getDisplayLineAtSlot fun(self:ReplayManager, slot: integer): string pass ReplayManager.replays[slot] to getDisplayLineOfReplay, doesnt read from disk
---@field runReplayAtSlot fun(self:ReplayManager, slot: integer, startStage: StageKey|nil): boolean returns whether replay is running (isn't empty)
local replayManager={}
replayManager.replays={}
replayManager.REPLAY_NUM_PER_PAGE=25
replayManager.PAGES=8
replayManager.OVERALL_WIDTH=replayBase.OVERALL_WIDTH

local dir='replay'
love.filesystem.createDirectory(dir)
local function savePath(slot)
    return dir..'/'..string.format('%03d',slot)..'.rpy'
end

function replayManager:readDataAtSlot(slot)
    local path=savePath(slot)
    local file=love.filesystem.read(path)
    if not file then
        return emptyReplay()
    end
    local data = lume.deserialize(file)
    local replayClass=GAME_TYPE_TO_REPLAY_CLASS[data.replayType]
    local valid,replay=replayClass:fromSaveFormat(data)
    if not valid then
        return emptyReplay()
    end
    return replay
end

function replayManager:readAllReplays()
    for i=1,self.PAGES*self.REPLAY_NUM_PER_PAGE do
        self.replays[i]=self:readDataAtSlot(i)
    end
end

function replayManager:getPendingReplay(name)
    local gameType=G.runInfo.gameType
    local replayClass=GAME_TYPE_TO_REPLAY_CLASS[gameType]
    local replay=replayClass:getReplayFromCurrentGame(name)
    return replay
end

function replayManager:saveToSlot(slot, name)
    local replay=self:getPendingReplay(name)
    self.replays[slot]=replay
    local toSaveData=replay:toSaveFormat()
    love.filesystem.write(savePath(slot), lume.serialize(toSaveData))
end

function replayManager:getDisplayLineOfReplay(replay,slot)
    local slotText=string.format("No.%03d", slot)
    return slotText..replay:getDisplayLine()
end

function replayManager:getDisplayLineAtSlot(slot)
    return self:getDisplayLineOfReplay(self.replays[slot], slot)
end

function replayManager:runReplayAtSlot(slot,stageKey)
    local replay=self.replays[slot]
    if replay:is(emptyReplay) then
        return false
    end
    local gameType=replay.data.type
    if gameType==G.CONSTANTS.GAME_TYPES.FULL_GAME then
        ---@cast replay fullGameReplay
        G:resetRunInfo(gameType,replay.data.difficulty,replay.data.shotType,G.STATES.LOAD_REPLAY,replay)
        G:switchState(G.STATES.IN_GAME)
        StageManager:load(stageKey or G.CONSTANTS.DIFFICULTIES_TO_STAGES[replay.data.difficulty][1])
    elseif gameType==G.CONSTANTS.GAME_TYPES.SPELL_PRACTICE then
        ---@cast replay spellPracticeReplay
        G:resetRunInfo(gameType,replay.data.difficulty,replay.data.shotType,G.STATES.LOAD_REPLAY,replay)
        G:switchState(G.STATES.IN_GAME)
        local spellKey=replay.data.spellcardKey
        local spellID=SpellcardCollection.byPhaseKeyAndDiff[spellKey][replay.data.difficulty]
        local spellcardData=SpellcardCollection.all[spellID]
        StageManager:load(spellcardData.stage,spellcardData.segmentKey,true,'end',{practicePhase=spellcardData.phaseKey})
    elseif gameType==G.CONSTANTS.GAME_TYPES.STAGE_PRACTICE then
        ---@cast replay stagePracticeReplay
        G:resetRunInfo(gameType,replay.data.difficulty,replay.data.shotType,G.STATES.LOAD_REPLAY,replay)
        G:switchState(G.STATES.IN_GAME)
        StageManager:load(replay.data.stage,replay.data.segmentKey,replay.data.onlyRunOneSegment,'end')
    end
    return true
end

replayManager.monospacePrint=function(str,width,x,y)
    for i=1,#str do
        love.graphics.printf(str:sub(i,i),x+width*(i-1),y,width,'center')
    end
end

replayManager:readAllReplays()

return replayManager