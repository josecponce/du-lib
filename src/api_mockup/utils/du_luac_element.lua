---@class DuLuacElement
DuLuacElement = {}
DuLuacElement.__index = DuLuacElement

---@return DuLuacElement
function DuLuacElement.new()
    local self = --[[---@type self]] {}

    ---@param event string Event
    ---@param handler fun Handler
    ---@return number
    function self:onEvent(event, handler) return 0 end

    ---@param event string Event
    ---@param handlerId number Handler
    function self:clearEvent(event, handlerId) end

    ---@param event string Event
    function self:triggerEvent(event, ...) end

    return setmetatable(self, DuLuacElement)
end