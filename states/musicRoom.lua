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
                text=Localize{'ui','MAIN_MENU',"MUSIC_ROOM"},
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
        local previewCircleRadius=800
        local anglePerOption=math.asin(optionHeight/previewCircleRadius)
        local musicSwitcher=UI.Switcher{
            x=optionBaseX,y=optionBaseY+optionHeight*previewCount,
            arrange=function(_,index)
                local angle=anglePerOption*index
                return previewCircleRadius*math.cos(angle),previewCircleRadius*math.sin(angle)
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
                width=600,height=170,
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
        if isPressed('x') or isPressed('escape')then
            SFX:play('select')
            self:switchState(self.STATES.MAIN_MENU)
            return
        end
        base:updateHierarchy()
    end,
    options={},
    draw=function(self)
    end,
    drawText=function(self)
        base:drawHierarchy()
    end,
}