local UI=...
---@class UIPanel:UIBase
---@field public edgeWidth number the width of the panel edge
---@field public edgeColor table the color of the panel edge
---@field public fillColor table the color of the panel fill
local UIPanel=UI.Base:extend()
function UIPanel:new(args)
    args=args or {}
    UI.Base.new(self,args)
    self.edgeWidth=args.edgeWidth or 2
    self.edgeColor=args.edgeColor or {0,0,0,1}
    self.fillColor=args.fillColor or {1,1,1,1}
end

function UIPanel:draw()
    local x,y=self:getXY()
    local colorRef={love.graphics.getColor()}
    love.graphics.setColor(self.fillColor[1],self.fillColor[2],self.fillColor[3],self.fillColor[4]*colorRef[4])
    love.graphics.rectangle("fill",x,y,self.width,self.height)
    love.graphics.setColor(self.edgeColor[1],self.edgeColor[2],self.edgeColor[3],self.edgeColor[4]*colorRef[4])
    love.graphics.setLineWidth(self.edgeWidth)
    love.graphics.rectangle("line",x,y,self.width,self.height)
    love.graphics.setColor(colorRef)
end

return UIPanel