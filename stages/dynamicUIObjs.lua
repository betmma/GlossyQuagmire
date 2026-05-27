-- for in-game UI like stage title, boss name, remaining time things

---@alias circleForegroundStrategy fun(self:UIText, centerXY:number[], radius:number):nil
---@alias rectangleForegroundStrategy fun(self:UIText, xywh:number[]):nil

---@param circleStrategy circleForegroundStrategy
---@param rectangleStrategy rectangleForegroundStrategy
local function strategy(circleStrategy, rectangleStrategy)
    return function(self)
        local shader=G.foregroundShaderData.shader
        if shader==G.CONSTANTS.FOREGROUND_SHADERS.CIRCLE or shader==G.CONSTANTS.FOREGROUND_SHADERS.TWO_CIRCLES then
            local centerXY, radius=G.foregroundShaderData.args.centerXY,G.foregroundShaderData.args.radius
            return circleStrategy(self, centerXY, radius)
        elseif shader==G.CONSTANTS.FOREGROUND_SHADERS.RECTANGLE then
            local xywh=G.foregroundShaderData.args.xywh
            return rectangleStrategy(self, xywh)
        end
    end
end

function makeDynamicUIObjs()
    ---@type UIBase
    local base=G.UIDEF.IN_GAME.base

    ---@class DynamicText:UIText
    ---@field setText fun(self, text:string, direct:boolean|nil):nil set text with fade in/out effect. if text is set to empty string, it will fade out and then set text, otherwise it will set text and then fade in. if direct is true, it will set text directly without fade in/out effect.
    local DynamicText=UI.Text:extend()
    -- set text with fade in/out effect. if text is set to empty string, it will fade out and then set text, otherwise it will set text and then fade in.
    function DynamicText:setText(text,direct)
        if self.text==nil then -- the first set in UI.Text.new() is not considered as a real setText, so just set it directly without fade in/out effect.
            self.text=text
            return
        end
        if direct then
            UI.Text.setText(self,text)
            return
        end
        if text~='' then
            UI.Text.setText(self,text)
            if self.transparency<1 then
                Event.EaseEvent{obj=self,duration=10,aims={transparency=1}}
            end
        else
            if self.text~='' then
                Event.EaseEvent{obj=self,duration=10,aims={transparency=0},afterFunc=function()
                    UI.Text.setText(self,text)
                end}
            end
        end
    end

    local dynamicObjs=base:child(UI.Base{x=0,y=0})
    local centerBase=base:child(UI.Base{x=0,y=0,
        extraUpdates={strategy(
            function(self, centerXY, radius)
                self.x,self.y=centerXY[1],centerXY[2]-radius*0.3
            end,
            function(self, xywh)
                self.x,self.y=xywh[1]+xywh[3]/2,xywh[2]+xywh[4]*0.2
            end
        )}})
    -- stage title, the main part
    local stageTitleText=centerBase:child(DynamicText{
        text='',fontSize=48,color={1,1,1,1},autoSize=true,
        x=0,y=20,align='center',toggleX=true,transparency=0
    })
    -- the small text above main title text. like STAGE 1 Somewhere in Gensokyo
    local stageTitleSmallText=centerBase:child(DynamicText{
        text='',fontSize=24,color={1,1,1,1},autoSize=true,
        x=0,y=-20,align='center',toggleX=true,transparency=0,
    })

    -- general notices for "Get Spell Card Bonus!!, Bonus Failed..., Challenge next stage!, Full PowerUp!, Hiscore! and Extend!!"
    local noticeText=centerBase:child(DynamicText{
        text='',fontSize=40,color={1,1,1,1},autoSize=true,
        x=0,y=0,align='center',toggleX=true,transparency=0,
    })

    -- display soundtrack name at bottom
    local soundtrackText=dynamicObjs:child(DynamicText{
        text='',fontSize=20,color={1,1,1,1},autoSize=true,
        x=0,y=0,align='center',toggleX=true,transparency=0,
        extraUpdates={strategy(
            function(self, centerXY, radius)
                self.x,self.y=centerXY[1],centerXY[2]+radius-self.height-10
                self.align='center'
            end,
            function(self, xywh)
                self.x,self.y=xywh[1]+xywh[3]-10,xywh[2]+xywh[4]-self.height-10
                self.align='right'
            end)}
    })

    -- display boss name at top during boss fight
    local bossNameBase=dynamicObjs:child(UI.Base{x=0,y=0,
        extraUpdates={
            strategy(
                function(self, centerXY, radius)
                    self.x,self.y=centerXY[1]-100,centerXY[2]-radius
                end,
                function(self, xywh)
                    self.x,self.y=xywh[1]+10,xywh[2]+10
                end
            )}
    })
    local bossNameText=bossNameBase:child(DynamicText{
        text='',fontSize=16,color={1,1,1,1},autoSize=true,
        x=0,y=0,align='center',toggleX=true,transparency=0,
        extraUpdates={
            strategy(
                function(self, centerXY, radius)
                    self.align='right'
                end,
                function(self, xywh)
                    self.align='left'
                end
            )}
    })
    ---@class BossStars:UIArranger
    ---@field addStar fun(self):nil add a star
    ---@field removeStar fun(self):nil remove a star, if there is any
    local bossStars=bossNameBase:child(UI.Arranger{
        x=0,y=20,arrange=function(self,index)
            return (index-1)*30,0
        end,
        extraUpdates={
            strategy(
                function(self, centerXY, radius)
                    self.x=-bossNameText.width
                end,
                function(self, xywh)
                end
            )}
    })

    function bossStars:addStar()
        local star=UI.Image{quad=Asset.itemSprites.enemySpellcardIndicator.quad, batch=Asset.itemUIBatch, x=0,y=0}
        self:child(star)
    end

    function bossStars:removeStar()
        if #self.children>0 then
            local toRemove=self.children[#self.children]
            toRemove:unchild()
            Event.EaseEvent{obj=toRemove,duration=10,aims={transparency=0},afterFunc=function()
                toRemove:remove()
            end}
        end
    end

    function bossStars:clearStars()
        for i=#self.children,1,-1 do
            local toRemove=self.children[i]
            toRemove:unchild()
            toRemove:remove()
        end
    end

    local remainingTimeBase=dynamicObjs:child(UI.Base{x=0,y=0,
        extraUpdates={strategy(
            function(self, centerXY, radius)
                self.x,self.y=centerXY[1],centerXY[2]-radius+10
            end,
            function(self, xywh)
                self.x,self.y=xywh[1]+xywh[3]/2,xywh[2]+20
            end
        )}
    })

    -- part before decimal point is bigger
    local remainingTimeTextLeft=remainingTimeBase:child(DynamicText{
        text='',fontSize=24,color={1,1,1,1},autoSize=true,
        x=0,y=0,align='right',toggleX=true,transparency=0
    })

    -- part after decimal point is smaller
    local remainingTimeTextRight=remainingTimeBase:child(DynamicText{
        text='',fontSize=16,color={1,1,1,1},autoSize=true,
        x=0,y=7,align='left',toggleX=false,transparency=0
    })

    local spellcardInfoBase=dynamicObjs:child(UI.Base{x=0,y=0,
        extraUpdates={
            strategy(
                function(self, centerXY, radius)
                    self.x,self.y=centerXY[1]+radius*0.6,centerXY[2]-radius+50
                end,
                function(self, xywh)
                    self.x,self.y=xywh[1]+xywh[3]-10,xywh[2]+10
                end
            )}
    })

    -- for spellcard info appear animation: sliding up and fade in.
    local spellcardInfoMoveUp=spellcardInfoBase:child(UI.Base())

    local spellcardNameText=spellcardInfoMoveUp:child(DynamicText{
        text='',fontSize=20,color={1,1,1,1},autoSize=true,
        x=0,y=0,align='right',toggleX=true,transparency=0
    })

    local spellcardLineBelowName=spellcardNameText:child(UI.Panel{
        x=-50,y=25,width=100,height=1,edgeColor={0.8,0.8,1,1},fillColor={0.8,0.8,1,1},transparency=0.3,
        extraUpdates={function(self)
            self.width=spellcardNameText.width+50
        end}
    })

    local spellcardBonusHistoryText=spellcardInfoMoveUp:child(DynamicText{
        text='',fontSize=14,color={1,1,1,1},autoSize=true,
        x=30,y=30,align='right',toggleX=true,transparency=0,
        extraUpdates={
            strategy(
                function(self, centerXY, radius)
                    self.x,self.y=30,30
                end,
                function(self, xywh)
                    self.x,self.y=0,30
                end
            )}
    })

    ---@class HPBar:UIImage
    ---@field batch MeshBatch
    ---@field phases number[] sorted in decreasing order. like {0.5,0.2} means 3 phases: 0.5-1, 0.2-0.5, 0-0.2
    ---@field colors {[1]:number,[2]:number,[3]:number}[]
    ---@field currentPhaseIndex integer which phase the boss's current hp is in 
    ---@field hpRatio number between 0 and 1. means the hpRatio in the whole hp bar. NOT MEANING THE SAME AS THE PARAMETER SENT TO updatePhaseHP, which is the hpRatio in the current phase.
    ---@field ratioToPos fun(self, ratio:number, upOrDown:boolean):ScreenPosition get the screen position of the hpbar at ratio percentage, at up or down side. used for mesh points
    ---@field setPhases fun(self, phases:number[], colors:{[1]:number,[2]:number,[3]:number}[]):nil set phases and colors.
    ---@field initHP fun(self):nil play the animation to initialize hp bar when boss appears
    ---@field increasePhase fun(self):nil increase currentPhaseIndex by 1, called when each boss phase ends.
    ---@field updatePhaseHP fun(self, hpRatio:number):nil update hp ratio in the current phase. hpRatio is a number between 0 and 1, means the hpRatio in the current phase, not the whole hp bar.
    local hpBar=dynamicObjs:child(UI.Image{
        batch=Asset.itemUIMeshes,quad=Asset.itemSprites.hpBar.quad,
        x=0,y=0,transparency=0,extraUpdates={function(self)
            self.transparency=bossNameText.transparency -- sync hp bar transparency with boss name
        end}})
    hpBar.phases={}
    hpBar.colors={{1,1,1}}
    hpBar.currentPhaseIndex=1
    hpBar.hpRatio=0

    ---return the screen position of the hpbar at ratio percentage, at up or down side. used for mesh points
    ---@param ratio number
    ---@param upOrDown boolean true for up side of hp bar, false for down side of hp bar
    ---@return ScreenPosition
    function hpBar:ratioToPos(ratio,upOrDown)
        local shader=G.foregroundShaderData.shader
        if shader==G.CONSTANTS.FOREGROUND_SHADERS.CIRCLE or shader==G.CONSTANTS.FOREGROUND_SHADERS.TWO_CIRCLES then
            local centerXY, radius=G.foregroundShaderData.args.centerXY,G.foregroundShaderData.args.radius
            local startAngle,endAngle=-math.pi*3/4,-math.pi/4
            local angle=math.lerp(startAngle,endAngle,ratio)
            local r=radius-(upOrDown and 5 or 10)
            return {
                x=centerXY[1]+math.cos(angle)*r,
                y=centerXY[2]+math.sin(angle)*r,
            }
        elseif shader==G.CONSTANTS.FOREGROUND_SHADERS.RECTANGLE then
            local xywh=G.foregroundShaderData.args.xywh
            local startx=xywh[1]+5
            local endx=xywh[1]+xywh[3]-5
            local y=xywh[2]+(upOrDown and 5 or 10)
            return {
                x=math.lerp(startx,endx,ratio),
                y=y,
            }
        else
            return {x=0,y=0}
        end
    end

    ---@param phases number[] will be sorted in decreasing order but colors will not be sorted.
    ---@param colors {[1]:number,[2]:number,[3]:number}[] should be one more than phases. like if phase is {0.5}, then colors should have color for phase 0-0.5 and color for phase 0.5-1. first color is for 1 to sorted phase[1], ...
    function hpBar:setPhases(phases,colors)
        table.sort(phases,function (a,b) return a>b end) -- decreasing
        self.phases=phases
        self.colors=colors
        self.currentPhaseIndex=1
    end

    function hpBar:initHP()
        self.duringInit=true
        Event.EaseEvent{obj=self,duration=60,aims={hpRatio=1},afterFunc=function()
            self.duringInit=false
        end}
    end

    function hpBar:getHighAndLow(phaseIndex)
        local high=phaseIndex==1 and 1 or self.phases[phaseIndex-1]
        local low=phaseIndex==#self.phases+1 and 0 or self.phases[phaseIndex]
        return high,low
    end

    function hpBar:increasePhase()
        self.currentPhaseIndex=math.min(self.currentPhaseIndex+1,#self.phases+1)
    end

    ---@param hpRatio number between 0 and 1. means the hpRatio in the current phase, not the whole hp bar. this function never calls increasePhase.
    function hpBar:updatePhaseHP(hpRatio)
        if self.duringInit then
            return -- during init animation, hpRatio is controlled by the animation, so ignore updatePhaseHP calls from bossManager.
        end
        hpRatio=math.clamp(hpRatio,0,1)
        local index=self.currentPhaseIndex
        local high,low=self:getHighAndLow(index)
        self.hpRatio=math.lerp(low,high,hpRatio)
    end

    function hpBar:draw()
        if self.transparency==0 then
            return
        end
        local x,y,w,h=love.graphics.getQuadXYWHOnImage(self.quad,Asset.itemImage)
        for i=#self.phases+1,1,-1 do
            local high,low=self:getHighAndLow(i)
            if self.hpRatio<low then -- this phase and the following phases are empty
                break
            end
            local ratioInPhase=math.min((self.hpRatio-low)/(high-low),1)
            local realHigh=math.lerp(low,high-0.005,ratioInPhase) -- -0.005 to create a gap between phases
            local color=self.colors[i] or {1,1,1}
            local gap=0.01
            local count=math.max(math.ceil((realHigh-low)/gap),1)
            local meshPoints={}
            local shadeMeshPoints={}
            local shadeOffset=2
            local shadeColor={0.5,0.5,0.5,1}
            for j=0,count-1 do
                local ratio=math.lerp(low,realHigh,j/(count-1))
                local posUp=self:ratioToPos(ratio,true)
                local posDown=self:ratioToPos(ratio,false)
                table.insert(meshPoints,{posUp.x,posUp.y,x+w,y,color[1],color[2],color[3],1})
                table.insert(shadeMeshPoints,{posUp.x+shadeOffset,posUp.y+shadeOffset,x+w,y,shadeColor[1],shadeColor[2],shadeColor[3],shadeColor[4]})
                table.insert(meshPoints,{posDown.x,posDown.y,x,y,color[1],color[2],color[3],1})
                table.insert(shadeMeshPoints,{posDown.x+shadeOffset,posDown.y+shadeOffset,x,y,shadeColor[1],shadeColor[2],shadeColor[3],shadeColor[4]})
            end
            self.batch:add(shadeMeshPoints,'strip')
            self.batch:add(meshPoints,'strip')
        end
    end

    local itemComboData={combo=0,duration=0,remainingFrames=0,active=false}
    local baseWidth=50
    local remainingFrameMax=60
    local bonuses={{value=20,items={bombPiece=1}},{value=40,items={lifePiece=1}},{value=80,items={bomb=1}},{value=150,items={life=1}},{value=250,items={life=2}}}
    local function durationBonus()
        return 1+itemComboData.duration/30
    end
    local function totalValue()
        return itemComboData.combo*durationBonus()
    end
    local function pickItem()
        if not itemComboData.active then
            itemComboData.active=true
            itemComboData.combo=0
            itemComboData.duration=0
        end
        itemComboData.combo=itemComboData.combo+1
        itemComboData.remainingFrames=remainingFrameMax
    end
    EventManager.listenTo(EventManager.EVENTS.PICK_ITEM, pickItem,EventManager.EVENTS.RELOAD_UI)
    local function spawnBonus()
        local value=totalValue()
        itemComboData.active=false
        local bonusIndex=0
        for index, bonus in ipairs(bonuses) do
            if value >= bonus.value then
                bonusIndex=index
            else
                break
            end
        end
        if bonusIndex==0 then
            return
        end
        local bonus=bonuses[bonusIndex]
        local player=G.runInfo.player
        if not player then
            return
        end
        SFX:play('notice',true)
        local pos,dir=G.runInfo.geometry:rThetaGo(player.kinematicState.pos,80,player.viewDirection-math.pi/2)
        for key, count in pairs(bonus.items) do
            for i=1,count do
                local kinematicState={pos=copyTable(pos),dir=dir+math.eval(0,0.1),speed=math.eval(300,100)}
                Item{kinematicState=kinematicState,type=key}
            end
        end
    end
    EventManager.listenTo(EventManager.EVENTS.PLAYER_PRESS_C,spawnBonus,EventManager.EVENTS.RELOAD_UI)
    local itemComboArea=UI.Base{parent=dynamicObjs,transparency=0,extraUpdates={
    strategy(
        function(self, centerXY, radius)
            self.x,self.y=centerXY[1],centerXY[2]+radius-30
        end,
        function(self, xywh)
            self.x,self.y=xywh[1]+baseWidth+5,xywh[2]+xywh[4]-30
        end
    ),function(self)
        self.transparency=math.lerpCondition(self.transparency,itemComboData.active,1,0,0.1)
        if itemComboData.active then
            itemComboData.duration=itemComboData.duration+1/60
            itemComboData.remainingFrames=itemComboData.remainingFrames-1
            if itemComboData.remainingFrames==0 then
                spawnBonus()
            end
        end
        if DEV_MODE then
            if love.keyboard.isDown(']') then
                itemComboData.combo=itemComboData.combo+1
            elseif love.keyboard.isDown('[') then
                itemComboData.combo=math.max(0,itemComboData.combo-1)
            end
        end
    end}}
    local comboColors={{amount=0,color={0,0,0,1},suffix='',size=14},{amount=20,color={1,1,0,1},suffix='!',size=15},{amount=40,color={1,0.6,0,1},suffix='?!',size=16},{amount=80,color={1,0,0,1},suffix='!!',size=18}}
    local itemComboText=UI.Text{parent=itemComboArea,y=-20,x=-10,align='right',color={0,0,0,1},text='',updateText=function (self)
        local combo=itemComboData.combo
        local text='x'..combo
        local finalIndex=1
        for index, value in ipairs(comboColors) do
            if combo >= value.amount then
                finalIndex=index
            else
                break
            end
        end
        self.color=comboColors[finalIndex].color
        self.fontSize=comboColors[finalIndex].size
        text=text..comboColors[finalIndex].suffix
        return text
    end}
    local itemMultipleSignText=UI.Text{parent=itemComboArea,y=-20,x=0,align='center',color={1,1,1,1},text='x'}
    local itemComboTimeText=UI.Text{parent=itemComboArea,y=-20,x=10,align='left',color={1,1,1,1},text='',updateText=function (self)
        return string.format("%.2f", durationBonus())
    end}
    local itemComboRemainingTime=UI.Panel{parent=itemComboArea,x=-baseWidth,y=-3,width=0,height=2,edgeColor={1,1,0,0},fillColor={1,1,0,1},extraUpdates={function(self)
        local ratio=itemComboData.remainingFrames/remainingFrameMax
        self.width=baseWidth*2*ratio
    end}}
    local itemComboBar=UI.Panel{parent=itemComboArea,x=-1,y=-1,width=2,height=6,edgeColor={1,1,1,0}} -- vertical bar
    local panelShaderCode=[[
    extern vec4 xywh; // x,y,width,height of the panel
    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 pixel_coords)
    {
        vec4 colorBase=Texel(texture, texture_coords)*color;
        // edge fade effect
        float center=xywh.z-50.0;
        float coord=(pixel_coords.x-xywh.x-center)/50.0;
        float awayFromCenter=abs(coord);
        float alphaMultiplier=1.0-awayFromCenter*awayFromCenter;
        return colorBase*vec4(1.0,1.0,1.0,alphaMultiplier);
    }
    ]]
    local panelShader=love.graphics.newShader(panelShaderCode)
    local itemComboProgress=UI.Panel{parent=itemComboArea,x=0,y=1,width=0,height=3,edgeColor={1,1,1,0},shader=panelShader,extraUpdates={function(self)
        local value=totalValue()
        self.x=-math.clamp(value,0,baseWidth)
        self.width=baseWidth-self.x
    end}}
    for index, bonus in ipairs(bonuses) do
        local bonusIndicatorBase=UI.Base{parent=itemComboArea,x=0,y=1,extraUpdates={function (self)
            self.x=bonus.value-totalValue()
            self.transparency=math.clamp(1-(self.x/baseWidth)^2,0,1)
        end}}
        local itemCount=0
        for item,count in pairs(bonus.items) do
            local sprite=Asset.itemSprites[item].indicator
            for i=1,count do
                local bonusIndicator=UI.Image{parent=bonusIndicatorBase,batch=Asset.itemUIBatch,quad=sprite.quad,x=-sprite.data.centerX,y=itemCount*sprite.data.sizeY/2}
                itemCount=itemCount+1
            end
        end
    end

    ----- below are high-level functions to return

    local function showStageTitle(stageKey)
        local mainTitle=Localize{'ui','IN_GAME','STAGE_TITLE',stageKey,'main'}
        local smallTitle=Localize{'ui','IN_GAME','STAGE_TITLE',stageKey,'small'}
        stageTitleText:setText(mainTitle)
        stageTitleSmallText:setText(smallTitle)
        Event.Event{obj=G.runInfo.player,action=function(self)
            wait(240)
            stageTitleText:setText('')
            stageTitleSmallText:setText('')
        end}
    end

    ---@param key NoticeKey
    local function showNotice(key)
        local notice=Localize{'ui','IN_GAME','notices',key}
        noticeText:setText(notice)
        Event.Event{obj=G.runInfo.player,action=function(self)
            wait(120)
            if noticeText.text==notice then -- if the notice is not changed during the 120 frames, then clear it. if it is changed, it means another notice is shown, so do not clear it.
                noticeText:setText('')
            end
        end}
    end

    local function showSoundtrack()
        local soundtrackName=BGM.currentAudio
        local name=Localize{'musicData',soundtrackName,'name'}
        local fullText=Localize{'ui','IN_GAME','bgm',bgm=name}
        soundtrackText:setText(fullText)
        Event.Event{obj=G.runInfo.player,action=function(self)
            wait(120)
            soundtrackText:setText('')
        end}
    end

    local function setRemainingTimeText(time)
        if not time then
            remainingTimeTextLeft:setText('')
            remainingTimeTextRight:setText('')
            return
        end
        local timeStr=string.format("%.2f", time)
        local leftStr, rightStr=timeStr:match("^(%d*)%.(%d*)$")
        remainingTimeTextLeft:setText(leftStr)
        remainingTimeTextRight:setText('.'..rightStr)
    end

    local function slideSpellcardInfo()
        local y0=300
        spellcardInfoMoveUp.y=y0
        Event.Event{obj=G.runInfo.player,action=function(self)
            wait(60)
            for i=1,60 do
                local ratio=i/60
                spellcardInfoMoveUp.y=(1-Event.sineIOProgressFunc(ratio))*y0
                wait()
            end
        end}
    end

    --- when starting a new game
    local function reset()
        stageTitleText:setText('',true)
        stageTitleSmallText:setText('',true)
        noticeText:setText('',true)
        soundtrackText:setText('',true)
        bossNameText:setText('',true)
        bossStars:clearStars()
        setRemainingTimeText(nil)
        spellcardNameText:setText('',true)
        spellcardNameText.transparency=0
        spellcardBonusHistoryText:setText('',true)
        hpBar.hpRatio=0
        itemComboArea.transparency=0
        itemComboData.active=false
    end

    ---@class DynamicObjs
    ---@field showStageTitle fun(stageKey:StageKey):nil
    ---@field showSoundtrack fun():nil reads BGM.currentAudio to display soundtrack name
    ---@field bossNameText DynamicText
    ---@field bossStars BossStars
    ---@field setRemainingTimeText fun(time: number|nil):nil
    ---@field slideSpellcardInfo fun():nil only slides the container of spellcard name and bonus & history text.
    ---@field spellcardNameText DynamicText
    ---@field spellcardBonusHistoryText DynamicText
    DynamicUIObjs={
        showStageTitle=showStageTitle,
        showNotice=showNotice,
        showSoundtrack=showSoundtrack,
        bossNameText=bossNameText,
        bossStars=bossStars,
        setRemainingTimeText=setRemainingTimeText,
        slideSpellcardInfo=slideSpellcardInfo,
        spellcardNameText=spellcardNameText,
        spellcardBonusHistoryText=spellcardBonusHistoryText,
        hpBar=hpBar,
        reset=reset,
    }
end