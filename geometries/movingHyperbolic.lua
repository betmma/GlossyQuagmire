---@type Hyperbolic
local Hyperbolic=...

---@class MovingHyperbolic
local MovingHyperbolic=Hyperbolic:extend()

---@class MovingHyperbolicViewConfig:HyperbolicViewConfig
---@field zoomCenterX number
---@field zoomRatio number

---@type MovingHyperbolicViewConfig
MovingHyperbolic.viewConfig={
    following=false,
    -- screenCenter={x=WINDOW_HEIGHT/2-WINDOW_WIDTH/40,y=WINDOW_HEIGHT/2},
    -- hyperbolicModel=Hyperbolic.HYPERBOLIC_MODELS.P_DISK,
    screenCenter={x=WINDOW_WIDTH/40*13,y=WINDOW_HEIGHT/2},
    hyperbolicModel=Hyperbolic.HYPERBOLIC_MODELS.UHP,
    diskRadiusBase={
        [Hyperbolic.HYPERBOLIC_MODELS.P_DISK]=14/15,
        [Hyperbolic.HYPERBOLIC_MODELS.K_DISK]=14/15
    },
    zoomCenterX=WINDOW_WIDTH/40*13, -- the center of rectangle foreground shader area
    zoomRatio=1.002
}

function MovingHyperbolic:init()
    return {pos={x=self.viewConfig.screenCenter.x,y=self.viewConfig.screenCenter.y},speed=0,dir=0}
end

function MovingHyperbolic:update(state,dt)
    Hyperbolic:update(state,dt)
    if state.skipZoom then
        return
    end
    state.pos.x=math.lerp(self.viewConfig.zoomCenterX,state.pos.x,self.viewConfig.zoomRatio)
    state.pos.y=math.lerp(Hyperbolic.axisY,state.pos.y,self.viewConfig.zoomRatio)
end

return MovingHyperbolic