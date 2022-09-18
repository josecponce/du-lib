require('../../requires/service')
require('../../datastructures/CircularBuffer')
require('NetworkService')
require('../NetworkRequestProtocol')

local json = require('dkjson')

---@class NetworkRequest
---@field remoteChannel string
---@field request any
---@field callback fun(result: any): void
NetworkRequest = {}

---@param remoteChannel string
---@param request any
---@param callback fun(result: any): void
---@return NetworkRequest
function NetworkRequest.new(remoteChannel, request, callback)
    return --[[---@type NetworkRequest]] {
        remoteChannel = remoteChannel,
        request = request,
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
function NetworkRequestClient.new(networkService, commandsQueueSize, commandTimerInterval, wakeRemote)
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

        local ackOpenEvent, dataEvent, timeoutEvent, pingEvent, ackCloseEvent, success

        ---@overload fun(): void
        local function completeRequest()
            if ackOpenEvent then
                networkService:clearEvent(NETWORK_SERVICE_EVENTS.ACK_OPEN, ackOpenEvent)
            end
            if dataEvent then
                networkService:clearEvent(NETWORK_SERVICE_EVENTS.DATA, dataEvent)
            end
            if timeoutEvent then
                networkService:clearEvent(NETWORK_SERVICE_EVENTS.TIMEOUT, timeoutEvent)
            end
            if pingEvent then
                networkService:clearEvent(NETWORK_SERVICE_EVENTS.PING, pingEvent)
            end
            if ackCloseEvent then
                networkService:clearEvent(NETWORK_SERVICE_EVENTS.ACK_CLOSE, ackCloseEvent)
            end

            if not success then
                request.callback(false)
            end
        end

        ackOpenEvent = networkService:onEvent(NETWORK_SERVICE_EVENTS.ACK_OPEN, function(_, source)
            networkService:clearEvent(NETWORK_SERVICE_EVENTS.ACK_OPEN, ackOpenEvent)
            if source ~= remoteChannel then
                completeRequest()
                networkService.close()
                networkError('Connection opened for incorrect channel.')
            end

            networkService.send(NetworkRequestProtocol.BEGIN_REQUEST)
            networkService.send(json.encode(request.request))
            networkService.send(NetworkRequestProtocol.END_REQUEST)
        end)

        local responseBegan
        ---@type string[]
        local response = { }
        dataEvent = networkService:onEvent(NETWORK_SERVICE_EVENTS.DATA, function(_, source, data)
            if source ~= remoteChannel then
                completeRequest()
                networkService.close()
                networkError('Data received from incorrect channel.')
            end
            if not responseBegan then
                if data ~= NetworkRequestProtocol.BEGIN_RESPONSE then
                    completeRequest()
                    networkService.close()
                    networkError('Expected begin response for our request but got: ' .. data)
                else
                    responseBegan = true
                end
            elseif data == NetworkRequestProtocol.END_RESPONSE then
                networkService.close()
                local fullResponse = table.concat(response)
                local result = json.decode(fullResponse)
                success = true
                request.callback(result)
            else
                table.insert(response, --[[---@type string]] data)
            end
        end)

        ackCloseEvent = networkService:onEvent(NETWORK_SERVICE_EVENTS.ACK_CLOSE, function(_, _)
            completeRequest()
            requestRunning = false
        end)

        timeoutEvent = networkService:onEvent(NETWORK_SERVICE_EVENTS.TIMEOUT, function(_, _)
            completeRequest()
            requestRunning = false
            networkError('Connection timed out while awaiting a response for request: ' .. json.encode(request.request))
        end)

        if wakeRemote then
            --this could hang if no ping is received back since no connection is opened and therefore there would be no timeout.
            pingEvent = networkService:onEvent(NETWORK_SERVICE_EVENTS.PING, function(_, source)
                if source ~= remoteChannel then
                    completeRequest()
                    networkError('Ping received from incorrect channel.')
                else
                    networkService.connect(remoteChannel)
                end
            end)
            networkService.ping(remoteChannel)
        else
            networkService.connect(remoteChannel)
        end
    end

    ---@param state State
    function self.start(state)
        state.registerTimer('NetworkRequestClient_sendCommand' .. tostring(instanceCount), commandTimerInterval, sendCommandTimer)

        instanceCount = instanceCount + 1
    end

    return setmetatable(self, NetworkRequestClient)
end