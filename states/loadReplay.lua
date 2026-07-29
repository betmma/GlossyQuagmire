local G=...
local crossShaderCode=[[
extern vec4 xywh; // x,y,width,height of the panel
uniform float gridSize = 30.0; 
vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 pixel_coords)
{
    float c = 0.70710678+xywh.x*0.00000001; // use xywh variable
    float s = 0.70710678;
    vec2 rotatedCoords = vec2(
        pixel_coords.x * c - pixel_coords.y * s,
        pixel_coords.x * s + pixel_coords.y * c
    );
    vec2 cellUV = fract(rotatedCoords / gridSize);
    vec2 distFromCenter = abs(cellUV - vec2(0.5));
    float edgeFactor = max(distFromCenter.x, distFromCenter.y) * 2.0;
    float gridAlpha = mix(0.9, 1.0, smoothstep(0.0, 1.0, edgeFactor*edgeFactor));
    vec4 colorBase = Texel(texture, texture_coords) * color;
    colorBase.a *= gridAlpha;

    return colorBase;
}
]]
local crossShader=love.graphics.newShader(crossShaderCode)
local base=UI.Base()
local chosenSlot=1
local charWidth=10
local inChooseStageMenu=false
return {
    base=base,
    init=function(self)
        local baseLayer=UI.Base{parent=base}
        baseLayer.canChildHaveFocus=function(self,childKey)
            return not inChooseStageMenu
        end
        local chooseStageLayer=UI.Base{extraUpdates={function(self)
            if inChooseStageMenu and isPressed(KEYS.CANCEL) then
                SFX:play('select')
                inChooseStageMenu=false
            end
        end},parent=base}
        chooseStageLayer.canChildHaveFocus=function(self,childKey)
            return inChooseStageMenu
        end
        -- choose stage menu for full game replay
        local width,height=300,200 -- this height will be adjusted according to the number of stages in the replay
        local panel=UI.Panel{width=width,height=height,x=(WINDOW_WIDTH-width)/2,y=(WINDOW_HEIGHT-height)/2,parent=chooseStageLayer,edgeColor={1,1,1,0.5},fillColor={0.8,0.8,0.8,0.8},transparency=0,extraUpdates={function(self)
            self.transparency=math.lerpCondition(self.transparency,inChooseStageMenu,1,0,0.15)
        end},shader=crossShader}
        local options=UI.Options{arrange=function(self, index)
            return 0,index*30-15
        end,keysToDirections={
            [KEYS.DIRECTIONS.UP] = 'up',
            [KEYS.DIRECTIONS.DOWN] = 'down',
        },cursor=UI.Cursor{fluctuateRatio=0.03},parent=panel,x=10}
        local gap=10
        local function addOptions()
            options:clearOptions()
            panel.height=gap*2+#ReplayManager:getStagesAndScores(chosenSlot)*30
            panel.y=(WINDOW_HEIGHT-panel.height)/2
            local stagesAndScores=ReplayManager:getStagesAndScores(chosenSlot)
            for i,stageAndScore in ipairs(stagesAndScores) do
                local stageKey,score=stageAndScore.stageKey,stageAndScore.score
                local stageName=Localize{'ui','SPELL_PRACTICE','stages',stageKey}
                scoreText=string.format('%09d',score)
                local option=UI.Base{width=width-gap*2,height=20,
                events={
                    [UI.EVENTS.SELECT]=function(_)
                        local canRun=ReplayManager:runReplayAtSlot(chosenSlot,stageKey)
                        if canRun then
                            SFX:play('select',false)
                        else
                            SFX:play('cancel') -- shouldn't happen
                        end
                    end,}
                }
                local stageText=UI.Text{fontSize=18,color={1,1,1,1},text=stageName,x=0,y=0,width=width-gap*2,align='left',toggleX=false,parent=option}
                local scoreText=UI.Text{fontSize=18,color={1,1,1,1},text=scoreText,x=0,y=0,width=width-gap*2,align='right',toggleX=false,parent=option}
                options:addOption(option)
            end
        end

        -- title and replays switch
        local titleText=baseLayer:child(
            UI.Text{
                text=Localize{'ui','MAIN_MENU',"REPLAY"},
                fontSize=48,color={1,1,1,1},
                x=100,y=30,
            }
        )
        local replaysSwitcher=UI.Switcher{
            x=(WINDOW_WIDTH-charWidth*ReplayManager.OVERALL_WIDTH)/2,y=70,parent=baseLayer,arrange=function (self, index)
                return index*800,0
            end,
            optionConstructor=function(self, optionIndex)
                if optionIndex<1 or optionIndex>ReplayManager.PAGES then
                    return nil
                end
                local rows=UI.Options{arrange=function(self, index)
                    return 0,index*20
                end,keysToDirections={
                    [KEYS.DIRECTIONS.UP] = 'up',
                    [KEYS.DIRECTIONS.DOWN] = 'down',
                },cursor=UI.Cursor{fluctuateRatio=0.03}}
                local num=ReplayManager.REPLAY_NUM_PER_PAGE
                local chosenSlotRef=chosenSlot
                for slot=num*(optionIndex-1)+1,optionIndex*num do
                    local replayLine=UI.Text.MonoText{
                        text='',updateText=function ()
                            return ReplayManager:getDisplayLineAtSlot(slot)
                        end,color={1,1,1,1},autoSize=true,charWidth=charWidth,fontName=Fonts.en_us,
                        events={
                            [UI.EVENTS.FOCUS]=function(_)
                                chosenSlot=slot
                            end,
                            [UI.EVENTS.SELECT]=function(_)
                                if #ReplayManager:getStagesAndScores(slot)>0 then
                                    SFX:play('select')
                                    inChooseStageMenu=true
                                    addOptions()
                                    Input.consume()
                                    return
                                end
                                local canRun=ReplayManager:runReplayAtSlot(slot)
                                if canRun then
                                    SFX:play('select')
                                else
                                    SFX:play('cancel')
                                end
                            end,
                    },}
                    rows:addOption(replayLine)
                    if slot%num==chosenSlotRef%num then
                        rows:switchOption(replayLine,true,false)
                    end
                end
                return rows
            end
        }

    end,
    enter=function(self)
        self:replaceBackgroundPatternIfNot(BackgroundPattern.MainMenuTesselation)
        BGM:play('title')
    end,
    chosen=1,
    update=function(self,dt)
        self.backgroundPattern:update(dt)
        if (isPressed('x') or isPressed('escape')) and not inChooseStageMenu then
            SFX:play('select',false)
            self:switchState(self.STATES.MAIN_MENU)
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