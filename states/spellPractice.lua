local base=UI.Base()
local updateOptions
local shotType=G.CONSTANTS.SHOT_TYPES[1]
return {
    base=base,
    init=function(self)
        local leftX=50
        local titleText=base:child(
            UI.Text{
                text=Localize{'ui','MAIN_MENU',"SPELL_PRACTICE"},
                fontSize=48,color={1,1,1,1},
                x=leftX+50,y=60,
            }
        )
        local shotTypeSwitcher=UI.Switcher{
            x=leftX,y=550,parent=base,
            preview=2,
            arrange=function(_,index)
                return index*100,0
            end,
            optionConstructor=function(_,shotTypeIndex)
                local shotType=G.CONSTANTS.SHOT_TYPES[(shotTypeIndex-1)%#G.CONSTANTS.SHOT_TYPES+1]
                local text=Localize{'ui','SPELL_PRACTICE','shotTypes',shotType}
                local base=UI.Base()
                local shotTypeText=UI.Text{
                    text=text,
                    fontSize=24,color={1,1,1,1},
                    x=350,y=0,parent=base,width=500,align='center'
                }
                return base
            end,
            events={
                [UI.EVENTS.SWITCHED]=function(_self,args)
                    local index=args.index
                    shotType=G.CONSTANTS.SHOT_TYPES[(index-1)%#G.CONSTANTS.SHOT_TYPES+1]
                    updateOptions()
                end
            }
        }
        local optionBaseX=leftX
        local optionBaseY=200
        local optionHeight=40
        local previewCircleRadius=800
        local anglePerOption=math.asin(optionHeight/previewCircleRadius)
        --- a circle arrangement switcher, each option means a stage. each option is a uiBase including stage X text and a switcher for spellcards in that stage. right to the second switcher is difficulty options to select difficulties
        local stageSwitcher
        stageSwitcher=UI.Switcher{
            parent=base,
            x=optionBaseX,y=optionBaseY,
            preview=2,
            arrange=function(_,index)
                local angle=anglePerOption*index
                return previewCircleRadius*math.cos(angle),previewCircleRadius*math.sin(angle)
            end,
            extraUpdates={function(self)
                self.x=math.lerp(self.x,optionBaseX+(140-self.currentOption.cursor.parent.x)*0.6,0.1) -- the width of stage x text + spellcard switcher + difficulty switcher exceeds window width, so slide the whole switcher to fit in
                if self.currentOption.cursor.parent~=self.currentOption.stageText then -- disable self's switching if the current option's cursor is not on the stage text (means the user is choosing spellcards or difficulties, not stages)
                    self.focused=false
                end
            end,},
            events={
                [UI.EVENTS.SWITCHED]=function(_self,args)
                    updateOptions()
                end
            },
            -- very cursed as if stageSwitcher.preview~=0, all local variables in optionConstructor will be shared among options so all objects in it must keep a reference to each other instead of using local names
            optionConstructor=function(_, optionIndex)
                local fade=function(self)
                    self.transparency=math.lerpCondition(self.transparency,stageSwitcher.currentOptionIndex==optionIndex,1,0,0.2)
                end
                local stageKey=G.CONSTANTS.STAGE_KEYS[optionIndex]
                if not stageKey then return nil end
                local horizontalOptionsCursor=UI.Cursor{
                    fluctuateRatio=0.05,extraUpdates={fade},transparency=0,
                }
                local rise=-15
                UI.Text{text='←:'..KEYS.CANCEL,color={0,0,0,1},fontSize=12,isBold=false,fontName=Fonts.zh_cn,x=0,y=rise,parent=horizontalOptionsCursor,extraUpdates={function(self)
                    local x,y,w,h=self.parent:getFluctuationXYWH()
                    local ax,ay=self.parent:getXY()
                    self.x=x-ax
                    self.y=y-ay+rise
                end},updateText=function(self)
                    local currentOption=self.parent.parent -- self -> cursor -> current option
                    local horizontalOptions=currentOption.parent.parent -- current option -> container -> horizontalOptions
                    if currentOption==horizontalOptions.stageText then
                        return Localize{'ui','SPELL_PRACTICE','cursor','back'}..':'..KEYS.CANCEL
                    else
                        return '←:'..KEYS.CANCEL
                    end
                end}
                UI.Text{text=KEYS.SELECT..':→',color={0,0,0,1},fontSize=12,isBold=false,fontName=Fonts.zh_cn,x=horizontalOptionsCursor.width,y=rise,align='right',toggleX=true,parent=horizontalOptionsCursor,extraUpdates={function(self)
                    local x,y,w,h=self.parent:getFluctuationXYWH()
                    local ax,ay=self.parent:getXY()
                    self.x=x-ax+w
                    self.y=y-ay+rise
                end},updateText=function(self)
                    local currentOption=self.parent.parent -- self -> cursor -> current option
                    local horizontalOptions=currentOption.parent.parent -- current option -> container -> horizontalOptions
                    if currentOption==horizontalOptions.difficultyOptions then
                        return KEYS.SELECT..':'..Localize{'ui','SPELL_PRACTICE','cursor','start'}
                    else
                        return KEYS.SELECT..':→'
                    end
                end}
                ---@class SpellPracticeHorizontalOptions: UIOptions
                ---@field currentSpellcard SpellcardCollectionItemCombineDifficulty|nil the currently chosen spellcard in the stage, used to determine which difficulties to show in difficulty options
                ---@field spellcards SpellcardCollectionItemCombineDifficulty[]
                ---@field stageText UIText
                ---@field spellcardSwitcher UISwitcher
                ---@field difficultyOptions UIOptions
                local horizontalOptions=UI.Options{cursor=horizontalOptionsCursor,keysToDirections={
                    [KEYS.SELECT] = 'right',
                    [KEYS.CANCEL] = 'left',
                },loopable=false}
                horizontalOptions.spellcards=SpellcardCollection.byStage[stageKey] or {}
                local stageText=UI.Text{
                    text=Localize{'ui','SPELL_PRACTICE','stages',stageKey},
                    fontSize=32,color={1,1,1,1},
                    x=-130,y=140,autoSize=true,
                }
                horizontalOptions.stageText=stageText
                horizontalOptions:addOption(stageText)
                local spellcardSwitcher=UI.Switcher{
                    x=0,y=150,width=120,height=22,transparency=0,extraUpdates={fade,function(self)
                        local option=self.currentOption
                        if not option then return end
                        self.width,self.height=option.width,option.height
                    end},
                    preview=3,previewDecayRadius=0.6,
                    arrange=function(_,index)
                        return 0,index*25
                    end,
                    optionConstructor=function(self,spellcardIndex)
                        local hoptions=self.parent and self.parent.parent or horizontalOptions -- first call of this function is in UI.Switcher:init, at that time self.parent is not set so use horizontalOptions to get spellcards
                        local item=hoptions.spellcards[spellcardIndex]
                        if not item then return nil end
                        local text=Localize{'ui','SPELL_PRACTICE','spellcard',index=spellcardIndex}
                        local spellcardText=UI.Text{
                            text=text,
                            fontSize=22,color={1,1,1,1},
                            x=0,y=0,parent=base,autoSize=true
                        }
                        return spellcardText
                    end,
                }
                horizontalOptions:addOption(spellcardSwitcher)
                horizontalOptions.spellcardSwitcher=spellcardSwitcher
                local difficultyOptions
                -- updates the currently chosen stage's spellcards and difficulties
                updateOptions=function()
                    ---@type SpellPracticeHorizontalOptions
                    local horizontalOptions=stageSwitcher.currentOption--[[@as SpellPracticeHorizontalOptions]]
                    local diffOptions=horizontalOptions.difficultyOptions
                    local chosenDifficulty=diffOptions.cursor and diffOptions.cursor.parent and diffOptions.cursor.parent--[[@as SpellPracticeDifficultyOption]].difficulty or nil
                    diffOptions:clearOptions()
                    item=horizontalOptions.spellcards[horizontalOptions.spellcardSwitcher.currentOptionIndex]
                    if not item then return end
                    for i,diff in ipairs(G.CONSTANTS.STAGE_TO_DIFFICULTIES[stageKey]) do
                        if item.difficulties[diff] then
                            local status=2 -- 1, 2, 3 means locked, unlocked, cleared respectively
                            local historyTable=G.save.spellcardHistory[item.phaseKey][diff][shotType]
                            if historyTable.practice.cleared or historyTable.ingame.cleared then
                                status=3
                            elseif not historyTable.ingame.unlocked then
                                status=1
                            end
                            local color=({{0.5,0.5,0.5,1},{1,1,1,1},{0.75,0.75,1,1}})[status]
                            ---@class SpellPracticeDifficultyOption: UIBase
                            local base=UI.Base{width=500,height=40}
                            base.difficulty=diff
                            local diffText=diff
                            local difficultyText=UI.Text{text=diffText,fontSize=20,color=color,boldColor={0,0,0,1},x=0,y=0,width=200,parent=base}
                            local id=item.difficulties[diff]
                            local idText=UI.Text{text='ID. '..tostring(id),fontSize=16,color=color,boldColor={0,0,0,1},x=0,y=20,parent=base}
                            local spellcardName=status>=2 and Localize{'spellcards',item.phaseKey, diff,'name'} or Localize{'spellcards','UNKNOWN', diff,'name'}
                            local spellcardNameText=UI.Text{text=spellcardName,fontSize=20,color=color,boldColor={0,0,0,1},x=500,y=0,width=400,align="right",parent=base}
                            local historyText=Localize{'ui','SPELL_PRACTICE','spellcardHistory',
                                ingamePass=historyTable.ingame.passes,
                                ingameTries=historyTable.ingame.tries,
                                practicePass=historyTable.practice.passes,
                                practiceTries=historyTable.practice.tries,
                            }
                            local historyUIText=UI.Text{text=historyText,fontSize=16,color=color,boldColor={0,0,0,1},x=500,y=20,width=400,align="right",parent=base}
                            diffOptions:addOption(base)
                            if diff==chosenDifficulty then
                                diffOptions:switchOption(base,true,true)
                            end
                        end
                    end
                end
                difficultyOptions=UI.Options{
                    x=140,y=40,width=500,height=250,transparency=0,
                    container=UI.Arranger{
                        arrange=function(self,index)
                            return 0,(index-1)*70
                        end
                    },extraUpdates={function(self)
                        local horizontalOptions=self.parent.parent -- difficulty options -> container -> horizontal options
                        local latestSpellcard=horizontalOptions.spellcards[horizontalOptions.spellcardSwitcher.currentOptionIndex]
                        if latestSpellcard~=horizontalOptions.currentSpellcard then
                            horizontalOptions.currentSpellcard=latestSpellcard
                            updateOptions()
                        end
                    end,fade},
                    cursor=UI.Cursor{
                        drawStyle=UI.Cursor.DRAW_STYLE.Face,
                        color={0,0,0,0.3},transparency=0,
                        fluctuateRatio=0,
                        extraUpdates={function(self)
                            self.transparency=math.lerpCondition(self.transparency,self.focused,1,0,0.1)
                        end},
                    }
                }
                horizontalOptions:addOption(difficultyOptions)
                horizontalOptions.difficultyOptions=difficultyOptions
                -- updateOptions()
                local exit=UI.Base{x=-100,y=0,width=0,height=0,events={
                    [UI.EVENTS.FOCUS]=function(self,args)
                        self.parent.parent:switchOption(stageText,true,false)
                        G:switchState(G.STATES.MAIN_MENU)
                    end}}
                horizontalOptions:addOption(exit)
                local enterGame=UI.Base{x=600,y=0,width=0,height=0,events={
                    [UI.EVENTS.FOCUS]=function(self,args)
                        self.parent.parent:switchOption(difficultyOptions,true,false)
                        local item=self.parent.parent.spellcards[self.parent.parent.spellcardSwitcher.currentOptionIndex]
                        if not item then return end
                        local diff=difficultyOptions.cursor.parent--[[@as SpellPracticeDifficultyOption]].difficulty
                        local id=item.difficulties[diff]
                        local spellcardData=SpellcardCollection.all[id]
                        local historyTable=G.save.spellcardHistory[item.phaseKey][diff][shotType]
                        if not historyTable.ingame.unlocked then
                            SFX:play('cancel',true)
                            return
                        end
                        SFX:play('select',true)
                        G.runInfo.difficulty=diff
                        G.runInfo.playerType=G.CONSTANTS.SHOT_TYPE_TO_PLAYER[shotType]
                        G.runInfo.shotType=shotType
                        StageManager:load(spellcardData.stage,spellcardData.segmentKey,true,function ()
                            G:switchState(G.STATES.SPELL_PRACTICE) -- after adding replay, should goto save replay state
                        end,{practicePhase=item.phaseKey})
                        G:resetRunInfo(0,0)
                        G.runInfo.practice=true
                        G.runInfo.exitToState=G.STATES.SPELL_PRACTICE
                        G:switchState(G.STATES.IN_GAME)
                    end}}
                horizontalOptions:addOption(enterGame)
                return horizontalOptions
            end
        }
    end,
    enter=function(self)
        self:replaceBackgroundPatternIfNot(BackgroundPattern.MainMenuTesselation)
        base.frame=0
        if updateOptions then updateOptions() end -- to refresh the options when entering the state, in case there are changes in spellcard history after playing a stage or practice
    end,
    update=function(self,dt)
        self.backgroundPattern:update(dt)
        base:updateHierarchy()
        if isPressed('escape')then
            SFX:play('select')
            self:switchState(self.STATES.MAIN_MENU)
        end
    end,
    draw=function(self)
    end,
    drawText=function(self)
        base:drawTextHierarchy()
    end
}