-- Global Variables
getgenv().Prediction = 0.165
getgenv().AimPart = "HumanoidRootPart"
getgenv().Key = "E"
getgenv().DisableKey = "P"
getgenv().ESPKey = "X"
getgenv().GUIKey = "Insert"
getgenv().FOV = true
getgenv().ShowFOV = false  -- FOV Circle off by default
getgenv().FOVSize = 55
getgenv().MaxDistance = 400
getgenv().SilentAim = false  -- Silent Aim off by default
getgenv().ESPNameColor = Color3.fromRGB(255, 255, 255)  -- Default ESP name color to white
getgenv().AutoTargetSwitch = false  -- Auto-target switching off by default

-- Services
local Players = game:GetService("Players")
local RS = game:GetService("RunService")
local WS = game:GetService("Workspace")
local GS = game:GetService("GuiService")
local SG = game:GetService("StarterGui")
local UIS = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Stats = game:GetService("Stats")

-- Variables
local LP = Players.LocalPlayer
local Mouse = LP:GetMouse()
local Camera = WS.CurrentCamera
local GetGuiInset = GS.GetGuiInset

local AimlockState = true
local Locked = false
local Victim = nil
local ESPEnabled = false
local RainbowChams = false
local ShowPlayerNames = true
local SilentAimEnabled = false
local GUIEnabled = false
local PingDisplay = nil

local SelectedKey = getgenv().Key:lower()
local SelectedDisableKey = getgenv().DisableKey:lower()
local SelectedESPKey = getgenv().ESPKey:lower()
local SelectedGUIKey = getgenv().GUIKey:lower()

-- Notification Function
local function Notify(text)
    SG:SetCore("SendNotification", {
        Title = "Enabled ✔ | [Se-Ware]",
        Text = text,
        Duration = 5
    })
end

-- Check if Aimlock is Already Loaded
if getgenv().Loaded then
    Notify("Aimlock is already loaded!")
    return
end

getgenv().Loaded = true

-- FOV Circle
local fov = Drawing.new("Circle")
fov.Filled = false
fov.Transparency = 1
fov.Thickness = 1
fov.Color = Color3.fromRGB(255, 255, 0)
fov.NumSides = 1000

-- Utility Functions
local function HSVtoRGB(h, s, v)
    local r, g, b
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)

    i = i % 6

    if i == 0 then r, g, b = v, t, p
    elseif i == 1 then r, g, b = q, v, p
    elseif i == 2 then r, g, b = p, v, t
    elseif i == 3 then r, g, b = p, q, v
    elseif i == 4 then r, g, b = t, p, v
    elseif i == 5 then r, g, b = v, p, q
    end

    return Color3.new(r, g, b)
end

local function getRainbowColor()
    return HSVtoRGB(tick() % 5 / 5, 1, 1)
end

-- ESP Function with Rainbow Chams
local function toggleESP(state)
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LP then
            local character = player.Character
            if character then
                local highlight = character:FindFirstChild("Highlight")
                local billboard = character:FindFirstChild("NameESP")

                if state then
                    -- Add Name ESP
                    if ShowPlayerNames and not billboard then
                        billboard = Instance.new("BillboardGui", character)
                        billboard.Name = "NameESP"
                        billboard.AlwaysOnTop = true
                        billboard.ExtentsOffset = Vector3.new(0, 3, 0)
                        billboard.Size = UDim2.new(0, 100, 0, 20)  -- Smaller size for name ESP
                        local nameLabel = Instance.new("TextLabel", billboard)
                        nameLabel.Text = player.Name
                        nameLabel.BackgroundTransparency = 1
                        nameLabel.TextSize = 8  -- Smaller text size for name ESP
                        nameLabel.Font = Enum.Font.SourceSans
                        nameLabel.TextColor3 = getgenv().ESPNameColor
                        nameLabel.Size = UDim2.new(1, 0, 1, 0)
                    elseif not ShowPlayerNames and billboard then
                        billboard:Destroy()
                    end

                    -- Add Rainbow Chams
                    if not highlight then
                        highlight = Instance.new("Highlight", character)
                        highlight.Name = "Highlight"
                        highlight.FillColor = getRainbowColor()
                        highlight.FillTransparency = 0.5
                        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                        highlight.OutlineTransparency = 0
                    end
                else
                    -- Remove Name ESP
                    if billboard then
                        billboard:Destroy()
                    end

                    -- Remove Chams
                    if highlight then
                        highlight:Destroy()
                    end
                end
            end
        end
    end
end

-- Update Rainbow Chams
RS.RenderStepped:Connect(function()
    if ESPEnabled and RainbowChams then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LP then
                local character = player.Character
                if character then
                    local highlight = character:FindFirstChild("Highlight")
                    if highlight then
                        highlight.FillColor = getRainbowColor()
                    end
                end
            end
        end
    end
end)

-- Automatically Update ESP for New Players
Players.PlayerAdded:Connect(function(player)
    if ESPEnabled then
        toggleESP(true)
    end
end)

-- GUI Elements
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Enabled = false
ScreenGui.Parent = game.CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
MainFrame.Size = UDim2.new(0, 400, 0, 300)
MainFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
MainFrame.BackgroundTransparency = 0.2
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local UICornerMain = Instance.new("UICorner", MainFrame)
UICornerMain.CornerRadius = UDim.new(0, 10)

local TabContainer = Instance.new("Frame")
TabContainer.Position = UDim2.new(0, 0, 0, 0)
TabContainer.Size = UDim2.new(1, 0, 0, 30)
TabContainer.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
TabContainer.BorderSizePixel = 0
TabContainer.Parent = MainFrame

local UICornerTabs = Instance.new("UICorner", TabContainer)
UICornerTabs.CornerRadius = UDim.new(0, 10)

local TabListLayout = Instance.new("UIListLayout")
TabListLayout.FillDirection = Enum.FillDirection.Horizontal
TabListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
TabListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
TabListLayout.Parent = TabContainer

local Footer = Instance.new("TextLabel")
Footer.Size = UDim2.new(1, 0, 0.1, 0)
Footer.Position = UDim2.new(0, 0, 0.9, 0)
Footer.Text = "[SE-WARE]"
Footer.BackgroundTransparency = 1
Footer.TextColor3 = getRainbowColor()
Footer.TextScaled = true
Footer.Font = Enum.Font.GothamBold
Footer.Parent = MainFrame

-- Real-Time Ping Display
PingDisplay = Instance.new("TextLabel")
PingDisplay.Size = UDim2.new(0.3, 0, 0.1, 0)
PingDisplay.Position = UDim2.new(0.7, 0, 0, 0)
PingDisplay.Text = "Ping: 0 ms"
PingDisplay.BackgroundTransparency = 1
PingDisplay.TextColor3 = Color3.fromRGB(255, 255, 255)
PingDisplay.TextScaled = true
PingDisplay.Font = Enum.Font.Gotham
PingDisplay.Parent = MainFrame

local Tabs = {}
local function createTab(name)
    local TabButton = Instance.new("TextButton")
    TabButton.Size = UDim2.new(0, 100, 1, 0)
    TabButton.Text = name
    TabButton.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    TabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    TabButton.Font = Enum.Font.Gotham
    TabButton.TextScaled = true
    TabButton.BorderSizePixel = 0
    TabButton.Parent = TabContainer

    local UICornerTab = Instance.new("UICorner", TabButton)
    UICornerTab.CornerRadius = UDim.new(0, 10)

    local TabFrame = Instance.new("Frame")
    TabFrame.Size = UDim2.new(1, 0, 0.9, -30)
    TabFrame.Position = UDim2.new(0, 0, 0.1, 0)
    TabFrame.BackgroundTransparency = 1
    TabFrame.Visible = false
    TabFrame.Parent = MainFrame

    Tabs[name] = TabFrame

    TabButton.MouseButton1Click:Connect(function()
        for _, tab in pairs(Tabs) do
            tab.Visible = false
        end
        TabFrame.Visible = true
    end)
end

createTab("Combat")
createTab("Visuals")
createTab("Misc")
createTab("Settings")

Tabs["Combat"].Visible = true

local function createCheckbox(tab, text, defaultState, callback)
    local CheckboxFrame = Instance.new("Frame")
    CheckboxFrame.Size = UDim2.new(0.9, 0, 0, 30)
    CheckboxFrame.BackgroundTransparency = 1
    CheckboxFrame.Parent = tab

    local Checkbox = Instance.new("TextButton")
    Checkbox.Size = UDim2.new(0, 30, 0, 30)
    Checkbox.BackgroundColor3 = defaultState and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(80, 80, 80)
    Checkbox.Text = ""
    Checkbox.Parent = CheckboxFrame

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -40, 1, 0)
    Label.Position = UDim2.new(0, 40, 0, 0)
    Label.Text = text
    Label.BackgroundTransparency = 1
    Label.TextColor3 = Color3.fromRGB(255, 255, 255)
    Label.TextScaled = true
    Label.Font = Enum.Font.Gotham
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = CheckboxFrame

    local UICornerCheckbox = Instance.new("UICorner", Checkbox)
    UICornerCheckbox.CornerRadius = UDim.new(0, 10)

    Checkbox.MouseButton1Click:Connect(function()
        defaultState = not defaultState
        Checkbox.BackgroundColor3 = defaultState and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(80, 80, 80)
        callback(defaultState)
    end)
end

createCheckbox(Tabs["Combat"], "Enable Aimlock", AimlockState, function(state)
    AimlockState = state
    Notify("Aimlock " .. (AimlockState and "enabled" or "disabled") .. "!")
end)

createCheckbox(Tabs["Visuals"], "Enable ESP", ESPEnabled, function(state)
    ESPEnabled = state
    toggleESP(ESPEnabled)
    Notify("ESP " .. (ESPEnabled and "enabled" or "disabled") .. "!")
end)

createCheckbox(Tabs["Visuals"], "Rainbow Chams", RainbowChams, function(state)
    RainbowChams = state
    Notify("Rainbow Chams " .. (RainbowChams and "enabled" or "disabled") .. "!")
    toggleESP(ESPEnabled)
end)

createCheckbox(Tabs["Visuals"], "Show Player Names", ShowPlayerNames, function(state)
    ShowPlayerNames = state
    Notify("Player Names " .. (ShowPlayerNames and "enabled" or "disabled") .. "!")
    toggleESP(ESPEnabled)
end)

createCheckbox(Tabs["Visuals"], "FOV Circle", getgenv().ShowFOV, function(state)
    getgenv().ShowFOV = state
    Notify("FOV Circle " .. (getgenv().ShowFOV and "enabled" or "disabled") .. "!")
end)

createCheckbox(Tabs["Combat"], "Silent Aim", SilentAimEnabled, function(state)
    SilentAimEnabled = state
    Notify("Silent Aim " .. (SilentAimEnabled and "enabled" or "disabled") .. "!")
end)

createCheckbox(Tabs["Combat"], "Auto Target Switch", getgenv().AutoTargetSwitch, function(state)
    getgenv().AutoTargetSwitch = state
    Notify("Auto Target Switch " .. (getgenv().AutoTargetSwitch and "enabled" or "disabled") .. "!")
end)

local function updateGUI()
    -- Update the GUI based on the current state
end

-- Make Frame Draggable
local dragging = false
local dragInput, dragStart, startPos

local function updateInput(input)
    local delta = input.Position - dragStart
    MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

UIS.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        updateInput(input)
    end
end)

-- Functions
local function updateFOV()
    if getgenv().FOV then
        if fov then
            fov.Radius = getgenv().FOVSize * 2
            fov.Visible = getgenv().ShowFOV
            fov.Position = Vector2.new(Mouse.X, Mouse.Y + GetGuiInset(GS).Y)
        end
    end
end

local function WTVP(arg)
    return Camera:WorldToViewportPoint(arg)
end

local function getDistanceFromPlayer(character)
    return (LP.Character.HumanoidRootPart.Position - character.HumanoidRootPart.Position).Magnitude
end

local function isVisible(targetPart)
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin).Unit * 1000
    local ray = Ray.new(origin, direction)
    local hitPart = workspace:FindPartOnRayWithIgnoreList(ray, {LP.Character, Camera})

    return hitPart and hitPart:IsDescendantOf(targetPart.Parent)
end

local function getClosestPlayer()
    local closestPlayer = nil
    local shortestDistance = math.huge

    for _, v in pairs(Players:GetPlayers()) do
        local character = v.Character
        if v ~= LP and character and character:FindFirstChild("Humanoid") and character.Humanoid.Health > 0 then
            local bodyEffects = character:FindFirstChild("BodyEffects")
            local notKO = bodyEffects and not bodyEffects:FindFirstChild("K.O").Value
            local notGrabbed = not character:FindFirstChild("GRABBING_CONSTRAINT")
            local aimPart = character:FindFirstChild(getgenv().AimPart)
            local distance = getDistanceFromPlayer(character)

            if notKO and notGrabbed and aimPart and distance <= getgenv().MaxDistance and isVisible(aimPart) then
                local pos = Camera:WorldToViewportPoint(character.PrimaryPart.Position)
                local distanceToCursor = (Vector2.new(pos.X, pos.Y) - Vector2.new(Mouse.X, Mouse.Y)).magnitude

                if (getgenv().FOV and fov.Radius > distanceToCursor and distanceToCursor < shortestDistance) or (not getgenv().FOV and distanceToCursor < shortestDistance) then
                    closestPlayer = v
                    shortestDistance = distanceToCursor
                end
            end
        end
    end
    return closestPlayer
end

-- Enhanced Aimlock with Improved Prediction and Smoothing
local function aimAt(target)
    if not target or not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then return end

    local aimPart = target.Character:FindFirstChild(getgenv().AimPart)
    if not aimPart then return end

    local targetPosition = aimPart.Position
    local targetVelocity = aimPart.Velocity

    -- Enhanced prediction calculation
    local travelTime = (targetPosition - Camera.CFrame.Position).Magnitude / 1000 -- Adjust this value to your game projectile speed
    local predictedPosition = targetPosition + (targetVelocity * travelTime)

    -- Aim at the predicted position with smoothing
    local currentCFrame = Camera.CFrame
    local targetCFrame = CFrame.new(currentCFrame.Position, predictedPosition)
    Camera.CFrame = currentCFrame:Lerp(targetCFrame, 0.2)  -- Adjust the 0.2 value for smoothing speed
end

-- Silent Aim Function
local function silentAim()
    local target = getClosestPlayer()
    if target and target.Character and target.Character:FindFirstChild(getgenv().AimPart) then
        local aimPart = target.Character:FindFirstChild(getgenv().AimPart)
        if aimPart then
            local targetPosition = aimPart.Position
            local targetVelocity = aimPart.Velocity

            -- Enhanced prediction calculation
            local travelTime = (targetPosition - Camera.CFrame.Position).Magnitude / 1000 -- Adjust this value to your game projectile speed
            local predictedPosition = targetPosition + (targetVelocity * travelTime)

            -- Simulate hit
            -- This part depends on how bullets/projectiles are handled in the game
            -- Assuming there is a function to fire a projectile
            local args = {
                [1] = {
                    ["Hit"] = aimPart,
                    ["RayObject"] = Ray.new(Vector3.new(), Vector3.new(0, 0, 0)),
                    ["Distance"] = 0,
                    ["Cframe"] = CFrame.new(targetPosition),
                    ["Vector"] = Vector3.new(),
                    ["Normal"] = Vector3.new(),
                    ["Material"] = Enum.Material.Plastic,
                }
            }

            -- FireServer method for simulating hits
            ReplicatedStorage.Events.HitPart:FireServer(unpack(args))
        end
    end
end

-- Auto-Target Switching
local function switchTarget()
    if not Victim or getDistanceFromPlayer(Victim.Character) > getgenv().MaxDistance or not isVisible(Victim.Character[getgenv().AimPart]) then
        Victim = getClosestPlayer()
        if Victim then
            Notify("Switched target to: " .. Victim.Character.Humanoid.DisplayName)
        end
    end
end

-- Key Down Event Handler
UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    local key = input.KeyCode.Name:lower()
    if key == SelectedKey then
        if AimlockState then
            Locked = not Locked
            if Locked then
                Victim = getClosestPlayer()
                if Victim then
                    Notify("Locked onto: " .. Victim.Character.Humanoid.DisplayName)
                end
            else
                Victim = nil
                Notify("Unlocked!")
            end
        else
            Notify("Aimlock is not enabled!")
        end
    elseif key == SelectedDisableKey then
        AimlockState = not AimlockState
        Notify("Aimlock " .. (AimlockState and "enabled" or "disabled") .. "!")
        updateGUI()
    elseif key == SelectedESPKey then
        ESPEnabled = not ESPEnabled
        toggleESP(ESPEnabled)
        Notify("ESP " .. (ESPEnabled and "enabled" or "disabled") .. "!")
        updateGUI()
    elseif key == SelectedGUIKey then
        GUIEnabled = not GUIEnabled
        ScreenGui.Enabled = GUIEnabled
    end
end)

-- Render Stepped Event Handler
RS.RenderStepped:Connect(function()
    updateFOV()
    if AimlockState and Locked then
        if getgenv().AutoTargetSwitch then
            switchTarget()
        end
        if Victim and Victim.Character and Victim.Character:FindFirstChild(getgenv().AimPart) then
            if getDistanceFromPlayer(Victim.Character) <= getgenv().MaxDistance then
                aimAt(Victim)
            else
                Victim = nil
                Notify("Target moved out of range, unlocking!")
            end
        end
    end
    -- Update Footer Color
    Footer.TextColor3 = getRainbowColor()

    -- Silent Aim
    if SilentAimEnabled then
        silentAim()
    end

    -- Update Ping Display
    PingDisplay.Text = "Ping: " .. tostring(getPing()) .. " ms"
end)

-- Auto Prediction
local function adjustPrediction(ping)
    if ping < 20 then
        getgenv().Prediction = 0.157
    elseif ping < 30 then
        getgenv().Prediction = 0.155
    elseif ping < 40 then
        getgenv().Prediction = 0.145
    elseif ping < 50 then
        getgenv().Prediction = 0.15038
    elseif ping < 60 then
        getgenv().Prediction = 0.15038
    elseif ping < 70 then
        getgenv().Prediction = 0.136
    elseif ping < 80 then
        getgenv().Prediction = 0.133
    elseif ping < 90 then
        getgenv().Prediction = 0.130
    elseif ping < 105 then
        getgenv().Prediction = 0.127
    elseif ping < 110 then
        getgenv().Prediction = 0.124
    elseif ping < 120 then
        getgenv().Prediction = 0.120
    elseif ping < 130 then
        getgenv().Prediction = 0.116
    elseif ping < 140 then
        getgenv().Prediction = 0.113
    elseif ping < 150 then
        getgenv().Prediction = 0.110
    elseif ping < 160 then
        getgenv().Prediction = 0.18
    elseif ping < 170 then
        getgenv().Prediction = 0.15
    elseif ping < 180 then
        getgenv().Prediction = 0.12
    elseif ping < 190 then
        getgenv().Prediction = 0.10
    elseif ping < 205 then
        getgenv().Prediction = 1.0
    elseif ping < 215 then
        getgenv().Prediction = 1.2
    elseif ping < 225 then
        getgenv().Prediction = 1.4
    end
end

local function getPing()
    local stats = Stats.Network.ServerStatsItem["Data Ping"]
    local ping = tonumber(stats:GetValueString():match("%d+"))
    return ping
end

spawn(function()
    while wait(1) do
        local ping = getPing()
        adjustPrediction(ping)
    end
end)
