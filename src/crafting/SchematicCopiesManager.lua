---@class SchematicCopy
---@field id number
---@field products number[]
---@field displayName string
---@field cost number
SchematicCopy = {}

---@param id number
---@param products number[]
---@param displayName string
---@return SchematicCopy
local function schematic(id, products, displayName, cost)
    return --[[---@type SchematicCopy]] {
        id = id,
        displayName = displayName,
        products = products,
        cost = cost,
    }
end

---@class SchematicCopiesManagerEvents
SCHEMATIC_COPIES_MANAGER_EVENT = {}
SCHEMATIC_COPIES_MANAGER_EVENT.REFRESH = 'onRefresh'

---@class SchematicCopiesManager : Service
---@field __index SchematicCopiesManager
SchematicCopiesManager = {}
SchematicCopiesManager.__index = SchematicCopiesManager

---@type number[]
SchematicCopiesManager.SCHEMATIC_COPY_IDS = { 86717297, 99491659, 109515712, 120427296, 210052275, 304578197, 318308564, 326757369, 363077945, 399761377, 425872842, 512435856, 616601802, 625377458, 632722426, 674258992, 690638651, 784932973, 787727253, 880043901, 1045229911, 1202149588, 1213081642, 1224468838, 1320378000, 1417495315, 1427639881, 1477134528, 1513927457, 1614573474, 1681671893, 1705420479, 1752968727, 1861676811, 1885016266, 1910482623, 1917988879, 1952035274, 1974208697, 2003602752, 2066101218, 2068774589, 2096799848, 2293088862, 2326433413, 2343247971, 2413250793, 2479827059, 2485530515, 2557110259, 2566982373, 2702634486, 2726927301, 2752973532, 2913149958, 3077761447, 3125069948, 3303272691, 3332597852, 3336558558, 3437488324, 3636126848, 3672319913, 3677281424, 3707339625, 3713463144, 3743434922, 3847207511, 3881438643, 3890840920, 3992802706, 4073976374, 4148773283, 4221430495 }

---@param system System
---@param schemCostDb Databank
---@return SchematicCopiesManager
function SchematicCopiesManager.new(system, schemCostDb)
    local self = --[[---@type self]] Service.new()

    ---@param schematicId number
    ---@return number
    local function getCost(schematicId)
        return schemCostDb.getFloatValue(tostring(schematicId))
    end

    ---@type table<number, SchematicCopy>
    local schematicCopies

    ---@param permit CoroutinePermit
    local function refresh(permit)
        ---@type table<number, SchematicCopy>
        local initSchematicCopies = {}

        for _, schematicId in ipairs(SchematicCopiesManager.SCHEMATIC_COPY_IDS) do
            permit.acquire()

            local item = system.getItem(schematicId)
            ---@type number[]
            local products = item.products
            if not products then
                error('Schematic without products found: ' .. schematicId)
            end

            local cost = getCost(schematicId)
            local schematic = schematic(schematicId, products, item.displayName, cost)
            initSchematicCopies[schematicId] = schematic
        end
        schematicCopies = initSchematicCopies

        self:triggerEvent(SCHEMATIC_COPIES_MANAGER_EVENT.REFRESH, schematicCopies)
    end

    ---@param itemId number
    ---@return SchematicCopy
    function self.getSchematicCopy(itemId)
        if schematicCopies then
            local item = system.getItem(itemId)
            local schematicId = item.schematics[1]
            return schematicCopies[schematicId]
        else
            return nil
        end
    end

    ---@param state State
    function self.start(state)
        state.registerCoroutine(self, 'SchematicCopiesManager_refresh', refresh, true)
    end

    return setmetatable(self, SchematicCopiesManager)
end