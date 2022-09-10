---@type table<string, ItemGroup>
ITEM_GROUPS = require('../data/raw/ItemGroupsRaw')

I_GROUP_FUEL = 'Fuels'
I_GROUP_ATMO_FUEL = 'Atmospheric Fuels'
I_GROUP_SPACE_FUEL = 'Space Fuels'
I_GROUP_ROCKET_FUEL = 'Rocket Fuels'

I_GROUP_INT_PART = 'Intermediary Parts'
I_GROUP_FUNC_PART = 'Functional Parts'
I_GROUP_STRUCT_PART = 'Structural Parts'
I_GROUP_COMPLEX_PART = 'Complex Parts'
I_GROUP_EXCEPT_PART = 'Exceptional Parts'

---@type string
I_GROUP_ORE = 'Ore'
I_GROUP_PURE = 'Pure'
I_GROUP_PRODUCT = 'Product'

I_GROUP_CONSUMABLES = 'Consumables'
I_GROUP_AMMO = 'Ammunition'
I_GROUP_SCRAP = 'Scraps'
I_GROUP_WARP_CELL = 'Warp Cell'

---@class ItemGroup
---@field groups table<string, ItemGroup>
---@field items number[]
ItemGroup = {}

---@param group string
---@param scope table<string, ItemGroup>
---@return ItemGroup
local function findItemGroup(group, scope)
    for name, groupDef in pairs(scope) do
        if name:lower() == group:lower() then
            return groupDef
        end

        if groupDef.groups then
            local child = findItemGroup(group, groupDef.groups)
            if child then
                return child
            end
        end
    end

    return nil
end

---@type table<string, ItemGroup>
local foundItemGroups = {}
---@param group string
---@return ItemGroup
function ItemGroup.findItemGroup(group)
    local foundItemGroup = foundItemGroups[group]
    if foundItemGroup then
        return foundItemGroup
    end

    local itemGroup = findItemGroup(group, ITEM_GROUPS)
    if not itemGroup then
        error("Could not find item group: " .. group)
    end

    foundItemGroups[group] = itemGroup

    return itemGroup
end

---@type table<ItemGroup, number[]>
local cachedItemsInGroups = {}
---@param itemGroup ItemGroup
---@return number[]
local function getAllItemsInGroup(itemGroup)
    ---@type number[]
    local items = { }

    local cached = cachedItemsInGroups[itemGroup]
    if cached then
        return cached
    end

    if itemGroup.groups then
        for _, group in pairs(itemGroup.groups) do
            local groupItems = getAllItemsInGroup(group)
            table.move(groupItems, 1, #groupItems, #items + 1, items)
        end
    end

    if itemGroup.items then
        for _, item in ipairs(itemGroup.items) do
            table.insert(items, item)
        end
    end
    cachedItemsInGroups[itemGroup] = items

    return items
end

---@param itemGroup ItemGroup
---@return number[]
function ItemGroup.getItemsInGroup(system, itemGroup, tier, size)
    local allItems = getAllItemsInGroup(itemGroup)
    if not (tier or size) then
        return allItems
    end

    local items = {}
    for _, item in ipairs(allItems) do
        local itemId = --[[---@type number]] item
        local itemDef = system.getItem(itemId)
        if (not tier or tier == itemDef.tier) and (not size or size:lower() == itemDef.size:lower()) then
            table.insert(items, itemId)
        end
    end

    return items
end