local G=...
---@class _pauseBase:UIBase
local base=UI.Base()
local chosenSlot=1
local charWidth=10
local keyboard={
    {'A',"B","C","D","E","F","G","H","I","J","K","L","M"},
    {"N","O","P","Q","R","S","T","U",'V',"W","X","Y","Z"},
    {'a',"b","c","d","e","f","g","h","i","j","k","l","m"},
    {"n","o","p","q","r","s","t","u",'v',"w","x","y","z"},
    {"0","1","2","3","4","5","6","7",'8',"9","+","-","="},
    {".",",","!","?","@",":",";","[",']',"(",")","_","/"},
    {"{","}","|","~","^","#","$","%",'&',"*"," ","BS","END"},
}
return {
    base=base,
    init=function(self)
        local overlay1=UI.Panel{parent=base,x=0,y=0,width=WINDOW_WIDTH,height=WINDOW_HEIGHT,fillColor={1,1,1,0.5},edgeWidth=0}
        local overlay2=UI.Panel{parent=base,x=0,y=0,width=WINDOW_WIDTH,height=WINDOW_HEIGHT,fillColor={0,0,0,0.5},edgeWidth=0}
        local transBase=UI.Base{parent=base}
        base.fade=transBase
        local excludeReplayLineBase=UI.Base{parent=transBase}
        base.fadeWithoutReplayLine=excludeReplayLineBase
        local titleText=UI.Text{
            text=Localize{'ui','SAVE_REPLAY_ENTER_NAME',"enterName"},
            fontSize=48,color={1,1,1,1},
            x=100,y=30,parent=excludeReplayLineBase
        }
        local replayLine=UI.Text.MonoText{
            x=(WINDOW_WIDTH-charWidth*ReplayManager.OVERALL_WIDTH)/2,fontName=Fonts.en_us,
            text='',updateText=function ()
                return ReplayManager:getDisplayLineOfReplay(G.runInfo.pendingReplay,G.UIDEF.SAVE_REPLAY.chosenSlot)
            end,color={1,1,1,1},autoSize=true,charWidth=charWidth,parent=transBase,extraUpdates={function (self)
                local baseY=90+20*((G.UIDEF.SAVE_REPLAY.chosenSlot-1)%25)
                local aimY=100
                local ratio=1-math.exp(-base.frame/20)
                self.y=math.lerp(baseY,aimY,Event.sineOProgressFunc(ratio))
            end}}
        local keyboardOptions=UI.Options{parent=excludeReplayLineBase,x=140,y=150}
        for i,row in ipairs(keyboard) do
            for j,char in ipairs(row) do
                local fontSize=24-(#char-1)*4
                local fontName
                local text=char
                if text==' ' then -- clearer display for space
                    text='▯'
                    fontName=Fonts.zh_cn
                end
                local key=UI.Text{
                    text=text,x=(j-1)*40,y=(i-1)*40,color={1,1,1,1},fontSize=fontSize,fontName=fontName,width=20,align='center',autoSize=true,
                    events={
                        [UI.EVENTS.SELECT]=function(self)
                            local name=G.runInfo.pendingReplay.data.name
                            if char=='END' then
                                if #name==0 then
                                    SFX:play('cancel')
                                    return
                                end
                                SFX:play('select',false)
                                ReplayManager:saveToSlot(G.runInfo.pendingReplay,G.UIDEF.SAVE_REPLAY.chosenSlot)
                                G.save.defaultName=G.runInfo.pendingReplay.data.name
                                G:saveData()
                                G:switchState(G.STATES.SAVE_REPLAY)
                            elseif char=='BS' then
                                if #name==0 then
                                    SFX:play('cancel')
                                    return
                                end
                                SFX:play('select',false)
                                G.runInfo.pendingReplay.data.name = name:sub(1, #name - 1)
                            else -- normal char
                                if #name>=ReplayManager.MAX_NAME_LENGTH then
                                    SFX:play('cancel')
                                    return
                                end
                                SFX:play('select',false)
                                G.runInfo.pendingReplay.data.name = name .. char
                            end
                        end,
                    }
                }
                keyboardOptions:addOption(key)
            end
        end
    end,
    enter=function(self)
        base.frame=0
    end,
    chosen=1,
    update=function(self,dt)
        base:updateHierarchy()
        if isPressed('x') or isPressed('escape')then
            SFX:play('select',false)
            G:switchState(G.STATES.SAVE_REPLAY)
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