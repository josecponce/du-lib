require('../requires/service')
require('../data_hud/FullDataHudData')
local duCurrentDateTime = require('../utils/fn_duCurrentDateTime')

---@class FullDataHudEvents
FULL_DATA_HUD_EVENTS = {}
---handler: func(self, groupIndex)
FULL_DATA_HUD_EVENTS.GROUP_SELECTED = 'onGroupSelected'
---handler: func(self, detailIndex)
FULL_DATA_HUD_EVENTS.DETAIL_SELECTED = 'onDetailSelected'
---handler: func(self, groupIndex, detailIndex)
FULL_DATA_HUD_EVENTS.DETAIL_ACTION_RIGHT = 'onDetailActionRight'
---handler: func(self, groupIndex, detailIndex)
FULL_DATA_HUD_EVENTS.DETAIL_ACTION_LEFT = 'onDetailActionLeft'
---handler: func(self, groupIndex, detailIndex)
FULL_DATA_HUD_EVENTS.DETAIL_ACTION_DOWN = 'onDetailActionDown'
---handler: func(self, groupIndex, detailIndex)
FULL_DATA_HUD_EVENTS.DETAIL_ACTION_UP = 'onDetailActionUp'
---handler: func(self, groupIndex)
FULL_DATA_HUD_EVENTS.GROUP_ACTION_RIGHT = 'onGroupActionRight'
---handler: func(self, groupIndex)
FULL_DATA_HUD_EVENTS.GROUP_ACTION_LEFT = 'onGroupActionLeft'

---@class FullDataHud : Service
FullDataHud = {}
FullDataHud.__index = FullDataHud

local function getHudHelpHtml(title)
    local year, month, day, hour, minute, second, _, _, _, _, _, _ = duCurrentDateTime(nil)
    local dateStr = string.format("%02d/%02d/%04d %02d:%02d:%02d", day, month, year, hour, minute, second)
    return table.concat({[[<div class="hud_help_commands hud_container">
    <table>
        <tr><th>]], title, [[</th></tr>
        <tr>
            <th colspan="2">
                ]], dateStr, [[
            </th>
        </tr>
        <tr>
            <td>Show/Hide HUD</td>
            <th style="text-align:right;">Alt+2</th>
        </tr>
    </table>
</div>]]})
end

local function getHudMainCss(contentFontSize, hideGroups)
    local detailsContainerOffset = 20
    if hideGroups then
        detailsContainerOffset = 1
    end
    return table.concat({[[
    <style>
	   * {
		  font-size: ]], tostring(contentFontSize), [[px;
	   }
        .hud_container {
            border: 2px solid orange;
            border-radius:10px;
            background-color: rgba(0,0,0,.75);
            padding:10px;
        }
        .hud_help_commands {
            position: absolute;
            top: 1vh;
            left: 1vw;
            text-transform: uppercase;
            font-weight: bold;
        }
        .hud_list_container {
            position: absolute;
            top: 17vh;
            left: 1vw;
            text-transform: uppercase;
            font-weight: bold;
        }
        .hud_machines_container {
            position: absolute;
            top: 17vh;
            left: ]], tostring(detailsContainerOffset), [[vw;
        }
        .elementType {
            margin-top:10px;
            border-radius:5px;
        }
        .elementType.selected {
            border: 2px solid green;
            background-color: rgba(0,200,0,.45);
        }
        tr.selected td, tr.selected th{
            border: 2px solid green;
            background-color: rgba(0,200,0,.1);
        }
        td, th {
            border-bottom:1px solid white;
            padding:5px;
            text-align: center;
        }
        th {
            font-weight: bold;
        }
        .text-success{color: #28a745;}
        .text-danger{color:#dc3545;}
        .text-warning{color:#ffc107;}
        .text-info{color:#17a2b8;}
        .text-primary{color:#007bff;}
        .text-orangered{color:orangered;}
        .bg-success{background-color: #28a745;}
        .bg-danger{background-color:#dc3545;}
        .bg-warning{background-color:#ffc107;}
        .bg-info{background-color:#17a2b8;}
        .bg-primary{background-color:#007bff;}
    </style>
]]})
end

local function getHudLoadingHtml()
    return [[
            <div class="hud_list_container hud_container">
            	<table style="width:100%">
            		<tr>
            			<th>LOADING...</th>
            		</tr>
            	</table>
            </div>
        ]]
end

---@return number
local function minOnPage(page, pageSize)
    return ((page - 1) * pageSize) + 1
end

local function maxOnPage(page, pageSize, lastItem)
    return math.min(page * pageSize, lastItem)
end

---@param groups string[]
local function renderGroupsHtml(groups, selectedGroupIndex, groupsByPage)
    ---@type string[]
    local groupsHtml = { [[<div class="hud_list_container hud_container">
                <div style="text-align:center;font-weight:bold;border-bottom:1px solid white;">&#x2191; &nbsp;&nbsp; Ctrl+Arrow Up</div>
            ]]}

    local page = math.floor((selectedGroupIndex - 1) / groupsByPage) + 1
    local minOnPage = minOnPage(page, groupsByPage)
    local maxOnPage = maxOnPage(page, groupsByPage, #groups)

    for i = minOnPage, maxOnPage do
        local group = groups[i]
        table.insert(groupsHtml, '<div class="elementType')
        if i == selectedGroupIndex then
            table.insert(groupsHtml, " selected")
        end

        table.insert(groupsHtml, [[">
                    <table style="width:100%;">
                        <tr>
                            <th style="text-align:left;border-bottom:none;">]])
        table.insert(groupsHtml, group)
        table.insert(groupsHtml, [[</th>
                        </tr>
                    </table>
                </div>
                ]])
    end

    table.insert(groupsHtml, [[<div style="margin-top:10px;text-align:center;font-weight:bold;border-top:1px solid white;">&#x2193; &nbsp;&nbsp; Ctrl+Arrow Down</div></div>]])

    return table.concat(groupsHtml)
end

---@param system System
---@param contentFontSize number
---@param elementsByPage number
---@param groupsByPage number
---@overload fun(system: System, contentFontSize: number, elementsByPage: number) : FullDataHud
---@return FullDataHud
function FullDataHud.new(system, contentFontSize, elementsByPage, groupsByPage)
    local self = --[[---@type self]] Service.new()

    local hudMainCss = getHudMainCss(contentFontSize, not groupsByPage)
    local hudMinimalHtml = hudMainCss .. getHudHelpHtml('Hud Loading')
    local hudLoadingHtml = hudMinimalHtml .. getHudLoadingHtml()

    ---@type FullDataHudData
    local data

    local hudDisplayed = true
    local selectedGroupIndex = 1
    local selectedDetailIndex = 1
    local page = 1
    local maxPage = 1

    local controlPressed = false
    local altPressed = false

    ---@param newData FullDataHudData
    function self.updateData(newData)
        data = newData
        if data.rows then
            maxPage = math.ceil(#data.rows / elementsByPage)
        end
    end

    function self.setSelected(groupIndex, detailIndex)
        selectedGroupIndex = groupIndex
        selectedDetailIndex = detailIndex

        page = math.floor((selectedDetailIndex - 1) / elementsByPage) + 1

        self:triggerEvent(FULL_DATA_HUD_EVENTS.GROUP_SELECTED, selectedGroupIndex)
        self:triggerEvent(FULL_DATA_HUD_EVENTS.DETAIL_SELECTED, selectedDetailIndex)
    end

    local hudHtml = ''
    local function updateHud()
        local data = data

        if data and data.title then
            hudMinimalHtml = hudMainCss .. getHudHelpHtml(data.title)
        end

        if not hudDisplayed then
            hudHtml = hudMinimalHtml
            return
        elseif not data then
            hudHtml = hudLoadingHtml
            return
        end

        local groupsHtml = ''
        if groupsByPage and data.groups then
            groupsHtml = renderGroupsHtml(data.groups, selectedGroupIndex, groupsByPage)
        end

        if not data.rows then
            if data.groups then
                hudHtml = hudMinimalHtml .. groupsHtml
            else
                hudHtml = hudLoadingHtml .. groupsHtml
            end
            return
        end

        local minOnPage = minOnPage(page, elementsByPage)
        local maxOnPage = maxOnPage(page, elementsByPage, #data.rows)

        ---@type (string | number)[]
        local detailsHtml = {[[<div class="hud_machines_container hud_container">
                <div style="text-align:center;font-weight:bold;border-bottom:1px solid white;">&#x2191; &nbsp;&nbsp; Arrow Up</div>
                <table class="elements_table" style="width:100%">
                    <tr>
                        <th>&#x2190; &nbsp;&nbsp; Arrow Left</th>
                        <th> Page ]], page, [[/]], maxPage, [[ (from ]], minOnPage, [[ to ]], maxOnPage, [[)</th>
                        <th>Arrow Right &nbsp;&nbsp; &#x2192;</th>
                    </tr>
                </table>
                <table class="elements_table" style="width:100%;">
                    <tr>]]}

        for _, header in ipairs(data.headers) do
            table.insert(detailsHtml, '<th>')
            table.insert(detailsHtml, header)
            table.insert(detailsHtml, '</th>')
        end
        table.insert(detailsHtml, '</tr>')

        for i = minOnPage, maxOnPage do
            local row = data.rows[i]

            table.insert(detailsHtml, [[<tr]])
            if selectedDetailIndex == i then
                table.insert(detailsHtml, [[ class="selected"]])
            end
            table.insert(detailsHtml, '>')

            for _, value in ipairs(row) do
                table.insert(detailsHtml, [[<th>]])
                table.insert(detailsHtml, value)
                table.insert(detailsHtml, '</th>')
            end
            table.insert(detailsHtml, '</tr>')
        end

        table.insert(detailsHtml, [[</table>
            <table class="elements_table" style="width:100%">
                <tr>
                    <th>&#x2190; &nbsp;&nbsp; Arrow Left</th>
                    <th> Page ]])
        table.insert(detailsHtml, page)
        table.insert(detailsHtml, '/')
        table.insert(detailsHtml, maxPage)
        table.insert(detailsHtml, ' (from ')
        table.insert(detailsHtml, minOnPage)
        table.insert(detailsHtml, ' to ')
        table.insert(detailsHtml, maxOnPage)
        table.insert(detailsHtml, [[)</th>
                    <th>Arrow Right &nbsp;&nbsp; &#x2192;</th>
                </tr>
            </table>
            <div style="text-align:center;font-weight:bold;border-top:1px solid white;">&#x2193; &nbsp;&nbsp; Arrow Down</div>
            </div>]])

        hudHtml = hudMinimalHtml .. groupsHtml .. table.concat(detailsHtml)
    end

    local function onStartBrake()
        controlPressed = true
    end

    local function onStopBrake()
        controlPressed = false
    end

    local function onStartAlt()
        altPressed = true
    end

    local function onStopAlt()
        altPressed = false
    end

    local function onStartDown()
        if not hudDisplayed then
            return
        end
        local data = data
        if data.groups and controlPressed == true then
            if selectedGroupIndex < #data.groups then
                selectedGroupIndex = selectedGroupIndex + 1
                selectedDetailIndex = 1
                page = 1

                self:triggerEvent(FULL_DATA_HUD_EVENTS.GROUP_SELECTED, selectedGroupIndex)
                self:triggerEvent(FULL_DATA_HUD_EVENTS.DETAIL_SELECTED, selectedDetailIndex)
            end
        elseif data.rows then
            if altPressed then
                self:triggerEvent(FULL_DATA_HUD_EVENTS.DETAIL_ACTION_DOWN, selectedGroupIndex, selectedDetailIndex)
            elseif selectedDetailIndex < maxOnPage(page, elementsByPage, #data.rows) then
                selectedDetailIndex = selectedDetailIndex + 1
                self:triggerEvent(FULL_DATA_HUD_EVENTS.DETAIL_SELECTED, selectedDetailIndex)
            elseif page < maxPage then
                page = page + 1
                selectedDetailIndex = minOnPage(page, elementsByPage)
                self:triggerEvent(FULL_DATA_HUD_EVENTS.DETAIL_SELECTED, selectedDetailIndex)
            end
        end
    end

    local function onStartUp()
        if not hudDisplayed then
            return
        end
        local data = data
        if data.groups and controlPressed then
            if selectedGroupIndex > 1 then
                selectedGroupIndex = selectedGroupIndex - 1
                selectedDetailIndex = 1
                page = 1

                self:triggerEvent(FULL_DATA_HUD_EVENTS.GROUP_SELECTED, selectedGroupIndex)
                self:triggerEvent(FULL_DATA_HUD_EVENTS.DETAIL_SELECTED, selectedDetailIndex)
            end
        elseif data.rows then
            if altPressed then
                self:triggerEvent(FULL_DATA_HUD_EVENTS.DETAIL_ACTION_UP, selectedGroupIndex, selectedDetailIndex)
            elseif selectedDetailIndex > minOnPage(page, elementsByPage) then
                selectedDetailIndex = selectedDetailIndex - 1
                self:triggerEvent(FULL_DATA_HUD_EVENTS.DETAIL_SELECTED, selectedDetailIndex)
            elseif page > 1 then
                page = page - 1
                selectedDetailIndex = maxOnPage(page, elementsByPage, #data.rows)
                self:triggerEvent(FULL_DATA_HUD_EVENTS.DETAIL_SELECTED, selectedDetailIndex)
            end
        end
    end

    local function onStartStrafeLeft()
        if not hudDisplayed then
            return
        end
        if altPressed then
            self:triggerEvent(FULL_DATA_HUD_EVENTS.DETAIL_ACTION_LEFT, selectedGroupIndex, selectedDetailIndex)
        elseif controlPressed then
            self:triggerEvent(FULL_DATA_HUD_EVENTS.GROUP_ACTION_LEFT, selectedGroupIndex)
        elseif page > 1 then
            page = page - 1
            selectedDetailIndex = minOnPage(page, elementsByPage)
            self:triggerEvent(FULL_DATA_HUD_EVENTS.DETAIL_SELECTED, selectedDetailIndex)
        end
    end

    local function onStartStrafeRight()
        if not hudDisplayed then
            return
        end
        if altPressed then
            self:triggerEvent(FULL_DATA_HUD_EVENTS.DETAIL_ACTION_RIGHT, selectedGroupIndex, selectedDetailIndex)
        elseif controlPressed then
            self:triggerEvent(FULL_DATA_HUD_EVENTS.GROUP_ACTION_RIGHT, selectedGroupIndex)
        elseif page < maxPage then
            page = page + 1
            selectedDetailIndex = minOnPage(page, elementsByPage)
            self:triggerEvent(FULL_DATA_HUD_EVENTS.DETAIL_SELECTED, selectedDetailIndex)
        end
    end

    local function onStartOption2()
        hudDisplayed = not hudDisplayed
    end

    self.hasHud = true
    ---@return string
    function self.drawHud()
        return hudHtml
    end

    ---@param state State
    function self.start(state)
        state.registerTimer('FullDataHud_updateUi', 0.1, updateHud)
        state.registerHandler(system, SYSTEM_EVENTS.ACTION_STOP, DuLuacUtils.createHandler({
            [LUA_ACTIONS.BRAKE] = onStopBrake,
            [LUA_ACTIONS.LALT] = onStopAlt,
        }))
        state.registerHandler(system, SYSTEM_EVENTS.ACTION_START, DuLuacUtils.createHandler({
            [LUA_ACTIONS.BRAKE] = onStartBrake,
            [LUA_ACTIONS.LALT] = onStartAlt,
            [LUA_ACTIONS.DOWN] = onStartDown,
            [LUA_ACTIONS.UP] = onStartUp,
            [LUA_ACTIONS.OPTION2] = onStartOption2,
            [LUA_ACTIONS.STRAFELEFT] = onStartStrafeLeft,
            [LUA_ACTIONS.STRAFERIGHT] = onStartStrafeRight,
        }))

        self:triggerEvent(FULL_DATA_HUD_EVENTS.GROUP_SELECTED, selectedGroupIndex)
        self:triggerEvent(FULL_DATA_HUD_EVENTS.DETAIL_SELECTED, selectedDetailIndex)
    end

    return setmetatable(self, FullDataHud)
end