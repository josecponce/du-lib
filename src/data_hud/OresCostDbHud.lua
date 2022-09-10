---@class OresCostDbHud : Service
OresCostDbHud = {}
OresCostDbHud.__index = OresCostDbHud

---@param hud DatabankHud
---@param system System
---@return OresCostDbHud
function OresCostDbHud.new(hud, system)
    local self = --[[---@type self]] Service.new()

    ---@param permit CoroutinePermit
    local function init(permit)
        permit.acquire()
        local oresGroup = ItemGroup.findItemGroup(I_GROUP_ORE)

        ---@type table<string, DbEntry[]>
        local entries = {}
        for group, oresGroup in pairs(oresGroup.groups) do
            permit.acquire()
            ---@type DbEntry[]
            local groupEntries = {}
            local groupItems = ItemGroup.getItemsInGroup(system, oresGroup, nil, nil)
            for _, itemId in ipairs(groupItems) do
                permit.acquire()
                local item = system.getItem(itemId)
                local entry = DbEntry.new(itemId, item.displayName)
                table.insert(groupEntries, entry)
            end
            entries[group] = groupEntries
        end

        hud.setKeys(entries)
    end

    ---@param state State
    function self.start(state)
        state.registerCoroutine(self, 'OresCostDbHud_init', init)
    end

    return setmetatable(self, OresCostDbHud)
end