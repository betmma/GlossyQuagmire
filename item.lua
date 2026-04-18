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
---@alias never "That's a wrong key" workaround from https://github.com/LuaLS/lua-language-server/issues/1990. LuaLS is shit

---@class DropItems for enemy, how many items to drop when killed. e.g. {powerSmall=3} dunno why table<ItemType,integer> cannot ensure key is ItemType.
---@field powerSmall integer|nil
---@field powerLarge integer|nil
---@field powerFull integer|nil
---@field point integer|nil
---@field pointGolden integer|nil
---@field lifePiece integer|nil
---@field bombPiece integer|nil
---@field life integer|nil
---@field bomb integer|nil
---@field [any] never


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
    if player then
        local distance=G.runInfo.geometry:distance(self.kinematicState.pos,player.kinematicState.pos)
        local hitboxRadius=self:getHitboxRadius()+player:getHitboxRadius()
        if distance<hitboxRadius*8 then
            self.kinematicState.dir=G.runInfo.geometry:to(self.kinematicState.pos,player.kinematicState.pos)
            self.kinematicState.speed=math.lerp(self.kinematicState.speed,200,0.1)
        else
            self.kinematicState.speed=math.lerp(self.kinematicState.speed,0,0.1)
        end
        if distance<hitboxRadius*4 then
            self:picked()
            self:remove()
        end
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
        isSquare=true
    }
end

-- to deal with potential floating point error when adding 0.2 for life and bomb pieces
---@param value number
---@return number newValue
---@return boolean reachesNewInteger
local function addOneFifth(value)
    value=value+0.2
    value=value*5
    value=math.floor(value+0.5)
    value=value/5
    return value,value%1==0
end

function Item:picked()
    if self.type==ItemType.powerSmall then
        if G.runInfo.power>=400 then
            SFX:play('select',true)
            return
        end
        G.runInfo.power=G.runInfo.power+1
        if G.runInfo.power%100==0 then
            SFX:play('extend',true)
        else
            SFX:play('select',true)
        end
    elseif self.type==ItemType.powerLarge then
        if G.runInfo.power>=400 then
            SFX:play('select',true)
            return
        end
        G.runInfo.power=G.runInfo.power+100
        SFX:play('extend',true)
    elseif self.type==ItemType.powerFull then
        G.runInfo.power=400
        SFX:play('extend',true)
    elseif self.type==ItemType.point then
        SFX:play('select',true)
        -- score not implemented yet
    elseif self.type==ItemType.pointGolden then
        SFX:play('extend',true)
        -- score not implemented yet
    elseif self.type==ItemType.lifePiece then
        local newValue, reachedInteger = addOneFifth(G.runInfo.lives)
        G.runInfo.lives = newValue
        if reachedInteger then
            SFX:play('extend',true)
        else
            SFX:play('select',true)
        end
    elseif self.type==ItemType.bombPiece then
        local newValue, reachedInteger = addOneFifth(G.runInfo.bombs)
        G.runInfo.bombs = newValue
        if reachedInteger then
            SFX:play('extend',true)
        else
            SFX:play('select',true)
        end
    elseif self.type==ItemType.life then
        G.runInfo.lives=G.runInfo.lives+1
        SFX:play('extend',true)
    elseif self.type==ItemType.bomb then
        G.runInfo.bombs=G.runInfo.bombs+1
        SFX:play('extend',true)
    end
end

return Item