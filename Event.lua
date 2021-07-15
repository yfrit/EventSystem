--[[
    Static class for registering listeners and firing events.
--]]
local Utils = require("YfritLib.Utils")
local Promise = require("YfritLib.Promise")
local Table = require("YfritLib.Table")
local unpack = unpack

local Event = {
    listeners = {},
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
    responderWrappers = {},
    pendingRequests = {},
    interceptors = {}
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
    local eventParameters = {...}
    for _, index in ipairs(event) do
        --go to next level
        --e.g. lastListeners = listeners["CompositeEvent"].events["SubEvent1"]
        lastListeners = lastListeners.events and lastListeners.events[index]

        --stop if none
        if not lastListeners then
            break
        end

        --remove parent event from parameters
        --we don't want a listener for "CompositeEvent" receiving ("CompositeEvent", "SubEvent1")
        --we only want it to receive "SubEvent1"
        table.remove(eventParameters, 1)

        --call all listeners on this level
        --e.g. methodTable = listeners["CompositeEvent"].events["SubEvent1"].methods
        methodTable = lastListeners.methods
        if methodTable then
            for _, method in ipairs(methodTable) do
                method(unpack(eventParameters))
            end
        end
    end
end

function Event.listenRequest(event, method)
    assert(type(event) == "table", "Event must be inside a table.")
    assert(Utils.isCallable(method), "Listener must be callable.")

    event = Utils.shallowCopy(event)

    --add __request to the start of the event
    --e.g. {"CompositeRequest", "SubRequest1"} becomes {"__request", "CompositeRequest", "SubRequest1"}
    --(this is done so that normal, request and response events don't get mixed together)
    local requestEvent = {"__request", unpack(event)}

    --check if method already has a wrapper (if not, create one)
    local methodWrapper = Event.responderWrappers[method]
    if not methodWrapper then
        methodWrapper = function(...)
            local results = {method(...)}

            --if method returned something, respond event automatically with the returns
            if #results > 0 then
                --suppose we have a responder for event ("CompositeEvent", "SubEvent")
                --that returns ("return1", "return2")
                --and we request ("CompositeEvent", "SubEvent", "parameter1", "parameter2")
                local response = {}

                --this adds sub-events to response (e.g. "CompositeEvent", "SubEvent")
                for _, subEvent in ipairs(event) do
                    response[#response + 1] = subEvent
                end

                --this adds request parameters to response (e.g. "parameter1", "parameter2")
                for _, requestParameter in ipairs({...}) do
                    response[#response + 1] = requestParameter
                end

                --this adds results to response (e.g. "return1", "return2")
                for _, result in ipairs(results) do
                    response[#response + 1] = result
                end

                --e.g Event.legacyRespond("CompositeEvent", "SubEvent", "parameter1", "parameter2", "return1", "return2")
                Event.legacyRespond(unpack(response))
            end
        end
        Event.responderWrappers[method] = methodWrapper
    end

    --register listener for request
    Event.listenEvent(requestEvent, methodWrapper)
end

function Event.unlistenRequest(event, method)
    local requestEvent = {"__request", unpack(event)}
    local methodWrapper = Event.responderWrappers[method]

    Event.unlistenEvent(requestEvent, methodWrapper)
end

function Event.request(...)
    local currentCoroutine = coroutine.running()
    assert(currentCoroutine, "Event.request must be run inside a coroutine")

    local event = {...}

    --add __response to the start of the event
    local responseEvent = {"__response", ...}

    --create a promise that will be completed when the response event occurs
    local responsePromise = Promise:new()

    --create listener for the response event
    local function responseListener(...)
        --stop waiting for responses
        Event.unlistenEvent(responseEvent, responseListener)

        --remove from pending requests
        local _, index =
            Table.find(
            Event.pendingRequests,
            function(pendingRequest)
                return Table.areSame(pendingRequest.event, event)
            end
        )
        if index then
            table.remove(Event.pendingRequests, index)
        else
            print("WARNING: pending request not found.", unpack(event))
        end

        -- check if any interceptor wants to change the response
        local response = {...}
        for _, interceptorCallback in ipairs(Event.interceptors) do
            local shouldIntercept, newResponse = interceptorCallback(event, response)
            if shouldIntercept then
                response = newResponse
                break
            end
        end

        --complete promise with response
        responsePromise:complete(unpack(response))
    end
    Event.listenEvent(responseEvent, responseListener)

    --store request to respond later
    table.insert(
        Event.pendingRequests,
        {
            event = event,
            responseListener = responseListener
        }
    )

    --broadcast request to responders
    Event.broadcast("__request", ...)

    --return response (the same '...' that were passed to responsePromise:complete())
    return responsePromise:await()
end

function Event.respond(...)
    local event = {...}

    -- find pending request
    local request =
        Table.find(
        Event.pendingRequests,
        function(pendingRequest)
            return Table.isSubTableOf(event, pendingRequest.event)
        end
    )
    if not request then
        print("WARNING: attempt to respond inexistent request.", debug.traceback())
    end

    local respondRequest = {}
    function respondRequest.with(...)
        if request then
            request.responseListener(...)
        end
    end

    return respondRequest
end

function Event.legacyRespond(...)
    Event.broadcast("__response", ...)
end

function Event.await(...)
    local waitingPromise = Promise:new()
    local event = {...}

    -- start listening for event
    local function listener()
        -- when event occurs, clear listener and complete promise
        Event.unlistenEvent(event, listener)
        waitingPromise:complete()
    end
    Event.listenEvent(event, listener)

    -- wait until promise is completed
    waitingPromise:await()
end

function Event.awaitMany(...)
    local events = {...}
    local eventsLeft = #events
    local waitingPromise = Promise:new()

    for _, event in ipairs(events) do
        -- start listening for event
        local function listener()
            -- when event occurs, clear listener and decrement counter
            Event.unlistenEvent(event, listener)
            eventsLeft = eventsLeft - 1

            -- if counter reached zero, all events occurred
            if eventsLeft == 0 then
                waitingPromise:complete()
            end
        end
        Event.listenEvent(event, listener)
    end

    -- wait until promise is completed
    waitingPromise:await()
end

function Event.registerInterceptor(interceptorCallback)
    table.insert(Event.interceptors, interceptorCallback)
end

function Event.deregisterInterceptor(interceptorCallback)
    local _, interceptorIndex = Table.findElement(Event.interceptors, interceptorCallback)
    table.remove(Event.interceptors, interceptorIndex)
end

return Event
