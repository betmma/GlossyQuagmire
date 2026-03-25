--- UIBase is the base class for all UI elements, such as textbox, image, option

---@class UIBase:Object
---@field public x number
---@field public y number
---@field public width number
---@field public height number
---@field public disabled boolean whether this UI element is disabled. if true, cannot be selected by cursor.
---@field public focused boolean whether this UI element is focused by cursor.
---@field public frame number
---@field public transparency number between 0 and 1, multiplied to the alpha value of all children and itself.
---@field public parent UIBase|nil
---@field public children table<number, UIBase>
---@field public child fun(self,child:UIBase):UIBase add a child UI element to this element. return the child element for chaining
---@field public unchild fun(self):nil remove this element from its parent
---@field public getXY fun(self):number,number get the actual position of this UI element on screen, which is the sum of its own x,y and all its parents' x,y
---@field public getCenterXY fun(self):number,number return getXY + half of width and height
---@field public canChildHaveFocus fun(self,childIndex:integer):boolean root element of ui will get focus between update is called. if an element has focus, after its update, it will pass focus to all children that this function returns true.
---@field public draw fun(self):nil
---@field public update fun(self):nil
---@field public extraUpdates (fun(self):nil)[] a list of extra update functions to be called in update
---@field public emit fun(self,eventName:UIEvent,...):nil what this element does when an event is emitted on it. like get focus, lose focus, or confirmed by cursor
---@field public events table<UIEvent, fun(self, ...):nil> a table of event handlers. when an event is emitted, if this table has a handler for that event, it will be called.
---@field public remove fun(self):nil
local UIBase=Object:extend()

function UIBase:new(args)
    args=args or {}
    self.x=args.x or 0
    self.y=args.y or 0
    self.width=args.width or 100
    self.height=args.height or 100
    self.frame=0
    if args.parent then
        args.parent:child(self)
    end
    self.children={}
    self.events=args.events or {}
    self.disabled=args.disabled or false
    self.focused=false
    self.transparency=args.transparency or 1
    self.extraUpdates=args.extraUpdates or {}
end

function UIBase:child(child)
    if not child then
        error("Child cannot be nil")
    end
    table.insert(self.children,child)
    child.parent=self
    child:emit(UI.EVENTS.SET_PARENT,self)
    return child
end

function UIBase:unchild()
    if self.parent then
        for i, child in ipairs(self.parent.children) do
            if child==self then
                table.remove(self.parent.children,i)
                break
            end
        end
        self.parent=nil
    end
end

function UIBase:getXY()
    if self.parent then
        local parentX,parentY=self.parent:getXY()
        return self.x+parentX,self.y+parentY
    else
        return self.x,self.y
    end
end

function UIBase:getCenterXY()
    local x,y=self:getXY()
    return x+self.width/2,y+self.height/2
end

function UIBase:draw()
    
end

function UIBase:update()
    self.frame=self.frame+1
    for _, update in ipairs(self.extraUpdates) do
        update(self)
    end
end

-- UI system is different from other game objects, as it passes update calls from parent to child, instead of the classes pass updateAll to subclasses. why? since draw order depends on the hierarchy, draw calls cannot come from class passing down to subclasses, instead it has to come from the root of the hierarchy and pass down to children. so update follows the same pattern to keep it consistent. updateAll is only used to clear removed elements.
function UIBase:cleanObjects()
  for key, cls in pairs(self.subclasses) do
      cls:cleanObjects()
  end
  local nextObjects={}
  for i, obj in ipairs(self.objects) do
    if not obj.removed then
      table.insert(nextObjects,obj)
    end
  end
  self.objects=nextObjects
end

function UIBase:canChildHaveFocus()
    return true
end

function UIBase:updateHierarchy()
    self:update()
    local hasFocus=self.focused
    self.focused=false
    for key, obj in pairs(self.children) do
        if hasFocus and self:canChildHaveFocus(key) then
            obj.focused=true
        end
        obj:updateHierarchy()
    end
end

function UIBase:drawHierarchy()
    local colorRef={love.graphics.getColor()}
    love.graphics.setColor(colorRef[1],colorRef[2],colorRef[3],self.transparency*colorRef[4])
    self:draw()
    for i, child in ipairs(self.children) do
        child:drawHierarchy()
    end
    love.graphics.setColor(colorRef[1],colorRef[2],colorRef[3],colorRef[4])
end

function UIBase:emit(eventName,args,...)
    if self.events[eventName] then
        args=args or {}
        self.events[eventName](self, args, ...)
    end
end

function UIBase:remove()
    if self.children then
        for i=#self.children,1,-1 do
            self.children[i]:remove()
        end
    end
    if self.parent then
        for i, child in ipairs(self.parent.children) do
            if child==self then
                table.remove(self.parent.children,i)
                break
            end
        end
    end
    self.removed=true
end

---@alias UIEvent "FOCUS"|"UNFOCUS"|"SELECT"|"SET_PARENT"|"SWITCHED"
local UI={
    ---@type table<UIEvent,string>
    EVENTS={
        FOCUS="focus",
        UNFOCUS="unfocus",
        SELECT="select",
        SET_PARENT="setParent",
        SWITCHED="switched",
    },
    Base=UIBase,
}

UI.Panel=love.filesystem.load("ui/panel.lua")(UI)
UI.Cursor=love.filesystem.load("ui/cursor.lua")(UI)
UI.Text=love.filesystem.load("ui/text.lua")(UI)
UI.Image=love.filesystem.load("ui/image.lua")(UI)
UI.Arranger=love.filesystem.load("ui/arranger.lua")(UI)
UI.Options=love.filesystem.load("ui/options.lua")(UI)
UI.Switcher=love.filesystem.load("ui/switcher.lua")(UI)

return UI