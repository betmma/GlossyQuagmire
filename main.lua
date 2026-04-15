VERSION="0.0.8.1"
WINDOW_WIDTH,WINDOW_HEIGHT=love.graphics.getDimensions()
CANVAS_WIDTH, CANVAS_HEIGHT = 3000, 1500
GAME_NAME="Glossy Quagmire"
IS_WEB=type(jit)~="table"
DEV_MODE=true
if arg[2] == "debug" then
    require("lldebugger").start()
end
io.stdout:setvbuf("no")
love.window.setTitle(GAME_NAME..' '..VERSION)
require'misc'
shove = require "import.shove"
Input = require "input"
function love.load()
    shove.setResolution(800, 600, {fitMethod = "aspect", renderMode = "layer"})
    Object = require "classic"
    GameObject=Object.GameObject
    UI = require "ui.uiBase"
    -- ExpandingMesh = require "import.expandingMesh"
    ---@type ShaderScan
    ShaderScan = (require 'import.shaderScan')()
    EventManager = require "eventManager"
    EM = EventManager
    MeshFuncs = require "meshFuncs"
    Shape = require "shape"
    Player = require "player"
    Action = require "action"
    Bullet = require "bullet"
    -- Laser=require"laser"
    -- PolyLine = require "polyline"
    Event= require "event"
    BulletSpawner=require"bulletSpawner"
    Enemy=require"enemy"
    Boss=Enemy.Boss
    Asset=require"loadAsset"
    ---@type AssetBulletSpritesCollection
    BulletSprites,BulletBatch,SpriteData=Asset.bulletSprites,Asset.bulletBatch,Asset.SpriteData
    ShotTypes= require "shotTypes.shotTypeBase"
    Audio=require"audio"
    SFX=Audio.sfx;BGM=Audio.bgm
    Effect=require"effect"
    -- LevelData = require "levelData"
    -- DialogueController=require"localization.dialogue"
    -- Upgrades = require "upgrades"
    G=require"state"
    StageManager=require"stages.stageManager"
    ---@type NoticeManager
    NoticeManager=require"notice"
    -- ScreenshotManager=require"screenshotManager"
    -- ReplayManager=require"replayManager"
    -- Nickname=require"nickname"

    BGM:play('title')

    shove.setWindowMode(G.save.options.resolution.width,G.save.options.resolution.height, {resizable = true})
    shove.createLayer("main",{stencil=true})
    shove.createLayer("UIBatches")
    -- shove.addEffect('main',Player.invertShader)
end
function love.keypressed(key, scancode, isrepeat)
    Input.keypressed(key, scancode, isrepeat)
end
-- return true if current frame is the first frame that key be pressed down
isPressed=Input.isKeyJustPressed

local profiExists=pcall(require,"profi") -- lib that log functions call and time spent to optimize code
local profi
if profiExists then
    profi=require"profi"
end
local profiActivate=false

local controlFPSmode=0
local sleepTime=1/60
local frameTime=1/60
AccumulatedTime=0
function love.update(dt)
    if profi then
        profiActivate=isPressed('f3')
        if profiActivate then
            profi:start('once')
        end
    end
    if controlFPSmode==0 then
        AccumulatedTime=AccumulatedTime+dt
        AccumulatedTime=math.min(AccumulatedTime,frameTime*5)
        if AccumulatedTime>=frameTime then
            AccumulatedTime=AccumulatedTime-frameTime
            dt=1/60
            Input.update()
            G:update(dt)
        end
    elseif controlFPSmode==1 then
        love.timer.sleep(sleepTime-dt)
        local fps=love.timer.getFPS()
        local newTime=sleepTime*fps/60
        sleepTime=0.995*(sleepTime-newTime)+newTime
        dt=1/60
        Input.update()
        G:update(dt)
    end
    if profi and love.keyboard.isDown('f4') then
        profi:stop()
        profi:writeReport( 'MyProfilingReport.txt' )
    end
end
function love.draw()
  shove.beginDraw()
    G:draw()
    shove.beginLayer('nickname')
    -- Nickname:drawText() -- nickname is an individual system 
    shove.endLayer()
  shove.endDraw()
end