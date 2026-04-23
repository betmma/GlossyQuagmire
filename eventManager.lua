local EventManager = {}
EventManager.EVENTS={
    SWITCH_STATE='switchState',
    PLAY_AUDIO='playAudio',
    PLAYER_HIT='playerHit',
    -- below are from previous game
    PLAYER_GRAZE='playerGraze',
    PLAYER_ACCUMULATE_FLASHBOMB='playerAccumulateFlashbomb',
    PLAYER_SHOOTING='playerShooting',
    PLAYER_BULLET_HIT_ENEMY='playerBulletHitEnemy',
    NICKNAME_GET='nicknameGet',
    NICKNAME_DANGEROUS_AREA='nicknameDangerousArea',
    WIN_GAME='winLevel',
    LOSE_LEVEL='loseLevel',
    LEAVE_LEVEL='leaveLevel',
    ENTER_LEVEL='enterLevel',
    ENEMY_GRAZED='enemyGrazed',
}
EventManager.DELETE_LISTENER='deleteListener'

EventManager.listeners = {}

---@param eventName string
---@param func function
---@param removeEventName string|nil
--- Registers a listener for an event. If `removeEventName` is provided, the listener will be removed when that event is posted.
function EventManager.listenTo(eventName, func, removeEventName)
    if not EventManager.listeners[eventName] then
        EventManager.listeners[eventName] = {}
    end
    table.insert(EventManager.listeners[eventName], func)
    if removeEventName then
        local removeFunc
        removeFunc = function()
            EventManager.removeListener(eventName, func)
            EventManager.removeListener(removeEventName, removeFunc)
        end
        EventManager.listenTo(removeEventName, removeFunc)
    end
end

function EventManager.removeListener(eventName, func)
    if not EventManager.listeners[eventName] then
        return
    end
    for i, listener in ipairs(EventManager.listeners[eventName]) do
        if listener == func then
            table.remove(EventManager.listeners[eventName], i)
            return
        end
    end
end
-- though arbitrary params can be used, since there is no ide to hint the listener function, it's suggested to use:
-- first arg: main object (if listener is a method, it will be the self)
-- second arg: quantity
-- third arg: string to tell different source 
---@param eventName string
function EventManager.post(eventName, ...)
    if EventManager.listeners[eventName] then
        -- make a copy to avoid issues if listeners are modified during iteration
        local listenersCopy = {}
        for i, func in ipairs(EventManager.listeners[eventName]) do
            table.insert(listenersCopy, func)
        end
        for _, func in ipairs(listenersCopy) do
            local ret=func(...)
            if ret == EventManager.DELETE_LISTENER then
                EventManager.removeListener(eventName, func)
            end
        end
    end
end
return EventManager