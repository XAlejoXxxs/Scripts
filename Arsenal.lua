local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")

-- Table to store ESP objects
local ESPObjects = {}

-- Aimbot toggle
local aimbotEnabled = false

-- Create ESP for a player
local function createESP(player)
    if player == LocalPlayer then return end

    local function onCharacterAdded(character)
        local humanoid = character:WaitForChild("Humanoid", 5)
        local rootPart = character:WaitForChild("HumanoidRootPart", 5)
        if not humanoid or not rootPart then return end

        -- Create BillboardGui
        local billboard = Instance.new("BillboardGui")
        billboard.Adornee = rootPart
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

        -- Health text
        local healthText = Instance.new("TextLabel", billboard)
        healthText.Size = UDim2.new(1, 0, 0.5, 0)
        healthText.BackgroundTransparency = 1
        healthText.Text = "Health: " .. tostring(humanoid.Health)
        healthText.TextColor3 = Color3.new(1, 1, 1)
        healthText.TextScaled = true
        healthText.Font = Enum.Font.SourceSansBold
        healthText.Position = UDim2.new(0, 0, 0.6, 0)

        -- Attach to character
        billboard.Parent = rootPart

        -- Tracers
        local tracer = Drawing.new("Line")
        tracer.Visible = true
        tracer.Thickness = 2
        tracer.Color = Color3.new(1, 1, 1)

        -- Store objects
        ESPObjects[player] = {Billboard = billboard, Nametag = nametag, HealthText = healthText, Tracer = tracer}

        -- Update health in real-time
        local function updateHealth()
            if humanoid.Health > 0 then
                healthText.Text = "Health: " .. math.ceil(humanoid.Health)
            else
                -- Cleanup ESP when health reaches 0
                if ESPObjects[player] then
                    ESPObjects[player].Billboard:Destroy()
                    ESPObjects[player].Tracer:Remove()
                    ESPObjects[player] = nil
                end
            end
        end

        -- Update health text continuously every frame
        RunService.Heartbeat:Connect(function()
            updateHealth()
        end)

        -- Cleanup on death
        humanoid.Died:Connect(function()
            if ESPObjects[player] then
                ESPObjects[player].Billboard:Destroy()
                ESPObjects[player].Tracer:Remove()
                ESPObjects[player] = nil
            end
        end)
    end

    -- Handle current and future characters
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
            if objects.Billboard then
                objects.Billboard:Destroy()
            end
            if objects.Tracer then
                objects.Tracer:Remove()
            end
            ESPObjects[player] = nil
        end
    end
end

-- Aimbot logic
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

-- Aimbot activation with right-click hold
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

-- Initialize players
Players.PlayerAdded:Connect(createESP)
for _, player in ipairs(Players:GetPlayers()) do
    createESP(player)
end

-- Update ESP and Aimbot every frame
RunService.RenderStepped:Connect(function()
    updateESP()
    updateAimbot()
end)
