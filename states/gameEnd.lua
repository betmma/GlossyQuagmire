---@class _pauseBase:UIBase
local base=UI.Base()
local playingReplay
local remakeOptions
return {
    base=base,
    init=function(self)
        -- entering from IN_GAME, fade in for everything including overlays
        local transBase=UI.Base{parent=base}
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
                local key
                if playingReplay then
                    key='replayEnd'
                elseif G.runInfo.gameType==G.CONSTANTS.GAME_TYPES.FULL_GAME then
                    if G.runInfo.lives<0 then
                        key='failed'
                    else
                        key='cleared'
                    end
                else
                    key='practiceEnd'
                end
                return Localize{'ui','GAME_END',key} -- change based on gameType (lose, practice ends ...)
            end
        }
        local optionsUI=UI.Options{
            x=5,y=300,parent=xBase,container=UI.Arranger{arrange=function(self,index)
                local i=(index-1)*(1-math.exp(-base.frame/15))
                return i*5,i*50
            end}
        }
        local options={
            {key='continue',func=function()
                if G.runInfo.remainingContinues<=0 then
                    SFX:play('cancel')
                    return
                end
                SFX:play('select')
                G.runInfo.remainingContinues=G.runInfo.remainingContinues-1
                G.runInfo.continued=true
                local startResources=G.CONSTANTS.START_LIVES_AND_BOMBS[G.runInfo.gameType]
                G.runInfo.lives=startResources.lives
                G.runInfo.bombs=startResources.bombs
                G.runInfo.score=0
                G.runInfo.grazes=0
                G:switchState(G.STATES.IN_GAME)
            end},
            {key='saveReplay',func=function()
                if playingReplay or G.runInfo.continued then
                    SFX:play('cancel')
                    return
                end
                SFX:play('select')
                G:switchState(G.STATES.SAVE_REPLAY)
            end},
            {key='restart',func=function()
                SFX:play('select')
                G:switchState(G.STATES.IN_GAME)
                G:restart()
            end},
            {key='exit',func=function()
                SFX:play('select')
                G:switchState(G.runInfo.exitToState)
            end}
        }
        -- used to store whether it contains continue option. remakeOption will save and check lastCallFlag. if it's the same, can skip remake to keep the cursor position. if different clear all options and remake them.
        local lastCallFlag
        remakeOptions=function()
            local newFlag=G.runInfo.gameType==G.CONSTANTS.GAME_TYPES.FULL_GAME and not playingReplay
            if newFlag==lastCallFlag then
                return
            end
            lastCallFlag=newFlag
            optionsUI:clearOptions()
            for i,option in ipairs(options) do
                if option.key=='continue' then
                    if not newFlag then
                        goto continue
                    end
                end
                optionsUI:addOption(UI.Text{
                    text='',fontSize=24,color={1,1,1,1},autoSize=true,
                    updateText=function (self)
                        if option.key=='continue' then
                            return Localize{'ui','GAME_END',option.key,continues=G.runInfo.remainingContinues}
                        end
                        return Localize{'ui','GAME_END',option.key,playingReplay and 'playingReplay' or 'normal'}
                    end,
                    events={
                        [UI.EVENTS.SELECT]=option.func
                    },
                    extraUpdates={function (self)
                        if option.key=='continue' then
                            self.transparency=G.runInfo.remainingContinues<=0 and 0.5 or 1
                        end
                        if option.key=='saveReplay' then
                            self.transparency=(playingReplay or G.runInfo.continued) and 0.5 or 1
                        end
                    end}
                })
                ::continue::
            end
        end
        remakeOptions()
    end,
    enter=function(self,lastState)
        base.frame=0
        playingReplay=G.runInfo.replay~=nil
        -- remakeOptions needs to know most recent playingReplay so cannot swap order
        remakeOptions()
        -- if player dies during a stage, stageManager:update part after stage coroutine ends wont be executed which includes adding current stage keyrecords and things into replay source data.
        if lastState==G.STATES.IN_GAME and not playingReplay then
            if #StageManager.previousStagesData==0 or StageManager.previousStagesData[#StageManager.previousStagesData].stageKey~=StageManager.args.stageKey then
                StageManager:addStageData()
            end
            G.runInfo.pendingReplay=ReplayManager:getPendingReplay(G.save.defaultName)
        end
        base:updateHierarchy() -- simple way to deal with the one-frame delay due to extraUpdate using base.frame to update positions
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