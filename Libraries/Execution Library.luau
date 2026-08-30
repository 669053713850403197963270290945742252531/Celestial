local executionLib = {}

local assetLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/669053713850403197963270290945742252531/Celestial/refs/heads/main/Libraries/Asset%20Library.luau"))()

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