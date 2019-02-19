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
        local Class

        setup(
            function()
                Class = require("Utils.Class")
            end
        )
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
            ":listenEvent injects self into Event.listenEvent",
            function()
                spy.on(Event, "listenEvent")

                local eventer = Eventer:new()
                local method =
                    spy.new(
                    function()
                    end
                )
                eventer:listenEvent({"Event"}, method)

                assert.spy(Event.listenEvent).was_called_with({"Event"}, match.has_self(method, eventer))
            end
        )

        it(
            ":listenRequest injects self into Event.listenRequest",
            function()
                spy.on(Event, "listenRequest")

                local eventer = Eventer:new()
                local method =
                    spy.new(
                    function()
                    end
                )
                eventer:listenRequest({"Event"}, method)

                assert.spy(Event.listenRequest).was_called_with({"Event"}, match.has_self(method, eventer))
            end
        )

        it(
            ":listenManyEvents registers all events in a table with Event.listenEvent",
            function()
                spy.on(Event, "listenEvent")

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
                eventer:listenManyEvents(
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
                assert.spy(Event.listenEvent).was_called_with({"Event1", "SubEvent1"}, match.has_self(method1, eventer))
                assert.spy(Event.listenEvent).was_called_with({"Event2", "SubEvent2"}, match.has_self(method2, eventer))
                assert.spy(Event.listenEvent).was_called_with({"Event2", "SubEvent3"}, match.has_self(method3, eventer))
            end
        )

        it(
            ":listenManyRequests registers all events in a table with Event.listenRequest",
            function()
                spy.on(Event, "listenRequest")

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
                eventer:listenManyRequests(
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
                    match.has_self(method1, eventer)
                )
                assert.spy(Event.listenRequest).was_called_with(
                    {"Event2", "SubEvent2"},
                    match.has_self(method2, eventer)
                )
                assert.spy(Event.listenRequest).was_called_with(
                    {"Event2", "SubEvent3"},
                    match.has_self(method3, eventer)
                )
            end
        )

        it(
            "child can use listener attribute to set instance listeners",
            function()
                spy.on(Eventer, "listenManyEvents")
                spy.on(Eventer, "listenManyRequests")
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
                    Eventer
                )

                local instance = ChildClass:new()

                assert.spy(Eventer.listenManyEvents).was_called_with(
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
                assert.spy(Eventer.listenManyRequests).was_called_with(
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

                Eventer.listenManyEvents:revert()
                Eventer.listenManyRequests:revert()
            end
        )
    end
)
