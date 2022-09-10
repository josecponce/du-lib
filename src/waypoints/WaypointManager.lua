require('../requires/service')

---@class WaypointManager
WaypointManager = {}
WaypointManager.__index = WaypointManager

---@param system System
---@param db Databank exclusive db to use for waypoints
---@return WaypointManager
function WaypointManager.new(system, db)
    local self = --[[---@type self]] {}

    ---@return string[]
    function self.listWaypoints()
        return db.getKeyList()
    end

    ---@param name string
    ---@param waypoint string
    ---@overload fun(name: string)
    function self.recordWaypoint(name, waypoint)
        local finalWp = waypoint
        if not finalWp then
            finalWp = system.getWaypointFromPlayerPos()
        end

        db.setStringValue(name, finalWp)
        system.print('Waypoint recorded "' .. name .. '": ' .. finalWp)
    end

    ---@param oldName string
    ---@param newName string
    function self.renameWaypoint(oldName, newName)
        local finalWp = db.getStringValue(oldName)
        db.clearValue(oldName)
        db.setStringValue(newName, finalWp)

        system.print('Waypoint renamed from "' .. oldName .. ' to "' .. newName .. '"')
    end

    ---@param name string
    function self.removeWaypoint(name)
        db.clearValue(name)
        system.print('Waypoint removed: ' .. name)
    end

    ---@param name string
    function self.setWaypoint(name)
        local waypoint = db.getStringValue(name)
        if waypoint then
            system.setWaypoint(waypoint, true)
        end
    end

    return setmetatable(self, WaypointManager)
end