local base=UI.Base()
local panelShaderCode=[[
extern vec4 xywh; // x,y,width,height of the panel
vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 pixel_coords)
{
    vec4 colorBase=Texel(texture, texture_coords)*color;
    // edge fade effect
    vec2 coords=vec2(pixel_coords.x-xywh.x, pixel_coords.y-xywh.y)/xywh.zw;
    float centerness=1.0-abs(coords.x-0.5)*2.0;
    float alphaMultiplier=smoothstep(0,0.5,centerness);
    return colorBase*vec4(1.0,1.0,1.0,alphaMultiplier);
}
]]
local panelShader=love.graphics.newShader(panelShaderCode)
return {
    base=base,
    init=function(self)
        local titleText=base:child(
            UI.Text{
                text=Localize{'ui','CHOOSE_PLAYER',"choosePlayer"},
                fontSize=48,color={1,1,1,1},
                x=400,y=30,align='center',width=600
            }
        )
        local playerW,playerH=500,240
        local playerSwitcher=base:child(UI.Switcher{
            x=400,y=200,
            arrange=function(_,index)
                return index*360,index*290
            end,
            lerpRatio=0.1,
            preview=2,canHold=false,
            optionConstructor=function(_,index)
                local player=G.CONSTANTS.PLAYERS[index]
                if not player then
                    return nil
                end
                local playerData=G.CONSTANTS.PLAYERS_DATA[player]
                if not playerData then
                    return nil
                end
                local player,playerColor=playerData.value,playerData.color
                local playerColorBold=math.interpolateTable(playerColor,{0,0,0,1},0.7)
                local fillColor={playerColor[1],playerColor[2],playerColor[3],0.2}
                local base=UI.Base{} -- add a base so box can move left width/2
                local box=base:child(UI.Panel{x=-250,width=playerW,height=playerH,fillColor=fillColor,edgeColor=playerColor,shader=panelShader})
                local leftPart=base:child(UI.Base{x=-150}):addLerpConditionUpdate('x', 'focused', -150, 0, 0.1)
                local name=leftPart:child(UI.Text{
                    text=Localize{'characters',player,'name'},
                    fontSize=36,color=playerColor,boldColor={0,0,0,1},
                    x=0,y=10,width=300,align='center'
                })
                local nickname=leftPart:child(UI.Text{
                    text=Localize{'characters',player,'nickname'},
                    fontSize=24,color=playerColor,boldColor={0,0,0,1},
                    x=0,y=50,width=300,align='center'
                })
                local description=leftPart:child(UI.Text{
                    text=Localize{'ui','CHOOSE_PLAYER','playerDescriptions',player},
                    fontSize=16,color={1,1,1,1},boldColor=playerColorBold,
                    x=0,y=80,width=270,align='center'}):addLerpConditionUpdate('transparency', 'focused', 1,0, 0.1)
                -- the expected effect is: unfocused option only shows name, focused option shows all info. so for the arrange function, the gap between 0 and 1 (current option) is higher. in addition, the topmost and bottommost options should be at same place, so the switcher needs an extra update to change its y.
                local lerpRatio=0.1
                local optionYGap=190
                local optionCollapseYGap=30 -- 
                local shotTypeSwitcher=base:child(UI.Switcher{
                    x=150,
                    arrange=function(_,index)
                        return 0,index*optionCollapseYGap+math.clamp(index,0,1)*(optionYGap-optionCollapseYGap)
                    end,
                    extraUpdates={
                        function(self)
                            self.transparency=math.lerpCondition(self.transparency,self.focused,1,0,lerpRatio)
                            self.x=math.lerpCondition(self.x,self.focused,150,0,lerpRatio)
                            self.y=math.lerp(self.y,(self.currentOptionIndex-1)*optionCollapseYGap+10,lerpRatio)
                            if self.focused and isPressed('z') then
                                local selectedShotType=G.CONSTANTS.PLAYER_TO_SHOT_TYPES[player][self.currentOptionIndex]
                                if not ShotTypes[selectedShotType] then -- the shot type isn't implemented yet
                                    SFX:play('cancel',true)
                                    return
                                end
                                G.runInfo.playerType=player
                                G.runInfo.shotType=selectedShotType
                                G:resetRunInfo()
                                G.runInfo.practice=false
                                SFX:play('select',true)
                                StageManager:load('stage1')
                                G:switchState(G.STATES.IN_GAME)
                            end
                        end
                    },
                    lerpRatio=lerpRatio,preview=2,canHold=false,
                    optionConstructor=function(_,index)
                        local shotTypes=G.CONSTANTS.PLAYER_TO_SHOT_TYPES
                        local shotType=shotTypes[player][index]
                        if not shotType then
                            return nil
                        end
                        local shotTypeBox=UI.Base{}
                        local shotTypeTitle=shotTypeBox:child(UI.Text{
                            text=Localize{'ui','CHOOSE_PLAYER','shotTypeDescriptions',shotType,'title'},
                            fontSize=24,color={1,1,1,1},boldColor=playerColorBold,
                            x=0,y=0,width=200,align='center',
                        })
                        local shotTypeDetailsBox=shotTypeBox:child(UI.Base{}):addLerpConditionUpdate('transparency', 'focused', 1,0, 0.1)
                        local keys={'unfocusedShot','focusedShot','spellCard'}
                        for i,key in pairs(keys) do
                            local yBase=i*50
                            local extraUpdate=function(self)
                                self.y=math.lerpCondition(self.y,self.focused,yBase,0,lerpRatio)
                            end
                            local keyText=shotTypeDetailsBox:child(UI.Text{
                                text=Localize{'ui','CHOOSE_PLAYER',key},
                                fontSize=20,color={1,1,1,1},boldColor=playerColorBold,
                                x=-10,y=yBase,width=150,align='right',extraUpdates={extraUpdate}
                            })
                            local valueText=shotTypeDetailsBox:child(UI.Text{
                                text=Localize{'ui','CHOOSE_PLAYER','shotTypeDescriptions',shotType,key,'title'},
                                fontSize=16,color={1,1,1,1},boldColor=playerColorBold,
                                x=10,y=yBase,width=250,align='left',extraUpdates={extraUpdate}
                            })
                            local extraUpdate2=function(self)
                                self.y=math.lerpCondition(self.y,self.focused,yBase+20,0,lerpRatio)
                            end
                            local valueDescription=shotTypeDetailsBox:child(UI.Text{
                                text=Localize{'ui','CHOOSE_PLAYER','shotTypeDescriptions',shotType,key,'description'},
                                fontSize=14,color={0.7,0.7,0.7,1},boldColor=playerColorBold,
                                x=10,y=yBase+20,width=250,align='left',extraUpdates={extraUpdate2}
                            })
                        end
                        return shotTypeBox
                    end
                })
                return base
            end,
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
            self:switchState(self.STATES.CHOOSE_DIFFICULTY)
            return
        end
        base:updateHierarchy()
    end,
    options={},
    draw=function(self)
    end,
    drawText=function(self)
        base:drawTextHierarchy()
    end,
}