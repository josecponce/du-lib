require('../../requires/service')
require('../messages/Packet')
require('../../datastructures/CircularBuffer')

---@class NetworkService : Service
NetworkService = {}
NetworkService.__index = NetworkService

---@param error string
---@param packet Packet
local function printNetworkError(error, packet)
    local msg = 'Network Error: ' .. error
    if packet then
        msg = msg .. ': "' .. Packet.serialize(packet) .. '"'
    end
    system.print(msg)
end

---@param errorMessage string
local function fail(errorMessage)
    system.print(errorMessage)
    error(errorMessage)
end

---@class NetworkServiceEvents
NETWORK_SERVICE_EVENTS = {}
---handler: func(self, source)
NETWORK_SERVICE_EVENTS.OPEN = 'onOpen'
---handler: func(self, source)
NETWORK_SERVICE_EVENTS.ACK_OPEN = 'onAckOpen'
---handler: func(self, source)
NETWORK_SERVICE_EVENTS.CLOSE = 'onClose'
---handler: func(self, source)
NETWORK_SERVICE_EVENTS.ACK_CLOSE = 'onAckClose'
---handler: func(self, source, data)
NETWORK_SERVICE_EVENTS.DATA = 'onData'
---handler: func(self, source)
NETWORK_SERVICE_EVENTS.ACK_DATA = 'onAckData'
---handler: func(self)
NETWORK_SERVICE_EVENTS.TIMEOUT = 'onTimeout'
---handler: func(self, source)
NETWORK_SERVICE_EVENTS.PING = 'onPing'

---@param emitter Emitter
---@param receiver Receiver
---@param listenChannel string
---@param timeout number
---@param dataSendBufferSize number
---@return NetworkService
function NetworkService.new(emitter, receiver, listenChannel, timeout, dataSendBufferSize)
    local self = --[[---@type self]] Service.new()

    local remoteChannel
    local lastMessageTime
    local expectingDataAck
    local expectingOpenAck

    local dataSendBuffer = --[[---@type CircularBuffer<Packet>]] CircularBuffer.new(dataSendBufferSize)
    --enough for 10s at 60fps
    local signalSendBuffer = --[[---@type CircularBuffer<Packet>]] CircularBuffer.new(600)

    function self.connectionOpen()
        return remoteChannel and not expectingOpenAck
    end

    local connectionOpen = self.connectionOpen

    ---@param type "OPEN" | "ACK OPEN" | "CLOSE" | "ACK CLOSE" | "DATA" | "ACK DATA"
    ---@param buffer CircularBuffer<Packet>
    ---@param data string
    ---@overload fun(type: "OPEN" | "ACK OPEN" | "CLOSE" | "ACK CLOSE" | "DATA" | "ACK DATA", buffer: CircularBuffer<Packet>): void
    local function queuePacketSend(type, buffer, data)
        local packet = Packet.new(type, listenChannel, remoteChannel, data)
        if not buffer.push(packet) then
            fail('Network Error: Failed to send message due to send buffer overflow.')
        end
    end

    local function updateLastMessageTime()
        lastMessageTime = system.getArkTime()
    end

    ---@param packet Packet
    local function fromCurrentSource(packet)
        return packet.source and remoteChannel == packet.source
    end

    local function resetConnectionState()
        remoteChannel = nil
        lastMessageTime = nil
        expectingDataAck = false
        expectingOpenAck = false

        dataSendBuffer = --[[---@type CircularBuffer<Packet>]] CircularBuffer.new(dataSendBufferSize)
    end

    ---@param reason string
    local function closeRemoteConnection(reason)
        queuePacketSend(Packet.TYPE_CLOSE, signalSendBuffer, reason)
        resetConnectionState()
    end

    local function handleConnectionTimeout()
        closeRemoteConnection('Connection Timeout')
        self:triggerEvent(NETWORK_SERVICE_EVENTS.TIMEOUT)
    end

    ---@param buffer CircularBuffer<Packet>
    local function handleSend(buffer)
        local packet = buffer.pop()

        if packet.type == Packet.TYPE_DATA then
            expectingDataAck = true
        end
        emitter.send(packet.dest, Packet.serialize(packet))
    end

    local function update()
        if signalSendBuffer.dataAvailable() then
            handleSend(signalSendBuffer)
            return
        end
        if not connectionOpen() then
            return
        end
        --Close connection if no messages in "timeout". Implement keepalive at some point?
        if system.getArkTime() - lastMessageTime > timeout then
            handleConnectionTimeout()
        elseif not expectingDataAck and dataSendBuffer.dataAvailable() then
            handleSend(dataSendBuffer)
        end
    end

    ---@param packet Packet
    local function handleOpenConnection(packet)
        if connectionOpen() then
            printNetworkError('Connection open attempt received while connection already open', packet)
        elseif not packet.source or packet.source:len() == 0 then
            printNetworkError('Connection open request received without client channel provided', packet)
        else
            remoteChannel = packet.source
            updateLastMessageTime()
            queuePacketSend(Packet.TYPE_ACK_OPEN, signalSendBuffer)
            self:triggerEvent(NETWORK_SERVICE_EVENTS.OPEN, packet.source)
        end
    end

    ---@param packet Packet
    local function handleOpenAck(packet)
        if connectionOpen() then
            printNetworkError('Connection Open Ack received while connection already open', packet)
        elseif not expectingOpenAck then
            printNetworkError('Connection Open Ack received while no connection attempt was in progress', packet)
        elseif not fromCurrentSource(packet) then
            printNetworkError('Connection Open Ack received from another source while connection attempt was in progress', packet)
        else
            updateLastMessageTime()
            expectingOpenAck = false
            self:triggerEvent(NETWORK_SERVICE_EVENTS.ACK_OPEN, packet.source)
        end
    end

    ---@param packet Packet
    local function handleCloseConnection(packet)
        if not connectionOpen() then
            printNetworkError('Connection close attempt received while no connection is open', packet)
        elseif not fromCurrentSource(packet) then
            printNetworkError('Connection close attempt received from another source while connection open', packet)
        else
            queuePacketSend(Packet.TYPE_ACK_CLOSE, signalSendBuffer)
            resetConnectionState()
            self:triggerEvent(NETWORK_SERVICE_EVENTS.CLOSE, packet.source)
        end
    end

    ---@param packet Packet
    local function handleCloseAck(packet)
        self:triggerEvent(NETWORK_SERVICE_EVENTS.ACK_CLOSE, packet.source)
    end

    ---@param packet Packet
    local function handleData(packet)
        if not connectionOpen() then
            printNetworkError('Data received while no connection is open', packet)
        elseif not fromCurrentSource(packet) then
            printNetworkError('Data received from another while connection open', packet)
        else
            updateLastMessageTime()
            queuePacketSend(Packet.TYPE_ACK_DATA, signalSendBuffer)
            self:triggerEvent(NETWORK_SERVICE_EVENTS.DATA, packet.source, packet.data)
        end
    end

    local function handleDataAck(packet)
        if not connectionOpen() then
            printNetworkError('Data Ack received while no connection is open', packet)
        elseif not fromCurrentSource(packet) then
            printNetworkError('Data Ack received from another while connection open', packet)
        elseif not expectingDataAck then
            printNetworkError('Data Ack received unexpectedly', packet)
        else
            updateLastMessageTime()
            expectingDataAck = false
            self:triggerEvent(NETWORK_SERVICE_EVENTS.ACK_DATA, packet.source)
        end
    end

    local function handlePing(packet)
        self:triggerEvent(NETWORK_SERVICE_EVENTS.PING, packet.source)
    end

    ---@type table<string, fun(packet: Packet): void>
    local messageHandlers = {
        [Packet.TYPE_OPEN] = handleOpenConnection,
        [Packet.TYPE_ACK_OPEN] = handleOpenAck,
        [Packet.TYPE_CLOSE] = handleCloseConnection,
        [Packet.TYPE_ACK_CLOSE] = handleCloseAck,
        [Packet.TYPE_DATA] = handleData,
        [Packet.TYPE_ACK_DATA] = handleDataAck,
        [Packet.TYPE_PING] = handlePing --don't care about pings, they're there to wake up the remotes only
    }

    ---@param message string
    local function receive(message)
        local packet = Packet.parse(message)
        local handler = messageHandlers[packet.type]
        if handler then
            handler(packet)
        else
            printNetworkError('Message received with unexpected format', packet)
        end
    end

    ---@param message string
    function self.send(message)
        for i = 1, message:len(), 400 do
            local lastChar = math.min(i + 399)
            local messagePart = message:sub(i, lastChar)

            queuePacketSend(Packet.TYPE_DATA, dataSendBuffer, messagePart)
        end
    end

    function self.ping(channel)
        local packet = Packet.new(Packet.TYPE_PING, listenChannel, channel)
        if not signalSendBuffer.push(packet) then
            fail('Network Error: Failed to send ping message due to send buffer overflow.')
        end
    end

    ---@param newRemoteChannel string
    function self.connect(newRemoteChannel)
        expectingOpenAck = true
        remoteChannel = newRemoteChannel
        queuePacketSend(Packet.TYPE_OPEN, signalSendBuffer)
        updateLastMessageTime()
    end

    function self.close()
        if not connectionOpen() then
            printNetworkError('Network Error: Attempted to close connection while no connection was open', nil)
        end

        closeRemoteConnection('OK')
    end

    ---@param state State
    function self.start(state)
        state.registerHandler(receiver, 'onReceived', DuLuacUtils.createHandler({
            [listenChannel] = receive
        }))
        state.registerHandler(system, SYSTEM_EVENTS.UPDATE, update)
    end

    return setmetatable(self, NetworkService)
end