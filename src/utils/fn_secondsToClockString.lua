---@param seconds number
---@return string
local function secondsToClockString(seconds)
    local seconds = tonumber(seconds)

    if seconds == nil or seconds <= 0 then
        return "-";
    else
        local days = string.format("%2.f", math.floor(seconds/(3600*24)));
        local hours = string.format("%2.f", math.floor(seconds/3600 - (days*24)));
        local mins = string.format("%2.f", math.floor(seconds/60 - (hours*60) - (days*24*60)));
        local secs = string.format("%2.f", math.floor(seconds - hours*3600  - (days*24*60*60) - mins *60));
        local str = ""
        if tonumber(days) > 0 then str = str .. days.."d " end
        if tonumber(hours) > 0 then str = str .. hours.."h " end
        if tonumber(mins) > 0 then str = str .. mins.."m " end
        if tonumber(secs) > 0 then str = str .. secs .."s" end
        return str
    end
end

return secondsToClockString