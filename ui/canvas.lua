local UI=...

---@class UICanvas:UIBase
---@field public canvas love.Canvas
---@overload fun(args:UICanvasArgs):UICanvas
local UICanvas=UI.Base:extend()

---@class UICanvasArgs:UIBaseArgs
---@field canvasWidth number? defaults to width
---@field canvasHeight number? defaults to height

---@param args UICanvasArgs
function UICanvas:new(args)
    args=args or {}
    UI.Base.new(self,args)
    args.canvasWidth=args.canvasWidth or args.width
    args.canvasHeight=args.canvasHeight or args.height
    self.canvas=love.graphics.newCanvas(args.canvasWidth,args.canvasHeight)
end

function UICanvas:drawText()
    local x,y=self:getXY()
    love.graphics.draw(self.canvas,x,y,0,self.width/self.canvas:getWidth(),self.height/self.canvas:getHeight())
end

return UICanvas