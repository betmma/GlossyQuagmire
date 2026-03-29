local UI=...
--- a textbox that can switch between multiple options. like difficulty selection or toggle volume in options menu. a huge difference between this and options is that options will always show all options and have all ui elements for all options, while switcher will only show and dynamically construct one option at a time (or 1+preview*2 if enabling preview), and only create ui elements for the current option, so switcher is more suitable for things like switching between 0-100 volume.
---@class UISwitcher:UIBase
---@field public optionConstructor fun(self,optionIndex:integer):UIBase|nil a function that constructs the UI for the given option index. this will be called when the switcher needs to switch to a different option and needs to construct the UI for that option. it's considered beginning or end of options when this function returns nil.
---@field public currentOptionIndex integer the current option index. starts from 1.
---@field public currentOption UIBase
---@field private firstPreviewOptionIndex integer the option index of the first preview option. (the first option in arranger's children)
---@field private lerpingOptionIndexOffset number to achieve transition effect (switching option bumps it by 1; it decays to 0)
---@field private preview integer preview how many previous and next options.
---@field private previewDecayMode PREVIEW_DECAY_MODE how the transparency of preview options decays. default to INDEX, which means the transparency is based on the index difference to current option. if set to DISTANCE, the transparency is based on the distance to current option.
---@field private previewDecayRadius number the decay radius for the transparency of preview options. transparency halves every previewDecayRadius distance. if uses INDEX mode, the distance is the index difference.
---@field public container UIArranger
---@field public lerpRatio number the ratio for lerping the position of options when switching. default to 0.2.
---@field public canHold boolean whether holding the switch key will continuously switch options. default to false.
---@field public increaseKey love.KeyConstant the key to switch to next option. can be auto set to arrow keys based on arrange function if not provided.
---@field public decreaseKey love.KeyConstant the key to switch to previous option. can be auto set as above
---@field private switchOption fun(self,direction:integer):nil a function that switches options in the given direction (1 for next, -1 for previous). this will be called when the switch key is pressed.
---@field private makeOptions fun(self):boolean a function that constructs the UI for the current option index and its preview options. returns false if current option index is out of range (optionConstructor returns nil).
---@field private lerpOffset fun(self,ratio:number|nil):nil a function that lerps the lerpingOptionIndexOffset by the given ratio. if ratio is nil, use self.lerpRatio.
local UISwitcher=UI.Base:extend()

---@enum PREVIEW_DECAY_MODE
UISwitcher.PREVIEW_DECAY_MODES={
    DISTANCE=1,
    INDEX=2,
}

---@class UISwitcherConfig
---@field optionConstructor fun(self,optionIndex:integer):UIBase|nil
---@field currentOptionIndex integer|nil
---@field preview integer|nil
---@field previewDecayMode PREVIEW_DECAY_MODE|nil
---@field previewDecayRadius number|nil the minimum transparency for preview options. the transparency of preview options will be linearly interpolated between 1 for current option and this value for the farthest preview option. default to distance of arrange(0) to arrange(1).
---@field container UIArranger|nil
---@field arrange nil|fun(self,index:integer):number,number if container is not provided, will use this to construct an arranger. note that, for simplicity, if arrangement is linear, the output can have arbitrary translation, and this class will position the current option at UISwitcher's x and y. if nonlinear like on a circle, index=0 corresponds to current option.
---@field lerpRatio number|nil
---@field canHold boolean|nil
---@field increaseKey love.KeyConstant|nil
---@field decreaseKey love.KeyConstant|nil
function UISwitcher:new(args)
    UI.Base.new(self,args)
    self.optionConstructor=args.optionConstructor
    self.currentOptionIndex=args.currentOptionIndex or 1
    self.firstPreviewOptionIndex=0
    self.lerpingOptionIndexOffset=0
    self.preview=args.preview or 0
    self.lerpRatio=args.lerpRatio or 0.5
    self.canHold=args.canHold or false
    if args.container then
        self.container=args.container
    else
        local arrangeFunc=args.arrange or function(self,index)
            return index*self.width,0
        end
        local axCurrent,ayCurrent=arrangeFunc(self,0)
        local arrangeFuncWrapped=function(_self,index) -- so that arranger sets position based on index difference to current option, and make current option return 0,0
            local x,y=arrangeFunc(_self,index+self.firstPreviewOptionIndex-1-self.currentOptionIndex+self.lerpingOptionIndexOffset) -- current option will call original arrangeFunc with index=0
            return x-axCurrent,y-ayCurrent
        end
        self.container=UI.Arranger{arrange=arrangeFuncWrapped}
    end
    self.container.canChildHaveFocus=function(container,childIndex) return childIndex+self.firstPreviewOptionIndex-1==self.currentOptionIndex end
    self.previewDecayMode=args.previewDecayMode or UISwitcher.PREVIEW_DECAY_MODES.INDEX
    self.previewDecayRadius=args.previewDecayRadius
    self.increaseKey=args.increaseKey
    self.decreaseKey=args.decreaseKey
    local x0,y0=self.container:arrange(0)
    local x1,y1=self.container:arrange(1)
    if not self.previewDecayRadius then -- default to distance between current option and next option
        if self.previewDecayMode==UISwitcher.PREVIEW_DECAY_MODES.INDEX then
            self.previewDecayRadius=1
        else
            self.previewDecayRadius=math.sqrt((x1-x0)^2+(y1-y0)^2)
        end
    end
    local dx,dy=x1-x0,y1-y0
    if not self.increaseKey then -- auto set increase and decrease keys based on direction to next option
        self.increaseKey=Dxy2DirectionName(dx,dy)
    end
    if not self.decreaseKey then
        self.decreaseKey=Dxy2DirectionName(-dx,-dy)
    end
    self:child(self.container)
    -- initialize options
    self:makeOptions()
    self:lerpOffset(1) -- start with options at the correct position without lerping
end

function UISwitcher:makeOptions()
    -- make currentOptionIndex first. this is kinda ugly as there is no way to know if optionConstructor returns nil (currentOptionIndex is invalid, switchOption should not change currentOptionIndex) without calling it. and once called, it's good to store the result to save one calling before constructing all options
    local currentOption=self.optionConstructor(self,self.currentOptionIndex)
    if not currentOption then
        return false
    end
    local currentOptionReused=false
    local childrenIndexes={} -- store current children with their corresponding option index, so that they can be reused
    for i =#self.container.children,1,-1 do
        childrenIndexes[self.firstPreviewOptionIndex+i-1]=self.container.children[i]
        self.container.children[i]:unchild() -- unchild all current children. they will be rechilded if their index is still in range, or removed if not. cannot leave them in container, otherwise newly added option could have wrong order.
    end
    local firstOption=false
    for i=-self.preview,self.preview do
        local optionIndex=self.currentOptionIndex+i
        local option
        if childrenIndexes[optionIndex] then -- if there is already a child for this option index, reuse it
            option=childrenIndexes[optionIndex]
            childrenIndexes[optionIndex]=nil
        elseif i==0 then -- use the already called optionConstructor result for current option
            option=currentOption
            currentOptionReused=true
        else -- otherwise, call optionConstructor to create a new one
            option=self.optionConstructor(self,optionIndex)
        end
        if option then
            if firstOption==false then -- the first option (the farthest previous preview option) determines the firstPreviewOptionIndex, which is needed for the arrange function to position options correctly
                firstOption=true
                self.firstPreviewOptionIndex=self.currentOptionIndex+i
            end
            self.container:child(option)
            if i==0 then
                self.currentOption=option
            end
        end
    end
    for index,option in pairs(childrenIndexes) do -- remove children that are no longer in range (or is redundant current option)
        if option then
            option:remove()
        end
    end
    if not currentOptionReused then
        currentOption:remove()
    end
    return true
end

function UISwitcher:switchOption(direction)
    self.currentOptionIndex=self.currentOptionIndex+direction
    local success=self:makeOptions()
    if not success then  -- out of options
        self.currentOptionIndex=self.currentOptionIndex-direction -- revert index change
        -- SFX:play('cancel')
    else
        SFX:play('select')
        self:emit(UI.EVENTS.SWITCHED,{index=self.currentOptionIndex})
        self.lerpingOptionIndexOffset=self.lerpingOptionIndexOffset+direction
    end
end

function UISwitcher:lerpOffset(ratio)
    ratio=ratio or self.lerpRatio
    self.lerpingOptionIndexOffset=self.lerpingOptionIndexOffset*(1-ratio)
end

function UISwitcher:update()
    UISwitcher.super.update(self)
    local pressFunc=self.canHold and love.keyboard.isDown or isPressed
    if self.focused then
        if pressFunc(self.increaseKey) then
            self:switchOption(1)
        elseif pressFunc(self.decreaseKey) then
            self:switchOption(-1)
        end
    end
    self:lerpOffset()
    local currentOption=self.currentOption
    if not currentOption then
        return
    end
    local x,y=currentOption:getXY()
    for i, option in ipairs(self.container.children) do
        local ox,oy=option:getXY()
        local distance
        if self.previewDecayMode==UISwitcher.PREVIEW_DECAY_MODES.INDEX then
            distance=math.abs(self.firstPreviewOptionIndex+i-1-self.currentOptionIndex+self.lerpingOptionIndexOffset)
        else
            distance=math.sqrt((ox-x)^2+(oy-y)^2)
        end
        option.transparency=0.5^(distance/math.max(self.previewDecayRadius,0.1))
    end
end

return UISwitcher