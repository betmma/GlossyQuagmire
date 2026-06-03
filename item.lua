---@enum ItemType
ItemType={
    powerSmall='powerSmall',
    powerLarge='powerLarge',
    powerFull='powerFull',
    point='point',
    pointGolden='pointGolden',
    lifePiece='lifePiece',
    bombPiece='bombPiece',
    life='life',
    bomb='bomb',
}
---@class DropItems:strict for enemy, how many items to drop when killed. e.g. {powerSmall=3} dunno why table<ItemType,integer> cannot ensure key is ItemType.
---@field powerSmall integer|nil
---@field powerLarge integer|nil
---@field powerFull integer|nil
---@field point integer|nil
---@field pointGolden integer|nil
---@field lifePiece integer|nil
---@field bombPiece integer|nil
---@field life integer|nil
---@field bomb integer|nil

---@class ItemArgs
---@field kinematicState KinematicState
---@field type ItemType

---@class Item:Shape
---@field type ItemType
---@field sprite Sprite
---@field indicatorSprite Sprite
---@overload fun(args:ItemArgs):Item
local Item=Shape:extend()
Item.ItemType=ItemType

---@param args ItemArgs
function Item:new(args)
    Item.super.new(self, args)
    self.type=args.type
    self.sprite=Asset.itemSprites[self.type].item
    self.indicatorSprite=Asset.itemSprites[self.type].indicator -- indicator not implemented yet
    self.batch=Asset.itemBatch
    self.meshBatch=nil -- can add a itemMeshBatch into Asset if needed later
end

function Item:update(dt)
    local player=G.runInfo.player
    local newGrazes=0
    if self.grazeRef then
        newGrazes=G.runInfo.grazes-self.grazeRef
    end
    self.grazeRef=G.runInfo.grazes
    self.lifeFrame=self.lifeFrame+newGrazes
    if player then
        local distance=G.runInfo.geometry:distance(self.kinematicState.pos,player.kinematicState.pos)
        local hitboxRadius=self:getHitboxRadius()+player:getHitboxRadius()
        local speedAim=newGrazes*500
        if distance<hitboxRadius*8 then
            speedAim=speedAim+200
        end
        if self.frame<20 then
            speedAim=0
        end
        if speedAim>0 then
            self.kinematicState.dir=G.runInfo.geometry:to(self.kinematicState.pos,player.kinematicState.pos)
        end
        self.kinematicState.speed=math.lerp(self.kinematicState.speed,speedAim,0.1)
        if distance<hitboxRadius*4 then
            self:picked()
            EventManager.post(EventManager.EVENTS.PICK_ITEM, self.type)
            self:remove()
        end
    end
    if self.frame+120>self.lifeFrame then
        self.spriteTransparency=math.max(0,(self.lifeFrame-self.frame)/120)
    end
    Item.super.update(self, dt)
end

function Item:draw()
    self:drawQuad{
        quad=self.sprite.quad,
        rotation=self.kinematicState.dir-math.pi/2,
        zoom=1,
        normalBatch=self.batch,
        meshBatch=self.meshBatch,
        isSquare=true,
        color={1,1,1,self.spriteTransparency or 1}
    }
end

-- to deal with potential floating point error when adding 0.2 for life and bomb pieces
---@param value number
---@return number newValue
local function roundToFifth(value)
    value=value*5
    value=math.floor(value+0.5)
    value=value/5
    return value
end

local function gainPower(amount)
    if G.runInfo.power>=400 then
        SFX:play('select')
        return
    end
    local powerBefore=G.runInfo.power
    G.runInfo.power=G.runInfo.power+amount
    if G.runInfo.power>400 then
        G.runInfo.power=400
    end
    if G.runInfo.power==400 and powerBefore<400 then
        DynamicUIObjs.showNotice('fullPowerUp')
    end
    if math.floor(powerBefore/100)<math.floor(G.runInfo.power/100) then
        SFX:play('extend')
    else
        SFX:play('select')
    end
end

local function gainLife(amount)
    local livesBefore=G.runInfo.lives
    G.runInfo.lives=roundToFifth(G.runInfo.lives+amount)
    if math.floor(livesBefore)<math.floor(G.runInfo.lives) then
        SFX:play('extend')
        DynamicUIObjs.showNotice('extend')
    else
        SFX:play('select')
    end
end

local function gainBomb(amount)
    local bombsBefore=G.runInfo.bombs
    G.runInfo.bombs=roundToFifth(G.runInfo.bombs+amount)
    if math.floor(bombsBefore)<math.floor(G.runInfo.bombs) then
        SFX:play('extend')
    else
        SFX:play('select')
    end
end

local function gainScore(amount)
    local newScore=G.runInfo.score+amount
    if G.runInfo.score<G.runInfo.hiScore and G.runInfo.hiScore<newScore then -- new hiscore
        DynamicUIObjs.showNotice('hiscore')
        SFX:play('extend')
    end
    SFX:play('select')
    G.runInfo.score=newScore
    G.runInfo.hiScore=math.max(G.runInfo.hiScore,G.runInfo.score)
    local highScoreTable,key=G:getHighScoreTableAndKey()
    highScoreTable[key]=math.max(highScoreTable[key], G.runInfo.score)
end

EventManager.listenTo(EventManager.EVENTS.GAIN_SCORE, gainScore)

function Item:picked()
    if self.type==ItemType.powerSmall then
        gainPower(1)
    elseif self.type==ItemType.powerLarge then
        gainPower(100)
    elseif self.type==ItemType.powerFull then
        gainPower(400)
    elseif self.type==ItemType.point then
        local scoreGain=1000*(1-self.frame/self.lifeFrame)
        EventManager.post(EventManager.EVENTS.GAIN_SCORE,scoreGain)
    elseif self.type==ItemType.pointGolden then
        EventManager.post(EventManager.EVENTS.GAIN_SCORE,1000)
    elseif self.type==ItemType.lifePiece then
        gainLife(0.2)
    elseif self.type==ItemType.bombPiece then
        gainBomb(0.2)
    elseif self.type==ItemType.life then
        gainLife(1)
    elseif self.type==ItemType.bomb then
        gainBomb(1)
    end
end

return Item