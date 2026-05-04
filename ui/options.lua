local UI=...
--- a bunch of elements arranged. have a cursor to select one of the options.
---@class UIOptions:UIBase
---@field public cursor UICursor
---@field private container UIBase the options container. should be a child of this, but not necessarily the direct child.
---@field public addOption fun(self: UIOptions, option: UIBase) add an option to the container.
---@field public switchOptionOnDirection fun(self: UIOptions, direction: number|string) switch to another option.
---@field public switchOption fun(self: UIOptions, option: UIBase, snap: boolean|nil, init: boolean|nil) switch to another option. if snap is true, cursor will snap to the new option immediately instead of lerping.
---@field public loopable boolean whether to loop around when switching options. default true.
---@overload fun(args: UIOptionsArgs): UIOptions
local UIOptions=UI.Base:extend()

---@class UIOptionsArgs:UIBaseArgs
---@field loopable boolean|nil whether to loop around when switching options. default true.
---@field container UIBase|nil the options container. usually an arranger to arrange the options
---@field cursor UICursor|nil the cursor to indicate the current option. if not provided, a default UICursor will be used.

function UIOptions:new(args)
    UI.Base.new(self,args)
    self.loopable=args.loopable~=false
    self.container=args.container or UI.Base()
    self:child(self.container)
    self.cursor=args.cursor or UI.Cursor()
    self.child=function(self,child)
        if child:is(UI.Cursor) then
            UI.Base.child(self,child)
            return child
        end
        error("Childing to UIOptions does not add an option. Use addOption instead.")
    end
    self.container.canChildHaveFocus=function(container,childIndex)
        return container.children[childIndex]==self.cursor.parent
    end
end

function UIOptions:clearOptions()
    for i=#self.container.children,1,-1 do
        local child=self.container.children[i]
        child:remove()
    end
    self.cursor:unchild()
end

function UIOptions:addOption(option)
    self.container:child(option)
    if self.cursor.parent==nil then
        self:switchOption(option,true,true)
    end
end

function UIOptions:update()
    UIOptions.super.update(self)
    if self.cursor.parent and self.focused then
        for i,key in pairs(KEYS.DIRECTIONS) do
            if isPressed(key) then
                self:switchOptionOnDirection(key)
                break
            end
        end
        if isPressed(KEYS.SELECT) then
            self.cursor.parent:emit(UI.EVENTS.SELECT,self.cursor.parent)
        end
    end
end

function UIOptions:switchOptionOnDirection(direction)
    if not self.cursor.parent then return end
    local options=self.container.children
    local currentOption=self.cursor.parent
    ---@cast currentOption UIBase
    local x,y=self.cursor:getCenterXY()
    local DEFAULT_SCORE_ABS=50000
    local bestScore,bestOption=-DEFAULT_SCORE_ABS,currentOption
    local dirx,diry=DirectionName2Dxy(direction)
    for i,option in pairs(options) do
        if option.disabled then
            goto continue
        end
        local ox,oy=option:getCenterXY()
        local dx,dy=ox-x,oy-y
        local score=0
        local distance=math.sqrt(dx*dx+dy*dy)
        score=score-distance*2 -- prefer closer nodes
        local angle=math.angleDiff(math.atan2(dy,dx),math.atan2(diry,dirx))
        if math.angleDiff(angle,math.pi/2)<math.pi/30 then
            angle=math.pi/2
        end
        local angleDeduction=5/math.clamp(math.abs(math.cos(angle)),1/DEFAULT_SCORE_ABS,1)
        score=score-angleDeduction
        if angle>math.pi*0.49 then
            if self.loopable then -- backwards is acceptable (better than -DEFAULT_SCORE_ABS) but worse than forewards
                score=score-DEFAULT_SCORE_ABS/2
                score=score+distance*4 -- when backwards, prefer farther nodes for looping
            else
                score=score-DEFAULT_SCORE_ABS*2 -- don't go backwards (worse than staying still)
            end
        end
        if score>bestScore and option ~= currentOption then
            bestScore=score
            bestOption=option
        end
        ::continue::
    end
    if bestOption==currentOption then return end
    self:switchOption(bestOption)
end

function UIOptions:switchOption(option,snap,init)
    if option.disabled then return end
    if self.cursor.parent then
        self.cursor.parent:emit(UI.EVENTS.UNFOCUS)
        self.cursor:unchild()
    end
    local asFirst=self.cursor.drawStyle==UI.Cursor.DRAW_STYLE.Face -- face style cursor should be under the option, line style cursor should be above the option
    option:child(self.cursor,asFirst)
    option:emit(UI.EVENTS.FOCUS,{init=init})
    if not init then
        SFX:play('select')
    end
    if snap then
        self.cursor:snap()
    end
end

return UIOptions
