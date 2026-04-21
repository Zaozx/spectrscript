local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Spectr",
   LoadingTitle = "Spectr Script",
   LoadingSubtitle = "by Spectr",
   ConfigurationSaving = { Enabled = false },
})

local ESPTab = Window:CreateTab("ESP", 4483362458)
local AimbotTab = Window:CreateTab("Aimbot", 4483362458)
local CombatTab = Window:CreateTab("Combat", 4483362458)

-- Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")

-- ================== SPAWN EXCLUSION ==================
local SpawnCFrame = CFrame.new(0, 497.5, 4000)  -- Your spawn world pivot
local SpawnExclusionDistance = 50  -- How close to spawn is considered "at spawn" (you can change this)

local function IsAtSpawn(character)
   if not character or not character:FindFirstChild("HumanoidRootPart") then return false end
   local rootPos = character.HumanoidRootPart.Position
   local spawnPos = SpawnCFrame.Position
   local distance = (rootPos - spawnPos).Magnitude
   return distance < SpawnExclusionDistance
end

-- ================== ESP + NAMES + TRACERS + PLAYER COUNT ==================
local Highlights = {}
local NameLabels = {}
local Tracers = {}
local ESPEnabled = false
local PlayerCountText = nil

local function CreatePlayerCount()
   if PlayerCountText then return end
   local screenGui = Instance.new("ScreenGui")
   screenGui.ResetOnSpawn = false
   screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

   PlayerCountText = Instance.new("TextLabel")
   PlayerCountText.Size = UDim2.new(0, 320, 0, 45)
   PlayerCountText.Position = UDim2.new(0.5, -160, 0, 15)
   PlayerCountText.BackgroundTransparency = 0.6
   PlayerCountText.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
   PlayerCountText.TextColor3 = Color3.fromRGB(255, 255, 255)
   PlayerCountText.TextStrokeTransparency = 0
   PlayerCountText.Font = Enum.Font.GothamBold
   PlayerCountText.TextSize = 18
   PlayerCountText.Text = "Players in ESP: 0"
   PlayerCountText.Parent = screenGui
end

local function UpdatePlayerCount()
   if not PlayerCountText then return end
   local count = 0
   for _ in pairs(Highlights) do count += 1 end
   PlayerCountText.Text = "Players in ESP: " .. count
end

local function IsVisible(targetCharacter)
   if not targetCharacter or not targetCharacter:FindFirstChild("HumanoidRootPart") then return false end
   local rootPart = targetCharacter.HumanoidRootPart
   local direction = (rootPart.Position - Camera.CFrame.Position).Unit
   local distance = (rootPart.Position - Camera.CFrame.Position).Magnitude
   
   local raycastParams = RaycastParams.new()
   raycastParams.FilterDescendantsInstances = {LocalPlayer.Character or {}}
   raycastParams.FilterType = Enum.RaycastFilterType.Exclude
   
   local result = workspace:Raycast(Camera.CFrame.Position, direction * (distance + 5), raycastParams)
   return result == nil or result.Instance:IsDescendantOf(targetCharacter)
end

local function CreateESPForCharacter(character, player)
   if not character or Highlights[character] then return end
   if IsAtSpawn(character) then return end  -- ← Skip if at spawn

   task.wait(0.15)

   -- Full Body Highlight
   local highlight = Instance.new("Highlight")
   highlight.Name = "SpectrHighlight"
   highlight.FillColor = Color3.fromRGB(255, 0, 0)
   highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
   highlight.FillTransparency = 0.4
   highlight.OutlineTransparency = 0
   highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
   highlight.Adornee = character
   highlight.Parent = character
   Highlights[character] = highlight

   -- Name above head
   local head = character:FindFirstChild("Head")
   if head then
      local billboard = Instance.new("BillboardGui")
      billboard.Adornee = head
      billboard.Size = UDim2.new(0, 200, 0, 50)
      billboard.StudsOffset = Vector3.new(0, 3, 0)
      billboard.AlwaysOnTop = true
      billboard.LightInfluence = 0
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

   -- Red Tracer
   local tracer = Drawing.new("Line")
   tracer.Thickness = 2
   tracer.Color = Color3.fromRGB(255, 0, 0)
   tracer.Transparency = 1
   tracer.Visible = false
   Tracers[character] = tracer
end

local function UpdateESP()
   for character, highlight in pairs(Highlights) do
      if IsAtSpawn(character) then 
         -- Clean up if somehow spawned near spawn
         if highlight then highlight:Destroy() end
         if NameLabels[character] then NameLabels[character]:Destroy() end
         if Tracers[character] then Tracers[character]:Remove() end
         Highlights[character] = nil
         NameLabels[character] = nil
         Tracers[character] = nil
         continue 
      end

      local player = character.Parent
      if not player or not player:IsA("Player") then continue end

      local isVis = IsVisible(character)
      highlight.FillColor = isVis and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)

      local tracer = Tracers[character]
      if tracer and character:FindFirstChild("HumanoidRootPart") then
         local rootPos = character.HumanoidRootPart.Position
         local screenPos, onScreen = Camera:WorldToScreenPoint(rootPos)
         if onScreen then
            local bottomCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y - 10)
            tracer.From = bottomCenter
            tracer.To = Vector2.new(screenPos.X, screenPos.Y)
            tracer.Visible = true
         else
            tracer.Visible = false
         end
      end
   end
   UpdatePlayerCount()
end

local function ToggleESP(state)
   ESPEnabled = state
   if state then
      CreatePlayerCount()
      for _, player in ipairs(Players:GetPlayers()) do
         if player ~= LocalPlayer and player.Character then
            CreateESPForCharacter(player.Character, player)
         end
      end
      RunService:BindToRenderStep("SpectrESPUpdate", Enum.RenderPriority.Camera.Value + 5, UpdateESP)
   else
      RunService:UnbindFromRenderStep("SpectrESPUpdate")
      for _, hl in pairs(Highlights) do if hl then hl:Destroy() end end
      for _, label in pairs(NameLabels) do if label then label:Destroy() end end
      for _, tracer in pairs(Tracers) do if tracer then tracer:Remove() end end
      Highlights = {}
      NameLabels = {}
      Tracers = {}
      if PlayerCountText and PlayerCountText.Parent then
         PlayerCountText.Parent:Destroy()
         PlayerCountText = nil
      end
   end
end

-- ================== AUTO TAPPER (unchanged) ==================
local AutoTapEnabled = false
local TapSpeed = 0.05

local TapConnection

local function StartAutoTapper()
   if TapConnection then return end
   TapConnection = RunService.Heartbeat:Connect(function()
      if not AutoTapEnabled then return end
      if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then return end

      VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.One, false, game)
      task.wait(TapSpeed)
      VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.One, false, game)

      task.wait(TapSpeed)

      VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Three, false, game)
      task.wait(TapSpeed)
      VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Three, false, game)
   end)
end

local function StopAutoTapper()
   if TapConnection then
      TapConnection:Disconnect()
      TapConnection = nil
   end
end

-- ================== AIMBOT + FOV CIRCLE (unchanged) ==================
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

local function UpdateFOVCircle()
   local centerX = Camera.ViewportSize.X / 2
   local centerY = Camera.ViewportSize.Y / 2
   FOVCircle.Position = Vector2.new(centerX, centerY)
   FOVCircle.Radius = AimFOV
end

local function GetClosestPlayer()
   local closest, shortest = nil, math.huge
   for _, plr in ipairs(Players:GetPlayers()) do
      if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild(AimPart) and not IsAtSpawn(plr.Character) then
         local pos = plr.Character[AimPart].Position
         local screen, onScreen = Camera:WorldToScreenPoint(pos)
         if onScreen then
            local dist = (Vector2.new(screen.X, screen.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
            if dist < AimFOV and dist < shortest then
               shortest = dist
               closest = plr
            end
         end
      end
   end
   return closest
end

local AimbotConnection
local function StartAimbot()
   if AimbotConnection then return end
   AimbotConnection = RunService.RenderStepped:Connect(function()
      UpdateFOVCircle()
      if not AimbotEnabled then return end
      local target = GetClosestPlayer()
      if target and target.Character and target.Character:FindFirstChild(AimPart) then
         local targetPos = target.Character[AimPart].Position
         local current = Camera.CFrame
         Camera.CFrame = current:Lerp(CFrame.new(current.Position, targetPos), Smoothing)
      end
   end)
end

local function StopAimbot()
   if AimbotConnection then AimbotConnection:Disconnect() end
   AimbotConnection = nil
   FOVCircle.Visible = false
end

-- ================== UI SETUP ==================

-- ESP Tab
ESPTab:CreateToggle({
   Name = "ESP + Names + Tracers Toggle",
   CurrentValue = false,
   Callback = function(Value)
      ToggleESP(Value)
   end,
})

ESPTab:CreateColorPicker({
   Name = "Behind Wall Highlight Color",
   Color = Color3.fromRGB(255, 0, 0),
   Callback = function(Value)
      for _, hl in pairs(Highlights) do
         if hl.FillColor ~= Color3.fromRGB(0, 255, 0) then
            hl.FillColor = Value
         end
      end
   end,
})

ESPTab:CreateColorPicker({
   Name = "Tracer Color",
   Color = Color3.fromRGB(255, 0, 0),
   Callback = function(Value)
      for _, tracer in pairs(Tracers) do
         if tracer then tracer.Color = Value end
      end
   end,
})

ESPTab:CreateSlider({
   Name = "Tracer Thickness",
   Range = {1, 5},
   Increment = 0.5,
   CurrentValue = 2,
   Callback = function(Value)
      for _, tracer in pairs(Tracers) do
         if tracer then tracer.Thickness = Value end
      end
   end,
})

-- Aimbot Tab
AimbotTab:CreateToggle({
   Name = "Aimbot Toggle",
   CurrentValue = false,
   Callback = function(Value)
      AimbotEnabled = Value
      if Value then
         StartAimbot()
         FOVCircle.Visible = true
      else
         StopAimbot()
      end
   end,
})

AimbotTab:CreateSlider({
   Name = "FOV Radius",
   Range = {30, 500},
   Increment = 5,
   CurrentValue = 150,
   Callback = function(Value)
      AimFOV = Value
   end,
})

AimbotTab:CreateSlider({
   Name = "Smoothing",
   Range = {0.05, 1},
   Increment = 0.05,
   CurrentValue = 0.2,
   Callback = function(Value) Smoothing = Value end,
})

AimbotTab:CreateDropdown({
   Name = "Aim Part",
   Options = {"Head", "UpperTorso", "HumanoidRootPart"},
   CurrentOption = {"Head"},
   Callback = function(Option) AimPart = Option[1] end,
})

AimbotTab:CreateColorPicker({
   Name = "FOV Circle Color",
   Color = Color3.fromRGB(255, 255, 255),
   Callback = function(Value) FOVCircle.Color = Value end,
})

-- Combat Tab (Auto Tapper)
CombatTab:CreateToggle({
   Name = "Auto Tapper (Hold LMB → Tap 1 & 3 Fast)",
   CurrentValue = false,
   Callback = function(Value)
      AutoTapEnabled = Value
      if Value then
         StartAutoTapper()
      else
         StopAutoTapper()
      end
   end,
})

CombatTab:CreateSlider({
   Name = "Tap Speed (Lower = Faster)",
   Range = {0.01, 0.15},
   Increment = 0.01,
   CurrentValue = 0.05,
   Callback = function(Value)
      TapSpeed = Value
   end,
})

CombatTab:CreateSection("How to use: Turn ON → Hold Left Mouse Button")

-- Auto setup for new players
Players.PlayerAdded:Connect(function(player)
   player.CharacterAdded:Connect(function(char)
      if ESPEnabled then
         CreateESPForCharacter(char, player)
      end
   end)
end)

for _, player in ipairs(Players:GetPlayers()) do
   if player ~= LocalPlayer and player.Character then
      CreateESPForCharacter(player.Character, player)
   end
end

UpdateFOVCircle()

Rayfield:Notify({
   Title = "Spectr Loaded Successfully",
   Content = "All features active:\n• ESP + Names + Tracers\n• Auto Tapper (Hold LMB)\n• Aimbot + FOV Circle",
   Duration = 8,
})
