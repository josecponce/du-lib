---@class MarkerManager : Service
MarkerManager = {}
MarkerManager.__index = MarkerManager

---@param core CoreUnit
---@param unit ControlUnit
---@return MarkerManager
function MarkerManager.new(core, unit)
    local self = --[[---@type self]] Service.new()

    ---key is element id, values are sticker ids for element if already spawned
    ---@type table<number, number[]>
    local elementMarkers = {}
    ---@type table<string, number>
    local elementMarkersNicknames = {}

    ---@param name string
    function self.removeElementMarker(name)
        local id = elementMarkersNicknames[name]
        local markers = elementMarkers[id]

        elementMarkersNicknames[name] = nil
        elementMarkers[id] = nil

        if markers then
            for _, marker in ipairs(markers) do
                core.deleteSticker(marker)
            end
        end
    end

    ---@param name string nickname
    ---@param id number
    function self.setElementMarker(name, id)
        local oldId = elementMarkersNicknames[name]

        if oldId then
            self.removeElementMarker(name)
        end

        ---@type number[]
        local markers = {}
        local position = vec3(core.getElementPositionById(id))
        local x = position.x
        local y = position.y
        local z = position.z
        local offset15 = 1.5

        table.insert(markers, core.spawnArrowSticker(x, y, z, "down"))
        table.insert(markers, core.spawnArrowSticker(x, y, z, "down"))
        core.rotateSticker(markers[2],0,0,90)
        table.insert(markers, core.spawnArrowSticker(x, y, z + offset15, "north"))
        table.insert(markers, core.spawnArrowSticker(x, y, z + offset15, "north"))
        core.rotateSticker(markers[4],90,90,0)
        table.insert(markers, core.spawnArrowSticker(x, y, z + offset15, "south"))
        table.insert(markers, core.spawnArrowSticker(x, y, z + offset15, "south"))
        core.rotateSticker(markers[6],90,-90,0)
        table.insert(markers, core.spawnArrowSticker(x, y, z + offset15, "east"))
        table.insert(markers, core.spawnArrowSticker(x, y, z + offset15, "east"))
        core.rotateSticker(markers[8],90,0,90)
        table.insert(markers, core.spawnArrowSticker(x, y, z + offset15, "west"))
        table.insert(markers, core.spawnArrowSticker(x, y, z + offset15, "west"))
        core.rotateSticker(markers[10],-90,0,90)

        elementMarkers[id] = markers
        elementMarkersNicknames[name] = id
    end

    local function refreshMarkers()
        local offset1 = 1
        local offset15 = 1.5
        local offset2 = 2
        local offset25 = 2.5
        local offsetFromCenter = 1.5

        for id, markers in pairs(elementMarkers) do
            local position = vec3(core.getElementPositionById(id))
            local x = position.x
            local y = position.y
            local z = position.z

            core.moveSticker(markers[1], x, y, z + offset25 + offsetFromCenter + 2)
            core.moveSticker(markers[2], x, y, z + offset25 + offsetFromCenter + 2)
            core.moveSticker(markers[3], x + offset1 + offsetFromCenter, y, z + offset15)
            core.moveSticker(markers[4], x + offset1 + offsetFromCenter, y, z + offset15)
            core.moveSticker(markers[5], x - offset1 - offsetFromCenter, y, z + offset15)
            core.moveSticker(markers[6], x - offset1 - offsetFromCenter, y, z + offset15)
            core.moveSticker(markers[7], x, y - offset2 - offsetFromCenter, z + offset15)
            core.moveSticker(markers[8], x, y - offset2 - offsetFromCenter, z + offset15)
            core.moveSticker(markers[9], x, y + offset2 + offsetFromCenter, z + offset15)
            core.moveSticker(markers[10], x, y + offset2 + offsetFromCenter, z + offset15)
        end
    end

    local function removeAllMarkers()
        for name, _ in pairs(elementMarkersNicknames) do
            self.removeElementMarker(name)
        end
    end

    ---@param state State
    function self.start(state)
        state.registerTimer('MarkerManager_refresh', 1, refreshMarkers)
        state.registerHandler(unit, UNIT_EVENTS.STOP, removeAllMarkers)
    end

    return setmetatable(self, MarkerManager)
end