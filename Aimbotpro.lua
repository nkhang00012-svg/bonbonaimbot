--[[
    bonbon script V5.5 - Avatar Profile ESP & Instant TP Edition
    Advanced Aim Assist, Real-Time Profile Picture ESP & Combat Teleportation
    UI Style: Cyder / Cyberpunk Neon
    Latest Features:
      - ESP System upgraded: Displays players' real Roblox Avatar Pictures instead of simple boxes.
      - Dynamic Scale: Image frames resize and calculate distances smoothly over the target's head.
      - Integrated PC Key 'P' and Mobile Round Floating button for instant 1-sec TP back attack.
    Support: PC (Keyboard) & Mobile (On-screen Buttons)
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- === SYSTEM CONFIGURATION ===
local IsAimEnabled = true
local IsWallbangEnabled = false
local IsTeamCheckEnabled = true 
local IsAutoClickEnabled = false 
local IsAutoHoldEnabled = false  
local IsEspEnabled = true        
local MaxWhitelist = 10
local Whitelist = {}
local FOVRadius = 400            

local IsHoldingMouse = false     
local EspStorage = {}            -- Container for BillboardGuis
local LastHoldTime = 0           
local IsInResetCooldown = false  
local SafeJamTimer = 0           

-- Combat State Variables
local CurrentLockedTarget = nil
local IsTeleporting = false
local BackAlertMode = 0 

-- === UI CREATION (CYDER STYLE) ===
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BonbonScriptV55"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 300, 0, 550) 
MainFrame.Position = UDim2.new(0.05, 0, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(0, 255, 150)
UIStroke.Thickness = 2
UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
UIStroke.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 45)
Title.Text = "BONBON IMAGE ESP // V5.5"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 16
Title.Font = Enum.Font.RobotoMono
Title.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
Title.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = Title

local TitleStroke = Instance.new("UIStroke")
TitleStroke.Color = Color3.fromRGB(0, 255, 150)
TitleStroke.Thickness = 1
TitleStroke.Parent = Title

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -20, 0, 30)
StatusLabel.Position = UDim2.new(0, 15, 0, 55)
StatusLabel.Text = "TARGET: NONE"
StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.BackgroundTransparency = 1
StatusLabel.Font = Enum.Font.SourceSansBold
StatusLabel.TextSize = 15
StatusLabel.Parent = MainFrame

local ButtonContainer = Instance.new("Frame")
ButtonContainer.Size = UDim2.new(1, -20, 0, 265)
ButtonContainer.Position = UDim2.new(0, 10, 0, 90)
ButtonContainer.BackgroundTransparency = 1
ButtonContainer.Parent = MainFrame

local UIGridLayout = Instance.new("UIGridLayout")
UIGridLayout.CellSize = UDim2.new(1, 0, 0, 32)
UIGridLayout.CellPadding = UDim2.new(0, 0, 0, 6)
UIGridLayout.Parent = ButtonContainer

local function createCyberButton(text, color, parent)
    local btn = Instance.new("TextButton")
    btn.Text = text
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 14
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.BackgroundColor3 = color
    btn.BorderSizePixel = 0
    btn.Parent = parent
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn
    return btn
end

local ToggleAimBtn = createCyberButton("AIM ASSIST: ON (Q)", Color3.fromRGB(0, 150, 90), ButtonContainer)
local ToggleWallBtn = createCyberButton("WALLBANG: OFF (T)", Color3.fromRGB(150, 0, 50), ButtonContainer)
local ToggleTeamBtn = createCyberButton("TEAM CHECK: ON (Y)", Color3.fromRGB(0, 120, 200), ButtonContainer)
local ToggleAutoClickBtn = createCyberButton("AUTO CLICK: OFF (G)", Color3.fromRGB(150, 0, 50), ButtonContainer)
local ToggleAutoHoldBtn = createCyberButton("ANTI-JAM HOLD: OFF (H)", Color3.fromRGB(150, 0, 50), ButtonContainer) 
local ToggleEspBtn = createCyberButton("IMAGE ESP: ON (J)", Color3.fromRGB(0, 150, 90), ButtonContainer)
local ToggleBackAlertBtn = createCyberButton("BACK ALERT: OFF (K)", Color3.fromRGB(150, 0, 50), ButtonContainer)

-- FLOATING ROUND BUTTON FOR MOBILE (ALWAYS VISIBLE)
local FloatingTpBtn = Instance.new("TextButton")
FloatingTpBtn.Size = UDim2.new(0, 70, 0, 70)
FloatingTpBtn.Position = UDim2.new(0.75, 0, 0.35, 0)
FloatingTpBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 150)
FloatingTpBtn.TextColor3 = Color3.fromRGB(15, 15, 20)
FloatingTpBtn.Text = "TP"
FloatingTpBtn.Font = Enum.Font.SourceSansBold
FloatingTpBtn.TextSize = 22
FloatingTpBtn.Visible = true 
FloatingTpBtn.Active = true
FloatingTpBtn.Draggable = true
FloatingTpBtn.Parent = ScreenGui

local FloatingCorner = Instance.new("UICorner")
FloatingCorner.CornerRadius = UDim.new(1, 0)
FloatingCorner.Parent = FloatingTpBtn

local FloatingStroke = Instance.new("UIStroke")
FloatingStroke.Color = Color3.fromRGB(255, 255, 255)
FloatingStroke.Thickness = 2.5
FloatingStroke.Parent = FloatingTpBtn

-- FULL-SCREEN ALERT UI
local ScreenWarningFrame = Instance.new("Frame")
ScreenWarningFrame.Size = UDim2.new(1, 0, 1, 0)
ScreenWarningFrame.BackgroundTransparency = 1
ScreenWarningFrame.Visible = false
ScreenWarningFrame.Parent = ScreenGui

local WarningStroke = Instance.new("UIStroke")
WarningStroke.Color = Color3.fromRGB(255, 0, 50)
WarningStroke.Thickness = 6
WarningStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
WarningStroke.Parent = ScreenWarningFrame

local WarningText = Instance.new("TextLabel")
WarningText.Size = UDim2.new(0, 500, 0, 50)
WarningText.Position = UDim2.new(0.5, -250, 0.25, -25)
WarningText.BackgroundTransparency = 1
WarningText.Text = "⚠️ ENEMY DETECTED BEHIND ⚠️"
WarningText.TextColor3 = Color3.fromRGB(255, 0, 50)
WarningText.Font = Enum.Font.SourceSansBold
WarningText.TextSize = 26
WarningText.Parent = ScreenWarningFrame

-- FOV Configuration Labels
local FOVLabel = Instance.new("TextLabel")
FOVLabel.Size = UDim2.new(1, -20, 0, 20)
FOVLabel.Position = UDim2.new(0, 15, 0, 365)
FOVLabel.Text = "FOV RADIUS: " .. FOVRadius
FOVLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
FOVLabel.BackgroundTransparency = 1
FOVLabel.TextXAlignment = Enum.TextXAlignment.Left
FOVLabel.Font = Enum.Font.SourceSansBold
FOVLabel.Parent = MainFrame

local FOVSlider = Instance.new("TextBox")
FOVSlider.Size = UDim2.new(1, -25, 0, 30)
FOVSlider.Position = UDim2.new(0, 12, 0, 390)
FOVSlider.Text = tostring(FOVRadius)
FOVSlider.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
FOVSlider.TextColor3 = Color3.fromRGB(0, 255, 150)
FOVSlider.Font = Enum.Font.Code
FOVSlider.TextSize = 14
FOVSlider.PlaceholderText = "Enter FOV value..."
FOVSlider.Parent = MainFrame

local FOVBoxCorner = Instance.new("UICorner")
FOVBoxCorner.CornerRadius = UDim.new(0, 6)
FOVBoxCorner.Parent = FOVSlider

local FOVBoxStroke = Instance.new("UIStroke")
FOVBoxStroke.Color = Color3.fromRGB(45, 45, 60)
FOVBoxStroke.Thickness = 1
FOVBoxStroke.Parent = FOVSlider

-- Whitelist Components
local WhitelistTitle = Instance.new("TextLabel")
WhitelistTitle.Size = UDim2.new(0, 100, 0, 30)
WhitelistTitle.Position = UDim2.new(0, 15, 0, 430)
WhitelistTitle.Text = "WHITELIST"
WhitelistTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
WhitelistTitle.TextXAlignment = Enum.TextXAlignment.Left
WhitelistTitle.BackgroundTransparency = 1
WhitelistTitle.Font = Enum.Font.SourceSansBold
WhitelistTitle.TextSize = 15
WhitelistTitle.Parent = MainFrame

local AddWhitelistBtn = Instance.new("TextButton")
AddWhitelistBtn.Size = UDim2.new(0, 30, 0, 25)
AddWhitelistBtn.Position = UDim2.new(0, 100, 0, 432)
AddWhitelistBtn.Text = "+"
AddWhitelistBtn.TextSize = 18
AddWhitelistBtn.Font = Enum.Font.SourceSansBold
AddWhitelistBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 150)
AddWhitelistBtn.TextColor3 = Color3.fromRGB(15, 15, 20)
AddWhitelistBtn.Parent = MainFrame

local AddCorner = Instance.new("UICorner")
AddCorner.CornerRadius = UDim.new(0, 4)
AddCorner.Parent = AddWhitelistBtn

local WhitelistListLabel = Instance.new("TextLabel")
WhitelistListLabel.Size = UDim2.new(1, -30, 0, 75)
WhitelistListLabel.Position = UDim2.new(0, 15, 0, 465)
WhitelistListLabel.Text = "Whitelist empty"
WhitelistListLabel.TextColor3 = Color3.fromRGB(120, 120, 140)
WhitelistListLabel.TextYAlignment = Enum.TextYAlignment.Top
WhitelistListLabel.TextXAlignment = Enum.TextXAlignment.Left
WhitelistListLabel.BackgroundTransparency = 1
WhitelistListLabel.Font = Enum.Font.SourceSansItalic
WhitelistListLabel.TextSize = 14
WhitelistListLabel.TextWrapped = true
WhitelistListLabel.Parent = MainFrame

-- === DRAWING FOV CIRCLE ===
local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = Color3.fromRGB(0, 255, 150)
FOVCircle.Thickness = 1.5
FOVCircle.NumSides = 64
FOVCircle.Radius = FOVRadius
FOVCircle.Filled = false
FOVCircle.Visible = true

-- === ADVANCED AVATAR IMAGE ESP ENGINE ===
local function createPlayerImageEsp(player)
    if EspStorage[player] then return end
    if not player.Character or not player.Character:FindFirstChild("Head") then return end

    -- Setup 3D Billboard Interface gham trên đầu mục tiêu
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "BonbonAvatarEsp_" .. player.Name
    billboard.Size = UDim2.new(0, 55, 0, 70) 
    billboard.Adornee = player.Character:WaitForChild("Head")
    billboard.AlwaysOnTop = true
    billboard.ExtentsOffset = Vector3.new(0, 2.5, 0) -- Higher offset above head
    billboard.Parent = ScreenGui

    -- Neon Cyder border container
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 55)
    container.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    container.Parent = billboard
    
    local containerCorner = Instance.new("UICorner")
    containerCorner.CornerRadius = UDim.new(0, 8)
    containerCorner.Parent = container

    local containerStroke = Instance.new("UIStroke")
    containerStroke.Color = Color3.fromRGB(0, 255, 150)
    containerStroke.Thickness = 1.5
    containerStroke.Parent = container

    -- Player Avatar Loader
    local imageLabel = Instance.new("ImageLabel")
    imageLabel.Size = UDim2.new(1, -4, 1, -4)
    imageLabel.Position = UDim2.new(0, 2, 0, 2)
    imageLabel.BackgroundTransparency = 1
    imageLabel.Parent = container
    
    local imgCorner = Instance.new("UICorner")
    imgCorner.CornerRadius = UDim.new(0, 6)
    imgCorner.Parent = imageLabel

    -- Dynamic text tags (Name + Distance displayer)
    local nameTag = Instance.new("TextLabel")
    nameTag.Size = UDim2.new(2, 0, 0, 15)
    nameTag.Position = UDim2.new(-0.5, 0, 1, 2)
    nameTag.BackgroundTransparency = 1
    nameTag.Text = string.upper(player.DisplayName)
    nameTag.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameTag.Font = Enum.Font.SourceSansBold
    nameTag.TextSize = 11
    nameTag.Parent = container

    local textStroke = Instance.new("UIStroke")
    textStroke.Color = Color3.fromRGB(0, 0, 0)
    textStroke.Thickness = 1
    textStroke.Parent = nameTag

    -- Async content background fetch image thread
    task.spawn(function()
        local userId = player.UserId
        local thumbType = Enum.ThumbnailType.HeadShot
        local thumbSize = Enum.ThumbnailSize.Size100x100
        local content, isReady = Players:GetUserThumbnailAsync(userId, thumbType, thumbSize)
        if isReady then
            imageLabel.Image = content
        else
            imageLabel.Image = "rbxassetid://0" -- Fallback if failed
        end
    end)

    EspStorage[player] = {
        Gui = billboard,
        NameLabel = nameTag
    }
end

local function removePlayerImageEsp(player)
    if EspStorage[player] then
        if EspStorage[player].Gui then
            EspStorage[player].Gui:Destroy()
        end
        EspStorage[player] = nil
    end
end

-- === SYSTEM RAYCAST DETECTORS ===
local function isWallBetween(targetPart)
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return true end
    local origin = Camera.CFrame.Position
    local direction = targetPart.Position - origin
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {character, targetPart.Parent}
    local raycastResult = workspace:Raycast(origin, direction, raycastParams)
    return raycastResult ~= nil
end

local function isValidTarget(player)
    if not player or not player.Character then return false end
    if table.find(Whitelist, player.Name) then return false end
    if IsTeamCheckEnabled and player.Team == LocalPlayer.Team then return false end
    
    local head = player.Character:FindFirstChild("Head")
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    if not head or not humanoid or humanoid.Health <= 0 then return false end
    
    if isWallBetween(head) and not IsWallbangEnabled then return false end
    return true
end

-- === PRIORITY LOCKING TARGET COMPILER ===
local function getBestPriorityTarget()
    if CurrentLockedTarget and isValidTarget(CurrentLockedTarget) then
        return CurrentLockedTarget
    end
    
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return nil end
    local myRoot = character.HumanoidRootPart
    local mousePos = UserInputService:GetMouseLocation()
    
    local bestBackTarget = nil
    local shortestBackDistance = math.huge
    local bestFrontTarget = nil
    local shortestFrontDistance = math.huge

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and not table.find(Whitelist, player.Name) then
            if IsTeamCheckEnabled and player.Team == LocalPlayer.Team then continue end
            
            local head = player.Character:FindFirstChild("Head")
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            
            if head and humanoid and humanoid.Health > 0 then
                local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
                local studDistance = (head.Position - myRoot.Position).Magnitude
                
                if not onScreen and studDistance <= 250 and not isWallBetween(head) then
                    local distanceToMouse = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    if distanceToMouse < shortestBackDistance then
                        shortestBackDistance = distanceToMouse
                        bestBackTarget = player
                    end
                elseif onScreen and not bestBackTarget then
                    local distanceToMouse = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    if distanceToMouse <= FOVRadius then
                        local canTarget = IsWallbangEnabled or not isWallBetween(head)
                        if canTarget and distanceToMouse < shortestFrontDistance then
                            shortestFrontDistance = distanceToMouse
                            bestFrontTarget = player
                        end
                    end
                end
            end
        end
    end
    return bestBackTarget or bestFrontTarget
end

-- === ONE-CLICK INSTANT TELEPORT METHOD ===
local function executeInstantTpBack()
    if IsTeleporting then return end
    if not CurrentLockedTarget or not CurrentLockedTarget.Character then return end
    
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local enemyRoot = CurrentLockedTarget.Character:FindFirstChild("HumanoidRootPart")
    local enemyHumanoid = CurrentLockedTarget.Character:FindFirstChildOfClass("Humanoid")
    
    if myRoot and enemyRoot and enemyHumanoid and enemyHumanoid.Health > 0 then
        IsTeleporting = true
        local originalCFrame = myRoot.CFrame
        
        -- Land 3 studs directly behind the targeted model
        local behindPosition = enemyRoot.CFrame * CFrame.new(0, 0, 3)
        myRoot.CFrame = behindPosition
        
        -- Delay hold exactly 1.0 second, then warp back safely
        task.delay(1.0, function()
            if myRoot then
                myRoot.CFrame = originalCFrame
            end
            IsTeleporting = false
        end)
    end
end

-- === REFRESH INTERFACE STATES ===
local function refreshButtonsUI()
    ToggleAimBtn.Text = IsAimEnabled and "AIM ASSIST: ON (Q)" or "AIM ASSIST: OFF (Q)"
    ToggleAimBtn.BackgroundColor3 = IsAimEnabled and Color3.fromRGB(0, 150, 90) or Color3.fromRGB(150, 0, 50)
    ToggleWallBtn.Text = IsWallbangEnabled and "WALLBANG: OFF (T)" or "WALLBANG: ON (T)"
    ToggleWallBtn.BackgroundColor3 = IsWallbangEnabled and Color3.fromRGB(0, 150, 90) or Color3.fromRGB(150, 0, 50)
    ToggleTeamBtn.Text = IsTeamCheckEnabled and "TEAM CHECK: ON (Y)" or "TEAM CHECK: OFF (Y)"
    ToggleTeamBtn.BackgroundColor3 = IsTeamCheckEnabled and Color3.fromRGB(0, 120, 200) or Color3.fromRGB(150, 0, 50)
    ToggleAutoClickBtn.Text = IsAutoClickEnabled and "AUTO CLICK: ON (G)" or "AUTO CLICK: OFF (G)"
    ToggleAutoClickBtn.BackgroundColor3 = IsAutoClickEnabled and Color3.fromRGB(0, 150, 90) or Color3.fromRGB(150, 0, 50)
    ToggleAutoHoldBtn.Text = IsAutoHoldEnabled and "ANTI-JAM HOLD: ON (H)" or "ANTI-JAM HOLD: OFF (H)"
    ToggleAutoHoldBtn.BackgroundColor3 = IsAutoHoldEnabled and Color3.fromRGB(0, 150, 90) or Color3.fromRGB(150, 0, 50)
    ToggleEspBtn.Text = IsEspEnabled and "IMAGE ESP: ON (J)" or "IMAGE ESP: OFF (J)"
    ToggleEspBtn.BackgroundColor3 = IsEspEnabled and Color3.fromRGB(0, 150, 90) or Color3.fromRGB(150, 0, 50)
    
    if BackAlertMode == 0 then
        ToggleBackAlertBtn.Text = "BACK ALERT: OFF (K)"
        ToggleBackAlertBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 50)
    elseif BackAlertMode == 1 then
        ToggleBackAlertBtn.Text = "BACK ALERT: WARN ONLY (K)"
        ToggleBackAlertBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 0)
    elseif BackAlertMode == 2 then
        ToggleBackAlertBtn.Text = "BACK ALERT: WARN + LOCK (K)"
        ToggleBackAlertBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 90)
    end
end

local function releaseMouseSafely(mousePos)
    if IsHoldingMouse then
        VirtualInputManager:SendMouseButtonEvent(mousePos.X, mousePos.Y, 0, false, game, 1)
        IsHoldingMouse = false
    end
end

-- === INTERACTIVE UI SIGNALS ===
ToggleBackAlertBtn.MouseButton1Click:Connect(function() BackAlertMode = (BackAlertMode + 1) % 3 if BackAlertMode == 0 then ScreenWarningFrame.Visible = false end refreshButtonsUI() end)
FOVSlider.FocusLost:Connect(function() local num = tonumber(FOVSlider.Text) if num then FOVRadius = num FOVCircle.Radius = num FOVLabel.Text = "FOV RADIUS: " .. num else FOVSlider.Text = tostring(FOVRadius) end end)
ToggleAimBtn.MouseButton1Click:Connect(function() IsAimEnabled = not IsAimEnabled CurrentLockedTarget = nil refreshButtonsUI() end)
ToggleWallBtn.MouseButton1Click:Connect(function() IsWallbangEnabled = not IsWallbangEnabled refreshButtonsUI() end)
ToggleTeamBtn.MouseButton1Click:Connect(function() IsTeamCheckEnabled = not IsTeamCheckEnabled refreshButtonsUI() end)
ToggleAutoClickBtn.MouseButton1Click:Connect(function() IsAutoClickEnabled = not IsAutoClickEnabled if IsAutoClickEnabled then IsAutoHoldEnabled = false IsInResetCooldown = false releaseMouseSafely(UserInputService:GetMouseLocation()) end refreshButtonsUI() end)
ToggleAutoHoldBtn.MouseButton1Click:Connect(function() IsAutoHoldEnabled = not IsAutoHoldEnabled if IsAutoHoldEnabled then IsAutoClickEnabled = false IsInResetCooldown = false SafeJamTimer = 0 end if not IsAutoHoldEnabled then releaseMouseSafely(UserInputService:GetMouseLocation()) end refreshButtonsUI() end)

ToggleEspBtn.MouseButton1Click:Connect(function() 
    IsEspEnabled = not IsEspEnabled 
    if not IsEspEnabled then 
        for _, p in pairs(Players:GetPlayers()) do removePlayerImageEsp(p) end 
    end 
    refreshButtonsUI() 
end)

FloatingTpBtn.MouseButton1Click:Connect(executeInstantTpBack)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    local mousePos = UserInputService:GetMouseLocation()
    if input.KeyCode == Enum.KeyCode.Q then IsAimEnabled = not IsAimEnabled CurrentLockedTarget = nil refreshButtonsUI()
    elseif input.KeyCode == Enum.KeyCode.T then IsWallbangEnabled = not IsWallbangEnabled refreshButtonsUI()
    elseif input.KeyCode == Enum.KeyCode.Y then IsTeamCheckEnabled = not IsTeamCheckEnabled refreshButtonsUI()
    elseif input.KeyCode == Enum.KeyCode.G then IsAutoClickEnabled = not IsAutoClickEnabled if IsAutoClickEnabled then IsAutoHoldEnabled = false IsInResetCooldown = false releaseMouseSafely(mousePos) end refreshButtonsUI()
    elseif input.KeyCode == Enum.KeyCode.H then IsAutoHoldEnabled = not IsAutoHoldEnabled if IsAutoHoldEnabled then IsAutoClickEnabled = false IsInResetCooldown = false SafeJamTimer = 0 end if not IsAutoHoldEnabled then releaseMouseSafely(mousePos) end refreshButtonsUI()
    elseif input.KeyCode == Enum.KeyCode.J then IsEspEnabled = not IsEspEnabled if not IsEspEnabled then for _, p in pairs(Players:GetPlayers()) do removePlayerImageEsp(p) end end refreshButtonsUI()
    elseif input.KeyCode == Enum.KeyCode.K then BackAlertMode = (BackAlertMode + 1) % 3 if BackAlertMode == 0 then ScreenWarningFrame.Visible = false end refreshButtonsUI()
    elseif input.KeyCode == Enum.KeyCode.P then executeInstantTpBack() 
    elseif input.KeyCode == Enum.KeyCode.RightShift then MainFrame.Visible = not MainFrame.Visible FOVCircle.Visible = MainFrame.Visible FloatingTpBtn.Visible = MainFrame.Visible end
end)

-- Clean handles when player leaves server
Players.PlayerRemoving:Connect(removePlayerImageEsp)

-- === CORE RENDERING & CALCULATION LOOP ===
RunService.RenderStepped:Connect(function()
    local mousePos = UserInputService:GetMouseLocation()
    FOVCircle.Position = mousePos
    
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    
    if ScreenWarningFrame.Visible then
        WarningStroke.Color = Color3.fromHSV((tick() * 2) % 1, 1, 1)
    end
    
    CurrentLockedTarget = getBestPriorityTarget()
    local target = CurrentLockedTarget
    
    if BackAlertMode > 0 and target then
        local head = target.Character:FindFirstChild("Head")
        if head then
            local _, onScreen = Camera:WorldToViewportPoint(head.Position)
            ScreenWarningFrame.Visible = not onScreen
        end
    else
        ScreenWarningFrame.Visible = false
    end
    
    -- TRACKING LOCK ENGINE
    if IsAimEnabled and target and target.Character and target.Character:FindFirstChild("Head") then
        local humanoid = target.Character:FindFirstChildOfClass("Humanoid")
        StatusLabel.Text = "LOCKED: " .. string.upper(target.DisplayName) .. " (@" .. target.Name .. ")"
        
        local headPos = target.Character.Head.Position
        Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, headPos)
        
        if IsAutoClickEnabled then
            VirtualInputManager:SendMouseButtonEvent(mousePos.X, mousePos.Y, 0, true, game, 1)
            task.wait()
            VirtualInputManager:SendMouseButtonEvent(mousePos.X, mousePos.Y, 0, false, game, 1)
        elseif IsAutoHoldEnabled and humanoid and humanoid.Health > 0 then
            local currentTime = tick()
            if IsInResetCooldown then
                if currentTime - LastHoldTime >= 0.5 then IsInResetCooldown = false SafeJamTimer = 0 else releaseMouseSafely(mousePos) end
            end
            
            if not IsInResetCooldown then
                if not IsHoldingMouse then
                    VirtualInputManager:SendMouseButtonEvent(mousePos.X, mousePos.Y, 0, true, game, 1) 
                    IsHoldingMouse = true
                    LastHoldTime = currentTime
                else
                    SafeJamTimer = SafeJamTimer + RunService.RenderStepped:Wait() 
                    if SafeJamTimer >= 1.2 then 
                        VirtualInputManager:SendMouseButtonEvent(mousePos.X, mousePos.Y, 0, false, game, 1) 
                        IsHoldingMouse = false
                        IsInResetCooldown = true 
                        LastHoldTime = tick()
                    end
                end
            end
        else releaseMouseSafely(mousePos) end
    else
        StatusLabel.Text = "TARGET: NONE"
        CurrentLockedTarget = nil
        IsInResetCooldown = false 
        SafeJamTimer = 0
        releaseMouseSafely(mousePos)
    end
    
    -- AVATAR ESP GRAPHICS MODULATOR
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            -- Validation check to clear or create profile tags
            if not IsEspEnabled or (IsTeamCheckEnabled and player.Team == LocalPlayer.Team) or table.find(Whitelist, player.Name) then
                removePlayerImageEsp(player)
                continue
            end
            
            local char = player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local head = char and char:FindFirstChild("Head")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            
            if root and head and hum and hum.Health > 0 and myRoot then
                local _, onScreen = Camera:WorldToViewportPoint(root.Position)
                if onScreen then
                    createPlayerImageEsp(player)
                    
                    -- Dynamic distance tracking text updater
                    local esp = EspStorage[player]
                    if esp then
                        local distance = math.floor((root.Position - myRoot.Position).Magnitude)
                        esp.NameLabel.Text = string.upper(player.DisplayName) .. " [" .. distance .. "M]"
                    end
                else
                    removePlayerImageEsp(player)
                end
            else
                removePlayerImageEsp(player)
            end
        end
    end
end)
