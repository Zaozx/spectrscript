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

-- // Spectr - Tabbed UI like your screenshot \\ --
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

local AimbotEnabled = false
local AimFOV = 150
local Smoothing = 0.2
local AimPart = "Head"

local AutoTapEnabled = false
local TapSpeed = 0.05

local TapConnection = nil
local AimbotConnection = nil

-- Helper Functions (same as before)
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
      RunService:BindToRenderStep("SpectrESP", Enum.RenderPriority.Camera.Value + 5, UpdateESP)
   else
      RunService:UnbindFromRenderStep("SpectrESP")
      for _, hl in pairs(Highlights) do if hl then hl:Destroy() end end
      for _, lbl in pairs(NameLabels) do if lbl then lbl:Destroy() end end
      Highlights = {}
      NameLabels = {}
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
         local targetPos = target.Character[AimPart].Position
         Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, targetPos), Smoothing)
      end
   end)
end

local function StopAimbot()
   if AimbotConnection then AimbotConnection:Disconnect() AimbotConnection = nil end
   FOVCircle.Visible = false
end

-- ================== NEW TABBED UI ==================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 800, 0, 500)
MainFrame.Position = UDim2.new(0.5, -400, 0.5, -250)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 60)
TitleBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
TitleBar.Parent = MainFrame
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 8)

local TitleLogo = Instance.new("ImageLabel")
TitleLogo.Size = UDim2.new(0, 40, 0, 40)
TitleLogo.Position = UDim2.new(0, 20, 0.5, -20)
TitleLogo.BackgroundTransparency = 1
TitleLogo.Image = "rbxassetid://118374262825356"
TitleLogo.ScaleType = Enum.ScaleType.Fit
TitleLogo.Parent = TitleBar

local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(1, -100, 1, 0)
TitleText.Position = UDim2.new(0, 70, 0, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text = "Spectr Script"
TitleText.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleText.Font = Enum.Font.GothamBold
TitleText.TextSize = 24
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.Parent = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 40, 0, 40)
CloseBtn.Position = UDim2.new(1, -50, 0.5, -20)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
CloseBtn.TextSize = 28
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = TitleBar

CloseBtn.MouseButton1Click:Connect(function()
   ScreenGui:Destroy()
end)

-- Left Sidebar (Buttons)
local LeftFrame = Instance.new("Frame")
LeftFrame.Size = UDim2.new(0, 180, 1, -60)
LeftFrame.Position = UDim2.new(0, 0, 0, 60)
LeftFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 17)
LeftFrame.BorderSizePixel = 0
LeftFrame.Parent = MainFrame

local LeftList = Instance.new("UIListLayout")
LeftList.Padding = UDim.new(0, 2)
LeftList.Parent = LeftFrame

-- Right Content Area
local RightFrame = Instance.new("Frame")
RightFrame.Size = UDim2.new(1, -180, 1, -60)
RightFrame.Position = UDim2.new(0, 180, 0, 60)
RightFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 14)
RightFrame.BorderSizePixel = 0
RightFrame.Parent = MainFrame

-- Large SPECTR Logo Background
local BackgroundLogo = Instance.new("ImageLabel")
BackgroundLogo.Size = UDim2.new(0.8, 0, 0.8, 0)
BackgroundLogo.Position = UDim2.new(0.1, 0, 0.1, 0)
BackgroundLogo.BackgroundTransparency = 1
BackgroundLogo.Image = "rbxassetid://118374262825356"
BackgroundLogo.ImageTransparency = 0.85
BackgroundLogo.ScaleType = Enum.ScaleType.Fit
BackgroundLogo.Parent = RightFrame

-- Tab Content Frames
local EspContent = Instance.new("Frame")
EspContent.Size = UDim2.new(1, 0, 1, 0)
EspContent.BackgroundTransparency = 1
EspContent.Visible = true
EspContent.Parent = RightFrame

local AimbotContent = Instance.new("Frame")
AimbotContent.Size = UDim2.new(1, 0, 1, 0)
AimbotContent.BackgroundTransparency = 1
AimbotContent.Visible = false
AimbotContent.Parent = RightFrame

local MacroContent = Instance.new("Frame")
MacroContent.Size = UDim2.new(1, 0, 1, 0)
MacroContent.BackgroundTransparency = 1
MacroContent.Visible = false
MacroContent.Parent = RightFrame

-- Left Buttons
local function CreateTabButton(text, contentFrame)
   local btn = Instance.new("TextButton")
   btn.Size = UDim2.new(1, 0, 0, 60)
   btn.BackgroundColor3 = Color3.fromRGB(25, 25, 28)
   btn.Text = text
   btn.TextColor3 = Color3.fromRGB(200, 200, 200)
   btn.Font = Enum.Font.GothamSemibold
   btn.TextSize = 18
   btn.Parent = LeftFrame
   Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 0)

   btn.MouseButton1Click:Connect(function()
      EspContent.Visible = false
      AimbotContent.Visible = false
      MacroContent.Visible = false
      contentFrame.Visible = true

      -- Highlight active button
      for _, b in ipairs(LeftFrame:GetChildren()) do
         if b:IsA("TextButton") then
            b.BackgroundColor3 = (b == btn) and Color3.fromRGB(40, 40, 45) or Color3.fromRGB(25, 25, 28)
         end
      end
   end)
   return btn
end

CreateTabButton("Esp", EspContent)
CreateTabButton("Aimbot", AimbotContent)
CreateTabButton("Macro", MacroContent)

-- ================== CONTENT FOR EACH TAB ==================

-- ESP Tab Content
local function AddToggle(parent, name, default, callback)
   -- Simple toggle for now (you can expand later)
   local frame = Instance.new("Frame")
   frame.Size = UDim2.new(1, -40, 0, 50)
   frame.Position = UDim2.new(0, 20, 0, 20)
   frame.BackgroundColor3 = Color3.fromRGB(25, 25, 28)
   frame.Parent = parent
   Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)

   local label = Instance.new("TextLabel")
   label.Size = UDim2.new(0.7, 0, 1, 0)
   label.BackgroundTransparency = 1
   label.Text = name
   label.TextColor3 = Color3.fromRGB(220, 220, 220)
   label.Font = Enum.Font.GothamSemibold
   label.TextSize = 16
   label.TextXAlignment = Enum.TextXAlignment.Left
   label.Position = UDim2.new(0, 20, 0, 0)
   label.Parent = frame

   local btn = Instance.new("TextButton")
   btn.Size = UDim2.new(0, 80, 0, 32)
   btn.Position = UDim2.new(1, -100, 0.5, -16)
   btn.BackgroundColor3 = default and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(60, 60, 65)
   btn.Text = default and "ON" or "OFF"
   btn.TextColor3 = Color3.fromRGB(0, 0, 0)
   btn.Font = Enum.Font.GothamBold
   btn.TextSize = 14
   btn.Parent = frame
   Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

   btn.MouseButton1Click:Connect(function()
      default = not default
      btn.BackgroundColor3 = default and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(60, 60, 65)
      btn.Text = default and "ON" or "OFF"
      callback(default)
   end)
end

AddToggle(EspContent, "Enable ESP", false, ToggleESP)

-- Aimbot Tab Content
AddToggle(AimbotContent, "Enable Aimbot", false, function(v)
   AimbotEnabled = v
   if v then StartAimbot() FOVCircle.Visible = true else StopAimbot() end
end)

-- Macro Tab Content (Auto Tapper)
AddToggle(MacroContent, "Auto Tapper", false, function(v)
   AutoTapEnabled = v
   if v then StartAutoTapper() else StopAutoTapper() end
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

UpdateFOVCircle()
print("✅ Spectr Tabbed UI Loaded!")
