-- ################################################################################
-- #                  Copyright 2014-2022 Novaquark SAS                           #
-- ################################################################################

-----------------------------------------------------------------------------------
-- Emitter
--
-- This unit is capable of emitting messages on a channel
-----------------------------------------------------------------------------------

require("element")

--- This unit is capable of emitting messages on a channel
---@class Emitter : Element
Emitter = {}
Emitter.__index = Emitter

---@return Emitter
function Emitter.new()
    ---@type self
    local self = Element.new()

    --- Send a message on the given channel, limited to one transmission per frame and per channel
    ---@param channel string The channel name, limited to 64 characters. The message will not be sent if it exceeds this
    ---@param message string The message to be transmitted, truncated to 512 characters in case of overflow
    function self.send(channel,message) end

    --- Returns the emitter range
    ---@return number
    function self.getRange() end

    --- Emitted when the emitter successfully sent a message
    ---@param channel string The channel name
    ---@param message string The transmitted message
    self.onSent = Event:new()

    return setmetatable(self, Emitter)
end