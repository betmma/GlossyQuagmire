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
        local optionBaseX=leftX
        local optionBaseY=200
        local optionHeight=100
        local previewCount=1
        local previewCircleRadius=800
        local anglePerOption=math.asin(optionHeight/previewCircleRadius)
        --- a circle arrangement switcher, each option means a stage. each option is a uiBase including stage X text and a switcher for spellcards in that stage. right to the second switcher is options to select difficulties
        local stageSwitcher=UI.Switcher{
            parent=base,
            x=optionBaseX,y=optionBaseY,
            preview=0,
            arrange=function(_,index)
                local angle=anglePerOption*index
                return previewCircleRadius*math.cos(angle),previewCircleRadius*math.sin(angle)
            end,
            extraUpdates={function(self)
                if self.currentOption.cursor.parent~=self.currentOption.stageText then
                    self.focused=false
                end
            end,},
            optionConstructor=function(_, optionIndex)
                local stageKey=StageManager.allStageKeys[optionIndex]
                if not stageKey then return nil end
                ---@class SpellPracticeStageOption: UIOptions
                local horizontalOptions=UI.Options{cursor=UI.Cursor{
                    fluctuateRatio=0.05,
                }}
                function horizontalOptions:switchOptionOnDirection(direction)
                    if direction==KEYS.DIRECTIONS.UP or direction==KEYS.DIRECTIONS.DOWN then
                        return
                    end
                    return UI.Options.switchOptionOnDirection(self,direction)
                end
                local spellcards=SpellcardCollection.byStage[stageKey] or {}
                local stageText=UI.Text{
                    text=Localize{'ui','SPELL_PRACTICE','stages',stageKey},
                    fontSize=32,color={1,1,1,1},
                    x=0,y=-20,autoSize=true
                }
                horizontalOptions.stageText=stageText
                horizontalOptions:addOption(stageText)
                local spellcardSwitcher=UI.Switcher{
                    x=20,y=120,width=100,height=20,
                    preview=5,
                    arrange=function(_,index)
                        return 0,index*20
                    end,
                    optionConstructor=function(_,spellcardIndex)
                        local item=spellcards[spellcardIndex]
                        if not item then return nil end
                        local text=Localize{'ui','SPELL_PRACTICE','spellcard',index=spellcardIndex}
                        local base=UI.Base()
                        local spellcardText=UI.Text{
                            text=text,
                            fontSize=20,color={1,1,1,1},
                            x=0,y=0,parent=base,
                        }
                        return base
                    end,
                }
                horizontalOptions:addOption(spellcardSwitcher)
                local difficultyOptions
                local currentSpellcard
                updateOptions=function()
                    difficultyOptions:clearOptions()
                    item=spellcards[spellcardSwitcher.currentOptionIndex]
                    if not item then return end
                    for i,diff in ipairs(G.CONSTANTS.STAGE_TO_DIFFICULTIES[stageKey]) do
                        if item.difficulties[diff] then
                            local status=2 -- 1, 2, 3 means locked, unlocked, cleared respectively
                            local historyTable=G.save.spellcardHistory[item.key][diff][shotType]
                            if historyTable.practice.cleared or historyTable.ingame.cleared then
                                status=3
                            elseif not historyTable.ingame.unlocked then
                                status=1
                            end
                            local color=({{0.5,0.5,0.5,1},{1,1,1,1},{0.75,0.75,1,1}})[status]
                            local base=UI.Base{width=500,height=40}
                            local diffText=diff
                            local difficultyText=UI.Text{text=diffText,fontSize=20,color=color,boldColor={0,0,0,1},x=0,y=0,width=200,parent=base}
                            local spellcardName=status>=2 and Localize{'spellcards',item.key, diff,'name'} or Localize{'spellcards','UNKNOWN', diff,'name'}
                            local spellcardNameText=UI.Text{text=spellcardName,fontSize=20,color=color,boldColor={0,0,0,1},x=500,y=0,width=400,align="right",parent=base}
                            local historyText=Localize{'ui','SPELL_PRACTICE','spellcardHistory',
                                ingamePass=historyTable.ingame.passes,
                                ingameTries=historyTable.ingame.tries,
                                practicePass=historyTable.practice.passes,
                                practiceTries=historyTable.practice.tries,
                            }
                            local historyUIText=UI.Text{text=historyText,fontSize=16,color=color,boldColor={0,0,0,1},x=500,y=20,width=400,align="right",parent=base}
                            difficultyOptions:addOption(base)
                        end
                    end
                end
                difficultyOptions=UI.Options{
                    x=140,y=40,width=500,height=250,
                    container=UI.Arranger{
                        arrange=function(self,index)
                            return 0,(index-1)*70
                        end
                    },extraUpdates={function(self)
                        local latestSpellcard=spellcards[spellcardSwitcher.currentOptionIndex]
                        if latestSpellcard~=currentSpellcard then
                            currentSpellcard=latestSpellcard
                            updateOptions()
                        end
                    end},
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
                return horizontalOptions
            end
        }
    end,
    enter=function(self)
        base.frame=0
        if updateOptions then updateOptions() end -- to refresh the options when entering the state, in case there are changes in spellcard history after playing a stage or practice
    end,
    update=function(self,dt)
        self.backgroundPattern:update(dt)
        base:updateHierarchy()
        if isPressed('x') or isPressed('escape')then
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