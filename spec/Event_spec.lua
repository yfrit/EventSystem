require("Utils.Tests")

describe(
    "Event",
    function()
        local Event

        before_each(
            function()
                Event = require("Event")
            end
        )
        after_each(
            function()
                unrequire("Event")
            end
        )

        it(
            "register a listener for a simple event, broadcast the event, function is called",
            function()
                local listenerFunction =
                    spy.new(
                    function()
                    end
                )

                Event.listenEvent({"SimpleEvent"}, listenerFunction)
                Event.broadcast("SimpleEvent")

                assert.spy(listenerFunction).was_called()
            end
        )

        it(
            "register a listener for a simple event, deregister the listener, broadcast the event, function is not called",
            function()
                local listenerFunction =
                    spy.new(
                    function()
                    end
                )

                Event.listenEvent({"SimpleEvent"}, listenerFunction)
                Event.unlistenEvent({"SimpleEvent"}, listenerFunction)
                Event.broadcast("SimpleEvent")

                assert.spy(listenerFunction).was_not_called()
            end
        )

        it(
            "register a listener for a simple event two times, broadcast the event, function is called twice",
            function()
                local listenerFunction =
                    spy.new(
                    function()
                    end
                )

                Event.listenEvent({"SimpleEvent"}, listenerFunction)
                Event.listenEvent({"SimpleEvent"}, listenerFunction)
                Event.broadcast("SimpleEvent")

                assert.spy(listenerFunction).was_called(2)
            end
        )

        it(
            "register a listener for a simple event, deregister the listener, broadcast the event, function is not called",
            function()
                local listenerFunction =
                    spy.new(
                    function()
                    end
                )

                Event.listenEvent({"SimpleEvent"}, listenerFunction)
                Event.listenEvent({"SimpleEvent"}, listenerFunction)
                Event.unlistenEvent({"SimpleEvent"}, listenerFunction)
                Event.broadcast("SimpleEvent")

                assert.spy(listenerFunction).was_not_called()
            end
        )

        it(
            "register a listener for first parameter of a composite event, broadcast the event, function is called",
            function()
                local listenerFunction =
                    spy.new(
                    function()
                    end
                )

                Event.listenEvent({"CompositeEvent"}, listenerFunction)
                Event.broadcast("CompositeEvent", "SubEvent")

                assert.spy(listenerFunction).was_called()
            end
        )

        it(
            "register a listener for first parameter of a composite event, broadcast the event, function is called",
            function()
                local listenerFunction =
                    spy.new(
                    function()
                    end
                )

                Event.listenEvent({"CompositeEvent", "SubEvent"}, listenerFunction)
                Event.broadcast("CompositeEvent", "SubEvent")

                assert.spy(listenerFunction).was_called()
            end
        )

        it(
            "register a listener for two parameters of a composite event, broadcast the event with wrong second parameter, function is not called",
            function()
                local listenerFunction =
                    spy.new(
                    function()
                    end
                )

                Event.listenEvent({"CompositeEvent", "SubEvent"}, listenerFunction)
                Event.broadcast("CompositeEvent", "AnotherSubEvent")

                assert.spy(listenerFunction).was_not_called()
            end
        )

        it(
            "register a listener for a non-table event, should error",
            function()
                local function listenerFunction()
                end
                assert.has_error(
                    function()
                        Event.listenEvent("NonTableEvent", listenerFunction)
                    end
                )
            end
        )

        it(
            "register a non-callable listener, should error",
            function()
                local notAFunction = {}
                assert.has_error(
                    function()
                        Event.listenEvent({"SimpleEvent"}, notAFunction)
                    end
                )
            end
        )

        it(
            "register a listener for a composite event, broadcast the event with the first parameter only, function should not be called",
            function()
                local listenerFunction =
                    spy.new(
                    function()
                    end
                )

                Event.listenEvent({"CompositeEvent", "SubEvent"}, listenerFunction)
                Event.broadcast("CompositeEvent")

                assert.spy(listenerFunction).was_not_called()
            end
        )

        it(
            "register a listener for a composite event with the number 1, broadcast the event with the first parameter only, function should not be called",
            function()
                local listenerFunction =
                    spy.new(
                    function()
                    end
                )

                Event.listenEvent({"Event", 1}, listenerFunction)
                Event.broadcast("Event")

                assert.spy(listenerFunction).was_not_called()
            end
        )

        it(
            "register a listener for the empty event, broadcast any event, function should be called",
            function()
                local listenerFunction =
                    spy.new(
                    function()
                    end
                )

                Event.listenEvent({}, listenerFunction)
                Event.broadcast("Event1")
                Event.broadcast("Event2", "SubEvent1")
                Event.broadcast("Event3", "SubEvent2", "SubEvent3")

                assert.spy(listenerFunction).was_called(3)
            end
        )

        it(
            "listener receives events as parameters",
            function()
                local listenerFunction =
                    spy.new(
                    function()
                    end
                )

                Event.listenEvent({"CompositeEvent"}, listenerFunction)
                Event.broadcast("CompositeEvent", "SubEvent1", "SubEvent2")

                assert.spy(listenerFunction).was_called_with("CompositeEvent", "SubEvent1", "SubEvent2")
            end
        )

        it(
            "register a listener for a request event, request that event, should return responder response and have called it passing the event as parameter",
            function()
                local responderFunction =
                    spy.new(
                    function(subEvent1, subEvent2)
                        Event.respond(subEvent1, subEvent2, "return1", "return2")
                    end
                )
                Event.listenRequest({"Event", "SubEvent"}, responderFunction)

                local co =
                    coroutine.create(
                    function()
                        local return1, return2 = Event.request("Event", "SubEvent")
                        assert.is_equal(return1, "return1")
                        assert.is_equal(return2, "return2")
                        assert.spy(responderFunction).was_called()
                        assert.spy(responderFunction).was_called_with("Event", "SubEvent")
                    end
                )

                local ok, errorMessage = coroutine.resume(co)
                if not ok then
                    error(errorMessage)
                end
                assert.is_equal(coroutine.status(co), "dead")
            end
        )

        it(
            "register a asynchronous listener for a request event, request that event, should work",
            function()
                local responderFunction =
                    spy.new(
                    function(event)
                        --simulate asynchronous listener by using a coroutine
                        local resumer =
                            coroutine.wrap(
                            function()
                                Event.respond(event)
                            end
                        )

                        --will resume when event "ResumeResponder" is broadcast
                        Event.listenEvent({"ResumeResponder"}, resumer)
                    end
                )
                Event.listenRequest({"Event"}, responderFunction)

                local co =
                    coroutine.create(
                    function()
                        Event.request("Event")
                    end
                )

                local ok, errorMessage = coroutine.resume(co)
                if not ok then
                    error(errorMessage)
                end
                Event.broadcast("ResumeResponder")

                assert.is_equal(coroutine.status(co), "dead")
            end
        )

        it(
            "register a listener for a request event, request that event, respond it twice, should ignore second response",
            function()
                local responderFunction =
                    spy.new(
                    function(subEvent1, subEvent2)
                        Event.respond(subEvent1, subEvent2, "correctReturn")
                        Event.respond(subEvent1, subEvent2, "wrongReturn")
                    end
                )
                Event.listenRequest({"Event", "SubEvent"}, responderFunction)

                local co =
                    coroutine.create(
                    function()
                        local return1 = Event.request("Event", "SubEvent")
                        assert.is_equal(return1, "correctReturn")
                    end
                )

                local ok, errorMessage = coroutine.resume(co)
                if not ok then
                    error(errorMessage)
                end
                assert.is_equal(coroutine.status(co), "dead")
            end
        )

        it(
            "calling Event.request outside a coroutine errors with message: " ..
                "'Event.request must be run inside a coroutine'",
            function()
                assert.has_error(
                    function()
                        Event.request("Event")
                    end,
                    "Event.request must be run inside a coroutine"
                )
            end
        )

        --TODO generic response for specific requests
        --e.g. request("Event", "SubEvent"), respond("Event", "Answer")
    end
)
