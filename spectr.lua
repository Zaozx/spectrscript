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
-------------------------------------------------------------------------------
print(ProtectionConfig.HubName .. " Loaded Successfully!")

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

RunService.RenderStepped:Connect(function()
    Camera = workspace.CurrentCamera
end)

-- ================== CORE FEATURES ==================
local SpawnPosition = Vector3.new(0, 497.5, 4000)
local SpawnExclusionDistance = 60
local Highlights = {}
local NameLabels = {}
local Tracers = {}
local ESPEnabled = false
local TracersEnabled = false
local PlayerCountText = nil
local AimbotEnabled = false
local Smoothing = 0.2
local AimPart = "Head"
local AimbotConnection = nil
local AutoTapEnabled = false
local TapSpeed = 0.05
local TapConnection = nil
local FOVEnabled = false
local FOVRadius = 150
local FOVCircle = nil

-- Helper Functions
local function IsAtSpawn(character)
    if not character or not character:FindFirstChild("HumanoidRootPart") then return false end
    return (character.HumanoidRootPart.Position - SpawnPosition).Magnitude < SpawnExclusionDistance
end

local function IsAlive(character)
    if not character then return false end
    if character.Parent and character.Parent.Name == "Dead" then return false end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end
    return true
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

local function CreateFOVCircle()
    if FOVCircle then FOVCircle:Destroy() end
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    FOVCircle = Instance.new("Frame")
    FOVCircle.Size = UDim2.new(0, FOVRadius * 2, 0, FOVRadius * 2)
    FOVCircle.Position = UDim2.new(0.5, -FOVRadius, 0.5, -FOVRadius)
    FOVCircle.BackgroundTransparency = 1
    FOVCircle.BorderSizePixel = 2
    FOVCircle.BorderColor3 = Color3.fromRGB(255, 255, 255)
    FOVCircle.ZIndex = 10
    FOVCircle.Parent = playerGui
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = FOVCircle
end

local function UpdateFOVCircle()
    if not FOVCircle then if FOVEnabled then CreateFOVCircle() end return end
    FOVCircle.Size = UDim2.new(0, FOVRadius * 2, 0, FOVRadius * 2)
    FOVCircle.Position = UDim2.new(0.5, -FOVRadius, 0.5, -FOVRadius)
end

local function ToggleFOV(state)
    FOVEnabled = state
    if state then CreateFOVCircle()
    else if FOVCircle then FOVCircle:Destroy() FOVCircle = nil end end
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
    character.AncestryChanged:Connect(function()
        if character.Parent and character.Parent.Name == "Dead" then
            if Highlights[character] then Highlights[character]:Destroy() end
            if NameLabels[character] then NameLabels[character]:Destroy() end
            Highlights[character] = nil
            NameLabels[character] = nil
        end
    end)
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
        elseif IsAtSpawn(character) or not IsAlive(character) then
            if highlight then highlight:Destroy() end
            if NameLabels[character] then NameLabels[character]:Destroy() end
            Highlights[character] = nil
            NameLabels[character] = nil
        else
            local isVis = IsVisible(character)
            highlight.FillColor = isVis and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
        end
    end
end

local function UpdateTracers()
    for _, line in pairs(Tracers) do
        if line and line.Parent then line:Destroy() end
    end
    Tracers = {}
    if not ESPEnabled or not TracersEnabled then return end
    local tracerGui = game:GetService("CoreGui"):FindFirstChild("SpectrTracers")
    if not tracerGui then
        tracerGui = Instance.new("ScreenGui")
        tracerGui.Name = "SpectrTracers"
        tracerGui.ResetOnSpawn = false
        tracerGui.Parent = game:GetService("CoreGui")
    end
    local screenBottom = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
    for character, highlight in pairs(Highlights) do
        if character and character.Parent and IsAlive(character) then
            local root = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Head")
            if root then
                local screenPos, onScreen = Camera:WorldToViewportPoint(root.Position)
                if onScreen then
                    local enemyPos = Vector2.new(screenPos.X, screenPos.Y)
                    local isGreen = highlight.FillColor == Color3.fromRGB(0, 255, 0)
                    local distance = (enemyPos - screenBottom).Magnitude
                    local center = (enemyPos + screenBottom) / 2
                    local angle = math.atan2(enemyPos.Y - screenBottom.Y, enemyPos.X - screenBottom.X)
                    local line = Instance.new("Frame")
                    line.BackgroundColor3 = isGreen and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
                    line.BorderSizePixel = 0
                    line.ZIndex = 5
                    line.Size = UDim2.new(0, distance, 0, 2)
                    line.Position = UDim2.new(0, center.X - distance / 2, 0, center.Y - 1)
                    line.Rotation = math.deg(angle)
                    line.Parent = tracerGui
                    table.insert(Tracers, line)
                end
            end
        end
    end
end

local function UpdatePlayerCount()
    if not PlayerCountText then return end
    local count = 0
    for character in pairs(Highlights) do
        if character and character.Parent and IsAlive(character) then count += 1 end
    end
    PlayerCountText.Text = "Players in ESP: " .. count
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
        RunService:BindToRenderStep("SpectrESP", Enum.RenderPriority.Camera.Value + 5, function()
            UpdateESP()
            UpdateTracers()
            UpdatePlayerCount()
            if FOVEnabled and FOVCircle then UpdateFOVCircle() end
        end)
    else
        RunService:UnbindFromRenderStep("SpectrESP")
        for _, hl in pairs(Highlights) do if hl then hl:Destroy() end end
        for _, lbl in pairs(NameLabels) do if lbl then lbl:Destroy() end end
        for _, line in pairs(Tracers) do if line then line:Destroy() end end
        Highlights = {}; NameLabels = {}; Tracers = {}
        if PlayerCountText then PlayerCountText.Parent:Destroy() PlayerCountText = nil end
        if FOVCircle then FOVCircle:Destroy() FOVCircle = nil end
    end
end

local function StartAutoTapper()
    if TapConnection then return end
    TapConnection = RunService.Heartbeat:Connect(function()
        if not AutoTapEnabled or not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then return end
        local VIM = game:GetService("VirtualInputManager")
        VIM:SendKeyEvent(true, Enum.KeyCode.Q, false, game) task.wait(TapSpeed)
        VIM:SendKeyEvent(false, Enum.KeyCode.Q, false, game) task.wait(TapSpeed)
        VIM:SendKeyEvent(true, Enum.KeyCode.One, false, game) task.wait(TapSpeed)
        VIM:SendKeyEvent(false, Enum.KeyCode.One, false, game)
    end)
end

local function StopAutoTapper()
    if TapConnection then TapConnection:Disconnect() TapConnection = nil end
end

local function GetClosestTargetInFOV()
    local closest, shortest = nil, math.huge
    for character, highlight in pairs(Highlights) do
        if highlight and highlight.FillColor == Color3.fromRGB(0, 255, 0) and IsAlive(character) then
            local part = character:FindFirstChild(AimPart) or character:FindFirstChild("Head")
            if part and not IsAtSpawn(character) then
                local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                    if (not FOVEnabled or dist <= FOVRadius) and dist < shortest then
                        shortest = dist
                        closest = character
                    end
                end
            end
        end
    end
    return closest
end

local function StartAimbot()
    if AimbotConnection then return end
    AimbotConnection = RunService.RenderStepped:Connect(function()
        if not AimbotEnabled then return end
        local target = GetClosestTargetInFOV()
        if target then
            local part = target:FindFirstChild(AimPart) or target:FindFirstChild("Head")
            if part then Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, part.Position), Smoothing) end
        end
    end)
end

local function StopAimbot()
    if AimbotConnection then AimbotConnection:Disconnect() AimbotConnection = nil end
end

-- ================== UI ==================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 720, 0, 520)
MainFrame.Position = UDim2.new(0.5, -360, 0.5, -260)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 60)
TitleBar.BackgroundColor3 = Color3.fromRGB(15, 15, 17)
TitleBar.Parent = MainFrame
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 12)

local TitleLogo = Instance.new("ImageLabel")
TitleLogo.Size = UDim2.new(0, 46, 0, 46)
TitleLogo.Position = UDim2.new(0, 16, 0, 7)
TitleLogo.BackgroundTransparency = 1
TitleLogo.Image = "rbxassetid://118374262825356"
TitleLogo.ScaleType = Enum.ScaleType.Fit
TitleLogo.Parent = TitleBar

local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(1, -100, 1, 0)
TitleText.Position = UDim2.new(0, 72, 0, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text = "Spectr Script"
TitleText.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleText.Font = Enum.Font.GothamBold
TitleText.TextSize = 23
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.Parent = TitleBar

local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 36, 0, 36)
MinimizeBtn.Position = UDim2.new(1, -80, 0, 12)
MinimizeBtn.BackgroundTransparency = 1
MinimizeBtn.Text = "–"
MinimizeBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
MinimizeBtn.TextSize = 26
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.Parent = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 36, 0, 36)
CloseBtn.Position = UDim2.new(1, -40, 0, 12)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
CloseBtn.TextSize = 26
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = TitleBar

-- Minimized Logo
local Logo = nil
local function CreateMinimizeLogo()
    if Logo then return end
    Logo = Instance.new("ImageButton")
    Logo.Size = UDim2.new(0, 90, 0, 55)
    Logo.Position = UDim2.new(0, 30, 0, 30)
    Logo.BackgroundTransparency = 1
    Logo.Image = "rbxassetid://118374262825356"
    Logo.ScaleType = Enum.ScaleType.Fit
    Logo.Parent = ScreenGui
    local drag, dragStart, startPos = false, nil, nil
    Logo.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then drag=true; dragStart=i.Position; startPos=Logo.Position end end)
    UserInputService.InputChanged:Connect(function(i) if drag and i.UserInputType==Enum.UserInputType.MouseMovement then local d=i.Position-dragStart; Logo.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y) end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end end)
    Logo.MouseButton1Click:Connect(function() MainFrame.Visible=true; Logo.Visible=false end)
end

MinimizeBtn.MouseButton1Click:Connect(function() MainFrame.Visible=false; CreateMinimizeLogo(); Logo.Visible=true end)
CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
    local tg = game:GetService("CoreGui"):FindFirstChild("SpectrTracers")
    if tg then tg:Destroy() end
end)

-- Draggable
local dragging, dragInput, dragStartPos, startFramePos
MainFrame.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true; dragStartPos=i.Position; startFramePos=MainFrame.Position end end)
MainFrame.InputChanged:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseMovement then dragInput=i end end)
UserInputService.InputChanged:Connect(function(i) if dragging and i==dragInput then local d=i.Position-dragStartPos; MainFrame.Position=UDim2.new(startFramePos.X.Scale,startFramePos.X.Offset+d.X,startFramePos.Y.Scale,startFramePos.Y.Offset+d.Y) end end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)

-- ================== TAB SYSTEM ==================
-- Left nav panel
local LeftNav = Instance.new("Frame")
LeftNav.Size = UDim2.new(0, 180, 1, -70)
LeftNav.Position = UDim2.new(0, 10, 0, 65)
LeftNav.BackgroundTransparency = 1
LeftNav.Parent = MainFrame

local NavList = Instance.new("UIListLayout")
NavList.Padding = UDim.new(0, 6)
NavList.Parent = LeftNav

-- Divider
local Divider = Instance.new("Frame")
Divider.Size = UDim2.new(0, 1, 1, -75)
Divider.Position = UDim2.new(0, 198, 0, 70)
Divider.BackgroundColor3 = Color3.fromRGB(45, 45, 47)
Divider.Parent = MainFrame

-- Right content area
local ContentArea = Instance.new("Frame")
ContentArea.Size = UDim2.new(1, -215, 1, -80)
ContentArea.Position = UDim2.new(0, 208, 0, 70)
ContentArea.BackgroundTransparency = 1
ContentArea.Parent = MainFrame

-- Pages table
local Pages = {}
local TabButtons = {}
local ActiveTab = nil

local function AddSlider(parent, name, minVal, maxVal, default, increment, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 68)
    frame.BackgroundColor3 = Color3.fromRGB(28, 28, 30)
    frame.Parent = parent
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -30, 0, 22)
    label.BackgroundTransparency = 1
    label.Text = name .. ": " .. default
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 15
    label.Position = UDim2.new(0, 18, 0, 8)
    label.Parent = frame
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -36, 0, 10)
    bar.Position = UDim2.new(0, 18, 0, 42)
    bar.BackgroundColor3 = Color3.fromRGB(45, 45, 48)
    bar.Parent = frame
    Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - minVal) / (maxVal - minVal), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    fill.Parent = bar
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
    local knob = Instance.new("TextButton")
    knob.Size = UDim2.new(0, 18, 0, 18)
    knob.Position = UDim2.new((default - minVal) / (maxVal - minVal), -9, 0.5, -9)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.Text = ""
    knob.Parent = bar
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
    local value = default
    local function update()
        local percent = (value - minVal) / (maxVal - minVal)
        fill.Size = UDim2.new(percent, 0, 1, 0)
        knob.Position = UDim2.new(percent, -9, 0.5, -9)
        label.Text = name .. ": " .. math.floor(value / increment) * increment
    end
    update()
    local sliderDragging = false
    knob.MouseButton1Down:Connect(function() sliderDragging = true end)
    UserInputService.InputChanged:Connect(function(input)
        if sliderDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local percent = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            value = math.floor((minVal + percent * (maxVal - minVal)) / increment) * increment
            update(); callback(value)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then sliderDragging = false end
    end)
end

local function AddToggle(parent, name, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 52)
    frame.BackgroundColor3 = Color3.fromRGB(28, 28, 30)
    frame.Parent = parent
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.6, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 15
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Position = UDim2.new(0, 18, 0, 0)
    label.Parent = frame
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 78, 0, 32)
    btn.Position = UDim2.new(1, -88, 0.5, -16)
    btn.BackgroundColor3 = default and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(55, 55, 60)
    btn.Text = default and "ON" or "OFF"
    btn.TextColor3 = default and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(200, 200, 200)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.Parent = frame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.MouseButton1Click:Connect(function()
        default = not default
        btn.BackgroundColor3 = default and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(55, 55, 60)
        btn.TextColor3 = default and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(200, 200, 200)
        btn.Text = default and "ON" or "OFF"
        callback(default)
    end)
end

local function CreatePage(name)
    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 4
    page.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Visible = false
    page.Parent = ContentArea
    local list = Instance.new("UIListLayout")
    list.Padding = UDim.new(0, 8)
    list.Parent = page
    Pages[name] = page
    return page
end

local function SwitchTab(name)
    -- Hide all pages
    for _, page in pairs(Pages) do
        page.Visible = false
    end
    -- Deselect all tab buttons
    for tabName, btn in pairs(TabButtons) do
        btn.BackgroundColor3 = Color3.fromRGB(28, 28, 30)
        btn.TextColor3 = Color3.fromRGB(180, 180, 180)
    end
    -- Show selected page
    if Pages[name] then Pages[name].Visible = true end
    -- Highlight selected tab
    if TabButtons[name] then
        TabButtons[name].BackgroundColor3 = Color3.fromRGB(50, 50, 55)
        TabButtons[name].TextColor3 = Color3.fromRGB(255, 255, 255)
    end
    ActiveTab = name
end

local function AddTab(name, icon)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 46)
    btn.BackgroundColor3 = Color3.fromRGB(28, 28, 30)
    btn.Text = (icon and (icon .. "  ") or "") .. name
    btn.TextColor3 = Color3.fromRGB(180, 180, 180)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 15
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Parent = LeftNav
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    -- Left padding via UIPadding
    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 14)
    pad.Parent = btn

    TabButtons[name] = btn
    CreatePage(name)

    btn.MouseButton1Click:Connect(function()
        SwitchTab(name)
    end)
end

-- ================== CREATE TABS ==================
AddTab("ESP", "👁")
AddTab("Aimbot", "🎯")
AddTab("Tracers", "📡")
AddTab("Auto Tap", "⚡")
AddTab("Settings", "⚙️")

-- ================== ESP PAGE ==================
local espPage = Pages["ESP"]
AddToggle(espPage, "Enable ESP", false, ToggleESP)
AddToggle(espPage, "Show Tracers", false, function(v)
    TracersEnabled = v
    if not v then
        for _, line in pairs(Tracers) do if line then line:Destroy() end end
        Tracers = {}
    end
end)
AddToggle(espPage, "FOV Circle", false, ToggleFOV)
AddSlider(espPage, "FOV Radius", 50, 400, 150, 5, function(v)
    FOVRadius = v
    if FOVEnabled and FOVCircle then UpdateFOVCircle() end
end)

-- ================== AIMBOT PAGE ==================
local aimPage = Pages["Aimbot"]
AddToggle(aimPage, "Enable Aimbot", false, function(v)
    AimbotEnabled = v
    if v then StartAimbot() else StopAimbot() end
end)
AddSlider(aimPage, "Smoothing", 0.05, 1, 0.2, 0.05, function(v) Smoothing = v end)

-- Aim Part selector
local aimFrame = Instance.new("Frame")
aimFrame.Size = UDim2.new(1, 0, 0, 80)
aimFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 30)
aimFrame.Parent = aimPage
Instance.new("UICorner", aimFrame).CornerRadius = UDim.new(0, 8)

local aimLabel = Instance.new("TextLabel")
aimLabel.Size = UDim2.new(1, 0, 0, 24)
aimLabel.BackgroundTransparency = 1
aimLabel.Text = "Aim Part"
aimLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
aimLabel.Font = Enum.Font.GothamSemibold
aimLabel.TextSize = 15
aimLabel.Position = UDim2.new(0, 18, 0, 8)
aimLabel.Parent = aimFrame

local aimContainer = Instance.new("Frame")
aimContainer.Size = UDim2.new(1, -36, 0, 34)
aimContainer.Position = UDim2.new(0, 18, 0, 36)
aimContainer.BackgroundTransparency = 1
aimContainer.Parent = aimFrame

local aimList = Instance.new("UIListLayout")
aimList.FillDirection = Enum.FillDirection.Horizontal
aimList.Padding = UDim.new(0, 6)
aimList.Parent = aimContainer

for _, part in ipairs({"Head", "UpperTorso", "LowerTorso", "HumanoidRootPart"}) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 110, 1, 0)
    btn.BackgroundColor3 = (part == AimPart) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(45, 45, 48)
    btn.Text = part
    btn.TextColor3 = (part == AimPart) and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(200, 200, 200)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 13
    btn.Parent = aimContainer
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.MouseButton1Click:Connect(function()
        AimPart = part
        for _, b in ipairs(aimContainer:GetChildren()) do
            if b:IsA("TextButton") then
                b.BackgroundColor3 = (b.Text == part) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(45, 45, 48)
                b.TextColor3 = (b.Text == part) and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(200, 200, 200)
            end
        end
    end)
end

-- ================== TRACERS PAGE ==================
local tracerPage = Pages["Tracers"]
AddToggle(tracerPage, "Enable Tracers", false, function(v)
    TracersEnabled = v
    if not v then
        for _, line in pairs(Tracers) do if line then line:Destroy() end end
        Tracers = {}
    end
end)

local tracerNote = Instance.new("TextLabel")
tracerNote.Size = UDim2.new(1, 0, 0, 50)
tracerNote.BackgroundColor3 = Color3.fromRGB(28, 28, 30)
tracerNote.TextColor3 = Color3.fromRGB(150, 150, 150)
tracerNote.Font = Enum.Font.Gotham
tracerNote.TextSize = 13
tracerNote.Text = "⚠️ ESP must be ON for tracers to work"
tracerNote.TextWrapped = true
tracerNote.Parent = tracerPage
Instance.new("UICorner", tracerNote).CornerRadius = UDim.new(0, 8)

-- ================== AUTO TAP PAGE ==================
local tapPage = Pages["Auto Tap"]
AddToggle(tapPage, "Enable Auto Tap", false, function(v)
    AutoTapEnabled = v
    if v then StartAutoTapper() else StopAutoTapper() end
end)
AddSlider(tapPage, "Tap Speed", 0.01, 0.15, 0.05, 0.01, function(v) TapSpeed = v end)

-- ================== SETTINGS PAGE ==================
local settingsPage = Pages["Settings"]
AddSlider(settingsPage, "Spawn Exclusion Radius", 10, 200, 60, 5, function(v) SpawnExclusionDistance = v end)

-- Auto Setup
Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function(char)
        if ESPEnabled then CreateESPForCharacter(char, plr) end
    end)
end)

-- Default to ESP tab
SwitchTab("ESP")

print("✅ Spectr Loaded - Tab system active!")
