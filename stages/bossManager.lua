---@class BossSegmentArgs
---@field key string like "1-mid"
---@field bossName string a key to be sent to Localize and to get sprite
---@field getBossSpawnPos fun(self):Position
---@field rounds BossRound[]

---@class BossSegment:Segment a segment that can be called by StageManager, which contains multiple boss rounds. (would also include dialogues in the future)
---@field type 'boss'
---@field bossName string a key to be sent to Localize and to get sprite
---@field getBossSpawnPos fun(self):Position
---@field rounds BossRound[]
---@overload fun(args:BossSegmentArgs):BossSegment
local BossSegment=Object:extend()

function BossSegment:new(args)
    self.key=args.key
    self.type='boss'
    self.bossName=args.bossName
    self.getBossSpawnPos=args.getBossSpawnPos
    self.rounds=args.rounds
end

function BossSegment:func()
    local boss=Boss{
        kinematicState={pos=self.getBossSpawnPos(self)},
        sprite=Asset.boss[self.bossName],maxhp=9999,revivable=true
    }
    DynamicUIObjs.bossNameText:setText(Localize{'characters',self.bossName,'name'})
    Event.Event{obj=boss,action=function()
        for i, round in ipairs(self.rounds) do
            wait(10)
            DynamicUIObjs.bossStars:addStar()
        end
    end
    }
    
    -- after dialogues are implemented, could add something before the rounds
    for i, round in ipairs(self.rounds) do
        round:func(boss)
        DynamicUIObjs.bossStars:removeStar()
    end
    -- after battle dialogue could be added here
    boss.revivable=false
    boss.invincible=false
    boss.dropItems={}
    boss:die()
    DynamicUIObjs.bossNameText:setText('')
end

---@class BossRoundArgsDefault
---@field phases BossPhase[]

---@class BossRoundArgsGimmick
---@field phaseCount table<BossPhaseType, integer>
---@field func fun(self)

---@class BossRound:Object a round typically contains one nonspell and one spellcard. this layer is used to calculate remaining stars besides boss name and calculate HP bar (all phases in the same round compose one multi part HP bar)
---@field phaseCount fun(self):table<BossPhaseType, integer> how many phases of each type in the round. can differ based on difficulties.
---@field func fun(self, boss:Boss) call phases:run(). implement special branches like based on player's performance.
---@field phases nil|BossPhase[] if no gimmicks, set this in args and will auto build phaseCount and func. will run phases in order and skip those not fitting current difficulty or player.
---@overload fun(args:BossRoundArgsDefault|BossRoundArgsGimmick):BossRound
local BossRound=Object:extend()

function BossRound:new(args)
    if args.phases then
        self.phases=args.phases
        self.phaseCount=function(self)
            local count={nonspell=0,spellcard=0}
            for _, phase in pairs(self.phases) do
                if phase.difficulties[G.runInfo.difficulty] and phase.players[G.runInfo.playerType] then
                    if phase.type~='nonspell' and phase.type~='spellcard' then
                        error('BossRound:new: invalid phase type '.. tostring(phase.type))
                    end
                    count[phase.type]=count[phase.type]+1
                end
            end
            return count
        end
        self.func=function(self, boss)
            -- calculate phases and colors for hp bar.
            local phaseCount=self:phaseCount()
            local colors={}
            local currentColor={1,1,1}
            for i=1,phaseCount.nonspell do
                table.insert(colors,currentColor)
                currentColor=math.lerpTable(currentColor,{0.5,0.5,0.5},0.2) -- gray for nonspell phases
            end
            currentColor={0.7,0.7,1}
            for i=1,phaseCount.spellcard do
                table.insert(colors,currentColor)
                currentColor=math.lerpTable(currentColor,{0.3,0.3,1},0.2) -- blue for spellcard phases
            end
            local phases={}
            local eachSpellcard=phaseCount.spellcard<4 and 0.2 or 0.6/phaseCount.spellcard
            for i=1,phaseCount.spellcard do
                table.insert(phases,i*eachSpellcard)
            end
            local spellcardTakesup=phaseCount.spellcard*eachSpellcard
            for i=1,phaseCount.nonspell-1 do
                table.insert(phases,spellcardTakesup+i*(1-spellcardTakesup)/phaseCount.nonspell)
            end
            print(pprint(phaseCount)..pprint(phases)..pprint(colors))
            DynamicUIObjs.hpBar:setPhases(phases,colors)
            DynamicUIObjs.hpBar:initHP()
            for _, phase in pairs(self.phases) do
                if phase.difficulties[G.runInfo.difficulty] and phase.players[G.runInfo.playerType] then
                    phase:run(boss)
                end
            end
        end
    else
        if not args.phaseCount or not args.func then
            error('BossRound:new: if args.phases is not provided, args.phaseCount and args.func must be provided')
        end
        self.phaseCount=args.phaseCount
        self.func=args.func
    end
end



---@alias BossPhaseType 'nonspell'|'spellcard'

---@class BossPhase:Object should not create a BossPhase directly; only use NonSpellPhase and SpellcardPhase.
---@field type BossPhaseType
---@field time integer frames of the phase
---@field isTimeout boolean if the phase is timeout type (survive until time runs out)
---@field hp integer hp of the phase. ignored if isTimeout is true
---@field difficulties nil|table<DIFFICULTY,true> which difficulties the phase will appear in. if nil, considers as appearing in all difficulties. spellcard practice menu and default bossRound will use this.
---@field players nil|table<PLAYER,true> same logic as above
---@field func fun(self, boss:Boss) the concrete content of the boss phase. like spawn bullets
---@field run fun(self, boss:Boss) create a coroutine for self.func and run until it ends.
---@field isFinished fun(self, boss:Boss):boolean check if the phase is finished. for timeout type, check if time runs out. for hp type, check if hp<=0. this is used to determine when to end the phase and move on to the next one.
local BossPhase=Object:extend()

local ALL_DIFFICULTIES={}
for diff,_ in pairs(G.CONSTANTS.DIFFICULTIES_DATA) do
    ALL_DIFFICULTIES[diff]=true
end
local ALL_PLAYERS={}
for player,_ in pairs(G.CONSTANTS.PLAYERS_DATA) do
    ALL_PLAYERS[player]=true
end
---@class BossPhaseBaseArgs
---@field time integer
---@field isTimeout boolean|nil
---@field hp integer
---@field dropItems nil|DropItems items to drop after clearing the phase.
---@field difficulties nil|table<DIFFICULTY,true>
---@field players nil|table<PLAYER,true>
---@field func fun(self, boss:Boss)

---@class BossPhaseArgs
---@field type BossPhaseType
function BossPhase:new(args)
    self.type=args.type
    self.time=args.time
    self.isTimeout=args.isTimeout
    self.hp=args.hp
    self.dropItems=args.dropItems or {}
    if self.isTimeout then
        self.hp=99999999
    end
    self.difficulties=args.difficulties or ALL_DIFFICULTIES
    self.players=args.players or ALL_PLAYERS
    self.func=args.func or function()end
end

function BossPhase:isFinished(boss)
    if self.isTimeout then
        return self.remainingFrames<=0
    else
        return boss.hp<=0 or self.remainingFrames<=0
    end
end

function BossPhase:run(boss)
    self.remainingFrames=self.time
    DynamicUIObjs.setRemainingTimeText(self.time/60)
    boss.maxhp=self.hp
    boss.hp=boss.maxhp
    boss.invincible=false
    boss.dropItems=self.dropItems -- update drop items for the phase, which will be dropped after clearing the phase.
    local task=coroutine.create(self.func)
    while true do
        while coroutine.status(task) ~= "dead" do
            local success, err = coroutine.resume(task, self, boss)
            if not success then error(err) end
        end
        self.remainingFrames=self.remainingFrames-1
        local remaining=self.remainingFrames
        if remaining%60==0 and remaining<=600 then
            SFX.data.timeout:setPitch(remaining<=300 and 1.5 or 1) -- increase pitch when time is less than 5 seconds to make it more intense
            SFX:play('timeout',true,3)
        end
        DynamicUIObjs.setRemainingTimeText(self.remainingFrames/60)
        DynamicUIObjs.hpBar:updatePhaseHP(boss.hp/boss.maxhp) -- update hp bar
        -- Check if HP <= 0 or Time <= 0 here
        if self:isFinished(boss) then break end
        coroutine.yield() -- for outer coroutine
    end
    DynamicUIObjs.setRemainingTimeText(nil)
    if self.isTimeout or boss.hp>0 then -- reduce boss hp to 0 gradually
        while boss.hp>0 do
            boss.hp=math.max(0, boss.hp - boss.maxhp/30)
            DynamicUIObjs.hpBar:updatePhaseHP(boss.hp/boss.maxhp) -- update hp bar
            coroutine.yield()
        end
        boss:die()
    end
    DynamicUIObjs.hpBar:increasePhase() -- move to next phase in hp bar
    wait(30) -- boss:dieEffect() will create shockwave to remove previous phase bullets and bulletSpawners. without this delay bulletSpawners created in the new phase are also removed by the shockwave.
end

---@class NonSpellPhaseArgs:BossPhaseBaseArgs

--- to be implemented. like turn off spellcard background, remove spellcard name text
---@class NonSpellPhase:BossPhase
---@field type 'nonspell'
---@overload fun(args:NonSpellPhaseArgs):NonSpellPhase
local NonSpellPhase=BossPhase:extend()
function NonSpellPhase:new(args)
    NonSpellPhase.super.new(self, args)
    self.type='nonspell'
end

---@class SpellcardPhaseArgs:BossPhaseBaseArgs
---@field key string a key to be sent to Localize to get name. must be distinct. the in-game spellcard id like in spellcard history will be auto generated.
---@field bonusScore integer score player gets after clearing the spellcard.

--- to be implemented.
---@class SpellcardPhase:BossPhase
---@field type 'spellcard'
---@field key string
---@field bonusScore integer score player gets after clearing the spellcard.
---@overload fun(args:SpellcardPhaseArgs):SpellcardPhase
local SpellcardPhase=BossPhase:extend()

function SpellcardPhase:new(args)
    BossPhase.new(self, args)
    self.type='spellcard'
    self.key=args.key
    self.bonusScore=args.bonusScore
end

function SpellcardPhase:run(boss)
    DynamicUIObjs.slideSpellcardInfo()
    DynamicUIObjs.spellcardNameText:setText(Localize{'spellcards', self.key, 'name'})
    Event.Event{obj=boss,action=function()
        wait(90)
        DynamicUIObjs.spellcardBonusHistoryText:setText('0/0'..'  BONUS '.. self.bonusScore)
    end}
    BossPhase.run(self, boss)
    -- after clearing the spellcard, add bonus score and clear spellcard name text and bonus history text.
    G.runInfo.score=G.runInfo.score+self.bonusScore
    DynamicUIObjs.spellcardNameText:setText('')
    DynamicUIObjs.spellcardBonusHistoryText:setText('')
end

BossManager={
    BossSegment=BossSegment,
    BossRound=BossRound,
    BossPhase=BossPhase,
    NonSpellPhase=NonSpellPhase,
    SpellcardPhase=SpellcardPhase,
}