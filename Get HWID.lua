-- ── Config ──────────────────────────────────
local CONFIG = {
    Title          = "HWID Viewer",
    AccentColor    = Color3.fromRGB(99, 102, 241),
    BgColor        = Color3.fromRGB(15, 15, 20),
    SurfaceColor   = Color3.fromRGB(24, 24, 32),
    BorderColor    = Color3.fromRGB(45, 45, 60),
    TextColor      = Color3.fromRGB(220, 220, 235),
    SubTextColor   = Color3.fromRGB(110, 110, 140),
    SuccessColor   = Color3.fromRGB(52, 211, 153),
    SuccessSound   = true,
    SuccessSoundId = "rbxassetid://3318713980",
}

-- ── Icons ────────────────────────────────────
local ICONS = {
    Copy     = "rbxassetid://131915844226323",  -- copy
    CopyDone = "rbxassetid://131007772158309",  -- checkmark
    Close    = "rbxassetid://129051827240219",  -- X mark
}

-- ── Fetch HWID ───────────────────────────────
getgenv()._celestial_noauth = true
local ok, auth = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/669053713850403197963270290945742252531/Celestial/refs/heads/main/Authentication.lua"))()
end)

local HWID
if ok and auth then
    local hok, hval = pcall(function() return auth.hwid("Hashed") end)
    HWID = (hok and hval) or "Error retrieving HWID"
else
    HWID = "Authentication module not found"
end

-- ── Services ─────────────────────────────────
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local SoundService     = game:GetService("SoundService")

-- ── Tween helper ─────────────────────────────
local function tween(obj, props, t, style, dir)
    style = style or Enum.EasingStyle.Quart
    dir   = dir   or Enum.EasingDirection.Out
    TweenService:Create(obj, TweenInfo.new(t or 0.25, style, dir), props):Play()
end

-- ── Root GUI ─────────────────────────────────
local hui    = gethui()
local screen = Instance.new("ScreenGui")
screen.Name           = "HWIDViewer"
screen.ResetOnSpawn   = false
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.IgnoreGuiInset = true
screen.Parent         = hui

-- Backdrop
local backdrop = Instance.new("Frame")
backdrop.Size                   = UDim2.fromScale(1, 1)
backdrop.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
backdrop.BackgroundTransparency = 1
backdrop.BorderSizePixel        = 0
backdrop.ZIndex                 = 1
backdrop.Parent                 = screen

-- ── Main window ──────────────────────────────
local WIN_W = 420
local window = Instance.new("Frame")
window.Size                   = UDim2.fromOffset(WIN_W, 0)
window.AutomaticSize          = Enum.AutomaticSize.Y
window.Position               = UDim2.fromScale(0.5, 0.5)
window.AnchorPoint            = Vector2.new(0.5, 0.5)
window.BackgroundColor3       = CONFIG.BgColor
window.BackgroundTransparency = 1
window.BorderSizePixel        = 0
window.ZIndex                 = 10
window.Parent                 = screen

do
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 12)
    c.Parent = window
end
do
    local s = Instance.new("UIStroke")
    s.Color     = CONFIG.BorderColor
    s.Thickness = 1.2
    s.Parent    = window
end

-- Accent bar
local accentBar = Instance.new("Frame")
accentBar.Size             = UDim2.new(1, 0, 0, 3)
accentBar.BackgroundColor3 = CONFIG.AccentColor
accentBar.BorderSizePixel  = 0
accentBar.ZIndex           = 11
accentBar.Parent           = window
Instance.new("UICorner", accentBar).CornerRadius = UDim.new(0, 12)

-- ── Title bar ────────────────────────────────
local titleBar = Instance.new("Frame")
titleBar.Size                   = UDim2.new(1, 0, 0, 48)
titleBar.BackgroundTransparency = 1
titleBar.ZIndex                 = 11
titleBar.Parent                 = window

-- Small accent dot
local dot = Instance.new("Frame")
dot.Size             = UDim2.fromOffset(10, 10)
dot.AnchorPoint      = Vector2.new(0, 0.5)
dot.Position         = UDim2.new(0, 18, 0.5, 0)
dot.BackgroundColor3 = CONFIG.AccentColor
dot.BorderSizePixel  = 0
dot.ZIndex           = 12
dot.Parent           = titleBar
Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size                   = UDim2.new(1, -80, 1, 0)
titleLabel.Position               = UDim2.fromOffset(36, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Font                   = Enum.Font.GothamBold
titleLabel.TextSize               = 15
titleLabel.TextColor3             = CONFIG.TextColor
titleLabel.Text                   = CONFIG.Title
titleLabel.TextXAlignment         = Enum.TextXAlignment.Left
titleLabel.ZIndex                 = 12
titleLabel.Parent                 = titleBar

-- ── Close button ─────────────────────────────
local closeBtn = Instance.new("TextButton")
closeBtn.Size             = UDim2.fromOffset(28, 28)
closeBtn.Position         = UDim2.new(1, -38, 0, 10)
closeBtn.BackgroundColor3 = Color3.fromRGB(60, 40, 50)
closeBtn.BorderSizePixel  = 0
closeBtn.Text             = ""
closeBtn.AutoButtonColor  = false
closeBtn.ZIndex           = 12
closeBtn.Parent           = titleBar
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

local closeIcon = Instance.new("ImageLabel")
closeIcon.Size                   = UDim2.fromOffset(14, 14)
closeIcon.AnchorPoint            = Vector2.new(0.5, 0.5)
closeIcon.Position               = UDim2.fromScale(0.5, 0.5)
closeIcon.BackgroundTransparency = 1
closeIcon.Image                  = ICONS.Close
closeIcon.ImageColor3            = Color3.fromRGB(220, 100, 100)
closeIcon.ScaleType              = Enum.ScaleType.Fit
closeIcon.ZIndex                 = 13
closeIcon.Parent                 = closeBtn

closeBtn.MouseEnter:Connect(function()
    tween(closeBtn,  {BackgroundColor3 = Color3.fromRGB(200, 60, 70)}, 0.15)
    tween(closeIcon, {ImageColor3      = Color3.fromRGB(255, 255, 255)}, 0.15)
end)
closeBtn.MouseLeave:Connect(function()
    tween(closeBtn,  {BackgroundColor3 = Color3.fromRGB(60, 40, 50)}, 0.15)
    tween(closeIcon, {ImageColor3      = Color3.fromRGB(220, 100, 100)}, 0.15)
end)
closeBtn.MouseButton1Click:Connect(function()
    local curH = window.AbsoluteSize.Y
    window.AutomaticSize = Enum.AutomaticSize.None
    window.Size = UDim2.fromOffset(WIN_W, curH)
    task.defer(function()
        tween(window,   {Size = UDim2.fromOffset(WIN_W, 0)}, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        tween(backdrop, {BackgroundTransparency = 1}, 0.2)
        task.delay(0.22, function() screen:Destroy() end)
    end)
end)

-- ── Divider ───────────────────────────────────
local divider = Instance.new("Frame")
divider.Size             = UDim2.new(1, -36, 0, 1)
divider.Position         = UDim2.fromOffset(18, 50)
divider.BackgroundColor3 = CONFIG.BorderColor
divider.BorderSizePixel  = 0
divider.ZIndex           = 11
divider.Parent           = window

-- ── Sub-label ────────────────────────────────
local subLabel = Instance.new("TextLabel")
subLabel.Size                   = UDim2.new(1, -36, 0, 20)
subLabel.Position               = UDim2.fromOffset(18, 62)
subLabel.BackgroundTransparency = 1
subLabel.Font                   = Enum.Font.Gotham
subLabel.TextSize               = 11
subLabel.TextColor3             = CONFIG.SubTextColor
subLabel.Text                   = "YOUR HASHED HWID"
subLabel.TextXAlignment         = Enum.TextXAlignment.Left
subLabel.ZIndex                 = 11
subLabel.Parent                 = window

-- ── HWID box (auto-height, wrapping) ─────────
local hwidBox = Instance.new("Frame")
hwidBox.Size             = UDim2.new(1, -36, 0, 0)
hwidBox.Position         = UDim2.fromOffset(18, 85)
hwidBox.AutomaticSize    = Enum.AutomaticSize.Y
hwidBox.BackgroundColor3 = CONFIG.SurfaceColor
hwidBox.BorderSizePixel  = 0
hwidBox.ZIndex           = 11
hwidBox.Parent           = window
Instance.new("UICorner", hwidBox).CornerRadius = UDim.new(0, 8)
do
    local s = Instance.new("UIStroke")
    s.Color     = CONFIG.BorderColor
    s.Thickness = 1
    s.Parent    = hwidBox
end
do
    local p = Instance.new("UIPadding")
    p.PaddingLeft   = UDim.new(0, 12)
    p.PaddingRight  = UDim.new(0, 12)
    p.PaddingTop    = UDim.new(0, 10)
    p.PaddingBottom = UDim.new(0, 10)
    p.Parent        = hwidBox
end

local hwidText = Instance.new("TextLabel")
hwidText.Size                   = UDim2.new(1, 0, 0, 0)
hwidText.AutomaticSize          = Enum.AutomaticSize.Y
hwidText.BackgroundTransparency = 1
hwidText.Font                   = Enum.Font.Code
hwidText.TextSize               = 13
hwidText.TextColor3             = CONFIG.AccentColor
hwidText.Text                   = HWID
hwidText.TextXAlignment         = Enum.TextXAlignment.Left
hwidText.TextYAlignment         = Enum.TextYAlignment.Top
hwidText.TextWrapped            = true
hwidText.RichText               = false
hwidText.ZIndex                 = 12
hwidText.Parent                 = hwidBox

-- ── Copy button ───────────────────────────────
local COPY_TOP_MARGIN = 10
local COPY_H          = 36
local HWIDBOX_TOP     = 85

local windowPad = Instance.new("UIPadding")
windowPad.PaddingBottom = UDim.new(0, 18)
windowPad.Parent        = window

local copyBtn = Instance.new("TextButton")
copyBtn.Size             = UDim2.new(1, -36, 0, COPY_H)
copyBtn.Position         = UDim2.fromOffset(18, HWIDBOX_TOP)
copyBtn.BackgroundColor3 = CONFIG.AccentColor
copyBtn.BorderSizePixel  = 0
copyBtn.Text             = ""
copyBtn.AutoButtonColor  = false
copyBtn.ZIndex           = 11
copyBtn.Parent           = window
Instance.new("UICorner", copyBtn).CornerRadius = UDim.new(0, 8)

-- Centered row container: icon sits directly beside label
local copyInner = Instance.new("Frame")
copyInner.Size                   = UDim2.fromScale(1, 1)
copyInner.BackgroundTransparency = 1
copyInner.ZIndex                 = 12
copyInner.Parent                 = copyBtn

local copyLayout = Instance.new("UIListLayout")
copyLayout.FillDirection       = Enum.FillDirection.Horizontal
copyLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
copyLayout.VerticalAlignment   = Enum.VerticalAlignment.Center
copyLayout.Padding             = UDim.new(0, 6)
copyLayout.SortOrder           = Enum.SortOrder.LayoutOrder
copyLayout.Parent              = copyInner

local copyIcon = Instance.new("ImageLabel")
copyIcon.Size                   = UDim2.fromOffset(16, 16)
copyIcon.BackgroundTransparency = 1
copyIcon.Image                  = ICONS.Copy
copyIcon.ImageColor3            = Color3.fromRGB(255, 255, 255)
copyIcon.ScaleType              = Enum.ScaleType.Fit
copyIcon.ZIndex                 = 13
copyIcon.LayoutOrder            = 1
copyIcon.Parent                 = copyInner

local copyLabel = Instance.new("TextLabel")
copyLabel.Size                   = UDim2.fromOffset(0, COPY_H)
copyLabel.AutomaticSize          = Enum.AutomaticSize.X
copyLabel.BackgroundTransparency = 1
copyLabel.Font                   = Enum.Font.GothamSemibold
copyLabel.TextSize               = 13
copyLabel.TextColor3             = Color3.fromRGB(255, 255, 255)
copyLabel.Text                   = "Copy HWID"
copyLabel.ZIndex                 = 13
copyLabel.LayoutOrder            = 2
copyLabel.Parent                 = copyInner

-- Dynamic Y position (tracks hwidBox height)
local function updateCopyPos()
    local boxH = hwidBox.AbsoluteSize.Y
    copyBtn.Position = UDim2.fromOffset(18, HWIDBOX_TOP + boxH + COPY_TOP_MARGIN)
end

hwidBox:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateCopyPos)
task.defer(updateCopyPos)

-- Hover
copyBtn.MouseEnter:Connect(function()
    tween(copyBtn, {BackgroundColor3 = Color3.fromRGB(129, 132, 255)}, 0.15)
end)
copyBtn.MouseLeave:Connect(function()
    tween(copyBtn, {BackgroundColor3 = CONFIG.AccentColor}, 0.15)
end)

-- Click
copyBtn.MouseButton1Click:Connect(function()
    setclipboard(HWID)

    tween(copyBtn, {BackgroundColor3 = CONFIG.SuccessColor}, 0.12)
    copyLabel.Text       = "Copied!"
    copyIcon.Image       = ICONS.CopyDone

    if CONFIG.SuccessSound then
        local snd = Instance.new("Sound")
        snd.SoundId = CONFIG.SuccessSoundId
        snd.Volume  = 0.6
        snd.Parent  = SoundService
        snd:Play()
        game:GetService("Debris"):AddItem(snd, 3)
    end

    task.delay(1.4, function()
        tween(copyBtn, {BackgroundColor3 = CONFIG.AccentColor}, 0.25)
        copyLabel.Text = "Copy HWID"
        copyIcon.Image = ICONS.Copy
    end)
end)

-- ── Drag logic ────────────────────────────────
do
    local dragging, dragStart, startPos = false, nil, nil

    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging  = true
            dragStart = input.Position
            startPos  = window.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            window.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

-- ── Entry animation ───────────────────────────
tween(backdrop, {BackgroundTransparency = 0.45}, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
tween(window,   {BackgroundTransparency = 0},    0.2,  Enum.EasingStyle.Quad, Enum.EasingDirection.Out)