local base=UI.Base()
local charWidth=10
local sortByIndex=1
local chosenValues
local scoreLines
local function setScoreLines()
    scoreLines=PlayerScoreManager:getSorted(PlayerScoreManager.SORT_BY[sortByIndex],chosenValues[1],chosenValues[2],chosenValues[3])
end
return {
    base=base,
    init=function(self)
        local titleText=base:child(
            UI.Text{
                text=Localize{'ui','MAIN_MENU',"PLAYER_DATA"},
                fontSize=48,color={1,1,1,1},
                x=100,y=60,
            }
        )
        local pressCText=UI.Text{
            text=Localize{'ui','SAVE_SCORE_ENTER_NAME',"pressC",key=KEYS.SPECIAL},
            fontSize=24,color={1,1,1,1},
            x=100,y=120,parent=base
        }
        local optionsUI=base:child(
            UI.Options{
                x=100,y=160,
                container=UI.Arranger{
                    arrange=function(self,index)
                        index=index-1
                        local value=index*30
                        if index>3 then
                            value=index*20+30
                        end
                        return 0,value*(1-math.exp(-base.frame/15))
                    end
                },keysToDirections={
                    [KEYS.DIRECTIONS.UP] = 'up',
                    [KEYS.DIRECTIONS.DOWN] = 'down',
                },cursor=UI.Cursor{fluctuateRatio=0.03}
            }
        )
        local function createOption(switcher,replaceIndex)
            local previewDecayRadius=switcher and switcher.previewDecayRadius or 0
            local option=UI.Base{width=600,height=30,
                events={
                    [UI.EVENTS.FOCUS]=function(self)
                        SFX:play('select',false)
                    end,
                },
                extraUpdates={
                    function(self)
                        if not switcher then
                            return
                        end
                        local lerpRatio=0.1
                        if self.focused then
                            switcher.previewDecayRadius=math.lerp(switcher.previewDecayRadius,previewDecayRadius,lerpRatio)
                        else
                            switcher.previewDecayRadius=math.lerp(switcher.previewDecayRadius,0,lerpRatio)
                        end
                    end
                },}
            if switcher then
                switcher.previewDecayRadius=0
                option:child(switcher)
            end
            if replaceIndex then
                optionsUI:replaceOption(replaceIndex,option)
            else
                optionsUI:addOption(option)
            end
            return option
        end
        chosenValues={G.CONSTANTS.SHOT_TYPES[1],G.CONSTANTS.DIFFICULTIES[1],'ALL'}
        setScoreLines()
        local possibleValues={
            G.CONSTANTS.SHOT_TYPES,
            G.CONSTANTS.DIFFICULTIES,
            function ()
                local values=copyTable(G.CONSTANTS.DIFFICULTIES_TO_STAGES[chosenValues[2] or G.CONSTANTS.DIFFICULTIES[1]])
                if #values>1 then
                    table.insert(values,1,'ALL')
                else
                    return {'ALL',stage=values[1]}
                end
                return values
            end
        }
        local function createSwitcher(i)
            local switcher=UI.Switcher{
                preview=i==3 and 1 or 2,currentOptionIndex=0,
                arrange=function(_,index)
                    return index*(i==3 and 200 or 100),0
                end,
                optionConstructor=function (self, optionIndex)
                    local values=possibleValues[i]
                    if type(values)=='function'then
                        values=values()
                    end
                    if #values==1 then
                        if optionIndex~=0 then
                            return
                        end
                    end
                    local value=values[optionIndex%#values+1]
                    local text=value
                    if i==1 then
                        text=Localize{'ui','SPELL_PRACTICE','shotTypes',value}
                    end
                    if i==3 then
                        if value=='ALL' then
                            if #values>1 then
                                text=Localize{'ui','PLAYER_DATA','ALL'}
                            else
                                text=Localize{'ui','SPELL_PRACTICE','stages',values.stage}
                            end
                        else
                            local stage=Localize{'ui','SPELL_PRACTICE','stages',value}
                            text=Localize{'ui','PLAYER_DATA','practice',stage=stage}
                        end
                    end
                    local textUI=UI.Text{width=600,height=50,align='center',text=text,color={1,1,1,1},toggleX=false,fontSize=24}
                    return textUI
                end,
                events={
                    [UI.EVENTS.SWITCHED]=function(_self,args)
                        local index=args.index
                        local values=possibleValues[i]
                        if type(values)=='function'then
                            values=values()
                        end
                        local value=values[index%#values+1]
                        chosenValues[i]=value
                        if i==2 then
                            local switcher=createSwitcher(3)
                            createOption(switcher,3)
                        end
                        setScoreLines()
                    end
                }
            }
            return switcher
        end
        for i=1,#possibleValues do
            local switcher=createSwitcher(i)
            createOption(switcher)
        end
        -- player score rows
        for i=1,PlayerScoreManager.MAX do
            local scoreLine=UI.Text.MonoText{
                text='',updateText=function (self)
                    return PlayerScoreManager:getDisplayLine(i,scoreLines[i],PlayerScoreManager.SORT_BY[sortByIndex])
                end,color={1,1,1,1},autoSize=true,charWidth=charWidth,fontName=Fonts.en_us
            }
            optionsUI:addOption(scoreLine)
        end
    end,
    enter=function(self)
        self:replaceBackgroundPatternIfNot(BackgroundPattern.MainMenuTesselation)
        base.frame=0
    end,
    update=function(self,dt)
        self.backgroundPattern:update(dt)
        base:updateHierarchy()
        if isPressed('x') or isPressed('escape')then
            SFX:play('select',false)
            self:saveData()
            self:switchState(self.STATES.MAIN_MENU)
        end
        if isPressed(KEYS.SPECIAL) then
            SFX:play('select',true)
            sortByIndex=sortByIndex%#PlayerScoreManager.SORT_BY+1
            setScoreLines()
        end
    end,
    draw=function(self)
    end,
    drawText=function(self)
        base:drawTextHierarchy()
    end
}