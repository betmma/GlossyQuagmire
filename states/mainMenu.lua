local base=UI.Base()
return {
    base=base,
    init=function(self)
        local leftPart=base:child(UI.Base{width=100,height=0})
        local titleImage=leftPart:child(
            UI.Image{
                batch=Asset.titleBatch,quad=Asset.title,
                x=0,y=0,
                r=0,sx=0.5,sy=0.5,
            }
        )
        local titleText=leftPart:child(
            UI.Text{
                text="Glossy Quagmire",
                fontSize=36,color={55/255,65/255,81/255,1},
                x=200,y=250,width=400,
                align='center',
            }
        )
        local optionsUI=leftPart:child(
            UI.Options{
                x=200,y=305,
                container=UI.Arranger{
                    arrange=function(self,index)
                        return 0,(index-1)*50*(1-math.exp(-base.frame/15))
                    end
                },
            }
        )
        local options={
                -- 'START',
                -- 'REPLAY',
                'OPTIONS',
                'MUSIC_ROOM',
                -- 'NICKNAMES',
                -- 'ENDING', -- test only
                'EXIT',
            }
        local option2state={
            START='CHOOSE_LEVELS',
            REPLAY='LOAD_REPLAY',
            OPTIONS='OPTIONS',
            MUSIC_ROOM='MUSIC_ROOM',
            NICKNAMES='NICKNAMES',
            ENDING='ENDING',
        }
        for index, value in ipairs(options) do
            optionsUI:addOption(
                UI.Text{
                    text=Localize{'ui',value},
                    fontSize=36,color={1,1,1,1},
                    autoSize=true,
                    align='center',
                    events={
                        [UI.EVENTS.FOCUS]=function(self,args)
                            if args.init then
                                return
                            end
                            SFX:play('select')
                        end,
                        [UI.EVENTS.SELECT]=function(_)
                            SFX:play('select')
                            if value=='EXIT' then
                                self.save.statistics.politeExit=true
                                self:saveData()
                                love.event.quit()
                                return
                            end
                            local state=option2state[value]
                            if state then
                                self:switchState(self.STATES[state])
                            end
                        end,
                    },
                }
            )
        end
        local versionText=base:child(
            UI.Text{
                text=VERSION,
                fontSize=24,color={1,1,1,1},
                x=WINDOW_WIDTH-80,y=WINDOW_HEIGHT-30,
            }
        )
        if IS_WEB then
            local disclaimerText=base:child(
                UI.Text{
                    text=Localize{'ui','DISCLAIMER'},
                    fontSize=16,color={1,1,1,1},
                    x=620,y=450,
                    width=240,
                    align='center',
                }
            )
        end
    end,
    enter=function(self)
        self:replaceBackgroundPatternIfNot(BackgroundPattern.MainMenuTesselation)
        BGM:play('title')
        base.frame=0
    end,
    update=function(self,dt)
        if isPressed('f3') then
            SFX:play('cancel',true)
            self.backgroundPattern:randomize()
        end
        self.backgroundPattern:update(dt)
        Asset.titleBatch:clear()
        base:updateHierarchy()
    end,
    draw=function(self)
    end,
    drawText=function(self)
        if love.keyboard.isDown('f2') then
            return
        end
        base:drawHierarchy()
        Asset.titleBatch:flush()
        love.graphics.draw(Asset.titleBatch)
    end
}