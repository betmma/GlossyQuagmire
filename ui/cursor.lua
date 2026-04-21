local UI=...
--- a cursor used to select options and navigate menus. note that cursor does not use relative coordinates. it always uses absolute coordinates to lerp between positions
---@class UICursor:UIBase
---@field public color table
---@field public lineLengthRatio number the ratio of line length to half of the width/height of the cursor
---@field public useShortSide boolean whether to let line length be lineLengthRatio*min(width, height)/2 instead of lineLengthRatio*width/2 and lineLengthRatio*height/2. 
---@field public lineWidth number the width of the cursor lines
---@field public lerpRatio number the ratio of lerp, between 0 and 1.
---@field public fluctuateRatio number the ratio of fluctuation
---@field public fluctuatePeriod number the period of fluctuation in frames
---@field public snap fun(self):nil snap the cursor to its parent immediately.
local UICursor=UI.Base:extend()
function UICursor:new(args)
    args=args or {}
    args.events=args.events or {}
    -- args.events[UI.EVENTS.SET_PARENT]=args.events[UI.EVENTS.SET_PARENT] or function(self, parent)
    --     self:setParent(parent)
    -- end
    UI.Base.new(self,args)
    self.color=args.color or {0,0,0,1}
    self.lineLengthRatio=args.lineLengthRatio or 0.5
    self.useShortSide=args.useShortSide~=false
    self.lineWidth=args.lineWidth or 2
    self.lerpRatio=args.lerpRatio or 0.2
    self.fluctuateRatio=args.fluctuateRatio or 0.1
    self.fluctuatePeriod=args.fluctuatePeriod or 60
end

-- function UICursor:setParent(parent)
--     self.x,self.y=parent:getXY()
--     self.width,self.height=parent.width,parent.height
-- end

function UICursor:getXY()
    return self.x,self.y
end

function UICursor:update()
    UICursor.super.update(self)
    if self.parent then
        local targetX,targetY=self.parent:getXY()
        self.x=self.x+(targetX-self.x)*self.lerpRatio
        self.y=self.y+(targetY-self.y)*self.lerpRatio
        self.width=self.width+(self.parent.width-self.width)*self.lerpRatio
        self.height=self.height+(self.parent.height-self.height)*self.lerpRatio
    end
end

function UICursor:snap()
    if self.parent then
        local targetX,targetY=self.parent:getXY()
        self.x=targetX
        self.y=targetY
        self.width=self.parent.width
        self.height=self.parent.height
    end
end

function UICursor:drawText()
    local x,y=self:getXY()
    local fluctuation=(math.sin(self.frame/self.fluctuatePeriod*2*math.pi)*0.5+0.5)*self.fluctuateRatio
    local dw,dh=self.width*fluctuation,self.height*fluctuation
    x,y=x-dw/2,y-dh/2
    local w,h=self.width+dw,self.height+dh
    local colorref={love.graphics.getColor()}
    love.graphics.setColor(self.color[1],self.color[2],self.color[3],self.color[4])
    local lineLengthX=self.lineLengthRatio*w/2
    local lineLengthY=self.lineLengthRatio*h/2
    if self.useShortSide then
        lineLengthX=math.min(lineLengthX,lineLengthY)
        lineLengthY=math.min(lineLengthX,lineLengthY)
    end
    -- 8 lines for a rectangle cursor (middle of each side is empty)
    local widthRef=love.graphics.getLineWidth()
    love.graphics.setLineWidth(self.lineWidth)
    love.graphics.line(x,y,x+lineLengthX,y)
    love.graphics.line(x+w,y,x+w-lineLengthX,y)
    love.graphics.line(x,y+h,x+lineLengthX,y+h)
    love.graphics.line(x+w,y+h,x+w-lineLengthX,y+h)
    love.graphics.line(x,y,x,y+lineLengthY)
    love.graphics.line(x+w,y,x+w,y+lineLengthY)
    love.graphics.line(x,y+h,x,y+h-lineLengthY)
    love.graphics.line(x+w,y+h,x+w,y+h-lineLengthY)
    love.graphics.setColor(colorref[1],colorref[2],colorref[3],colorref[4])
    love.graphics.setLineWidth(widthRef)
end

return UICursor