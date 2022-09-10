-- ################################################################################
-- #                  Copyright 2014-2022 Novaquark SAS                           #
-- ################################################################################

-----------------------------------------------------------------------------------
-- Force Field
--
-- A Force Field to create an uncrossable energy barrier.
-----------------------------------------------------------------------------------

require("element")

---@class ForceField
ForceField = {}
ForceField.__index = ForceField
function ForceField()
    ---@type self
    local self = Element.new()

    --- Deploys the forcefield
    function self.deploy() end
    ---@deprecated ForceField.activate() is deprecated, use ForceField.deploy() instead.
    function self.activate() error("ForceField.activate() is deprecated, use ForceField.deploy() instead.") end

    --- Retracts the forcefield
    function self.retract() end
    ---@deprecated ForceField.deactivate() is deprecated, use ForceField.retract() instead.
    function self.deactivate() error("ForceField.deactivate() is deprecated, use ForceField.retract() instead.") end

    --- Checks if the forcefield is deployed
    ---@return number
    function self.isDeployed() end
    ---@deprecated ForceField.getState() is deprecated, use ForceField.isDeployed() instead.
    function self.getState() error("ForceField.getState() is deprecated, use ForceField.isDeployed() instead.") end

    --- Toggle the forcefield
    function self.toggle() end

    return setmetatable(self, ForceField)
end