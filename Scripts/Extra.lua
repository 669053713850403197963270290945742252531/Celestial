local weaponDropdown = sections.playerSection1:Dropdown({
	Name = "Give Weapons",
	Search = true,
	Multi = true,
	Required = false,
	Options = {"AK-47", "M4A1", "Desert Eagle", "AWP", "MP5", "SPAS-12"},
	Default = {"M4A1", "AWP"},
	Callback = function(value)
		-- Value should now directly contain the weapon names
		print("Selected weapons:", table.concat(value, ", "))
	end,
}, "weaponDropdown")

sections.playerSection1:Button({
	Name = "Give Weapon",
	Callback = function()
        if weaponDropdown.Value and type(weaponDropdown.Value) == "table" then
            for _, weaponName in ipairs(weaponDropdown.Value) do
                print("Fired event for weapon:", weaponName)
            end
        else
            print("No weapons selected or invalid value.")
        end
	end,
})





-- get label text

local playerCountLabel = sections.homeSection2:Label({ Text = "Active Players: " .. playerCount, Flag = "playerCountLabel"})
print(playerCountLabel.Settings.Text)




-- clip

local clipDirectionDropdown = sections.playerSection1:Dropdown({
	Name = "Clip Direction",
	Search = false,
	Multi = false,
	Required = true,
	Options = {"X (+)", "X (-)", "Y (+)", "Y (-)", "Z (+)", "Z (-)"},
	Default = 4,
	Callback = function(value) end,
}, "clipDirectionDropdown")

local clipAmountInput = sections.playerSection1:Input({
    Name = "Clip Amount",
    Placeholder = "Number (###)",
    AcceptedCharacters = "Numeric",
    Callback = function(text) end,
}, "clipAmountInput")

sections.playerSection1:Button({
	Name = "Clip",
	Callback = function()
        if #clipAmountInput:GetInput() > 3 then

            window:Dialog({
                Title = "Clip",
                Description = "Clip Amount input cannot be greater than 3 characters.",
                Buttons = {
                    {
                        Name = "Close"
                    }
                }
            })

            return
        end

        local clipDirection = clipDirectionDropdown.Value
        local clipAmount = tonumber(clipAmountInput:GetInput())

        if not clipAmount then -- If it failed to convert the clipAmount to a number
            return
        end

        local hrp = getHRP()

        if hrp then
            if clipDirection == "X (+)" then
                hrp.CFrame = hrp.CFrame + Vector3.new(clipAmount, 0, 0)
            elseif clipDirection == "X (-)" then
                hrp.CFrame = hrp.CFrame + Vector3.new(-clipAmount, 0, 0)
            elseif clipDirection == "Y (+)" then
                hrp.CFrame = hrp.CFrame + Vector3.new(0, clipAmount, 0)
            elseif clipDirection == "Y (-)" then
                hrp.CFrame = hrp.CFrame + Vector3.new(0, -clipAmount, 0)
            elseif clipDirection == "Z (+)" then
                hrp.CFrame = hrp.CFrame + Vector3.new(0, 0, clipAmount)
            elseif clipDirection == "Z (-)" then
                hrp.CFrame = hrp.CFrame + Vector3.new(0, 0, -clipAmount)
            end
        end
	end,
})







-- shitty "asset updater"


sections.miscSection1:Button({
	Name = "Update Assets",
	Callback = function()
        window:Dialog({
            Title = "Update Assets",
            Description = "Are you sure? This action is irreversible and will overwrite the current assets.",
            Buttons = {
                {
                    Name = "Confirm",
                    Callback = function()
                        assetLib.updateFile("Celestial ScriptHub/Assets/Home.png", game:HttpGet("https://gitlab.com/scripts1463602/Celestial/-/raw/main/Assets/Home.png?ref_type=heads"))
                        assetLib.updateFile("Celestial ScriptHub/Assets/Player.png", game:HttpGet("https://gitlab.com/scripts1463602/Celestial/-/raw/main/Assets/Player.png?ref_type=heads"))
                        assetLib.updateFile("Celestial ScriptHub/Assets/Settings.png", game:HttpGet("https://gitlab.com/scripts1463602/Celestial/-/raw/main/Assets/Settings.png"))
                        assetLib.updateFile("Celestial ScriptHub/Assets/Miscellaneous.png", game:HttpGet("https://gitlab.com/scripts1463602/Celestial/-/raw/main/Assets/Miscellaneous.png"))

                        if not assetLib.errored then
                            notify("Assets updated", "Successfully updated assets.", 5, "Success")
                        else
                            notify("Asset update failed", "Failed to update assets: " .. assetLib.errorMsg .. ". Check the console for more information.", 5, "Error")
                        end
                    end,
                },

                {
                    Name = "Cancel"
                }
            }
        })
	end,
})




-- multi dropdown




local notificationTypeDropdown = sections.miscSection1:Dropdown({
    Name = "Notification",
    Search = false,
    Multi = true,
    Required = true,
    Options = {"Neutral", "Success", "Error"},
    Default = {"Neutral"},    
    Callback = function(value) end,
}, "notificationTypeDropdown")

local notificationDurationInput
notificationDurationInput = sections.miscSection1:Input({
    Name = "Notification Duration",
    Placeholder = "Number (##)",
    AcceptedCharacters = "Numeric",
    Callback = function(text) end,
}, "notificationDurationInput")

sections.miscSection1:Button({
    Name = "Send Notification",
    Callback = function()
        if not tonumber(notificationDurationInput:GetInput()) or #notificationDurationInput:GetInput() > 2 then
            window:Dialog({
                Title = "Send Notification",
                Description = "Notification Duration input must be a valid number and cannot exceed 2 characters.",
                Buttons = {
                    {
                        Name = "Close"
                    }
                }
            })

            return
        end
        
        for notifType, isSelected in pairs(notificationTypeDropdown:GetOptions()) do
            if isSelected then
                print("Running code for selected notification type:", notifType)
                print(notifType)
                notify("Title", "Content", tonumber(durationInput), notifType)
                task.wait(0.5)
            end
        end
    end,
})





-- notification testing




sections.miscSection1:Divider()

local notificationTypeDropdown = sections.miscSection1:Dropdown({
    Name = "Notification",
    Search = false,
    Multi = true,
    Required = true,
    Options = {"Neutral", "Success", "Error", "Hint"},
    Default = {"Neutral"},    
    Callback = function(value) end,
}, "notificationTypeDropdown")

local notificationDurationInput
notificationDurationInput = sections.miscSection1:Input({
    Name = "Notification Duration",
    Placeholder = "Number (##)",
    AcceptedCharacters = "Numeric",
    Callback = function(text) end,
}, "notificationDurationInput")

sections.miscSection1:Button({
    Name = "Send Notification",
    Callback = function()
        local durationInput = tonumber(notificationDurationInput:GetInput())

        if not durationInput or #notificationDurationInput:GetInput() > 2 then
            window:Dialog({
                Title = "Send Notification",
                Description = "Notification Duration input must be a valid number and cannot exceed 2 characters.",
                Buttons = {
                    {
                        Name = "Close"
                    }
                }
            })

            return
        end
        
        for notifType, isSelected in pairs(notificationTypeDropdown:GetOptions()) do
            if isSelected then
                notify("Title", "Content", durationInput, notifType)
                task.wait(0.5)
            end
        end
    end,
})









-- divider styles



-- =================================================
--                   TAB: HOME                   --
-- =================================================

-------------------------------------
-- Section: User Information  --
-------------------------------------