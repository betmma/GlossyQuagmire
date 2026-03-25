local UI=...
--- simple text ui element
---@class UIText:UIBase
---@field public align nil|"center"|"left"|"right"|"justify" if nil, uses love.graphics.print, otherwise uses love.graphics.printf with this align. 
---@field public text string
---@field public color table
---@field public fontSize number
---@field public fontName string|nil if nil, use default font for current language
---@field public toggleX boolean whether to toggle x for more instinctive alignment. if true, with center or justify alignment, center of text will be at x. with right alignment, right edge of text will be at x.
---@field public autoSize boolean whether to automatically set width to the width of the text using font:getWidth, and same to height.
---@field public isBold boolean whether to simulate bold by drawing text multiple times with slight offset.
---@field public boldOffset number the offset ratio for simulating bold (will be multiplied by font size to get actual offset). default to 0.05 = 5% of font size.
---@field public boldColor table the color for simulating bold, default to 1-color with same alpha.
---@field public setText fun(self, text:string):nil set the text of this UIText. this is a function instead of a simple setter because it may need to do some extra work like updating width and height when autoSize is true.
---@field public updateText nil|fun(self):string if set, this function will be called in update to update the text. this is useful for dynamic text that changes every frame, like score or fps.
local UIText=UI.Base:extend()

function UIText:new(args)
    UI.Base.new(self,args)
    self.align=args.align
    self.color=args.color or {1,1,1,1}
    self.color[4]=self.color[4] or 1
    self.fontSize=args.fontSize or 16
    self.fontName=args.fontName
    self.toggleX=args.toggleX~=false
    self.autoSize=args.autoSize or false
    self.isBold=args.isBold~=false
    self.boldOffset=args.boldOffset or 0.05
    self.boldColor=args.boldColor or {1-self.color[1],1-self.color[2],1-self.color[3],self.color[4]}
    self.updateText=args.updateText
    local text=args.text or ""
    self:setText(text)
end

function UIText:getXY()
    local x,y=UI.Base.getXY(self)
    if self.toggleX and self.align then
        if self.align=="center" or self.align=="justify" then
            x=x-self.width/2
        elseif self.align=="right" then
            x=x-self.width
        end
    end
    return x,y
end

function UIText:update()
    UIText.super.update(self)
    if self.updateText then
        self:setText(self.updateText(self))
    end
end

function UIText:setText(text)
    self.text=text
    if self.autoSize then
        local font=SetFont(self.fontSize,self.fontName)
        self.width=font:getWidth(self.text)
        self.height=font:getAscent() - font:getDescent()
    end
end

function UIText:draw()
    local x,y=self:getXY()
    local colorref={love.graphics.getColor()}
    SetFont(self.fontSize,self.fontName)
    love.graphics.setColor(self.color[1],self.color[2],self.color[3],self.color[4]*colorref[4])
    local args={love.graphics.print,self.text,x,y}
    if self.align then
        args[1]=love.graphics.printf
        table.insert(args,self.width)
        table.insert(args,self.align)
    end
    self:boldWrap(unpack(args))
    -- love.graphics.rectangle("line",x,y,self.width,self.height) -- for debugging
    love.graphics.setColor(colorref[1],colorref[2],colorref[3],colorref[4])
    UI.Base.draw(self)
end

function UIText:boldWrap(func,text,x,y,...)
    local offset=self.fontSize*self.boldOffset
    local colorref={love.graphics.getColor()}
    if self.isBold then
        love.graphics.setColor(self.boldColor[1],self.boldColor[2],self.boldColor[3],self.boldColor[4]*colorref[4])
        func(text,x+offset,y,...)
        func(text,x-offset,y,...)
        func(text,x,y+offset,...)
        func(text,x,y-offset,...)
        love.graphics.setColor(colorref[1],colorref[2],colorref[3],colorref[4])
    end
    func(text,x,y,...)
end

return UIText