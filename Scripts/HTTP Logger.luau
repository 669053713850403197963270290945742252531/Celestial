--[[
    Potassium HTTP Logger
    ----------------------

    Features:
      • request() logging
      • httpget() logging
      • game:HttpGet() / HttpGetAsync() logging
      • request/response headers
      • request/response bodies
      • HTTP errors are logged without silently killing the logger
      • optional loadstring source logging WITHOUT hooking loadstring
      • console logging
      • file logging
      • console clearing on join/rejoin
      • automatic logger reload after teleport/rejoin

    IMPORTANT:
      Set LOGGER_PATH to the exact path where this script is saved.
--]]

local LOGGER_PATH = "Celestial/Scripts/HTTP Logger.luau"

local LOGGER = {
    Enabled = true,

    -- Console output
    Console = true,

    -- File output
    File = true,
    FilePath = "http_logger.log",

    -- Maximum request/response body size printed.
    -- Use math.huge for unlimited.
    MaxBodyLength = 100000,

    -- Log source passed to loadstring().
    --
    -- This is deliberately implemented as a wrapper rather than hooking
    -- the executor's native loadstring(), so the native function isn't
    -- modified.
    LogLoadstring = true,

    -- Include potentially sensitive headers/cookies.
    LogSensitiveHeaders = true,

    -- Clear executor console whenever a new session starts.
    ClearConsoleOnJoin = true,

    -- Re-load this logger after teleport/rejoin.
    ReloadOnTeleport = true,
}


--========================================================--
-- State
--========================================================--

local requestCounter = 0


--========================================================--
-- Utility
--========================================================--

local function now()
    return os.date("%Y-%m-%d %H:%M:%S")
end


local function truncate(value)
    value = tostring(value or "")

    if LOGGER.MaxBodyLength == math.huge
        or #value <= LOGGER.MaxBodyLength
    then
        return value
    end

    return value:sub(1, LOGGER.MaxBodyLength)
        .. string.format(
            "\n... [TRUNCATED: %d bytes total]",
            #value
        )
end


local function serialize(value, depth, visited)
    depth = depth or 0
    visited = visited or {}

    if depth > 8 then
        return "<max depth>"
    end

    if value == nil then
        return "nil"
    end

    local valueType = typeof(value)

    if valueType == "string" then
        return truncate(value)
    end

    if valueType == "number"
        or valueType == "boolean"
        or valueType == "function"
        or valueType == "thread"
    then
        return tostring(value)
    end

    if valueType == "Instance" then
        local ok, fullName = pcall(function()
            return value:GetFullName()
        end)

        return string.format(
            "Instance<%s:%s>",
            value.ClassName,
            ok and fullName or "?"
        )
    end

    if valueType ~= "table" then
        return tostring(value)
    end

    if visited[value] then
        return "<recursive table>"
    end

    visited[value] = true

    local parts = {
        "{"
    }

    for key, item in pairs(value) do
        local keyString = serialize(
            key,
            depth + 1,
            visited
        )

        local valueString = serialize(
            item,
            depth + 1,
            visited
        )

        parts[#parts + 1] = string.format(
            "    [%s] = %s",
            keyString,
            valueString
        )
    end

    parts[#parts + 1] = "}"

    visited[value] = nil

    return table.concat(parts, "\n")
end


local function printConsole(text)
    if not LOGGER.Console then
        return
    end

    if typeof(rconsoleprint) == "function" then
        rconsoleprint(text)
    else
        print(text)
    end
end


local function writeFileLog(text)
    if not LOGGER.File then
        return
    end

    if typeof(isfile) ~= "function"
        or typeof(writefile) ~= "function"
        or typeof(appendfile) ~= "function"
    then
        return
    end

    local ok, err = pcall(function()
        if isfile(LOGGER.FilePath) then
            appendfile(
                LOGGER.FilePath,
                text
            )
        else
            writefile(
                LOGGER.FilePath,
                text
            )
        end
    end)

    if not ok then
        printConsole(
            "[HTTP LOGGER] File logging failed: "
            .. tostring(err)
            .. "\n"
        )
    end
end


local function writeLog(text)
    if not LOGGER.Enabled then
        return
    end

    local output = string.format(
        "\n[%s]\n%s\n",
        now(),
        text
    )

    printConsole(output)
    writeFileLog(output)
end


--========================================================--
-- Console initialization
--========================================================--

local function clearLoggerConsole()
    if not LOGGER.ClearConsoleOnJoin then
        return
    end

    if typeof(rconsoleclear) == "function" then
        pcall(rconsoleclear)
    end
end


-- Clear the current session before printing anything.
clearLoggerConsole()


--========================================================--
-- Request logging
--========================================================--

local function logRequest(kind, options)
    requestCounter += 1

    local id = requestCounter

    options = options or {}

    local method =
        options.Method
        or options.method
        or "GET"

    local url =
        options.Url
        or options.URL
        or options.url
        or "?"

    local output = string.format(
        "========== HTTP REQUEST #%d ==========\n"
        .. "Type: %s\n"
        .. "Method: %s\n"
        .. "URL: %s\n",
        id,
        tostring(kind),
        tostring(method),
        tostring(url)
    )

    -- Headers
    if options.Headers then
        output ..= "\n--- Headers ---\n"

        for key, value in pairs(options.Headers) do
            local keyString = tostring(key)
            local lowerKey = keyString:lower()

            if LOGGER.LogSensitiveHeaders then
                output ..= string.format(
                    "%s: %s\n",
                    keyString,
                    tostring(value)
                )
            else
                if lowerKey == "authorization"
                    or lowerKey == "cookie"
                    or lowerKey == "set-cookie"
                    or lowerKey:find("token", 1, true)
                then
                    output ..= string.format(
                        "%s: <REDACTED>\n",
                        keyString
                    )
                else
                    output ..= string.format(
                        "%s: %s\n",
                        keyString,
                        tostring(value)
                    )
                end
            end
        end
    end

    -- Cookies
    if options.Cookies then
        output ..= "\n--- Cookies ---\n"

        if LOGGER.LogSensitiveHeaders then
            output ..= serialize(options.Cookies)
        else
            output ..= "<REDACTED>"
        end

        output ..= "\n"
    end

    -- Body
    if options.Body ~= nil then
        output ..= "\n--- Request Body ---\n"
        output ..= truncate(options.Body)
        output ..= "\n"
    end

    writeLog(output)

    return id
end


--========================================================--
-- Response logging
--========================================================--

local function logResponse(id, response)
    if response == nil then
        writeLog(
            string.format(
                "========== HTTP RESPONSE #%d ==========\n"
                .. "Response: nil\n",
                id
            )
        )

        return
    end

    local statusCode =
        response.StatusCode
        or response.status_code
        or response.Status
        or "?"

    local statusMessage =
        response.StatusMessage
        or response.status_message

    local output = string.format(
        "========== HTTP RESPONSE #%d ==========\n"
        .. "StatusCode: %s\n",
        id,
        tostring(statusCode)
    )

    if statusMessage ~= nil then
        output ..= string.format(
            "StatusMessage: %s\n",
            tostring(statusMessage)
        )
    end

    -- Response headers
    if response.Headers then
        output ..= "\n--- Response Headers ---\n"

        for key, value in pairs(response.Headers) do
            local keyString = tostring(key)
            local lowerKey = keyString:lower()

            if LOGGER.LogSensitiveHeaders then
                output ..= string.format(
                    "%s: %s\n",
                    keyString,
                    tostring(value)
                )
            else
                if lowerKey == "set-cookie"
                    or lowerKey == "authorization"
                    or lowerKey:find("token", 1, true)
                then
                    output ..= string.format(
                        "%s: <REDACTED>\n",
                        keyString
                    )
                else
                    output ..= string.format(
                        "%s: %s\n",
                        keyString,
                        tostring(value)
                    )
                end
            end
        end
    end

    -- Response body
    local body =
        response.Body
        or response.body
        or response.ResponseBody

    if body ~= nil then
        output ..= "\n--- Response Body ---\n"
        output ..= truncate(body)
        output ..= "\n"
    end

    writeLog(output)
end


--========================================================--
-- Error logging
--========================================================--

local function logHttpError(id, err)
    writeLog(
        string.format(
            "========== HTTP ERROR #%d ==========\n"
            .. "Error: %s\n",
            id,
            tostring(err)
        )
    )
end


--========================================================--
-- request()
--========================================================--

if typeof(request) == "function" then
    local originalRequest

    originalRequest = hookfunction(
        request,
        function(options)
            local id = logRequest(
                "request()",
                options
            )

            local packed

            local ok, err = pcall(function()
                packed = table.pack(
                    originalRequest(options)
                )
            end)

            if not ok then
                logHttpError(
                    id,
                    err
                )

                -- Preserve the original failure behavior.
                error(err, 0)
            end

            local response = packed[1]

            logResponse(
                id,
                response
            )

            return table.unpack(
                packed,
                1,
                packed.n
            )
        end
    )

    writeLog(
        "[LOGGER] Hooked request()"
    )
else
    writeLog(
        "[LOGGER] request() is unavailable"
    )
end


--========================================================--
-- httpget()
--========================================================--

if typeof(httpget) == "function" then
    local originalHttpGet

    originalHttpGet = hookfunction(
        httpget,
        function(url)
            local id = logRequest(
                "httpget()",
                {
                    Method = "GET",
                    Url = url,
                }
            )

            local packed

            local ok, err = pcall(function()
                packed = table.pack(
                    originalHttpGet(url)
                )
            end)

            if not ok then
                logHttpError(
                    id,
                    err
                )

                error(err, 0)
            end

            -- httpget() returns the response body directly.
            logResponse(
                id,
                {
                    StatusCode = "N/A",
                    Body = packed[1],
                }
            )

            return table.unpack(
                packed,
                1,
                packed.n
            )
        end
    )

    writeLog(
        "[LOGGER] Hooked httpget()"
    )
else
    writeLog(
        "[LOGGER] httpget() is unavailable"
    )
end


--========================================================--
-- game:HttpGet / HttpGetAsync
--========================================================--

if typeof(hookmetamethod) == "function"
    and typeof(getnamecallmethod) == "function"
then
    local originalNamecall

    originalNamecall = hookmetamethod(
        game,
        "__namecall",
        function(self, ...)
            local method = getnamecallmethod()

            if method == "HttpGet"
                or method == "HttpGetAsync"
            then
                local args = table.pack(...)

                local url = args[1]

                local id = logRequest(
                    "game:" .. tostring(method),
                    {
                        Method = "GET",
                        Url = url,
                    }
                )

                local packed

                local ok, err = pcall(function()
                    packed = table.pack(
                        originalNamecall(
                            self,
                            table.unpack(
                                args,
                                1,
                                args.n
                            )
                        )
                    )
                end)

                if not ok then
                    logHttpError(
                        id,
                        err
                    )

                    error(err, 0)
                end

                logResponse(
                    id,
                    {
                        StatusCode = "N/A",
                        Body = packed[1],
                    }
                )

                return table.unpack(
                    packed,
                    1,
                    packed.n
                )
            end

            return originalNamecall(
                self,
                ...
            )
        end
    )

    writeLog(
        "[LOGGER] Hooked game.__namecall "
        .. "for HttpGet/HttpGetAsync"
    )
else
    writeLog(
        "[LOGGER] hookmetamethod/getnamecallmethod "
        .. "is unavailable"
    )
end


--========================================================--
-- Logged loadstring wrapper
--========================================================--
--
-- DO NOT hook the executor's native loadstring().
--
-- Use LoggedLoadstring(source, chunkname) when you
-- specifically want to log source being compiled.
--

if LOGGER.LogLoadstring
    and typeof(loadstring) == "function"
then
    local nativeLoadstring = loadstring

    function LoggedLoadstring(source, chunkname)
        source = tostring(source)

        writeLog(
            "========== LOADSTRING ==========\n"
            .. "Source length: "
            .. tostring(#source)
            .. "\n"
            .. "Chunk name: "
            .. tostring(chunkname)
            .. "\n\n"
            .. "--- Source ---\n"
            .. truncate(source)
            .. "\n"
        )

        return nativeLoadstring(
            source,
            chunkname
        )
    end

    writeLog(
        "[LOGGER] LoggedLoadstring() ready"
    )
end


--========================================================--
-- Teleport / rejoin persistence
--========================================================--

local function setupTeleportReload()
    if not LOGGER.ReloadOnTeleport then
        return
    end

    -- Potassium/builds may expose one spelling or the other.
    local queueTeleport =
        queue_on_teleport
        or queueonteleport

    if typeof(queueTeleport) ~= "function" then
        writeLog(
            "[LOGGER] queue_on_teleport/queueonteleport "
            .. "is unavailable; teleport reload disabled"
        )

        return
    end

    local queuedScript = string.format([[
        repeat
            task.wait()
        until game:IsLoaded()

        -- Give the new client a moment to finish
        -- initializing after the teleport.
        task.wait(0.25)

        if %s
            and typeof(rconsoleclear) == "function"
        then
            pcall(rconsoleclear)
        end

        local loggerPath = %q

        if typeof(isfile) ~= "function"
            or typeof(readfile) ~= "function"
            or typeof(loadstring) ~= "function"
        then
            warn(
                "[HTTP LOGGER] Required filesystem/loadstring "
                .. "functions are unavailable after teleport"
            )

            return
        end

        if not isfile(loggerPath) then
            warn(
                "[HTTP LOGGER] Logger file does not exist: "
                .. tostring(loggerPath)
            )

            return
        end

        local okRead, source = pcall(function()
            return readfile(loggerPath)
        end)

        if not okRead then
            warn(
                "[HTTP LOGGER] Failed reading logger: "
                .. tostring(source)
            )

            return
        end

        local okCompile, logger, compileError = pcall(function()
            return loadstring(source, "@HTTP Logger")
        end)

        if not okCompile then
            warn(
                "[HTTP LOGGER] Logger compilation threw: "
                .. tostring(logger)
            )

            return
        end

        if not logger then
            warn(
                "[HTTP LOGGER] Logger compilation failed: "
                .. tostring(compileError)
            )

            return
        end

        local okExecute, executeError = pcall(logger)

        if not okExecute then
            warn(
                "[HTTP LOGGER] Logger initialization failed: "
                .. tostring(executeError)
            )
        end
    ]], tostring(LOGGER.ClearConsoleOnJoin), LOGGER_PATH)

    local ok, err = pcall(function()
        queueTeleport(queuedScript)
    end)

    if ok then
        writeLog(
            "[LOGGER] Teleport reload queued"
        )
    else
        writeLog(
            "[LOGGER] Failed to queue teleport reload: "
            .. tostring(err)
        )
    end
end


setupTeleportReload()


--========================================================--
-- Startup
--========================================================--

local executorName = "unknown"

if typeof(identifyexecutor) == "function" then
    local ok, result = pcall(identifyexecutor)

    if ok then
        executorName = tostring(result)
    end
end

writeLog(
    "========================================\n"
    .. "[LOGGER] Potassium HTTP logger initialized\n"
    .. "[LOGGER] Executor: "
    .. executorName
    .. "\n"
    .. "[LOGGER] ClearConsoleOnJoin: "
    .. tostring(LOGGER.ClearConsoleOnJoin)
    .. "\n"
    .. "[LOGGER] ReloadOnTeleport: "
    .. tostring(LOGGER.ReloadOnTeleport)
    .. "\n"
    .. "========================================"
)