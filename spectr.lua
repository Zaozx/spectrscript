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

-- // Spectr - Sniper Arena with Silent Aim \\ --
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")

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

local SilentAimEnabled = false
local AimFOV = 150
local AimPart = "Head"

local AutoTapEnabled = false
local TapSpeed = 0.05

local TapConnection = nil

-- Helper Functions
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

local function GetClosestPlayer()
   local closest, shortest = nil, math.huge
   for _, plr in ipairs(Players:GetPlayers()) do
      if plr == LocalPlayer or not plr.Character then continue end
      local char = plr.Character
      local part = char:FindFirstChild(AimPart) or char:FindFirstChild("Head")
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

-- ================== SILENT AIM FOR SNIPER ARENA ==================
local SilentAimConnection = nil

local function StartSilentAim()
   if SilentAimConnection then return end
   SilentAimConnection = RunService.RenderStepped:Connect(function()
      if not SilentAimEnabled then return end
      local target = GetClosestPlayer()
      if target and target.Character then
         local targetPart = target.Character:FindFirstChild(AimPart) or target.Character:FindFirstChild("Head")
         if targetPart then
            -- Store target for silent aim (many Sniper Arena scripts use this pattern)
            _G.SilentAimTarget = targetPart
         end
      end
   end)
end

local function StopSilentAim()
   if SilentAimConnection then 
      SilentAimConnection:Disconnect() 
      SilentAimConnection = nil 
   end
   _G.SilentAimTarget = nil
end

-- ================== ESP ==================
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
      RunService:BindToRenderStep("SpectrESP", Enum.RenderPriority.Camera.Value + 5, UpdateESP)
   else
      RunService:UnbindFromRenderStep("SpectrESP")
      for _, hl in pairs(Highlights) do if hl then hl:Destroy() end end
      for _, lbl in pairs(NameLabels) do if lbl then lbl:Destroy() end end
      Highlights = {}
      NameLabels = {}
   end
end

-- Auto Tapper
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

-- ================== DARK MODERN UI ==================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 720, 0, 520)
MainFrame.Position = UDim2.new(0.5, -360, 0.5, -260)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)

-- Title Bar, Logo, Minimize, Close, Draggable (kept the same as your last version)
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

-- Minimized Logo (small)
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

   local dragging = false
   local dragStart, startPos

   Logo.InputBegan:Connect(function(input)
      if input.UserInputType == Enum.UserInputType.MouseButton1 then
         dragging = true
         dragStart = input.Position
         startPos = Logo.Position
      end
   end)

   UserInputService.InputChanged:Connect(function(input)
      if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
         local delta = input.Position - dragStart
         Logo.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
      end
   end)

   UserInputService.InputEnded:Connect(function(input)
      if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
   end)

   Logo.MouseButton1Click:Connect(function()
      MainFrame.Visible = true
      Logo.Visible = false
   end)
end

MinimizeBtn.MouseButton1Click:Connect(function()
   MainFrame.Visible = false
   CreateMinimizeLogo()
   Logo.Visible = true
end)

CloseBtn.MouseButton1Click:Connect(function()
   ScreenGui:Destroy()
end)

-- Draggable
local dragging, dragInput, dragStartPos, startFramePos
MainFrame.InputBegan:Connect(function(input)
   if input.UserInputType == Enum.UserInputType.MouseButton1 then
      dragging = true
      dragStartPos = input.Position
      startFramePos = MainFrame.Position
   end
end)
MainFrame.InputChanged:Connect(function(input)
   if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
end)
UserInputService.InputChanged:Connect(function(input)
   if dragging and input == dragInput then
      local delta = input.Position - dragStartPos
      MainFrame.Position = UDim2.new(startFramePos.X.Scale, startFramePos.X.Offset + delta.X, startFramePos.Y.Scale, startFramePos.Y.Offset + delta.Y)
   end
end)
UserInputService.InputEnded:Connect(function(input)
   if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

-- Left / Right Frames (your layout)
local LeftFrame = Instance.new("Frame")
LeftFrame.Size = UDim2.new(0.35, 0, 1, -80)
LeftFrame.Position = UDim2.new(0, 15, 0, 70)
LeftFrame.BackgroundTransparency = 1
LeftFrame.Parent = MainFrame

local LeftTitle = Instance.new("TextLabel")
LeftTitle.Size = UDim2.new(1, 0, 0, 30)
LeftTitle.BackgroundTransparency = 1
LeftTitle.Text = "Features"
LeftTitle.TextColor3 = Color3.fromRGB(180, 180, 180)
LeftTitle.Font = Enum.Font.GothamBold
LeftTitle.TextSize = 18
LeftTitle.Parent = LeftFrame

local LeftList = Instance.new("UIListLayout")
LeftList.Padding = UDim.new(0, 8)
LeftList.Parent = LeftFrame

local Divider = Instance.new("Frame")
Divider.Size = UDim2.new(0, 1, 1, -90)
Divider.Position = UDim2.new(0.39, 0, 0, 75)
Divider.BackgroundColor3 = Color3.fromRGB(45, 45, 47)
Divider.Parent = MainFrame

local RightFrame = Instance.new("Frame")
RightFrame.Size = UDim2.new(0.58, 0, 1, -80)
RightFrame.Position = UDim2.new(0.41, 0, 0, 70)
RightFrame.BackgroundTransparency = 1
RightFrame.Parent = MainFrame

local RightTitle = Instance.new("TextLabel")
RightTitle.Size = UDim2.new(1, 0, 0, 30)
RightTitle.BackgroundTransparency = 1
RightTitle.Text = "Settings"
RightTitle.TextColor3 = Color3.fromRGB(180, 180, 180)
RightTitle.Font = Enum.Font.GothamBold
RightTitle.TextSize = 18
RightTitle.Parent = RightFrame

local RightList = Instance.new("UIListLayout")
RightList.Padding = UDim.new(0, 10)
RightList.Parent = RightFrame

-- Toggle & Slider (your original)
local function AddToggle(parent, name, default, callback)
   local frame = Instance.new("Frame")
   frame.Size = UDim2.new(1, 0, 0, 52)
   frame.BackgroundColor3 = Color3.fromRGB(28, 28, 30)
   frame.Parent = parent
   Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

   local label = Instance.new("TextLabel")
   label.Size = UDim2.new(0.5, 0, 1, 0)
   label.BackgroundTransparency = 1
   label.Text = name
   label.TextColor3 = Color3.fromRGB(220, 220, 220)
   label.Font = Enum.Font.GothamSemibold
   label.TextSize = 16
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

   local dragging = false
   knob.MouseButton1Down:Connect(function() dragging = true end)

   UserInputService.InputChanged:Connect(function(input)
      if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
         local barPos = bar.AbsolutePosition.X
         local barSize = bar.AbsoluteSize.X
         local percent = math.clamp((input.Position.X - barPos) / barSize, 0, 1)
         value = minVal + percent * (maxVal - minVal)
         value = math.floor(value / increment) * increment
         update()
         callback(value)
      end
   end)

   UserInputService.InputEnded:Connect(function(input)
      if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
   end)
end

-- ================== BUILD UI ==================
AddToggle(LeftFrame, "ESP", false, ToggleESP)
AddToggle(LeftFrame, "Silent Aim", false, function(v)
   SilentAimEnabled = v
   if v then 
      StartSilentAim() 
      FOVCircle.Visible = true 
   else 
      StopSilentAim() 
   end
end)
AddToggle(LeftFrame, "Auto Tapper", false, function(v)
   AutoTapEnabled = v
   if v then StartAutoTapper() else StopAutoTapper() end
end)

AddSlider(RightFrame, "Spawn Exclusion Radius", 10, 200, 60, 5, function(v) SpawnExclusionDistance = v end)
AddSlider(RightFrame, "FOV Radius", 30, 500, 150, 5, function(v) AimFOV = v end)

-- Aim Part
local aimFrame = Instance.new("Frame")
aimFrame.Size = UDim2.new(1, 0, 0, 68)
aimFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 30)
aimFrame.Parent = RightFrame
Instance.new("UICorner", aimFrame).CornerRadius = UDim.new(0, 8)

local aimLabel = Instance.new("TextLabel")
aimLabel.Size = UDim2.new(1, 0, 0, 22)
aimLabel.BackgroundTransparency = 1
aimLabel.Text = "Aim Part"
aimLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
aimLabel.Font = Enum.Font.GothamSemibold
aimLabel.TextSize = 15
aimLabel.Position = UDim2.new(0, 18, 0, 8)
aimLabel.Parent = aimFrame

local aimContainer = Instance.new("Frame")
aimContainer.Size = UDim2.new(1, -36, 0, 30)
aimContainer.Position = UDim2.new(0, 18, 0, 32)
aimContainer.BackgroundTransparency = 1
aimContainer.Parent = aimFrame

local aimList = Instance.new("UIListLayout")
aimList.FillDirection = Enum.FillDirection.Horizontal
aimList.Padding = UDim.new(0, 6)
aimList.Parent = aimContainer

for _, part in ipairs({"Head", "UpperTorso", "LowerPart"}) do
   local btn = Instance.new("TextButton")
   btn.Size = UDim2.new(0, 124, 1, 0)
   btn.BackgroundColor3 = (part == AimPart) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(45, 45, 48)
   btn.Text = part
   btn.TextColor3 = (part == AimPart) and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(200, 200, 200)
   btn.Font = Enum.Font.Gotham
   btn.TextSize = 14
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

AddSlider(RightFrame, "Tap Speed", 0.01, 0.15, 0.05, 0.01, function(v) TapSpeed = v end)

-- Auto Setup
Players.PlayerAdded:Connect(function(plr)
   plr.CharacterAdded:Connect(function(char)
      if ESPEnabled then CreateESPForCharacter(char, plr) end
   end)
end)

UpdateFOVCircle()
print("✅ Spectr Loaded with Silent Aim for Sniper Arena!")
