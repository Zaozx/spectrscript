-- ⚠️ IMPORTANT: Put this code at the VERY TOP of your Main Script (before obfuscating) ⚠️
local ProtectionConfig = {
    SecretKey = "Spectr",
    HubName = "Spectr"
}
if not _G[ProtectionConfig.SecretKey] then
    local player = game:GetService("Players").LocalPlayer
    if player then
        player:Kick("\n🛡️ Unauthorized Execution 🛡️\n\nPlease use the official Key System to run " .. ProtectionConfig.HubName)
    end
    return
end
print(ProtectionConfig.HubName .. " Loaded Successfully!")

-- // Spectr Script - Sidebar Tab UI \\ --
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")

-- ================== CORE FEATURES ==================
local SpawnPosition = Vector3.new(0, 497.5, 4000)
local SpawnExclusionDistance = 60

local Highlights = {}
local NameLabels = {}
local ESPEnabled = false
local PlayerCountText = nil

local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 2
FOVCircle.NumSides = 64
FOVCircle.Color = Color3.fromRGB(255, 255, 255)
FOVCircle.Transparency = 0.7
FOVCircle.Filled = false
FOVCircle.Visible = false

local AimbotEnabled = false
local AimFOV = 150
local Smoothing = 0.2
local AimPart = "Head"

local AutoTapEnabled = false
local TapSpeed = 0.05

local TapConnection = nil
local AimbotConnection = nil

local function IsAtSpawn(character)
    if not character or not character:FindFirstChild("HumanoidRootPart") then return false end
    return (character.HumanoidRootPart.Position - SpawnPosition).Magnitude < SpawnExclusionDistance
end

local function IsVisible(targetCharacter)
    if not targetCharacter then return false end
    local checkPart = targetCharacter:FindFirstChild(AimPart) or targetCharacter:FindFirstChild("Head")
    if not checkPart then return false end
    local direction = (checkPart.Position - Camera.CFrame.Position).Unit
    local distance = (checkPart.Position - Camera.CFrame.Position).Magnitude
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character or {}}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    local result = workspace:Raycast(Camera.CFrame.Position, direction * (distance + 10), raycastParams)
    return result == nil or result.Instance:IsDescendantOf(targetCharacter)
end

local function CreateESPForCharacter(character, player)
    if not character or Highlights[character] then return end
    if not character:FindFirstChild("HumanoidRootPart") or not character:FindFirstChild("Head") then return end
    local highlight = Instance.new("Highlight")
    highlight.FillColor = Color3.fromRGB(255, 0, 0)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.4
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Adornee = character
    highlight.Parent = character
    Highlights[character] = highlight
    local head = character:FindFirstChild("Head")
    if head then
        local billboard = Instance.new("BillboardGui")
        billboard.Adornee = head
        billboard.Size = UDim2.new(0, 200, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.AlwaysOnTop = true
        billboard.Parent = character
        local textLabel = Instance.new("TextLabel")
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.Text = player.Name
        textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        textLabel.TextStrokeTransparency = 0
        textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        textLabel.Font = Enum.Font.GothamBold
        textLabel.TextSize = 16
        textLabel.Parent = billboard
        NameLabels[character] = billboard
    end
end

local function UpdateESP()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and not Highlights[plr.Character] then
            if not IsAtSpawn(plr.Character) then
                CreateESPForCharacter(plr.Character, plr)
            end
        end
    end
    for character, highlight in pairs(Highlights) do
        if not character or not character.Parent or not character:FindFirstChild("HumanoidRootPart") then
            if highlight then highlight:Destroy() end
            if NameLabels[character] then NameLabels[character]:Destroy() end
            Highlights[character] = nil
            NameLabels[character] = nil
            continue
        end
        if IsAtSpawn(character) then
            if highlight then highlight:Destroy() end
            if NameLabels[character] then NameLabels[character]:Destroy() end
            Highlights[character] = nil
            NameLabels[character] = nil
            continue
        end
        local isVis = IsVisible(character)
        highlight.FillColor = isVis and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
    end
end

local function ToggleESP(state)
    ESPEnabled = state
    if state then
        if not PlayerCountText then
            local sg = Instance.new("ScreenGui")
            sg.ResetOnSpawn = false
            sg.Parent = LocalPlayer:WaitForChild("PlayerGui")
            PlayerCountText = Instance.new("TextLabel")
            PlayerCountText.Size = UDim2.new(0, 280, 0, 40)
            PlayerCountText.Position = UDim2.new(0.5, -140, 0, 15)
            PlayerCountText.BackgroundTransparency = 0.6
            PlayerCountText.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            PlayerCountText.TextColor3 = Color3.fromRGB(255, 255, 255)
            PlayerCountText.TextStrokeTransparency = 0
            PlayerCountText.Font = Enum.Font.GothamBold
            PlayerCountText.TextSize = 16
            PlayerCountText.Text = "Players in ESP: 0"
            PlayerCountText.Parent = sg
        end
        RunService:BindToRenderStep("SpectrESP", Enum.RenderPriority.Camera.Value + 5, UpdateESP)
    else
        RunService:UnbindFromRenderStep("SpectrESP")
        for _, hl in pairs(Highlights) do if hl then hl:Destroy() end end
        for _, lbl in pairs(NameLabels) do if lbl then lbl:Destroy() end end
        Highlights = {}
        NameLabels = {}
        if PlayerCountText then PlayerCountText.Parent:Destroy() PlayerCountText = nil end
    end
end

local function StartAutoTapper()
    if TapConnection then return end
    TapConnection = RunService.Heartbeat:Connect(function()
        if not AutoTapEnabled or not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then return end
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Q, false, game)
        task.wait(TapSpeed)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Q, false, game)
        task.wait(TapSpeed)
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.One, false, game)
        task.wait(TapSpeed)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.One, false, game)
    end)
end

local function StopAutoTapper()
    if TapConnection then TapConnection:Disconnect() TapConnection = nil end
end

local function UpdateFOVCircle()
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    FOVCircle.Radius = AimFOV
end

local function GetClosestPlayer()
    local closest, shortest = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer or not plr.Character then continue end
        local char = plr.Character
        local part = char:FindFirstChild(AimPart)
        if not part or IsAtSpawn(char) then continue end
        local screen, onScreen = Camera:WorldToScreenPoint(part.Position)
        if onScreen then
            local dist = (Vector2.new(screen.X, screen.Y) - Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)).Magnitude
            if dist < AimFOV and dist < shortest then
                shortest = dist
                closest = plr
            end
        end
    end
    return closest
end

local function StartAimbot()
    if AimbotConnection then return end
    AimbotConnection = RunService.RenderStepped:Connect(function()
        UpdateFOVCircle()
        if not AimbotEnabled then return end
        local target = GetClosestPlayer()
        if target and target.Character and target.Character:FindFirstChild(AimPart) then
            local targetPos = target.Character[AimPart].Position
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, targetPos), Smoothing)
        end
    end)
end

local function StopAimbot()
    if AimbotConnection then AimbotConnection:Disconnect() AimbotConnection = nil end
    FOVCircle.Visible = false
end

-- ================== UI HELPERS ==================
local COLOR_BG        = Color3.fromRGB(10, 10, 10)
local COLOR_SIDEBAR   = Color3.fromRGB(14, 14, 14)
local COLOR_TITLEBAR  = Color3.fromRGB(14, 14, 14)
local COLOR_CONTENT   = Color3.fromRGB(8, 8, 8)
local COLOR_TAB_IDLE  = Color3.fromRGB(14, 14, 14)
local COLOR_TAB_HOVER = Color3.fromRGB(22, 22, 22)
local COLOR_TAB_ACTIVE= Color3.fromRGB(28, 28, 28)
local COLOR_DIVIDER   = Color3.fromRGB(35, 35, 35)
local COLOR_CARD      = Color3.fromRGB(22, 22, 22)
local COLOR_WHITE     = Color3.fromRGB(255, 255, 255)
local COLOR_SUBTEXT   = Color3.fromRGB(160, 160, 160)
local COLOR_TOGGLE_ON = Color3.fromRGB(255, 255, 255)
local COLOR_TOGGLE_OFF= Color3.fromRGB(50, 50, 55)
local COLOR_TRACK     = Color3.fromRGB(40, 40, 45)

-- ================== SCREEN GUI ==================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- ================== MAIN FRAME ==================
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 740, 0, 500)
MainFrame.Position = UDim2.new(0.5, -370, 0.5, -250)
MainFrame.BackgroundColor3 = COLOR_BG
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 14)
MainCorner.Parent = MainFrame

-- ================== TITLE BAR ==================
local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 56)
TitleBar.Position = UDim2.new(0, 0, 0, 0)
TitleBar.BackgroundColor3 = COLOR_TITLEBAR
TitleBar.BorderSizePixel = 0
TitleBar.ZIndex = 6
TitleBar.Parent = MainFrame

-- Bottom border under title bar
local TitleDivider = Instance.new("Frame")
TitleDivider.Size = UDim2.new(1, 0, 0, 1)
TitleDivider.Position = UDim2.new(0, 0, 1, -1)
TitleDivider.BackgroundColor3 = COLOR_DIVIDER
TitleDivider.BorderSizePixel = 0
TitleDivider.ZIndex = 7
TitleDivider.Parent = TitleBar

-- Logo image
local TitleLogo = Instance.new("ImageLabel")
TitleLogo.Size = UDim2.new(0, 38, 0, 38)
TitleLogo.Position = UDim2.new(0, 14, 0.5, -19)
TitleLogo.BackgroundTransparency = 1
TitleLogo.Image = "rbxassetid://118374262825356"
TitleLogo.ScaleType = Enum.ScaleType.Fit
TitleLogo.ZIndex = 7
TitleLogo.Parent = TitleBar

-- Title text
local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(0, 200, 1, 0)
TitleText.Position = UDim2.new(0, 60, 0, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text = "Spectr Script"
TitleText.TextColor3 = COLOR_WHITE
TitleText.Font = Enum.Font.GothamBold
TitleText.TextSize = 20
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.ZIndex = 7
TitleText.Parent = TitleBar

-- Minimize button
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 34, 0, 34)
MinBtn.Position = UDim2.new(1, -80, 0.5, -17)
MinBtn.BackgroundTransparency = 1
MinBtn.Text = "–"
MinBtn.TextColor3 = COLOR_SUBTEXT
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 22
MinBtn.ZIndex = 7
MinBtn.Parent = TitleBar

-- Close button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 34, 0, 34)
CloseBtn.Position = UDim2.new(1, -42, 0.5, -17)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 26
CloseBtn.ZIndex = 7
CloseBtn.Parent = TitleBar

-- ================== SIDEBAR ==================
local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, 200, 1, -56)
Sidebar.Position = UDim2.new(0, 0, 0, 56)
Sidebar.BackgroundColor3 = COLOR_SIDEBAR
Sidebar.BorderSizePixel = 0
Sidebar.ZIndex = 5
Sidebar.Parent = MainFrame

-- Sidebar right divider
local SidebarDivider = Instance.new("Frame")
SidebarDivider.Size = UDim2.new(0, 1, 1, 0)
SidebarDivider.Position = UDim2.new(1, -1, 0, 0)
SidebarDivider.BackgroundColor3 = COLOR_DIVIDER
SidebarDivider.BorderSizePixel = 0
SidebarDivider.ZIndex = 6
SidebarDivider.Parent = Sidebar

local SidebarLayout = Instance.new("UIListLayout")
SidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
SidebarLayout.Padding = UDim.new(0, 0)
SidebarLayout.Parent = Sidebar

-- ================== CONTENT AREA ==================
local ContentArea = Instance.new("Frame")
ContentArea.Name = "ContentArea"
ContentArea.Size = UDim2.new(1, -200, 1, -56)
ContentArea.Position = UDim2.new(0, 200, 0, 56)
ContentArea.BackgroundColor3 = COLOR_CONTENT
ContentArea.BorderSizePixel = 0
ContentArea.ZIndex = 4
ContentArea.Parent = MainFrame

-- Watermark logo
local WatermarkLabel = Instance.new("TextLabel")
WatermarkLabel.Name = "Watermark"
WatermarkLabel.Size = UDim2.new(1, 0, 1, 0)
WatermarkLabel.Position = UDim2.new(0, 0, 0, 0)
WatermarkLabel.BackgroundTransparency = 1
WatermarkLabel.TextColor3 = COLOR_WHITE
WatermarkLabel.TextTransparency = 0.91
WatermarkLabel.Text = "SPECTR"
WatermarkLabel.Font = Enum.Font.GothamBlack
WatermarkLabel.TextSize = 120
WatermarkLabel.ZIndex = 5
WatermarkLabel.Parent = ContentArea

-- ================== TAB PAGES ==================
local TabPages = {}
local TabButtons = {}
local ActiveTabName = nil

local function CreatePage(name)
    local page = Instance.new("ScrollingFrame")
    page.Name = name .. "Page"
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = Color3.fromRGB(55, 55, 55)
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Visible = false
    page.ZIndex = 6
    page.Parent = ContentArea

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 10)
    layout.Parent = page

    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 18)
    pad.PaddingBottom = UDim.new(0, 18)
    pad.PaddingLeft = UDim.new(0, 18)
    pad.PaddingRight = UDim.new(0, 18)
    pad.Parent = page

    return page
end

local function SetActiveTab(name)
    for tabName, btn in pairs(TabButtons) do
        if tabName == name then
            btn.BackgroundColor3 = COLOR_TAB_ACTIVE
            btn.TextColor3 = COLOR_WHITE
            -- Active indicator bar
            if btn:FindFirstChild("ActiveBar") then
                btn.ActiveBar.Visible = true
            end
        else
            btn.BackgroundColor3 = COLOR_TAB_IDLE
            btn.TextColor3 = COLOR_SUBTEXT
            if btn:FindFirstChild("ActiveBar") then
                btn.ActiveBar.Visible = false
            end
        end
    end
    for pageName, page in pairs(TabPages) do
        page.Visible = (pageName == name)
    end
    WatermarkLabel.Visible = (name == nil)
    ActiveTabName = name
end

-- Build sidebar tab buttons
local tabDefs = {
    { name = "Esp",    order = 1 },
    { name = "Aimbot", order = 2 },
    { name = "Macro",  order = 3 },
}

for _, def in ipairs(tabDefs) do
    local page = CreatePage(def.name)
    TabPages[def.name] = page

    local btn = Instance.new("TextButton")
    btn.Name = def.name .. "Tab"
    btn.Size = UDim2.new(1, 0, 0, 64)
    btn.BackgroundColor3 = COLOR_TAB_IDLE
    btn.BorderSizePixel = 0
    btn.Text = def.name
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 18
    btn.TextColor3 = COLOR_SUBTEXT
    btn.LayoutOrder = def.order
    btn.ZIndex = 6
    btn.Parent = Sidebar

    -- Bottom divider on each tab
    local tabDivider = Instance.new("Frame")
    tabDivider.Name = "Divider"
    tabDivider.Size = UDim2.new(1, 0, 0, 1)
    tabDivider.Position = UDim2.new(0, 0, 1, -1)
    tabDivider.BackgroundColor3 = COLOR_DIVIDER
    tabDivider.BorderSizePixel = 0
    tabDivider.ZIndex = 7
    tabDivider.Parent = btn

    -- Left active indicator bar
    local activeBar = Instance.new("Frame")
    activeBar.Name = "ActiveBar"
    activeBar.Size = UDim2.new(0, 3, 0.55, 0)
    activeBar.Position = UDim2.new(0, 0, 0.225, 0)
    activeBar.BackgroundColor3 = COLOR_WHITE
    activeBar.BorderSizePixel = 0
    activeBar.Visible = false
    activeBar.ZIndex = 8
    activeBar.Parent = btn

    local activeBarCorner = Instance.new("UICorner")
    activeBarCorner.CornerRadius = UDim.new(1, 0)
    activeBarCorner.Parent = activeBar

    -- Hover tween
    btn.MouseEnter:Connect(function()
        if ActiveTabName ~= def.name then
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = COLOR_TAB_HOVER}):Play()
        end
    end)
    btn.MouseLeave:Connect(function()
        if ActiveTabName ~= def.name then
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = COLOR_TAB_IDLE}):Play()
        end
    end)

    btn.MouseButton1Click:Connect(function()
        SetActiveTab(def.name)
    end)

    TabButtons[def.name] = btn
end

-- ================== UI COMPONENTS ==================

local function AddSectionLabel(page, text)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 22)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = COLOR_SUBTEXT
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 7
    lbl.Parent = page
end

local function AddToggle(page, name, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 54)
    frame.BackgroundColor3 = COLOR_CARD
    frame.BorderSizePixel = 0
    frame.ZIndex = 7
    frame.Parent = page
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 9)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -100, 1, 0)
    label.Position = UDim2.new(0, 16, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(225, 225, 225)
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 15
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 8
    label.Parent = frame

    local state = default
    -- Toggle pill
    local pill = Instance.new("Frame")
    pill.Size = UDim2.new(0, 52, 0, 28)
    pill.Position = UDim2.new(1, -68, 0.5, -14)
    pill.BackgroundColor3 = state and COLOR_TOGGLE_ON or COLOR_TOGGLE_OFF
    pill.BorderSizePixel = 0
    pill.ZIndex = 8
    pill.Parent = frame
    Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 22, 0, 22)
    knob.Position = state and UDim2.new(1, -25, 0.5, -11) or UDim2.new(0, 3, 0.5, -11)
    knob.BackgroundColor3 = state and Color3.fromRGB(10, 10, 10) or Color3.fromRGB(130, 130, 130)
    knob.BorderSizePixel = 0
    knob.ZIndex = 9
    knob.Parent = pill
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.ZIndex = 10
    btn.Parent = frame

    btn.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(pill, TweenInfo.new(0.18), {
            BackgroundColor3 = state and COLOR_TOGGLE_ON or COLOR_TOGGLE_OFF
        }):Play()
        TweenService:Create(knob, TweenInfo.new(0.18), {
            Position = state and UDim2.new(1, -25, 0.5, -11) or UDim2.new(0, 3, 0.5, -11),
            BackgroundColor3 = state and Color3.fromRGB(10, 10, 10) or Color3.fromRGB(130, 130, 130)
        }):Play()
        callback(state)
    end)
end

local function AddSlider(page, name, minVal, maxVal, default, increment, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 68)
    frame.BackgroundColor3 = COLOR_CARD
    frame.BorderSizePixel = 0
    frame.ZIndex = 7
    frame.Parent = page
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 9)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -16, 0, 24)
    label.Position = UDim2.new(0, 16, 0, 9)
    label.BackgroundTransparency = 1
    label.Text = name .. ":  " .. default
    label.TextColor3 = Color3.fromRGB(225, 225, 225)
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 8
    label.Parent = frame

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -32, 0, 8)
    track.Position = UDim2.new(0, 16, 0, 46)
    track.BackgroundColor3 = COLOR_TRACK
    track.BorderSizePixel = 0
    track.ZIndex = 8
    track.Parent = frame
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - minVal) / (maxVal - minVal), 0, 1, 0)
    fill.BackgroundColor3 = COLOR_WHITE
    fill.BorderSizePixel = 0
    fill.ZIndex = 9
    fill.Parent = track
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("TextButton")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = UDim2.new((default - minVal) / (maxVal - minVal), -8, 0.5, -8)
    knob.BackgroundColor3 = COLOR_WHITE
    knob.Text = ""
    knob.BorderSizePixel = 0
    knob.ZIndex = 10
    knob.Parent = track
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local value = default
    local dragging = false

    local function updateVisual()
        local pct = (value - minVal) / (maxVal - minVal)
        fill.Size = UDim2.new(pct, 0, 1, 0)
        knob.Position = UDim2.new(pct, -8, 0.5, -8)
        label.Text = name .. ":  " .. math.floor(value / increment) * increment
    end
    updateVisual()

    knob.MouseButton1Down:Connect(function() dragging = true end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local bx = track.AbsolutePosition.X
            local bw = track.AbsoluteSize.X
            local pct = math.clamp((input.Position.X - bx) / bw, 0, 1)
            value = minVal + pct * (maxVal - minVal)
            value = math.floor(value / increment + 0.5) * increment
            value = math.clamp(value, minVal, maxVal)
            updateVisual()
            callback(value)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
end

local function AddAimPartSelector(page)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 68)
    frame.BackgroundColor3 = COLOR_CARD
    frame.BorderSizePixel = 0
    frame.ZIndex = 7
    frame.Parent = page
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 9)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -16, 0, 24)
    label.Position = UDim2.new(0, 16, 0, 8)
    label.BackgroundTransparency = 1
    label.Text = "Aim Part"
    label.TextColor3 = Color3.fromRGB(225, 225, 225)
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 8
    label.Parent = frame

    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -32, 0, 28)
    container.Position = UDim2.new(0, 16, 0, 36)
    container.BackgroundTransparency = 1
    container.ZIndex = 8
    container.Parent = frame

    local listLayout = Instance.new("UIListLayout")
    listLayout.FillDirection = Enum.FillDirection.Horizontal
    listLayout.Padding = UDim.new(0, 6)
    listLayout.Parent = container

    local parts = {"Head", "UpperTorso", "LowerTorso"}
    local partBtns = {}

    for _, part in ipairs(parts) do
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 118, 1, 0)
        b.BackgroundColor3 = (part == AimPart) and COLOR_WHITE or COLOR_TRACK
        b.Text = part
        b.TextColor3 = (part == AimPart) and Color3.fromRGB(10, 10, 10) or COLOR_SUBTEXT
        b.Font = Enum.Font.GothamSemibold
        b.TextSize = 13
        b.BorderSizePixel = 0
        b.ZIndex = 9
        b.Parent = container
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 7)
        partBtns[part] = b

        b.MouseButton1Click:Connect(function()
            AimPart = part
            for _, pb in pairs(partBtns) do
                TweenService:Create(pb, TweenInfo.new(0.15), {
                    BackgroundColor3 = (pb.Text == part) and COLOR_WHITE or COLOR_TRACK,
                    TextColor3 = (pb.Text == part) and Color3.fromRGB(10, 10, 10) or COLOR_SUBTEXT
                }):Play()
            end
        end)
    end
end

-- ================== POPULATE PAGES ==================

-- ESP Page
AddSectionLabel(TabPages["Esp"], "ESP SETTINGS")
AddToggle(TabPages["Esp"], "ESP", false, ToggleESP)

-- Aimbot Page
AddSectionLabel(TabPages["Aimbot"], "AIMBOT SETTINGS")
AddToggle(TabPages["Aimbot"], "Aimbot", false, function(v)
    AimbotEnabled = v
    if v then StartAimbot() FOVCircle.Visible = true else StopAimbot() end
end)
AddSlider(TabPages["Aimbot"], "FOV Radius", 30, 500, 150, 5, function(v) AimFOV = v end)
AddSlider(TabPages["Aimbot"], "Smoothing", 0.05, 1, 0.2, 0.05, function(v) Smoothing = v end)
AddAimPartSelector(TabPages["Aimbot"])
AddSlider(TabPages["Aimbot"], "Spawn Exclusion Radius", 10, 200, 60, 5, function(v) SpawnExclusionDistance = v end)

-- Macro Page
AddSectionLabel(TabPages["Macro"], "MACRO SETTINGS")
AddToggle(TabPages["Macro"], "Auto Tapper", false, function(v)
    AutoTapEnabled = v
    if v then StartAutoTapper() else StopAutoTapper() end
end)
AddSlider(TabPages["Macro"], "Tap Speed", 0.01, 0.15, 0.05, 0.01, function(v) TapSpeed = v end)

-- Default open tab
SetActiveTab("Esp")

-- ================== DRAGGING ==================
local dragging, dragStartPos, startFramePos
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStartPos = input.Position
        startFramePos = MainFrame.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStartPos
        MainFrame.Position = UDim2.new(
            startFramePos.X.Scale,
            startFramePos.X.Offset + delta.X,
            startFramePos.Y.Scale,
            startFramePos.Y.Offset + delta.Y
        )
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

-- ================== MINIMIZE / CLOSE ==================
local Logo = nil
local function CreateMinimizeLogo()
    if Logo then return end
    Logo = Instance.new("ImageButton")
    Logo.Size = UDim2.new(0, 80, 0, 50)
    Logo.Position = UDim2.new(0, 30, 0, 30)
    Logo.BackgroundTransparency = 1
    Logo.Image = "rbxassetid://118374262825356"
    Logo.ScaleType = Enum.ScaleType.Fit
    Logo.Parent = ScreenGui

    local ld, ls, lsp = false, nil, nil
    Logo.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            ld = true; ls = i.Position; lsp = Logo.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if ld and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position - ls
            Logo.Position = UDim2.new(lsp.X.Scale, lsp.X.Offset + d.X, lsp.Y.Scale, lsp.Y.Offset + d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then ld = false end
    end)
    Logo.MouseButton1Click:Connect(function()
        MainFrame.Visible = true
        Logo.Visible = false
    end)
end

MinBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    CreateMinimizeLogo()
    Logo.Visible = true
end)

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- ================== AUTO SETUP ==================
Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function(char)
        if ESPEnabled then CreateESPForCharacter(char, plr) end
    end)
end)

UpdateFOVCircle()
print("✅ Spectr Script Loaded — Sidebar UI Active!")
