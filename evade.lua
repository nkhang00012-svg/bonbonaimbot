--[[
    EVADE MULTIMOD V13.8
    - P Key / FLY Button: Toggle Advanced CFrame Fly Mode.
    - V Key / SPEED Button: Toggle Dynamic Speed Lock.
    - R Key / RESCUE Button: Instant Window Rescue 0.5s.
    - [=] Key -> Emote Dash Tiến (Sử dụng lực đẩy Velocity giúp bật cực cao khi va chạm).
    - [-] Key -> Emote Dash Lùi (Giật lùi bằng lực đẩy vật lý).
    - Auto Slide Macro: Nhấp Ctrl liên tục tạo chuyển động nhấp nhô.
    - NEW: Giữ phím Space 3 giây -> Kích hoạt Auto Jump nhảy liên tục. Nhấn lại Space để tắt.
    - RightShift: Ẩn/Hiện Menu.
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

-- States tính năng cũ & mới
local DashForwardEnabled = false
local DashBackwardEnabled = false
local AutoSlideEnabled = false
local AutoJumpEnabled = false

-- === UI CREATION ===
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "EvadeGlobalEspV138"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 260, 0, 395) -- Tăng chiều cao chứa thêm trạng thái Auto Jump
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
Title.Text = "EVADE GLOBAL ESP // V13.8"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 13
Title.Font = Enum.Font.RobotoMono
Title.BackgroundColor3 = Color3.fromRGB(25, 10, 20)
Title.Parent = MainFrame
Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 8)

local function createButton(text, yPos, color, xSize, xPos)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, xSize or 240, 0, 32)
    btn.Position = UDim2.new(0, xPos or 10, 0, yPos)
    btn.Text = text
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 13
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.BackgroundColor3 = color
    btn.Parent = MainFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
    return btn
end

local FlyBtn = createButton("FLY MODE: OFF (P)", 50, Color3.fromRGB(150, 0, 50))
local SpeedMinusBtn = createButton("-", 90, Color3.fromRGB(35, 35, 40), 35, 10)
local SpeedBtn = createButton("SPEED: OFF (45)", 90, Color3.fromRGB(150, 0, 50), 165, 48)
local SpeedPlusBtn = createButton("+", 90, Color3.fromRGB(35, 35, 40), 35, 215)

local DashFwdBtn = createButton("EMOTE DASH TIẾN: OFF (=)", 130, Color3.fromRGB(150, 0, 50))
local DashBwdBtn = createButton("EMOTE DASH LÙI: OFF (-)", 170, Color3.fromRGB(150, 0, 50))
local SlideBtn = createButton("AUTO SLIDE MACRO: OFF", 210, Color3.fromRGB(150, 0, 50))
local JumpBtn = createButton("AUTO JUMP: OFF (HOLD SPACE 3S)", 250, Color3.fromRGB(150, 0, 50))

local RescueBtn = createButton("WINDOW RESCUE (R)", 295, Color3.fromRGB(0, 120, 200))
local CloseBtn = createButton("CLOSE SCRIPT", 345, Color3.fromRGB(40, 40, 45))

-- === SYSTEM TOGGLES ===
local function toggleFly()
    FlyEnabled = not FlyEnabled
    if FlyEnabled then
        SpeedLockEnabled = false
        SpeedBtn.Text = "SPEED: OFF ("..tostring(TargetSpeed)..")"
        SpeedBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 50)
        FlyBtn.Text = "FLY MODE: ON (P)"
        FlyBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 90)
    else
        FlyBtn.Text = "FLY MODE: OFF (P)"
        FlyBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 50)
    end
end

local function updateSpeedButtonHolo()
    if SpeedLockEnabled then
        SpeedBtn.Text = "SPEED: ON ("..tostring(TargetSpeed)..")"
        SpeedBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 90)
    else
        SpeedBtn.Text = "SPEED: OFF ("..tostring(TargetSpeed)..")"
        SpeedBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 50)
    end
end

local function toggleSpeedLock()
    SpeedLockEnabled = not SpeedLockEnabled
    if SpeedLockEnabled then
        if FlyEnabled then FlyEnabled = false end
        FlyBtn.Text = "FLY MODE: OFF (P)"
        FlyBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 50)
    end
    updateSpeedButtonHolo()
end

SpeedMinusBtn.MouseButton1Click:Connect(function()
    if TargetSpeed > 16 then TargetSpeed = TargetSpeed - 5 updateSpeedButtonHolo() end
end)

SpeedPlusBtn.MouseButton1Click:Connect(function()
    if TargetSpeed < 150 then TargetSpeed = TargetSpeed + 5 updateSpeedButtonHolo() end
end)

local function toggleDashForward()
    DashForwardEnabled = not DashForwardEnabled
    if DashForwardEnabled then
        DashBackwardEnabled = false
        DashBwdBtn.Text = "EMOTE DASH LÙI: OFF (-)"
        DashBwdBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 50)
        DashFwdBtn.Text = "EMOTE DASH TIẾN: ON (=)"
        DashFwdBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 90)
    else
        DashFwdBtn.Text = "EMOTE DASH TIẾN: OFF (=)"
        DashFwdBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 50)
    end
end

local function toggleDashBackward()
    DashBackwardEnabled = not DashBackwardEnabled
    if DashBackwardEnabled then
        DashForwardEnabled = false
        DashFwdBtn.Text = "EMOTE DASH TIẾN: OFF (=)"
        DashFwdBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 50)
        DashBwdBtn.Text = "EMOTE DASH LÙI: ON (-)"
        DashBwdBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 90)
    else
        DashBwdBtn.Text = "EMOTE DASH LÙI: OFF (-)"
        DashBwdBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 50)
    end
end

local function toggleAutoSlide()
    AutoSlideEnabled = not AutoSlideEnabled
    if AutoSlideEnabled then
        SlideBtn.Text = "AUTO SLIDE MACRO: ON"
        SlideBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 90)
    else
        SlideBtn.Text = "AUTO SLIDE MACRO: OFF"
        SlideBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 50)
    end
end

local function toggleAutoJump()
    AutoJumpEnabled = not AutoJumpEnabled
    if AutoJumpEnabled then
        JumpBtn.Text = "AUTO JUMP: ON"
        JumpBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 90)
    else
        JumpBtn.Text = "AUTO JUMP: OFF (HOLD SPACE 3S)"
        JumpBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 50)
    end
end

FlyBtn.MouseButton1Click:Connect(toggleFly)
SpeedBtn.MouseButton1Click:Connect(toggleSpeedLock)
DashFwdBtn.MouseButton1Click:Connect(toggleDashForward)
DashBwdBtn.MouseButton1Click:Connect(toggleDashBackward)
SlideBtn.MouseButton1Click:Connect(toggleAutoSlide)
JumpBtn.MouseButton1Click:Connect(toggleAutoJump)

-- === THỜI GIAN GIỮ SPACE ĐỂ KÍCH HOẠT AUTO JUMP ===
local spacePressedTime = 0
local checkSpaceHolding = false

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe or not ScriptRunning then return end
    if input.KeyCode == Enum.KeyCode.Space then
        if AutoJumpEnabled then
            toggleAutoJump() -- Nếu đang bật, nhấn đơn Space sẽ TẮT đi
        else
            spacePressedTime = tick()
            checkSpaceHolding = true
            task.spawn(function()
                while checkSpaceHolding do
                    if tick() - spacePressedTime >= 3.0 then -- Giữ đủ 3 giây
                        toggleAutoJump()
                        checkSpaceHolding = false
                        break
                    end
                    task.wait(0.1)
                end
            end)
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Space then
        checkSpaceHolding = false -- Thả phím sớm trước 3 giây thì hủy đếm
    end
end)

-- === AUTO JUMP & SLIDE LOOPS ===
task.spawn(function()
    while ScriptRunning do
        if AutoJumpEnabled and not FlyEnabled and not IsProcessingRescue then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum and hum.FloorMaterial ~= Enum.Material.Air then
                hum.Jump = true
            end
        end
        task.wait(0.05)
    end
end)

task.spawn(function()
    while ScriptRunning do
        if AutoSlideEnabled and not FlyEnabled and not IsProcessingRescue then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum and (hum.MoveDirection.Magnitude > 0 or DashForwardEnabled or DashBackwardEnabled) then
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.LeftControl, false, game)
                task.wait(0.08)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.LeftControl, false, game)
                task.wait(0.08)
            else
                task.wait(0.1)
            end
        else
            task.wait(0.2)
        end
    end
end)

-- === CORE RUNTIME ENGINE (PHYSICS & VELOCITY IMPROVED) ===
RunService.Heartbeat:Connect(function(deltaTime)
    if not ScriptRunning then return end
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    
    if not root or not hum or IsProcessingRescue then return end
    
    -- Ưu tiên 1: Chế độ Bay (Fly Mode)
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
    
    -- Ưu tiên 2: Chế độ Emote Dash Tiến (Sử dụng lực đẩy Vận Tốc)
    elseif DashForwardEnabled then
        local camLook = Camera.CFrame.LookVector
        local flatDirection = Vector3.new(camLook.X, 0, camLook.Z).Unit
        
        -- Cải tiến độ nảy vật lý: Giữ lại vận tốc cũ theo trục Y (để nhảy/bật tường được đẩy vọt lên)
        local currentYVelocity = root.AssemblyLinearVelocity.Y
        local targetVelocity = flatDirection * TargetSpeed
        
        root.AssemblyLinearVelocity = Vector3.new(targetVelocity.X, currentYVelocity, targetVelocity.Z)
        
    -- Ưu tiên 3: Chế độ Emote Dash Lùi (Sử dụng lực đẩy Vận Tốc)
    elseif DashBackwardEnabled then
        local camLook = Camera.CFrame.LookVector
        local flatDirection = Vector3.new(camLook.X, 0, camLook.Z).Unit
        
        local currentYVelocity = root.AssemblyLinearVelocity.Y
        local targetVelocity = -flatDirection * TargetSpeed
        
        root.AssemblyLinearVelocity = Vector3.new(targetVelocity.X, currentYVelocity, targetVelocity.Z)

    -- Ưu tiên 4: Chạy nhanh thông thường (Speed Hack V - Giữ nguyên CFrame mượt mà)
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
    box.Color = Color3.fromRGB(255, 10, 10) 
    box.Thickness = 2
    box.Filled = false
    box.Visible = false

    local tracer = Drawing.new("Line")
    tracer.Color = Color3.fromRGB(255, 50, 50)
    tracer.Thickness = 1.5
    tracer.Visible = false

    return {Box = box, Tracer = tracer}
end

RunService.RenderStepped:Connect(function()
    if not ScriptRunning then return end
    local validThreats = {}
    
    for _, obj in pairs(workspace:GetChildren()) do
        if obj:IsA("Model") and not Players:GetPlayerFromCharacter(obj) then
            local root = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("PrimaryPart")
            if root then
                local hasKillerJoint = false
                for _, part in pairs(obj:GetDescendants()) do
                    if part:IsA("TouchTransmitter") then hasKillerJoint = true break end
                end
                if hasKillerJoint then validThreats[obj] = root end
            end
        end
    end

    for model, drawings in pairs(ActiveEsps) do
        if not validThreats[model] then
            drawings.Box:Destroy()
            drawings.Tracer:Destroy()
            ActiveEsps[model] = nil
        end
    end

    for model, root in pairs(validThreats) do
        if not ActiveEsps[model] then ActiveEsps[model] = createEspElements() end
        local drawings = ActiveEsps[model]
        local screenPos, onScreen = Camera:WorldToViewportPoint(root.Position)

        if onScreen then
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
            if npcRoot and (npcRoot.Position - targetPosition).Magnitude <= safetyRadius then return true end
        end
    end
    return false
end

local function findDownedPlayerTarget()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local root = p.Character:FindFirstChild("HumanoidRootPart")
            if root and checkIsTargetStillDowned(p) then
                if not isDangerCloseToTarget(root.Position) then return root, p end
            end
        end
    end
    return nil, nil
end

-- === WINDOW RESCUE ENGINE ===
local function executeRescueOperation()
    if IsProcessingRescue or not ScriptRunning then return end
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    local targetPart, targetPlayer = findDownedPlayerTarget()
    if targetPart and targetPlayer then
        IsProcessingRescue = true
        local originalCFrame = root.CFrame
        
        root.CFrame = targetPart.CFrame + Vector3.new(0, 1.2, 0)
        task.wait(0.1) 
        
        local targetPrompt = nil
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("ProximityPrompt") and (obj.Parent == targetPart or obj.Parent == targetPart.Parent) then
                targetPrompt = obj
                break
            end
        end
        
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
        root.CFrame = originalCFrame
        IsProcessingRescue = false
    end
end

-- === KEYBINDS MAPPING ===
RescueBtn.MouseButton1Click:Connect(executeRescueOperation)

CloseBtn.MouseButton1Click:Connect(function()
    ScriptRunning = false
    FlyEnabled = false
    SpeedLockEnabled = false
    DashForwardEnabled = false
    DashBackwardEnabled = false
    AutoSlideEnabled = false
    AutoJumpEnabled = false
    for _, drawings in pairs(ActiveEsps) do drawings.Box:Destroy() drawings.Tracer:Destroy() end
    ScreenGui:Destroy()
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed or not ScriptRunning then return end
    if input.KeyCode == Enum.KeyCode.P then toggleFly()
    elseif input.KeyCode == Enum.KeyCode.V then toggleSpeedLock()
    elseif input.KeyCode == Enum.KeyCode.R then executeRescueOperation()
    elseif input.KeyCode == Enum.KeyCode.Equals then toggleDashForward()
    elseif input.KeyCode == Enum.KeyCode.Minus then toggleDashBackward()
    elseif input.KeyCode == Enum.KeyCode.RightShift then
        MainFrame.Visible = not MainFrame.Visible
        SpeedMinusBtn.Visible = MainFrame.Visible
        SpeedPlusBtn.Visible = MainFrame.Visible
    end
end)
