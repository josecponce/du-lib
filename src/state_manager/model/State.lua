---@class State
State = {}
State.__index = State

---@param services Service[]
---@param unit ControlUnit
---@param system System
---@param workPerTick number coroutine amount of work done per tick
---@param workTickInterval number coroutine interval between two ticks
---@param onStarts (fun(state: State): void)[]
---@overload fun(services: Service[], unit: ControlUnit, system: System, workPerTick: number, workInterval: number): State
---@return State
function State.new(services, unit, system, workPerTick, workTickInterval, onStarts)
    local self = --[[---@type self]] {}

    onStarts = onStarts or {}

    ---@type fun[]
    local handlersDeregister = {}
    ---@type string[]
    local timers = {}

    local function drawHud()
        ---@type string[]
        local hud = {}
        for _, service in ipairs(services) do
            if service.hasHud then
                table.insert(hud, service.drawHud())
            end
        end

        if #hud > 0 then
            local hudString = table.concat(hud)

            if hudString ~= '' then
                system.setScreen(hudString)
            end
        end
    end

    local coroutineManager = CoroutineManager.new(workPerTick)
    function self.start()
        for _, service in ipairs(services) do
            service.start(self)
        end

        for _, onStart in ipairs(onStarts) do
            onStart(self)
        end

        if coroutineManager.activeCoroutines > 0 then
            self.registerTimer('State_masterCoroutine', workTickInterval, coroutineManager.poll)
        end

        system.showScreen(true)
        self.registerHandler(system, SYSTEM_EVENTS.UPDATE, drawHud)
    end

    function self.stop()
        for _, deregister in ipairs(handlersDeregister) do
            deregister()
        end
        handlersDeregister = {}

        for _, timer in ipairs(timers) do
            unit.stopTimer(timer)
        end
        timers = {}

        coroutineManager = CoroutineManager.new(workPerTick)
    end

    ---@param object DuLuacElement
    ---@param event string
    ---@param handler fun
    function self.registerHandler(object, event, handler)
        local handlerId = object:onEvent(event, handler)
        table.insert(handlersDeregister, function()
            object:clearEvent(event, handlerId)
        end)
    end

    ---@param service Service
    ---@param name string
    ---@param handler fun(permit: CoroutinePermit): void
    ---@param repeated boolean
    ---@overload fun(service: Service, name: string, handler: (fun(permit: CoroutinePermit): void)): void
    function self.registerCoroutine(service, name, handler, repeated)
       coroutineManager.registerCoroutine(service, name, handler, repeated)
    end

    ---@param timer string
    ---@param interval number
    ---@param handler fun
    function self.registerTimer(timer, interval, handler)
        self.registerHandler(unit, 'onTimer', DuLuacUtils.createHandler({
            [timer] = handler
        }))

        unit.setTimer(timer, interval)
        table.insert(timers, timer)
    end

    return setmetatable(self, State)
end
