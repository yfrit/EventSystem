require("TestUtils")

describe("Event", function()
    local Event

    before_each(function()
        Event = require("Event")
    end)
    after_each(function()
        unrequire("Event")
    end)

    it("register a listener for a simple event, broadcast the event, function is called", function()
        local listenerFunction = spy.new(function() end)

        Event.listen({"SimpleEvent"}, listenerFunction)
        Event.broadcast("SimpleEvent")

        assert.spy(listenerFunction).was_called()
    end)

    it("register a listener for a simple event, deregister the listener, broadcast the event, function is not called", function()
        local listenerFunction = spy.new(function() end)

        Event.listen({"SimpleEvent"}, listenerFunction)
        Event.unlisten({"SimpleEvent"}, listenerFunction)
        Event.broadcast("SimpleEvent")

        assert.spy(listenerFunction).was_not_called()
    end)

    it("register a listener for a simple event two times, broadcast the event, function is called twice", function()
        local listenerFunction = spy.new(function() end)

        Event.listen({"SimpleEvent"}, listenerFunction)
        Event.listen({"SimpleEvent"}, listenerFunction)
        Event.broadcast("SimpleEvent")

        assert.spy(listenerFunction).was_called(2)
    end)

    it("register a listener for a simple event, deregister the listener, broadcast the event, function is not called", function()
        local listenerFunction = spy.new(function() end)

        Event.listen({"SimpleEvent"}, listenerFunction)
        Event.listen({"SimpleEvent"}, listenerFunction)
        Event.unlisten({"SimpleEvent"}, listenerFunction)
        Event.broadcast("SimpleEvent")

        assert.spy(listenerFunction).was_not_called()
    end)

    it("register a listener for first parameter of a composite event, broadcast the event, function is called", function()
        local listenerFunction = spy.new(function() end)

        Event.listen({"CompositeEvent"}, listenerFunction)
        Event.broadcast("CompositeEvent", "SubEvent")

        assert.spy(listenerFunction).was_called()
    end)

    it("register a listener for first parameter of a composite event, broadcast the event, function is called", function()
        local listenerFunction = spy.new(function() end)

        Event.listen({"CompositeEvent", "SubEvent"}, listenerFunction)
        Event.broadcast("CompositeEvent", "SubEvent")

        assert.spy(listenerFunction).was_called()
    end)

    it("register a listener for two parameters of a composite event, broadcast the event with wrong second parameter, function is not called", function()
        local listenerFunction = spy.new(function() end)

        Event.listen({"CompositeEvent", "SubEvent"}, listenerFunction)
        Event.broadcast("CompositeEvent", "AnotherSubEvent")

        assert.spy(listenerFunction).was_not_called()
    end)

    it("register a listener for a non-table event, should error", function()
        local function listenerFunction()
        end
        assert.has_error(function()
            Event.listen("NonTableEvent", listenerFunction)
        end)
    end)

    it("register a non-callable listener, should error", function()
        local notAFunction = {}
        assert.has_error(function()
            Event.listen({"SimpleEvent"}, notAFunction)
        end)
    end)

    it("register a listener for a composite event, broadcast the event with the first parameter only, function should not be called", function()
        local listenerFunction = spy.new(function() end)

        Event.listen({"CompositeEvent", "SubEvent"}, listenerFunction)
        Event.broadcast("CompositeEvent")

        assert.spy(listenerFunction).was_not_called()
    end)

    it("register a listener for a composite event with the number 1, broadcast the event with the first parameter only, function should not be called", function()
        local listenerFunction = spy.new(function() end)

        Event.listen({"Event", 1}, listenerFunction)
        Event.broadcast("Event")

        assert.spy(listenerFunction).was_not_called()
    end)

    it("register a listener for the empty event, broadcast any event, function should be called", function()
        local listenerFunction = spy.new(function() end)

        Event.listen({}, listenerFunction)
        Event.broadcast("Event1")
        Event.broadcast("Event2", "SubEvent1")
        Event.broadcast("Event3", "SubEvent2", "SubEvent3")

        assert.spy(listenerFunction).was_called(3)
    end)

    it("listener receives events as parameters", function()
        local listenerFunction = spy.new(function() end)

        Event.listen({"CompositeEvent"}, listenerFunction)
        Event.broadcast("CompositeEvent", "SubEvent1", "SubEvent2")

        assert.spy(listenerFunction).was_called_with("CompositeEvent", "SubEvent1", "SubEvent2")
    end)
end)