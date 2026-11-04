--[[
there are 3 info collector things:
replay, statistics and player score.
replay info collection is mostly managed by stage manager. main events are
RUN_START -> empty, 
STAGE_END/LOSE_GAME -> add stage data, 
RUN_END/LOSE_GAME -> set G.runInfo.pendingReplay to getPendingReplay() (actually written in gameEnd.lua)
statistics info collection is in its file. main events are 
RUN_START -> empty, 
STAGE_END/LOSE_GAME -> add stage data, 
USE_CONTINUE -> pop stage data.
player score:
RUN_START -> empty, 
RUN_END/LOSE_GAME -> make a score line.

why don't merge LOSE_GAME into RUN_END and STAGE_END: counting 1cc can solely rely on RUN_END
]]

---@alias ALLAndStages StageKey|"ALL"

--- note that, not like replay where each replay should know which gameplay mode and which player it's for, player scores are stored in saves, so save-playerScore-player-difficulty-fullGame/stagex-lines the path to lines already gives what they are for, so no need to store these in ScoreLine. still needs a stage to sort full game score lines.
--- after continue, cannot save player score.
--- considering save score and player score menu need some common logic, player score should have its own file
--- how to decide the states? save score should have its own state. but game end should have a unified entrance. auto switching from gameEnd to saveScore could cause problem... but that remains to see.

---@class ScoreLine
---@field id string timestamp is enough. i don't care if player decides to change system time to mess with this
---@field name string The name user typed
---@field time string %Y-%m-%d %H:%M:%S
---@field score number
---@field missCount integer miss count and bomb count aren't tracked now. not good to add to statistics because it records changes of these values but doesn't track the cause. so add a local tracker here
---@field bombCount integer
---@field stage ALLAndStages

---@alias ScoreSortBy "SCORE"|"SURVIVAL"

local currentRunTracker={miss=0,bomb=0,lose=false}
EM.listenTo(EM.EVENTS.PLAYER_MISS,function ()
    currentRunTracker.miss=currentRunTracker.miss+1
end)
EM.listenTo(EM.EVENTS.PLAYER_BOMB,function ()
    currentRunTracker.bomb=currentRunTracker.bomb+1
end)
EM.listenTo(EM.EVENTS.LOSE_GAME,function ()
    currentRunTracker.lose=true
end)
EM.listenTo(EM.EVENTS.RUN_START,function ()
    currentRunTracker.miss=0
    currentRunTracker.bomb=0
    currentRunTracker.lose=false
end)

---@type table<string,integer>
local LENGTHS={
    INDEX=3, -- "10."
    NAME=ReplayManager.MAX_NAME_LENGTH, -- =20
    SCORE=10, -- 10 score digits, or XXM XXB for survival
    DATE=19, -- "2023-10-11 18:30:20"
    STAGE=5, -- "St XX"
}
local sum=-1 -- 3+1+20+1+10+1+19+1+5=61 chars
for _,value in pairs(LENGTHS) do
    sum=sum+value+1
end

---@class PlayerScoreManager
---@field pendingScoreLine ScoreLine|nil if no pending score line could be nil. including: continued, not full stage practice, spell practice
---@field SORT_BY ScoreSortBy[]
---@field OVERALL_WIDTH integer character count of a score line
local PlayerScoreManager={
    currentRunTracker=currentRunTracker,
    pendingScoreLine=nil,
    SORT_BY={'SURVIVAL','SCORE'},
    MAX=10,
    OVERALL_WIDTH=sum
}

function PlayerScoreManager:setPendingScoreLine()
    if G.runInfo.continued then
        self.pendingScoreLine=nil
        return
    end
    if G.runInfo.gameType==G.CONSTANTS.GAME_TYPES.SPELL_PRACTICE then
        self.pendingScoreLine=nil
        return
    end
    if G.runInfo.gameType==G.CONSTANTS.GAME_TYPES.STAGE_PRACTICE and not (StageManager.args.skipToSegmentKey==StageManager.currentStageData.segments[1].key and not StageManager.args.onlyRunOneSegment) then
        self.pendingScoreLine=nil
        return
    end
    local id=tostring(os.time())
    local time=getTimeString()
    ---@type ALLAndStages
    local stage=StageManager.args.stageKey
    if G.runInfo.gameType==G.CONSTANTS.GAME_TYPES.FULL_GAME and currentRunTracker.lose==false then
        stage="ALL" -- so stage practice failed and cleared are both "stage x". it's fine because failing a stage practice means 8+ misses
    end
    self.pendingScoreLine={id=id,name=G.save.defaultName,time=time,score=G.runInfo.score,missCount=currentRunTracker.miss,bombCount=currentRunTracker.bomb,stage=stage}
end
EM.listenTo(EM.EVENTS.RUN_END,function ()
    PlayerScoreManager:setPendingScoreLine()
end)
EM.listenTo(EM.EVENTS.LOSE_GAME,function ()
    PlayerScoreManager:setPendingScoreLine()
end)

---@type table<ScoreSortBy,fun(a:ScoreLine,b:ScoreLine):boolean>
local compares={
    SCORE=function (a, b)
        if a.score~=b.score then
            return a.score>b.score
        end
        return a.time<b.time
    end,
    SURVIVAL=function (a, b)
        -- stage first
        local stagea,stageb=a.stage,b.stage
        local aall,ball=stagea=='ALL', stageb=='ALL'
        if aall and not ball then
            return true
        end
        if not aall and ball then
            return false
        end
        if not aall and not ball then
            local stages=G.CONSTANTS.STAGE_KEYS
            for _,stage in ipairs(stages) do
                local ay,by=stagea==stage,stageb==stage
                if ay and not by then
                    return false
                end
                if by and not ay then
                    return true
                end
                if ay and by then
                    break
                end
            end
        end
        -- miss, then bomb, then time
        if a.missCount~=b.missCount then
            return a.missCount<b.missCount
        end
        if a.bombCount~=b.bombCount then
            return a.bombCount<b.bombCount
        end
        return a.time<b.time
    end
}

local function getCurrentAllOrStage()
    return G.runInfo.gameType==G.CONSTANTS.GAME_TYPES.FULL_GAME and 'ALL' or StageManager.args.stageKey
end
---find top MAX of score lines
---@param sortBy ScoreSortBy
---@param shotType? SHOT_TYPE
---@param difficulty? DIFFICULTY
---@param allOrStage? ALLAndStages
---@return ScoreLine[] table
function PlayerScoreManager:getSorted(sortBy,shotType,difficulty,allOrStage)
    shotType=shotType or G.runInfo.shotType
    difficulty=difficulty or G.runInfo.difficulty
    allOrStage=allOrStage or getCurrentAllOrStage()
    local lines=G.save.scoreLines[shotType][difficulty][allOrStage]
    table.sort(lines,compares[sortBy])
    local ret={}
    for i=1,self.MAX do
        ret[i]=lines[i]
    end
    return ret
end

---get the rank of scoreLine (usually new score line) on all sortBys, sorted by rank
---@param scoreLine ScoreLine
---@param shotType? SHOT_TYPE
---@param difficulty? DIFFICULTY
---@param allOrStage? ALLAndStages
---@return {sortBy:ScoreSortBy,rank:integer}[] fullResults
function PlayerScoreManager:getScoreLineRank(scoreLine,shotType,difficulty,allOrStage)
    shotType=shotType or G.runInfo.shotType
    difficulty=difficulty or G.runInfo.difficulty
    allOrStage=allOrStage or getCurrentAllOrStage()
    local lines=G.save.scoreLines[shotType][difficulty][allOrStage]
    local results={}
    for _,sortBy in ipairs(self.SORT_BY) do
        local compare=compares[sortBy]
        local rank=1
        while rank<=#lines and compare(lines[rank],scoreLine) do
            rank=rank+1
        end
        table.insert(results,{sortBy=sortBy,rank=rank})
    end
    table.sort(results,function (a, b)
        return a.rank<b.rank
    end)
    return results
end


---add the scoreLine into save and evict a line not in top MAX of any sortBy if such line exists.
---@param scoreLine ScoreLine
---@param shotType? SHOT_TYPE
---@param difficulty? DIFFICULTY
---@param allOrStage? ALLAndStages
function PlayerScoreManager:addAndEvictScoreLine(scoreLine,shotType,difficulty,allOrStage)
    shotType=shotType or G.runInfo.shotType
    difficulty=difficulty or G.runInfo.difficulty
    allOrStage=allOrStage or getCurrentAllOrStage()
    local lines=G.save.scoreLines[shotType][difficulty][allOrStage]
    table.insert(lines,scoreLine)
    local inTopMAX={}
    for _,sortBy in ipairs(self.SORT_BY) do
        table.sort(lines,compares[sortBy])
        for i=1,math.min(#lines,self.MAX) do
            inTopMAX[lines[i].id]=true
        end
    end
    for i=#lines,1,-1 do
        if not inTopMAX[lines[i].id] then
            table.remove(lines,i)
            return
        end
    end
end

---get a string of the line
---@param index integer
---@param scoreLine ScoreLine|nil
---@param sortBy ScoreSortBy
function PlayerScoreManager:getDisplayLine(index,scoreLine,sortBy)
    local indexStr=string.format("%-"..LENGTHS.INDEX.."s",tostring(index)..".")
    if not scoreLine then
        return indexStr..' '..string.rep('-', self.OVERALL_WIDTH-LENGTHS.INDEX-1)
    end
    local nameStr = string.format("%-" .. LENGTHS.NAME .. "s", scoreLine.name):sub(1, LENGTHS.NAME) -- Pad or truncate name (though truncate wont happen)
    local scoreStr=''
    if sortBy=="SCORE" then
        scoreStr=string.format("%"..LENGTHS.SCORE.."s",scoreLine.score)
    elseif sortBy=="SURVIVAL" then
        -- two parts
        local miss,bomb=scoreLine.missCount,scoreLine.bombCount
        local length=math.floor(LENGTHS.SCORE/2)-1
        scoreStr=string.format("%"..length.."s",tostring(miss)..'M')..' '..string.format("%"..length.."s",tostring(bomb)..'B')
        scoreStr=string.format("%"..LENGTHS.SCORE.."s",scoreStr)
    end
    local dateStr = scoreLine.time
    local stageStr=scoreLine.stage=='ALL' and 'ALL' or 'St '..G.CONSTANTS.STAGE_SHORT_FORMS[scoreLine.stage]
    stageStr= string.format("%"..LENGTHS.STAGE..'s',stageStr)
    return string.format("%s %s %s %s %s",indexStr,nameStr,scoreStr,dateStr,stageStr)
end

return PlayerScoreManager