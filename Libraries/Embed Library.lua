local httpService = game:GetService("HttpService")

-- Helper functions

local function getTime(displaySeconds)
    local time = os.date("*t")
    local hour = time.hour
    local minute = time.min
    local second = time.sec
    
    local ampm = "AM"
    if hour >= 12 then
        ampm = "PM"
    end
    
    -- Convert to 12 hour

    if hour == 0 then
        hour = 12 -- me when midnight 😨
    elseif hour > 12 then
        hour = hour - 12
    end

    if displaySeconds then
        return string.format("%02d:%02d:%02d %s", hour, minute, second, ampm)
    else
        return string.format("%02d:%02d %s", hour, minute, ampm)
    end
end

local function getDate()
    return os.date("%m/%d/%Y")
end

-- Convert Color3 values to discord's integer color format shit

local function color3ToDiscordInt(color)
    local r = math.floor(color.R * 255)
    local g = math.floor(color.G * 255)
    local b = math.floor(color.B * 255)

    return bit32.lshift(r, 16) + bit32.lshift(g, 8) + b -- Combine to a 24 bit integer
end

local function createTimestamp(unixTime, format)
    format = format or "f" -- Default format is "f" (e.g., January 27, 2024 12:34 PM)
    return string.format("<t:%d:%s>", unixTime, format)
end

local embedLib = {}

embedLib.createEmbed = function(args)
    local webhookUrl = args.webhookUrl
    local title = args.title or nil
    local description = args.description or nil
    local color = args.color or Color3.fromRGB(255, 255, 255)
    local titleUrl = args.url
    local thumbnail = args.thumbnail
    local author = args.author or nil
    local footer = args.footer or false
    local fields = args.fields or {}

    local integerColor = color3ToDiscordInt(color) -- Convert Color3 value to integer format

    local embed = {
        title = title,
        description = description,
        color = integerColor,
        url = titleUrl,
        thumbnail = {
            url = thumbnail or ""
        },

        fields = {},

        webhookUrl = webhookUrl -- Store the webhook URL inside the embed object
    }

    if author then
        if author.icon_url == "Celestial" then
            author.icon_url = "https://i.imgur.com/8OzNxqE.png"
        elseif author.icon_url == "Corrade Private" then
            author.icon_url = "https://i.imgur.com/OrzOOD2.jpeg"
        end

        embed.author = {
            name = author.name or nil,
            icon_url = author.icon_url or nil,
            url = author.url or nil
        }
    end

    if footer.enabled then
        local time = getTime(false)

        if footer.displaySeconds then
            time = getTime(true)
        end

        if not footer.name then
            embed.footer = {
                text = getDate() .. " | " .. time,
                icon_url = footer.icon
            }
        else
            embed.footer = {
                text = footer.name,
                icon_url = footer.icon
            }
        end
    end

    -- Check for "Timestamp" field value

    for _, field in ipairs(fields) do
        if field.value == "Timestamp" then
            field.value = createTimestamp(os.time(), "d") -- Convert to gay discord timestamp
        end
        table.insert(embed.fields, field) -- Add field to embed
    end

    return embed
end

embedLib.addField = function(embed, name, value, inline)
    if value == "Timestamp" then
        value = createTimestamp(os.time(), "d")
    end

    --[[

    f = March 4, 2025 1:39 AM
    d = 3/4/2025

    ]]

    table.insert(embed.fields, {
        name = name,
        value = value,
        inline = inline or false
    })
end

embedLib.addTimestampField = function(embed, name, format, inline)
    local timestamp = createTimestamp(os.time(), format)
    embedLib.addField(embed, name, timestamp, inline)
end

embedLib.sendEmbed = function(embed, username, avatarUrl)
    webhookUrl = embed.webhookUrl

    if not webhookUrl then
        warn("❌ No Webhook URL provided.")
        return
    end
    
    if avatarUrl == "Celestial" then
        avatarUrl = "https://i.imgur.com/8OzNxqE.png"
    elseif avatarUrl == "Corrade Private" then
        avatarUrl = "https://i.imgur.com/OrzOOD2.jpeg"
    end

    local data = {
        username = username or "Unknown",
        avatar_url = avatarUrl or nil,
        embeds = { embed }
    }

    local encodedData = httpService:JSONEncode(data)

    local headers = {
        ["Content-Type"] = "application/json"
    }

    local response = request({
        Url = webhookUrl,
        Method = "POST",
        Headers = headers,
        Body = encodedData
    })

    if response.Success then
        print("✅ Embed sent successfully!")
        data = {}
    else
        warn("❌ Failed to send embed: ", response.StatusMessage)
    end
end

return embedLib