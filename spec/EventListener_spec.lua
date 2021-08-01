require("LocalRockInit")
require("YfritLib.Tests")
local Utils = require("YfritLib.Utils")
local Class = require("YfritLib.Class")

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

insulate(
    "#EventListener",
    function()
        local Event
        local EventListener

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

insulate(
    "#EventListener #integration",
    function()
        local Event, EventListener
        setup(
            function()
                Event = require("Event")
                EventListener = require("EventListener")
            end
        )
        teardown(
            function()
            end
        )
        it(
            "child can return the response to the request",
            function()
                local ChildClass =
                    Class.new(
                    {
                        listeners = {
                            requests = {
                                RequestEvent = "method"
                            }
                        }
                    },
                    function()
                    end,
                    EventListener
                )
                function ChildClass:method()
                    return true, 2, "banana"
                end

                local instance = ChildClass:new()
                finally(
                    function()
                        instance:destroy()
                    end
                )
                local result1, result2, result3
                local co =
                    Utils.executeAsCoroutine(
                    function()
                        result1, result2, result3 = Event.request("RequestEvent")
                    end
                )
                assert.are_equal(coroutine.status(co), "dead")
                assert.are_equal(result1, true)
                assert.are_equal(result2, 2)
                assert.are_equal(result3, "banana")
            end
        )

        it(
            "#destroy clears request listeners",
            function()
                local ChildClass =
                    Class.new(
                    {
                        listeners = {
                            requests = {
                                RequestEvent = "method"
                            }
                        }
                    },
                    function()
                    end,
                    EventListener
                )
                function ChildClass:method()
                    return "banana"
                end

                local instance = ChildClass:new()
                instance:destroy()

                local result
                local co =
                    Utils.executeAsCoroutine(
                    function()
                        result = Event.request("RequestEvent")
                    end
                )
                assert.are_equal(result, nil)
                assert.are_equal(coroutine.status(co), "suspended")
            end
        )

        it(
            "broadcast MultipleInstancesOfSameEventListeners TriggersEachOnce",
            function()
                local callArgs = {}

                local ChildClass =
                    Class.new(
                    {},
                    function(self)
                        self:listenEvent({"Event"}, self._onEvent)
                    end,
                    EventListener
                )

                function ChildClass:_onEvent()
                    callArgs[self] = true
                end

                local instance1 = ChildClass:new()
                local instance2 = ChildClass:new()

                Event.broadcast("Event")

                assert.are_same(
                    {
                        [instance1] = true,
                        [instance2] = true
                    },
                    callArgs
                )
            end
        )
        it(
            "broadcast OverrideOnEventListener TriggersEachOnce",
            function()
                local callArgs = {}

                local ChildClass =
                    Class.new(
                    {},
                    function(self)
                        self:listenEvent({"Event"}, self._onEvent)
                    end,
                    EventListener
                )
                function ChildClass:_onEvent()
                    callArgs[self] = true
                end

                local GrandChildClass =
                    Class.new(
                    {},
                    function(self)
                    end,
                    ChildClass
                )
                function GrandChildClass:_onEvent()
                    callArgs[self] = true
                end

                local instance1 = ChildClass:new()
                local instance2 = GrandChildClass:new()

                Event.broadcast("Event")

                assert.are_same(
                    {
                        [instance1] = true,
                        [instance2] = true
                    },
                    callArgs
                )
            end
        )
    end
)
