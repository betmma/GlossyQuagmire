local G=...
local base=UI.Base()
return {
    base=base,
    init=function(self)
        local rightSide=base:child(UI.Base{x=500,y=20})
        local difficultyText=rightSide:child(UI.Text{
            text='',updateText=function(self)
                self.color=G.CONSTANTS.DIFFICULTIES_DATA[G.runInfo.difficulty].color
                return G.runInfo.difficulty
            end,
            fontSize=36,color=G.CONSTANTS.DIFFICULTIES_DATA[G.runInfo.difficulty].color,boldColor={0,0,0,1},
            x=0,y=0,width=300,align='center',toggleX=false,
        })
        local gameIconText=rightSide:child(UI.Text{
            text=GAME_NAME,
            fontSize=28,color={55/255,65/255,81/255,1},
            x=0,y=520,width=300,
            align='center',toggleX=false,
        })
        local items={'hiScore','score','empty','lives','bombs','grazes'}
        for i,key in ipairs(items) do
            local y=i*30+30
            local nameText,rightText
            if key~='empty' then
                nameText=rightSide:child(UI.Text{
                    text=Localize{'ui','IN_GAME',key},
                    fontSize=24,color={1,1,1,1},
                    x=20,y=y,width=100,
                })
                rightText=rightSide:child(UI.Text{
                    text='',updateText=function(self)
                        if key=='hiScore' or key=='score' then
                            return string.format('%09d',G.runInfo[key])
                        end
                        return tostring(G.runInfo[key])
                    end,
                    fontSize=24,color={1,1,1,1},
                    x=120,y=y,width=200,
                })
            end
        end
    end,
    enter=function(self)
        self:replaceBackgroundPatternIfNot(BackgroundPattern.Empty)
        base.frame=0
    end,
    update=function(self,dt)
        base:updateHierarchy()
    end,
    draw=G.CONSTANTS.DRAW,
    drawText=function(self)
        if love.keyboard.isDown('f2') then
            return
        end
        if isPressed('escape') then
            SFX:play('select')
            self:switchState(self.STATES.CHOOSE_PLAYER)
        end
        base:drawHierarchy()
    end
}