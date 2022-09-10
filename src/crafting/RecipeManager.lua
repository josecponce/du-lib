---@class ItemTalentsEffect
---@field timeDiscount number
---@field inputFixedDiscount number
---@field inputPercentDiscount number
---@field outputFixedPremium number
---@field outputPercentPremium number
ItemTalentsEffect = {}

---@return ItemTalentsEffect
function ItemTalentsEffect.new()
    local self = --[[---@type self]] {}

    self.timeDiscount = 0
    self.inputFixedDiscount = 0
    self.inputPercentDiscount = 0
    self.outputFixedPremium = 0
    self.outputPercentPremium = 0

    ---@param talent Talent
    function self.applyTalent(talent)
        local template = talent.template
        if template.type == TalentTemplate.TYPE_OUT then
            if template.isFixedAmount then
                self.outputFixedPremium = self.outputFixedPremium + template.amount * talent.level
            else
                self.outputPercentPremium = self.outputPercentPremium + template.amount * talent.level
            end
        elseif template.type == TalentTemplate.TYPE_IN then
            if template.isFixedAmount then
                self.inputFixedDiscount = self.inputFixedDiscount + template.amount * talent.level
            else
                self.inputPercentDiscount = self.inputPercentDiscount + template.amount * talent.level
            end
        elseif template.type == TalentTemplate.TYPE_TIME then
            self.timeDiscount = self.timeDiscount + template.amount * talent.level
        end
    end

    return setmetatable(self, ItemTalentsEffect)
end

---@param system System
---@param group string
---@param product number id
---@param tier number
---@param size string
---@return number[] ids
local function getAffectedItems(system, group, product, tier, size)
    local itemGroup = ItemGroup.findItemGroup(group)

    ---@type number[]
    local items = {}

    if product then
        items = { product }
    else
        items = ItemGroup.getItemsInGroup(system, itemGroup, tier, size)
    end

    return items
end

---@param system System
---@param talents Talent[]
---@param permit CoroutinePermit
---@return table<number, ItemTalentsEffect>
local function calculateTalents(system, talents, permit)
    ---@type table<number, ItemTalentsEffect>
    local calculatedTalents = {}

    for _, talent in ipairs(talents) do
        permit.acquire()
        local items = getAffectedItems(system, talent.template.group, talent.product, talent.tier, talent.size)

        for _, item in ipairs(items) do
            permit.acquire()
            calculatedTalents[item] = calculatedTalents[item] or ItemTalentsEffect.new()
            local itemTalentsEffect = calculatedTalents[item]
            itemTalentsEffect.applyTalent(talent)
        end
    end

    return calculatedTalents
end

---@class RecipeItem
---@field id number
---@field quantity number

---@class Recipe
---@field id number
---@field tier number
---@field time number
---@field nanocraftable boolean
---@field products RecipeItem[]
---@field ingredients RecipeItem[]

---@param system System
---@param talentsEffects table<number, ItemTalentsEffect>
---@param permit CoroutinePermit
---@return table<number, Recipe>
local function adjustRecipes(system, talentsEffects, permit)
    ---@type table<number, Recipe>
    local recipes = {}

    for itemId, talentsEffect in pairs(talentsEffects) do
        local recipe = RecipeManager.getRawRecipe(system, itemId)

        recipe.time = recipe.time * (1 - talentsEffect.timeDiscount)

        for _, output in ipairs(recipe.products) do
            permit.acquire()
            output.quantity = output.quantity * (1 + talentsEffect.outputPercentPremium) + talentsEffect.outputFixedPremium
        end

        for _, input in ipairs(recipe.ingredients) do
            permit.acquire()
            input.quantity = input.quantity * (1 - talentsEffect.inputPercentDiscount) + talentsEffect.inputFixedDiscount
        end

        recipes[itemId] = recipe
    end

    return recipes
end

---@class RecipeManager : Service
---@field __index RecipeManager
RecipeManager = {}
RecipeManager.__index = RecipeManager

---@param system System
---@param itemId number
---@return Recipe
function RecipeManager.getRawRecipe(system, itemId)
    local recipes = --[[---@type Recipe[] ]] system.getRecipes(itemId)

    for _, recipe in ipairs(recipes) do
        if recipe.products[1].id == itemId then
            return recipe
        end
    end

    return nil
end

---@class RecipeManagerEvents
RECIPE_MANAGER_EVENTS = {}
---handler: func(self)
RECIPE_MANAGER_EVENTS.REFRESH = 'onRefresh'

---@param system System
---@param talentsRepo TalentsRepo
---@return RecipeManager
function RecipeManager.new(system, talentsRepo)
    local self = --[[---@type self]] Service.new()

    ---@type Talent[]
    local talents
    local function updateTalents(_, newTalents)
        talents = newTalents
    end

    ---@type table<number, Recipe>
    local adjustedRecipes
    ---@type table<number, boolean>
    local knownItems

    ---@param permit CoroutinePermit
    local function refresh(permit)
        if not knownItems then
            ---@type table<number, boolean>
            local knownItemsInit = {}
            for _, group in pairs(ITEM_GROUPS) do
                local items = ItemGroup.getItemsInGroup(system, group, nil, nil)
                for _, item in ipairs(items) do
                    permit.acquire()
                    knownItemsInit[item] = true
                end
                permit.yield() --no overloads for me ty!
            end
            knownItems = knownItemsInit
        end
        while not talents do
            permit.yield()
        end

        local talentsEffects = calculateTalents(system, talents, permit)
        adjustedRecipes = adjustRecipes(system, talentsEffects, permit)

        self:triggerEvent(RECIPE_MANAGER_EVENTS.REFRESH)
    end

    ---@param itemId number
    ---@return Recipe
    function self.getAdjustedRecipe(itemId)
        if not adjustedRecipes then
            error("RecipeManager can't be called until refresh event is first emitted.")
        end

        if not knownItems[itemId] then
            error('Attempting to retrieve adjusted recipe for unknown item with id ' .. itemId)
        end

        local recipe = adjustedRecipes[itemId]
        if not recipe then
            recipe = RecipeManager.getRawRecipe(system, itemId)
            adjustedRecipes[itemId] = recipe
        end

        if not recipe then
            local msg = "Could not find recipe for itemId " .. itemId
            local item = system.getItem(itemId)
            if item and item.displayNameWithSize then
                msg = msg .. ' ' .. item.displayNameWithSize
            end
            error(msg)
        end

        return recipe
    end

    ---@param state State
    function self.start(state)
        state.registerHandler(talentsRepo, TALENTS_REPO_EVENTS.REFRESH, updateTalents)
        state.registerCoroutine(self, 'RecipeManager_refresh', refresh, true)
    end

    return setmetatable(self, RecipeManager)
end