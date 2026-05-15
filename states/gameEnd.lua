---@class _pauseBase:UIBase
local base=UI.Base()
local transBase
return {
    base=base,
    init=function(self)
        -- entering from IN_GAME, fade in for everything including overlays
        transBase=UI.Base{parent=base}
        base.fadeAll=transBase
        local overlay1=UI.Panel{parent=transBase,x=0,y=0,width=WINDOW_WIDTH,height=WINDOW_HEIGHT,fillColor={1,1,1,0.5},edgeWidth=0}
        local overlay2=UI.Panel{parent=transBase,x=0,y=0,width=WINDOW_WIDTH,height=WINDOW_HEIGHT,fillColor={0,0,0,0.5},edgeWidth=0}
        -- switching to saveReplay. since it also has overlay, only fade out texts, excluding overlays
        local transBase2=UI.Base{parent=base}
        base.fade=transBase2
        local x0=100
        local xBase=UI.Base{parent=transBase2,x=x0}
        local titleText=UI.Text{
            text='',
            fontSize=48,color={1,1,1,1},
            x=0,y=30,parent=xBase,updateText=function (self)
                return Localize{'ui','GAME_END',G.runInfo.gameType==G.CONSTANTS.GAME_TYPES.FULL_GAME and 'failed' or 'practiceEnd'} -- change based on gameType (lose, practice ends ...)
            end
        }
        local optionsUI=UI.Options{
            x=5,y=300,parent=xBase,container=UI.Arranger{arrange=function(self,index)
                local i=(index-1)*(1-math.exp(-base.frame/15))
                return i*5,i*50
            end}
        }
        local options={
            {key='saveReplay',func=function()
                SFX:play('select',true)
                G:switchState(G.STATES.SAVE_REPLAY)
            end},
            {key='restart',func=function()
                SFX:play('select',true)
                G:switchState(G.STATES.IN_GAME)
                G:restart()
            end},
            {key='exit',func=function()
                SFX:play('select',true)
                G:switchState(G.runInfo.exitToState)
            end}
        }
        for i,option in ipairs(options) do
            optionsUI:addOption(UI.Text{
                text=Localize{'ui','GAME_END',option.key},fontSize=24,color={1,1,1,1},autoSize=true,
                events={
                    [UI.EVENTS.SELECT]=option.func
                }
            })
        end
    end,
    enter=function(self,lastState)
        base.frame=0
        -- if transBase and lastState==G.STATES.IN_GAME then
        --     transBase.extraUpdates[1](transBase) -- without this the first frame in pause menu would have old transparency
        -- end
    end,
    update=function(self,dt)
        base:updateHierarchy()
    end,
    draw=function(self)
        G.CONSTANTS.DRAW(self,'IN_GAME') -- gameplay graphics as background. need to pass IN_GAME or :drawHierarchy() will be called on current state PAUSE instead of IN_GAME, and lives and bombs ui sprites will be missing
        base:drawHierarchy() -- should have nothing to draw, as it would be below half transparent overlay. if needed can change draw order in some way??
    end,
    drawText=function(self)
        G.UIDEF.IN_GAME.drawText(G) -- gameplay texts
        base:drawTextHierarchy() -- will add a half transparent overlay before drawing pause ui
    end
}