require('../requires/service')
require('../general/DatabankHud')
require('../crafting/SchematicCopiesManager')

---@class SchematicsCostDbHud : Service
SchematicsCostDbHud = {}
SchematicsCostDbHud.__index = SchematicsCostDbHud

---@param hud DatabankHud
---@param system System
---@return SchematicsCostDbHud
function SchematicsCostDbHud.new(hud, system)
    local self = --[[---@type self]] Service.new()

    ---@param permit CoroutinePermit
    local function init(permit)
        ---@type DbEntry[]
        local groupEntries = {}
        ---@type table<string, DbEntry[]>
        local entries = { ['Schematic Copies'] = groupEntries }
        for _, itemId in ipairs(SchematicCopiesManager.SCHEMATIC_COPY_IDS) do
            permit.acquire()
            local item = system.getItem(itemId)
            local entry = DbEntry.new(itemId, item.displayName)
            table.insert(groupEntries, entry)
        end

        hud.setKeys(entries)
    end

    ---@param state State
    function self.start(state)
        state.registerCoroutine(self, 'SchematicsCostDbHud_init', init)
    end

    return setmetatable(self, SchematicsCostDbHud)
end