local UI=...
--- a textbox that can switch between multiple options. like difficulty selection or toggle volume in options menu. a huge difference between this and options is that options will always show all options and have all ui elements for all options, while switcher will only show and dynamically construct one option at a time (or 3 if enabling preview), and only create ui elements for the current option, so switcher is more suitable for things like switching between 0-100 volume.
---@class UISwitcher:UIBase
---@field public optionConstructor fun(self,optionIndex:integer):UIBase|nil a function that constructs the UI for the given option index. this will be called when the switcher needs to switch to a different option and needs to construct the UI for that option. it's considered beginning or end of options when this function returns nil.
---@field public currentOptionIndex integer the current option index. starts from 1.
---@field public currentOption UIBase
---@field private preview integer preview how many previous and next options.
---@field private previewDecayRadius number the decay radius for the transparency of preview options. further from the aim position of current option, more transparent.
---@field public container UIArranger
---@field private offsetX number used to position the current option at the center of the switcher.
---@field private offsetY number 
---@field public lerpRatio number the ratio for lerping the position of options when switching. default to 0.2.
---@field public canHold boolean whether holding the switch key will continuously switch options. default to false.
---@field public increaseKey love.KeyConstant the key to switch to next option. default to "right".
---@field public decreaseKey love.KeyConstant the key to switch to previous option. default to "left".
---@field private switchOption fun(self,direction:integer):nil a function that switches options in the given direction (1 for next, -1 for previous). this will be called when the switch key is pressed.
---@field private makeOptions fun(self):boolean a function that constructs the UI for the current option index and its preview options. returns false if current option index is out of range (optionConstructor returns nil).
---@field private lerpContainer fun(self,ratio:number|nil):nil a function that lerps the position of the container towards the target position based on the current option. this should be called in update to create the lerping effect when switching options.
local UISwitcher=UI.Base:extend()

---@class UISwitcherConfig
---@field optionConstructor fun(self,optionIndex:integer):UIBase|nil
---@field currentOptionIndex integer|nil
---@field preview integer|nil
---@field previewDecayRadius number|nil the minimum transparency for preview options. the transparency of preview options will be linearly interpolated between 1 for current option and this value for the farthest preview option. default to distance of arrange(0) to arrange(1).
---@field container UIArranger|nil
---@field arrange nil|fun(self,index:integer):number,number if container is not provided, will use this to construct an arranger. note that, for simplicity, the output can have arbitrary translation, and this class will position the current option at UISwitcher's x and y
---@field lerpRatio number|nil
---@field canHold boolean|nil
---@field increaseKey love.KeyConstant|nil
---@field decreaseKey love.KeyConstant|nil
function UISwitcher:new(args)
    UI.Base.new(self,args)
    self.optionConstructor=args.optionConstructor
    self.currentOptionIndex=args.currentOptionIndex or 1
    self.preview=args.preview or 0
    self.lerpRatio=args.lerpRatio or 0.5
    self.increaseKey=args.increaseKey or "right"
    self.decreaseKey=args.decreaseKey or "left"
    self.canHold=args.canHold or false
    if args.container then
        self.container=args.container
    else
        local arrangeFunc=args.arrange or function(self,index)
            return index*self.width,0
        end
        local arrangeFuncWrapped=function(_self,index) -- so that arranger sets position based on option index (with preview offset but doesn't matter)
            local x,y=arrangeFunc(_self,index+self.currentOptionIndex)
            return x,y
        end
        self.container=UI.Arranger{arrange=arrangeFuncWrapped}
    end
    self.previewDecayRadius=args.previewDecayRadius
    if not self.previewDecayRadius then
        local x0,y0=self.container:arrange(0)
        local x1,y1=self.container:arrange(1)
        self.previewDecayRadius=math.sqrt((x1-x0)^2+(y1-y0)^2)
    end
    self:child(self.container)
    -- initialize options
    self:makeOptions()
    self:lerpContainer(1) -- start with options at the correct position without lerping
end

function UISwitcher:makeOptions()
    -- make currentOptionIndex first
    local currentOption=self.optionConstructor(self,self.currentOptionIndex)
    if not currentOption then
        return false
    end
    for i =#self.container.children,1,-1 do
        self.container.children[i]:remove()
    end
    for i=-self.preview,self.preview do
        local option=i==0 and currentOption or self.optionConstructor(self,self.currentOptionIndex+i)
        if option then
            self.container:child(option)
            if i==0 then
                self.currentOption=option
            end
        end
    end
    self:updateOffsets()
    return true
end

function UISwitcher:lerpContainer(ratio)
    ratio=ratio or self.lerpRatio
    self.container.x=self.container.x+(self.offsetX-self.container.x)*ratio
    self.container.y=self.container.y+(self.offsetY-self.container.y)*ratio
end

function UISwitcher:updateOffsets()
    local currentOption=self.currentOption
    local index=1
    for i, option in ipairs(self.container.children) do
        if option==currentOption then
            index=i
            break
        end
    end
    if currentOption then
        local dx,dy=self.container:arrange(index)
        self.offsetX=-dx
        self.offsetY=-dy
    else
        self.offsetX=0
        self.offsetY=0
    end
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
    self:lerpContainer()
    local x,y=self:getXY()
    for i, option in ipairs(self.container.children) do
        local ox,oy=option:getXY()
        local distance=math.sqrt((ox-x)^2+(oy-y)^2)
        option.transparency=0.5^(distance/math.max(self.previewDecayRadius,0.1))
    end
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
    end
    self:updateOffsets()
end


return UISwitcher