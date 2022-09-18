require('../../requires/service')
require('NetworkService')
require('../NetworkRequestProtocol')

local json = require('dkjson')

---@class NetworkRequestServer : Service
NetworkRequestServer = {}
NetworkRequestServer.__index = NetworkRequestServer

---@param message string
local function networkError(message)
    local errorMessage = 'NetworkRequestServer Error: ' .. message
    system.print(errorMessage)
    error(errorMessage)
end

---@param networkService NetworkService
---@param handler fun(source: string, request: any): any params are source and request
---@param shutdownSwitch ManualSwitch if not nil unit will be exited (and switch deactivated) after either a response is send, a connection is closed or a timout elapses
---@param unitTimeout number if shutdownSwitch not nil then unit will exit after this long
---@param remoteChannel string if shutdownSwitch not nil then a ping is sent to this channel on startup to notify client server is awake
---@overload fun(networkService: NetworkService, handler: fun(source: string, request: any): any): NetworkRequestServer
---@return NetworkRequestServer
function NetworkRequestServer.new(networkService, handler, shutdownSwitch, unitTimeout, remoteChannel)
    local self = --[[---@type self]] Service.new()

    local receivingRequest
    ---@type string[]
    local currentRequest

    local function exit()
        if shutdownSwitch then
            shutdownSwitch.deactivate()
            unit.exit()
        end
    end

    local function endRequest()
        --not in single request mode
        if not shutdownSwitch then
            currentRequest = --[[---@type string[] ]] nil
            receivingRequest = false
        end
    end

    ---@param source string
    ---@param data string
    local function handleRequest(source, data)
        local request = json.decode(data)
        local response = handler(source, request)

        networkService.send(NetworkRequestProtocol.BEGIN_RESPONSE)
        networkService.send(json.encode(response))
        networkService.send(NetworkRequestProtocol.END_RESPONSE)
    end

    ---@param source string
    ---@param data string
    local function onData(_, source, data)
        if not receivingRequest then
            if data == NetworkRequestProtocol.BEGIN_REQUEST then
                receivingRequest = true
                currentRequest = {}
            else
                networkError('Received data packet without prior ' .. NetworkRequestProtocol.BEGIN_REQUEST .. '.')
            end
        elseif data == NetworkRequestProtocol.END_REQUEST then
            local fullRequest = table.concat(currentRequest)
            handleRequest(source, fullRequest)
            endRequest()
        else
            table.insert(currentRequest, data)
        end
    end

    ---@param state State
    function self.start(state)
        local onDisconnect = shutdownSwitch and exit or endRequest
        networkService:onEvent(NETWORK_SERVICE_EVENTS.DATA, onData)
        networkService:onEvent(NETWORK_SERVICE_EVENTS.TIMEOUT, onDisconnect)
        networkService:onEvent(NETWORK_SERVICE_EVENTS.CLOSE, onDisconnect)

        if unitTimeout then
            state.registerTimer('NetworkRequestServer_unitTimeout', unitTimeout, exit)
        end

        if shutdownSwitch then
            networkService.ping(remoteChannel)
        end
    end

    return setmetatable(self, NetworkRequestServer)
end