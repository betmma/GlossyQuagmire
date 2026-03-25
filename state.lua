BackgroundPattern=require"backgroundPattern"
local G={
    CONSTANTS={
        DRAW=function(self)
            Asset:clearBatches()
            local colorRef={love.graphics.getColor()}
            Asset.foregroundBatch:setColor(colorRef[1],colorRef[2],colorRef[3],self.foregroundTransparency)
            Asset.foregroundBatch:add(Asset.backgroundLeft,0,0,0,1,1,0,0)
            Asset.foregroundBatch:add(Asset.backgroundRight,650,0,0,1,1,0,0)
            Asset.setHyperbolicRotateShader()
            GameObject:drawAll() -- including directly calling love.graphics functions like .circle and adding sprite into corresponding batch.
            Asset:flushBatches()
            Asset:drawBatches()
            love.graphics.setShader()
        end,
        ---@enum VIEW_MODE
        VIEW_MODES={NORMAL='NORMAL',FOLLOW='FOLLOW'},
        ---@enum HYPERBOLIC_MODEL
        HYPERBOLIC_MODELS={UHP=0,P_DISK=1,K_DISK=2}, -- use number is because it will be sent to shader
        HYPERBOLIC_MODELS_COUNT=3
    },
}
G={
    backgroundPattern=BackgroundPattern.MainMenuTesselation(),
    switchState=function(self,state)
        if state==nil then
            error("Switch state to nil")
        end
        if not self.UIDEF[state] then
            error("State "..state.." not defined")
        end
        if self.UIDEF[state].TRANSITION then
            error("Illegal to switch to a transition state directly")
        end

        local lastState=self.STATE
        
        if lastState==self.STATES.MAIN_MENU and state==self.STATES.CHOOSE_LEVELS and self.save.extraUnlock.firstStart then -- skip choose levels menu if first start
            self.save.extraUnlock.firstStart = false
            self.UIDEF.CHOOSE_LEVELS.chosenLevel=1
            self.UIDEF.CHOOSE_LEVELS.chosenScene=1
            self:enterLevel(1,1)
            return
        end
        EventManager.post(EventManager.EVENTS.SWITCH_STATE,self.STATE,state)

        -- check if there is transition data between current state and the state to switch to
        local transitionData=self.transitionData[lastState]
        if transitionData and transitionData[state] then
            local data=transitionData[state]
            local transitionState=data.transitionState or self.STATES.TRANSITION_SLIDE
            local args={nextState=state,lastState=lastState}
            if transitionState==self.STATES.TRANSITION_SLIDE then
                local slideDirection=data.slideDirection
                local slideRatio=data.slideRatio or 0.15
                local slideFrame=data.slideFrame or 300
                args.slideDirection=slideDirection
                args.slideRatio=slideRatio
                args.transitionFrame=slideFrame
            elseif transitionState==self.STATES.TRANSITION_IMAGE then
                local image=data.image
                local thershold=data.thershold or 0.5
                local frame=data.fadeFrame or 60
                args.image=image
                args.thershold=thershold
                args.transitionFrame=frame
            end
            self.STATE=transitionState
            self.currentUI=self.UIDEF[self.STATE]
            self.currentUI.enter(self,args)
            return
        end

        self.STATE=state
        self.currentUI=self.UIDEF[self.STATE]
        if self.UIDEF[state].enter then
            self.UIDEF[state].enter(self,lastState)
        end
    end,
    replaceBackgroundPatternIfNot=function(self,patternClass)
        if getmetatable(self.backgroundPattern)~=patternClass then
            self.backgroundPattern:remove()
            self.backgroundPattern=patternClass()
        end
    end,
    CONSTANTS=G.CONSTANTS,
    STATES={
        MAIN_MENU='MAIN_MENU',
        OPTIONS='OPTIONS',
        MUSIC_ROOM='MUSIC_ROOM',
        -- NICKNAMES='NICKNAMES',
        -- UPGRADES='UPGRADES',
        -- CHOOSE_LEVELS='CHOOSE_LEVELS',
        -- IN_LEVEL='IN_LEVEL',
        -- PAUSE='PAUSE',
        -- GAME_END='GAME_END', -- either win or lose a scene
        -- SAVE_REPLAY='SAVE_REPLAY',
        -- SAVE_REPLAY_ENTER_NAME='SAVE_REPLAY_ENTER_NAME',
        -- LOAD_REPLAY='LOAD_REPLAY',
        -- ENDING='ENDING', -- ending screen after beating the game
        TRANSITION_SLIDE='TRANSITION_SLIDE', -- a state that slides the screen. Draw both last state and next state, while update is only called for next state
        TRANSITION_IMAGE='TRANSITION_IMAGE', -- an image that covers the screen and fades
    },
    STATE=...,
    transitionData={ -- transitionData[STATE1][STATE2] is the transition data from STATE1 to STATE2. like, if transitionData[MAIN_MENU][CHOOSE_LEVELS].slideDirection='up', then when switching from MAIN_MENU to CHOOSE_LEVELS, the texts of both states will slide up.
        MAIN_MENU={
            CHOOSE_LEVELS={
                slideDirection='up'
            },
            LOAD_REPLAY={
                slideDirection='left'
            },
            OPTIONS={
                slideDirection='right'
            },
            MUSIC_ROOM={
                slideDirection='down'
            },
            NICKNAMES={
                slideDirection='up'
            },
            IN_LEVEL={ -- first time playing, skip choose levels menu and directly enter 1-1
                transitionState='TRANSITION_IMAGE',
            }
        },
        OPTIONS={
            MAIN_MENU={
                slideDirection='left'
            }
        },
        MUSIC_ROOM={
            MAIN_MENU={
                slideDirection='up'
            }
        },
        NICKNAMES={
            MAIN_MENU={
                slideDirection='down'
            },
            ENDING={
                transitionState='TRANSITION_IMAGE'
            }
        },
        GAME_END={
            ENDING={
                transitionState='TRANSITION_IMAGE'
            }
        },
        ENDING={
            MAIN_MENU={
                transitionState='TRANSITION_IMAGE'
            }
        },
        UPGRADES={
            CHOOSE_LEVELS={
                slideDirection='down'
            }
        },
        CHOOSE_LEVELS={
            UPGRADES={
                slideDirection='up'
            },
            MAIN_MENU={
                slideDirection='down'
            },
            IN_LEVEL={
                transitionState='TRANSITION_IMAGE',
            }
        },
        LOAD_REPLAY={
            MAIN_MENU={
                slideDirection='right'
            },
            IN_LEVEL={
                transitionState='TRANSITION_IMAGE',
            }
        },
    },
    currentLevel={},
    --- Warning: besides setting max time, do not access it in any level logic (like for random seed). it is 1 frame less in replay (dunno why) so using it will break replays.
    ---@type integer|nil
    levelRemainingFrame=nil,
    ---@type integer|nil
    levelRemainingFrameMax=nil,
    ---@type boolean|nil
    levelIsTimeoutSpellcard=nil,
    ---@type {level: integer, scene: integer}
    lastLevel={},
    mainEnemy=nil,
    preWin=nil,
    frame=0,
    sceneTempObjs={},
    ---@type replayData|nil
    replay=nil,
    ---@type GameObject|nil
    spellNameText=nil,
    ---@type boolean
    UseHypRotShader=true,
    ---@type boolean
    -- to replay dialogue when entering level (spaghetti???)
    replayDialogue=false,

    DISK_RADIUS_BASE={
        [G.CONSTANTS.HYPERBOLIC_MODELS.P_DISK]=1, -- Poincare disk
        [G.CONSTANTS.HYPERBOLIC_MODELS.K_DISK]=1, -- Klein disk
    },
    ---@type {mode: VIEW_MODE, hyperbolicModel: HYPERBOLIC_MODEL, object: GameObject|nil, viewOffset: pos}
    viewMode={
        mode=G.CONSTANTS.VIEW_MODES.NORMAL,
        hyperbolicModel=G.CONSTANTS.HYPERBOLIC_MODELS.UHP,
        object=...,
        viewOffset={x=0,y=0}
    },
    UIDEF={
    }
}


local SaveManager=require"saveManager"
G.saveData=function(self)
    SaveManager:saveData(self)
end
-- an example of its structure
---@class Save
---@field options {master_volume: integer, music_volume: integer, sfx_volume: integer, language: string, resolution: {width: integer, height: integer}}
---@field defaultName string
---@field playTimeTable {playTimeOverall: number, playTimeInLevel: number}
---@field extraUnlock {[string]: boolean} -- secret level unlocks, format not decided
---@field musicUnlock {[string]: boolean}
---@field nicknameUnlock {[string]: boolean}
---@field statistics {[string]: number}
---@type Save
G.save={
    options={master_volume=100,},
    defaultName='',-- the default name when saving replay
    playTimeTable={
        playTimeOverall=0,
        playTimeInLevel=0,
    },
    extraUnlock={
    }, -- secret level unlocks, format not decided
    musicUnlock={},
    nicknameUnlock={},
    statistics={},
}
G.loadData=function(self)
	SaveManager:loadData(self)
    SFX:setVolume(self.save.options.master_volume*self.save.options.sfx_volume/10000)
    BGM:setVolume(self.save.options.master_volume*self.save.options.music_volume/10000)
    self:saveData()
end
G:loadData()


G.language=G.save.options.language--'zh_cn'--'en_us'--

G.reloadUI=function(self)
    for state,stateDef in pairs(self.UIDEF) do
        stateDef.inited=false
        stateDef.reloaded=true
        if stateDef.base then
            for i=#stateDef.base.children,1,-1 do
                stateDef.base.children[i]:remove()
            end
        end
    end
end

local function loadState(uppercaseName)
    local camelName=uppercaseName:lower():gsub("_(%w)", string.upper)
    local stateChunk=love.filesystem.load('states/'..camelName..'.lua')
    if not stateChunk then
        error('State '..uppercaseName..' ('..camelName..') not found')
    end
    return stateChunk(G)
end

for stateName,state in pairs(G.STATES) do
    local def=loadState(state)
    local update=def.update or function(...) end
    local function updateWrap(self,...)
        if not self.currentUI.inited then
            if self.currentUI.init then
                self.currentUI.init(self)
            end
            self.currentUI.inited=true
        end
        if self.currentUI.base then
            self.currentUI.base.focused=true
        end
        update(self,...)
    end
    def.update=updateWrap
    G.UIDEF[state]=def
end

G:switchState(G.STATES.MAIN_MENU)


G.update=function(self,dt)
    self.frame=self.frame+1
    self.currentUI=self.UIDEF[self.STATE]
    NoticeManager:update()
    -- replay speed control
    if G.replay then
        if love.keyboard.isDown('lalt') then -- +2x
            self.currentUI.update(self,dt)
            self.currentUI.update(self,dt)
        end
        if love.keyboard.isDown('lctrl') then -- +1x
            self.currentUI.update(self,dt)
        end
        if not love.keyboard.isDown('lshift') or self.frame%2==0 then -- -0.5x
            self.currentUI.update(self,dt)
        end
    else
        self.currentUI.update(self,dt)
    end

    -- playtime calculation
    if self.STATE==self.STATES.IN_LEVEL then
        self.save.playTimeTable.playTimeInLevel=self.save.playTimeTable.playTimeInLevel+dt
    end
    self.save.playTimeTable.playTimeOverall=self.save.playTimeTable.playTimeOverall+dt

    UI.Base:cleanObjects() -- to remove removed elements in class.objects
end
G.hyperbolicRotateShader=ShaderScan:load_shader("shaders/hyperbolicRotateM.glsl")
G.draw=function(self)
    shove.beginLayer('main')
    self.currentUI=self.UIDEF[self.STATE]
    self:_drawBatches()

    -- if Player.objects[1] and not Player.objects[1].removed then
    --     Player.objects[1]:invertShaderEffect()
    -- else
    --     Player:invertShaderEffect()
    -- end
    love.graphics.setShader()
    shove.endLayer()
    shove.beginLayer('text')
    self:drawText()
    shove.endLayer()
end
G.drawText=function(self)
    if DEV_MODE and love.keyboard.isDown('f5') then
        return
    end
    self.currentUI.drawText(self)
    NoticeManager:drawText()
end
G._drawBatches=function(self)
    if not self.backgroundPattern.noZoom or G.viewMode.mode==G.CONSTANTS.VIEW_MODES.NORMAL then
        self.backgroundPattern:draw()
    end
    self.currentUI.draw(self)
end
-- remove all objects in the scene
G.removeAll=function(self)
    Asset:clearBatches()
    GameObject:removeAll()
    if self.spellNameText and not self.spellNameText.removed then
        self.spellNameText:remove()
    end
    for i,obj in pairs(self.sceneTempObjs) do
        if not obj.removed then
            obj:remove()
        end
    end
    self.sceneTempObjs={}
end

return G