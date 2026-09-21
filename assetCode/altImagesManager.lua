---@alias variation string

local DEFAULT_PATH='assets'
local OFFICIAL_ALTS_PATH='alts'
local PLAYER_CUSTOM_PATH='custom'
local FOLDERS={OFFICIAL_ALTS_PATH,PLAYER_CUSTOM_PATH}

local VALID_EXTENSIONS={png=true,jpg=true,jpeg=true}

local ORIGINAL='original'

-- mount external folder
local baseDir=love.filesystem.isFused() and love.filesystem.getSourceBaseDirectory() or "."
love.filesystem.mount(baseDir,'')

--- manages alternative images. for example, main menu and every stage can have their own logo and background image (official alternatives). player can also add custom alternatives outside of packed .exe file. also to keep original asset files path the same, there are 3 possible paths: assets/NAME.png, alts/NAME/VARIATION.png, ..(outside of exe when packed)/custom/NAME/VARIATION.png. the assets/ one is considered the default image. player's custom one should shadow official one with same variation name. it loads all possible files so there could be options in game to choose from alternatives. for background and logos, would need a map table elsewhere, so user can add like "FUNKY" alternative and map stage 1 to FUNKY instead of alts/bg/stage1.png
---@class AltImagesManager:Object
---@field fileName string with file extension
---@field name string without file extension
---@field imageCache table<variation,love.Image>
---@field availableVariations table<variation,string> filled when loadAllImages is called. value is full path
---@field loadImage fun(self:AltImagesManager,variation:variation):nil look at availableVariations to get path, call love.graphics.newImage and put into cache
---@field loadAllImages fun(self:AltImagesManager):nil read assets/fileName and two folders/name/*. fill availableVariations but does not load any variation except for original (including overrides original) as lazy loading
---@field getVariation fun(self:AltImagesManager,variation?:variation):love.Image get a certain variation. defaults to original
---@field current love.Image it's very common for the code using image to not consider which variation, instead only use the variation set by options or elsewhere. with this attribute most consumer code can simply use AltImagesManager.current
---@field set fun(self:AltImagesManager,variation?:variation) set self.current to a certain variation and call setTexture for spriteBatches in self.spriteBatchesToUpdate. IMPORTANT: spriteBatches must be manually added to self.spriteBatchesToUpdate beforehand so it can be updated.
---@field private spriteBatchesToUpdate love.SpriteBatch[]
---@field addSpriteBatch fun(self:AltImagesManager,spriteBatch:love.SpriteBatch):nil simply call table.insert
---@overload fun(args:AltImagesManagerArgs):AltImagesManager
local AltImagesManager=Object:extend()

---@class AltImagesManagerArgs:strict
---@field fileName string should include file extension as finding it in assets/ needs full name

---@param args AltImagesManagerArgs
function AltImagesManager:new(args)
    self.spriteBatchesToUpdate={}
    local fileName=args.fileName
    self.fileName=fileName
    self.name=fileName:match("(.+)%.%w+$")
    self:loadAllImages()
    self.current=self.imageCache[ORIGINAL]
end

function AltImagesManager:loadImage(variation)
    local path=self.availableVariations[variation]
    if not path then
        error('AltImagesManager:loadImage tries to load variation '..variation..' not in availableVariations')
    end
    local image=love.graphics.newImage(path)
    self.imageCache[variation]=image
end

function AltImagesManager:loadAllImages()
    self.imageCache={}
    self.availableVariations={[ORIGINAL]=DEFAULT_PATH..'/'..self.fileName}
    -- load assets/
    for i,folder in ipairs(FOLDERS) do
        local targetFolder=folder..'/'..self.name
        local files=love.filesystem.getDirectoryItems(targetFolder)
        for j,fileName in ipairs(files) do
            local varName,ext=fileName:match("^(.-)%.([^%.]+)$")
            local fullPath=targetFolder..'/'..fileName
            local info = love.filesystem.getInfo(fullPath)

            if info and info.type == "file" and VALID_EXTENSIONS[ext] then
                self.availableVariations[varName]=fullPath
            end
        end
    end
    self:loadImage(ORIGINAL)
end

function AltImagesManager:getVariation(variation)
    variation=variation or ORIGINAL
    if not self.availableVariations[variation] then
        variation=ORIGINAL
    end
    if self.imageCache[variation] then
        return self.imageCache[variation]
    end
    self:loadImage(variation)
    return self.imageCache[variation]
end

function AltImagesManager:set(variation)
    self.current=self:getVariation(variation)
    for i,spriteBatch in ipairs(self.spriteBatchesToUpdate) do
        spriteBatch:setTexture(self.current)
    end
end

function AltImagesManager:addSpriteBatch(spriteBatch)
    table.insert(self.spriteBatchesToUpdate,spriteBatch)
end

return AltImagesManager