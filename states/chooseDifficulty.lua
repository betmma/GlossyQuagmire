
local base=UI.Base()
return {
    base=base,
    init=function(self)
        local titleText=base:child(
            UI.Text{
                text=Localize{'ui','CHOOSE_DIFFICULTY',"chooseDifficulty"},
                fontSize=48,color={1,1,1,1},
                x=400,y=30,align='center',width=600
            }
        )
        local difficultySwitcher=base:child(UI.Switcher{
            x=250,y=200,
            arrange=function(_,index)
                return index*400,index*200
            end,
            lerpRatio=0.1,
            optionConstructor=function(_,index)
                local difficulties=G.CONSTANTS.REGULAR_DIFFICULTIES
                local difficulty=difficulties[index]
                if not difficulty then
                    return nil
                end
                local data=G.CONSTANTS.DIFFICULTIES[difficulty]
                local color=data.color
                local fillColor={color[1],color[2],color[3],0.2}
                local box=UI.Panel{width=300,height=200,fillColor=fillColor,edgeColor=data.color}
                local title=box:child(UI.Text{
                    text=Localize{'ui','CHOOSE_DIFFICULTY','difficultyDescriptions',difficulty,'title'},
                    fontSize=36,color={1,1,1,1},
                    x=0,y=0,width=300,align='center',toggleX=false,
                })
                local plainName=box:child(UI.Text{
                    text=Localize{'ui','CHOOSE_DIFFICULTY','difficultyDescriptions',difficulty,'plainName'},
                    fontSize=28,color=data.color,boldColor={0,0,0,1},
                    x=0,y=50,width=300,align='center',toggleX=false,
                })
                local description=box:child(UI.Text{
                    text=Localize{'ui','CHOOSE_DIFFICULTY','difficultyDescriptions',difficulty,'description'},
                    fontSize=24,color={1,1,1,1},
                    x=0,y=100,width=300,align='center',toggleX=false,
                })
                return box
            end,
            extraUpdates={
                function(switcher)
                    if isPressed('z') then
                        SFX:play('cancel',true)
                        return
                    end
                end
            },
            preview=3,canHold=false
        })
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