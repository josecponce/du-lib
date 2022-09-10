---@class DuLuacUtils
DuLuacUtils = {}

---@param target DuLuacElement
---@param event string
---@param handlers table<string, function>
function DuLuacUtils.addListener(target, event, handlers)
    target:onEvent(event, DuLuacUtils.createHandler(handlers))
end

function DuLuacUtils.createHandler(handlers)
    return function(_, key)
        local handler = handlers[key]

        if handler then
            handler()
        end
    end
end