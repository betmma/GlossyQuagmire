---@alias expression "normal"|"happy"|"sad"|"angry"|"surprised"|"cunning"|"frustrated"
---@alias position "left"|"right"|nil -- nil means use default position for the speaker. 

---@class DialogueLine
---@field speaker string used to pick image and display speaker name. 'system' is darken screen and display text in center
---@field expression expression used to pick image
---@field textKey string text is in localization.lua
---@field position position where to position image (and flip)

--- of course i want to omit "key=" in each line definition
---@param speaker string
---@param expression expression
---@param textKey string
---@param position position
---@return DialogueLine
local function line(speaker,expression,textKey,position)
    return {
        speaker=speaker,
        expression=expression,
        textKey=textKey,
        position=position,
    }
end

---@class Dialogue
---@field name string identifier, and is the key in localization.dialogues
---@field defaultSpeakerPosition table<string,position> default position for each speaker
---@field lines DialogueLine[]

local Dialogue={}

---@class DialogueController:GameObject
---@field transparency number
---@field removing boolean
---@field currentLineIndex integer
---@field autoAdvanceTime number seconds to auto advance
---@field timeSinceLastAdvance number
---@field timeSinceLastAutoAdvance number
---@field dialogueKey string key in Dialogue.data
---@field data Dialogue
---@field afterFunc function called after dialogue ends
---@field activeCharacters table<string,activeCharacter> list of characters that have appeared in this dialogue
---@overload fun(args:DialogueControllerArgs):DialogueController
local DialogueController=GameObject:extend()
local portraitBatch=Asset.portraitBatch
local portraitQuads=Asset.portraitQuads
local portraitWidth,portraitHeight=Asset.portraitWidth,Asset.portraitHeight

---@class DialogueControllerArgs
---@field key string key in Dialogue.data
---@field autoAdvanceTime? number seconds to auto advance
---@field afterFunc? function called after dialogue ends
function DialogueController:new(args)
    DialogueController.super.new(self,args)
    self.transparency=0
    self.removing=false
    self.currentLineIndex=1
    self.autoAdvanceTime=args.autoAdvanceTime or 5 -- seconds to auto advance
    self.timeSinceLastAdvance=0
    self.timeSinceLastAutoAdvance=999
    self.dialogueKey=args.key
    self.data=Dialogue.data[args.key]
    if not self.data then
        error("Dialogue key "..tostring(args.key).." not found in Dialogue.data")
    end
    self.afterFunc=args.afterFunc -- function to call after dialogue ends
    ---@class activeCharacter
    ---@field speaker string
    ---@field expression expression
    ---@field position position
    ---@field brightness number -- 0-1, automatically update to highlight speaking character
    
    ---@type table<string,activeCharacter>
    self.activeCharacters={} -- list of characters that have appeared in this dialogue. once appeared, their portrait will stay on screen (changing transparency based on who is speaking)

    self.playerZCallback=function() -- why dont in DialogueController:update directly read player.keyIsPressed? because DialogueController:update could be called after player:update, while player:update bumps player.frame by 1. so in replay player.keyIsPressed call in DialogueController:update could see 1 frame later than the calls in player.update. so let player emit an event in player.update to prevent this issue.
        if self.timeSinceLastAutoAdvance>0.5 then -- > 0.5 check to avoid unintended advance after an auto advance
            self:advanceDialogue()
        end
    end
    EventManager.listenTo(EventManager.EVENTS.PLAYER_PRESS_Z,self.playerZCallback)
end

function DialogueController:block()
    while not self.removed do
        wait()
    end
end

function DialogueController:update(dt)
    if self.removing then
        self.transparency=math.max(self.transparency-1/30,0)
        if self.transparency==0 then
            EventManager.removeListener(EventManager.EVENTS.PLAYER_PRESS_Z,self.playerZCallback)
            self:remove()
        end
    else
        self.transparency=math.min(self.transparency+1/30,1)
    end

    self.timeSinceLastAdvance=self.timeSinceLastAdvance+dt
    self.timeSinceLastAutoAdvance=self.timeSinceLastAutoAdvance+dt
    local player=G.runInfo.player
    if player then
        if self.timeSinceLastAdvance>=self.autoAdvanceTime then -- or love.keyboard.isDown('lctrl') then -- press z or hold left ctrl to advance. lctrl isn't in player's replay record keys so cannot add now. and adding lctrl would exceed 8 keys and also need to change replayManager's serialize (currently 8 keys -> 2 hex chars) ughh
            self:advanceDialogue()
        end
    end
    if self.removed then
        return
    end
    -- update character portraits
    local line=self.data.lines[self.currentLineIndex]
    local speaker=line and line.speaker
    if speaker=='system' then
        self.activeCharacters={} -- clear all characters when system message
    end
    if speaker~='system' and self.activeCharacters[speaker]==nil then
        self.activeCharacters[speaker]={
            speaker=speaker,
            expression=line.expression,
            position=line.position or self.data.defaultSpeakerPosition[speaker] or 'left',
            brightness=0,
        }
    end
    for s,character in pairs(self.activeCharacters) do -- fade in/out portraits
        if s==speaker then
            character.brightness=math.min(character.brightness+dt*4,1)
            character.expression=line.expression
        else
            character.brightness=math.max(character.brightness-dt*4,0.3)
        end
    end
end

function DialogueController:advanceDialogue()
    SFX:play('select',false)
    if self.timeSinceLastAdvance>=self.autoAdvanceTime then
        self.timeSinceLastAutoAdvance=0
    end
    self.timeSinceLastAdvance=0
    self.currentLineIndex=self.currentLineIndex+1
    if self.currentLineIndex>#self.data.lines then
        if self.afterFunc then
            self.afterFunc()
        end
        self.removing=true
        self.currentLineIndex=#self.data.lines -- stay on last line until removed
    end
end

function DialogueController:draw()
    local line=self.data.lines[self.currentLineIndex]
    local speaker=line and line.speaker
    local charactersOrder={}
    for s,character in pairs(self.activeCharacters) do
        if character==speaker then -- draw later to ensure on top
            goto continue
        end
        table.insert(charactersOrder,character)
        ::continue::
    end
    if self.activeCharacters[speaker] then
        table.insert(charactersOrder,self.activeCharacters[speaker])
    end
    for _,character in ipairs(charactersOrder) do
        portraitBatch:setColor(character.brightness,character.brightness,character.brightness,1*self.transparency)
        local speaker,expression=character.speaker,character.expression
        local expressions=portraitQuads[speaker]
        if not expressions then
            goto continue
        end
        local quad=expressions[expression] or expressions.normal
        if not quad then
            goto continue
        end
        local x=character.position=='left' and -150+portraitWidth/4 or WINDOW_WIDTH-10-portraitWidth/4 -- width and height are 2000px. /4 -> 500px
        local y=WINDOW_HEIGHT-portraitHeight/4
        portraitBatch:add(quad,x,y,0,0.25*(character.position=='left' and -1 or 1),0.25)
        ::continue::
    end
    Asset.dialogueBatch:add(function()
        self:drawDialogueBox()
    end)
end

-- draw the dialogue box, current line and speaker name
function DialogueController:drawDialogueBox()
    if self.currentLineIndex>#self.data.lines then
        return
    end
    local line=self.data.lines[self.currentLineIndex]
    local speaker=line.speaker
    local textKey=line.textKey
    local position=line.position or self.data.defaultSpeakerPosition[speaker] or 'left'
    local text=Localize{'dialogues',self.dialogueKey,textKey}
    local color={love.graphics.getColor()}
    SetFont(24)
    if speaker=='system' then
        love.graphics.setColor(0,0,0,0.5*self.transparency)
        love.graphics.rectangle('fill',0,0,WINDOW_WIDTH,WINDOW_HEIGHT)
        love.graphics.setColor(1,1,1,1*self.transparency)
        love.graphics.printf(text,150,WINDOW_HEIGHT/2-50,WINDOW_WIDTH-300,'center')
    else
        love.graphics.setColor(0,0,0,0.5*self.transparency)
        local x,y,width,height=50,450,500,130
        love.graphics.rectangle('fill',x,y,width,height)
        local gap=15
        love.graphics.setColor(1,1,1,1*self.transparency)
        love.graphics.printf(text,x+gap,y+gap,width-gap*2,'left')
        -- speaker name. it's possible for white part in portrait to cover the name, so draw shadow texts first
        love.graphics.setColor(0,0,0,0.5*self.transparency)
        local name=Localize{'characters',speaker,'name'}
        local basex,basey,baseWidth=x+gap,y-gap-20,width-gap*2
        love.graphics.printf(name,basex-2,basey,baseWidth,position)
        love.graphics.printf(name,basex+2,basey,baseWidth,position)
        love.graphics.printf(name,basex,basey-2,baseWidth,position)
        love.graphics.printf(name,basex,basey+2,baseWidth,position)
        love.graphics.setColor(1,1,1,1*self.transparency)
        love.graphics.printf(name,basex,basey,baseWidth,position)
    end
    love.graphics.setColor(color)
end


local REIMUS1BossBefore={
    name='REIMUS1BossBefore',
    defaultSpeakerPosition={
        reimu='left',
        kotoba='right',
    },
    lines={
        line('reimu','normal','hiKotoba'),
        line('reimu','happy','howsYourWorkHere'),
        line('kotoba','normal','workIsFine'),
        line('reimu','normal','haveYouHeardThatMysteriousPlace'),
        -- line('kotoba','surprised','sheKnowsIllSkipWork'),
        line('kotoba','frustrated','ughNo'),
        line('reimu','surprised','howCanYouNotKnow'),
        line('kotoba','sad','ahhhIMeanIKnowBut'),
        line('reimu','cunning','aDanmakuBattleWouldHelpYouRemember'),
    }
}

local REIMUS1BossAfter={
    name='REIMUS1BossAfter',
    defaultSpeakerPosition={
        reimu='left',
        kotoba='right',
    },
    lines={
        line('kotoba','frustrated','yeahIRememberNow'),
        line('reimu','happy','soItsThisWay'),
    }
}

local MARISAS1BossBefore={
    name='MARISAS1BossBefore',
    defaultSpeakerPosition={
        marisa='left',
        kotoba='right',
    },
    lines={
        line('marisa','surprised','wowThisPlaceSoCool'),
        line('kotoba','normal','welcomeToHyperbolicDomain'),
        line('marisa','normal','ohHi'),
        line('marisa','cunning','wheresThatPlace'),
        line('kotoba','surprised','waitThatThievishLook'),
        line('kotoba','angry','iMustStopYouNow'),
    }
}

local MARISAS1BossAfter={
    name='MARISAS1BossAfter',
    defaultSpeakerPosition={
        marisa='left',
        kotoba='right',
    },
    lines={
        line('kotoba','frustrated','youreStrong'),
        line('marisa','happy','ofCourseIAm'),
        line('kotoba','frustrated','whatAreYouLookingForHere'),
        line('marisa','normal','thatPlace'),
        line('kotoba','frustrated','thisWay'),
        line('marisa','happy','shouldTellMeInTheBeginning'),
    }
}

---@type table<string,Dialogue>
Dialogue.data={
    REIMUS1BossBefore=REIMUS1BossBefore,
    REIMUS1BossAfter=REIMUS1BossAfter,
    MARISAS1BossBefore=MARISAS1BossBefore,
    MARISAS1BossAfter=MARISAS1BossAfter,
}


return DialogueController