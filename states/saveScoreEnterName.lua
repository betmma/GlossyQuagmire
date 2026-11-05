---@type G
local G=...
---@class _pauseBase:UIBase
local base=UI.Base()
local charWidth=10
local keyboardOptions
return {
    base=base,
    init=function(self)
        local overlay1=UI.Panel{parent=base,x=0,y=0,width=WINDOW_WIDTH,height=WINDOW_HEIGHT,fillColor={1,1,1,0.5},edgeWidth=0}
        local overlay2=UI.Panel{parent=base,x=0,y=0,width=WINDOW_WIDTH,height=WINDOW_HEIGHT,fillColor={0,0,0,0.5},edgeWidth=0}
        local transBase=UI.Base{parent=base}
        base.fade=transBase
        local titleText=UI.Text{
            text=Localize{'ui','SAVE_REPLAY_ENTER_NAME',"enterName"},
            fontSize=48,color={1,1,1,1},
            x=100,y=30,parent=transBase
        }
        local pressCText=UI.Text{
            text='',updateText=function (self)
                if #G.currentUI.any.result>1 then
                    return Localize{'ui','SAVE_SCORE_ENTER_NAME',"pressC",key=KEYS.SPECIAL}
                end
                return ''
            end,
            fontSize=24,color={1,1,1,1},
            x=100,y=100,parent=transBase
        }
        local scoreLine=UI.Text.MonoText{
            x=WINDOW_WIDTH/2,y=200,fontName=Fonts.en_us,
            text='',updateText=function ()
                local chosenResult=G.currentUI.any.result[G.currentUI.any.chosen]
                return PlayerScoreManager:getDisplayLine(chosenResult.rank,PlayerScoreManager.pendingScoreLine,chosenResult.sortBy)
            end,color={1,1,1,1},autoSize=true,charWidth=charWidth,parent=transBase,align="center"}
        keyboardOptions=UI.Keyboard{parent=transBase,x=140,y=250,textChangeCallBack=function (newText)
            PlayerScoreManager.pendingScoreLine.name=newText
        end,endCallBack=function ()
            PlayerScoreManager:addAndEvictScoreLine(PlayerScoreManager.pendingScoreLine)
            G.save.defaultName=PlayerScoreManager.pendingScoreLine.name
            G:saveData()
            G:switchState(G.STATES.SAVE_SCORE)
        end}
        keyboardOptions.text=PlayerScoreManager.pendingScoreLine.name
    end,
    enter=function(self)
        base.frame=0
        if keyboardOptions then
            keyboardOptions.text=PlayerScoreManager.pendingScoreLine.name
        end
    end,
    update=function(self,dt)
        base:updateHierarchy()
        if isPressed(KEYS.SPECIAL) then
            SFX:play('select',true)
            G.currentUI.any.chosen=G.currentUI.any.chosen%#G.currentUI.any.result+1
        end
    end,
    any={result={},chosen=1},
    draw=function(self)
        G.CONSTANTS.DRAW(self,'IN_GAME')
        base:drawHierarchy()
    end,
    drawText=function(self)
        G.UIDEF.IN_GAME.drawText(G) -- gameplay texts
        base:drawTextHierarchy() -- will add a half transparent overlay before drawing pause ui
    end
}