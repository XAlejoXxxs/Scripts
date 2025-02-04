local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")

-- Table to store ESP objects
local ESPObjects = {}

-- Aimbot toggle
local aimbotEnabled = false
local recoilEnabled = true

-- Create ESP for a player
local function createESP(player)
    if player == LocalPlayer then return end

    local function onCharacterAdded(character)
        if not character:FindFirstChild("HumanoidRootPart") or not character:FindFirstChild("Humanoid") then return end

        local humanoid = character:WaitForChild("Humanoid")

        -- BillboardGui for Nametag and Health Bar
        local billboard = Instance.new("BillboardGui")
        billboard.Adornee = character:WaitForChild("HumanoidRootPart")
        billboard.Size = UDim2.new(5, 0, 1, 0)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.AlwaysOnTop = true

        -- Nametag
        local nametag = Instance.new("TextLabel", billboard)
        nametag.Size = UDim2.new(1, 0, 0.5, 0)
        nametag.BackgroundTransparency = 1
        nametag.Text = player.Name
        nametag.TextColor3 = Color3.new(1, 1, 1)
        nametag.TextScaled = true
        nametag.Font = Enum.Font.SourceSansBold

        -- Health Bar
        local healthBarBackground = Instance.new("Frame", billboard)
        healthBarBackground.Size = UDim2.new(1, 0, 0.2, 0)
        healthBarBackground.Position = UDim2.new(0, 0, 0.6, 0)
        healthBarBackground.BackgroundColor3 = Color3.new(0, 0, 0)

        local healthBar = Instance.new("Frame", healthBarBackground)
        healthBar.Size = UDim2.new(1, 0, 1, 0)
        healthBar.BackgroundColor3 = Color3.new(0, 1, 0)

        billboard.Parent = character:WaitForChild("HumanoidRootPart")

        -- Tracers
        local tracer = Drawing.new("Line")
        tracer.Visible = true
        tracer.Thickness = 2
        tracer.Color = Color3.new(1, 1, 1)

        -- Store objects
        ESPObjects[player] = {Billboard = billboard, HealthBar = healthBar, Tracer = tracer}

        -- Update health in real-time
        local function updateHealth()
            if humanoid.Health > 0 then
                healthBar.Size = UDim2.new(humanoid.Health / humanoid.MaxHealth, 0, 1, 0)
                healthBar.BackgroundColor3 = Color3.fromRGB(255 - (humanoid.Health / humanoid.MaxHealth) * 255, (humanoid.Health / humanoid.MaxHealth) * 255, 0)
            else
                if ESPObjects[player] then
                    ESPObjects[player].Billboard:Destroy()
                    ESPObjects[player].Tracer:Remove()
                    ESPObjects[player] = nil
                end
            end
        end

        humanoid.HealthChanged:Connect(updateHealth)
        updateHealth()
    end

    if player.Character then
        onCharacterAdded(player.Character)
    end

    player.CharacterAdded:Connect(onCharacterAdded)
end

-- Update ESP
local function updateESP()
    for player, objects in pairs(ESPObjects) do
        local character = player.Character
        if character and character:FindFirstChild("HumanoidRootPart") and character:FindFirstChild("Humanoid") then
            local rootPart = character.HumanoidRootPart

            -- Update tracer
            local tracer = objects.Tracer
            local rootPartPosition, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
            if onScreen and player.Team ~= LocalPlayer.Team then
                tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                tracer.To = Vector2.new(rootPartPosition.X, rootPartPosition.Y)
                tracer.Visible = true
            else
                tracer.Visible = false
            end
        else
            -- Cleanup if character is not valid
            objects.Billboard:Destroy()
            objects.Tracer:Remove()
            ESPObjects[player] = nil
        end
    end
end

-- Aimbot function
local function getClosestEnemy()
    local closestPlayer = nil
    local shortestDistance = math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Team ~= LocalPlayer.Team and player.Character and player.Character:FindFirstChild("Head") then
            local head = player.Character.Head
            local screenPoint, onScreen = Camera:WorldToViewportPoint(head.Position)

            if onScreen then
                local mousePosition = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                local distance = (mousePosition - Vector2.new(screenPoint.X, screenPoint.Y)).Magnitude

                if distance < shortestDistance then
                    shortestDistance = distance
                    closestPlayer = player
                end
            end
        end
    end

    return closestPlayer
end

-- Aimbot update
local function updateAimbot()
    if aimbotEnabled then
        local target = getClosestEnemy()
        if target and target.Character and target.Character:FindFirstChild("Head") then
            local targetPosition = target.Character.Head.Position
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPosition)
        end
    end
end

-- No recoil function
local function noRecoil()
    local weapon = LocalPlayer.Character:FindFirstChild("Tool")
    if weapon and weapon:IsA("Tool") then
        local handle = weapon:FindFirstChild("Handle")
        if handle then
            local originalCFrame = handle.CFrame
            local targetCFrame = originalCFrame

            if recoilEnabled then
                handle.CFrame = handle.CFrame:Lerp(targetCFrame, 0.1)
            end

            weapon.Activated:Connect(function()
                handle.CFrame = originalCFrame
            end)
        end
    end
end

-- Activación y desactivación del Aimbot con clic derecho
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        aimbotEnabled = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        aimbotEnabled = false
    end
end)

-- Create a simple UI panel
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = game.CoreGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 200, 0, 150)
frame.Position = UDim2.new(0, 10, 0, 10)
frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
frame.Parent = ScreenGui

local espButton = Instance.new("TextButton")
espButton.Size = UDim2.new(0, 180, 0, 30)
espButton.Position = UDim2.new(0, 10, 0, 10)
espButton.Text = "Toggle ESP"
espButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
espButton.Parent = frame

local aimbotButton = Instance.new("TextButton")
aimbotButton.Size = UDim2.new(0, 180, 0, 30)
aimbotButton.Position = UDim2.new(0, 10, 0, 50)
aimbotButton.Text = "Toggle Aimbot"
aimbotButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
aimbotButton.Parent = frame

local recoilButton = Instance.new("TextButton")
recoilButton.Size = UDim2.new(0, 180, 0, 30)
recoilButton.Position = UDim2.new(0, 10, 0, 90)
recoilButton.Text = "Toggle No Recoil"
recoilButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
recoilButton.Parent = frame

-- Toggle ESP visibility
espButton.MouseButton1Click:Connect(function()
    for _, player in ipairs(Players:GetPlayers()) do
        createESP(player)
    end
end)

-- Toggle Aimbot
aimbotButton.MouseButton1Click:Connect(function()
    aimbotEnabled = not aimbotEnabled
    aimbotButton.Text = aimbotEnabled and "Aimbot ON" or "Aimbot OFF"
end)

-- Toggle No Recoil
recoilButton.MouseButton1Click:Connect(function()
    recoilEnabled = not recoilEnabled
    recoilButton.Text = recoilEnabled and "No Recoil ON" or "No Recoil OFF"
end)

-- Listen for players
Players.PlayerAdded:Connect(function(player)
    createESP(player)
end)

Players.PlayerRemoving:Connect(function(player)
    if ESPObjects[player] then
        ESPObjects[player].Billboard:Destroy()
        ESPObjects[player].Tracer:Remove()
        ESPObjects[player] = nil
    end
end)

-- Initialize ESP for existing players
for _, player in ipairs(Players:GetPlayers()) do
    createESP(player)
end

-- Update ESP, Aimbot, and No Recoil every frame
RunService.RenderStepped:Connect(function()
    updateESP()
    updateAimbot()
    noRecoil()
end)
