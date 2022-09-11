require('../../requires/service')
require('NetworkService')

---@class NetworkRequestClient : Service
NetworkRequestClient = {}
NetworkRequestClient.__index = NetworkRequestClient

---@param networkService NetworkService
---@return NetworkRequestClient
function NetworkRequestClient.new(networkService)
    local self = --[[---@type self]] Service.new()

    ---@param command any
    ---@return any
    function self.sendCommand(command)

    end

    ---@param state State
    function self.start(state)
    end

    return setmetatable(self, NetworkRequestClient)
end