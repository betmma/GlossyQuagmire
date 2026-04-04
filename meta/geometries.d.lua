---@meta


---@class ViewConfig
---@field following boolean whether the view will follow the player.
---@field screenCenter Position if following is true, the view will put player at this position on screen.

---@class Position cannot assume it's always 2 dimensional!
---@field x number
---@field y number

---@class ScreenPosition
---@field x number
---@field y number

---@alias PossiblePosition ScreenPosition|Dummy

---@class Viewer
---@field viewDirection number note that it doesn't need to be the same as the direction of movement.
---@field kinematicState KinematicState

---@class KinematicState
---@field pos Position
---@field speed number
---@field dir number


---Returns a default kinematic state. Objects in game will have kinematic states.
---@alias def.GeometryBase.init fun(self:GeometryBase):KinematicState
---Updates the kinematic state. Note that, this may choose not to use the precise rThetaGo. from previous experience, approximation is good enough.
---@alias def.GeometryBase.update fun(self:GeometryBase,state:KinematicState,dt:number):nil
---From the [position], facing the [direction] and go [length] units forward, return the new position and the new direction facing. Note that the returned position MUST NOT be the same table as the input position.
---@alias def.GeometryBase.rThetaGo fun(self:GeometryBase,position:Position,length:number,direction:number):Position,number
---Returns the distance between two positions.
---@alias def.GeometryBase.distance fun(self:GeometryBase,position1:Position,position2:Position):number
---From the [position], the direction facing the [target] (if multiple directions are possible, return the one along which the distance is shortest).
---@alias def.GeometryBase.to fun(self:GeometryBase,position:Position,target:Position):number
---Returns which side of the line formed by linePoint1 and linePoint2 the position is on. It doesn't matter which side is true or false.
---@alias def.GeometryBase.sideToLine fun(self:GeometryBase,position:Position,linePoint1:Position,linePoint2:Position):boolean
---Convert the position in geometry space to screen space. It's possible to return multiple positions for later shader processing, and the draw function needs to handle that. If returns multiple positions (like to two circles), ensure the order (first element goes to the first circle. If does not map to first circle, first element should be Dummy). It could consider the viewConfig (and like following in it).
---@alias def.GeometryBase.toScreen fun(self:GeometryBase,position:Position):PossiblePosition[]
---Returns whether an object at the position with the radius (in geometry space) can be drawn with a simple quad within acceptable distortion. If false, the object should be drawn with a custom mesh and second return value indicates the suggested number of sides in the mesh. Second value is STILL MEANINGFUL if first value is true, as draw function can still choose to draw with mesh for better visual effect.
---@alias def.GeometryBase.canSimpleDraw fun(self:GeometryBase,position:Position,radius:number):boolean,integer
---Apply shader for drawing objects in this geometry if needed. The viewer is usually the player, and the shader will need the viewer's position and direction to do correct projection.
---@alias def.GeometryBase.applyDrawShader fun(self:GeometryBase,viewer:Viewer):nil
---Apply shader for drawing foreground. Like make a rectangle hole to show the gameplay area.
---@alias def.GeometryBase.applyForegroundShader fun(self:GeometryBase):nil
---From the [position], the distance to the target and the direction facing the [target] (if multiple values are possible, return the shortest distance and the corresponding direction).
---@alias def.GeometryBase.rThetaTo fun(self:GeometryBase,position:Position,target:Position):number,number
---Returns the zoom factors at the screen space of the position (one for each toScreen results). It's used to draw quads (only a square) where distortion is negligible (and with prerequisite that the geometry is conformal). The default implementation calls toScreen on position and position+small value to estimate.
---@alias def.GeometryBase.zoomFactorToScreen fun(self:GeometryBase,position:Position):number[]

---@class GeometryBase:Object base class for all geometries. is actually euclidean geometry as an example (and also because lua annotation doesnt support abstract classes). should not be instantiated as only its methods are used.
---@field init def.GeometryBase.init
---@field update def.GeometryBase.update
---@field rThetaGo def.GeometryBase.rThetaGo
---@field distance def.GeometryBase.distance
---@field to def.GeometryBase.to
---@field sideToLine def.GeometryBase.sideToLine
---@field toScreen def.GeometryBase.toScreen
---@field canSimpleDraw def.GeometryBase.canSimpleDraw
---@field MESH_MAX_SIDES integer the maximum number of sides that the geometry will suggest for canSimpleDraw, can control performance. note that, even if not reaching MESH_MAX_SIDES, the geometry can still adjust the number of sides based on this (like math.floor(MESH_MAX_SIDES*0.5))
---@field applyDrawShader def.GeometryBase.applyDrawShader
---@field applyForegroundShader def.GeometryBase.applyForegroundShader
---@field public viewConfig ViewConfig
--------below are methods defaulted to be composed by using the above methods, but you can override them for better performance if you want.
---@field rThetaTo def.GeometryBase.rThetaTo
---@field zoomFactorToScreen def.GeometryBase.zoomFactorToScreen



---@class Hyperbolic:GeometryBase
---@field curvature number
---@field axisY number
---@field EPS number
---@field viewConfig HyperbolicViewConfig
---@field init def.GeometryBase.init
---@field update def.GeometryBase.update
---@field rThetaGo def.GeometryBase.rThetaGo
---@field distance def.GeometryBase.distance
---@field to def.GeometryBase.to
---@field sideToLine def.GeometryBase.sideToLine
---@field toScreen def.GeometryBase.toScreen
---@field canSimpleDraw def.GeometryBase.canSimpleDraw
---@field applyDrawShader def.GeometryBase.applyDrawShader
---@field applyForegroundShader def.GeometryBase.applyForegroundShader
---@field rThetaTo def.GeometryBase.rThetaTo
---@field zoomFactorToScreen def.GeometryBase.zoomFactorToScreen


---@class Spherical:GeometryBase
---@field init def.GeometryBase.init
---@field update def.GeometryBase.update
---@field rThetaGo def.GeometryBase.rThetaGo
---@field distance def.GeometryBase.distance
---@field to def.GeometryBase.to
---@field sideToLine def.GeometryBase.sideToLine
---@field toScreen def.GeometryBase.toScreen
---@field canSimpleDraw def.GeometryBase.canSimpleDraw
---@field applyDrawShader def.GeometryBase.applyDrawShader
---@field applyForegroundShader def.GeometryBase.applyForegroundShader
---@field rThetaTo def.GeometryBase.rThetaTo
---@field zoomFactorToScreen def.GeometryBase.zoomFactorToScreen