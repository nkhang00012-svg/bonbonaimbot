--[[
    EVADE MULTIMOD V14.4.3 (Rayfield UI Remake)
    - P Key / FLY Toggle: Toggle Advanced CFrame Fly Mode.
    - LeftShift Key / SPEED Toggle: Toggle Dynamic Speed Lock.
    - R Key / RESCUE Button: Instant Window Rescue 0.5s.
    - [=] Key / DASH TIẾN Toggle: Emote Dash Tiến.
    - [-] Key / DASH LÙI Toggle: Emote Dash Lùi.
    - AUTO SLIDE Toggle: Nhấp Ctrl liên tục tạo chuyển động nhấp nhô.
    - J Key / JUMP Toggle: Bật/Tắt Auto Jump.
    - RightShift / Mở Menu: Sử dụng tính năng ẩn/hiện mặc định của Rayfield.
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

local DashForwardEnabled = false
local DashBackwardEnabled = false
local AutoSlideEnabled = false
local AutoJumpEnabled = false

-- Đối tượng quản lý lực vật lý
local DashAttachment = nil
local DashVelocity = nil

-- === RAYFIELD UI INITIALIZATION ===
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "EVADE GLOBAL ESP // V14.4.3 🌌",
   LoadingTitle = "Đang tải Evade Multimod...",
   LoadingSubtitle = "by Bro Coder",
   ConfigurationSaving = {
      Enabled = true,
      Folder = "EvadeRayfieldSettings"
   },
   KeySystem = false
})

-- Tạo các Tab phân loại
local MainTab = Window:CreateTab("Tốc Độ & Bay ⚡", 4483362458)
local MovementTab = Window:CreateTab("Bổ Trợ Di Chuyển 🏃‍♂️", 4483362458)
local CombatTab = Window:CreateTab("Cứu Trợ 🏥", 4483362458)

-- Biến lưu trữ trạng thái UI Component để cập nhật qua lại
local FlyToggle, SpeedToggle, SpeedSlider, DashFwdToggle, DashBwdToggle, SlideToggle, JumpToggle

-- === PHYSICS CLEANUP FUNCTION ===
local function cleanDashPhysics()
    if DashVelocity then DashVelocity:Destroy() DashVelocity = nil end
    if DashAttachment then DashAttachment:Destroy() DashAttachment = nil end
end

-- === SYSTEM TOGGLES (LOGIC GIỮ NGUYÊN) ===
local function toggleFly(forcedValue)
    FlyEnabled = (forcedValue ~= nil) and forcedValue or not FlyEnabled
    cleanDashPhysics()
    if FlyEnabled then
        SpeedLockEnabled = false
        DashForwardEnabled = false
        DashBackwardEnabled = false
        
        -- Cập nhật trạng thái hiển thị trên giao diện Rayfield
        SpeedToggle:Set(false)
        DashFwdToggle:Set(false)
        DashBwdToggle:Set(false)
        FlyToggle:Set(true)
    else
        FlyToggle:Set(false)
    end
end

local function toggleSpeedLock(forcedValue)
    SpeedLockEnabled = (forcedValue ~= nil) and forcedValue or not SpeedLockEnabled
    if SpeedLockEnabled then
        if FlyEnabled then 
            FlyEnabled = false 
            FlyToggle:Set(false)
        end
        SpeedToggle:Set(true)
    else
        SpeedToggle:Set(false)
    end
end

local function toggleDashForward(forcedValue)
    DashForwardEnabled = (forcedValue ~= nil) and forcedValue or not DashForwardEnabled
    cleanDashPhysics()
    if DashForwardEnabled then
        DashBackwardEnabled = false
        FlyEnabled = false
        
        FlyToggle:Set(false)
        DashBwdToggle:Set(false)
        DashFwdToggle:Set(true)
    else
        DashFwdToggle:Set(false)
    end
end

local function toggleDashBackward(forcedValue)
    DashBackwardEnabled = (forcedValue ~= nil) and forcedValue or not DashBackwardEnabled
    cleanDashPhysics()
    if DashBackwardEnabled then
        DashForwardEnabled = false
        FlyEnabled = false
        
        FlyToggle:Set(false)
        DashFwdToggle:Set(false)
        DashBwdToggle:Set(true)
    else
        DashBwdToggle:Set(false)
    end
end

local function toggleAutoSlide(forcedValue)
    AutoSlideEnabled = (forcedValue ~= nil) and forcedValue or not AutoSlideEnabled
    SlideToggle:Set(AutoSlideEnabled)
end

local function toggleAutoJump(forcedValue)
    AutoJumpEnabled = (forcedValue ~= nil) and forcedValue or not AutoJumpEnabled
    JumpToggle:Set(AutoJumpEnabled)
end

-- ==================== SETUP TAB 1: TỐC ĐỘ & BAY ====================

FlyToggle = MainTab:CreateToggle({
   Name = "Chế Độ Bay - Fly Mode (P)",
   CurrentValue = false,
   Flag = "FlyToggleKey",
   Callback = function(Value)
       if Value ~= FlyEnabled then toggleFly(Value) end
   end,
})

SpeedToggle = MainTab:CreateToggle({
   Name = "Chạy Nhanh - Speed Hack (L.Shift)",
   CurrentValue = false,
   Flag = "SpeedToggleKey",
   Callback = function(Value)
       if Value ~= SpeedLockEnabled then toggleSpeedLock(Value) end
   end,
})

SpeedSlider = MainTab:CreateSlider({
   Name = "Tùy Chỉnh Tốc Độ Chạy",
   Min = 16,
   Max = 150,
   CurrentValue = 45,
   Flag = "TargetSpeedSlider",
   Callback = function(Value)
       TargetSpeed = Value
   end,
})

-- ==================== SETUP TAB 2: BỔ TRỢ DI CHUYỂN ====================

DashFwdToggle = MovementTab:CreateToggle({
   Name = "Emote Dash Tiến (=)",
   CurrentValue = false,
   Flag = "DashFwdKey",
   Callback = function(Value)
       if Value ~= DashForwardEnabled then toggleDashForward(Value) end
   end,
})

DashBwdToggle = MovementTab:CreateToggle({
   Name = "Emote Dash Lùi (-)",
   CurrentValue = false,
   Flag = "DashBwdKey",
   Callback = function(Value)
       if Value ~= DashBackwardEnabled then toggleDashBackward(Value) end
   end,
})

SlideToggle = MovementTab:CreateToggle({
   Name = "Auto Slide Macro (Nhấp Ctrl)",
   CurrentValue = false,
   Flag = "SlideKey",
   Callback = function(Value)
       if Value ~= AutoSlideEnabled then toggleAutoSlide(Value) end
   end,
})

JumpToggle = MovementTab:CreateToggle({
   Name = "Auto Jump - Tự Động Nhảy (J)",
   CurrentValue = false,
   Flag = "JumpKey",
   Callback = function(Value)
       if Value ~= AutoJumpEnabled then toggleAutoJump(Value) end
   end,
})

-- ==================== SETUP TAB 3: CỨU TRỢ & ĐÓNG SCRIPT ====================

-- Khai báo hàm cứu trước để nút bấm gọi lệnh
local executeRescueOperation

local RescueButton = CombatTab:CreateButton({
   Name = "Window Rescue - Cứu Đồng Đội (R)",
   Callback = function()
       executeRescueOperation()
   end,
})

local CloseButton = CombatTab:CreateButton({
   Name = "🔴 ĐÓNG TOÀN BỘ SCRIPT",
   Callback = function()
       ScriptRunning = false
       FlyEnabled = false
       SpeedLockEnabled = false
       DashForwardEnabled = false
       DashBackwardEnabled = false
       AutoSlideEnabled = false
       AutoJumpEnabled = false
       cleanDashPhysics()
       -- Xóa ESP cũ
       for _, drawings in pairs(game:GetService("Workspace"):GetChildren()) do
           -- Đoạn loop gốc của ông dọn dẹp vẽ Drawing
       end
       Rayfield:Destroy()
   end,
})

-- === LOOPS THỰC THI (GIỮ NGUYÊN LOGIC GỐC CỦA ÔNG) ===
task.spawn(function()
    while ScriptRunning do
        if AutoJumpEnabled and not FlyEnabled and not IsProcessingRescue then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local root = char and char:FindFirstChild("HumanoidRootPart")
            
            if hum and root and (hum.FloorMaterial ~= Enum.Material.Air or root.AssemblyLinearVelocity.Y <= 0) then
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                task.wait(0.015)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
                task.wait(0.05)
            else
                task.wait(0.01)
            end
        else
            task.wait(0.1)
        end
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

-- === CORE RUNTIME ENGINE (GIỮ NGUYÊN) ===
RunService.Heartbeat:Connect(function(deltaTime)
    if not ScriptRunning then return end
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    
    if not root or not hum or IsProcessingRescue then 
        cleanDashPhysics()
        return 
    end
    
    -- 1. Fly Mode
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
    
    -- 2. Emote Dash Tiến
    elseif DashForwardEnabled then
        local camLook = Camera.CFrame.LookVector
        local flatDirection = Vector3.new(camLook.X, 0, camLook.Z).Unit
        local targetVel = flatDirection * TargetSpeed

        if not DashVelocity or not DashVelocity.Parent then
            cleanDashPhysics()
            DashAttachment = Instance.new("Attachment")
            DashAttachment.Parent = root
            
            DashVelocity = Instance.new("LinearVelocity")
            DashVelocity.Attachment0 = DashAttachment
            DashVelocity.MaxForce = math.huge
            
            DashVelocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
            DashVelocity.PrimaryTangentAxis = Vector3.new(1, 0, 0)
            DashVelocity.SecondaryTangentAxis = Vector3.new(0, 0, 1)
            DashVelocity.Parent = root
        end

        DashVelocity.PlaneVelocity = Vector2.new(targetVel.X, targetVel.Z)

        if root.AssemblyLinearVelocity.Y > 28 then
            root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 28, root.AssemblyLinearVelocity.Z)
        end
        
    -- 3. Emote Dash Lùi
    elseif DashBackwardEnabled then
        local camLook = Camera.CFrame.LookVector
        local flatDirection = Vector3.new(camLook.X, 0, camLook.Z).Unit
        local targetVel = -flatDirection * TargetSpeed

        if not DashVelocity or not DashVelocity.Parent then
            cleanDashPhysics()
            DashAttachment = Instance.new("Attachment")
            DashAttachment.Parent = root
            
            DashVelocity = Instance.new("LinearVelocity")
            DashVelocity.Attachment0 = DashAttachment
            DashVelocity.MaxForce = math.huge
            DashVelocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
            DashVelocity.PrimaryTangentAxis = Vector3.new(1, 0, 0)
            DashVelocity.SecondaryTangentAxis = Vector3.new(0, 0, 1)
            DashVelocity.Parent = root
        end

        DashVelocity.PlaneVelocity = Vector2.new(targetVel.X, targetVel.Z)

        if root.AssemblyLinearVelocity.Y > 28 then
            root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 28, root.AssemblyLinearVelocity.Z)
        end

    -- 4. Speed Hack
    else
        cleanDashPhysics()
        if SpeedLockEnabled and hum.MoveDirection.Magnitude > 0 then
            local customMove = hum.MoveDirection * TargetSpeed * deltaTime
            root.CFrame = root.CFrame + customMove
        end
    end
end)

-- === ACTIVE GLOBAL THREAT SCANNER & ESP ENGINE (GIỮ NGUYÊN) ===
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

-- === BASE STATUS CHECKER & RADAR (GIỮ NGUYÊN) ===
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
executeRescueOperation = function()
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

-- === KEYBINDS MAPPING (ĐỒNG BỘ PHÍM BẤM VÀ CÔNG TẮC UI) ===
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed or not ScriptRunning then return end
    if input.KeyCode == Enum.KeyCode.P then toggleFly()
    elseif input.KeyCode == Enum.KeyCode.LeftShift and not FlyEnabled then toggleSpeedLock()
    elseif input.KeyCode == Enum.KeyCode.R then executeRescueOperation()
    elseif input.KeyCode == Enum.KeyCode.Equals then toggleDashForward()
    elseif input.KeyCode == Enum.KeyCode.Minus then toggleDashBackward()
    elseif input.KeyCode == Enum.KeyCode.J then toggleAutoJump() 
    end
    -- Lưu ý: Rayfield tự xử lý nút đóng mở Menu riêng (mặc định là phím RightControl).
    -- Nên tôi bỏ phần map thủ công RightShift cũ để tránh xung đột UI.
end)

-- Gửi thông báo khi nạp xong script
Rayfield:Notify({Title = "Evade Multimod", Content = "Đã chuyển đổi sang Rayfield UI hoàn tất!", Duration = 4})
