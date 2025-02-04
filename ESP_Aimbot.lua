local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Variables de configuración
local ESPEnabled = false
local AimbotEnabled = false
local ESPObjects = {}

-- Crear el panel con Drawing API
local GUI = {}
GUI.Frame = Drawing.new("Square")
GUI.Frame.Size = Vector2.new(200, 150)
GUI.Frame.Position = Vector2.new(50, 50)
GUI.Frame.Color = Color3.fromRGB(30, 30, 30)
GUI.Frame.Thickness = 2
GUI.Frame.Filled = true
GUI.Frame.Visible = true

GUI.Title = Drawing.new("Text")
GUI.Title.Text = "ESP & Aimbot"
GUI.Title.Size = 20
GUI.Title.Position = Vector2.new(80, 60)
GUI.Title.Color = Color3.fromRGB(255, 255, 255)
GUI.Title.Outline = true
GUI.Title.Visible = true

GUI.ESPButton = Drawing.new("Square")
GUI.ESPButton.Size = Vector2.new(180, 30)
GUI.ESPButton.Position = Vector2.new(60, 90)
GUI.ESPButton.Color = Color3.fromRGB(50, 150, 250)
GUI.ESPButton.Filled = true
GUI.ESPButton.Visible = true

GUI.ESPText = Drawing.new("Text")
GUI.ESPText.Text = "Activar ESP"
GUI.ESPText.Size = 18
GUI.ESPText.Position = Vector2.new(90, 95)
GUI.ESPText.Color = Color3.fromRGB(255, 255, 255)
GUI.ESPText.Visible = true

GUI.AimbotButton = Drawing.new("Square")
GUI.AimbotButton.Size = Vector2.new(180, 30)
GUI.AimbotButton.Position = Vector2.new(60, 130)
GUI.AimbotButton.Color = Color3.fromRGB(250, 50, 50)
GUI.AimbotButton.Filled = true
GUI.AimbotButton.Visible = true

GUI.AimbotText = Drawing.new("Text")
GUI.AimbotText.Text = "Activar Aimbot"
GUI.AimbotText.Size = 18
GUI.AimbotText.Position = Vector2.new(90, 135)
GUI.AimbotText.Color = Color3.fromRGB(255, 255, 255)
GUI.AimbotText.Visible = true

-- Función para crear ESP
local function createESP(player)
    if player == LocalPlayer or not ESPEnabled then return end

    local function onCharacterAdded(character)
        local rootPart = character:WaitForChild("HumanoidRootPart", 5)
        local humanoid = character:WaitForChild("Humanoid", 5)
        if not rootPart or not humanoid then return end

        -- Crear Nametag y Tracer
        local tracer = Drawing.new("Line")
        tracer.Visible = false
        tracer.Thickness = 2
        tracer.Color = Color3.new(1, 1, 1)

        ESPObjects[player] = {Tracer = tracer}

        -- Actualizar ESP en cada frame
        RunService.RenderStepped:Connect(function()
            if ESPObjects[player] and character and rootPart then
                local screenPos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
                if onScreen then
                    tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    tracer.To = Vector2.new(screenPos.X, screenPos.Y)
                    tracer.Visible = ESPEnabled
                else
                    tracer.Visible = false
                end
            end
        end)

        -- Eliminar ESP cuando muere el jugador
        humanoid.Died:Connect(function()
            if ESPObjects[player] then
                ESPObjects[player].Tracer:Remove()
                ESPObjects[player] = nil
            end
        end)
    end

    if player.Character then
        onCharacterAdded(player.Character)
    end
    player.CharacterAdded:Connect(onCharacterAdded)
end

-- Función para encontrar al enemigo más cercano
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

-- Función para manejar el Aimbot
local function updateAimbot()
    if AimbotEnabled then
        local target = getClosestEnemy()
        if target and target.Character and target.Character:FindFirstChild("Head") then
            local targetPosition = target.Character.Head.Position
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPosition)
        end
    end
end

-- Eventos para activar/desactivar Aimbot con clic derecho
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        AimbotEnabled = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        AimbotEnabled = false
    end
end)

-- Evento para alternar ESP
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local mousePos = Vector2.new(input.Position.X, input.Position.Y)
        local espBtnPos = GUI.ESPButton.Position
        local aimBtnPos = GUI.AimbotButton.Position
        local btnSize = GUI.ESPButton.Size

        if mousePos.X >= espBtnPos.X and mousePos.X <= (espBtnPos.X + btnSize.X) and
           mousePos.Y >= espBtnPos.Y and mousePos.Y <= (espBtnPos.Y + btnSize.Y) then
            ESPEnabled = not ESPEnabled
            GUI.ESPText.Text = ESPEnabled and "Desactivar ESP" or "Activar ESP"
        end

        if mousePos.X >= aimBtnPos.X and mousePos.X <= (aimBtnPos.X + btnSize.X) and
           mousePos.Y >= aimBtnPos.Y and mousePos.Y <= (aimBtnPos.Y + btnSize.Y) then
            AimbotEnabled = not AimbotEnabled
            GUI.AimbotText.Text = AimbotEnabled and "Desactivar Aimbot" or "Activar Aimbot"
        end
    end
end)

-- Iniciar ESP para los jugadores
Players.PlayerAdded:Connect(createESP)
for _, player in ipairs(Players:GetPlayers()) do
    createESP(player)
end

-- Actualizar Aimbot en cada frame
RunService.RenderStepped:Connect(updateAimbot)
