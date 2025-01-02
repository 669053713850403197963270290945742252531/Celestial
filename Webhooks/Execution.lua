local webhookUrl = "https://discord.com/api/webhooks/1281779439293960192/hp7PavVKiUOdIVc1AiB6EBKgwfbFrc00pvsBC-RJYrePn4CaRDKsrqk9QM15imHpiWzX"
local utils = loadstring(game:HttpGet("https://raw.githubusercontent.com/669053713850403197963270290945742252531/Celestial/main/Utilities.lua"))()

local player = game:GetService("Players").LocalPlayer
local httpService = game:GetService("HttpService")

local gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
local hwid = game:GetService("RbxAnalyticsService"):GetClientId()

-- Global Variables

local owner = false
local robloxPremium = false
local altAccount = false





-- Owner check







-- Fetch whitelist

local function fetchWhitelist(url)
    local success, response = pcall(function()
        return game:HttpGet(url)
    end)

    if success then
        local successDecode, whitelistData = pcall(function()
            return httpService:JSONDecode(response)
        end)

        if successDecode then
            return whitelistData
        else
            player:Kick("Failed to decode JSON. Response may be malformed.")
        end
    else
        player:Kick("Failed to fetch whitelist. Error: " .. tostring(response))
    end
    return nil
end

-- Fetch whitelist URL

local whitelistURL = "https://raw.githubusercontent.com/669053713850403197963270290945742252531/Celestial/refs/heads/main/Users.json"
local whitelistedUsers = fetchWhitelist(whitelistURL)

if not whitelistedUsers then
    player:Kick("Whitelist retrieval failed. Check your URL and JSON formatting.")
    return
end

-- Owner check

local function isOwner(hwid, whitelist)
    for _, user in ipairs(whitelist) do
        if user.HWID == hwid and user.Rank == "Owner" then
            return true, user
        end
    end
    return false, nil
end

local owner = isOwner(hwid, whitelistedUsers) -- Set owner







-- Premium check

if player.MembershipType == Enum.MembershipType.Premium then
    robloxPremium = true
else
    robloxPremium = false
end

-- Alt detection

if player.AccountAge >= 30 then
    altAccount = false
else
    altAccount = true
end


-- Embed


local data = {
    embeds = {
        {
            title = "**__Celestial has been executed__**",
            type = "rich",
            color = tonumber(2752256),
            fields = {
                {
                    name = "Execution Date",
                    value = "**" .. os.date("%x") .. " | " .. utils.getTime(true) .. os.date(" %p") .. "**",
                    inline = true
                },

                -- Account Info Section

                {
                    name = "",
                    value = "[**" .. player.DisplayName .. "**'s Profile](https://roblox.com/users/" .. player.UserId .. "/profile)",
                    inline = true
                },
                
                {
                    name = "=================== Account =====================",
                    value = "",
                    inline = false
                },

                {
                    name = "Display Name",
                    value = player.DisplayName,
                    inline = true
                },

                {
                    name = "Username",
                    value = player.Name,
                    inline = true
                },
                
                {
                    name = "User ID",
                    value = player.UserId,
                    inline = true
                },
    
                {
                    name = "Account Age",
                    value = player.AccountAge .. " Days",
                    inline = true
                },

                {
                    name = "Owner",
                    value = owner,
                    inline = true
                },

                {
                    name = "Roblox Premium",
                    value = tostring(robloxPremium),
                    inline = true
                },
                
                {
                    name = "Alt Account",
                    value = altAccount,
                    inline = true
                },

                -- Game Info Section

                {
                    name = "=================== Game =====================",
                    value = "",
                    inline = false
                },

                {
                    name = "",
                    value = "[Game Page](https://www.roblox.com/games/" .. game.PlaceId .. ")",
                    inline = true
                },

                {
                    name = "Game Name",
                    value = gameName,
                    inline = true
                },

                {
                    name = "Place ID",
                    value = game.PlaceId,
                    inline = true
                },

                {
                    name = "Server Join Code",
                    value = "```" .. [[game:GetService("TeleportService")]] .. ":TeleportToPlaceInstance(" .. game.PlaceId..", '" .. game.JobId.."')" .. "```",
                    inline = true
                },

                -- Miscellaneous Section
                
                {
                    name = "=================== Miscellaneous =====================",
                    value = "",
                    inline = false
                },

                {
                    name = "Exploit",
                    value = identifyexecutor(),
                    inline = true
                },

                {
                    name = "HWID",
                    value = "||" .. hwid .. "||",
                    inline = true
                },
               }
           }
       }
    }

    local encodedData = httpService:JSONEncode(data)

    local headers = {
        ["content-type"] = "application/json"
     }

     local args = {Url = webhookUrl, Body = encodedData, Method = "POST", Headers = headers}
     request(args)