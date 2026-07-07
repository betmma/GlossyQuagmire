
---@type OneStageDataRaw
return{
    init=function()
        if G.runInfo.geometry==G.geometries.Euclidean then
            local border=Border.XYBorder{minx=20,maxx=500,miny=30,maxy=560}
            G.runInfo.player.border=border
            G:replaceBackgroundPatternIfNot(BackgroundPattern.Planes)
        end
        BGM:play('level2',true)
        DynamicUIObjs.showSoundtrack()
    end,
    segments={
        {
            key='3-1',
            type='midStage',
            func=function() -- 
                wait(300000)
            end
        },
    }
}