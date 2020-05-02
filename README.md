# EventSystem

Enables communication through events and requests in Lua projects. More details in the "Usages" section.

# Dependencies

YfritLib: https://github.com/yfrit/yfritlib

# How to install

This project was once used as a LuaRocks module and it's probably possible to install it that way, but we no longer support it. Currently, we only support installing through Git, as following:

First, install the dependencies. Then if your project is a Git project, run this inside its folder:

`git submodule add https://github.com/yfrit/EventSystem.git`

If it is not a Git project, run this instead:

`git clone https://github.com/yfrit/EventSystem.git`

# Usages

## Broadcasting simple events

```
local Event = require("EventSystem.Event")

Event.listenEvent(
    {"SimpleEvent"},
    function()
        print("Hello")
    end
)

Event.broadcast("SimpleEvent")
-- prints "Hello"
```

## Broadcasting composite events

```
local Event = require("EventSystem.Event")

Event.listenEvent(
    {"CompositeEvent"},
    function()
        print("GoodBye1")
    end
)

Event.listenEvent(
    {"CompositeEvent", "SubEvent"},
    function()
        print("GoodBye2")
    end
)

Event.broadcast("CompositeEvent", "SubEvent")
-- prints "GoodBye1" and "GoodBye2"
```

## Broadcasting with extra parameters

```
local Event = require("EventSystem.Event")

Event.listenEvent(
    {"SimpleEvent"},
    function(...)
        print("Hello with: ", ...)
    end
)

Event.broadcast("SimpleEvent", "potato", 1, true)
-- prints "Hello with: potato, 1, true"
```

## Performing requests

There are two ways to repond to a request. You can either return the response as the return value, or call `Event.respond`. Using the return makes the code simplier, while using `Event.respond` has the advantage of allowing asynchronous responses, since the response does not need to be immediately returned in this case.

### Using the return

```
local Event = require("EventSystem.Event")

Event.listenRequest(
    {"GiveMeSomeWords"},
    function()
        return "potato", "hello"
    end
)

-- Event.request must be run inside a coroutine
local co =
    coroutine.wrap(
    function()
        local word1, word2 = Event.request("GiveMeSomeWords")
        print("I got the words:", word1, word2)
    end
)
co()
-- prints "I got the words: potato hello"
```

### Using the Event.respond

```
local Event = require("EventSystem.Event")

Event.listenRequest(
    {"GiveMeSomeWords"},
    function()
        Event.respond("GiveMeSomeWords", "potato", "hello")
    end
)

-- Event.request must be run inside a coroutine
local co =
    coroutine.wrap(
    function()
        local word1, word2 = Event.request("GiveMeSomeWords")
        print("I got the words:", word1, word2)
    end
)
co()
-- prints "I got the words: potato hello"
```

## Deregistering listeners

After you no longer want to listen to an event/request, you should clear the listeners.

```
local Event = require("EventSystem.Event")

local function listener()
    -- ...
end
Event.listenEvent({"SimpleEvent"}, listener)

Event.unlistenEvent({"SimpleEvent"}, listener)

```

```
local Event = require("EventSystem.Event")

local function listener()
    -- ...
end
Event.listenRequest({"SimpleEvent"}, listener)

Event.unlistenRequest({"SimpleEvent"}, listener)
```

## Using the EventListener class

If you are using YfritLib Classes, you can inherit from the EventListener class to simplify the creation of listeners.

```
local Class = require("YfritLib.Class")
local EventListener = require("EventSystem.EventListener")

local MyClass =
    Class.new(
    {
        listeners = {
            events = {
                SimpleEvent = "sayHello",
                CompositeEvent = {
                    SubEvent = "sayGoodBye"
                }
            },
            requests = {
                GiveMeSomeWords = "getWords"
            }
        }
    },
    function(self)
    end,
    EventListener
)

function MyClass:sayHello()
    print("Hello")
end

function MyClass:sayGoodBye()
    print("GoodBye")
end

function MyClass:getWords()
    return "potato", "hello"
end
```

```
local Event = require("EventSystem.Event")

local instance = MyClass:new()

Event.broadcast("SimpleEvent")
-- prints "Hello"

Event.broadcast("CompositeEvent", "SubEvent")
-- prints "GoodBye"

local co =
    coroutine.wrap(
    function()
        local word1, word2 = Event.request("GiveMeSomeWords")
        print("I got the words:", word1, word2)
    end
)
co()
-- prints "I got the words: potato hello"

```

## More

For more usage examples, see the test files inside the "spec" folder.
