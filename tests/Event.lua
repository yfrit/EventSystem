--TODO criar um git de testes genéricos
--Faz algo similar ao busted (it, mocks, asserts)

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
            print("\t" .. message)
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

    assert(functionWasCalled, "Listener was not called.")
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

    assert(not functionWasCalled, "Listener was called.")
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

    assert(functionWasCalled==2, "Listener was not called twice.")
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

    assert(not functionWasCalled, "Listener was called.")
end

--register a listener for first parameter of a composite event, broadcast the event, function is called
function test.compositeEventListener()
    local functionWasCalled = false
    local function listenerFunction()
        functionWasCalled = true
    end
    Event.listen({"CompositeEvent"}, listenerFunction)
    Event.broadcast("CompositeEvent", "SubEvent")

    assert(functionWasCalled, "Listener was not called.")
end

--register a listener for two parameters of a composite event, broadcast the event, function is called
function test.compositeTwoEventListener()
    local functionWasCalled = false
    local function listenerFunction()
        functionWasCalled = true
    end
    Event.listen({"CompositeEvent", "SubEvent"}, listenerFunction)
    Event.broadcast("CompositeEvent", "SubEvent")

    assert(functionWasCalled, "Listener was not called.")
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

    assert(not functionWasCalled, "Listener was called.")
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
    assert(not success, "Did not error.")
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

    assert(not functionWasCalled, "Listener was called.")
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

    assert(not functionWasCalled, "Listener was called.")
end

--register a listener for the empty event, broadcast any event, function should be called
function test.emptyEventListener()
    local functionWasCalled = 0
    local function listenerFunction()
        functionWasCalled = functionWasCalled + 1
    end
    Event.listen({}, listenerFunction)
    Event.broadcast("Event1")
    Event.broadcast("Event2", "SubEvent1")
    Event.broadcast("Event3", "SubEvent2", "SubEvent3")

    assert(functionWasCalled==3, "Listener was not called thrice.")
end

--listener receives events as parameters
function test.eventParameters()
    local param1, param2, param3
    local function listenerFunction(...)
        param1, param2, param3 = ...
    end
    Event.listen({"CompositeEvent"}, listenerFunction)
    Event.broadcast("CompositeEvent", "SubEvent1", "SubEvent2")

    assert(param1=="CompositeEvent", "First parameter was not 'CompositeEvent'.")
    assert(param2=="SubEvent1", "Second parameter was not 'SubEvent1'.")
    assert(param3=="SubEvent2", "Third parameter was not 'SubEvent2'.")
end

runTest(...)