--[[
    Wraps Event methods in a instantiable Class.
    This makes it easier to create children classes that already have communication methods implemented.
]]
local Utils = require("Utils.Utils")
local Class = require("Class.Class")
local Event = require("Event")

local Eventer = Class.new({
    --static things

},
function(self)
    
end)

function Eventer:broadcast(...)
    Event.broadcast(...)
end

function Eventer:listen(event, method)
    local function methodWithSelf(...)
        method(self, ...)
    end
    Event.listen(event, methodWithSelf)
end

function Eventer:listenMany(listeners, prefix)
    prefix = prefix or {}
    local index = #prefix + 1
    for event, value in pairs(listeners) do
        prefix[index] = event
        if Utils.isCallable(value) then
            --callable, register listener
            self:listen(prefix, value)
        else
            --sub event table, continue recursively
            self:listenMany(value, prefix)
        end
    end
    prefix[index] = nil
end

return Eventer