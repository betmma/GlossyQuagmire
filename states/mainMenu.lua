local base=UI.Base()
return {
    base=base,
    init=function(self)
        local fangameText=base:child(
            UI.Text{
                text=Localize{'ui','MAIN_MENU','FANGAME'},
                fontSize=16,color={1,1,1,1},
                x=20,y=WINDOW_HEIGHT-20,
            }
        )
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
                text=GAME_NAME,
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
                        return 0,(index-1)*25*(1-math.exp(-base.frame/15))
                    end
                },
            }
        )
        local options={
                {value='GAME_START',state='CHOOSE_DIFFICULTY'},
                {value='EXTRA_START',disabled=true},
                {value='PRACTICE',disabled=true},
                {value='SPELL_PRACTICE'},
                {value='REPLAY',disabled=true},
                {value='PLAYER_DATA',disabled=true},
                {value='MUSIC_ROOM'},
                {value='NICKNAMES',disabled=true},
                {value='OPTIONS'},
                {value='MANUAL',disabled=true},
                {value='EXIT'},
            }
        for index, data in ipairs(options) do
            local value=data.value
            optionsUI:addOption(
                UI.Text{
                    text=Localize{'ui','MAIN_MENU',value},
                    fontSize=24,color={1,1,1,1},
                    autoSize=true,
                    align='center',transparency=data.disabled and 0.5 or 1,
                    events={
                        [UI.EVENTS.SELECT]=function(_)
                            if data.disabled then
                                SFX:play('cancel',true)
                                return
                            end
                            SFX:play('select')
                            if value=='EXIT' then
                                self.save.statistics.politeExit=true
                                self:saveData()
                                love.event.quit()
                                return
                            end
                            local state=data.state or value -- need to ensure same as state name
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
                x=WINDOW_WIDTH-85,y=WINDOW_HEIGHT-30,
            }
        )
        if IS_WEB then
            local disclaimerText=base:child(
                UI.Text{
                    text=Localize{'ui','MAIN_MENU','DISCLAIMER'},
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
        base:drawHierarchy()
    end,
    drawText=function(self)
        if love.keyboard.isDown('f2') then
            return
        end
        base:drawTextHierarchy()
        Asset.titleBatch:flush()
        love.graphics.draw(Asset.titleBatch)
    end
}