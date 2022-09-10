-- ################################################################################
-- #                  Copyright 2014-2022 Novaquark SAS                           #
-- ################################################################################

-----------------------------------------------------------------------------------
-- Library
--
-- Contains a list of useful math and helper methods that would be slow to implement in Lua, and which are
-- given here as fast C++ implementation.
-----------------------------------------------------------------------------------


--- Contains a list of useful math and helper methods that would be slow to implement in Lua, and which are
--- given here as fast C++ implementation.
---@class Library : DuLuacElement
Library = {}
Library.__index = Library

---@return Library
function Library.new()
    local self = --[[---@type self]] {}

    ---du-luac util method to add event handlers to custom objects
    ---@param object any custom object to add event handlers to
    function self.addEventHandlers(object) end

    ---Returns the connection to the Core Unit, if it's connected
    ---@return CoreUnit
    function self.getCoreUnit() end

    ---Gets a list of linked elements, optionally filtering based on the element's function stated in filter
    ---(you can supply nil to ignore filtering).
    ---example: local screens = library.getLinks({ getClass: 'ScreenUnit' })
    ---@overload fun(): table<any, any>
    ---@param filter table
    ---@param noLinkNames boolean When noLinkNames is true, you get indexes instead of link names as the keys
    ---@return table<any, any>
    function self.getLinks(filter, noLinkNames) end

    ---Gets a list of linked elements matching the selected class.
    ---example: local screens = library.getLinksByClass('ScreenUnit')
    ---@param elementClass string
    ---@param noLinkNames boolean When noLinkNames is true, you get indexes instead of link names as the keys
    ---@return table<any, any>
    function self.getLinksByClass(elementClass, noLinkNames) end

    ---Same as the previous function, but returns the first matching element
    ---example: local screen = library.getLinkByClass('ScreenUnit')
    ---@param elementClass string
    ---@return any
    function self.getLinkByClass(elementClass) end
    ---Gets an element's link based on the element name (not the link name!)
    ---@param elementName string
    ---@return any
    function self.getLinkByName(elementName) end


    --- Solve the 3D linear system M*x=c0 where M is defined by its column vectors c1,c2,c3
    ---@param c1 table The first column of the matrix M
    ---@param c2 table The second column of the matrix M
    ---@param c3 table The third column of the matrix M
    ---@param c0 table The target column vector of the system
    ---@return table value The vec3 solution of the above system
    function self.systemResolution3(c1,c2,c3,c0) end

    --- Solve the 2D linear system M*x=c0 where M is defined by its column vectors c1,c2
    ---@param c1 table The first column of the matrix M
    ---@param c2 table The second column of the matrix M
    ---@param c0 table The target column vector of the system
    ---@return table value The vec2 solution of the above system
    function self.systemResolution2(c1,c2,c0) end

    --- Returns the position of the given point in world coordinates system, on the game screen
    ---@param worldPos table: The world position of the point
    ---@return table value The position in percentage (between 0 and 1) of the screen resolution as vec3 with {x, y, depth}
    function self.getPointOnScreen(worldPos) end


    return setmetatable(self, Library)
end

--- Global alias available out of the game
DULibrary = Library
