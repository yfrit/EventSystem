--TODO criar um git de testes genéricos
--Faz algo similar ao busted (it, mocks, asserts)

local test = require("tests.Event")

local function runTest(testName)
    if not testName then
        --running from console
        for name in pairs(test) do
            os.execute("lua .\\Tester.lua " .. name)
        end
        return
    end

    --running from execute
    if test[testName] then
        local success, message = pcall(test[testName])
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