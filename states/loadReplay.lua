local G=...

local base=UI.Base()
local chosenSlot=1
local charWidth=10
return {
    base=base,
    init=function(self)
        local titleText=base:child(
            UI.Text{
                text=Localize{'ui','MAIN_MENU',"REPLAY"},
                fontSize=48,color={1,1,1,1},
                x=100,y=30,
            }
        )
        local replaysSwitcher=UI.Switcher{
            x=(WINDOW_WIDTH-charWidth*ReplayManager.OVERALL_WIDTH)/2,y=70,parent=base,arrange=function (self, index)
                return index*800,0
            end,
            optionConstructor=function(self, optionIndex)
                if optionIndex<1 or optionIndex>ReplayManager.PAGES then
                    return nil
                end
                local rows=UI.Options{arrange=function(self, index)
                    return 0,index*20
                end,keysToDirections={
                    [KEYS.DIRECTIONS.UP] = 'up',
                    [KEYS.DIRECTIONS.DOWN] = 'down',
                },cursor=UI.Cursor{fluctuateRatio=0.03}}
                local num=ReplayManager.REPLAY_NUM_PER_PAGE
                local chosenSlotRef=chosenSlot
                for slot=num*(optionIndex-1)+1,optionIndex*num do
                    local replayLine=UI.Text.MonoText{
                        text='',updateText=function ()
                            return ReplayManager:getDisplayLineAtSlot(slot)
                        end,color={1,1,1,1},autoSize=true,charWidth=charWidth,fontName=Fonts.en_us,
                        events={
                            [UI.EVENTS.FOCUS]=function(_)
                                chosenSlot=slot
                            end,
                            [UI.EVENTS.SELECT]=function(_)
                                local canRun=ReplayManager:runReplayAtSlot(slot)
                                if canRun then
                                    SFX:play('select',false)
                                else
                                    SFX:play('cancel')
                                end
                            end,
                    },}
                    rows:addOption(replayLine)
                    if slot%num==chosenSlotRef%num then
                        rows:switchOption(replayLine,true,false)
                    end
                end
                return rows
            end
        }
    end,
    enter=function(self)
        self:replaceBackgroundPatternIfNot(BackgroundPattern.MainMenuTesselation)
        BGM:play('title')
    end,
    chosen=1,
    update=function(self,dt)
        self.backgroundPattern:update(dt)
        if isPressed('x') or isPressed('escape')then
            SFX:play('select',false)
            self:switchState(self.STATES.MAIN_MENU)
            return
        end
        base:updateHierarchy()
    end,
    options={},
    draw=function(self)
    end,
    drawText=function(self)
        base:drawTextHierarchy()
    end,
}