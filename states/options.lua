local base=UI.Base()
local languageValues={
    {text='English',value='en_us'},
    {text='简体中文',value='zh_cn'},
}
local resolutionValues={
    {text="800x600",value={width=800,height=600}},
    {text="1024x768",value={width=1024,height=768}},
    {text="1280x720",value={width=1280,height=720}},
    {text="1600x1200",value={width=1600,height=1200}},
    {text="1920x1080",value={width=1920,height=1080}},
}
return {
    base=base,
    init=function(self)
        local titleText=base:child(
            UI.Text{
                text=Localize{'ui','MAIN_MENU',"OPTIONS"},
                fontSize=48,color={1,1,1,1},
                x=100,y=60,
            }
        )
        local optionsUI=base:child(
            UI.Options{
                x=100,y=150,
                container=UI.Arranger{
                    arrange=function(self,index)
                        return 0,(index-1)*50*(1-math.exp(-base.frame/15))
                    end
                }
            }
        )
        -- each option is a base with a left aligned text child for the name and a right aligned text child for the value (except for EXIT). also, there is an empty base before exit to have empty space between exit and the other options
        local function createOption(name,switcher)
            local previewDecayRadius=switcher and switcher.previewDecayRadius or 0
            local option=UI.Base{width=600,height=50,
                events={
                    [UI.EVENTS.FOCUS]=function(self)
                        SFX:play('select')
                    end,
                },
                extraUpdates={
                    function(self)
                        if not switcher then
                            return
                        end
                        local lerpRatio=0.1
                        if self.focused then
                            switcher.previewDecayRadius=math.lerp(switcher.previewDecayRadius,previewDecayRadius,lerpRatio)
                        else
                            switcher.previewDecayRadius=math.lerp(switcher.previewDecayRadius,0,lerpRatio)
                        end
                    end
                },}
            if name then
                local nameElement=UI.Text{
                    text=name,
                    fontSize=36,color={1,1,1,1},
                    x=0,y=0,width=300,
                    align='left',toggleX=false,
                }
                option:child(nameElement)
            end
            if switcher then
                switcher.previewDecayRadius=0
                option:child(switcher)
            end
            optionsUI:addOption(option)
            return option
        end
        local integerOptionValues={'master_volume','music_volume','sfx_volume'}
        for i,key in ipairs(integerOptionValues) do
            local switcher=UI.Switcher{
                arrange=function(_,index)
                    return 70*index,0
                end,
                optionConstructor=function(_,index)
                    if index<0 or index>100 then
                        return nil
                    end
                    return UI.Text{
                        text=tostring(index),
                        fontSize=36,color={1,1,1,1},
                        width=500,
                        align='right',toggleX=false,
                    }
                end,
                preview=2,
                canHold=true,
                currentOptionIndex=self.save.options[key],
                events={
                    [UI.EVENTS.SWITCHED]=function(_self,args)
                        local value=args.index
                        self.save.options[key]=value
                        SFX:setVolume(self.save.options.master_volume*self.save.options.sfx_volume/10000)
                        BGM:setVolume(self.save.options.master_volume*self.save.options.music_volume/10000)
                    end
                }
            }
            createOption(Localize{'ui','OPTIONS',key},switcher)
        end
        local languageIndex=1
        for i=1,#languageValues do
            if self.save.options.language==languageValues[i].value then
                languageIndex=i
                break
            end
        end
        local languageOption=createOption(Localize{'ui','OPTIONS','language'},UI.Switcher{
            arrange=function(_,index)
                return 150*index,0
            end,
            optionConstructor=function(_,index)
                if index<1 or index>#languageValues then
                    return nil
                end
                return UI.Text{
                    text=languageValues[index].text,
                    fontName=Fonts[languageValues[index].value],fontSize=36,color={1,1,1,1},
                    width=500,
                    align='right',toggleX=false,
                }
            end,
            preview=2,
            canHold=false,
            currentOptionIndex=languageIndex,
            events={
                [UI.EVENTS.SWITCHED]=function(_self,args)
                    local index=args.index
                    self.save.options.language=languageValues[index].value
                    self.language=self.save.options.language
                    self:reloadUI()
                end
            }
        })
        if self.currentUI.reloaded then
            -- after reload the cursor need to be on language option, for consecutive switching language
            optionsUI:switchOption(languageOption,true)
        end
        local resolutionIndex=1
        for i=1,#resolutionValues do
            if TableEqual(self.save.options.resolution,resolutionValues[i].value) then
                resolutionIndex=i
                break
            end
        end
        createOption(Localize{'ui','OPTIONS','resolution'},UI.Switcher{
            arrange=function(_,index)
                return 200*index,0
            end,
            optionConstructor=function(_,index)
                if index<1 or index>#resolutionValues then
                    return nil
                end
                return UI.Text{
                    text=resolutionValues[index].text,
                    fontSize=36,color={1,1,1,1},
                    width=500,
                    align='right',toggleX=false,
                }
            end,
            preview=2,
            canHold=false,
            currentOptionIndex=resolutionIndex,
            events={
                [UI.EVENTS.SWITCHED]=function(_self,args)
                    local index=args.index
                    self.save.options.resolution=resolutionValues[index].value
                    shove.setWindowMode(self.save.options.resolution.width,self.save.options.resolution.height, {resizable = true})
                end
            }
        })
        createOption().disabled=true -- empty option for spacing
        createOption(Localize{'ui','MAIN_MENU','EXIT'},nil).events[UI.EVENTS.SELECT]=function(_)
            SFX:play('select')
            self:saveData()
            self:switchState(self.STATES.MAIN_MENU)
        end
    end,
    enter=function(self)
        self:replaceBackgroundPatternIfNot(BackgroundPattern.MainMenuTesselation)
        base.frame=0
    end,
    update=function(self,dt)
        self.backgroundPattern:update(dt)
        base:updateHierarchy()
        if isPressed('x') or isPressed('escape')then
            SFX:play('select')
            self:saveData()
            self:switchState(self.STATES.MAIN_MENU)
        end
    end,
    draw=function(self)
    end,
    drawText=function(self)
        base:drawHierarchy()
        SetFont(36)
        love.graphics.print("FPS: "..love.timer.getFPS(), 10, 20)
    end
}