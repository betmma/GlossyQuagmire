local BackgroundPattern=...

-- love2d draws a white rectangle then shader draws pattern.
local Shader=BackgroundPattern:extend()
---@class ShaderBackground
---@class love.Shader
---@class ShaderBackgroundArgs
---@field shader love.Shader the shader to use for drawing the background
---@field paramSendFunction fun(self:ShaderBackground,shader:love.Shader):nil a function to send parameters to the shader, called in Shader:draw()

---@param args ShaderBackgroundArgs
function Shader:new(args)
    Shader.super.new(self,args)
    args=args or {}
    self.shader=args.shader
    self.frame=0
    self.paramSendFunction=args.paramSendFunction or function(self,shader) end
    self.color={1,1,1}
    self.lightColor={1,1,1}
    self.darkColor={0.5,0.5,0.5}
    self.autoDark=true -- if true, color will be lerped to darkColor when self.darking=true (managed by bossManager, during spellcard) (for very bright shaders)
end
function Shader:update(dt)
    self.frame=self.frame+1
    if self.autoDark then
        local ratio=0.02
        if self.darking then
            self.color=math.lerpTable(self.color,self.darkColor,ratio)
        else
            self.color=math.lerpTable(self.color,self.lightColor,ratio)
        end
    end
end
function Shader:draw()
    local colorref={love.graphics.getColor()}
    love.graphics.setColor(self.color[1],self.color[2],self.color[3])
    -- love.graphics.rectangle('fill',0,0,800,600)
    love.graphics.setShader(self.shader)
    self:paramSendFunction(self.shader) -- send parameters to shader
    local translateX,translateY,scale=0,0,1
    love.graphics.rectangle('fill',-translateX/scale,-translateY/scale,800/scale,600/scale)
    love.graphics.setShader()
    love.graphics.setColor(colorref[1],colorref[2],colorref[3],colorref[4])
end

return Shader