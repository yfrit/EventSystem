--[[
    Wraps Event methods in a instantiable Class.
    This makes it easier to create children classes that already have communication methods implemented.
]]
local Utils = require("Utils.Utils")
local Class = require("Utils.Class")
local Event = require("Event", ...)

local Eventer =
    Class.new(
    {},
    function(self)
        if self.listeners then
            if self.listeners.events then
                self:listenManyEvents(self.listeners.events)
            end
            if self.listeners.requests then
                self:listenManyRequests(self.listeners.requests)
            end
        end
    end
)

function Eventer:broadcast(...)
    Event.broadcast(...)
end

function Eventer:listenEvent(event, method)
    local function methodWithSelf(...)
        method(self, ...)
    end
    Event.listenEvent(event, methodWithSelf)
end

function Eventer:listenRequest(event, method)
    local function methodWithSelf(...)
        method(self, ...)
    end
    Event.listenRequest(event, methodWithSelf)
end

function Eventer:listenManyEvents(listeners, prefix)
    prefix = prefix or {}
    local index = #prefix + 1
    for event, value in pairs(listeners) do
        prefix[index] = event
        if Utils.isCallable(value) then
            --callable, register listener
            self:listenEvent(prefix, value)
        else
            --sub event table, continue recursively
            self:listenManyEvents(value, prefix)
        end
    end
    prefix[index] = nil
end

function Eventer:listenManyRequests(listeners, prefix)
    prefix = prefix or {}
    local index = #prefix + 1
    for event, value in pairs(listeners) do
        prefix[index] = event
        if Utils.isCallable(value) then
            --callable, register listener
            self:listenRequest(prefix, value)
        else
            --sub event table, continue recursively
            self:listenManyRequests(value, prefix)
        end
    end
    prefix[index] = nil
end

return Eventer
