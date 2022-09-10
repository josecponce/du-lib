---@class Service : DuLuacElement
---@field hasHud boolean
Service = {}
Service.__index = Service

---@return Service
function Service.new()
    local self = --[[---@type self]] {}

    library.addEventHandlers(self)

    ---@param state State
    function self.start(state)
        error('Service.start() method not implemented.')
    end

    self.hasHud = false

    ---@return string
    function self.drawHud()
        error('Service.drawHud() method not implemented.')

        return ''
    end

    return setmetatable(self, Service)
end
