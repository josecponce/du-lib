---@class DbEntry
---@field key string
---@field label string
DbEntry = {}

---@param key string | number
---@param label string | nil
---@return DbEntry
---@overload fun(key: string | number): DbEntry
function DbEntry.new(key, label)
    return --[[---@type DbEntry]] {
        key = tostring(key),
        label = label or key
    }
end

---@class DatabankHud : Service
---@field __index DatabankHud
DatabankHud = {}
DatabankHud.__index = DatabankHud

---@param system System
---@param db Databank
---@param valueType string 'string', 'float', 'int'
---@param hud FullDataHud
---@param title string
---@param keys table<string, DbEntry[]> | table<string, DbEntry[]>
---@overload fun(system: System, db: Databank, valueType: string, hud: FullDataHud, title: string) : DatabankHud
---@return DatabankHud
function DatabankHud.new(system, db, valueType, hud, title, keys)
    local self = --[[---@type self]] Service.new()

    local initDone
    ---@type table<string, DbEntry[]>
    local groups
    ---@type string[]
    local groupNames
    ---@param permit CoroutinePermit
    local function initDb(permit)
        while not keys do
            permit.yield()
        end

        groups = {}
        groupNames = {}
        ---@type table<string, boolean>
        local knownKeys = {}
        for group, keys in pairs(keys) do
            table.insert(groupNames, group)
            ---@type DbEntry[]
            local groupKeys = {}
            for _, entry in ipairs(keys) do
                permit.acquire()
                local key = entry.key
                if knownKeys[key] then
                    error('Found duplicate key: ' .. key)
                end
                knownKeys[key] = true
                table.insert(groupKeys, entry)
                if db.hasKey(key) == 0 then
                    db.setStringValue(key, '')
                end
            end
            table.sort(groupKeys, function(l, r) return l.label < r.label end)
            groups[group] = groupKeys
        end
        table.sort(groupNames)
        initDone = true
    end

    local recordMode
    local selectedGroupIndex = 1
    local selectedIndex = 1
    local function selectEntry(_, newSelectedIndex)
        recordMode = false
        selectedIndex = newSelectedIndex
    end

    local function selectGroup(_, newSelectedGroupIndex)
        recordMode = false
        selectedGroupIndex = newSelectedGroupIndex
    end

    local function setRecordMode(_, newSelectedGroupIndex, newSelectedIndex)
        recordMode = true
        selectedGroupIndex = newSelectedGroupIndex
        selectedIndex = newSelectedIndex
        system.print('Please enter a ' .. valueType)
    end

    local function recordValue(_, text)
        local setMethod, value
        local result = true
        if valueType == 'string' then
            setMethod = db.setStringValue
            value = text
        elseif valueType == 'float' then
            setMethod = db.setFloatValue
            result, value = pcall(tonumber, text)
        elseif valueType == 'int' then
            setMethod = db.setIntValue
            result, value = pcall(tonumber, text)
        end

        if result then
            local groupName = groupNames[selectedGroupIndex]
            local group = groups[groupName]
            setMethod(group[selectedIndex].key, value)
            recordMode = false
            system.print('Databank value recorded')
        else
            system.print('Please enter a valid value')
        end
    end

    local headers = { 'Label', 'Data' }
    ---@param permit CoroutinePermit
    local function refresh(permit)
        if not initDone then
            permit.yield()
        end

        ---@type string[][]
        local rows = {}

        local groupName = groupNames[selectedGroupIndex]
        local group = groups[groupName]
        for _, entry in ipairs(group) do
            permit.acquire()
            local value = db.getStringValue(entry.key)
            local row = { entry.label, value }
            table.insert(rows, row)
        end

        local data = FullDataHudData.new(title, headers, rows, groupNames)
        hud.updateData(data)
    end

    ---@param newKeys table<string, DbEntry[]> | table<string, DbEntry[]>
    function self.setKeys(newKeys)
        keys = newKeys
    end

    ---@param state State
    function self.start(state)
        state.registerCoroutine(self, 'DatabankHud_init', initDb)
        state.registerCoroutine(self, 'DatabankHud_refresh', refresh, true)

        state.registerHandler(hud, FULL_DATA_HUD_EVENTS.DETAIL_ACTION_LEFT, setRecordMode)
        state.registerHandler(hud, FULL_DATA_HUD_EVENTS.DETAIL_SELECTED, selectEntry)
        state.registerHandler(hud, FULL_DATA_HUD_EVENTS.GROUP_SELECTED, selectGroup)

        state.registerHandler(system, SYSTEM_EVENTS.INPUT_TEXT, recordValue)
    end

    return setmetatable(self, DatabankHud)
end
