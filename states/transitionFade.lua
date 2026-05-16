local function halfway(self,args)
    local target=self.UIDEF[args.lastState].base[args.from.target]
    if target then
        target.transparency=1 -- restore alpha
    end
    local currentUI=self.currentUI
    self.currentUI=self.UIDEF[args.nextState]
    self.currentUI.enter(self,args.nextState)
    self.currentUI=currentUI
    self.currentUI.halfway=true
end
return {
    TRANSITION=true,
    enter=function(self,args)
        self.currentUI.transitionArgs=args
        self.currentUI.duration=0
        self.currentUI.halfway=false
        local target=self.UIDEF[args.lastState].base[args.from.target]
        if target then
            target.transparency=1
        end
        if not self.UIDEF[args.nextState].inited then
            if self.UIDEF[args.nextState].init then
                self.UIDEF[args.nextState].init(self)
            end
            self.UIDEF[args.nextState].inited=true
        end
        target=self.UIDEF[args.nextState].base[args.to.target]
        if target then
            target.transparency=0
        end
        if args.from.duration==0 then
            halfway(self,args)
        end
    end,
    update=function(self,dt)
        -- in this transition no need to consider interrupt because input is consumed
        Input.consume()
        local args=self.currentUI.transitionArgs
        self.currentUI.duration=self.currentUI.duration+1
        if self.currentUI.duration==args.from.duration then -- execute nextState:enter()
            halfway(self,args)
        end
        if self.currentUI.duration==args.from.duration+args.to.duration then 
            self.STATE=args.nextState
            self.currentUI=self.UIDEF[self.STATE]
            return
        end
        if not self.currentUI.halfway then
            local alpha=args.from.progressFunc(self.currentUI.duration/args.from.duration)
            local target=self.UIDEF[args.lastState].base[args.from.target]
            if target then
                target.transparency=1-alpha -- fade out
            end
            if args.from.doUpdate then
                local currentUI=self.currentUI
                self.currentUI=self.UIDEF[args.lastState]
                self.currentUI.update(self)
                self.currentUI=currentUI
            end
        else
            local alpha=args.to.progressFunc((self.currentUI.duration-args.from.duration)/args.to.duration)
            local target=self.UIDEF[args.nextState].base[args.to.target]
            if target then
                target.transparency=alpha
            end
            if args.to.doUpdate then
                local currentUI=self.currentUI
                self.currentUI=self.UIDEF[args.nextState]
                self.currentUI.update(self)
                self.currentUI=currentUI
            end
        end
    end,
    draw=function(self)
        local args=self.currentUI.transitionArgs

        local currentUI=self.currentUI
        if not self.currentUI.halfway then
            self.currentUI=self.UIDEF[args.lastState]
            self.currentUI.draw(self)
        else
            self.currentUI=self.UIDEF[args.nextState]
            self.currentUI.draw(self)
        end
        self.currentUI=currentUI
    end,
    drawText=function(self)
        local args=self.currentUI.transitionArgs

        local currentUI=self.currentUI
        if not self.currentUI.halfway then
            self.currentUI=self.UIDEF[args.lastState]
            self.currentUI.drawText(self)
        else
            self.currentUI=self.UIDEF[args.nextState]
            self.currentUI.drawText(self)
        end
        self.currentUI=currentUI
    end
}