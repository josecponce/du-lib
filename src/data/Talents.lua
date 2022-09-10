---@class TalentTemplate
---@field __index TalentTemplate
---@field name string
---@field group string
---@field type string
---@field amount number
---@field byTier number[]
---@field bySize string[]
---@field TYPE_OUT string
---@field TYPE_IN string
---@field TYPE_TIME string
TalentTemplate = {}
TalentTemplate.__index = TalentTemplate

TalentTemplate.TYPE_OUT = 'output'
TalentTemplate.TYPE_IN = 'input'
TalentTemplate.TYPE_TIME = 'time'

---@param isFixedAmount boolean
---@return TalentTemplate
local function talentTemplate(name, group, type, amount, byTier, bySize, byProduct, isFixedAmount)
    local self = --[[---@type TalentTemplate]] {}

    self.name = name
    self.group = group
    self.type = type
    self.amount = amount
    self.byTier = byTier
    self.bySize = bySize
    self.byProduct = byProduct or false
    self.isFixedAmount = isFixedAmount or false

    return setmetatable(self, TalentTemplate)
end

---@overload fun(name, group, type, amount) : TalentTemplate
---@return TalentTemplate
local function talentTemplateSingle(name, group, type, amount, isFixedAmount)
    return talentTemplate(name, group, type, amount, nil, nil, false, isFixedAmount)
end

---@overload fun(name, group, tiers, type, amount) : TalentTemplate
---@return TalentTemplate
local function talentTemplateByTier(name, group, type, tiers, amount, isFixedAmount)
    return talentTemplate(name, group, type, amount, tiers, nil, false, isFixedAmount)
end

---@overload fun(name, group, type, amount) : TalentTemplate
---@return TalentTemplate
local function talentTemplateByProduct(name, group, type, amount, isFixedAmount)
    return talentTemplate(name, group, type, amount, nil, nil, true, isFixedAmount)
end

---@overload fun(name, group, type, tiers, sizes, amount) : TalentTemplate
---@return TalentTemplate
local function talentTemplateByTierAndSize(name, group, type, tiers, sizes, amount, isFixedAmount)
    return talentTemplate(name, group, type, amount, tiers, sizes, false, isFixedAmount)
end

T_GROUP_FUEL_PROD = 'Fuel Productivity'
T_NAME_ATMO_FUEL_PROD = 'Atmospheric Fuel Productivity'
T_NAME_SPACE_FUEL_PROD = 'Space Fuel Productivity'
T_NAME_ROCKET_FUEL_PROD = 'Rocket Fuel Productivity'

T_GROUP_FUEL_REF = 'Fuel Refining'
T_NAME_FUEL_EFF = 'Fuel Efficiency'
T_NAME_FUEL_REF = 'Fuel Refinery'
T_NAME_ATMO_FUEL_REF = 'Atmospheric Fuel Refinery'
T_NAME_SPACE_FUEL_REF = 'Space Fuel Refinery'
T_NAME_ROCKET_FUEL_REF = 'Rocket Fuel Refinery'

T_GROUP_INT_PART_PROD = 'Intermediary Part Productivity'
T_NAME_INT_PART_PROD = 'Intermediary Part Productivity'

T_GROUP_AMMO_PROD = 'Ammo Productivity'
T_NAME_AMMO_EFF = 'Ammo Efficiency'
T_NAME_AMMO_PROD = 'Ammo Productivity'

T_GROUP_COMP_PART_MAN = 'Complex Parts Manufacturer'
T_NAME_COMP_PART_MAN = 'Complex Parts Manufacturer'

T_GROUP_EX_PART_MAN = 'Exceptional Parts Manufacturer'
T_NAME_EX_PART_MAN = 'Exceptional Parts Manufacturer'

T_GROUP_FUNC_PART_MAN = 'Functional Parts Manufacturer'
T_NAME_FUNC_PART_MAN = 'Functional Parts Manufacturer'

T_GROUP_STRUCT_PART_MAN = 'Structural Parts Manufacturer'
T_NAME_STRUCT_PART_MAN = 'Structural Parts Manufacturer'

T_GROUP_INT_PART_MAN = 'Intermediary Parts Manufacturer'
T_NAME_INT_PART_MAN = 'Intermediary Parts Manufacturer'

T_GROUP_ORE_REF = 'Ore Refining'
T_NAME_PURE_REF_EFF = 'Pure Refinery Efficiency'
T_NAME_ORE_REF = 'Ore Refining'

T_GROUP_PURE_PROD = 'Pure Productivity'
T_NAME_PURE_PROD = 'Pure Productivity'

T_GROUP_PROD_REF = 'Product Refining'
T_NAME_PROD_REF_EFF = 'Product Refinery Efficiency'
T_NAME_PROD_REF = 'Product Refining'

T_GROUP_PROD_PROD = 'Product Productivity'
T_NAME_PROD_PROD = 'Product Productivity'

T_GROUP_SCRAP_REF = 'Scrap Refining'
T_NAME_SCRAP_EFF = 'Scrap Efficiency'
T_NAME_TIER_SCRAP_REF = 'Tier Scrap Refinery'
T_NAME_SCRAP_REF = 'Scrap Refinery'

T_GROUP_SCRAP_PROD = 'Scrap Productivity'
T_NAME_SCRAP_PROD = 'Scrap Productivity'

---@type table<string, TalentTemplate[]>
local TALENT_TEMPLATES = --[[---@type table<string, TalentTemplate[]> ]] {
    --Crafting Talents
    [T_GROUP_FUEL_PROD] = {
        talentTemplateSingle(T_NAME_ATMO_FUEL_PROD, I_GROUP_ATMO_FUEL, TalentTemplate.TYPE_OUT, 0.05),
        talentTemplateSingle(T_NAME_SPACE_FUEL_PROD, I_GROUP_SPACE_FUEL, TalentTemplate.TYPE_OUT, 0.05),
        talentTemplateSingle(T_NAME_ROCKET_FUEL_PROD, I_GROUP_ROCKET_FUEL, TalentTemplate.TYPE_OUT, 0.05),
    },
    [T_GROUP_FUEL_REF] = {
        talentTemplateSingle(T_NAME_FUEL_EFF, I_GROUP_FUEL, TalentTemplate.TYPE_TIME, 0.1),
        talentTemplateSingle(T_NAME_FUEL_REF, I_GROUP_FUEL, TalentTemplate.TYPE_IN, 0.02),
        talentTemplateSingle(T_NAME_ATMO_FUEL_REF, I_GROUP_ATMO_FUEL, TalentTemplate.TYPE_IN, 0.03),
        talentTemplateSingle(T_NAME_SPACE_FUEL_REF, I_GROUP_SPACE_FUEL, TalentTemplate.TYPE_IN, 0.03),
        talentTemplateSingle(T_NAME_ROCKET_FUEL_REF, I_GROUP_ROCKET_FUEL, TalentTemplate.TYPE_IN, 0.03)
    },
    [T_GROUP_INT_PART_PROD] = {
        talentTemplateByTier(T_NAME_INT_PART_PROD, I_GROUP_INT_PART, TalentTemplate.TYPE_OUT, {1, 2, 3}, 1, true),
    },
    [T_GROUP_AMMO_PROD] = {
        talentTemplateByTier(T_NAME_AMMO_EFF, I_GROUP_AMMO, TalentTemplate.TYPE_TIME, {2, 3}, 0.1),
        talentTemplateByTierAndSize(T_NAME_AMMO_PROD, I_GROUP_AMMO, TalentTemplate.TYPE_OUT, {2,3}, {'XS', 'S', 'M', 'L'}, 1, true),
    },
    [T_GROUP_COMP_PART_MAN] = {
        talentTemplateByTier(T_NAME_COMP_PART_MAN, I_GROUP_COMPLEX_PART, TalentTemplate.TYPE_TIME, {1, 2, 3, 4, 5}, 0.1),
    },
    [T_GROUP_EX_PART_MAN] = {
        talentTemplateByTier(T_NAME_EX_PART_MAN, I_GROUP_EXCEPT_PART, TalentTemplate.TYPE_TIME, {3, 4, 5}, 0.1),
    },
    [T_GROUP_FUNC_PART_MAN] = {
        talentTemplateByTier(T_NAME_FUNC_PART_MAN, I_GROUP_FUNC_PART, TalentTemplate.TYPE_TIME, {1, 2, 3, 4, 5}, 0.1),
    },
    [T_GROUP_STRUCT_PART_MAN] = {
        talentTemplateByTier(T_NAME_STRUCT_PART_MAN, I_GROUP_STRUCT_PART, TalentTemplate.TYPE_TIME, {1, 2, 3, 4, 5}, 0.1),
    },
    [T_GROUP_INT_PART_MAN] = {
        talentTemplateByTier(T_NAME_INT_PART_MAN, I_GROUP_INT_PART, TalentTemplate.TYPE_TIME, {1, 2, 3}, 0.1),
    },
    [T_GROUP_ORE_REF] = {
        talentTemplateByTier(T_NAME_PURE_REF_EFF, I_GROUP_PURE, TalentTemplate.TYPE_TIME, {1, 2, 3, 4, 5}, 0.05),
        talentTemplateByProduct(T_NAME_ORE_REF, I_GROUP_PURE, TalentTemplate.TYPE_IN, 0.03),
    },
    [T_GROUP_PURE_PROD] = {
        talentTemplateByProduct(T_NAME_PURE_PROD, I_GROUP_PURE, TalentTemplate.TYPE_OUT, 0.03),
    },
    [T_GROUP_PROD_REF] = {
        talentTemplateByTier(T_NAME_PROD_REF_EFF, I_GROUP_PRODUCT, TalentTemplate.TYPE_TIME, {1, 2, 3, 4, 5}, 0.05),
        talentTemplateByProduct(T_NAME_PROD_REF, I_GROUP_PRODUCT, TalentTemplate.TYPE_IN, 0.03)
    },
    [T_GROUP_PROD_PROD] = {
        talentTemplateByProduct(T_NAME_PROD_PROD, I_GROUP_PRODUCT, TalentTemplate.TYPE_OUT, 0.03),
    },
    --ignoring honeycomb on purpose
    [T_GROUP_SCRAP_REF] = {
        talentTemplateByTier(T_NAME_SCRAP_EFF, I_GROUP_SCRAP, TalentTemplate.TYPE_TIME, {1, 2, 3, 4, 5}, 0.1),
        talentTemplateByTier(T_NAME_TIER_SCRAP_REF, I_GROUP_SCRAP, TalentTemplate.TYPE_IN, {1, 2, 3, 4, 5}, 1, true),
        talentTemplateByProduct(T_NAME_SCRAP_REF, I_GROUP_SCRAP, TalentTemplate.TYPE_IN, 2, true),
    },
    [T_GROUP_SCRAP_PROD] = {
        talentTemplateByProduct(T_NAME_SCRAP_PROD, I_GROUP_SCRAP, TalentTemplate.TYPE_OUT, 1, true),
    },
    --Industry Talents: Not in use since we have no way of retrieving the industries that produces each item
}

---@class Talent
---@field __index Talent
---@field name string
---@field level number
---@field template TalentTemplate
---@field product number id
---@field tier number
---@field size string
Talent = {}
Talent.__index = Talent

---@param name string
---@param level number
---@param template TalentTemplate
---@param product number id
---@param tier number
---@param size string
---@return Talent
local function talent(name, level, template, product, tier, size)
    local self = --[[---@type self]] {}

    self.name = name
    self.level = level
    self.template = template
    self.product = product
    self.tier = tier
    self.size = size

    return setmetatable(self, Talent)
end

---@type string[]
local TIER_NAMES = { 'Basic', 'Uncommon', 'Advanced', 'Rare', 'Exotic' }

---@class TalentsRepo : Service
TalentsRepo = {}
TalentsRepo.__index = TalentsRepo

---@class TalentsRepoEvents
TALENTS_REPO_EVENTS = {}
---handler: func(self, talents)
TALENTS_REPO_EVENTS.REFRESH = 'onRefresh'

---@param system System
---@param db Databank talent levels db
---@return TalentsRepo
function TalentsRepo.new(system, db)
    local self = --[[---@type self]] Service.new()

    ---@param permit CoroutinePermit
    ---@return table<string, Talent[]>
    local function loadTalents(permit)
        ---@type table<string, Talent[]>
        local talents = {}

        for templateGroup, templates in pairs(TALENT_TEMPLATES) do
            ---@type Talent[]
            local groupTalents = {}
            for _, template in ipairs(templates) do
                permit.acquire()
                local itemGroup = ItemGroup.findItemGroup(template.group)
                if template.byProduct then
                    local items = ItemGroup.getItemsInGroup(system, itemGroup, nil, nil)
                    for _, itemId in ipairs(items) do
                        permit.acquire()

                        local item = system.getItem(itemId)
                        local name = item.displayNameWithSize .. ' ' .. template.name
                        local talent = talent(name, 0, template, itemId, nil, nil)
                        table.insert(groupTalents, talent)
                    end
                elseif template.byTier then
                    for _, tier in ipairs(template.byTier) do
                        local tierName = TIER_NAMES[tier] .. ' ' .. template.name
                        if template.bySize then
                            for _, size in ipairs(template.bySize) do
                                permit.acquire()

                                local name = tierName .. ' ' .. size:upper()
                                local talent = talent(name, 0, template, nil, tier, size)
                                table.insert(groupTalents, talent)
                            end
                        else
                            permit.acquire()

                            local talent = talent(tierName, 0, template, nil, tier, nil)
                            table.insert(groupTalents, talent)
                        end
                    end
                else
                    local name = template.group .. ' ' .. template.name
                    local talent = talent(name, 0, template, nil, nil, nil)
                    table.insert(groupTalents, talent)
                end
            end
            talents[templateGroup] = groupTalents
        end

        return talents
    end

    ---@type table<string, Talent[]>
    local talents
    ---@param permit CoroutinePermit
    local function refresh(permit)
        if not talents then
            talents = loadTalents(permit)
        end

        for _, groupTalents in pairs(talents) do
            for _, talent in ipairs(groupTalents) do
                permit.acquire()
                local level = db.getIntValue(talent.name)
                if level and level >= 0 then
                    talent.level = level
                end
            end
        end

        self:triggerEvent(TALENTS_REPO_EVENTS.REFRESH, talents)
    end

    ---@param state State
    function self.start(state)
        state.registerCoroutine(self, 'TalentsRepo_refresh', refresh, true)
    end

    return setmetatable(self, TalentsRepo)
end