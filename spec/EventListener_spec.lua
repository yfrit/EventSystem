require("LocalRockInit")
require("YfritLib.Tests")

assert:register(
    "matcher",
    "has_self",
    function(state, arguments)
        local method = arguments[1]
        local eventListener = arguments[2]
        return function(methodWithSelf)
            methodWithSelf()
            assert.spy(method).was_called_with(eventListener)
            return true
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
            "child can use listener attribute to set instance listeners",
            function()
                spy.on(EventListener, "listenManyEvents")
                spy.on(EventListener, "listenManyRequests")
                local mockMethod = function()
                end
                local ChildClass =
                    Class.new(
                    {
                        listeners = {
                            events = {
                                Event1 = {
                                    SubEvent1 = mockMethod
                                },
                                Event2 = {
                                    SubEvent2 = mockMethod,
                                    SubEvent3 = mockMethod
                                }
                            },
                            requests = {
                                Event3 = {
                                    SubEvent4 = mockMethod
                                },
                                Event4 = {
                                    SubEvent5 = mockMethod,
                                    SubEvent6 = mockMethod
                                }
                            }
                        }
                    },
                    function(self)
                    end,
                    EventListener
                )

                local instance = ChildClass:new()

                assert.spy(EventListener.listenManyEvents).was_called_with(
                    instance,
                    {
                        Event1 = {
                            SubEvent1 = mockMethod
                        },
                        Event2 = {
                            SubEvent2 = mockMethod,
                            SubEvent3 = mockMethod
                        }
                    }
                )
                assert.spy(EventListener.listenManyRequests).was_called_with(
                    instance,
                    {
                        Event3 = {
                            SubEvent4 = mockMethod
                        },
                        Event4 = {
                            SubEvent5 = mockMethod,
                            SubEvent6 = mockMethod
                        }
                    }
                )

                EventListener.listenManyEvents:revert()
                EventListener.listenManyRequests:revert()
            end
        )
    end
)
