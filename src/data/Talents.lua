require('../requires/service')
require('../data/ItemGroups')

---@type table<string, TalentTemplate[]>
TALENT_TEMPLATES = require('../data/raw/TalentTemplatesRaw')

---@class Talent
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