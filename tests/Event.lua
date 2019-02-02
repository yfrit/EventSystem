--TODO criar um git de testes genéricos
--Faz algo similar ao busted (it, mocks, asserts)

--[[
    Number in the event
]]

local test = {}
local function runTest(testName)
    if not testName then
        --running from console
        for name in pairs(test) do
            os.execute("lua .\\tests\\Event.lua " .. name)
        end
        return
    end

    --running from execute
    if test[testName] then
        local success, message = pcall(test[testName])
        if success then
            print("SUCCESS\t\t" .. testName)
        else
            print("FAIL\t\t" .. testName)
        end
    else
        error("Attempt to run unexistent test '" .. testName .. "'")
    end
end

local Event = require("Event")

--register a listener for a simple event, broadcast the event, function is called
function test.simpleEventListener()
    local functionWasCalled = false
    local function listenerFunction()
        functionWasCalled = true
    end
    Event.listen({"SimpleEvent"}, listenerFunction)
    Event.broadcast("SimpleEvent")

    assert(functionWasCalled)
end

--register a listener for a simple event, deregister the listener, broadcast the event, function is not called
function test.unlistenEvent()
    local functionWasCalled = false
    local function listenerFunction()
        functionWasCalled = true
    end
    Event.listen({"SimpleEvent"}, listenerFunction)
    Event.unlisten({"SimpleEvent"}, listenerFunction)
    Event.broadcast("SimpleEvent")

    assert(not functionWasCalled)
end

--register a listener for a simple event two times, broadcast the event, function is called twice
function test.listenTwiceEvent()
    local functionWasCalled = 0
    local function listenerFunction()
        functionWasCalled = functionWasCalled + 1
    end
    Event.listen({"SimpleEvent"}, listenerFunction)
    Event.listen({"SimpleEvent"}, listenerFunction)
    Event.broadcast("SimpleEvent")

    assert(functionWasCalled==2)
end

--register a listener for a simple event two times, deregister the listener, broadcast the event, function is not called
function test.unlistenTwiceEvent()
    local functionWasCalled = false
    local function listenerFunction()
        functionWasCalled = true
    end
    Event.listen({"SimpleEvent"}, listenerFunction)
    Event.listen({"SimpleEvent"}, listenerFunction)
    Event.unlisten({"SimpleEvent"}, listenerFunction)
    Event.broadcast("SimpleEvent")

    assert(not functionWasCalled)
end

--register a listener for first parameter of a composite event, broadcast the event, function is called
function test.compositeEventListener()
    local functionWasCalled = false
    local function listenerFunction()
        functionWasCalled = true
    end
    Event.listen({"CompositeEvent"}, listenerFunction)
    Event.broadcast("CompositeEvent", "SubEvent")

    assert(functionWasCalled)
end

--register a listener for two parameters of a composite event, broadcast the event, function is called
function test.compositeTwoEventListener()
    local functionWasCalled = false
    local function listenerFunction()
        functionWasCalled = true
    end
    Event.listen({"CompositeEvent", "SubEvent"}, listenerFunction)
    Event.broadcast("CompositeEvent", "SubEvent")

    assert(functionWasCalled)
end

--register a listener for two parameters of a composite event, broadcast the event with wrong second parameter,
--function is not called
function test.compositeWrongEventListener()
    local functionWasCalled = false
    local function listenerFunction()
        functionWasCalled = true
    end
    Event.listen({"CompositeEvent", "SubEvent"}, listenerFunction)
    Event.broadcast("CompositeEvent", "AnotherSubEvent")

    assert(not functionWasCalled)
end

--register a listener for a non-table event, should error
function test.nonTableEvent()
    local function listenerFunction()
    end
    local success = pcall(function()
        Event.listen("NonTableEvent", listenerFunction)
    end)
    assert(not success)
end

--register a listener for a non-table event, should error
function test.listenerWithoutFunction()
    local notAFunction = {}
    local success = pcall(function()
        Event.listen({"SimpleEvent"}, notAFunction)
    end)
    assert(not success)
end

--register a listener for a composite event, broadcast the event with the first parameter only,
--function should not be called
function test.missedListener()
    local functionWasCalled = false
    local function listenerFunction()
        functionWasCalled = true
    end
    Event.listen({"CompositeEvent", "SubEvent"}, listenerFunction)
    Event.broadcast("CompositeEvent")

    assert(not functionWasCalled)
end

--register a listener for a composite event with the number 1, broadcast the event with the first parameter only,
--function should not be called
function test.eventWithNumber()
    local functionWasCalled = false
    local function listenerFunction()
        functionWasCalled = true
    end
    Event.listen({"Event", 1}, listenerFunction)
    Event.broadcast("Event")

    assert(not functionWasCalled)
end

runTest(...)