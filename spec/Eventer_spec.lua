require("Utils.Tests")

assert:register(
    "matcher",
    "has_self",
    function(state, arguments)
        local method = arguments[1]
        local eventer = arguments[2]
        return function(methodWithSelf)
            methodWithSelf()
            assert.spy(method).was_called_with(eventer)
            return true
        end
    end
)

describe(
    "Eventer",
    function()
        local Event
        local Eventer

        before_each(
            function()
                Event = mockRequire("Event")
                Eventer = require("Eventer")
            end
        )
        after_each(
            function()
                unrequire("Event")
                unrequire("Eventer")
            end
        )

        it(
            ":broadcast(...) calls Event.broadcast(...)",
            function()
                spy.on(Event, "broadcast")

                local eventer = Eventer:new()
                eventer:broadcast("SubEvent1", "SubEvent2", "SubEvent3")

                assert.spy(Event.broadcast).was_called_with("SubEvent1", "SubEvent2", "SubEvent3")
            end
        )

        it(
            ":listen injects self into Event.listen",
            function()
                spy.on(Event, "listen")

                local eventer = Eventer:new()
                local method =
                    spy.new(
                    function()
                    end
                )
                eventer:listen({"Event"}, method)

                assert.spy(Event.listen).was_called_with({"Event"}, match.has_self(method, eventer))
            end
        )

        it(
            ":listenMany registers all events in a table with Event.listen",
            function()
                spy.on(Event, "listen")

                local eventer = Eventer:new()
                local method1 =
                    spy.new(
                    function()
                    end
                )
                local method2 =
                    spy.new(
                    function()
                    end
                )
                local method3 =
                    spy.new(
                    function()
                    end
                )
                eventer:listenMany(
                    {
                        Event1 = {
                            SubEvent1 = method1
                        },
                        Event2 = {
                            SubEvent2 = method2,
                            SubEvent3 = method3
                        }
                    }
                )

                assert.spy(Event.listen).was_called(3)
                assert.spy(Event.listen).was_called_with({"Event1", "SubEvent1"}, match.has_self(method1, eventer))
                assert.spy(Event.listen).was_called_with({"Event2", "SubEvent2"}, match.has_self(method2, eventer))
                assert.spy(Event.listen).was_called_with({"Event2", "SubEvent3"}, match.has_self(method3, eventer))
            end
        )
    end
)
