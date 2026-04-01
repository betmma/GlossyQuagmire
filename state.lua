BackgroundPattern=require"backgroundPattern"
local G={
    CONSTANTS={
        DRAW=function(self)
            Asset:clearBatches()
            local colorRef={love.graphics.getColor()}
            Asset.foregroundBatch:setColor(colorRef[1],colorRef[2],colorRef[3],self.foregroundTransparency)
            Asset.foregroundBatch:add(Asset.backgroundQuad,0,0,0,1,1,0,0)
            -- Asset.foregroundBatch:add(Asset.backgroundRight,500,0,0,1,1,0,0)
            Asset.titleBatch:add(Asset.title,500,350,0,0.375,0.375,0,0)
            GameObject:drawAll() -- including directly calling love.graphics functions like .circle and adding sprite into corresponding batch.
            Asset:flushBatches()
            Asset:drawBatches()
            love.graphics.setShader()
        end,
        --- from previous game vvv
        ---@enum VIEW_MODE
        VIEW_MODES={NORMAL='NORMAL',FOLLOW='FOLLOW'},
        --- from previous game ^^^
        FOREGROUND_SHADERS={
            -- xywh: vec4
            RECTANGLE=love.graphics.newShader('shaders/foreground/rectangle.glsl'),
            -- centerXY: vec2, radius: number
            CIRCLE=love.graphics.newShader('shaders/foreground/circle.glsl'),
        },
        USE_FOREGROUND_SHADER=function(key,args)
            love.graphics.setShader(G.CONSTANTS.FOREGROUND_SHADERS[key])
            for k,v in pairs(args) do
                G.CONSTANTS.FOREGROUND_SHADERS[key]:send(k,v)
            end
        end,
        -- ---@enum GEOMETRY
        -- GEOMETRIES={EUCLIDEAN='EUCLIDEAN',HYPERBOLIC='HYPERBOLIC'},

        ---@alias colorValue {[1]: number, [2]: number, [3]: number, [4]: number}
        ---@alias DIFFICULTY 'EASY'|'NORMAL'|'HARD'|'LUNATIC'|'EXTRA'
        ---@type {DIFFICULTY: {value: string, shortForm: string, color:colorValue}}
        DIFFICULTIES_DATA={
            EASY={value='EASY',shortForm='E',color={0,0.7,0,1}},
            NORMAL={value='NORMAL',shortForm='N',color={0.5,0.5,1,1}},
            HARD={value='HARD',shortForm='H',color={0.25,0.25,1,1}},
            LUNATIC={value='LUNATIC',shortForm='L',color={0.9,0,0.9,1}},
            EXTRA={value='EXTRA',shortForm='Ex',color={1,0.1,0.1,1}},
        },
        REGULAR_DIFFICULTIES={ -- shown in game start menu
            'EASY',
            'NORMAL',
            'HARD',
            'LUNATIC',
        },
        ---@alias PLAYER 'REIMU'|'MARISA'|'KOTOBA'
        PLAYERS={'REIMU','MARISA','KOTOBA'},
        PLAYERS_DATA={
            REIMU={value='REIMU',color={1,0.2,0.2,1}},
            MARISA={value='MARISA',color={1,1,0.5,1}},
            KOTOBA={value='KOTOBA',color={1,0.5,1,1}},
        },
        ---@alias SHOT_TYPE 'REIMUA'|'REIMUB'|'MARISAA'|'MARISAB'|'KOTOBAA'|'KOTOBAB'
        SHOT_TYPES={'REIMUA','REIMUB','MARISAA','MARISAB','KOTOBAA','KOTOBAB'},
        PLAYER_TO_SHOT_TYPES={
            REIMU={'REIMUA','REIMUB'},
            MARISA={'MARISAA','MARISAB'},
            KOTOBA={'KOTOBAA','KOTOBAB'},
        },
    },
}
local geometries=require"geometries.geometryBase"
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
        CHOOSE_DIFFICULTY='CHOOSE_DIFFICULTY',
        CHOOSE_PLAYER='CHOOSE_PLAYER',
        MUSIC_ROOM='MUSIC_ROOM',
        -- NICKNAMES='NICKNAMES',
        OPTIONS='OPTIONS',
        IN_GAME='IN_GAME',
        -- PAUSE='PAUSE',
        -- GAME_END='GAME_END',
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
            CHOOSE_DIFFICULTY={
                slideDirection='up',
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
        CHOOSE_DIFFICULTY={
            MAIN_MENU={
                slideDirection='down'
            },
            CHOOSE_PLAYER={
                slideDirection='up'
            },
        },
        CHOOSE_PLAYER={
            CHOOSE_DIFFICULTY={
                slideDirection='down'
            },
            IN_GAME={
                transitionState='TRANSITION_IMAGE',
            }
        },
        LOAD_REPLAY={
            MAIN_MENU={
                slideDirection='right'
            },
            IN_GAME={
                transitionState='TRANSITION_IMAGE',
            }
        },
    },
    geometries=geometries,
    ---@type {difficulty: DIFFICULTY, playerType: PLAYER, shotType: SHOT_TYPE, hiScore:number, score: number, lives: integer, bombs: integer, grazes: integer, stage: integer, geometry: GeometryBase, player:Player}
    runInfo={ -- things that can be changed and accessed during the run should be put there
        difficulty=G.CONSTANTS.REGULAR_DIFFICULTIES[1],
        playerType=G.CONSTANTS.PLAYERS[1],
        shotType=G.CONSTANTS.PLAYER_TO_SHOT_TYPES[G.CONSTANTS.PLAYERS[1]][1],
        hiScore=0,
        score=0,
        lives=3,
        bombs=3,
        grazes=0,
        stage=1,
        geometry=geometries.Hyperbolic,
        player=nil,
    },
    frame=0,
    ---@type replayData|nil
    replay=nil,

    currentUI={},
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
        if self.currentUI.base then -- note that base.updateHierarchy and drawHierarchy should not be added to wrap, since some states may need different order
            self.currentUI.base.focused=true
        end
        update(self,...)
    end
    def.update=updateWrap
    if def.base then -- let base fade out when unfocused (during transition. there is code in transitionSlide to call updateHierarchy of lastState's base.) i didnt make all states' base be child of some root since it would update all bases every frame.
        def.base:addLerpConditionUpdate()
    end
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
    if self.STATE==self.STATES.IN_GAME then
        self.save.playTimeTable.playTimeInLevel=self.save.playTimeTable.playTimeInLevel+dt
    end
    self.save.playTimeTable.playTimeOverall=self.save.playTimeTable.playTimeOverall+dt

    UI.Base:cleanObjects() -- to remove removed elements in class.objects
end
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
    if DEV_MODE then
        SetFont(12)
        love.graphics.print("FPS: "..love.timer.getFPS(), 20, 20)
    end
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