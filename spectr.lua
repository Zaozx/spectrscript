-- ⚠️ IMPORTANT: Put this at the VERY TOP of your Main Script ⚠️
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
        highlight.FillColor = IsVisible(character) and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,0,0)
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
            PlayerCountText.BackgroundColor3 = Color3.fromRGB(0,0,0)
            PlayerCountText.TextColor3 = Color3.fromRGB(255,255,255)
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
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
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
            local dist = (Vector2.new(screen.X, screen.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
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
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, target.Character[AimPart].Position), Smoothing)
        end
    end)
end

local function StopAimbot()
    if AimbotConnection then AimbotConnection:Disconnect() AimbotConnection = nil end
    FOVCircle.Visible = false
end

-- ================== UI SETUP ==================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SpectrGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Main window (ClipsDescendants = true so rounded corners clip children)
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 700, 0, 480)
Main.Position = UDim2.new(0.5, -350, 0.5, -240)
Main.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Parent = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)

-- ── Title Bar ──
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 54)
TitleBar.Position = UDim2.new(0, 0, 0, 0)
TitleBar.BackgroundColor3 = Color3.fromRGB(13, 13, 13)
TitleBar.BorderSizePixel = 0
TitleBar.ZIndex = 5
TitleBar.Parent = Main

local TitleLine = Instance.new("Frame")
TitleLine.Size = UDim2.new(1, 0, 0, 1)
TitleLine.Position = UDim2.new(0, 0, 1, -1)
TitleLine.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
TitleLine.BorderSizePixel = 0
TitleLine.ZIndex = 6
TitleLine.Parent = TitleBar

local TitleLogo = Instance.new("ImageLabel")
TitleLogo.Size = UDim2.new(0, 36, 0, 36)
TitleLogo.Position = UDim2.new(0, 12, 0.5, -18)
TitleLogo.BackgroundTransparency = 1
TitleLogo.Image = "rbxassetid://118374262825356"
TitleLogo.ScaleType = Enum.ScaleType.Fit
TitleLogo.ZIndex = 6
TitleLogo.Parent = TitleBar

local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(0, 250, 1, 0)
TitleText.Position = UDim2.new(0, 56, 0, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text = "Spectr Script"
TitleText.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleText.Font = Enum.Font.GothamBold
TitleText.TextSize = 20
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.ZIndex = 6
TitleText.Parent = TitleBar

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 32, 0, 32)
MinBtn.Position = UDim2.new(1, -76, 0.5, -16)
MinBtn.BackgroundTransparency = 1
MinBtn.Text = "–"
MinBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 24
MinBtn.ZIndex = 6
MinBtn.Parent = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 32, 0, 32)
CloseBtn.Position = UDim2.new(1, -38, 0.5, -16)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Color3.fromRGB(255, 70, 70)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 28
CloseBtn.ZIndex = 6
CloseBtn.Parent = TitleBar

-- ── Sidebar (190px, below title bar) ──
local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, 190, 1, -54)
Sidebar.Position = UDim2.new(0, 0, 0, 54)
Sidebar.BackgroundColor3 = Color3.fromRGB(13, 13, 13)
Sidebar.BorderSizePixel = 0
Sidebar.ZIndex = 4
Sidebar.Parent = Main

local SideLine = Instance.new("Frame")
SideLine.Size = UDim2.new(0, 1, 1, 0)
SideLine.Position = UDim2.new(1, -1, 0, 0)
SideLine.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
SideLine.BorderSizePixel = 0
SideLine.ZIndex = 5
SideLine.Parent = Sidebar

-- UIListLayout stacks buttons vertically
local SideList = Instance.new("UIListLayout")
SideList.SortOrder = Enum.SortOrder.LayoutOrder
SideList.FillDirection = Enum.FillDirection.Vertical
SideList.HorizontalAlignment = Enum.HorizontalAlignment.Center
SideList.VerticalAlignment = Enum.VerticalAlignment.Top
SideList.Padding = UDim.new(0, 0)
SideList.Parent = Sidebar

-- ── Content Area (right of sidebar) ──
local ContentArea = Instance.new("Frame")
ContentArea.Name = "ContentArea"
ContentArea.Size = UDim2.new(0, 510, 1, -54)
ContentArea.Position = UDim2.new(0, 190, 0, 54)
ContentArea.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
ContentArea.BorderSizePixel = 0
ContentArea.ClipsDescendants = true
ContentArea.ZIndex = 4
ContentArea.Parent = Main

-- Faint watermark
local Watermark = Instance.new("TextLabel")
Watermark.Size = UDim2.new(1, 0, 1, 0)
Watermark.BackgroundTransparency = 1
Watermark.TextColor3 = Color3.fromRGB(255, 255, 255)
Watermark.TextTransparency = 0.92
Watermark.Text = "SPECTR"
Watermark.Font = Enum.Font.GothamBlack
Watermark.TextSize = 110
Watermark.ZIndex = 4
Watermark.Parent = ContentArea

-- ================== TAB SYSTEM ==================
-- Stores {btn, txt, bar, page} per tab
local Tabs = {}

local function MakePage()
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, 0, 1, 0)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 4
    scroll.ScrollBarImageColor3 = Color3.fromRGB(55, 55, 55)
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Visible = false
    scroll.ZIndex = 5
    scroll.Parent = ContentArea

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 10)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.Parent = scroll

    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 16)
    pad.PaddingBottom = UDim.new(0, 16)
    pad.PaddingLeft = UDim.new(0, 16)
    pad.PaddingRight = UDim.new(0, 16)
    pad.Parent = scroll

    return scroll
end

local function SelectTab(name)
    for tabName, t in pairs(Tabs) do
        local isActive = (tabName == name)
        TweenService:Create(t.btn, TweenInfo.new(0.12), {
            BackgroundColor3 = isActive and Color3.fromRGB(22,22,22) or Color3.fromRGB(13,13,13)
        }):Play()
        t.txt.TextColor3 = isActive and Color3.fromRGB(255,255,255) or Color3.fromRGB(140,140,140)
        t.bar.Visible = isActive
        t.page.Visible = isActive
    end
end

local function AddTab(name, order)
    local page = MakePage()

    -- Button fills full sidebar width
    local btn = Instance.new("TextButton")
    btn.Name = name .. "Tab"
    btn.Size = UDim2.new(1, 0, 0, 60)
    btn.BackgroundColor3 = Color3.fromRGB(13, 13, 13)
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.LayoutOrder = order
    btn.ZIndex = 5
    btn.Parent = Sidebar

    -- Divider line at bottom of button
    local divider = Instance.new("Frame")
    divider.Size = UDim2.new(1, 0, 0, 1)
    divider.Position = UDim2.new(0, 0, 1, -1)
    divider.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    divider.BorderSizePixel = 0
    divider.ZIndex = 6
    divider.Parent = btn

    -- Left active indicator
    local bar = Instance.new("Frame")
    bar.Name = "Bar"
    bar.Size = UDim2.new(0, 3, 0.5, 0)
    bar.Position = UDim2.new(0, 0, 0.25, 0)
    bar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    bar.BorderSizePixel = 0
    bar.Visible = false
    bar.ZIndex = 7
    bar.Parent = btn
    Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

    -- Tab label (MUST be TextLabel child, not btn.Text, so it always renders)
    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(1, 0, 1, 0)
    txt.Position = UDim2.new(0, 0, 0, 0)
    txt.BackgroundTransparency = 1
    txt.Text = name
    txt.TextColor3 = Color3.fromRGB(140, 140, 140)
    txt.Font = Enum.Font.GothamBold
    txt.TextSize = 17
    txt.ZIndex = 6
    txt.Parent = btn

    Tabs[name] = {btn = btn, txt = txt, bar = bar, page = page}

    btn.MouseButton1Click:Connect(function()
        SelectTab(name)
    end)

    return page
end

-- ================== COMPONENT BUILDERS ==================

local function AddToggle(page, name, default, callback)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 52)
    card.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    card.BorderSizePixel = 0
    card.ZIndex = 6
    card.Parent = page
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -80, 1, 0)
    lbl.Position = UDim2.new(0, 14, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 15
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 7
    lbl.Parent = card

    local state = default

    local pill = Instance.new("Frame")
    pill.Size = UDim2.new(0, 48, 0, 26)
    pill.Position = UDim2.new(1, -62, 0.5, -13)
    pill.BackgroundColor3 = state and Color3.fromRGB(255,255,255) or Color3.fromRGB(45,45,50)
    pill.BorderSizePixel = 0
    pill.ZIndex = 7
    pill.Parent = card
    Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 20, 0, 20)
    knob.Position = state and UDim2.new(1,-23,0.5,-10) or UDim2.new(0,3,0.5,-10)
    knob.BackgroundColor3 = state and Color3.fromRGB(15,15,15) or Color3.fromRGB(120,120,120)
    knob.BorderSizePixel = 0
    knob.ZIndex = 8
    knob.Parent = pill
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local clickBtn = Instance.new("TextButton")
    clickBtn.Size = UDim2.new(1, 0, 1, 0)
    clickBtn.BackgroundTransparency = 1
    clickBtn.Text = ""
    clickBtn.ZIndex = 9
    clickBtn.Parent = card

    clickBtn.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(pill, TweenInfo.new(0.15), {
            BackgroundColor3 = state and Color3.fromRGB(255,255,255) or Color3.fromRGB(45,45,50)
        }):Play()
        TweenService:Create(knob, TweenInfo.new(0.15), {
            Position = state and UDim2.new(1,-23,0.5,-10) or UDim2.new(0,3,0.5,-10),
            BackgroundColor3 = state and Color3.fromRGB(15,15,15) or Color3.fromRGB(120,120,120)
        }):Play()
        callback(state)
    end)
end

local function AddSlider(page, name, minVal, maxVal, default, increment, callback)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 64)
    card.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    card.BorderSizePixel = 0
    card.ZIndex = 6
    card.Parent = page
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -14, 0, 22)
    lbl.Position = UDim2.new(0, 14, 0, 8)
    lbl.BackgroundTransparency = 1
    lbl.Text = name .. ":  " .. default
    lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 7
    lbl.Parent = card

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -28, 0, 8)
    track.Position = UDim2.new(0, 14, 0, 42)
    track.BackgroundColor3 = Color3.fromRGB(38, 38, 42)
    track.BorderSizePixel = 0
    track.ZIndex = 7
    track.Parent = card
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default-minVal)/(maxVal-minVal), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    fill.BorderSizePixel = 0
    fill.ZIndex = 8
    fill.Parent = track
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("TextButton")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = UDim2.new((default-minVal)/(maxVal-minVal), -8, 0.5, -8)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.Text = ""
    knob.BorderSizePixel = 0
    knob.ZIndex = 9
    knob.Parent = track
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local value = default
    local dragging = false

    local function refresh()
        local pct = math.clamp((value-minVal)/(maxVal-minVal), 0, 1)
        fill.Size = UDim2.new(pct, 0, 1, 0)
        knob.Position = UDim2.new(pct, -8, 0.5, -8)
        lbl.Text = name .. ":  " .. math.floor(value/increment + 0.5)*increment
    end
    refresh()

    knob.MouseButton1Down:Connect(function() dragging = true end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local pct = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            value = math.clamp(math.floor((minVal + pct*(maxVal-minVal))/increment + 0.5)*increment, minVal, maxVal)
            refresh()
            callback(value)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
end

local function AddAimPartSelector(page)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 66)
    card.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    card.BorderSizePixel = 0
    card.ZIndex = 6
    card.Parent = page
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -14, 0, 22)
    lbl.Position = UDim2.new(0, 14, 0, 6)
    lbl.BackgroundTransparency = 1
    lbl.Text = "Aim Part"
    lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 7
    lbl.Parent = card

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -28, 0, 28)
    row.Position = UDim2.new(0, 14, 0, 32)
    row.BackgroundTransparency = 1
    row.ZIndex = 7
    row.Parent = card

    local rowList = Instance.new("UIListLayout")
    rowList.FillDirection = Enum.FillDirection.Horizontal
    rowList.Padding = UDim.new(0, 6)
    rowList.VerticalAlignment = Enum.VerticalAlignment.Center
    rowList.Parent = row

    local parts = {"Head", "UpperTorso", "LowerTorso"}
    local btns = {}

    for _, part in ipairs(parts) do
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 142, 1, 0)
        b.BackgroundColor3 = (part == AimPart) and Color3.fromRGB(255,255,255) or Color3.fromRGB(38,38,42)
        b.Text = part
        b.TextColor3 = (part == AimPart) and Color3.fromRGB(10,10,10) or Color3.fromRGB(180,180,180)
        b.Font = Enum.Font.GothamSemibold
        b.TextSize = 13
        b.BorderSizePixel = 0
        b.ZIndex = 8
        b.Parent = row
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
        btns[part] = b

        b.MouseButton1Click:Connect(function()
            AimPart = part
            for _, pb in pairs(btns) do
                TweenService:Create(pb, TweenInfo.new(0.12), {
                    BackgroundColor3 = (pb.Text == part) and Color3.fromRGB(255,255,255) or Color3.fromRGB(38,38,42),
                    TextColor3 = (pb.Text == part) and Color3.fromRGB(10,10,10) or Color3.fromRGB(180,180,180)
                }):Play()
            end
        end)
    end
end

-- ================== BUILD TABS & POPULATE ==================

local espPage = AddTab("Esp", 1)
AddToggle(espPage, "ESP", false, ToggleESP)

local aimPage = AddTab("Aimbot", 2)
AddToggle(aimPage, "Aimbot", false, function(v)
    AimbotEnabled = v
    if v then StartAimbot() FOVCircle.Visible = true else StopAimbot() end
end)
AddSlider(aimPage, "FOV Radius", 30, 500, 150, 5, function(v) AimFOV = v end)
AddSlider(aimPage, "Smoothing", 0.05, 1, 0.2, 0.05, function(v) Smoothing = v end)
AddAimPartSelector(aimPage)
AddSlider(aimPage, "Spawn Exclusion", 10, 200, 60, 5, function(v) SpawnExclusionDistance = v end)

local macroPage = AddTab("Macro", 3)
AddToggle(macroPage, "Auto Tapper", false, function(v)
    AutoTapEnabled = v
    if v then StartAutoTapper() else StopAutoTapper() end
end)
AddSlider(macroPage, "Tap Speed", 0.01, 0.15, 0.05, 0.01, function(v) TapSpeed = v end)

-- Open Esp tab by default
SelectTab("Esp")

-- ================== DRAG ==================
local dragging, dragStart, frameStart
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        frameStart = Main.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local d = input.Position - dragStart
        Main.Position = UDim2.new(frameStart.X.Scale, frameStart.X.Offset + d.X, frameStart.Y.Scale, frameStart.Y.Offset + d.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

-- ================== MINIMIZE / CLOSE ==================
local Logo = nil
local function CreateMinLogo()
    if Logo then return end
    Logo = Instance.new("ImageButton")
    Logo.Size = UDim2.new(0, 80, 0, 50)
    Logo.Position = UDim2.new(0, 30, 0, 30)
    Logo.BackgroundTransparency = 1
    Logo.Image = "rbxassetid://118374262825356"
    Logo.ScaleType = Enum.ScaleType.Fit
    Logo.Parent = ScreenGui

    local ld, ls, lp = false, nil, nil
    Logo.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then ld=true; ls=i.Position; lp=Logo.Position end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if ld and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position - ls
            Logo.Position = UDim2.new(lp.X.Scale, lp.X.Offset+d.X, lp.Y.Scale, lp.Y.Offset+d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then ld = false end
    end)
    Logo.MouseButton1Click:Connect(function()
        Main.Visible = true
        Logo.Visible = false
    end)
end

MinBtn.MouseButton1Click:Connect(function()
    Main.Visible = false
    CreateMinLogo()
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
print("✅ Spectr Script Loaded!")
