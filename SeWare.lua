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

--// Variables (Service)
local Players = game:GetService("Players")
local RS = game:GetService("RunService")
local WS = game:GetService("Workspace")
local GS = game:GetService("GuiService")
local SG = game:GetService("StarterGui")
local UIS = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Variables (Regular)
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

local SelectedKey = getgenv().Key:lower()
local SelectedDisableKey = getgenv().DisableKey:lower()
local SelectedESPKey = getgenv().ESPKey:lower()
local SelectedGUIKey = getgenv().GUIKey:lower()

--// Notification Function
local function Notify(text)
    SG:SetCore("SendNotification", {
        Title = "Enabled ✔ | [Se-Ware]",
        Text = text,
        Duration = 5
    })
end

--// Check if Aimlock is Already Loaded
if getgenv().Loaded then
    Notify("Aimlock is already loaded!")
    return
end

getgenv().Loaded = true

--// FOV Circle
local fov = Drawing.new("Circle")
fov.Filled = false
fov.Transparency = 1
fov.Thickness = 1
fov.Color = Color3.fromRGB(255, 255, 0)
fov.NumSides = 1000

--// Utility Functions
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

--// ESP Function with Rainbow Chams
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
                        billboard.Size = UDim2.new(0, 200, 0, 50)
                        local nameLabel = Instance.new("TextLabel", billboard)
                        nameLabel.Text = player.Name
                        nameLabel.BackgroundTransparency = 1
                        nameLabel.TextSize = 14
                        nameLabel.Font = Enum.Font.SourceSans
                        nameLabel.TextColor3 = Color3.new(1, 0, 0)
                        nameLabel.Size = UDim2.new(1, 0, 1, 0)
                        nameLabel.TextScaled = true  -- Ensure the text is centered
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

--// Update Rainbow Chams
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

--// GUI Elements
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Enabled = false
ScreenGui.Parent = game.CoreGui

local Frame = Instance.new("Frame")
Frame.Position = UDim2.new(0.5, -100, 0.5, -75)  -- Smaller and more compact
Frame.Size = UDim2.new(0, 200, 0, 200)  -- Adjusted size to accommodate Silent Aim toggle
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)  -- Darker background
Frame.BackgroundTransparency = 0.3  -- Slightly less transparent
Frame.BorderSizePixel = 0
Frame.Parent = ScreenGui

local UICorner = Instance.new("UICorner", Frame)
UICorner.CornerRadius = UDim.new(0, 10)

local Footer = Instance.new("TextLabel")
Footer.Size = UDim2.new(1, 0, 0.1, 0)  -- Reduced size to avoid overlap
Footer.Position = UDim2.new(0, 0, 0.9, 0)  -- Adjusted position
Footer.Text = "[SE-WARE]"
Footer.BackgroundTransparency = 1
Footer.TextColor3 = getRainbowColor()
Footer.TextScaled = true
Footer.Font = Enum.Font.GothamBold
Footer.Parent = Frame

local Checkboxes = {}

local function createCheckbox(text, position, defaultState, callback)
    local CheckboxFrame = Instance.new("Frame")
    CheckboxFrame.Size = UDim2.new(0.8, 0, 0.1, 0)  -- Smaller checkboxes
    CheckboxFrame.Position = UDim2.new(0.1, 0, position, 0)
    CheckboxFrame.BackgroundTransparency = 1
    CheckboxFrame.Parent = Frame

    local Checkbox = Instance.new("TextButton")
    Checkbox.Size = UDim2.new(0, 20, 0, 20)
    Checkbox.Position = UDim2.new(0, 0, 0, 0)
    Checkbox.BackgroundColor3 = defaultState and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(80, 80, 80)  -- Subtle colors
    Checkbox.Text = ""
    Checkbox.Parent = CheckboxFrame

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -30, 1, 0)
    Label.Position = UDim2.new(0, 30, 0, 0)
    Label.Text = text
    Label.BackgroundTransparency = 1
    Label.TextColor3 = Color3.fromRGB(255, 255, 255)
    Label.TextScaled = true
    Label.Font = Enum.Font.Gotham
    Label.TextXAlignment = Enum.TextXAlignment.Left  -- Align text to the left
    Label.Parent = CheckboxFrame

    local UICorner = Instance.new("UICorner", Checkbox)
    UICorner.CornerRadius = UDim.new(0, 4)

    Checkbox.MouseButton1Click:Connect(function()
        defaultState = not defaultState
        Checkbox.BackgroundColor3 = defaultState and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(80, 80, 80)
        callback(defaultState)
    end)

    Checkboxes[text] = Checkbox
end

createCheckbox("Aimlock", 0.05, AimlockState, function(state)
    AimlockState = state
    Notify("Aimlock " .. (AimlockState and "enabled" or "disabled") .. "!")
end)

createCheckbox("ESP", 0.2, ESPEnabled, function(state)
    ESPEnabled = state
    toggleESP(ESPEnabled)
    Notify("ESP " .. (ESPEnabled and "enabled" or "disabled") .. "!")
end)

createCheckbox("Rainbow Chams", 0.35, RainbowChams, function(state)
    RainbowChams = state
    Notify("Rainbow Chams " .. (RainbowChams and "enabled" or "disabled") .. "!")
    toggleESP(ESPEnabled) -- Refresh ESP to apply changes
end)

createCheckbox("Player Names", 0.5, ShowPlayerNames, function(state)
    ShowPlayerNames = state
    Notify("Player Names " .. (ShowPlayerNames and "enabled" or "disabled") .. "!")
    toggleESP(ESPEnabled)  -- Refresh ESP to apply changes
end)

createCheckbox("FOV Circle", 0.65, getgenv().ShowFOV, function(state)
    getgenv().ShowFOV = state
    Notify("FOV Circle " .. (getgenv().ShowFOV and "enabled" or "disabled") .. "!")
end)

createCheckbox("Silent Aim", 0.8, SilentAimEnabled, function(state)
    SilentAimEnabled = state
    Notify("Silent Aim " .. (SilentAimEnabled and "enabled" or "disabled") .. "!")
end)

local function updateGUI()
    Checkboxes["Aimlock"].BackgroundColor3 = AimlockState and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(80, 80, 80)
    Checkboxes["ESP"].BackgroundColor3 = ESPEnabled and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(80, 80, 80)
    Checkboxes["Rainbow Chams"].BackgroundColor3 = RainbowChams and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(80, 80, 80)
    Checkboxes["Player Names"].BackgroundColor3 = ShowPlayerNames and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(80, 80, 80)
    Checkboxes["FOV Circle"].BackgroundColor3 = getgenv().ShowFOV and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(80, 80, 80)
    Checkboxes["Silent Aim"].BackgroundColor3 = SilentAimEnabled and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(80, 80, 80)
end

--// Make Frame Draggable
local dragging = false
local dragInput, dragStart, startPos

local function updateInput(input)
    local delta = input.Position - dragStart
    Frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

Frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = Frame.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

Frame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

UIS.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        updateInput(input)
    end
end)

--// Functions
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

            if notKO and notGrabbed and aimPart and distance <= getgenv().MaxDistance then
                local pos = Camera:WorldToViewportPoint(character.PrimaryPart.Position)
                local distanceToCursor = (Vector2.new(pos.X, pos.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude

                if (getgenv().FOV and fov.Radius > distanceToCursor and distanceToCursor < shortestDistance) or (not getgenv().FOV and distanceToCursor < shortestDistance) then
                    closestPlayer = v
                    shortestDistance = distanceToCursor
                end
            end
        end
    end
    return closestPlayer
end

--// Enhanced Aimlock with Improved Prediction
local function aimAt(target)
    if not target or not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then return end

    local aimPart = target.Character:FindFirstChild(getgenv().AimPart)
    if not aimPart then return end

    local targetPosition = aimPart.Position
    local targetVelocity = aimPart.Velocity

    -- Enhanced prediction calculation
    local travelTime = (targetPosition - Camera.CFrame.Position).Magnitude / 1000 -- Adjust this value to your game projectile speed
    local predictedPosition = targetPosition + (targetVelocity * travelTime)

    -- Aim at the predicted position
    Camera.CFrame = CFrame.new(Camera.CFrame.Position, predictedPosition)
end

--// Silent Aim Function
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

--// Key Down Event Handler
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

--// Render Stepped Event Handler
RS.RenderStepped:Connect(function()
    updateFOV()
    if AimlockState and Locked and Victim and Victim.Character and Victim.Character:FindFirstChild(getgenv().AimPart) then
        if getDistanceFromPlayer(Victim.Character) <= getgenv().MaxDistance then
            aimAt(Victim)
        else
            Victim = nil
            Notify("Target moved out of range, unlocking!")
        end
    end
    -- Update Footer Color
    Footer.TextColor3 = getRainbowColor()

    -- Silent Aim
    if SilentAimEnabled then
        silentAim()
    end
end)

--// Auto Prediction
while wait() do
    if getgenv().AutoPrediction then
        local ping = tonumber(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValueString():match("(%d+)"))
        if ping then
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
    end
end
