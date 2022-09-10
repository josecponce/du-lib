require('../requires/service')
require('../crafting/SchematicCopiesManager')
require('../crafting/RecipeManager')

---@class CraftingCostDirect
---@field itemId number
---@field quantity number
---@field time number
---@field schematics RecipeItem
---@field byproducts table<number, number>
---@field ingredients table<number, number>
CraftingCostDirect = {}
CraftingCostDirect.__index = CraftingCostDirect

---@param itemId number
---@param quantity number
---@param recipeManager RecipeManager
---@param schematicCopiesManager SchematicCopiesManager
---@return CraftingCostDirect
function CraftingCostDirect.calculate(itemId, quantity, recipeManager, schematicCopiesManager)
    local recipe = recipeManager.getAdjustedRecipe(itemId)
    local products = recipe.products
    local unitMultiplier = quantity / products[1].quantity

    local time = recipe.time * unitMultiplier

    local schematicCopy = schematicCopiesManager.getSchematicCopy(itemId)
    local schematics
    if schematicCopy then
        schematics = {
            id = schematicCopy.id,
            quantity = unitMultiplier
        }
    end

    ---@type table<number, number>
    local byproducts = {}
    for i, product in ipairs(products) do
        if i > 1 then
            byproducts[product.id] = product.quantity * unitMultiplier
        end
    end

    ---@type table<number, number>
    local ingredients = {}
    for _, ingredient in ipairs(recipe.ingredients) do
        ingredients[ingredient.id] = ingredient.quantity * unitMultiplier
    end

    return --[[---@type CraftingCostDirect]] {
        itemId = itemId,
        quantity = quantity,
        time = time,
        schematics = schematics,
        byproducts = byproducts,
        ingredients = ingredients
    }
end

---@class CraftingCostItem
---@field quantity number
---@field cost number
---@field industries number

---@param quantity number
---@param cost number
---@param industries number
---@return CraftingCostItem
local function craftingCostItem(quantity, cost, industries)
    return --[[---@type CraftingCostItem]] {
        quantity = quantity,
        cost = cost,
        industries = industries
    }
end

---@class CraftingCost
---@field __index CraftingCost
---@field itemId number
---@field quantity number
---@field totalCost number
---@field industries number
---@field directCost CraftingCost
---@field schematics table<number, CraftingCostItem> itemId to quantity
---@field byproducts table<number, CraftingCostItem> itemId to quantity
---@field ingredients table<number, CraftingCostItem> itemId to quantity
CraftingCost = {}
CraftingCost.__index = CraftingCost

---@param itemId number
---@param oresCostDb Databank
---@param recipeManager RecipeManager
---@param schematicCopiesManager SchematicCopiesManager
---@param system System
---@param quantity number
---@param permit CoroutinePermit
---@param timeframe number
---@param recursive boolean
---@return CraftingCost
---@overload fun(itemId: number, oresCostDb: Databank, recipeManager: RecipeManager, schematicCopiesManager: SchematicCopiesManager, system: System, permit: CoroutinePermit, quantity: number): CraftingCost
function CraftingCost.calculate(itemId, oresCostDb, recipeManager, schematicCopiesManager, system, permit, quantity, timeframe, recursive)
    local self = --[[---@type self]] {}

    if recursive == nil then
        recursive = true
    end

    self.itemId = itemId
    self.totalCost = 0
    self.directCost = nil
    self.schematics = {}
    self.byproducts = {}
    self.ingredients = {}

    if quantity then
        quantity = quantity
    else
        local unitCost = CraftingCostDirect.calculate(itemId, 1, recipeManager, schematicCopiesManager)
        quantity = 24 * 3600 / unitCost.time --quantity in 24h
    end
    permit.acquire()
    local directCost = CraftingCostDirect.calculate(itemId, quantity, recipeManager, schematicCopiesManager)
    self.quantity = quantity

    timeframe = timeframe or directCost.time
    self.industries = directCost.time / timeframe

    if recursive then
        permit.acquire()
        self.directCost = CraftingCost.calculate(itemId, oresCostDb, recipeManager, schematicCopiesManager, system, permit, quantity, timeframe, false)
    end

    ---@param itemId number
    ---@param newItem CraftingCostItem
    ---@param addToTable table<number, CraftingCostItem>
    local function addCostItem(itemId, newItem, addToTable)
        permit.acquire()
        local item = addToTable[itemId]
        if item then
            item.quantity = item.quantity + newItem.quantity
            item.cost = item.cost + newItem.cost
        else
            item = newItem
        end

        addToTable[itemId] = item
    end

    ---@param cost CraftingCost
    local function mergeCost(cost)
        for schematicId, schematic in pairs(cost.schematics) do
            addCostItem(schematicId, schematic, self.schematics)
        end

        for byproductId, byproduct in pairs(cost.byproducts) do
            addCostItem(byproductId, byproduct, self.byproducts)
        end

        for ingredientId, ingredient in pairs(cost.ingredients) do
            addCostItem(ingredientId, ingredient, self.ingredients)
        end
    end

    ---@param directCost CraftingCostDirect
    local function add(directCost)
        local totalCost = 0
        if directCost.schematics then
            local quantity = directCost.schematics.quantity
            local copy = schematicCopiesManager.getSchematicCopy(itemId)

            if not copy.cost or copy.cost == 0 then
                local msg = 'Failed to find cost for schematic in schematics cost db ' .. copy.displayName
                system.print(msg)
                error(msg)
            end

            local cost = quantity * copy.cost

            totalCost = totalCost + cost
            addCostItem(directCost.schematics.id, craftingCostItem(quantity, cost, nil), self.schematics)
        end

        for byproductId, byproductQuantity in pairs(directCost.byproducts) do
            local byproductCost = CraftingCost.calculate(byproductId, oresCostDb, recipeManager, schematicCopiesManager,
                    system, permit, byproductQuantity, timeframe, true)

            totalCost = totalCost - byproductCost.totalCost
            local costItem = craftingCostItem(byproductQuantity, byproductCost.totalCost, nil)
            addCostItem(byproductId, costItem, self.byproducts)
        end

        for ingredientId, ingredientQuantity in pairs(directCost.ingredients) do
            local cost, industries
            if RecipeManager.getRawRecipe(system, ingredientId) then
                local ingredientCost = CraftingCost.calculate(ingredientId, oresCostDb, recipeManager,
                        schematicCopiesManager, system, permit, ingredientQuantity, timeframe, true)
                if recursive then
                    mergeCost(ingredientCost)
                end

                cost = ingredientCost.totalCost
                industries = ingredientCost.industries
            else --ores
                local oreCost = oresCostDb.getFloatValue(tostring(ingredientId))
                if not oreCost or oreCost == 0 then
                    local msg = 'Failed to find cost for ore in oreDb ' .. system.getItem(ingredientId).displayName
                    system.print(msg)
                    error(msg)
                end
                cost = oreCost * ingredientQuantity
                industries = nil
            end
            totalCost = totalCost + cost
            local costItem = craftingCostItem(ingredientQuantity, cost, industries)
            addCostItem(ingredientId, costItem, self.ingredients)
        end

        self.totalCost = totalCost
    end

    add(directCost)

    return setmetatable(self, CraftingCost)
end

---@class CraftingCalculator : Service
CraftingCalculator = {}
CraftingCalculator.__index = CraftingCalculator

---@class CraftingCalculatorEvents
CRAFTING_CALCULATOR_EVENT = {}
CRAFTING_CALCULATOR_EVENT.INIT = 'onInit'

---@param system System
---@param recipeManager RecipeManager
---@param schematicCopiesManager SchematicCopiesManager
---@param oresCostDb Databank
---@return CraftingCalculator
function CraftingCalculator.new(system, recipeManager, schematicCopiesManager, oresCostDb)
    local self = --[[---@type self]] Service.new()

    local recipeManagerDone
    local schematicManagerDone

    local function recipeManagerRefresh()
        recipeManagerDone = true
        if schematicManagerDone then
            self:triggerEvent(CRAFTING_CALCULATOR_EVENT.INIT)
        end
    end

    local function schematicManagerRefresh()
        schematicManagerDone = true
        if recipeManagerDone then
            self:triggerEvent(CRAFTING_CALCULATOR_EVENT.INIT)
        end
    end

    ---this needs to be run as a coroutine
    ---@param itemId number
    ---@param mode "day" | "unit"
    ---@param permit CoroutinePermit
    ---@return CraftingCost
    function self.calculate(itemId, mode, permit)
        if not (schematicManagerDone and recipeManagerDone) then
            error("Crafting calculator can't be called until the 'onInit' event has been emitted.")
        end

        local quantity
        if mode == 'day' then
            quantity = nil
        elseif mode == 'unit' then
            quantity = 1
        else
            error('Invalid mode: ' .. mode)
        end
        return CraftingCost.calculate(itemId, oresCostDb, recipeManager, schematicCopiesManager, system, permit, quantity)
    end

    ---@param state State
    function self.start(state)
        state.registerHandler(recipeManager, RECIPE_MANAGER_EVENTS.REFRESH, recipeManagerRefresh)
        state.registerHandler(schematicCopiesManager, SCHEMATIC_COPIES_MANAGER_EVENT.REFRESH, schematicManagerRefresh)
    end

    return setmetatable(self, CraftingCalculator)
end