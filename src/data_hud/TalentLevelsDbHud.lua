---@class TalentLevelsDbHud : Service
TalentLevelsDbHud = {}
TalentLevelsDbHud.__index = TalentLevelsDbHud

---@param hud DatabankHud
---@param talentsRepo TalentsRepo
---@return TalentLevelsDbHud
function TalentLevelsDbHud.new(hud, talentsRepo)
    local self = --[[---@type self]] Service.new()

    local init
    ---@param talents table<string, Talent[]>
    local function talentsRefresh(_, talents)
        if init then
            return
        end

        ---@type table<string, DbEntry[]>
        local initKeys = {}
        for group, groupTalents in pairs(talents) do
            ---@type DbEntry[]
            local groupKeys = {}
            for _, talent in ipairs(groupTalents) do
                local entry = DbEntry.new(talent.name)
                table.insert(groupKeys, entry)
            end
            initKeys[group] = groupKeys
        end
        hud.setKeys(initKeys)
        init = true
    end

    ---@param state State
    function self.start(state)
        state.registerHandler(talentsRepo, TALENTS_REPO_EVENTS.REFRESH, talentsRefresh)
    end

    return setmetatable(self, TalentLevelsDbHud)
end