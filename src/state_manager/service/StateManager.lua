---@class StateManager
---@field __index
StateManager = {}
StateManager.__index = StateManager

---@param states State[]
---@param system System
---@return StateManager
function StateManager.new(states, system)
    local self = --[[---@type self]] {}

    local currentStateIndex = 1
    local currentState = states[1]

    function self.start()
        currentState.start()

        DuLuacUtils.addListener(system, 'onActionStart', {
            ['option1'] = self.nextState
        })
    end

    function self.nextState()
        currentState.stop()

        if currentStateIndex + 1 > #states then
            currentStateIndex = 1
        else
            currentStateIndex = currentStateIndex + 1
        end

        currentState = states[currentStateIndex]
        currentState.start()
    end

    return setmetatable(self, StateManager)
end
