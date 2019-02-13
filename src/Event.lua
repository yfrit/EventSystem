--[[
    Static class for registering listeners and firing events.

    TODO
        remove empty tables when listeners are removed
--]]
local Utils = require("Utils.Utils")

local Event = {
    listeners = {}
}

function Event.listen(event, method)
    assert(type(event)=="table", "Event must be inside a table.")
    assert(Utils.isCallable(method), "Listener must be callable.")

    --find listener table
    local lastListeners = Event.listeners
    for _, index in ipairs(event) do
        lastListeners.events = lastListeners.events or {}
        lastListeners.events[index] = lastListeners.events[index] or {}
        lastListeners = lastListeners.events[index]
    end

    --create method table
    lastListeners.methods = lastListeners.methods or {}

    --insert method in it
    table.insert(lastListeners.methods, method)
end

function Event.unlisten(event, method)
    assert(type(event)=="table", "Event must be inside a table.")
    assert(Utils.isCallable(method), "Listener must be callable.")

    --find listener table
    local lastListeners = Event.listeners
    for _, index in ipairs(event) do
        lastListeners = lastListeners.events and lastListeners.events[index]
        if not lastListeners then
            --event doesn't exist
            return
        end
    end

    --find method index
    local methodTable = lastListeners.methods
    if not methodTable then
        --event doesn't have a method table
        return
    end
    for i=#methodTable,1,-1 do
        if methodTable[i]==method then
            --remove method from it
            table.remove(methodTable, i)
        end
    end
end

function Event.broadcast(...)
    local event = {...}

    local lastListeners = Event.listeners

    --call empty event listeners
    local methodTable = lastListeners.methods
    if methodTable then
        for _, method in ipairs(methodTable) do
            method(...)
        end
    end

    --find listener table
    for _, index in ipairs(event) do
        --go to next level
        lastListeners = lastListeners.events and lastListeners.events[index]

        --stop if none
        if not lastListeners then
            break
        end

        --call all listeners on this level
        methodTable = lastListeners.methods
        if methodTable then
            for _, method in ipairs(methodTable) do
                method(...)
            end
        end
    end
end

return Event