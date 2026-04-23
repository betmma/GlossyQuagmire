---@class Border: GameObject
---@field isInside fun(self:Border, pos:Position):boolean
---@field findInside fun(self:Border, pos:Position):Position find an inside position to the given position. the default implementation scans angles to find the general direction of the border, then uses binary search along the average successful angle to find the closest entry point. subclasses can override this for better performance.
local Border=GameObject:extend()

function Border:isInside(pos)
    return true
end

function Border:findInside(pos)
    if self:isInside(pos) then
        return pos
    end
    local g=G.runInfo.geometry
    local radius=10
    local successx,successy=0,0
    local successCount=0
    for firstRoundTries=1,3 do
        for angle=0,math.pi*2,math.pi/18 do
            local testPos=g:rThetaGo(pos,radius,angle)
            if self:isInside(testPos) then
                local x,y=math.cos(angle),math.sin(angle)
                successx=successx+x
                successy=successy+y
                successCount=successCount+1
            end
        end
        if successCount>0 then
            break
        end
        radius=radius*2
    end
    if successCount == 0 then
        return pos -- failed
    end
    local averageAngle=math.atan2(successy,successx)
    -- then, use binary search to find a more accurate radius
    local low,high=0,radius
    for i=1,10 do
        local mid=(low+high)/2
        local testPos=g:rThetaGo(pos,mid,averageAngle)
        if self:isInside(testPos) then
            high=mid
        else
            low=mid
        end
    end
    local finalPos=g:rThetaGo(pos,high,averageAngle)
    return finalPos
end


---@class XYBorder: Border
---@field minx number
---@field maxx number
---@field miny number
---@field maxy number 
local XYBorder=Border:extend()

---@class XYBorderArgs:strict
---@field minx number
---@field maxx number
---@field miny number
---@field maxy number
function XYBorder:new(args)
    XYBorder.super.new(self,args)
    self.minx=args.minx
    self.maxx=args.maxx
    self.miny=args.miny
    self.maxy=args.maxy
end

function XYBorder:isInside(pos)
    return pos.x>=self.minx and pos.x<=self.maxx and pos.y>=self.miny and pos.y<=self.maxy
end

function XYBorder:findInside(pos)
    return {
        x=math.clamp(pos.x,self.minx,self.maxx),
        y=math.clamp(pos.y,self.miny,self.maxy)
    }
end

Border.XYBorder=XYBorder

---@class CircleBorder: Border
---@field center Position
---@field radius number
local CircleBorder=Border:extend()

---@class CircleBorderArgs:strict
---@field center Position
---@field radius number
function CircleBorder:new(args)
    CircleBorder.super.new(self,args)
    self.center=args.center
    self.radius=args.radius
end

function CircleBorder:isInside(pos)
    local g=G.runInfo.geometry
    return g:distance(pos,self.center)<=self.radius
end

function CircleBorder:findInside(pos)
    if self:isInside(pos) then
        return pos
    end
    local g=G.runInfo.geometry
    local dir=g:to(self.center,pos)
    return g:rThetaGo(self.center,self.radius-1e-5,dir)
end

function CircleBorder:draw()
    MeshFuncs.ringMesh(self.center,self.radius,self.radius+20,0,BulletSprites.laser.white.quad,96,{1,1,1,1},nil,Asset.laserMeshes)
end

Border.CircleBorder=CircleBorder

return Border