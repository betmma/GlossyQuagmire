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
            circleStrategy(self, centerXY, radius)
        elseif shader==G.CONSTANTS.FOREGROUND_SHADERS.RECTANGLE then
            local xywh=G.foregroundShaderData.args.xywh
            rectangleStrategy(self, xywh)
        end
    end
end

function makeDynamicUIObjs()
    local base=G.UIDEF.IN_GAME.base

    ---@class DynamicText:UIText
    ---@field setText fun(self, text:string):nil set text with fade in/out effect. if text is set to empty string, it will fade out and then set text, otherwise it will set text and then fade in.
    local DynamicText=UI.Text:extend()
    -- set text with fade in/out effect. if text is set to empty string, it will fade out and then set text, otherwise it will set text and then fade in.
    function DynamicText:setText(text)
        if self.text==nil then -- the first set in UI.Text.new() is not considered as a real setText, so just set it directly without fade in/out effect.
            self.text=text
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
                    self.x,self.y=centerXY[1]-150,centerXY[2]-radius+10
                end,
                function(self, xywh)
                    self.x,self.y=xywh[1]+10,xywh[2]+10
                end
            )}
    })
    local bossNameText=bossNameBase:child(DynamicText{
        text='',fontSize=20,color={1,1,1,1},autoSize=true,
        x=0,y=0,align='center',toggleX=true,transparency=0,
        extraUpdates={
            strategy(
                function(self, centerXY, radius)
                    self.align='center'
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
        x=0,y=30,arrange=function(self,index)
            return (index-1)*30,0
        end
    })

    function bossStars:addStar()
        local star=UI.Image{quad=Asset.itemSprites.enemySpellcardIndicator.quad, batch=Asset.itemUIBatch, x=0,y=0}
        self:child(star)
    end

    function bossStars:removeStar()
        if #self.children>0 then
            local toRemove=self.children[#self.children]
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
    local spellcardBonusHistoryText=spellcardInfoMoveUp:child(DynamicText{
        text='',fontSize=16,color={1,1,1,1},autoSize=true,
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
        spellcardInfoMoveUp.y=300
        Event.Event{obj=G.runInfo.player,action=function(self)
            for i=1,60 do
                spellcardInfoMoveUp.y=spellcardInfoMoveUp.y*0.95
                wait()
            end
        end}
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
        showSoundtrack=showSoundtrack,
        bossNameText=bossNameText,
        bossStars=bossStars,
        setRemainingTimeText=setRemainingTimeText,
        slideSpellcardInfo=slideSpellcardInfo,
        spellcardNameText=spellcardNameText,
        spellcardBonusHistoryText=spellcardBonusHistoryText
    }
end