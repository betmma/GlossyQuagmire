

---@type OneStageDataRaw
return{
    init=function()
        if G.runInfo.geometry==G.geometries.Euclidean then
            G.runInfo.geometry=copyRecursiveTable(G.runInfo.geometry)
            local geo=G.runInfo.geometry
            ---@cast geo PortalGeometryBase
            geo.portal=true
            geo.viewConfig.following=true
            local applyVertexShaderRef=geo.applyVertexShader
            geo.applyVertexShader=function(self,viewer)
                local vx,vy=viewer.kinematicState.pos.x,viewer.kinematicState.pos.y
                local zoom=Portal.zoomFactor(viewer.kinematicState.pos)
                zoom=1/zoom
                local x,y=geo.viewConfig.screenCenter.x,geo.viewConfig.screenCenter.y
                love.graphics.translate(x,y)
                love.graphics.rotate(-viewer.viewDirection)
                love.graphics.scale(zoom,zoom)
                love.graphics.translate(-vx,-vy)
            end
            local zoomFactorToScreenRef=geo.zoomFactorToScreen
            geo.zoomFactorToScreen=function(self,position)
                local ret={1}--zoomFactorToScreenRef(self,position) -- anyway, the overall method doesn't work for hyperbolic and spherical geometry, as cannot "zoom" the view at all. about the original zoomFactorToScreen, there is a problem that it calls update that is portal version but should be original one. once that is fixed, actually does not need to override.
                local zoomFactorFromPortal=Portal.zoomFactor(position)--/Portal.zoomFactor(G.runInfo.player.kinematicState.pos)
                for i=1,#ret do
                    ret[i]=ret[i]*zoomFactorFromPortal
                end
                return ret
            end
            local updateRef=geo.update
            geo.update=function(self,kinematicState,dt)
                local zoomFromPortal=Portal.zoomFactor(kinematicState.pos)
                updateRef(self,kinematicState,dt*zoomFromPortal)
                local pos,delta=Portal.considerTeleport(kinematicState.pos)
                kinematicState.pos=pos
                kinematicState.dir=kinematicState.dir+delta
            end
            local rThetaGoRef=geo.rThetaGo
            geo.rThetaGoRef=rThetaGoRef
            local rThetaGo=function(self,position,length,direction)
                local segment=math.ceil(length/Portal.range)
                local stepLength=length/segment
                for i=1,segment do
                    position, direction=rThetaGoRef(self,position,stepLength,direction)
                    position, delta=Portal.considerTeleport(position)
                    direction=direction+delta
                end
                return position,direction
            end
            local toRef=geo.to
            geo.toRef=toRef
            local distanceRef=geo.distance
            geo.distanceRef=distanceRef
            local rThetaToRef=geo.rThetaTo
            --- compare direct distance and distances through every portal. ignore zoom effect.
            local rThetaTo=function(self,position,target)
                local bestDistance=distanceRef(self,position,target)
                local bestDirection=toRef(self,position,target)
                for i,portal in ipairs(Portal.objects) do
                    ---@cast portal Portal
                    local pos1,pos2=portal.pos1,portal.pos2
                    local posIn=geo:nearestToLine(position,pos1,pos2)
                    local sizeIn=portal.size
                    local linkedPortal=portal.linked
                    local linkedSize=linkedPortal.size
                    local pos3,pos4=linkedPortal.pos1,linkedPortal.pos2
                    local posOut=geo:nearestToLine(target,pos3,pos4)
                    local distanceToPortal=geo:distanceRef(position,posIn)
                    local distanceFromPortal=geo:distanceRef(posOut,target)
                    local ratioIn=geo:distanceRef(pos1,posIn)/sizeIn
                    local ratioOut=geo:distanceRef(pos3,posOut)/linkedSize
                    local ratio=math.interpolate(ratioIn,ratioOut,distanceFromPortal/(distanceToPortal+distanceFromPortal))
                    if ratio<0 or ratio>1 then
                        ratio=math.clamp(ratio,0,1)
                    end
                    local posIn2=geo:rThetaGoRef(pos1,sizeIn*ratio,geo:toRef(pos1,pos2))
                    local posOut2=geo:rThetaGoRef(pos3,linkedSize*ratio,geo:toRef(pos3,pos4))
                    local totalDistance=geo:distanceRef(position,posIn2)+geo:distanceRef(posOut2,target)
                    if totalDistance<bestDistance then
                        bestDistance=totalDistance
                        bestDirection=geo:toRef(position,posIn)
                    end
                end
                return bestDistance,bestDirection
            end
            local distance=function(self,position1,position2)
                local distance,direction=geo:rThetaTo(position1,position2)
                return distance
            end
            local to=function(self,position,target)
                local distance,direction=geo:rThetaTo(position,target)
                return direction
            end
            geo.enterPhase=function(self,phase)
                if phase=='update' then
                    self.rThetaGo=rThetaGo
                    self.to=to
                    self.distance=distance
                    self.rThetaTo=rThetaTo
                elseif phase=='draw' then
                    self.rThetaGo=rThetaGoRef
                    self.to=toRef
                    self.distance=distanceRef
                    self.rThetaTo=rThetaToRef
                end
            end
            local border=Border.XYBorder{minx=20,maxx=500,miny=30,maxy=560}
            G.runInfo.player.border=border
            -- G:replaceBackgroundPatternIfNot(BackgroundPattern.Corridor)
        end
        BGM:play('level3',true)
        DynamicUIObjs.showSoundtrack()
    end,
    segments={
        {
            key='4-1',
            type='midStage',
            func=function()
                local geo=G.runInfo.geometry
                local pos0=geo:init().pos
                local portal1=Portal({x=100,y=320},{x=500,y=450},{x=300,y=500})
                local portal2=Portal({x=200,y=520},{x=400,y=520},{x=300,y=400})
                portal1:link(portal2)
                wait(9999)
            end
        }
    }
}