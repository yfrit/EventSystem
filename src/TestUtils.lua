--TODO colocar no git

function _G.magicMock()
    local mock = setmetatable({}, {
        __index = function(t, k)
            local newMock = magicMock()
            rawset(t, k, newMock)
            return newMock
        end,
        __call = function()
            return magicMock()
        end
    })
    return mock
end

function _G.mockRequire(path)
    local mock = magicMock()
    package.loaded[path] = mock
    return mock
end

function _G.unrequire(path)
    package.loaded[path] = nil
end