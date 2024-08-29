--[[
    Wraps Event listening methods into a instantiable Class.
    This makes it easier to create children classes that already have communication methods implemented.
]]
local Utils = require("YfritLib.Utils")
local Class = require("YfritLib.Class")
local Table = require("YfritLib.Table")
local Event = require("EventSystem.Event")

local EventListener =
    Class.new(
    {},
    function(self)
        if not self.registeredListeners then
            self:_resetRegisteredListeners()

            if self.listeners then
                if self.listeners.events then
                    self:listenManyEvents(self.listeners.events)
                end
                if self.listeners.requests then
                    self:listenManyRequests(self.listeners.requests)
                end
            end
        end
    end
)

function EventListener:listenEvent(event, method)
    local function methodWithSelf(...)
        method(self, ...)
    end
    Event.listenEvent(event, methodWithSelf)

    table.insert(
        self.registeredListeners.events,
        {
            event = Table.shallowCopy(event),
            method = methodWithSelf
        }
    )
end

function EventListener:listenRequest(event, method)
    local function methodWithSelf(...)
        return method(self, ...)
    end
    Event.listenRequest(event, methodWithSelf)

    table.insert(
        self.registeredListeners.requests,
        {
            event = Table.shallowCopy(event),
            method = methodWithSelf
        }
    )
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
        elseif type(value) == "table" then
            --sub event table, continue recursively
            self:listenManyEvents(value, prefix)
        else
            error(string.format("'%s' is not an implemented method.", tostring(value)))
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
        elseif type(value) == "table" then
            --sub event table, continue recursively
            self:listenManyRequests(value, prefix)
        else
            error(string.format("'%s' is not an implemented method.", tostring(value)))
        end
    end
    prefix[index] = nil
end

function EventListener:destroy()
    for _, listener in ipairs(self.registeredListeners.events) do
        Event.unlistenEvent(listener.event, listener.method)
    end
    for _, listener in ipairs(self.registeredListeners.requests) do
        Event.unlistenRequest(listener.event, listener.method)
    end

    self:_resetRegisteredListeners()
end

function EventListener:_resetRegisteredListeners()
    self.registeredListeners = {
        events = {},
        requests = {}
    }
end

return EventListener
