local Action={}

---@class Action
---@field isAction true
---@field params table<string, any>
---@field func fun(self:Bullet, params:table<string, any>):nil it should not modify the params as this table may be shared among multiple objects. store into self if needed.
---@field init (fun(self:Bullet, params:table<string, any>):nil)|nil an optional function to initialize the action, called at bullet:new. 


local fadeOut=function(self,params)
    local fadeFrame=params.fadeFrame or 30
    if self.frame+fadeFrame>=self.lifeFrame then
        if params.setSafe then
            self.safe=true
        end
        self.spriteTransparency=(self.lifeFrame - self.frame)/fadeFrame
    end
end

---@param fadeFrame integer number of frames for the fade out animation, default 30
---@param setSafe boolean whether to set the bullet safe when start fading out, default false
--- @return Action
Action.FadeOut=function(fadeFrame,setSafe)
    return {isAction=true,params={fadeFrame=fadeFrame,setSafe=setSafe},func=fadeOut}
end

local fadeIn=function(self,params)
    local fadeFrame=params.fadeFrame or 30
    if self.frame<=fadeFrame then
        if params.setSafe then
            self.safe=true
        end
        self.spriteTransparency=(params.fadeTransparency or 1) * self.frame/fadeFrame
    elseif self.frame==fadeFrame+1 then
        if params.setSafe then
            self.safe=false
        end
    end
end

local fadeInInit=function(self,params)
    self.spriteTransparency=0
    if params.setSafe then
       self.safe=true
    end
end

---@param fadeFrame integer number of frames for the fade in animation, default 30
---@param setSafe boolean whether to set the bullet safe when start fading in, default false
---@param fadeTransparency number|nil if you want to set a specific transparency instead of 0-1, default nil
--- @return Action
Action.FadeIn=function(fadeFrame,setSafe,fadeTransparency)
    return {isAction=true,params={fadeFrame=fadeFrame,setSafe=setSafe,fadeTransparency=fadeTransparency},func=fadeIn,init=fadeInInit}
end

local zoomOut=function(self,params)
    local zoomFrame=params.zoomFrame or 30
    local initialSize=self.sizeReference or self.size
    if self.frame+zoomFrame>=self.lifeFrame then
        self.sizeReference=self.sizeReference or initialSize
        self.size=initialSize*(self.lifeFrame - self.frame)/zoomFrame
    end
end

--- the bullet shrinks from its size to 0 in the last [zoomFrame] frames of its life.
--- @param zoomFrame integer number of frames for the zoom out animation, default 30
--- @return Action
Action.ZoomOut=function(zoomFrame)
    return {isAction=true,params={zoomFrame=zoomFrame},func=zoomOut}
end

local zoomIn=function(self,params)
    local zoomFrame=params.zoomFrame or 30
    local targetSize=params.targetSize or self.zoomInTargetSize
    if self.frame<=zoomFrame then
        self.size=targetSize*self.frame/zoomFrame
    end
end

local zoomInInit=function(self,params)
    self.zoomInTargetSize=self.size
    self.size=0
end

-- bullet size grows from 0 to [self.targetSize] in [self.zoomFrame] frames.
--- @param zoomFrame integer number of frames for the zoom animation, default 30
--- @param targetSize number|nil target size for the zoom animation, default self.size
--- @return Action
Action.ZoomIn=function(zoomFrame,targetSize)
    return {isAction=true,params={zoomFrame=zoomFrame,targetSize=targetSize},func=zoomIn,init=zoomInInit}
end

local appearingHint=function(self,params)
    if self.appearingHintexecuted then
        return
    end
    self.appearingHintexecuted=true
    local size=params.size or self.size*2
    local duration=params.duration or 10
    local spriteColor=self.sprite and self.sprite.data and self.sprite.data.color or 'gray'
    local shockwaveColor=Asset.spectrum1MapSpectrum2[spriteColor] or 'gray'
    Effect.Larger{kinematicState=self.kinematicState,sprite=BulletSprites.shockwave[shockwaveColor],size=size,growSpeed=-size/duration,animationFrame=duration,spriteTransparency=0.8}
end

--- a shrinking shockwave to hint something appears.
--- @param size number|nil size of the hint, default self.size*2
--- @param duration integer|nil number of frames for the hint animation, default 10
Action.AppearingHint=function(size,duration)
    return {isAction=true,params={size=size,duration=duration},func=appearingHint}
end


local actionPack=function(self,params)
    for k,action in ipairs(params) do
        action.func(self,action.params)
    end
end

--- execute multiple actions. a way to nest actions and make preset action combinations.
--- @param actions table<string, Action> a table of actions to be executed.
Action.Pack=function(actions)
    return {isAction=true,params=actions,func=actionPack}
end

return Action