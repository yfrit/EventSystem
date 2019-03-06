--[[
    Static class for registering listeners and firing events.
--]]
local Utils = require("Utils.Utils")
local unpack = unpack

local Event = {
    listeners = {} --TODO add a comment showing a structure example
}

function Event.listenEvent(event, method)
    assert(type(event) == "table", "Event must be inside a table.")
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

function Event.unlistenEvent(event, method)
    assert(type(event) == "table", "Event must be inside a table.")
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
    for i = #methodTable, 1, -1 do
        if methodTable[i] == method then
            --remove method from it
            table.remove(methodTable, i)
        end
    end
end

function Event.broadcast(specialEvent, ...)
    local hideFirstEvent = specialEvent:sub(1, 2) == "__"

    local event = {specialEvent, ...}

    local lastListeners = Event.listeners

    --call empty event listeners
    local methodTable = lastListeners.methods
    if methodTable then
        for _, method in ipairs(methodTable) do
            if hideFirstEvent then
                method(...)
            else
                method(specialEvent, ...)
            end
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
                if hideFirstEvent then
                    method(...)
                else
                    method(specialEvent, ...)
                end
            end
        end
    end
end

function Event.listenRequest(event, method)
    local requestEvent = {"__request", unpack(event)}
    Event.listenEvent(requestEvent, method)
end

function Event.request(...)
    local currentCoroutine = coroutine.running()

    --listenEvent to response
    local responseEvent = {"__response", ...}
    local response
    local function responselistener(...)
        --stop waiting for responses
        Event.unlistenEvent(responseEvent, responselistener)

        --get full response, which includes events we don't need
        local fullResponse = {...}

        --remove unneeded parameters and convert to table again
        response = {unpack(fullResponse, #responseEvent)}

        --resume coroutine if it is stopped
        if coroutine.status(currentCoroutine) == "suspended" then
            coroutine.resume(currentCoroutine)
        end
    end
    Event.listenEvent(responseEvent, responselistener)

    --broadcast request to responders
    Event.broadcast("__request", ...)

    --yield until someone responds
    if not response then
        coroutine.yield()
    end

    return unpack(response)
end

function Event.respond(...)
    Event.broadcast("__response", ...)
end

return Event
