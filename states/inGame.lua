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
            extraUpdates={function(self)
                local shader=G.foregroundShaderData.shader
                self.transparency=math.lerpCondition(self.transparency,shader==G.CONSTANTS.FOREGROUND_SHADERS.TWO_CIRCLES,0,1,0.1)
            end}
        })
        local getForegroundBaseX=function(y)
            local shader=G.foregroundShaderData.shader
            if shader==G.CONSTANTS.FOREGROUND_SHADERS.CIRCLE or shader==G.CONSTANTS.FOREGROUND_SHADERS.TWO_CIRCLES then
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
        local items={'hiScore','score','empty','lives','bombs','power','grazes'}
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
        G.runInfo.player=Player{shotType=ShotTypes[G.runInfo.shotType]}
        -- Bullet{kinematicState={pos={x=250,y=400},speed=0,dir=math.pi/2},lifeFrame=9999,sprite=BulletSprites.round.blue}
        local spawnerPos=G.runInfo.geometry:rThetaGo(G.runInfo.player.kinematicState.pos,100,-math.pi/2)
        local spawner=BulletSpawner{
            kinematicState={pos=spawnerPos,speed=0,dir=0},period=116,firstPeriod=3,lifeFrame=9999,bulletNumber=8,bulletSpeed=50,bulletSize=5,angle=0,range=math.pi*4,bulletSprite=BulletSprites.arrow.blue,bulletLifeFrame=600,bulletEvents={
                function(cir,args,self)
                    if args.index==1 then
                        self.angle=self.angle+math.pi/48
                    end
                    local index=args.index
                    cir.kinematicState.speed=140+math.ceil(index/20)*10
                    Event.Event{
                        obj=cir,action=function()
                            wait(60)
                            local sign=math.mod2Sign(math.ceil(index/4))
                            -- cir.kinematicState.dir=cir.kinematicState.dir+sign*math.pi/3
                            local scale=math.clamp(self.frame/600,0.1,1.2)
                            cir.kinematicState.dir=cir.kinematicState.dir+sign*math.eval(scale,scale-0.1)
                            cir:changeSpriteColor(sign>0 and 'red' or 'green')
                            -- wait(120)
                            -- cir.kinematicState.dir=cir.kinematicState.dir-sign*math.pi/3
                            -- cir:changeSpriteColor('blue')
                            -- for i=1,120 do
                            --     cir.kinematicState.dir=cir.kinematicState.dir-math.pi/720*sign
                            --     wait(1)
                            -- end
                        end
                    }
                end
            }
        }
        Effect.Charge{obj=spawner}
        local boss=Boss{kinematicState={pos=spawnerPos,speed=0,dir=0},maxhp=5000,sprite=Asset.boss.flandre}
        local fairyPos=G.runInfo.geometry:rThetaGo(spawnerPos,150,math.pi/4)
        local fairy=Enemy{kinematicState={pos=fairyPos,speed=0,dir=0},maxhp=1000,sprite=Asset.fairy.red}
    end,
    enter=function(self)
        self:replaceBackgroundPatternIfNot(BackgroundPattern.Empty)
        base.frame=0
    end,
    update=function(self,dt)
        base:updateHierarchy()
        GameObject:updateAll(dt)
        if isPressed('c') then
            local index=1
            local geometries={}
            for key,geometry in pairs(G.geometries) do
                table.insert(geometries,geometry)
            end
            for k,geometry in pairs(geometries) do
                if geometry==G.runInfo.geometry then
                    index=k
                    break
                end
            end
            G.runInfo.geometry=geometries[(index%#geometries)+1]
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