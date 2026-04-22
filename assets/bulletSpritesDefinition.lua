local Asset=...
-- below is for IDE hinting
---@class spectrum
---@field white Sprite
---@field gray Sprite
---@field red Sprite
---@field orange Sprite
---@field yellow Sprite
---@field green Sprite
---@field teal Sprite
---@field cyan Sprite
---@field blue Sprite
---@field purple Sprite
---@field magenta Sprite
---@field black Sprite

---@class spectrum2
---@field gray Sprite
---@field red Sprite
---@field yellow Sprite
---@field green Sprite
---@field blue Sprite
---@field magenta Sprite

---@alias AssetBulletSpritesCollection { \
---laser: spectrum, round: spectrum, rim: spectrum, rice: spectrum, bill: spectrum, kunai: spectrum, scale: spectrum, bullet: spectrum, bulletFog: spectrum, crystal: spectrum, star: spectrum, rain: spectrum, diamond: spectrum, coin: spectrum, cross: spectrum, crossDark: spectrum, crossRim: spectrum, crossDarkRim: spectrum, \
---laserDark: spectrum, roundDark: spectrum, rimDark: spectrum, blackrice: spectrum, billDark: spectrum, kunaiDark: spectrum, scaleDark: spectrum, bulletDark: spectrum, bulletFogDark: spectrum, crystalDark: spectrum, starDark: spectrum, rainDark: spectrum, \
---ellipse: spectrum, knife: spectrum, arrow: spectrum, \
---dot: spectrum, darkdot: spectrum, \
---bigRound: spectrum, bigStar: spectrum, heart: spectrum, flower: spectrum, magatama: spectrum, haniwa: spectrum, orb: spectrum, \
---giant: spectrum, lightRound: spectrum, largeOrb: spectrum, largeMagatama: spectrum, \
---lotus: spectrum2, darkLotus: spectrum2, explosion: spectrum2, shockwave: spectrum2, \
---butterfly: spectrum, flame: spectrum, human: spectrum, dog: spectrum, dogMirrored: spectrum, bird: spectrum, frog: spectrum, note: spectrum, \
---snake: spectrum, \
---rest: spectrum, \
---stick: spectrum, stickBlack: spectrum, stone: spectrum, egg: spectrum, fog: spectrum, \
---moon: Sprite, anchor: Sprite, playerFocus: Sprite, \
---nuke: Sprite}

---@type bulletSpriteLoaders
local loaders=Asset.bulletSpriteLoaders
local switchTargets,single,gifSingle,movingSingle,spectrum,matrix,simpleOffsetFunc,setCenterPosition=loaders.switchTargets,loaders.single,loaders.gifSingle,loaders.movingSingle,loaders.spectrum,loaders.matrix,loaders.simpleOffsetFunc,loaders.setCenterPosition

---@type AssetBulletSpritesCollection
Asset.bulletSprites={}
switchTargets(Asset.bulletImage, Asset.bulletSprites)

local names16x16={'laser','round','rim','rice','bill','kunai','scale','bullet','bulletFog','crystal','star','rain','coin','cross','crossDark','crossRim','crossDarkRim'}
local colors={'white','gray','red','orange','yellow','green','teal','cyan','blue','purple','magenta','black'}
Asset.colors=colors
matrix{
    unit=single{sizeX=16,sizeY=16},
    names=names16x16,colors=colors,
    nameOffsetFunc=simpleOffsetFunc(0,16),
    colorOffsetFunc=simpleOffsetFunc(16,0),
    baseX=0,baseY=0,
}:addToAsset()
local names16x16_2={'laserDark','roundDark','rimDark','blackrice','billDark','kunaiDark','scaleDark','bulletDark','bulletFogDark','crystalDark','starDark','rainDark'}
matrix{
    unit=single{sizeX=16,sizeY=16},
    names=names16x16_2,colors=colors,
    nameOffsetFunc=simpleOffsetFunc(0,16),
    colorOffsetFunc=simpleOffsetFunc(16,0),
    baseX=16*12,baseY=0,
}:addToAsset()
local names16x32={'ellipse','knife','arrow'}
matrix{
    unit=single{sizeX=16,sizeY=32},
    names=names16x32,colors=colors,
    nameOffsetFunc=simpleOffsetFunc(0,32),
    colorOffsetFunc=simpleOffsetFunc(16,0),
    baseX=0,baseY=16*17,
}:addToAsset()
setCenterPosition('arrow',8,6)
local names8x8={'dot','darkdot'}
matrix{
    unit=single{sizeX=8,sizeY=8},
    names=names8x8,colors=colors,
    nameOffsetFunc=simpleOffsetFunc(0,8),
    colorOffsetFunc=simpleOffsetFunc(8,0),
    baseX=0,baseY=16*17+3*32,
}:addToAsset()
local names32x32={'bigRound','bigStar','heart','flower','magatama','haniwa','orb'}
matrix{
    unit=single{sizeX=32,sizeY=32},
    names=names32x32,colors=colors,
    nameOffsetFunc=simpleOffsetFunc(0,32),
    colorOffsetFunc=simpleOffsetFunc(32,0),
    baseX=16*24,baseY=0,
}:addToAsset()
local names64x64={'giant','lightRound','largeOrb','largeMagatama'}
matrix{
    unit=single{sizeX=64,sizeY=64},
    names=names64x64,colors=colors,
    nameOffsetFunc=simpleOffsetFunc(64,0),
    colorOffsetFunc=simpleOffsetFunc(0,64),
    baseX=16*24+32*12,baseY=0,
}:addToAsset()
local names128x128={'lotus','darkLotus','explosion','shockwave'}
local colors128x128={'gray','red','yellow','green','blue','magenta'}
matrix{
    unit=single{sizeX=128,sizeY=128},
    names=names128x128,colors=colors128x128,
    nameOffsetFunc=simpleOffsetFunc(128,0),
    colorOffsetFunc=simpleOffsetFunc(0,128),
    baseX=1024,baseY=0,
}:addToAsset()
local namesGIF32x32={'butterfly','flame','human','dog','dogMirrored','bird','frog','note'}
matrix{
    unit=gifSingle{sizeX=32,sizeY=32,frameCount=3,frameTime=10,frameOffsetFunc=simpleOffsetFunc(0,32)},
    names=namesGIF32x32,colors=colors,
    nameOffsetFunc=simpleOffsetFunc(0,32*3),
    colorOffsetFunc=simpleOffsetFunc(32,0),
    baseX=16*24,baseY=32*7,
}:addToAsset()
setCenterPosition('flame',16,12)
setCenterPosition('note',16,25)
spectrum{
    unit=gifSingle{sizeX=16,sizeY=112,frameCount=3,frameTime=10,frameOffsetFunc=simpleOffsetFunc(0,112),name='snake'},
    colors=colors,
    offsetFunc=simpleOffsetFunc(16,0),
    baseX=16*12,baseY=16*19
}:addToAsset()
spectrum{
    unit=single{sizeX=32,sizeY=32,name='rest'},
    colors=colors,
    offsetFunc=simpleOffsetFunc(32,0),
    baseX=16*24,baseY=32*31,
}:addToAsset()
matrix{
    unit=single{sizeX=32,sizeY=32},
    names={'stick','stickBlack','stone','egg','fog'},colors=colors,
    nameOffsetFunc=simpleOffsetFunc(0,32),
    colorOffsetFunc=simpleOffsetFunc(32,0),
    baseX=0,baseY=32*27,
}:addToAsset()
single{
    sizeX=128,sizeY=128,name='moon',
    baseX=16*24+32*12,baseY=64*12,
}:addToAsset()
single{
    sizeX=128,sizeY=128,name='anchor',
    baseX=16*24+32*12+128,baseY=64*12,
}:addToAsset()
single{
    sizeX=256,sizeY=256,name='nuke',
    baseX=1280,baseY=768,
}:addToAsset()
single{
    sizeX=64,sizeY=64,name='playerFocus',
    baseX=0,baseY=496,
}:addToAsset()
-- some old names mapping
Asset.shards={dot=Asset.bulletSprites.dot.white,round=Asset.bulletSprites.fog.white}

----------------------------------------- Player Shot sprites (player.png)

---@class BlPuRe
---@field blue Sprite
---@field purple Sprite
---@field red Sprite

---@class GrCyPu
---@field green Sprite
---@field cyan Sprite
---@field purple Sprite

---@class BlGr
---@field blue Sprite
---@field green Sprite

---@class ReOrPu
---@field red Sprite
---@field orange Sprite
---@field purple Sprite

---@alias AssetPlayerShotSpritesCollection { \
---amuletMid:BlPuRe, amuletWide:BlPuRe, amuletNarrow:BlPuRe, poker:BlPuRe, \
---amuletFade:BlPuRe, pokerFade:BlPuRe, \
---yinyangOrb:BlPuRe, ball:BlPuRe, burst:ReOrPu, hakkero:GrCyPu, laser:Sprite, explosive:BlGr, amuletHuge:Sprite}

---@type AssetPlayerShotSpritesCollection
Asset.playerShotSprites={}

switchTargets(Asset.playerImage, Asset.playerShotSprites)

local baseY=16*9

local BlPuReColors={'blue','purple','red'}
spectrum{
    unit=single{sizeX=16,sizeY=48,name='amuletMid'},
    colors=BlPuReColors,
    offsetFunc=simpleOffsetFunc(16,0),
    baseX=0,baseY=baseY,
}:addToAsset()
setCenterPosition('amuletMid',8,8)
matrix{
    unit=single{sizeX=16,sizeY=48},
    names={'poker','amuletNarrow'},
    colors=BlPuReColors,
    nameOffsetFunc=simpleOffsetFunc(48,0),
    colorOffsetFunc=simpleOffsetFunc(16,0),
    baseX=0,baseY=baseY+64,
}:addToAsset()
setCenterPosition('poker',8,8)
setCenterPosition('amuletNarrow',8,8)
matrix{
    unit=single{sizeX=16,sizeY=16},
    names={'yinyangOrb','ball'},
    colors=BlPuReColors,
    nameOffsetFunc=simpleOffsetFunc(48,0),
    colorOffsetFunc=simpleOffsetFunc(16,0),
    baseX=0,baseY=baseY+64+48,
}:addToAsset()
matrix{
    unit=gifSingle{sizeX=16,sizeY=16,frameCount=4,frameTime=10,frameOffsetFunc=simpleOffsetFunc(0,16)},
    names={'amuletFade','pokerFade'},
    colors=BlPuReColors,
    nameOffsetFunc=simpleOffsetFunc(48,0),
    colorOffsetFunc=simpleOffsetFunc(16,0),
    baseX=0+16*3,baseY=baseY,
}:addToAsset()
spectrum{
    unit=single{sizeX=16,sizeY=48,name='burst'},
    colors={'red','orange','purple'},
    offsetFunc=simpleOffsetFunc(16,0),
    baseX=0+16*9,baseY=baseY,
}:addToAsset()
setCenterPosition('burst',8,16)
spectrum{
    unit=single{sizeX=16,sizeY=48,name='amuletWide'},
    colors=BlPuReColors,
    offsetFunc=simpleOffsetFunc(16,0),
    baseX=0+16*12,baseY=baseY,
}:addToAsset()
setCenterPosition('amuletWide',8,8)
spectrum{
    unit=single{sizeX=16,sizeY=16,name='hakkero'},
    colors={'green','cyan','purple'},
    offsetFunc=simpleOffsetFunc(16,0),
    baseX=0+16*15,baseY=baseY,
}:addToAsset()
single{
    sizeX=16,sizeY=32,name='laser',
    baseX=0+16*18,baseY=baseY+16,
}:addToAsset()
gifSingle{
    sizeX=64,sizeY=64,frameCount=4,frameTime=10,frameOffsetFunc=simpleOffsetFunc(64,0),name='amuletHuge',baseX=16*6,baseY=baseY+64,
}:addToAsset()
Asset.playerShotSprites.amuletHuge.data.isSquare=true
spectrum{
    unit=gifSingle{sizeX=16,sizeY=32,frameCount=4,frameTime=10,frameOffsetFunc=simpleOffsetFunc(0,-32),name='explosive'},
    colors={'blue','green'},
    offsetFunc=simpleOffsetFunc(16,0),
    baseX=0+16*22,baseY=baseY+64+48,
}:addToAsset()

----------------------------------------- Player sprites (also player.png)

Asset.playerSprites={}
switchTargets(Asset.playerImage, Asset.playerSprites)

---@class playerSpectrum
---@field REIMU MovingSprite
---@field MARISA MovingSprite
---@field KOTOBA MovingSprite

local sizeX,sizeY=32,48
spectrum{
    unit=movingSingle{sizeX=sizeX,sizeY=sizeY,name='player',data={
        normal={frameCount=8,offsetX=0,offsetY=0,frameOffsetFunc=simpleOffsetFunc(sizeX,0)},
        moveTransition={
            left={frameCount=4,offsetX=0,offsetY=sizeY,frameOffsetFunc=simpleOffsetFunc(sizeX,0)},
            right={frameCount=4,offsetX=0,offsetY=sizeY*2,frameOffsetFunc=simpleOffsetFunc(sizeX,0)},
        },
        moving={
            left={frameCount=4,offsetX=sizeX*4,offsetY=sizeY,frameOffsetFunc=simpleOffsetFunc(sizeX,0)},
            right={frameCount=4,offsetX=sizeX*4,offsetY=sizeY*2,frameOffsetFunc=simpleOffsetFunc(sizeX,0)},
        },
        frameTime={normal=8,moveTransition=2,moving=8},
    }},
    colors={'REIMU','MARISA','KOTOBA'},
    offsetFunc=simpleOffsetFunc(sizeX*8,0),
    baseX=0,baseY=0,
}:addToAsset()
-- current structure is Asset.playerSprites.player.REIMU. simplify it to Asset.playerSprites.REIMU for easier access
Asset.playerSprites=Asset.playerSprites.player

----------------------------------------- Fairy sprites

---@class fairySpectrum
---@field red MovingSprite
---@field blue MovingSprite
---@field green MovingSprite
---@field orange MovingSprite
---@field purple MovingSprite
---@field white MovingSprite
---@field black MovingSprite

---@alias AssetFairySpritesCollection {\
--- small:fairySpectrum, medium:fairySpectrum, large:fairySpectrum}

---@type AssetFairySpritesCollection
Asset.fairySprites={}

switchTargets(Asset.fairyImage, Asset.fairySprites)

local fairyColors={'red','blue','green','orange','purple','white','black'}

local size=32

local function getSmallFairySingleSpriteDataArg()
    return {
        normal={frameCount=4,offsetX=0,offsetY=0,frameOffsetFunc=simpleOffsetFunc(size,0)},
        moveTransition={
            left={frameCount=1,offsetX=size*4,offsetY=0,frameOffsetFunc=simpleOffsetFunc(0,0)},
            right={frameCount=1,offsetX=size*13,offsetY=0,frameOffsetFunc=simpleOffsetFunc(0,0)},
        },
        moving={
            left={frameCount=4,offsetX=size*5,offsetY=0,frameOffsetFunc=simpleOffsetFunc(size,0)},
            right={frameCount=4,offsetX=size*12,offsetY=0,frameOffsetFunc=simpleOffsetFunc(-size,0)},
        },
        frameTime={normal=8,moveTransition=8,moving=8},
    }
end

spectrum{
    unit=movingSingle{
        sizeX=size,sizeY=size,name='small',
        data=getSmallFairySingleSpriteDataArg(),
    },
    colors=fairyColors,
    offsetFunc=simpleOffsetFunc(0,size),
    baseX=0,baseY=0,
}:addToAsset()

local function getMediumLargeFairySingleSpriteDataArg()
    return {
        normal={frameCount=4,offsetX=0,offsetY=0,frameOffsetFunc=simpleOffsetFunc(size,0)},
        moveTransition={
            left={frameCount=1,offsetX=size*4,offsetY=0,frameOffsetFunc=simpleOffsetFunc(0,0)},
            right={frameCount=1,offsetX=size*11,offsetY=0,frameOffsetFunc=simpleOffsetFunc(0,0)},
        },
        moving={
            left={frameCount=3,offsetX=size*5,offsetY=0,frameOffsetFunc=simpleOffsetFunc(size,0)},
            right={frameCount=3,offsetX=size*10,offsetY=0,frameOffsetFunc=simpleOffsetFunc(-size,0)},
        },
        frameTime={normal=8,moveTransition=8,moving=8},
    }
end

size=48
matrix{
    unit=movingSingle{
        sizeX=size,sizeY=size,
        data=getMediumLargeFairySingleSpriteDataArg(),
    },
    names={'large','medium'},
    colors=fairyColors,
    nameOffsetFunc=simpleOffsetFunc(0,size*#fairyColors),
    colorOffsetFunc=simpleOffsetFunc(0,size),
    baseX=0,baseY=32*7,
}:addToAsset()


----------------------------------------- Items (item.png)

Asset.itemSprites={}
switchTargets(Asset.itemImage, Asset.itemSprites)

---@class ItemAndIndicator like P box and triangle indicator of P box
---@field item Sprite
---@field indicator Sprite

---@class LifeOrBombMeter 0 is empty, 5 is full, 1-4 are 1-4 pieces filled
---@field [0] Sprite
---@field [1] Sprite
---@field [2] Sprite
---@field [3] Sprite
---@field [4] Sprite
---@field [5] Sprite

---@alias AssetItemSpritesCollection {\
--- powerSmall:ItemAndIndicator, powerLarge:ItemAndIndicator, powerFull:ItemAndIndicator, point:ItemAndIndicator, pointGolden:ItemAndIndicator, lifePiece:ItemAndIndicator, bombPiece:ItemAndIndicator, life:ItemAndIndicator, bomb:ItemAndIndicator,\
--- lifeMeter:LifeOrBombMeter, bombMeter:LifeOrBombMeter, enemySpellcardIndicator:Sprite, hpBar:Sprite}

matrix{
    unit=single{sizeX=16,sizeY=16},
    names={'powerSmall','powerLarge','powerFull','point','pointGolden'},
    colors={'item','indicator'},
    nameOffsetFunc=simpleOffsetFunc(16,0),
    colorOffsetFunc=simpleOffsetFunc(0,16),
    baseX=0,baseY=64,
}:addToAsset()
matrix{
    unit=single{sizeX=32,sizeY=32},
    names={'lifePiece','bombPiece','life','bomb'},
    colors={'item','indicator'},
    nameOffsetFunc=simpleOffsetFunc(32,0),
    colorOffsetFunc=simpleOffsetFunc(0,32),
    baseX=48,baseY=0,
}:addToAsset()
single{
    sizeX=16,sizeY=16,name='enemySpellcardIndicator',
    baseX=32,baseY=32,
}:addToAsset()
single{
    sizeX=16,sizeY=16,name='hpBar',
    baseX=0,baseY=0,
}:addToAsset()
matrix{
    unit=single{sizeX=32,sizeY=32},
    names={'lifeMeter','bombMeter'},
    colors={0,1,2,3,4,5},
    nameOffsetFunc=simpleOffsetFunc(0,32),
    colorOffsetFunc=simpleOffsetFunc(32,0),
    baseX=0,baseY=96,
}:addToAsset()