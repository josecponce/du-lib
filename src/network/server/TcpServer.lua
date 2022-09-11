require('../requires/service')
require('../network/messages/Packet')

---@class TcpServer : Service
TcpServer = {}
TcpServer.__index = TcpServer

---@param error string
---@param packet Packet
local function printTcpError(error, packet)
    system.print('Tcp Error: ' .. error .. ': "' .. Packet.serialize(packet) .. '"')
end

---@class TcpServerEvents
TCP_SERVER_EVENTS = {}
---handler: func(self, source)
TCP_SERVER_EVENTS.OPEN = 'onOpen'
---handler: func(self, source)
TCP_SERVER_EVENTS.CLOSE = 'onClose'
---handler: func(self, source, data)
TCP_SERVER_EVENTS.DATA = 'onData'
---handler: func(self, source)
TCP_SERVER_EVENTS.ACK_DATA = 'onAckData'

---@param emitter Emitter
---@param receiver Receiver
---@param listenChannel string
---@param timeout number
---@param sendBufferSize number
---@return TcpServer
function TcpServer.new(emitter, receiver, listenChannel, timeout, sendBufferSize)
    local self = --[[---@type self]] Service.new()

    local clientChannel
    local lastMessageTime
    local expectingDataAck
    ---@type table<number, string>
    local sendBuffer = {}
    local sendBufferReadIndex = 1
    local sendBufferWriteIndex = 1

    local function updateLastMessageTime()
        lastMessageTime = system.getArkTime()
    end

    ---@param packet Packet
    local function fromCurrentSource(packet)
        return packet.source and clientChannel == packet.source
    end

    local function handleConnectionTimeout()
        clientChannel = nil
        lastMessageTime = nil
        local close = Packet.new(Packet.TYPE_CLOSE, listenChannel, 'Connection Timeout')
        emitter.send(clientChannel, Packet.serialize(close))
    end

    local function handleSendData()
        local sendMessage = sendBuffer[sendBufferReadIndex]
        if not sendMessage then
            return
        end
        sendBuffer[sendBufferReadIndex] = nil
        sendBufferReadIndex = ((sendBufferReadIndex + 1) % sendBufferSize) + 1

        local data = Packet.new(Packet.TYPE_DATA, listenChannel, sendMessage)
        emitter.send(clientChannel, Packet.serialize(data))
        expectingDataAck = true
    end

    local function update()
        if not clientChannel then
            return
        end
        --Close connection if not alive
        if system.getArkTime() - lastMessageTime > timeout then
            handleConnectionTimeout()
        --Send new package if available
        elseif not expectingDataAck then
            handleSendData()
        end
    end

    ---@param packet Packet
    local function handleOpenConnection(packet)
        if clientChannel then
            printTcpError('Connection open attempt received while connection already open', packet)
        elseif not packet.source or packet.source:len() == 0 then
            printTcpError('Connection open request received without client channel provided', packet)
        else
            clientChannel = packet.source
            updateLastMessageTime()
            local ack = Packet.new(Packet.TYPE_ACK_OPEN, listenChannel)
            emitter.send(clientChannel, Packet.serialize(ack))
            self:triggerEvent(TCP_SERVER_EVENTS.OPEN, packet.source)
        end
    end

    ---@param packet Packet
    local function handleCloseConnection(packet)
        if not clientChannel then
            printTcpError('Connection close attempt received while no connection is open', packet)
        elseif not fromCurrentSource(packet) then
            printTcpError('Connection close attempt received from another source while connection open', packet)
        else
            local ack = Packet.new(Packet.TYPE_ACK_CLOSE, listenChannel)
            emitter.send(clientChannel, Packet.serialize(ack))
            clientChannel = nil
            lastMessageTime = nil
            self:triggerEvent(TCP_SERVER_EVENTS.CLOSE, packet.source)
        end
    end

    ---@param packet Packet
    local function handleData(packet)
        if not clientChannel then
            printTcpError('Data received while no connection is open', packet)
        elseif not fromCurrentSource(packet) then
            printTcpError('Data received from another while connection open', packet)
        else
            updateLastMessageTime()
            local ack = Packet.new(Packet.TYPE_ACK_DATA, listenChannel)
            emitter.send(clientChannel, Packet.serialize(ack))
            self:triggerEvent(TCP_SERVER_EVENTS.DATA, packet.source, packet.data)
        end
    end

    local function handleDataAck(packet)
        if not clientChannel then
            printTcpError('Data Ack received while no connection is open', packet)
        elseif not fromCurrentSource(packet) then
            printTcpError('Data Ack received from another while connection open', packet)
        elseif not expectingDataAck then
            printTcpError('Data Ack received unexpectedly', packet)
        else
            updateLastMessageTime()
            expectingDataAck = false
            self:triggerEvent(TCP_SERVER_EVENTS.ACK_DATA, packet.source)
        end
    end

    ---@type table<string, fun(packet: Packet): void>
    local messageHandlers = {
        [Packet.TYPE_OPEN] = handleOpenConnection,
        [Packet.TYPE_CLOSE] = handleCloseConnection,
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
        local writeSlot = sendBuffer[sendBufferWriteIndex]
        if writeSlot then
            local errorMessage = 'Tcp Error: Failed to send message due to send buffer overflow.'
            system.print(errorMessage)
            error(errorMessage)
        end

        sendBuffer[sendBufferWriteIndex] = message
        sendBufferWriteIndex = ((sendBufferWriteIndex + 1) % sendBufferSize) + 1
    end

    ---@param state State
    function self.start(state)
        state.registerHandler(receiver, 'onReceived', DuLuacUtils.createHandler({
            [listenChannel] = receive
        }))
        state.registerHandler(system, SYSTEM_EVENTS.UPDATE, update)
    end

    return setmetatable(self, TcpServer)
end