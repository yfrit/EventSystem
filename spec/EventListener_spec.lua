require("LocalRockInit")
require("YfritLib.Tests")

assert:register(
    "matcher",
    "has_self",
    function(state, arguments)
        local method = arguments[1]
        local eventListener = arguments[2]
        return function(methodWithSelf)
            return pcall(
                function()
                    methodWithSelf()
                    assert.spy(method).was_called_with(eventListener)
                end
            )
        end
    end
)

describe(
    "EventListener",
    function()
        local Event
        local EventListener
        local Class

        setup(
            function()
                Class = require("YfritLib.Class")
            end
        )
        before_each(
            function()
                Event = mockRequire("Event")
                EventListener = require("EventListener")
            end
        )
        after_each(
            function()
                unrequire("Event")
                unrequire("EventListener")
            end
        )

        it(
            ":listenEvent injects self into Event.listenEvent",
            function()
                spy.on(Event, "listenEvent")

                local eventListener = EventListener:new()
                local method =
                    spy.new(
                    function()
                    end
                )
                eventListener:listenEvent({"Event"}, method)

                assert.spy(Event.listenEvent).was_called_with({"Event"}, match.has_self(method, eventListener))
            end
        )

        it(
            ":listenRequest injects self into Event.listenRequest",
            function()
                spy.on(Event, "listenRequest")

                local eventListener = EventListener:new()
                local method =
                    spy.new(
                    function()
                    end
                )
                eventListener:listenRequest({"Event"}, method)

                assert.spy(Event.listenRequest).was_called_with({"Event"}, match.has_self(method, eventListener))
            end
        )

        it(
            ":listenManyEvents registers all events in a table with Event.listenEvent",
            function()
                spy.on(Event, "listenEvent")

                local eventListener = EventListener:new()
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
                eventListener:listenManyEvents(
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

                assert.spy(Event.listenEvent).was_called(3)
                assert.spy(Event.listenEvent).was_called_with(
                    {"Event1", "SubEvent1"},
                    match.has_self(method1, eventListener)
                )
                assert.spy(Event.listenEvent).was_called_with(
                    {"Event2", "SubEvent2"},
                    match.has_self(method2, eventListener)
                )
                assert.spy(Event.listenEvent).was_called_with(
                    {"Event2", "SubEvent3"},
                    match.has_self(method3, eventListener)
                )
            end
        )

        it(
            ":listenManyRequests registers all events in a table with Event.listenRequest",
            function()
                spy.on(Event, "listenRequest")

                local eventListener = EventListener:new()
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
                eventListener:listenManyRequests(
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

                assert.spy(Event.listenRequest).was_called(3)
                assert.spy(Event.listenRequest).was_called_with(
                    {"Event1", "SubEvent1"},
                    match.has_self(method1, eventListener)
                )
                assert.spy(Event.listenRequest).was_called_with(
                    {"Event2", "SubEvent2"},
                    match.has_self(method2, eventListener)
                )
                assert.spy(Event.listenRequest).was_called_with(
                    {"Event2", "SubEvent3"},
                    match.has_self(method3, eventListener)
                )
            end
        )

        it(
            "#this child can use listener attribute to set instance listeners",
            function()
                spy.on(Event, "listenEvent")
                spy.on(Event, "listenRequest")

                local ChildClass =
                    Class.new(
                    {
                        listeners = {
                            events = {
                                Event1 = "method1"
                            },
                            requests = {
                                Event2 = "method2"
                            }
                        }
                    },
                    function(self)
                    end,
                    EventListener
                )
                ChildClass.method1 =
                    spy.new(
                    function()
                    end
                )
                ChildClass.method2 =
                    spy.new(
                    function()
                    end
                )

                local instance = ChildClass:new()

                assert.spy(Event.listenEvent).was_called_with({"Event1"}, match.has_self(ChildClass.method1, instance))
                assert.spy(Event.listenRequest).was_called_with(
                    {"Event2"},
                    match.has_self(ChildClass.method2, instance)
                )

                Event.listenEvent:revert()
                Event.listenRequest:revert()
            end
        )
    end
)
