--TODO criar um git de testes genéricos
--Faz algo similar ao busted (it, mocks, asserts)
--Deixar mais eficiente (O(n²) é ridículo)
    --Isso vai bugar quanto tiver um arquivo mockando outro que está sendo testado também

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

local tests = {
    -- Event = require("tests.Event"),
    Eventer = require("tests.Eventer"),
}

local function runTest(fileName, testName)
    if not fileName then
        --running from console
        for fileName,testFile in pairs(tests) do
            for testName in pairs(testFile) do
                os.execute("lua .\\Tester.lua " .. fileName .. " " .. testName)
            end
        end
        return
    end

    --running from execute
    local test = tests[fileName][testName]
    if test then
        local success, message = pcall(test)
        if success then
            print("SUCCESS\t\t" .. testName)
        else
            print("FAIL\t\t" .. testName)
            print("\t" .. message)
        end
    else
        error("Attempt to run unexistent test '" .. testName .. "'")
    end
end

runTest(...)