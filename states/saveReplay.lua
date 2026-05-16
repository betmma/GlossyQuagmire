local G=...
---@class _pauseBase:UIBase
local base=UI.Base()
local chosenSlot=1
local charWidth=10
return {
    base=base,
    init=function(self)
        local overlay1=UI.Panel{parent=base,x=0,y=0,width=WINDOW_WIDTH,height=WINDOW_HEIGHT,fillColor={1,1,1,0.5},edgeWidth=0}
        local overlay2=UI.Panel{parent=base,x=0,y=0,width=WINDOW_WIDTH,height=WINDOW_HEIGHT,fillColor={0,0,0,0.5},edgeWidth=0}
        transBase=UI.Base{parent=base}
        base.fade=transBase
        local titleText=transBase:child(
            UI.Text{
                text=Localize{'ui','GAME_END',"saveReplay",'normal'},
                fontSize=48,color={1,1,1,1},
                x=100,y=30,
            }
        )
        local replaysSwitcher=UI.Switcher{
            x=(WINDOW_WIDTH-charWidth*ReplayManager.OVERALL_WIDTH)/2,y=70,parent=transBase,arrange=function (self, index)
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
                                G.UIDEF.SAVE_REPLAY.chosenSlot=slot -- saveReplayEnterName needs this
                            end,
                            [UI.EVENTS.SELECT]=function(_)
                                SFX:play('select')
                                G:switchState(G.STATES.SAVE_REPLAY_ENTER_NAME)
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
        base.frame=0
    end,
    chosen=1,
    update=function(self,dt)
        self.backgroundPattern:update(dt)
        base:updateHierarchy()
        if isPressed('x') or isPressed('escape')then
            SFX:play('select')
            G:switchState(G.STATES.GAME_END)
        end
    end,
    options={},
    draw=function(self)
        G.CONSTANTS.DRAW(self,'IN_GAME') -- gameplay graphics as background. need to pass IN_GAME or :drawHierarchy() will be called on current state PAUSE instead of IN_GAME, and lives and bombs ui sprites will be missing
        base:drawHierarchy() -- should have nothing to draw, as it would be below half transparent overlay. if needed can change draw order in some way??
    end,
    drawText=function(self)
        G.UIDEF.IN_GAME.drawText(G) -- gameplay texts
        base:drawTextHierarchy() -- will add a half transparent overlay before drawing pause ui
    end
}