require('../../requires/service')
require('../messages/Packet')
require('../../datastructures/CircularBuffer')

---@class NetworkService : Service
NetworkService = {}
NetworkService.__index = NetworkService

---@param error string
---@param packet Packet
local function printTcpError(error, packet)
    system.print('Network Error: ' .. error .. ': "' .. Packet.serialize(packet) .. '"')
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
    ---@type table<number, Packet>
    local dataSendBuffer = {}
    local dataSendBufferReadIndex = 1
    local dataSendBufferWriteIndex = 1
    ---@type table<number, Packet>
    local signalSendBuffer = {}
    local signalSendBufferReadIndex = 1
    local signalSendBufferWriteIndex = 1
    --enough for 10s at 60fps
    local signalSendBufferSize = 600

    function self.connectionOpen()
        return remoteChannel and not expectingOpenAck
    end

    local connectionOpen = self.connectionOpen

    ---@param type "OPEN" | "ACK OPEN" | "CLOSE" | "ACK CLOSE" | "DATA" | "ACK DATA"
    ---@param buffer table<number, Packet>
    ---@param bufferWriteIndex number
    ---@param bufferSize number
    ---@param data string
    ---@overload fun(type: "OPEN" | "ACK OPEN" | "CLOSE" | "ACK CLOSE" | "DATA" | "ACK DATA", buffer: table<number, Packet>, bufferWriteIndex: number, bufferSize: number): number
    ---@return number new bufferWriteIndex
    local function queuePacketSend(type, buffer, bufferWriteIndex, bufferSize, data)
        local writeSlot = buffer[bufferWriteIndex]
        if writeSlot then
            fail('Network Error: Failed to send message due to send buffer overflow.')
        end
        buffer[bufferWriteIndex] = Packet.new(type, listenChannel, remoteChannel, data)
        return ((bufferWriteIndex + 1) % bufferSize) + 1
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

        dataSendBuffer = {}
        dataSendBufferReadIndex = 1
        dataSendBufferWriteIndex = 1
    end

    ---@param reason string
    local function closeRemoteConnection(reason)
        signalSendBufferWriteIndex = queuePacketSend(Packet.TYPE_CLOSE, signalSendBuffer, signalSendBufferWriteIndex, signalSendBufferSize, reason)
        resetConnectionState()
    end

    local function handleConnectionTimeout()
        closeRemoteConnection('Connection Timeout')
        self:triggerEvent(NETWORK_SERVICE_EVENTS.TIMEOUT)
    end

    ---@param buffer table<number, Packet>
    ---@param bufferReadIndex number
    ---@param bufferSize number
    ---@return number new bufferReadIndex
    local function handleSend(buffer, bufferReadIndex, bufferSize)
        local packet = buffer[bufferReadIndex]
        buffer[bufferReadIndex] = nil

        if packet.type == Packet.TYPE_DATA then
            expectingDataAck = true
        end
        emitter.send(packet.dest, Packet.serialize(packet))

        return ((bufferReadIndex + 1) % bufferSize) + 1
    end

    local function update()
        if signalSendBuffer[signalSendBufferReadIndex] then
            signalSendBufferReadIndex = handleSend(signalSendBuffer, signalSendBufferReadIndex, signalSendBufferSize)
            return
        end
        if not connectionOpen() then
            return
        end
        --Close connection if not alive
        if system.getArkTime() - lastMessageTime > timeout then
            handleConnectionTimeout()
        elseif not expectingDataAck and dataSendBuffer[dataSendBufferReadIndex] then
            dataSendBufferReadIndex = handleSend(dataSendBuffer, dataSendBufferReadIndex, dataSendBufferSize)
        end
    end

    ---@param packet Packet
    local function handleOpenConnection(packet)
        if connectionOpen() then
            printTcpError('Connection open attempt received while connection already open', packet)
        elseif not packet.source or packet.source:len() == 0 then
            printTcpError('Connection open request received without client channel provided', packet)
        else
            remoteChannel = packet.source
            updateLastMessageTime()
            signalSendBufferWriteIndex = queuePacketSend(Packet.TYPE_ACK_OPEN, signalSendBuffer, signalSendBufferWriteIndex, signalSendBufferSize)
            self:triggerEvent(NETWORK_SERVICE_EVENTS.OPEN, packet.source)
        end
    end

    ---@param packet Packet
    local function handleOpenAck(packet)
        if connectionOpen() then
            printTcpError('Connection Open Ack received while connection already open', packet)
        elseif not expectingOpenAck then
            printTcpError('Connection Open Ack received while no connection attempt was in progress', packet)
        elseif not fromCurrentSource(packet) then
            printTcpError('Connection Open Ack received from another source while connection attempt was in progress', packet)
        else
            updateLastMessageTime()
            expectingOpenAck = false
            self:triggerEvent(NETWORK_SERVICE_EVENTS.ACK_OPEN, packet.source)
        end
    end

    ---@param packet Packet
    local function handleCloseConnection(packet)
        if not connectionOpen() then
            printTcpError('Connection close attempt received while no connection is open', packet)
        elseif not fromCurrentSource(packet) then
            printTcpError('Connection close attempt received from another source while connection open', packet)
        else
            signalSendBufferWriteIndex = queuePacketSend(Packet.TYPE_ACK_CLOSE, signalSendBuffer, signalSendBufferWriteIndex, signalSendBufferSize)
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
            printTcpError('Data received while no connection is open', packet)
        elseif not fromCurrentSource(packet) then
            printTcpError('Data received from another while connection open', packet)
        else
            updateLastMessageTime()
            signalSendBufferWriteIndex = queuePacketSend(Packet.TYPE_ACK_DATA, signalSendBuffer, signalSendBufferWriteIndex, signalSendBufferSize)
            self:triggerEvent(NETWORK_SERVICE_EVENTS.DATA, packet.source, packet.data)
        end
    end

    local function handleDataAck(packet)
        if not connectionOpen() then
            printTcpError('Data Ack received while no connection is open', packet)
        elseif not fromCurrentSource(packet) then
            printTcpError('Data Ack received from another while connection open', packet)
        elseif not expectingDataAck then
            printTcpError('Data Ack received unexpectedly', packet)
        else
            updateLastMessageTime()
            expectingDataAck = false
            self:triggerEvent(NETWORK_SERVICE_EVENTS.ACK_DATA, packet.source)
        end
    end

    ---@type table<string, fun(packet: Packet): void>
    local messageHandlers = {
        [Packet.TYPE_OPEN] = handleOpenConnection,
        [Packet.TYPE_ACK_OPEN] = handleOpenAck,
        [Packet.TYPE_CLOSE] = handleCloseConnection,
        [Packet.TYPE_ACK_CLOSE] = handleCloseAck,
        [Packet.TYPE_DATA] = handleData,
        [Packet.TYPE_ACK_DATA] = handleDataAck
    }

    ---@param message string
    local function receive(message)
        local packet = Packet.parse(message)
        local handler = messageHandlers[packet.type]
        if handler then
            handler(packet)
        else
            printTcpError('Message received with unexpected format', packet)
        end
    end

    ---@param message string
    function self.send(message)
        for i = 1, message:len(), 400 do
            local lastChar = math.min(i + 399)
            local messagePart = message:sub(i, lastChar)

            dataSendBufferWriteIndex = queuePacketSend(Packet.TYPE_DATA, dataSendBuffer, dataSendBufferWriteIndex, dataSendBufferSize, messagePart)
        end
    end

    function self.connect(newRemoteChannel)
        expectingOpenAck = true
        remoteChannel = newRemoteChannel
        signalSendBufferWriteIndex = queuePacketSend(Packet.TYPE_OPEN, signalSendBuffer, signalSendBufferWriteIndex, signalSendBufferSize)
        updateLastMessageTime()
    end

    function self.close()
        if not connectionOpen() then
            fail('Network Error: Attempted to close connection while no connection was open')
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