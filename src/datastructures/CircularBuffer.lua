---@class CircularBuffer<T : any>
CircularBuffer = {}
CircularBuffer.__index = CircularBuffer

---@param size number
---@return CircularBuffer<T>
function CircularBuffer.new(size)
    local self = --[[---@type self]] { }

    ---@type table<number, any>
    local buffer = {}
    local readIndex = 1
    local writeIndex = 1

    ---@param data T
    ---@return boolean false if push failed, otherwise tru
    function self.push(data)
        local writeSlot = buffer[writeIndex]
        if writeSlot then
            return false
        end
        buffer[writeIndex] = data
        writeIndex = ((writeIndex + 1) % size) + 1

        return true
    end

    ---@return boolean
    function self.spaceAvailable()
        return not buffer[writeIndex]
    end

    ---@return T
    function self.pop()
        local data = buffer[readIndex]
        buffer[readIndex] = nil

        readIndex = ((readIndex + 1) % size) + 1

        return data
    end

    ---@return boolean
    function self.dataAvailable()
        return not not buffer[readIndex]
    end

    return setmetatable(self, CircularBuffer)
end