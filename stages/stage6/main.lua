---@type OneStageDataRaw
return{
    init=function(stageKey)
        G:replaceBackgroundPatternIfNot(BackgroundPattern.SphericalGrid)
        StageManager.commonStageInit(stageKey)
    end,
    segments={
        {
            key='6-1',
            type='midStage',
            func=function()
                wait(999)
            end
        }
    }
}