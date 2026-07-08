local G=...
local base=UI.Base()
return {
    base=base,
    init=function(self)
        -- dynamic ui objects like spellcard title are created in stages/dynamicObjs.lua.
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
            extraUpdates={function(self)
                local shader=G.foregroundShaderData.shader
                self.transparency=math.lerpCondition(self.transparency,shader==G.CONSTANTS.FOREGROUND_SHADERS.TWO_CIRCLES,0,1,0.1)
            end}
        })
        local getForegroundBaseX=function(y)
            local shader=G.foregroundShaderData.shader
            if shader==G.CONSTANTS.FOREGROUND_SHADERS.CIRCLE or shader==G.CONSTANTS.FOREGROUND_SHADERS.TWO_CIRCLES then
                local centerXY, radius=G.foregroundShaderData.args.centerXY,G.foregroundShaderData.args.radius
                local dy=y-centerXY[2]
                if math.abs(dy)>=radius then
                    return 0
                end
                local dx=math.sqrt(radius^2-dy^2)
                return centerXY[1]+dx-500-10 -- 500 is rightSide.x, 10 is margin
            else
                return 0
            end
        end
        local items={'hiScore','score','empty','lives','bombs','power','grazes'}
        local function getAlignToForegroundExtraUpdate(offsetX)
            return function(self)
                local xr,yr=self:getXY()
                self.x=math.lerp(self.x,getForegroundBaseX(yr+self.height/2)+offsetX,0.1)
            end
        end
        ---@param key 'lives'|'bombs'
        ---@param idx integer
        local function getLifeOrBombMeterSprite(key,idx)
            local currentValue=G.runInfo[key]
            local meterSpriteTable=Asset.itemSprites[key=='lives' and 'lifeMeter' or 'bombMeter']
            if idx>currentValue+1 then
                return meterSpriteTable[0]
            end
            if idx<=currentValue then
                return meterSpriteTable[5]
            end
            return meterSpriteTable[math.ceil((currentValue%1)*5-0.5)]
        end
        local colors={
            lives={1,0.15,0.7,1},
            bombs={0,0.7,0,1},
        }
        for i,key in ipairs(items) do
            local y=i*30+30
            if key=='lives' then
                y=y-12
            elseif key=='bombs' then
                y=y-8
            end
            local color=colors[key] or {1,1,1,1}
            if key~='empty' then
                nameText=rightSide:child(UI.Text{
                    text=Localize{'ui','IN_GAME',key},
                    fontSize=24,color=color,autoSize=true,
                    x=20,y=y,width=100,extraUpdates={getAlignToForegroundExtraUpdate(20)}
                })
                if key=='lives' or key=='bombs' then -- draw item icons
                    ---@cast key 'lives'|'bombs'
                    local rightBase=rightSide:child(UI.Base{x=120,y=y,height=16,extraUpdates={getAlignToForegroundExtraUpdate(120)}})
                    local maxCount=8
                    local dx=16
                    for idx=1,maxCount do -- display up to 8 lives/bombs
                        local icon=rightBase:child(UI.Image{
                            batch=Asset.itemUIBatch,quad=getLifeOrBombMeterSprite(key,idx).quad,
                            x=(idx-1)*dx,y=8,sx=0.5,sy=0.5,
                            extraUpdates={function(self)
                                local sprite=getLifeOrBombMeterSprite(key,idx)
                                self.quad=sprite.quad
                            end}
                        })
                    end
                    -- moving text showing pieces
                    local pieceText=rightBase:child(UI.Text{
                        text='',updateText=function(self)
                            local currentValue=G.runInfo[key]
                            local piece=math.ceil((currentValue%1)*5-0.5) -- 0 to 4
                            piece=math.abs(piece) -- dunno why 0 displays as -0
                            return Localize{'ui','IN_GAME','pieces',piece=piece,max=5}
                        end,
                        fontSize=16,color=color,autoSize=true,align='right',
                        x=13,y=24,width=200,extraUpdates={function (self)
                            local currentValue=G.runInfo[key]
                            local positionIndex=math.clamp(currentValue-currentValue%1,0,maxCount)
                            self.x=math.lerp(self.x,13+positionIndex*dx,0.1)
                        end}
                    })
                    -- +n text when exceeding maxCount
                    local plusText=rightBase:child(UI.Text{
                        text='',updateText=function(self)
                            local currentValue=G.runInfo[key]
                            local exceedAmount=currentValue-currentValue%1-maxCount
                            if exceedAmount>0 then
                                return '+'..tostring(exceedAmount)
                            end
                            return ''
                        end,
                        fontSize=16,color=color,autoSize=true,x=maxCount*dx,y=6,width=200
                    })
                else -- draw text
                    rightText=rightSide:child(UI.Text{
                        text='',updateText=function(self)
                            if key=='hiScore' or key=='score' then
                                return string.format('%09d',G.runInfo[key])
                            end
                            if key=='power' then
                                return string.format('%.2f/4.00',G.runInfo[key]/100)
                            end
                            return tostring(G.runInfo[key])
                        end,
                        fontSize=24,color=color,autoSize=true,
                        x=120,y=y,width=200,extraUpdates={getAlignToForegroundExtraUpdate(120)}
                    })
                end
            end
        end
        -- replaying text
        local replayingText=UI.Text{
            text='',x=10,y=580,color={1,1,1,1},parent=base,
            updateText=function (self)
                if not G.runInfo.replay then
                    return ''
                end
                local text=Localize{'ui','IN_GAME','replaying'}
                local speed=1
                if love.keyboard.isDown('lalt') then
                    speed=speed+2
                end
                if love.keyboard.isDown('lctrl') then
                    speed=speed+1
                end
                if love.keyboard.isDown('lshift') then
                    speed=speed-0.5
                end
                if speed~=1 then
                    text=text..' ['..speed..'x]'
                end
                return text
            end
        }
    end,
    enter=function(self,lastState)
        if lastState~=G.STATES.PAUSE then
            self:replaceBackgroundPatternIfNot(BackgroundPattern.Empty)
            for i,mainEffect in pairs(Asset.mainEffects) do
                if mainEffect.reset then
                    mainEffect:reset()
                end
            end
        end
        base.frame=0
        G.runInfo.exitToState=G.runInfo.exitToState or G.STATES.CHOOSE_PLAYER
    end,
    update=function(self,dt)
        base:updateHierarchy()
        StageManager:update()
        GameObject:updateAll(dt)
        if isPressed('d') then
            local index=1
            local geometries={}
            for key,geometry in pairs(G.geometries) do
                table.insert(geometries,geometry)
            end
            for k,geometry in pairs(geometries) do
                if geometry==G.runInfo.geometry then
                    index=k
                    break
                end
            end
            G.runInfo.geometry=geometries[(index%#geometries)+1]
        end
        if isPressed('r') then
            GameObject:removeAll()
            G:reloadUI()
        end
        if isPressed('escape') then
            SFX:play('select',false)
            G:switchState(G.STATES.PAUSE)
        end
    end,
    draw=G.CONSTANTS.DRAW,
    drawText=function(self)
        GameObject:drawTextAll()
        if love.keyboard.isDown('f2') then
            return
        end
        -- if isPressed('escape') then
        --     SFX:play('select',false)
        --     EventManager.post(EventManager.EVENTS.LEAVE_GAME)
        --     self:switchState(G.runInfo.exitToState)
        -- end
        base:drawTextHierarchy()
    end
}