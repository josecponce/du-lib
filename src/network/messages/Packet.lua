local json = require('dkjson')
local base64 = require('../../requires/base64')

---@class Packet
---@field type string
---@field source string
---@field dest string
---@field data string
Packet = {}
Packet.TYPE_PING = "PING"
Packet.TYPE_OPEN = "OPEN"
Packet.TYPE_ACK_OPEN = "ACK OPEN"
Packet.TYPE_CLOSE = "CLOSE"
Packet.TYPE_ACK_CLOSE = "ACK CLOSE"
Packet.TYPE_DATA = "DATA"
Packet.TYPE_ACK_DATA = "ACK DATA"

---@param raw string
---@return Packet
function Packet.parse(raw)
    local packet = --[[---@type Packet]] json.decode(raw)
    local data = packet.data
    if data ~= nil then
        data = base64.decode(data)
    end
    return --[[---@type Packet]] {
        type = packet.type,
        source = packet.source,
        dest = packet.dest,
        data = data
    }
end

---@param packet Packet
---@return string
---local data = packet.data
function Packet.serialize(packet)
    local data = packet.data
    if data ~= nil then
        data = base64.encode(data)
    end
    local encoded = {
        type = packet.type,
        source = packet.source,
        dest = packet.dest,
        data = data
    }
    return --[[---@type string]] json.encode(encoded)
end

---@param type "PING" | "OPEN" | "ACK OPEN" | "CLOSE" | "ACK CLOSE" | "DATA" | "ACK DATA"
---@param source string
---@param dest string
---@param data string
---@overload fun(type: "PING" | "OPEN" | "ACK OPEN" | "CLOSE" | "ACK CLOSE" | "DATA" | "ACK DATA", source: string, dest: string): Packet
---@return Packet
function Packet.new(type, source, dest, data)
    return --[[---@type Packet]] {
        type = type,
        source = source,
        dest = dest,
        data = data
    }
end