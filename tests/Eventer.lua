local Event = mockRequire("Event")
local Eventer = require("Eventer")

local test = {}

--Eventer:broadcast(...) calls Event.broadcast(...)
function test.broadcast()
    local functionWasCalled = false
    local param1, param2, param3
    Event.broadcast = function(...)
        functionWasCalled = true
        param1, param2, param3 = ...
    end

    local eventer = Eventer:new()
    eventer:broadcast("SubEvent1", "SubEvent2", "SubEvent3")

    assert(functionWasCalled, "Event.broadcast was not called.")
    assert(param1=="SubEvent1", "First parameter was not 'SubEvent1'.")
    assert(param2=="SubEvent2", "Second parameter was not 'SubEvent2'.")
    assert(param3=="SubEvent3", "Third parameter was not 'SubEvent3'.")
end

--Eventer:listen injects self into Event.listen
function test.listen()
    local functionWasCalled = false
    local param1
    Event.listen = function(_, method)
        functionWasCalled = true
        method()
    end

    local eventer = Eventer:new()
    eventer:listen({"Event"}, function(...)
        param1 = ...
    end)

    assert(functionWasCalled, "Listener was not called.")
    assert(param1==eventer, "First parameter was not the eventer instance.")
end

return test