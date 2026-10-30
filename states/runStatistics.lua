
---@class _pauseBase:UIBase
local base=UI.Base()
local Statistics=require"statistics"
---@type UILineGraph
local lineGraph
return {
    base=base,
    init=function(self)
        local overlay1=UI.Panel{parent=base,x=0,y=0,width=WINDOW_WIDTH,height=WINDOW_HEIGHT,fillColor={1,1,1,0.5},edgeWidth=0}
        local overlay2=UI.Panel{parent=base,x=0,y=0,width=WINDOW_WIDTH,height=WINDOW_HEIGHT,fillColor={0,0,0,0.5},edgeWidth=0}
        transBase=UI.Base{parent=base}
        base.fade=transBase
        lineGraph=Statistics.UILineGraph{parent=transBase,x=50,y=50,width=700,height=500}
    end,
    enter=function(self)
        -- base.frame=0
        lineGraph:setData(Statistics.GetData())
    end,
    update=function(self,dt)
        base:updateHierarchy()
        if isPressed('x') or isPressed('escape')then
            SFX:play('select',false)
            self:switchState(self.STATES.GAME_END)
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