require('../../requires/service')
require('../../datastructures/CircularBuffer')
require('NetworkService')

local serde = require('../../requires/serde')

---@class NetworkRequest
---@field remoteChannel string
---@field command any
---@field callback fun(result: any): void
NetworkRequest = {}

---@return NetworkRequest
function NetworkRequest.new(remoteChannel, command, callback)
    return --[[---@type NetworkRequest]] {
        remoteChannel = remoteChannel,
        command = command,
        callback = callback
    }
end

---@class NetworkRequestClient : Service
NetworkRequestClient = {}
NetworkRequestClient.__index = NetworkRequestClient

local instanceCount = 0

---@param message string
local function networkError(message)
    local errorMessage = 'NetworkRequestClient Error: ' .. message
    system.print(errorMessage)
    error(errorMessage)
end

---@param networkService NetworkService
---@param commandsQueueSize number
---@param commandTimerInterval number
---@return NetworkRequestClient
function NetworkRequestClient.new(networkService, commandsQueueSize, commandTimerInterval)
    local self = --[[---@type self]] Service.new()

    local buffer = --[[---@type CircularBuffer<NetworkRequest>]] CircularBuffer.new(commandsQueueSize)
    local requestRunning

    ---@param request NetworkRequest
    function self.sendRequest(request)
        if not buffer.push(request) then
            networkError('Failed to queue up request due to lack of space in buffer.')
        end
    end

    local function sendCommandTimer()
        --wait until network is available
        if requestRunning or networkService.connectionOpen() or not buffer.dataAvailable() then
            return
        end

        requestRunning = true
        local request = buffer.pop()
        local remoteChannel = request.remoteChannel

        local ackOpenEvent, dataEvent, timeoutEvent
        ---@param success boolean
        ---@overload fun(): void
        local function completeRequest(success)
            if ackOpenEvent then
                networkService:clearEvent(NETWORK_SERVICE_EVENTS.ACK_OPEN, ackOpenEvent)
            end
            if dataEvent then
                networkService:clearEvent(NETWORK_SERVICE_EVENTS.DATA, dataEvent)
            end
            if timeoutEvent then
                networkService:clearEvent(NETWORK_SERVICE_EVENTS.TIMEOUT, timeoutEvent)
            end
            requestRunning = false
            if not success then
                request.callback(false)
            end
        end

        ackOpenEvent = networkService:onEvent(NETWORK_SERVICE_EVENTS.ACK_OPEN, function(_, source)
            networkService:clearEvent(NETWORK_SERVICE_EVENTS.ACK_OPEN, ackOpenEvent)
            if source ~= remoteChannel then
                completeRequest()
                networkError('Connection opened for incorrect channel.')
            end

            networkService.send(NetworkRequestProtocol.BEGIN_REQUEST)
            networkService.send(serde.serialize(request.command))
            networkService.send(NetworkRequestProtocol.END_REQUEST)
        end)

        local responseBegan
        ---@type string[]
        local response = { }
        dataEvent = networkService:onEvent(NETWORK_SERVICE_EVENTS.DATA, function(_, source, data)
            if source ~= remoteChannel then
                completeRequest()
                networkError('Data received from incorrect channel.')
            end
            if not responseBegan then
                if data ~= NetworkRequestProtocol.BEGIN_RESPONSE then
                    completeRequest()
                    networkError('Expected begin response for our request but got: ' .. data)
                else
                    responseBegan = true
                end
            elseif data == NetworkRequestProtocol.END_RESPONSE then
                completeRequest(true)
                networkService.close()
                local fullResponse = table.concat(response)
                local result = serde.deserialize(fullResponse)
                request.callback(result)
            else
                table.insert(response, --[[---@type string]] data)
            end
        end)

        timeoutEvent = networkService:onEvent(NETWORK_SERVICE_EVENTS.TIMEOUT, function(_, _)
            completeRequest()
            networkError('Connection timed out while awaiting a response for request: ' .. serde.serialize(request.command))
        end)

        networkService.connect(remoteChannel)
    end

    ---@param state State
    function self.start(state)
        state.registerTimer('NetworkRequestClient_sendCommand' .. tostring(instanceCount), commandTimerInterval, sendCommandTimer)

        instanceCount = instanceCount + 1
    end

    return setmetatable(self, NetworkRequestClient)
end