local executionLib = {}

local assetLib = loadstring(game:HttpGet("https://gitlab.com/scripts1463602/Celestial/-/raw/main/Libraries/Asset%20Library.lua?ref_type=heads"))()

local file = "Celestial ScriptHub/Executions.txt"

if not isfile(file) then
    assetLib.createFile("Executions.txt", "1", true)
else
    -- Read and increase the execution count by one

    local currentCount = tonumber(readfile(file))

    if currentCount == nil then
        --warn("❌ | Invalid file contents. Resetting count to 0.")
        currentCount = 0
    end

    local newCount = currentCount + 1
    assetLib.updateFile(file, tostring(newCount))
end

executionLib.fetchExecutions = function()
    local executionCount = tonumber(readfile(file))
    return executionCount or 0
end

executionLib.clearExecutions = function()
    assetLib.updateFile(file, "0")
end

return executionLib