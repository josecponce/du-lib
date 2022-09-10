---@class CoroutinePermit
---@field __index
---@field workCounter number
CoroutinePermit = {}
CoroutinePermit.__index = CoroutinePermit

---@param max number
---@return CoroutinePermit
function CoroutinePermit.new(max)
    local self = --[[---@type self]] {}

    self.workCounter = 0

    ---@param permits number
    ---@overload fun() : void
    function self.acquire(permits)
        permits = permits or 1

        if self.workCounter < max then
            self.workCounter = self.workCounter + 1
        else
            self.yield()
        end
    end

    function self.yield()
        _, max = coroutine.yield(self.workCounter)
        self.workCounter = 0
    end

    return setmetatable(self, CoroutinePermit)
end

---@class CoroutineManager
---@field __index
CoroutineManager = {}
CoroutineManager.__index = CoroutineManager

---@param workPerTick number coroutine amount of work done per tick
---@return CoroutineManager
function CoroutineManager.new(workPerTick)
    local self = --[[---@type self]] {}

    ---@type thread
    local masterCoroutine
    ---@type table<Service, table<string, thread>>
    local coroutines
    ---@type number
    self.activeCoroutines = 0

    function self.poll()
        if self.activeCoroutines > 0 and coroutine.status(masterCoroutine) == "suspended" then
            local result, msg = coroutine.resume(masterCoroutine)
            if not result then
                error('master coroutine failed: ' .. msg)
            end
        end
    end

    ---@param service Service
    ---@param name string
    ---@param handler fun(permit: CoroutinePermit): void
    ---@param repeated boolean
    ---@overload fun(service: Service, name: string, handler: (fun(permit: CoroutinePermit): void)): void
    function self.registerCoroutine(service, name, handler, repeated)
        coroutines = coroutines or {}
        self.activeCoroutines = self.activeCoroutines + 1

        if not masterCoroutine then
            masterCoroutine = coroutine.create(function()
                local tickWorkQuota = workPerTick
                local tickRoutinesCalled = 0
                while self.activeCoroutines > 0 do
                    local cycleActiveCoroutines = 0
                    for _, routines in pairs(coroutines) do
                        for routineName, routine in pairs(routines) do
                            local permit = CoroutinePermit.new(tickWorkQuota)

                            if coroutine.status(routine) == "suspended" then
                                cycleActiveCoroutines = cycleActiveCoroutines + 1
                                tickRoutinesCalled = tickRoutinesCalled + 1
                                local result, returned = coroutine.resume(routine, permit, tickWorkQuota)
                                if result then
                                    tickWorkQuota = tickWorkQuota - returned
                                else
                                    error('coroutine failed "' .. routineName .. '": ' .. returned)
                                end

                                if tickWorkQuota == 0 or tickRoutinesCalled >= self.activeCoroutines then
                                    coroutine.yield()
                                    tickWorkQuota = workPerTick
                                    tickRoutinesCalled = 0
                                end
                            end
                        end
                    end
                    self.activeCoroutines = cycleActiveCoroutines
                end
            end)
        end

        local routine = coroutine.create(function(permit)
            while repeated do
                handler(permit)
                permit.yield()
            end
            handler(permit)

            return permit.workCounter
        end)

        local serviceCoroutines = coroutines[service] or {}
        serviceCoroutines[name] = routine
        coroutines[service] = serviceCoroutines
    end

    return setmetatable(self, CoroutineManager)
end