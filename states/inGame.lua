local G=...
local base=UI.Base()
return {
    base=base,
    init=function(self)
        local rightSide=base:child(UI.Base{x=500,y=20})
        local difficultyText=rightSide:child(UI.Text{
            text='',updateText=function(self)
                self.color=G.CONSTANTS.DIFFICULTIES_DATA[G.runInfo.difficulty].color
                return G.runInfo.difficulty
            end,
            fontSize=36,color=G.CONSTANTS.DIFFICULTIES_DATA[G.runInfo.difficulty].color,boldColor={0,0,0,1},
            x=0,y=0,width=300,align='center',toggleX=false,
        })
        local gameIconText=rightSide:child(UI.Text{
            text=GAME_NAME,
            fontSize=28,color={55/255,65/255,81/255,1},
            x=0,y=520,width=300,
            align='center',toggleX=false,
        })
        local getForegroundBaseX=function(y)
            local shader=G.foregroundShaderData.shader
            if shader==G.CONSTANTS.FOREGROUND_SHADERS.CIRCLE then
                local centerXY, radius=G.foregroundShaderData.args.centerXY,G.foregroundShaderData.args.radius
                local dy=y-centerXY[2]
                if math.abs(dy)>=radius then
                    return 0
                end
                local dx=math.sqrt(radius^2-dy^2)
                return centerXY[1]+dx-500 -- 500 is rightSide.x, 20 is margin
            else
                return 0
            end
        end
        local items={'hiScore','score','empty','lives','bombs','grazes'}
        for i,key in ipairs(items) do
            local y=i*30+30
            if key~='empty' then
                nameText=rightSide:child(UI.Text{
                    text=Localize{'ui','IN_GAME',key},
                    fontSize=24,color={1,1,1,1},autoSize=true,
                    x=20,y=y,width=100,extraUpdates={function(self)
                        local xr,yr=self:getXY()
                        self.x=math.lerp(self.x,getForegroundBaseX(yr+self.height/2)+20,0.1)
                    end}
                })
                rightText=rightSide:child(UI.Text{
                    text='',updateText=function(self)
                        if key=='hiScore' or key=='score' then
                            return string.format('%09d',G.runInfo[key])
                        end
                        return tostring(G.runInfo[key])
                    end,
                    fontSize=24,color={1,1,1,1},autoSize=true,
                    x=120,y=y,width=200,extraUpdates={function(self)
                        local xr,yr=self:getXY()
                        self.x=math.lerp(self.x,getForegroundBaseX(yr+self.height/2)+120,0.1)
                    end}
                })
            end
        end
        -- for test
        G.runInfo.player=Player()
        -- Bullet{kinematicState={x=250,y=400,speed=0,direction=math.pi/2},lifeFrame=9999,sprite=BulletSprites.round.blue}
        local spawner=BulletSpawner{
            kinematicState={x=250,y=200,speed=0,direction=0},period=60,firstPeriod=30,lifeFrame=9999,bulletNumber=80,bulletSpeed=40,angle='player',range=math.pi*8,bulletSprite=BulletSprites.round.blue,bulletLifeFrame=600,bulletEvents={
                function(cir,args)
                    local index=args.index
                    cir.kinematicState.speed=40+math.ceil(index/20)*10
                    Event.Event{
                        obj=cir,action=function()
                            wait(60)
                            cir.kinematicState.direction=cir.kinematicState.direction+math.mod2Sign(index)*math.pi/2
                            cir:changeSpriteColor(index%2==0 and 'red' or 'green')
                        end
                    }
                end
            }
        }
        Effect.Charge{obj=spawner}
    end,
    enter=function(self)
        self:replaceBackgroundPatternIfNot(BackgroundPattern.Empty)
        base.frame=0
    end,
    update=function(self,dt)
        base:updateHierarchy()
        GameObject:updateAll(dt)
        if isPressed('c') then
            if G.runInfo.geometry==G.geometries.Hyperbolic then
                G.runInfo.geometry=G.geometries.Euclidean
            else
                G.runInfo.geometry=G.geometries.Hyperbolic
            end
        end
        if isPressed('r') then
            GameObject:removeAll()
            G:reloadUI()
        end
    end,
    draw=G.CONSTANTS.DRAW,
    drawText=function(self)
        GameObject:drawTextAll()
        if love.keyboard.isDown('f2') then
            return
        end
        if isPressed('escape') then
            SFX:play('select')
            self:switchState(self.STATES.CHOOSE_PLAYER)
        end
        base:drawHierarchy()
    end
}