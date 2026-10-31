-- the module to store life and bomb change info and draw diagram after a run.

-- record layer

-- currently recorded info: for each stage, when (player frame index, same as replay) did life or bomb change and what's the new value. when did each segment start.
-- the starting lives and bombs cannot be tracked with SET_LIFE event because the code in state.lua doesn't call event and player object hasn't been created. so has to read first segment's recorded life and bomb. also current logic ensures there must be a segment at first frame of a stage.
---@alias frame integer
---@class valueChangeEvent
---@field [1] frame
---@field [2] number
---@class enterSegmentEvent
---@field frame frame
---@field segmentKey SegmentKey
---@field life number to easier calculate each segment resource delta
---@field bomb number

---@class StatisticsOneStageData
---@field stageKey StageKey
---@field duration frame
---@field lifeChanges valueChangeEvent[]
---@field bombChanges valueChangeEvent[]
---@field enterSegments enterSegmentEvent[]

---@alias StatisticsData StatisticsOneStageData[]

local Statistics={
    ---@type StatisticsData
    data={}
}

---@type StatisticsOneStageData
local OneStageData

---@return StatisticsOneStageData
local function GetOneStageDataTemplate()
    -- stage1 is a temporary placeholder. correct value is set in addStageData. other values similar
    return {stageKey='stage1',duration=0,lifeChanges={},bombChanges={},enterSegments={}}
end
local ResetStatistics=function ()
    Statistics.data={}
    OneStageData=GetOneStageDataTemplate()
end
EM.listenTo(EM.EVENTS.RESET_STATISTICS,ResetStatistics)
local function getFrame()
    return G.runInfo.player.frame
end
local function getCallbackOf(key)
    return function (value)
        table.insert(OneStageData[key],{getFrame(),value})
    end
end
EM.listenTo(EM.EVENTS.SET_LIFE,getCallbackOf('lifeChanges'))
EM.listenTo(EM.EVENTS.SET_BOMB,getCallbackOf('bombChanges'))
EM.listenTo(EM.EVENTS.ENTER_SEGMENT,function (value)
    table.insert(OneStageData.enterSegments,{frame=getFrame(),segmentKey=value,life=G.runInfo.lives,bomb=G.runInfo.bombs})
end)
local function addStageData()
    OneStageData.stageKey=StageManager.args.stageKey
    OneStageData.duration=getFrame()
    table.insert(Statistics.data,OneStageData)
    OneStageData=GetOneStageDataTemplate()
end
EM.listenTo(EM.EVENTS.STAGE_END,addStageData)
EM.listenTo(EM.EVENTS.LOSE_GAME,addStageData)
-- when entering GAME_END by losing, does need to post LOSE_GAME to show current stage statistics. but after using continue, the added stage data needs to be popped and becomes the current stage data written to.
local function popStageData()
    OneStageData=Statistics.data[#Statistics.data]
    Statistics.data[#Statistics.data]=nil
end
EM.listenTo(EM.EVENTS.USE_CONTINUE,popStageData)

-- prepare layer, merge stages, calculate y range, return line vertices

---@class tick
---@field value number
---@field name string
---@alias ticks tick[]
---@alias twoTicks {major:ticks,minor:ticks} if both ticks are empty, draw part would consider it to be auto
---@alias range {min:number,max:number}
---@class seriesData
---@field key string
---@field vertices Position[]
---@field color rgbaColor

---@class LineGraphData:strict
---@field ranges {x:range,y:range}
---@field ticks {x:twoTicks,y:twoTicks}
---@field series seriesData[]

local colors={
    lives={1,0.15,0.7,0.7},
    bombs={0,0.7,0,0.7},
}
---@param data StatisticsData
---@return LineGraphData
local function TransformStatisticsData(data)
    local accumulatedFrames=0
    local ticks={x={major={},minor={}},y={major={},minor={}}}
    ---@type seriesData[]
    local series={
        {key='lives',vertices={},color=colors.lives},
        {key='bombs',vertices={},color=colors.bombs}
    }
    for i,oneStageData in ipairs(data) do
        table.insert(ticks.x.major,{value=accumulatedFrames,name=Localize{'ui','SPELL_PRACTICE','stages',oneStageData.stageKey}})
        for index, value in ipairs(oneStageData.enterSegments) do
            table.insert(ticks.x.minor,{value=accumulatedFrames+value.frame,name=Localize{'ui','PRACTICE','segments',value.segmentKey,'name'}})
            if i==1 and index==1 then -- add first points
                table.insert(series[1].vertices,{x=0,y=value.life})
                table.insert(series[2].vertices,{x=0,y=value.bomb})
            end
        end
        local seriesNames={'lifeChanges','bombChanges'}
        for index,key in ipairs(seriesNames) do
            for _,value in ipairs(oneStageData[key]) do
                -- make staircase (this point x, last point y)
                local lastPoint=series[index].vertices[#series[index].vertices]
                table.insert(series[index].vertices,{x=accumulatedFrames+value[1],y=lastPoint.y})
                table.insert(series[index].vertices,{x=accumulatedFrames+value[1],y=value[2]})
            end
        end
        accumulatedFrames=accumulatedFrames+oneStageData.duration
    end
    local ranges={
        x={min=0,max=0},
        y={min=0,max=0}
    }
    for _,seriesValue in ipairs(series) do
        for _,vertex in ipairs(seriesValue.vertices) do
            local y=vertex.y
            ranges.y.min=math.min(ranges.y.min,y)
            ranges.y.max=math.max(ranges.y.max,y)
        end
    end
    ranges.x.max=accumulatedFrames
    -- extend lines to the end of the x axis
    for _,value in ipairs(series) do
        local lastPoint=value.vertices[#value.vertices]
        if lastPoint and lastPoint.x~=ranges.x.max then
            table.insert(value.vertices,{x=ranges.x.max,y=lastPoint.y})
        end
    end
    ---@type LineGraphData
    local ret={
        ranges=ranges,
        ticks=ticks,
        series=series
    }
    return ret
end

--- draw layer.

--- number to text (keep decimal places same as gapValue's magnitude, and when gap)
local function numberToText(number,gapValue)
    if gapValue<1000 and gapValue>=1 then
        return tostring(math.ceil(number-0.5))
    end
    local magnitude=math.floor(math.log10(gapValue))
    if magnitude<0 and magnitude>=-2 then
        return string.format("%."..math.abs(magnitude).."f",number)
    end
    local number2=number/10^magnitude
    local string=tostring(math.ceil(number2-0.5))
    if string=="0" then
        return "0"
    end
    local e=magnitude+(#string-1)
    if #string>1 then
        string=string:sub(1,1)..'.'..string:sub(2)
    end
    return string..'e'..tostring(e)
end

--- auto ticks calculator. would choose 1, 2 or 5x10^n gap for major ticks that satisfy gap >20px and <60px. no minor ticks
---@param range range
---@param height number
---@return range newRange new range that would normally be bigger than min max. for exmaple, min=1.4, max=5.8, height=180px, would return {min=1.1,max=6.1}, ticks at integers that keep min-max value at center.
---@return twoTicks ticks
local function autoTicks(range,height)
    local min,max=range.min,range.max
    if min==max then -- malformed, whatever
        return range,{major={},minor={}}
    end
    local reverse=min>max
    if reverse then
        min,max=max,min
    end
    local minGap,maxGap=20,60
    local delta=max-min
    local deltaAbs=math.abs(delta)
    local maxGapValue=deltaAbs/math.floor(height/maxGap)
    local minGapValue=deltaAbs/math.ceil(height/minGap)
    -- just pick middle one
    local middleGapValue=maxGapValue^0.5*minGapValue^0.5
    -- round to 1, 2 or 5x10^n
    local magnitude=math.floor(math.log10(middleGapValue))
    local rest=math.log10(middleGapValue)-magnitude -- [0,1)
    -- pick from 0, log10(2), log10(5) and 1 that is closest to rest
    local best,diff=0,rest
    local values={math.log10(2),math.log10(5),1}
    for _,value in ipairs(values) do
        local diffi=math.abs(rest-value)
        if diffi<diff then
            best,diff=value,diffi
        end
    end
    local finalGapValue=10^(best+magnitude)
    local finalGapCount=math.ceil(deltaAbs*1.03/finalGapValue) -- *1.03 to ensure some gap
    local finalGaps=finalGapCount*finalGapValue
    local average=(min+max)/2
    local finalRange={min=average-finalGaps/2,max=average+finalGaps/2}
    local majorTicks={}
    local value=math.ceil(min/finalGapValue)*finalGapValue
    while value<finalRange.max do
        table.insert(majorTicks,reverse and 1 or #majorTicks+1,{value=value,name=numberToText(value,finalGapValue)})
        value=value+finalGapValue
    end
    if reverse then
        finalRange={min=finalRange.max,max=finalRange.min}
    end
    return finalRange,{major=majorTicks,minor={}}
end

---@class UILineGraph:UICanvas
---@field data LineGraphData
---@field setData fun(self:UILineGraph,data:LineGraphData) update the data and call drawToCanvas
---@field drawToCanvas fun(self:UILineGraph) draw the graph onto canvas.
---@overload fun(args:UILineGraphArgs):UILineGraph
local UILineGraph=UI.Canvas:extend()

---@class UILineGraphArgs:UICanvasArgs
---@param args UILineGraphArgs
function UILineGraph:new(args)
    args=args or {}
    UI.Canvas.new(self,args)
    self.data={
        ranges={x={min=0,max=1},y={min=0,max=1}},
        ticks={x={major={},minor={}},y={major={},minor={}}},
        series={}
    }
end

function UILineGraph:setData(data)
    self.data=data
    local ranges,ticks,series=self.data.ranges,self.data.ticks,self.data.series
    local width,height=self.canvas:getWidth(),self.canvas:getHeight()
    local yrange,yticks=autoTicks(ranges.y,height)
    self.data.ranges.y,self.data.ticks.y=yrange,yticks
    self:drawToCanvas()
end

---map value in range to [0,1]
---@param range range
---@param value number
---@return number
local function rangeMap(range,value)
    return (value-range.min)/(range.max-range.min)
end

function UILineGraph:drawToCanvas()
    local color={love.graphics.getColor()}
    local lineWidth=love.graphics.getLineWidth()
    local canvas=love.graphics.getCanvas()
    love.graphics.setCanvas(self.canvas)
    love.graphics.clear()
    local ranges,ticks,series=self.data.ranges,self.data.ticks,self.data.series
    local width,height=self.canvas:getWidth(),self.canvas:getHeight()
    -- want to know how much edge is needed for tick texts. y ticks are horizontal texts, while x ticks could include small vertical texts for minor segment ticks when it's narrow but currently, just draw horizontal texts.
    local font=SetFont(16)
    local yTextsMaxWidth=0
    for index, value in ipairs(ticks.y.major) do
        yTextsMaxWidth=math.max(yTextsMaxWidth,font:getWidth(value.name))
    end
    local fontHeight=font:getHeight()
    local xTextsMaxHeight=font:getHeight()*2

    -- a box
    love.graphics.setColor(0,0,0,1)
    love.graphics.rectangle("fill",0,0,width,height)
    local boxXYWH={yTextsMaxWidth,0,width-yTextsMaxWidth,height-xTextsMaxHeight}
    local function toBox(x01,y01)
        return boxXYWH[1]+boxXYWH[3]*x01,boxXYWH[2]+boxXYWH[4]*y01
    end
    love.graphics.setColor(1,1,1,1)
    love.graphics.rectangle("line",boxXYWH[1],boxXYWH[2],boxXYWH[3],boxXYWH[4])
    -- ticks
    local tickLengths={major=10,minor=5}
    for tickType,ticks2 in pairs(ticks.x) do
        for index,tick in ipairs(ticks2) do
            local x,y=toBox(rangeMap(ranges.x,tick.value),1)
            love.graphics.line(x,y,x,y-tickLengths[tickType])
            local next=ticks2[index+1]
            local nextx,_=toBox(rangeMap(ranges.x,next and next.value or ranges.x.max),1)
            y=y+(tickType=='major' and fontHeight or 0)
            love.graphics.line(x,y,x,y+fontHeight)
            local neededWidth=font:getWidth(tick.name)
            if neededWidth<nextx-x then
                love.graphics.printf(tick.name,x,y,nextx-x,'center')
            end
        end
    end
    for tickType,ticks2 in pairs(ticks.y) do
        for _,tick in ipairs(ticks2) do
            local x,y=toBox(0,1-rangeMap(ranges.y,tick.value))
            love.graphics.line(x,y,x+tickLengths[tickType],y)
            love.graphics.printf(tick.name,x-yTextsMaxWidth,y-fontHeight/2,yTextsMaxWidth,'right')
        end
    end
    -- lines
    local function toPixel(x, y)
        local px = rangeMap(ranges.x, x)
        local py = (1 - rangeMap(ranges.y, y))
        return toBox(px,py)
    end
    love.graphics.setLineWidth(2)
    for index=#series,1,-1 do
        local s=series[index] -- top series (life) at top
        if #s.vertices >= 2 then
            local polyline = {}
            for _, pt in ipairs(s.vertices) do
                local px, py = toPixel(pt.x, pt.y)
                table.insert(polyline, px)
                table.insert(polyline, py)
            end
            love.graphics.setColor(s.color)
            love.graphics.line(polyline)
        end
    end

    love.graphics.setCanvas(canvas)
    love.graphics.setLineWidth(lineWidth)
    love.graphics.setColor(color)
end

Statistics.GetData=function ()
    return TransformStatisticsData(Statistics.data)
end
Statistics.UILineGraph = UILineGraph

return Statistics
