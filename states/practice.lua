local base=UI.Base()
---@alias segmentType 'notReached'|'notMatch'|'available' notReached means player hasn't met this segment in game. notMatch means difficulty or shotType doesn't match the segment's requirement. available means can enter
---@return segmentType
local function getSegmentType(stageKey,segmentKey)
    if not G.save.reachedSegments[stageKey][segmentKey] then
        return 'notReached'
    end
    local segmentData=SegmentsData.bySegment[segmentKey]
    local difficulty=G.runInfo.difficulty
    local shotType=G.runInfo.shotType
    if not segmentData.difficulties[difficulty] or not segmentData.players[G.CONSTANTS.SHOT_TYPE_TO_PLAYER[shotType]] then
        return 'notMatch'
    end
    return 'available'
end
local stageSwitcher,segmentSwitcher,modeSwitcher
local function segmentSwitcherRemake()
    segmentSwitcher.currentOptionIndex=1
    segmentSwitcher:remakeOptions()
    segmentSwitcher.transparency=0
end
local modes={
    {onlyRunOneSegment=true,localizeKey='segment'},
    {onlyRunOneSegment=false,localizeKey='stage'},
}
local function enter()
    local stageKey=G.CONSTANTS.STAGE_KEYS[stageSwitcher.currentOptionIndex]
    local segment=SegmentsData.byStage[stageKey][segmentSwitcher.currentOptionIndex]
    local mode=modes[modeSwitcher.currentOptionIndex].onlyRunOneSegment
    local segmentType=getSegmentType(stageKey,segment)
    if segmentType~='available' then
        SFX:play('cancel')
        if not DEV_MODE then -- dev can bypass
            return
        end
    else
        SFX:play('select')
    end
    G:resetRunInfo(G.CONSTANTS.GAME_TYPES.STAGE_PRACTICE,G.runInfo.difficulty,G.runInfo.shotType,G.STATES.PRACTICE) -- difficulty and shotType are already set in chooseDifficulty and choosePlayer
    G:switchState(G.STATES.IN_GAME)
    StageManager:load(stageKey,segment,mode,'end')
end
return {
    base=base,
    init=function(self)
        local leftX=50
        local titleText=base:child(
            UI.Text{
                text=Localize{'ui','MAIN_MENU',"PRACTICE"},
                fontSize=48,color={1,1,1,1},
                x=leftX+50,y=60,
            }
        )
        local segmentTitleText=base:child(
            UI.Text{
                text=Localize{'ui','PRACTICE','headers','segment'},
                fontSize=28,color={1,1,1,1},
                x=leftX*2+130,y=170,
            }
        )
        local modeTitleText=base:child(
            UI.Text{
                text=Localize{'ui','PRACTICE','headers','mode'},
                fontSize=28,color={1,1,1,1},
                x=leftX*2+400,y=170,
            }
        )
        -- compared to spell practice, since shotType is determined earlier, left and right aren't occupied, so simple horizontal Option -> vertical switcher is enough. first column is same wheel stage switcher as spell practice. second column is segment switcher, third column is only run one segment switcher. second column's content need to change on stage change.
        local optionBaseX=leftX
        local optionBaseY=300
        local optionHeight=40
        local previewCircleRadius=800
        local anglePerOption=math.asin(optionHeight/previewCircleRadius)
        stageSwitcher=UI.Switcher{
            parent=base,
            x=optionBaseX,y=0,
            preview=2,autoSize=true,
            arrange=function(_,index)
                local angle=anglePerOption*index
                return previewCircleRadius*math.cos(angle),previewCircleRadius*math.sin(angle)
            end,
            optionConstructor=function (self, optionIndex)
                local stageKey=G.CONSTANTS.STAGE_KEYS[optionIndex]
                if not stageKey or not SegmentsData.byStage[stageKey] then return nil end
                local stageText=UI.Text{
                    text=Localize{'ui','SPELL_PRACTICE','stages',stageKey},
                    fontSize=32,color={1,1,1,1},
                    autoSize=true,
                }
                return stageText
            end
        }
        segmentSwitcher=UI.Switcher{
            parent=base,
            x=leftX+130,y=optionHeight*0.1,extraUpdates={function(self)
                self.transparency=math.lerp(self.transparency,1,0.1)
            end,},
            preview=3,autoSize=true,
            arrange=function(_,index)
                return 0,optionHeight*0.8*index
            end,
            optionConstructor=function (self, optionIndex)
                local stageKey=G.CONSTANTS.STAGE_KEYS[stageSwitcher.currentOptionIndex]
                local segmentKey=SegmentsData.byStage[stageKey][optionIndex]
                if not segmentKey then return nil end
                local segmentType=getSegmentType(stageKey,segmentKey)
                local color
                local textKey=segmentKey
                if segmentType=='notReached' then
                    color={0.5,0.5,0.5,1}
                    textKey='notReached'
                elseif segmentType=='notMatch' then
                    color={0.5,0.5,0.5,1}
                else
                    color={1,1,1,1}
                end
                local segmentText=UI.Text{
                    text=Localize{'ui','PRACTICE','segments',textKey,'name'},
                    fontSize=24,color=color,
                    autoSize=true,
                }
                return segmentText
            end
        }
        modeSwitcher=UI.Switcher{
            parent=base,
            x=leftX+400,y=optionHeight*0.1,
            preview=1,autoSize=true,
            arrange=function(_,index)
                return 0,optionHeight*0.8*index
            end,
            optionConstructor=function (self, optionIndex)
                local mode=modes[optionIndex]
                if not mode then return nil end
                local modeText=UI.Text{
                    text=Localize{'ui','PRACTICE','modes',mode.localizeKey},
                    fontSize=24,color={1,1,1,1},
                    autoSize=true,
                }
                return modeText
            end,
        }

        local horizontalOptions=UI.Options{
            parent=base,x=leftX,y=optionBaseY,
            container=UI.Base(),
            keysToDirections={
                [KEYS.DIRECTIONS.LEFT] = 'left',
                [KEYS.DIRECTIONS.RIGHT] = 'right'
            }
        }
        horizontalOptions:addOption(stageSwitcher)
        horizontalOptions:addOption(segmentSwitcher)
        horizontalOptions:addOption(modeSwitcher)
    end,
    enter=function(self,fromState)
        self:replaceBackgroundPatternIfNot(BackgroundPattern.MainMenuTesselation)
        BGM:play('title')
        base.frame=0
        if stageSwitcher then -- reached state and shotType may have changed, so must remake
            segmentSwitcherRemake()
        end
    end,
    update=function(self,dt)
        self.backgroundPattern:update(dt)
        base:updateHierarchy()
        if isPressed('escape')or isPressed(KEYS.CANCEL)then
            SFX:play('select')
            self:switchState(self.STATES.CHOOSE_PLAYER)
        end
        if isPressed(KEYS.SELECT)then -- options send EVENT.SELECT to selected option not itself, while i want it to trigger no matter which option is selected, so check here instead of using EVENT.SELECT
            enter()
        end
    end,
    draw=function(self)
    end,
    drawText=function(self)
        base:drawTextHierarchy()
    end
}
