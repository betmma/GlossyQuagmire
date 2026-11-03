local UI=...

local keyboard={
    {'A',"B","C","D","E","F","G","H","I","J","K","L","M"},
    {"N","O","P","Q","R","S","T","U",'V',"W","X","Y","Z"},
    {'a',"b","c","d","e","f","g","h","i","j","k","l","m"},
    {"n","o","p","q","r","s","t","u",'v',"w","x","y","z"},
    {"0","1","2","3","4","5","6","7",'8',"9","+","-","="},
    {".",",","!","?","@",":",";","[",']',"(",")","_","/"},
    {"{","}","|","~","^","#","$","%",'&',"*"," ","BS","END"},
}

---@class UIKeyboard:UIOptions
---@field text string the input string
---@field maxLength integer
---@overload fun(args:UIKeyboardArgs):UIKeyboard
local UIKeyboard=UI.Options:extend()

---@class UIKeyboardArgs:UIOptionsArgs
---@field maxLength? integer defaults to ReplayManager.MAX_NAME_LENGTH
---@field textChangeCallBack fun(newText:string) callback when self.text changed by entering or deleting character
---@field endCallBack fun() callback when end is pressed
---@param args UIKeyboardArgs
function UIKeyboard:new(args)
    UI.Options.new(self,args)
    self.maxLength=args.maxLength or ReplayManager.MAX_NAME_LENGTH
    for i,row in ipairs(keyboard) do
        for j,char in ipairs(row) do
            local fontSize=24-(#char-1)*4
            local fontName
            local text=char
            if text==' ' then -- clearer display for space
                text='▯'
                fontName=Fonts.zh_cn
            end
            local key=UI.Text{
                text=text,x=(j-1)*40,y=(i-1)*40,color={1,1,1,1},fontSize=fontSize,fontName=fontName,width=20,align='center',autoSize=true,
                events={
                    [UI.EVENTS.SELECT]=function()
                        local name=self.text
                        if char=='END' then
                            if #name==0 then
                                SFX:play('cancel')
                                return
                            end
                            SFX:play('select',false)
                            args.endCallBack()
                        elseif char=='BS' then
                            if #name==0 then
                                SFX:play('cancel')
                                return
                            end
                            SFX:play('select',false)
                            self.text = name:sub(1, #name - 1)
                            args.textChangeCallBack(self.text)
                        else -- normal char
                            if #name>=self.maxLength then
                                SFX:play('cancel')
                                return
                            end
                            SFX:play('select',false)
                            self.text = name .. char
                            args.textChangeCallBack(self.text)
                        end
                    end,
                }
            }
            self:addOption(key)
        end
    end
end

return UIKeyboard