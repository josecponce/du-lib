require("element")

---@class ShieldGenerator : Element
ShieldGenerator = {}
ShieldGenerator.__index = ShieldGenerator

---@return ShieldGenerator
function ShieldGenerator.new()
    local self = --[[---@type self]] Element.new()

    ---@return number
    function self.getShieldHitpoints() end

    ---@return number
    function self.getMaxShieldHitpoints() end

    ---@return boolean
    function self.isVenting() end

    function self.startVenting() end

    function self.stopVenting() end

    ---@return number
    function self.getVentingCooldown() end

    ---@return boolean
    function self.isActive() end

    function self.activate() end

    ---@return number
    function self.getResistancesPool() end

    ---@return number[]
    function self.getResistances() end

    ---@return number
    function self.getResistancesCooldown() end

    ---@return number[]
    function self.getStressRatioRaw() end

    ---@param res1 number
    ---@param res2 number
    ---@param res3 number
    ---@param res4 number
    function self.setResistances(res1, res2, res3, res4) end

    return setmetatable(self, ShieldGenerator)
end