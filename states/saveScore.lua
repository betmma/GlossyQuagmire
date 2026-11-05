---@type G
local G=...
---@class _pauseBase:UIBase
local base=UI.Base()
local charWidth=10
local scoreLines
return {
    base=base,
    init=function(self)
        local overlay1=UI.Panel{parent=base,x=0,y=0,width=WINDOW_WIDTH,height=WINDOW_HEIGHT,fillColor={1,1,1,0.5},edgeWidth=0}
        local overlay2=UI.Panel{parent=base,x=0,y=0,width=WINDOW_WIDTH,height=WINDOW_HEIGHT,fillColor={0,0,0,0.5},edgeWidth=0}
        local transBase=UI.Base{parent=base}
        base.fade=transBase
        local titleText=UI.Text{
            text='',updateText=function (self)
                local any=G.UIDEF.SAVE_SCORE_ENTER_NAME.any
                local sortBy=any.result[any.chosen].sortBy
                return Localize{'ui','SAVE_SCORE',"sortBy",sortBy}
            end,
            fontSize=48,color={1,1,1,1},
            x=100,y=30,parent=transBase
        }
        local pressCText=UI.Text{
            text='',updateText=function (self)
                if #G.UIDEF.SAVE_SCORE_ENTER_NAME.any.result>1 then
                    return Localize{'ui','SAVE_SCORE_ENTER_NAME',"pressC",key=KEYS.SPECIAL}
                end
                return ''
            end,
            fontSize=24,color={1,1,1,1},
            x=100,y=100,parent=transBase
        }
        local scoreLinesUI=UI.Options{x=(WINDOW_WIDTH-charWidth*PlayerScoreManager.OVERALL_WIDTH)/2,y=200,
        arrange=function(self, index)
            return 0,index*20
        end,keysToDirections={
            [KEYS.DIRECTIONS.UP] = 'up',
            [KEYS.DIRECTIONS.DOWN] = 'down',
        },cursor=UI.Cursor{fluctuateRatio=0.03},parent=transBase}
        for i=1,PlayerScoreManager.MAX do
            local scoreLine=UI.Text.MonoText{
                text='',updateText=function (self)
                    local any=G.UIDEF.SAVE_SCORE_ENTER_NAME.any
                    local sortBy=any.result[any.chosen].sortBy
                    return PlayerScoreManager:getDisplayLine(i,scoreLines[i],sortBy)
                end,color={1,1,1,1},autoSize=true,charWidth=charWidth,fontName=Fonts.en_us,extraUpdates={function (self)
                    local any=G.UIDEF.SAVE_SCORE_ENTER_NAME.any
                    local index=any.result[any.chosen].rank
                    if i==index then
                        self.color=math.lerpTable(self.color,{1,1,0,1},0.2)
                    else
                        self.color=math.lerpTable(self.color,{1,1,1,1},0.2)
                    end
                end}
            }
            scoreLinesUI:addOption(scoreLine)
        end
    end,
    enter=function(self)
        base.frame=0
        local any=G.UIDEF.SAVE_SCORE_ENTER_NAME.any
        local sortBy=any.result[any.chosen].sortBy
        scoreLines=PlayerScoreManager:getSorted(sortBy)
    end,
    update=function(self,dt)
        base:updateHierarchy()
        if isPressed(KEYS.SELECT) or isPressed('x') or isPressed('escape')then
            SFX:play('select')
            G:switchState(G.STATES.GAME_END)
        end
        if isPressed(KEYS.SPECIAL) then
            SFX:play('select',true)
            local any=G.UIDEF.SAVE_SCORE_ENTER_NAME.any
            any.chosen=any.chosen%#any.result+1
            local sortBy=any.result[any.chosen].sortBy
            scoreLines=PlayerScoreManager:getSorted(sortBy)
        end
    end,
    draw=function(self)
        G.CONSTANTS.DRAW(self,'IN_GAME')
        base:drawHierarchy()
    end,
    drawText=function(self)
        G.UIDEF.IN_GAME.drawText(G) -- gameplay texts
        base:drawTextHierarchy() -- will add a half transparent overlay before drawing pause ui
    end
}