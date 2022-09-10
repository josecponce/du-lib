---@param s string
---@param delimiter string
---@return string[]
local function strSplit(s, delimiter)
    local result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

return strSplit