local base=UI.Base()
return {
    base=base,
    init=function(self)
        local titleText=base:child(
            UI.Text{
                text=Localize{'ui','MAIN_MENU',"CREDITS"},
                fontSize=48,color={1,1,1,1},
                x=100,y=60,
            }
        )
        -- switcher with multiple half transparent dark panels
        local pageCount=3
        local pageSwitcher=UI.Switcher{
            x=100,y=150,parent=base,
            preview=0,
            arrange=function(_,index)
                return 0,index*50
            end,
            optionConstructor=function(_,shotTypeIndex)
                if shotTypeIndex<1 or shotTypeIndex>pageCount then
                    return
                end
                local panel=UI.Panel{width=600,height=400,fillColor={0,0,0,0.3},}
                local text=Localize{'ui','CREDITS',shotTypeIndex}
                local mainText=UI.Text{
                    parent=panel,text=text,fontName=Fonts.zh_cn,
                    fontSize=20,color={1,1,1,1},
                    x=50,y=20,width=500,align='center',toggleX=false
                }
                local pageCountText=UI.Text{
                    parent=panel,text=Localize{'ui','CREDITS','page',current=shotTypeIndex,total=pageCount},
                    fontSize=16,color={1,1,1,1},
                    x=50,y=370,width=500,align='center',toggleX=false
                }
                return panel
            end,
            events={
                [UI.EVENTS.SWITCHED]=function(_self,args)
                end
            }
        }
    end,
    enter=function(self)
        self:replaceBackgroundPatternIfNot(BackgroundPattern.MainMenuTesselation)
        base.frame=0
    end,
    update=function(self,dt)
        self.backgroundPattern:update(dt)
        base:updateHierarchy()
        if isPressed('x') or isPressed('escape')then
            SFX:play('select',false)
            self:switchState(self.STATES.MAIN_MENU)
        end
    end,
    draw=function(self)
    end,
    drawText=function(self)
        base:drawTextHierarchy()
    end
}