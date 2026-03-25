local G=...
EventManager.listenTo(EventManager.EVENTS.PLAY_AUDIO, function(audioSystem, audioName)
    if audioSystem==BGM then -- unlock corresponding music
        local musicUnlock=G.save.musicUnlock
        musicUnlock[audioName]=true
    end
end)
local base=UI.Base()
return {
    base=base,
    init=function(self)
        local titleText=base:child(
            UI.Text{
                text=Localize{'ui',"MUSIC_ROOM"},
                fontSize=48,color={1,1,1,1},
                x=100,y=30,
            }
        )
        self.UIDEF.MUSIC_ROOM.options={}
        for i,v in ipairs(BGM.fileNames) do
            table.insert(self.UIDEF.MUSIC_ROOM.options,{value=v})
        end
        -- -- for testing ui insert some dummy options
        -- for i=1,10 do
        --     table.insert(self.UIDEF.MUSIC_ROOM.options,{value='test_music_'..i})
        -- end
        local musics=self.UIDEF.MUSIC_ROOM.options
        local optionBaseX=100
        local optionBaseY=100
        local optionHeight=40
        local previewCount=3
        local musicSwitcher=UI.Switcher{
            x=optionBaseX,y=optionBaseY+optionHeight*previewCount,
            arrange=function(_,index)
                return 0,index*optionHeight
            end,
            optionConstructor=function(_,index)
                local option=musics[index]
                if not option then
                    return nil
                end
                return UI.Text{
                    text='',updateText=function(self)
                        local musicName=option.value
                        local musicUnlock=G.save.musicUnlock
                        if not musicUnlock[musicName] then
                            musicName='unknown'
                        end
                        return ''..index..'. '..Localize{'musicData',musicName,'name'}
                    end,
                    fontSize=24,color={1,1,1,1},
                    width=500,
                    align='left',
                }
            end,
            extraUpdates={
                function(switcher)
                    local musicName=musics[switcher.currentOptionIndex].value
                    local musicUnlock=self.save.musicUnlock
                    if isPressed('z') then
                        if not musicUnlock[musicName] then
                            SFX:play('cancel',true)
                            return
                        end
                        SFX:play('select')
                        BGM:play(musicName)
                    end
                    if DEV_MODE then
                        if isPressed('[') then
                            musicUnlock[musicName]=false
                            SFX:play('cancel',true)
                        elseif isPressed(']') then
                            musicUnlock[musicName]=true
                            SFX:play('select',true)
                        end
                    end
                end
            },
            preview=previewCount,canHold=false
        }
        base:child(musicSwitcher)
        local infoPanel=base:child(
            UI.Panel{
                x=optionBaseX,y=400,
                width=600,height=previewCount*optionHeight,
                fillColor={0,0,0,0.3},
                borderColor={1,1,1,1},
                borderWidth=2,
            }
        )
        local descriptionText=infoPanel:child(
            UI.Text{
                text='',updateText=function(self)
                    local chosenIndex=musicSwitcher.currentOptionIndex
                    local option=musics[chosenIndex]
                    local musicName=option.value
                    local musicUnlock=G.save.musicUnlock
                    if not musicUnlock[musicName] then
                        musicName='unknown'
                    end
                    return Localize{'musicData',musicName,'description'}
                end,
                fontSize=20,color={1,1,1,1},
                x=10,y=10,width=590,
                align='left',
            }
        )
    end,
    enter=function(self)
        self:replaceBackgroundPatternIfNot(BackgroundPattern.MainMenuTesselation)
    end,
    chosen=1,
    update=function(self,dt)
        self.backgroundPattern:update(dt)
        -- UIHelper.optionsCalc(self,{})
        if isPressed('x') or isPressed('escape')then
            SFX:play('select')
            self:switchState(self.STATES.MAIN_MENU)
            return
        end
        -- local musicUnlock=self.save.musicUnlock
        -- local chosen=self.currentUI.chosen
        -- local musicName=self.currentUI.options[chosen].value
        -- if isPressed('z') then
        --     if not musicUnlock[musicName] then
        --         SFX:play('cancel',true)
        --         return
        --     end
        --     SFX:play('select')
        --     BGM:play(musicName)
        -- end
        -- if DEV_MODE then
        --     if isPressed('[') then
        --         musicUnlock[musicName]=false
        --         SFX:play('cancel',true)
        --     elseif isPressed(']') then
        --         musicUnlock[musicName]=true
        --         SFX:play('select',true)
        --     end
        -- end
        base:updateHierarchy()
    end,
    options={},
    draw=function(self)
    end,
    drawText=function(self)
        base:drawHierarchy()
        local musicUnlock=self.save.musicUnlock
        -- SetFont(48)
        -- love.graphics.setColor(1,1,1,1)
        -- love.graphics.print(Localize{'ui',"MUSIC_ROOM"}, 100, 30)
        local edge=5
        local width=600
        local optionBaseX=100
        local optionBaseY=100
        local optionHeight=40
        SetFont(24)
        local chosen=self.currentUI.chosen
        local optionCount=#self.currentUI.options
        local displayedCount=7
        -- local slider=true
        -- if displayedCount>optionCount then
        --     displayedCount=optionCount
        --     slider=false
        -- end
        -- local displayHeight=displayedCount*optionHeight
        -- love.graphics.setColor(0,0,0,0.3)
        -- love.graphics.rectangle("fill",optionBaseX,optionBaseY,width,displayHeight) -- background
        -- local halfDisplayedCount=math.floor(displayedCount/2)
        -- local beginIndex=math.clamp(chosen-halfDisplayedCount,1,optionCount-displayedCount+1)
        -- local endIndex=math.min(optionCount,beginIndex+displayedCount-1)
        -- love.graphics.setColor(1,1,1,1)
        -- if slider==true then
        --     local sliderHeight=displayHeight-edge*2
        --     love.graphics.line(optionBaseX+width-edge,optionBaseY+edge+(beginIndex-1)/optionCount*sliderHeight,optionBaseX+width-edge,optionBaseY+edge+(endIndex)/optionCount*sliderHeight) -- vertical line (slider)
        -- end
        -- for index = beginIndex,endIndex do
        --     local value=self.currentUI.options[index]
        --     if not value then
        --         error("Option "..index.." not found in MUSIC_ROOM options")
        --     end
        --     local musicName=value.value
        --     if not musicUnlock[musicName] then
        --         musicName='unknown'
        --     end
        --     local name=Localize{'musicData',musicName,'name'}
        --     local prefix=''..index..'. '
        --     local indexAppearing=index-beginIndex -- indexAppearing is the index of the option in the current view, starting from 0
        --     love.graphics.print(prefix..name,optionBaseX+edge,optionBaseY+edge+indexAppearing*optionHeight,0,1,1)
        -- end
        -- love.graphics.rectangle("line",optionBaseX,optionBaseY+edge+(chosen-beginIndex)*optionHeight,width,30)
        -- local option=self.currentUI.options[chosen]
        -- if not option then
        --     return
        -- end
        -- local musicName=option.value
        -- if not musicUnlock[musicName] then
        --     musicName='unknown'
        -- end
        -- local description=Localize{'musicData',musicName,'description'}

        -- local bottomY=400
        -- love.graphics.setColor(0,0,0,0.3)
        -- love.graphics.rectangle("fill",optionBaseX,bottomY,width,180)
        -- love.graphics.setColor(1,1,1,1)
        -- SetFont(20)
        -- love.graphics.printf(description,optionBaseX+edge,bottomY+edge,width-edge*2,'left')
        -- love.graphics.rectangle("line",optionBaseX,bottomY,width,180)
        -- SetFont(36)
        -- love.graphics.print("FPS: "..love.timer.getFPS(), 10, 20)
    end,
}