
--// Services
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

--// Obsidian Initialization
-- Remove this section if Obsidian is already initialized.

local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()

local Window = Library:CreateWindow({
    Title = "Teleport Manager",
    Footer = "Custom Teleports",
})

--// Tab
local TeleportTab = Window:AddTab("Teleports", "map-pin")

--// Groupboxes
local CreateGroup = TeleportTab:AddGroupbox({
    Side = "Left",
    Name = "Create Teleport",
    IconName = "plus",
})

local ListGroup = TeleportTab:AddGroupbox({
    Side = "Right",
    Name = "Saved Teleports",
    IconName = "map-pin",
    MaxHeight = 400,
})

--// Teleport Storage
local Teleports = {}
local RenderedElements = {}

--// Utility Functions

local function GetRootPart()
    local Character = LocalPlayer.Character

    if not Character then
        return nil
    end

    local RootPart = Character:FindFirstChild("HumanoidRootPart")

    if RootPart and RootPart:IsA("BasePart") then
        return RootPart
    end

    return nil
end

local function FormatPosition(Position)
    return string.format(
        "%.6f, %.6f, %.6f",
        Position.X,
        Position.Y,
        Position.Z
    )
end

local function ParsePosition(Value)
    -- Expected format: X, Y, Z
    local X, Y, Z = Value:match(
        "^%s*([^,]+),%s*([^,]+),%s*([^,]+)%s*$"
    )

    if not X then
        return nil
    end

    X = tonumber(X)
    Y = tonumber(Y)
    Z = tonumber(Z)

    local function IsFinite(Number)
        return Number ~= nil
            and Number == Number
            and Number ~= math.huge
            and Number ~= -math.huge
    end

    if not IsFinite(X) or not IsFinite(Y) or not IsFinite(Z) then
        return nil
    end

    return Vector3.new(X, Y, Z)
end

local function TeleportTo(Position)
    local RootPart = GetRootPart()

    if not RootPart then
        warn("[Teleport] Character or HumanoidRootPart not found.")
        return
    end

    -- Preserve the player's current rotation.
    local Rotation = RootPart.CFrame - RootPart.Position

    RootPart.CFrame = CFrame.new(Position) * Rotation

    -- Prevent existing momentum from carrying over.
    RootPart.AssemblyLinearVelocity = Vector3.zero
    RootPart.AssemblyAngularVelocity = Vector3.zero
end

--// Dynamic UI Rendering

local function ClearTeleportList()
    for Index = #RenderedElements, 1, -1 do
        local Element = RenderedElements[Index]

        Element:Destroy()
        RenderedElements[Index] = nil
    end
end

local function RenderTeleportList()
    ClearTeleportList()

    -- Empty state
    if #Teleports == 0 then
        local EmptyLabel = ListGroup:AddLabel({
            Text = "No custom teleports created yet.",
            DoesWrap = true,
        })

        table.insert(RenderedElements, EmptyLabel)
        return
    end

    -- Generate an entry for each teleport.
    for Index, Entry in ipairs(Teleports) do
        local TeleportEntry = Entry

        if Index > 1 then
            local Divider = ListGroup:AddDivider()
            table.insert(RenderedElements, Divider)
        end

        -- Name and position
        local EntryLabel = ListGroup:AddLabel({
            Text = string.format(
                "%s\nPosition: %s",
                TeleportEntry.Name,
                FormatPosition(TeleportEntry.Position)
            ),
            DoesWrap = true,
        })

        table.insert(RenderedElements, EntryLabel)

        -- Teleport button
        local TeleportButton = ListGroup:AddButton({
            Text = "Teleport",
            Icon = "map-pin",

            Func = function()
                TeleportTo(TeleportEntry.Position)
            end,
        })

        table.insert(RenderedElements, TeleportButton)

        -- Optional remove sub-button
        TeleportButton:AddButton({
            Text = "Remove",
            Icon = "trash-2",
            Risky = true,

            Func = function()
                for Position, SavedEntry in ipairs(Teleports) do
                    if SavedEntry == TeleportEntry then
                        table.remove(Teleports, Position)
                        break
                    end
                end

                -- Rebuild after the current button callback finishes.
                task.defer(RenderTeleportList)
            end,
        })
    end
end

--// Creation Inputs

local NameInput = CreateGroup:AddInput("TeleportName", {
    Text = "Teleport Name",
    Placeholder = "Enter a name...",
    Default = "",
    ClearTextOnFocus = false,
})

local PositionInput = CreateGroup:AddInput("TeleportPosition", {
    Text = "Position (X, Y, Z)",
    Placeholder = "0, 10, 0",
    Default = "",
    ClearTextOnFocus = false,
})

--// Capture Current Position

CreateGroup:AddButton({
    Text = "Use Current Position",
    Icon = "crosshair",

    Func = function()
        local RootPart = GetRootPart()

        if not RootPart then
            warn("[Teleport] Character not found.")
            return
        end

        PositionInput:SetValue(FormatPosition(RootPart.Position))
    end,
})

--// Create Teleport

CreateGroup:AddButton({
    Text = "Create Teleport",
    Icon = "plus",

    Func = function()
        local Name = NameInput.Value:match("^%s*(.-)%s*$")

        if not Name or Name == "" then
            warn("[Teleport] Enter a teleport name.")
            return
        end

        local Position = ParsePosition(PositionInput.Value)

        if not Position then
            warn("[Teleport] Invalid position. Use X, Y, Z.")
            return
        end

        -- Store teleport.
        table.insert(Teleports, {
            Name = Name,
            Position = Position,
        })

        -- Reset name input.
        NameInput:SetValue("")

        -- Update saved entries.
        RenderTeleportList()

        print("[Teleport] Created:", Name, FormatPosition(Position))
    end,
})

--// Initial Rendering

RenderTeleportList()
