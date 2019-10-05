--[[
    Wraps Event listening methods into a instantiable Class.
    This makes it easier to create children classes that already have communication methods implemented.
]]
local Utils = require("YfritLib.Utils")
local Class = require("YfritLib.Class")
local Event = require("EventSystem.Event")

local EventListener =
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

function EventListener:listenEvent(event, method)
    local function methodWithSelf(...)
        method(self, ...)
    end
    Event.listenEvent(event, methodWithSelf)
end

function EventListener:listenRequest(event, method)
    local function methodWithSelf(...)
        return method(self, ...)
    end
    Event.listenRequest(event, methodWithSelf)
end

function EventListener:listenManyEvents(listeners, prefix)
    prefix = prefix or {}
    local index = #prefix + 1
    for event, value in pairs(listeners) do
        prefix[index] = event
        if Utils.isCallable(value) then
            --callable, register listener
            self:listenEvent(prefix, value)
        elseif Utils.isCallable(self[value]) then
            --method name, register listener
            self:listenEvent(prefix, self[value])
        else
            --sub event table, continue recursively
            self:listenManyEvents(value, prefix)
        end
    end
    prefix[index] = nil
end

function EventListener:listenManyRequests(listeners, prefix)
    prefix = prefix or {}
    local index = #prefix + 1
    for event, value in pairs(listeners) do
        prefix[index] = event
        if Utils.isCallable(value) then
            --callable, register listener
            self:listenRequest(prefix, value)
        elseif Utils.isCallable(self[value]) then
            --method name, register listener
            self:listenRequest(prefix, self[value])
        else
            --sub event table, continue recursively
            self:listenManyRequests(value, prefix)
        end
    end
    prefix[index] = nil
end

return EventListener
