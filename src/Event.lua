--[[
    Static class for registering listeners and firing events.
--]]
local Utils = require("Utils.Utils")
local unpack = unpack

local Event = {
    listeners = {}
    --[[ e.g.
        listeners = {
            events = {
                ["CompositeEvent"] = {
                    events = {
                        ["SubEvent1"] = {
                            methods = {listener1, listener2}
                        },
                        ["SubEvent2"] = {
                            methods = {listener3}
                        }
                    },
                    methods = {listener4}
                }
            },
            methods = {listener5}
        }
    ]]
}

function Event.listenEvent(event, method)
    assert(type(event) == "table", "Event must be inside a table.")
    assert(Utils.isCallable(method), "Listener must be callable.")

    --find listener table
    local lastListeners = Event.listeners
    for _, index in ipairs(event) do
        --e.g. listeners["CompositeEvent"].events = {}
        lastListeners.events = lastListeners.events or {}

        --e.g. listeners["CompositeEvent"].events["SubEvent1"] = {}
        lastListeners.events[index] = lastListeners.events[index] or {}

        --e.g. lastListeners = listeners["CompositeEvent"].events["SubEvent1"]
        lastListeners = lastListeners.events[index]
    end

    --create method table
    --e.g. listeners["CompositeEvent"].events["SubEvent1"].methods = {}
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
        --e.g. lastListeners = listeners["CompositeEvent"].events["SubEvent1"]
        lastListeners = lastListeners.events and lastListeners.events[index]

        if not lastListeners then
            --event doesn't exist
            --i.e. the event, and its sub-events, don't have any listener registered
            return
        end
    end

    --find method index
    --e.g. methodTable = listeners["CompositeEvent"].events["SubEvent1"].methods
    local methodTable = lastListeners.methods

    if not methodTable then
        --event doesn't have a method table
        --i.e. the event doesn't have any listener registered
        return
    end
    for i = #methodTable, 1, -1 do
        if methodTable[i] == method then
            --remove method from it
            table.remove(methodTable, i)
        end
    end
end

function Event.broadcast(...)
    --calls all listener for the event and all its preffixes
    --e.g.if the event {"CompositeEvent", "SubEvent1"} is triggered
    --it should call all of its listeners, but also all of its preffixes
    --[[ so, it would call the listeners for:
        {"CompositeEvent", "SubEvent1"},
        {"CompositeEvent"}, and
        {}
    --]]
    local event = {...}

    local lastListeners = Event.listeners

    --this calls the listeners for the empty event ({})
    local methodTable = lastListeners.methods
    if methodTable then
        for _, method in ipairs(methodTable) do
            method(...)
        end
    end

    --and this calls the listeners for all other events
    --[[ e.g.
        iteration #1: {"CompositeEvent"}
        iteration #2: {"CompositeEvent", "SubEvent1"}
    ]]
    for _, index in ipairs(event) do
        --go to next level
        --e.g. lastListeners = listeners["CompositeEvent"].events["SubEvent1"]
        lastListeners = lastListeners.events and lastListeners.events[index]

        --stop if none
        if not lastListeners then
            break
        end

        --call all listeners on this level
        --e.g. methodTable = listeners["CompositeEvent"].events["SubEvent1"].methods
        methodTable = lastListeners.methods
        if methodTable then
            for _, method in ipairs(methodTable) do
                method(...)
            end
        end
    end
end

function Event.listenRequest(event, method)
    --add __request to the start of the event
    --e.g. {"CompositeRequest", "SubRequest1"} becomes {"__request", "CompositeRequest", "SubRequest1"}
    --(this is done so that normal, request and response events don't get mixed together)
    local requestEvent = {"__request", unpack(event)}

    --register listener for request
    Event.listenEvent(
        requestEvent,
        function(__request, ...)
            --wrap method to discard the first parameter, since we don't want to pass "__request" to the listener method
            method(...)
        end
    )
end

function Event.request(...)
    local currentCoroutine = coroutine.running()
    assert(currentCoroutine, "Event.request must be run inside a coroutine")

    --add __response to the start of the event
    local responseEvent = {"__response", ...}
    local response

    --create listener for the response event
    local function responselistener(...)
        --stop waiting for responses
        Event.unlistenEvent(responseEvent, responselistener)

        --get full response, which includes parameters we don't need
        --e.g. fullResponse = {"__response", "CompositeRequest", "SubRequest1", "SubResponse1", "SubResponse2"}
        local fullResponse = {...}

        --remove unneeded parameters and convert to table again
        --e.g. discard "__response", "CompositeRequest" and "SubRequest1", keeping only {"SubResponse1", "SubResponse2"}
        response = {unpack(fullResponse, #responseEvent + 1)}

        --resume coroutine if it is stopped
        --(it won't be stopped if someone responds before the yield, i.e. directly in response to the request broadcast)
        if coroutine.status(currentCoroutine) == "suspended" then
            coroutine.resume(currentCoroutine)
        end
    end
    Event.listenEvent(responseEvent, responselistener)

    --broadcast request to responders
    Event.broadcast("__request", ...)

    --if nobody responded yet (i.e. directly to the request broadcast), yield until someone responds
    if not response then
        coroutine.yield()
    end

    --unpack response before returning
    --e.g. return "SubResponse1", "SubResponse2" (instead of {"SubResponse1", "SubResponse2"})
    return unpack(response)
end

function Event.respond(...)
    Event.broadcast("__response", ...)
end

return Event
