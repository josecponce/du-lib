local serde = require('../requires/serde')

---@class Packet
---@field type string
---@field source string
---@field data string
Packet = {}
Packet.TYPE_OPEN = "OPEN"
Packet.TYPE_ACK_OPEN = "ACK OPEN"
Packet.TYPE_CLOSE = "CLOSE"
Packet.TYPE_ACK_CLOSE = "ACK CLOSE"
Packet.TYPE_DATA = "DATA"
Packet.TYPE_ACK_DATA = "ACK DATA"

---@param raw string
---@return Packet
function Packet.parse(raw)
    return --[[---@type Packet]] serde.deserialize(raw)
end

---@param packet Packet
---@return string
function Packet.serialize(packet)
    return serde.serialize(packet)
end

---@param type "OPEN" | "ACK OPEN" | "CLOSE" | "ACK CLOSE" | "DATA" | "ACK DATA"
---@param source string
---@param data string
---@overload fun(type: "OPEN" | "ACK OPEN" | "CLOSE" | "ACK CLOSE" | "DATA" | "ACK DATA", source: string): Packet
---@return Packet
function Packet.new(type, source, data)
    return --[[---@type]] {
        type = type,
        source = source,
        data = data
    }
end