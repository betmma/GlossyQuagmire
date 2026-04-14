local Asset={}
---@alias color string
---@class spriteData
---@field size number|nil if size is defined, sizeX and sizeY will be set to this value
---@field sizeX number sprite size in pixels
---@field sizeY number
---@field centerX number (hitbox) center x of the sprite. defaulted to sizeX/2
---@field centerY number center y of the sprite
---@field hitRadius number?
---@field color color?
---@field key string key in Asset.bulletSprites like "round"
---@field isLaser boolean? if the sprite is laser (needs different drawing method) 
---@field isGIF boolean? if the sprite is gif (circle.lua will copy table, randomize initial frame and call update for it)
---@field isSquare boolean? if true, will draw a square instead of a circle. quad always draw square and only mesh drawing need to know this.
---@field possibleColors color[]?

---@class love.Quad

---@class Sprite:Object
---@field quad love.Quad when drawing, use like love.graphics.draw(sprite.quad, ...)
---@field data spriteData
local Sprite=Object:extend()
Asset.Sprite=Sprite

---@param quad love.Quad
---@param data spriteData
function Sprite:new(quad,data)
    data.sizeX=data.size or data.sizeX
    data.sizeY=data.size or data.sizeY
    data.centerX=data.centerX or data.sizeX/2
    data.centerY=data.centerY or data.sizeY/2
    self.quad=quad
    self.data=data
end

---@class GIFSprite:Sprite
---@field private quads love.Quad[]
---@field private currentFrame number
---@field private frameTime number 
---@field private switchCounting number 
---@field randomizeCurrentFrame fun(self):nil randomize the current frame, called when creating a new bullet with the sprite, so that not all bullets with the same sprite are in sync
local GIFSprite=Sprite:extend()
Asset.GIFSprite=GIFSprite

---@class GIFSpriteData:spriteData
---@field frameTime number
---@field currentFrame integer|nil
---@field isGIF true
--- @param quads love.Quad[] array of quads, each quad is a frame of the gif
--- @param data GIFSpriteData
function GIFSprite:new(quads,data)
    data.isGIF=true
    self.currentFrame=data.currentFrame or 1
    GIFSprite.super.new(self,quads[self.currentFrame],data)
    self.quads=quads
    if #quads==0 then
        error('GIFSprite:new: quads array is empty')
    end
    self.frameTime=data.frameTime or 1
    self.switchCounting=0
end

--- Important reason of why don't naming it update: Such object inheriting Object is removed in G.removeAll which calls Object:removeAll when entering or exiting level (remove an object only removes it from Class.objects. :remove is not a garbage collector lol so the object is still usable), so Object.updateAll won't find this object and won't call it automatically. To avoid confusion, we name it countDown instead of update. It's called in circle.lua.
function GIFSprite:countDown()
    self.switchCounting=self.switchCounting+1
    if self.switchCounting>=self.frameTime then
        self.switchCounting=0
        self.currentFrame=self.currentFrame%#self.quads+1
        self.quad=self.quads[self.currentFrame]
    end
end

local randomSeed=0
function GIFSprite:randomizeCurrentFrame()
    self.currentFrame=math.ceil(math.pseudoRandom(randomSeed)*#self.quads)
    randomSeed=(randomSeed+1)%99999
    self.quad=self.quads[self.currentFrame]
end

function GIFSprite:reset()
    self.currentFrame=1
    self.quad=self.quads[self.currentFrame]
end

function GIFSprite:getDuration()
    return self.frameTime*#self.quads
end

---@alias MovingSpriteState 'normal'|'moveTransition'|'moving'

---@class MovingSprite:Sprite sprite including normal (not moving), transition left/right and left/right variations. Calculate which to use on countdown(). Used for player and fairy.
---@field normal love.Quad[]
---@field moveTransition {left:love.Quad[],right:love.Quad[]}
---@field moving {left:love.Quad[],right:love.Quad[]}
---@field tilt integer range is -#moveTransition.left*frameTime.left to #moveTransition.right*frameTime.right
---@field keptFrame integer how many frames have been kept in the current state, used for animation of normal and moving state.
---@field frameTime table<MovingSpriteState,integer>
---@field data MovingSpriteData
---@overload fun(quads:MovingSpriteQuads,data:MovingSpriteData):MovingSprite
local MovingSprite=Sprite:extend()
Asset.MovingSprite=MovingSprite
---@class MovingSpriteQuads
---@field normal love.Quad[] -- animation of normal state
---@field moveTransition {left:love.Quad[],right:love.Quad[]} -- these quads are more and more tilted, not animation of same tilt extent.
---@field moving {left:love.Quad[],right:love.Quad[]} -- animation of moving (most tilted) state

---@class MovingSpriteData:spriteData
---@field frameTime table<MovingSpriteState,integer>

---@param quads MovingSpriteQuads
---@param data MovingSpriteData
function MovingSprite:new(quads,data)
    self.quads=quads
    if not quads then
        error('MovingSprite:new: quads is nil')
    end
    if not quads.normal or not quads.moveTransition or not quads.moving then
        error('MovingSprite:new: quads must have normal, moveTransition and moving')
    end
    GIFSprite.super.new(self,quads.normal[1],data)
    self.frameTime=data.frameTime
    self.state='normal'
    self.tilt=0
    self.keptFrame=0
end

---@param movingLeft boolean
---@param movingRight boolean
function MovingSprite:countDown(movingLeft, movingRight)
    -- 1 means moving right, -1 means moving left, 0 means not moving
    local rightness=(movingRight and 1 or 0)-(movingLeft and 1 or 0)
    local tilt,keptFrame=self.tilt,self.keptFrame
    local tiltMax=#self.quads.moveTransition[tilt<0 and 'left' or 'right']*self.data.frameTime.moveTransition -- max tilt is the duration of transition
    if tilt==0 then -- normal state
        if rightness==0 then -- not moving
            keptFrame=keptFrame+1 -- keeping unmove
        else -- start moving
            keptFrame=0
            tilt=tilt+rightness
        end
    elseif math.abs(tilt)==tiltMax then -- moving (max tilt) state
        if math.sign(rightness)==math.sign(tilt) then -- keep moving at the same direction
            keptFrame=keptFrame+1
        else -- not moving at the same direction
            keptFrame=0
            tilt=tilt-math.sign(tilt) -- reduce tilt towards 0
        end
    else -- in transition
        keptFrame=0 -- keptFrame is not used in transition state
        tilt=tilt+(rightness==0 and -math.sign(tilt) or rightness) -- if not moving, reduce tilt towards 0. if do move, add tilt towards the moving direction. 
    end
    self.tilt=tilt
    self.keptFrame=keptFrame
    local direction=tilt>0 and 'right' or 'left'
    if tilt==0 then
        local index=math.ceil(keptFrame/self.data.frameTime.normal)%#self.quads.normal+1
        self.quad=self.quads.normal[index]
    elseif math.abs(tilt)==tiltMax then
        local index=math.ceil(keptFrame/self.data.frameTime.moving)%#self.quads.moving[direction]+1
        self.quad=self.quads.moving[direction][index]
    else
        local index=math.ceil(math.abs(tilt)/self.data.frameTime.moveTransition)
        self.quad=self.quads.moveTransition[direction][index]
    end
end

local playerImage = love.graphics.newImage( "assets/player.png" )
Asset.playerImage=playerImage

local bulletImage = love.graphics.newImage( "assets/bullets.png" )
Asset.bulletImage=bulletImage
bulletImage:setFilter("nearest", "linear") -- this "linear filter" removes some artifacts if we were to scale the tiles

local hitRadius={laser=4,scale=2.4,rim=2.4,round=4,rice=2.4,kunai=2.4,crystal=2.4,bill=2.8,bullet=2.4,blackrice=2.4,star=4,darkdot=2.4,dot=2.4,bigStar=7,bigRound=8.5,butterfly=7,knife=6,ellipse=7,fog=8.5,heart=10,giant=14,lightRound=14,hollow=2.4,flame=6,orb=6,moon=60,nuke=96,explosion=38,snake=2.4}
Asset.hitRadius=hitRadius

local fairyImage = love.graphics.newImage( "assets/fairy.png" )
Asset.fairyImage=fairyImage

love.filesystem.load('loadBulletSprites.lua')(Asset)
---@type AssetPlayerShotSpritesCollection
Asset.playerShotSprites=Asset.playerShotSprites
---@type AssetFairySpritesCollection
Asset.fairySprites=Asset.fairySprites
---@type playerSpectrum
Asset.playerSprites=Asset.playerSprites

Asset.spectrum1MapSpectrum2={white='gray',gray='gray',red='red',orange='red',yellow='yellow',green='green',teal='green',cyan='blue',blue='blue',purple='purple',magenta='purple',black='gray'}

local bgImage = love.graphics.newImage( "assets/bg.png" )
Asset.backgroundImage=bgImage
Asset.backgroundQuad=love.graphics.newQuad(0,0,bgImage:getWidth(),bgImage:getHeight(),bgImage:getWidth(),bgImage:getHeight())
-- Asset.backgroundLeft=love.graphics.newQuad(0,0,150,bgImage:getHeight(),bgImage:getWidth(),bgImage:getHeight())
Asset.backgroundRight=love.graphics.newQuad(500,0,300,bgImage:getHeight(),bgImage:getWidth(),bgImage:getHeight())
local titleImage = love.graphics.newImage( "assets/title.png" )
Asset.title=love.graphics.newQuad(0,0,1280,720,titleImage:getWidth(),titleImage:getHeight())

local bossImage = love.graphics.newImage( "assets/placeholderBossSprite.png" )
bossImage:setFilter("nearest", "nearest")
Asset.bossImage=bossImage
local bossWidth,bossHeight=80,80
---@type {width:number,height:number,[string]:{key:string,width:number,height:number,normal:love.Quad[]}}
Asset.boss={}
Asset.boss.width,Asset.boss.height=bossWidth,bossHeight
local bossImagePoses={{name='placeholder',num=4},{name='asama',num=2},{name='toyohime',num=4},{name='ariya',num=4},{name='chimi',num=4},{name='urumi',num=2},{name='yuugi',num=2},{name='nareko',num=2},{name='ubame',num=2},{name='aya',num=2},{name='minamitsu',num=2},{name='seija',num=2},{name='clownpiece',num=2},{name='keiki',num=2},{name='yukari',num=2},{name='youmu',num=2},{name='marisa',num=2},{name='yatsuhashi',num=2},{name='kotoba',num=4},{name='byakuren',num=2},{name='doremy',num=4},{name='mike',num=2},{name='takane',num=2},{name='nina',num=2,x0=2,y0=1},{name='mystia',num=2,x0=2,y0=5},{name='nitori',num=2,x0=2,y0=6},{name='seiran',num=2,x0=2,y0=7},{name='eika',num=2,x0=2,y0=8},{name='patchouli',num=2,x0=2,y0=9},{name='reisen',num=2,x0=2,y0=10},{name='shou',num=2,x0=2,y0=11},{name='utsuho',num=2,x0=2,y0=12},{name='okina',num=2,x0=2,y0=13},{name='flandre',num=2,x0=2,y0=14},{name='sakuya',num=2,x0=2,y0=15},{name='renko',num=2,x0=2,y0=16},{name='benben',num=2,x0=2,y0=17},{name='junko',num=2,x0=2,y0=19},{name='nemuno',num=2,x0=2,y0=21},{name='cirno',num=2,x0=2,y0=22}}
for i,info in pairs(bossImagePoses) do
    Asset.boss[info.name]={key='boss',width=bossWidth,height=bossHeight,normal={}}
    for j=1,info.num do
        Asset.boss[info.name].normal[j]=love.graphics.newQuad(((info.x0 or 0) + j-1)*bossWidth,(info.y0 or i-1)*bossHeight,bossWidth,bossHeight,bossImage:getWidth(),bossImage:getHeight())
    end
end



local portraitsImage=love.graphics.newImage('assets/portraits.png')
local portraitWidth=512
local portraitHeight=512
Asset.portraitWidth,Asset.portraitHeight=portraitWidth,portraitHeight
---@type table<string,table<string,love.Quad>> speaker -> expression -> quad
Asset.portraitQuads={}
local speakerList={'benben','doremy','kotoba','marisa','nitori','reimu','sakuya','yatsuhashi','youmu'}
local speakerExpressionList={'angry','frustrated','happy','normal','sad','surprised'}
for i,speaker in ipairs(speakerList) do
    Asset.portraitQuads[speaker]={}
    for j,expression in ipairs(speakerExpressionList) do
        Asset.portraitQuads[speaker][expression]=love.graphics.newQuad((j-1)*portraitWidth,(i-1)*portraitHeight,portraitWidth,portraitHeight,portraitsImage:getDimensions())
    end
end

--[[
Batches are used to seperate different draw layers. Generally, order should be:

Background (backgroundPattern class)
Enemy with HP bar (boss)
Player bullets
Player
Enemy without HP bar
Items (niy)
Enemy bullets highlighted (add blend mode)
Enemy bullets
Effects
Player spell (niy)
Player focus 
UI (left half and right half foreground)
Dialogue 
Dialogue Characters 
]]
---@class SpecialBatch:Object
---@field type string 'mesh' or 'function' or other types if needed
---@field contents table
---@field add fun(self, item) add item to batch
---@field clear fun(self) clear batch contents
---@field flush fun(self) for batches that need to be flushed before drawing, like sprite batches
---@field draw fun(self) draw the batch, for function batch, call all functions in contents
local SpecialBatch=Object:extend()
function SpecialBatch:new(type)
    self.type=type
    self.contents={}
end
function SpecialBatch:add(item)
    self.contents[#self.contents+1]=item
end
function SpecialBatch:clear()
    for i=1,#self.contents do
        self.contents[i]=nil
    end
end
function SpecialBatch:flush()
end
function SpecialBatch:draw()
end

---@alias MeshVertices {[1]:number,[2]:number,[3]:number,[4]:number,[5]:number,[6]:number,[7]:number,[8]:number}[]

---@class MeshBatch:SpecialBatch Used for drawing shapes with mesh for better quality. It maintains one mesh and adds vertices on :add() for higher performance. it can only draw from one image.
---@field image love.Image
---@field mesh love.Mesh
---@field capacity integer maximum number of vertices the mesh can hold. can auto grow
---@field vertexCount integer current number of vertices in the mesh
---@field vertices MeshVertices
---@overload fun(image:love.Image,initialCapacity:integer):MeshBatch
local MeshBatch=SpecialBatch:extend()
function MeshBatch:new(image,initialCapacity)
    MeshBatch.super.new(self,'mesh')
    initialCapacity=initialCapacity or 1000
    self.image=image
    self.capacity=initialCapacity
    self.vertexCount=0
    self.vertices={}
    self.mesh= love.graphics.newMesh(initialCapacity, "triangles", "dynamic")
    self.mesh:setTexture(self.image)
end

---@param vertices MeshVertices array of vertices, each vertex is {x,y,u,v,r,g,b,a}
---@param mode "triangles"|"fan"|"strip" the mesh uses triangles and will auto convert vertices from given mode to triangles
function MeshBatch:add(vertices,mode)
    local vertexCount=#vertices
    local neededVertexCount=vertexCount
    if mode=='fan' then
        neededVertexCount=(vertexCount-2)*3
    elseif mode=='strip' then
        neededVertexCount=(vertexCount-2)*3
    end
    local neededCapacity=self.vertexCount+neededVertexCount
    if neededCapacity>self.capacity then
        -- doubles
        self.capacity=math.max(neededCapacity,self.capacity*2)
        local newMesh=love.graphics.newMesh(self.capacity, "triangles", "dynamic")
        newMesh:setTexture(self.image)
        self.mesh=newMesh
    end
    if mode=="triangles" then
        for i,vertex in pairs(vertices) do
            self.vertexCount=self.vertexCount+1
            self.vertices[self.vertexCount]=vertex
        end
    elseif mode=="fan" then
        for i=2,vertexCount-1 do
            self.vertexCount=self.vertexCount+1
            self.vertices[self.vertexCount]=vertices[1]
            self.vertexCount=self.vertexCount+1
            self.vertices[self.vertexCount]=vertices[i]
            self.vertexCount=self.vertexCount+1
            self.vertices[self.vertexCount]=vertices[i+1]
        end
    elseif mode=="strip" then
        for i=1,vertexCount-2 do
            self.vertexCount=self.vertexCount+1
            self.vertices[self.vertexCount]=vertices[i]
            self.vertexCount=self.vertexCount+1
            self.vertices[self.vertexCount]=vertices[i+1]
            self.vertexCount=self.vertexCount+1
            self.vertices[self.vertexCount]=vertices[i+2]
        end
    end
end

function MeshBatch:clear()
    self.vertexCount=0
end

function MeshBatch:flush()
    if self.vertexCount > 0 then
        self.mesh:setVertices(self.vertices, 1, self.vertexCount)
        self.mesh:setDrawRange(1, self.vertexCount)
    end
end

function MeshBatch:draw()
    if self.vertexCount > 0 then
        love.graphics.draw(self.mesh)
    end
end

--- for love.graphics function calls
--- @class FunctionBatch:SpecialBatch
---@overload fun(self):FunctionBatch
local FunctionBatch=SpecialBatch:extend()
function FunctionBatch:new()
    FunctionBatch.super.new(self,'function')
end
function FunctionBatch:draw()
    for i, func in pairs(self.contents) do
        func()
    end
end

Asset.titleBatch=love.graphics.newSpriteBatch(titleImage,1,'stream') -- title screen
-- for boss effects like hexagon and hp bar
Asset.bossEffectMeshes=MeshBatch(Asset.bulletImage,500)
Asset.bossMeshes=MeshBatch(Asset.bossImage,5)
Asset.fairyBatch=love.graphics.newSpriteBatch(fairyImage,100,'stream')
Asset.playerBatch=love.graphics.newSpriteBatch(playerImage, 5,'stream')
Asset.playerBulletMeshes=MeshBatch(playerImage,200)
Asset.playerBulletBatch=love.graphics.newSpriteBatch(playerImage, 2000,'stream')
Asset.bigBulletMeshes=MeshBatch(Asset.bulletImage,1000)
Asset.bulletHighlightBatch = love.graphics.newSpriteBatch(bulletImage, 2000,'stream')
Asset.laserMeshes=MeshBatch(Asset.bulletImage,1000)
Asset.bulletBatch = love.graphics.newSpriteBatch(bulletImage, 2000,'stream')
Asset.effectBatch=love.graphics.newSpriteBatch(bulletImage, 2000,'stream')
Asset.playerFocusMeshes=MeshBatch(Asset.bulletImage,5)
-- deprecated, use meshes for higher quality. maybe useful if a level has thousands of focus points and lags for meshes
Asset.playerFocusBatch=love.graphics.newSpriteBatch(bulletImage, 5,'stream')
Asset.foregroundBatch=love.graphics.newSpriteBatch(bgImage,5,'stream')
Asset.portraitBatch=love.graphics.newSpriteBatch(portraitsImage,2)
Asset.dialogueBatch=FunctionBatch()
Asset.Batches={
    {
        name='MAIN',
        batches={
            Asset.bossEffectMeshes,
            Asset.bossMeshes,
            Asset.playerBatch,
            Asset.playerBulletMeshes,
            Asset.playerBulletBatch,
            Asset.fairyBatch,
            Asset.bigBulletMeshes,
            Asset.bulletHighlightBatch,
            Asset.laserMeshes,
            Asset.bulletBatch,
            Asset.effectBatch,
            Asset.playerFocusMeshes,
            Asset.playerFocusBatch,
        }
    },
    {
        name='UI',
        batches={
            Asset.foregroundBatch,
            Asset.titleBatch, -- draw the logo at bottom right in game
            Asset.portraitBatch,
            Asset.dialogueBatch,
        }
    }
}
Asset.BatchesList={}
for layer, batches in pairs(Asset.Batches) do
    for key, batch in pairs(batches.batches) do
        table.insert(Asset.BatchesList,batch)
    end
end
--- batch:{before:fun()|nil,after:fun()|nil}
Asset.batchExtraActions={
    [Asset.foregroundBatch]={ -- foreground always draw 800*600 full image and use a shader to make it hollow.
        before=function()
            G.runInfo.geometry:applyForegroundShader()
        end,
        after=function()
            love.graphics.setShader()
        end
    }
}
for i,batch in pairs(Asset.BatchesList) do
    if not Asset.batchExtraActions[batch] then
        Asset.batchExtraActions[batch]={}
    end
end
local isHighlightBatch={}
isHighlightBatch[Asset.playerBulletMeshes]=true
isHighlightBatch[Asset.playerBulletBatch]=true
isHighlightBatch[Asset.bigBulletMeshes]=true
isHighlightBatch[Asset.bulletHighlightBatch]=true
isHighlightBatch[Asset.laserMeshes]=true
Asset.clearBatches=function(self)
    for key, batch in pairs(self.BatchesList) do
        batch:clear()
    end
end
Asset.flushBatches=function(self)
    for key, batch in pairs(self.BatchesList) do
        batch:flush()
    end
end
local activeCanvas
Asset.drawBatches=function(self)
    if G:useCanvas() then
        activeCanvas=love.graphics.getCanvas() -- shove is lying. it does not preserve canvas so must save and call setCanvas(activeCanvas) later
        love.graphics.setCanvas(G.mainCanvas)
        love.graphics.clear({0,0,0,1})
    end
    if G.runInfo.player then
        G.runInfo.geometry:applyVertexShader(G.runInfo.player)
    end
    for i, batches in pairs(self.Batches) do
        local layer=batches.name
        for key, batch in ipairs(batches.batches) do
            if isHighlightBatch[batch] then
                love.graphics.setBlendMode("add")
            end
            if self.batchExtraActions[batch] and self.batchExtraActions[batch].before then
                self.batchExtraActions[batch].before()
            end
            if batch.draw then -- special batch
                ---@cast batch FunctionBatch|MeshBatch
                batch:draw()
            else
                ---@cast batch love.SpriteBatch
                love.graphics.draw(batch)
            end
            if self.batchExtraActions[batch] and self.batchExtraActions[batch].after then
                self.batchExtraActions[batch].after()
            end
            love.graphics.setBlendMode('alpha') -- default mode
        end
        if layer=='MAIN' then
            if G:useCanvas() then
                love.graphics.setShader()
                if G.runInfo.player then
                    G.runInfo.geometry:applyPixelShader(G.runInfo.player)
                end
                love.graphics.setCanvas(activeCanvas)
                love.graphics.draw(G.mainCanvas)
            end
            love.graphics.setShader()
            shove.endLayer()
            shove.beginLayer('UIBatches')
            love.graphics.origin()
        end
    end
end


local upgradeIconsImage = love.graphics.newImage( "assets/upgrades.png" )
local upgradeSize,upgradeGap=30,32
Asset.upgradeIcons={}
Asset.upgradeIconsImage=upgradeIconsImage
for x=0,7 do
    Asset.upgradeIcons[x]={}
    for y=0,3 do
        Asset.upgradeIcons[x][y]=love.graphics.newQuad(x*upgradeGap,y*upgradeGap,upgradeSize,upgradeSize,upgradeIconsImage:getWidth(),upgradeIconsImage:getHeight())
    end
end
Asset.upgradeSize=30
return Asset