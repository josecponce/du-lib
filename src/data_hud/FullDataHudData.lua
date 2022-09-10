---@class FullDataHudData
---@field groups string[]
---@field headers string[]
---@field rows string[][]
---@field title string
FullDataHudData = {}
FullDataHudData.__index = FullDataHudData

---@param groups string[] | nil
---@param headers string[]
---@param rows string[][]
---@param title string
---@overload fun(title: string, headers: string[], rows: string[][]) : FullDataHudData
---@return FullDataHudData
function FullDataHudData.new(title, headers, rows, groups)
    local self = --[[---@type self]] { }

    self.groups = --[[---@type string[] ]] groups
    self.headers = headers
    self.rows = rows
    self.title = title

    return setmetatable(self, FullDataHudData)
end