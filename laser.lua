--[[geodesic laser: area between two straight rays perpendicular to the diameter of a circle:
|--->
.
|--->
]]

---@class GeoLaserMeshBudget:strict
---@field step number|nil the distance between each point on the rays that define the laser's area. default 70.
---@field num number|nil the number of points to add between the two rays to fill the area of the laser. default 20.
---@field capNum number|nil the number of points to add to the end of the laser to make it look more rounded. default 16.
---@class GeoLaser:Bullet
---@field getRays fun(self:GeoLaser):GeoLaserRays Calculates the positions and directions of the rays that define the laser's area.
---@field meshBudget GeoLaserMeshBudget
local GeoLaser=Bullet:extend()

---@class GeoLaserArgs:BulletArgs
---@field meshBudget GeoLaserMeshBudget|nil parameters that control the density and appearance of the laser's mesh. 
function GeoLaser:new(args)
    args.invincible=args.invincible~=false
    args.forceMesh=true
    GeoLaser.super.new(self, args)
    self.meshBudget=args.meshBudget or {}
end

---@param pos Position
---@param w number
---@param h number
---@param rotation number
---@param quad love.Quad
---@param color rgbaColor|nil
---@param meshBatch MeshBatch
---@param sideNum integer
function GeoLaser:meshDrawQuad(pos,w,h,rotation,quad,color,meshBatch,sideNum)
    MeshFuncs.twoRaysMesh(self:getRays(),quad,color,meshBatch,self.meshBudget)
end


---@class Ray:strict
---@field pos Position
---@field dir angle
---@field pos2 Position -- a point further along the ray, for convenience in calling geometry functions that require two points to define a line.
---@class RayPair:strict
---@field left Ray
---@field right Ray
---@class GeoLaserRays:strict
---@field center Position
---@field hitbox RayPair
---@field border RayPair
---@field hitboxRadius number
---@field borderRadius number

function GeoLaser:getRays()
    local hitboxRadius=self:getHitboxRadius()
    local quadX,quadY,w,h=self.sprite.quad:getViewport()
    local borderRadius=w/2*self.size
    local direction=self.kinematicState.dir
    local pos=self.kinematicState.pos
    local getRay=function(radius,i)
        local rayDir=direction+math.pi/2*i
        local rayEnd,rayDir2=G.runInfo.geometry:rThetaGo(pos,radius,rayDir)
        rayDir2=rayDir2-math.pi/2*i
        local pos2, _=G.runInfo.geometry:rThetaGo(rayEnd,radius*2,rayDir2)
        return {pos=rayEnd,dir=rayDir2,pos2=pos2}
    end
    return {
        center=pos,
        hitbox={
            left=getRay(hitboxRadius,-1),
            right=getRay(hitboxRadius,1)
        },
        border={
            left=getRay(borderRadius,-1),
            right=getRay(borderRadius,1)
        },
        hitboxRadius=hitboxRadius,
        borderRadius=borderRadius
    }
end

function GeoLaser:collide(pos,radius)
    if self.size==0 then -- size=0 will cause strange hit
        return false
    end
    local rays=self:getRays().hitbox
    local innerSide=true
    for _,ray in ipairs({rays.left,rays.right}) do
        local pos1,dir,pos2=ray.pos,ray.dir,ray.pos2
        local closest=G.runInfo.geometry:nearestToLine(pos,pos1,pos2)
        local distance=G.runInfo.geometry:distance(pos,closest)
        local dirToClosest=G.runInfo.geometry:to(pos1,closest)
        innerSide=innerSide and G.runInfo.geometry:sideToLine(pos,pos1,pos2)==G.runInfo.geometry:sideToLine(self.kinematicState.pos,pos1,pos2)
        local correctHalf=math.angleDiff(dir,dirToClosest)<math.pi/2
        if not correctHalf then
            return false
        end
        if distance<radius then
            return true
        end
    end
    if innerSide then
        return true
    end
    return false
end

function GeoLaser:checkShockwaveRemove()
    for k,shockwave in pairs(Effect.Shockwave.objects) do
        ---@cast shockwave Shockwave
        if shockwave.canRemove.bullet==true and
        (self.invincible==false or shockwave.canRemove.invincible==true) and
        (self.safe==false or shockwave.canRemove.safe==true) and
        (self.fromPlayer==false or shockwave.canRemove.fromPlayer==true) and
        self:collide(shockwave.kinematicState.pos, shockwave:getHitboxRadius()) then
            self:shrinkAndRemove()
        end
    end
end

function GeoLaser:checkHitPlayer()
    if self.safe then return end
    for key, player in pairs(Player.objects) do
        ---@cast player Player
        local graze=self:collide(player.kinematicState.pos, player:getHitboxRadius()*player.grazeRadiusFactor)
        local hit=self:collide(player.kinematicState.pos, player:getHitboxRadius())
        if graze and self.frame%3==0 then
            EventManager.post(EventManager.EVENTS.PLAYER_GRAZE,player,self:grazeValue())
        end
        if player.invincibleFrame<=0 and hit then
            EventManager.post(EventManager.EVENTS.PLAYER_HIT,player,self.damage or 1)
        end
    end
end

function GeoLaser:removeEffect()
end

function GeoLaser:shrinkAndRemove()
    self.safe=true
    self.lifeFrame=self.frame+20
    self.extraUpdate[#self.extraUpdate+1] = Action.ZoomOut(20)
end

return GeoLaser
