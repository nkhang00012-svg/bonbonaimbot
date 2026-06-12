--[[
    EVADE MULTIMOD V13.5 (INTEGRATED TARGET-SPECIFIC ESP)
    - P Key / FLY Button: Toggle Advanced CFrame Fly Mode.
    - V Key / SPEED Button: Toggle Instant CFrame Speed 45.
    - R Key / RESCUE Button: TP to target, spam Q for exactly 0.5s, then return home immediately.
    - NEW: Global ESP (Box & Tracers) exclusively for dynamic targets with 'Touch Interest' KILL zones (Nextbots, custom threat NPCs).
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- === SYSTEM STATES ===
local FlyEnabled = false
local SpeedLockEnabled = false
local FlySpeed = 60
local TargetSpeed = 45
local IsProcessingRescue = false
local ScriptRunning = true

-- === UI CREATION ===
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "EvadeGlobalEspV135"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 260, 0, 245)
MainFrame.Position = UDim2.new(0.1, 0, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)
local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(255, 0, 150) -- Hot Cyber Pink
UIStroke.Thickness = 2
UIStroke.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 35)
Title.Text = "EVADE GLOBAL ESP // V13.5"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 13
Title.Font = Enum.Font.RobotoMono
Title.BackgroundColor3 = Color3.fromRGB(25, 10, 20)
Title.Parent = MainFrame
Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 8)

local function createButton(text, yPos, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 35)
    btn.Position = UDim2.new(0, 10, 0, yPos)
    btn.Text = text
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 14
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.BackgroundColor3 = color
    btn.Parent = MainFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
    return btn
end

local FlyBtn = createButton("FLY MODE: OFF (P)", 50, Color3.fromRGB(150, 0, 50))
local SpeedBtn = createButton("SPEED HACK 45: OFF (V)", 95, Color3.fromRGB(150, 0, 50))
local RescueBtn = createButton("WINDOW RESCUE (R)", 140, Color3.fromRGB(0, 120, 200))
local CloseBtn = createButton("CLOSE SCRIPT", 190, Color3.fromRGB(40, 40, 45))

-- === MOBILE BUTTONS ===
local function createMobileButton(text, yFrame, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 65, 0, 65)
    btn.Position = UDim2.new(0.82, 0, yFrame, 0)
    btn.BackgroundColor3 = color
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Text = text
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 14
    btn.Active = true
    btn.Draggable = true
    btn.Parent = ScreenGui
    Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
    return btn
end

local MobileFlyBtn = createMobileButton("FLY", 0.25, Color3.fromRGB(255, 0, 100))
local MobileSpeedBtn = createMobileButton("SPEED", 0.36, Color3.fromRGB(255, 150, 0))
local MobileTpBtn = createMobileButton("RESCUE", 0.47, Color3.fromRGB(0, 150, 255))

-- === FLY ENGINE ===
local function toggleFly()
    FlyEnabled = not FlyEnabled
    if FlyEnabled then
        SpeedLockEnabled = false
        SpeedBtn.Text = "SPEED HACK 45: OFF (V)"
        SpeedBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 50)
        FlyBtn.Text = "FLY MODE: ON (P)"
        FlyBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 90)
    else
        FlyBtn.Text = "FLY MODE: OFF (P)"
        FlyBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 50)
    end
end

-- === SPEED ENGINE ===
local function toggleSpeedLock()
    SpeedLockEnabled = not SpeedLockEnabled
    if SpeedLockEnabled then
        if FlyEnabled then FlyEnabled = false end
        FlyBtn.Text = "FLY MODE: OFF (P)"
        FlyBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 50)
        SpeedBtn.Text = "SPEED HACK 45: ON (V)"
        SpeedBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 90)
    else
        SpeedBtn.Text = "SPEED HACK 45: OFF (V)"
        SpeedBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 50)
    end
end

-- CORE RUNTIME ENGINE
RunService.Heartbeat:Connect(function(deltaTime)
    if not ScriptRunning then return end
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    
    if not root or not hum or IsProcessingRescue then return end
    
    if FlyEnabled then
        root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        local moveVector = Vector3.new(0, 0, 0)
        local camCFrame = Camera.CFrame
        
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveVector = moveVector + camCFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVector = moveVector - camCFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveVector = moveVector - camCFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVector = moveVector + camCFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveVector = moveVector + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveVector = moveVector - Vector3.new(0, 1, 0) end
        
        if moveVector.Magnitude > 0 then
            root.CFrame = root.CFrame + (moveVector.Unit * FlySpeed * deltaTime)
        end
    elseif SpeedLockEnabled then
        if hum.MoveDirection.Magnitude > 0 then
            local customMove = hum.MoveDirection * TargetSpeed * deltaTime
            root.CFrame = root.CFrame + customMove
        end
    end
end)

-- === ACTIVE GLOBAL THREAT SCANNER & ESP ENGINE ===
local ActiveEsps = {}

local function createEspElements()
    local box = Drawing.new("Square")
    box.Color = Color3.fromRGB(255, 10, 10) -- High Warning Red
    box.Thickness = 2
    box.Filled = false
    box.Visible = false

    local tracer = Drawing.new("Line")
    tracer.Color = Color3.fromRGB(255, 50, 50)
    tracer.Thickness = 1.5
    tracer.Visible = false

    return {Box = box, Tracer = tracer}
end

-- Scan targets in workspace non-stop for Nextbots and dynamic threat NPCs
RunService.RenderStepped:Connect(function()
    if not ScriptRunning then return end
    
    local validThreats = {}
    
    for _, obj in pairs(workspace:GetChildren()) do
        -- 1. Must be a Model in Workspace
        -- 2. Must NOT be a valid Player character
        if obj:IsA("Model") and not Players:GetPlayerFromCharacter(obj) then
            local root = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("PrimaryPart")
            if root then
                -- 3. MUST possess a 'TouchInterest' (Killer sensory joint)
                local hasKillerJoint = false
                for _, part in pairs(obj:GetDescendants()) do
                    if part:IsA("TouchTransmitter") then
                        hasKillerJoint = true
                        break
                    end
                end
                
                if hasKillerJoint then
                    validThreats[obj] = root
                end
            end
        end
    end

    -- Autosweep drawing cache for models removed by the server
    for model, drawings in pairs(ActiveEsps) do
        if not validThreats[model] then
            drawings.Box:Destroy()
            drawings.Tracer:Destroy()
            ActiveEsps[model] = nil
        end
    end

    -- Perform draw update loop for all dynamic threat targets
    for model, root in pairs(validThreats) do
        if not ActiveEsps[model] then
            ActiveEsps[model] = createEspElements()
        end

        local drawings = ActiveEsps[model]
        local screenPos, onScreen = Camera:WorldToViewportPoint(root.Position)

        if onScreen then
            -- Dynamics sizing system to scale Box based on threat dimensions and distance
            local extents = model:GetExtentsSize()
            local topWorld = root.Position + Vector3.new(0, extents.Y / 1.5, 0)
            local bottomWorld = root.Position - Vector3.new(0, extents.Y / 1.5, 0)
            
            local topScreen = Camera:WorldToViewportPoint(topWorld)
            local bottomScreen = Camera:WorldToViewportPoint(bottomWorld)
            local boxHeight = math.abs(topScreen.Y - bottomScreen.Y)
            local boxWidth = boxHeight * 0.85

            drawings.Box.Size = Vector2.new(boxWidth, boxHeight)
            drawings.Box.Position = Vector2.new(screenPos.X - boxWidth / 2, screenPos.Y - boxHeight / 2)
            drawings.Box.Visible = true

            -- Draw tracer line from bottom-center of screen to the threat root
            drawings.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            drawings.Tracer.To = Vector2.new(screenPos.X, screenPos.Y + boxHeight / 2)
            drawings.Tracer.Visible = true
        else
            drawings.Box.Visible = false
            drawings.Tracer.Visible = false
        end
    end
end)

-- === BASE STATUS CHECKER ===
local function checkIsTargetStillDowned(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return false end
    local char = targetPlayer.Character
    local hum = char:FindFirstChildOfClass("Humanoid")
    
    if char:FindFirstChild("Downed") or char:FindFirstChild("Incapacitated") or (hum and hum.PlatformStand == true) then
        return true
    end
    
    for _, child in pairs(char:GetDescendants()) do
        if child:IsA("ProximityPrompt") or (child:IsA("ImageLabel") and child.Visible and child.ImageColor3.R > 0.7) then
            return true
        end
    end
    return false
end

-- === DANGER ZONE RADAR FILTER ===
local function isDangerCloseToTarget(targetPosition)
    local safetyRadius = 12 
    for _, object in pairs(workspace:GetChildren()) do
        if object:IsA("Model") and not Players:GetPlayerFromCharacter(object) then
            local npcRoot = object:FindFirstChild("HumanoidRootPart") or object:FindFirstChild("PrimaryPart")
            if npcRoot and (npcRoot.Position - targetPosition).Magnitude <= safetyRadius then
                return true 
            end
        end
    end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local otherRoot = p.Character:FindFirstChild("HumanoidRootPart")
            if otherRoot and (otherRoot.Position - targetPosition).Magnitude <= safetyRadius then
                if not checkIsTargetStillDowned(p) then
                    return true 
                end
            end
        end
    end
    return false
end

-- === CARRY STATE VERIFICATION ===
local function checkIfCarryingSuccess(targetCharacter)
    local myChar = LocalPlayer.Character
    if not myChar or not targetCharacter then return false end
    
    if targetCharacter:FindFirstChild("Carried") or targetCharacter.Parent == myChar then
        return true
    end
    
    for _, part in pairs(myChar:GetDescendants()) do
        if part:IsA("Weld") or part:IsA("WeldConstraint") then
            if part.Part0 == targetCharacter or part.Part1 == targetCharacter or part.Parent == targetCharacter then
                return true
            end
        end
    end
    return false
end

local function findDownedPlayerTarget()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local root = p.Character:FindFirstChild("HumanoidRootPart")
            if root and checkIsTargetStillDowned(p) then
                if not isDangerCloseToTarget(root.Position) then
                    return root, p
                end
            end
        end
    end
    return nil, nil
end

-- === 0.5s TIME-WINDOW RESCUE ENGINE ===
local function executeRescueOperation()
    if IsProcessingRescue or not ScriptRunning then return end
    
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    local targetPart, targetPlayer = findDownedPlayerTarget()
    
    if targetPart and targetPlayer then
        IsProcessingRescue = true
        local originalCFrame = root.CFrame
        local targetModel = targetPlayer.Character
        
        -- 1. Instant Teleport right onto the downed player
        root.CFrame = targetPart.CFrame + Vector3.new(0, 1.2, 0)
        task.wait(0.1) 
        
        Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, targetPart.Position)
        
        local targetPrompt = nil
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("ProximityPrompt") and (obj.Parent == targetPart or obj.Parent == targetPart.Parent) then
                targetPrompt = obj
                break
            end
        end
        
        -- 2. THE 0.5 SECOND WINDOW: Spam Carry (Q) and Prompt Trigger
        local timeWindowActive = true
        task.spawn(function()
            while timeWindowActive do
                if targetPrompt then fireproximityprompt(targetPrompt) end
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Q, false, game)
                task.wait(0.05)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Q, false, game)
                RunService.Heartbeat:Wait()
            end
        end)
        
        task.wait(0.5) 
        timeWindowActive = false 
        
        -- 3. ABSOLUTE RETURN: Instantly return to safe base location
        root.CFrame = originalCFrame
        task.wait(0.1)
        
        -- 4. VERIFICATION: Did the 0.5s carry window succeed?
        local carrySuccess = checkIfCarryingSuccess(targetModel)
        
        if carrySuccess then
            -- [CARRY WAS ON] -> Execute stationary safe zone revive loop until fully alive
            local spamActive = true
            task.spawn(function()
                while spamActive do
                    if targetPrompt then fireproximityprompt(targetPrompt) end
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                    RunService.Heartbeat:Wait()
                end
            end)
            
            while checkIsTargetStillDowned(targetPlayer) do
                task.wait(0.05)
            end
            
            spamActive = false
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
        else
            RescueBtn.Text = "TARGET CARRY OFF!"
            RescueBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 0)
            task.delay(1.2, function()
                RescueBtn.Text = "WINDOW RESCUE (R)"
                RescueBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
            end)
        end
        
        IsProcessingRescue = false
    else
        RescueBtn.Text = "DANGER / NO TARGET"
        RescueBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 0)
        task.delay(1.2, function()
            RescueBtn.Text = "WINDOW RESCUE (R)"
            RescueBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
        end)
    end
end

-- === CONNECTIONS & CLEANUP ===
FlyBtn.MouseButton1Click:Connect(toggleFly)
MobileFlyBtn.MouseButton1Click:Connect(toggleFly)

SpeedBtn.MouseButton1Click:Connect(toggleSpeedLock)
MobileSpeedBtn.MouseButton1Click:Connect(toggleSpeedLock)

RescueBtn.MouseButton1Click:Connect(executeRescueOperation)
MobileTpBtn.MouseButton1Click:Connect(executeRescueOperation)

CloseBtn.MouseButton1Click:Connect(function()
    ScriptRunning = false
    FlyEnabled = false
    SpeedLockEnabled = false
    
    -- Terminate and deep clear all drawing frames to prevent dynamic memory leaks
    for _, drawings in pairs(ActiveEsps) do
        drawings.Box:Destroy()
        drawings.Tracer:Destroy()
    end
    table.clear(ActiveEsps)
    
    ScreenGui:Destroy()
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed or not ScriptRunning then return end
    if input.KeyCode == Enum.KeyCode.P then toggleFly()
    elseif input.KeyCode == Enum.KeyCode.V then toggleSpeedLock()
    elseif input.KeyCode == Enum.KeyCode.R then executeRescueOperation()
    elseif input.KeyCode == Enum.KeyCode.RightShift then
        MainFrame.Visible = not MainFrame.Visible
        MobileFlyBtn.Visible = MainFrame.Visible
        MobileSpeedBtn.Visible = MainFrame.Visible
        MobileTpBtn.Visible = MainFrame.Visible
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    FlyEnabled = false
    SpeedLockEnabled = false
    IsProcessingRescue = false
end)