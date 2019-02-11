--[[
    TODO

    Unlisten
    Nested listeners
--]]
local Class = require("Class.Class")
local Event = require("Event")

local Eventer = Class.new({
    --static things

},
function(self)
    
end)

function Eventer:broadcast(...)
    Event.broadcast(...)
end

function Eventer:listen(event, method)
    local function methodWithSelf(...)
        method(self, ...)
    end
    Event.listen(event, methodWithSelf)
end

return Eventer