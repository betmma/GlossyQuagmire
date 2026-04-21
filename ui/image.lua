local UI=...

---@class UIImage:UIBase
---@field public batch love.SpriteBatch
---@field public quad love.Quad
---@field public r number rotation in radians
---@field public sx number scale x
---@field public sy number scale y
local UIImage=UI.Base:extend()
function UIImage:new(args)
    UI.Base.new(self,args)
    self.batch=args.batch
    self.quad=args.quad
    self.r=args.r or 0
    self.sx=args.sx or 1
    self.sy=args.sy or 1
end

function UIImage:draw()
    UIImage.super.draw(self)
    if self.batch and self.quad then
        local x,y=self:getXY()
        self.batch:add(self.quad,x,y,self.r,self.sx,self.sy)
    end
end

return UIImage