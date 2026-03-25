local UI=...
--- set children's position based on their index. this is useful for things like vertical or horizontal lists.
---@class UIArranger:UIBase
---@field public arrange fun(self,index:number):number,number returns the position for the child at the given index.
local UIArranger=UI.Base:extend()
function UIArranger:new(args)
    UI.Base.new(self,args)
    self.arrange=args.arrange
end

function UIArranger:update()
    UIArranger.super.update(self)
    if not self.arrange then return end
    for i, child in ipairs(self.children) do
        local x,y=self.arrange(self,i)
        child.x=x
        child.y=y
    end
end

function UIArranger:child(child)
    UIArranger.super.child(self,child)
    local index=#self.children
    local x,y=self.arrange(self,index)
    child.x=x
    child.y=y
end

return UIArranger