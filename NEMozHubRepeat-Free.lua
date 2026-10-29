local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Tranhoanam/Test-2/refs/heads/main/8.lua"))()

local Window = Library:CreateWindow({
    Name = "NEMoz Hub Repeat"
})

local Tab = Window:CreateTab("Loop", "124620632231839")
local Tab2 = Window:CreateTab("Auto click", "139650104834071")
local Tab3 = Window:CreateTab("Camera", "117259180607823")
local Tab4 = Window:CreateTab("Troll", "111033757146676")
local Tab5 = Window:CreateTab("Information", "99559214342519")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local isRecording = false
local isRepeating = false
local recordedActions = {}
local waitRepeatTime = 1
local playbackSpeed = 1 -- Mặc định tốc độ x1
local noclipConnection = nil

local function setNoclip(enabled)
    if not enabled then
        if noclipConnection then
            noclipConnection:Disconnect()
            noclipConnection = nil
        end
        local character = LocalPlayer.Character
        if character then
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
        return
    end

    if not noclipConnection then
        noclipConnection = RunService.Stepped:Connect(function()
            local character = LocalPlayer.Character
            if character then
                for _, part in ipairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
    end
end

Tab:CreateButton("Check action", function()
    recordedActions = {}
    isRecording = true
    task.spawn(function()
        while isRecording do
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hrp and hum then
                table.insert(recordedActions, {
                    Position = hrp.Position,
                    Jump = hum.Jump,
                    FloorMaterial = tostring(hum.FloorMaterial),
                    IsAirborne = (hum.FloorMaterial == Enum.Material.Air)
                })
            end
            task.wait(0.15)
        end
    end)
end)

Tab:CreateButton("End action", function()
    isRecording = false
end)

Tab:CreateToggle("Repeat", function(state)
    isRepeating = state
    if isRepeating and #recordedActions > 0 then
        task.spawn(function()
            while isRepeating do
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                
                if hrp and hum then
                    local i = 1
                    while i <= #recordedActions and isRepeating do
                        local action = recordedActions[i]
                        local targetPos = action.Position
                        local heightDiff = targetPos.Y - hrp.Position.Y
                        local isAir = action.IsAirborne or hum.FloorMaterial == Enum.Material.Air or heightDiff > 3
                        
                        -- Áp dụng hệ số tốc độ phát lại (Playback Speed)
                        if isAir or playbackSpeed > 5 then
                            setNoclip(true)
                            hum.PlatformStand = false
                            
                            local startTime = tick()
                            local maxWaitTime = math.max(0.02, 2.5 / playbackSpeed)
                            while isRepeating and (targetPos - hrp.Position).Magnitude > 3 and (tick() - startTime) < maxWaitTime do
                                local currentPos = hrp.Position
                                local dir = (targetPos - currentPos).Unit
                                local speedMultiplier = math.clamp(playbackSpeed, 1, 50)
                                hrp.AssemblyLinearVelocity = Vector3.new(dir.X * (20 * math.min(speedMultiplier, 35)), math.clamp(dir.Y * 20, -10, 20), dir.Z * (20 * math.min(speedMultiplier, 35)))
                                hrp.CFrame = CFrame.new(currentPos, Vector3.new(targetPos.X, currentPos.Y, targetPos.Z))
                                RunService.RenderStepped:Wait()
                            end
                            setNoclip(false)
                        else
                            hum.PlatformStand = false
                            setNoclip(false)
                            hum:MoveTo(targetPos)
                            if action.Jump then
                                hum.Jump = true
                            end
                            
                            local moveStart = tick()
                            local maxWaitTime = math.max(0.02, 2 / playbackSpeed)
                            while isRepeating and (targetPos - hrp.Position).Magnitude > 3.5 and (tick() - moveStart) < maxWaitTime do
                                -- 4.3: Cảm nhận mắc kẹt và tự động bật/tắt noclip chuẩn xác theo tốc độ
                                local preCheckPos = hrp.Position
                                task.wait(math.max(0.01, 0.2 / playbackSpeed))
                                local postCheckPos = hrp.Position
                                
                                if (postCheckPos - preCheckPos).Magnitude < (0.2 * math.min(playbackSpeed, 5)) then
                                    setNoclip(true)
                                    hrp.AssemblyLinearVelocity = Vector3.new(0, 25, 0)
                                    task.wait(0.1 / playbackSpeed)
                                    setNoclip(false)
                                    break
                                end
                                RunService.RenderStepped:Wait()
                            end
                        end
                        
                        if hum.FloorMaterial ~= Enum.Material.Air then
                            setNoclip(false)
                        end
                        
                        -- Tua nhanh qua các mốc tọa độ tương ứng với mức Playback Speed
                        i = i + math.max(1, math.floor(playbackSpeed / 10))
                    end
                end
                
                task.wait(waitRepeatTime / math.clamp(playbackSpeed, 1, 10))
            end
            
            local c = LocalPlayer.Character
            local h = c and c:FindFirstChildOfClass("Humanoid")
            if h then h.PlatformStand = false end
            setNoclip(false)
        end)
    else
        local c = LocalPlayer.Character
        local h = c and c:FindFirstChildOfClass("Humanoid")
        if h then h.PlatformStand = false end
        setNoclip(false)
    end
end)

Tab:CreateSlider("Wait repeat (sec)", 1, 100, function(value)
    waitRepeatTime = value
end)

Tab:CreateSlider("Playback Speed", 1, 50, function(value)
    playbackSpeed = value
end)

-- =================================================================
-- TAB 2: SCREEN / TARGET AUTOMATION SYSTEM
-- =================================================================

local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")

-- Màn hình chứa toàn bộ UI Target Nổi & Menu Cấu Hình
local TargetGui = Instance.new("ScreenGui")
TargetGui.Name = "NEMoz_TargetSystem"
TargetGui.ResetOnSpawn = false
pcall(function()
    TargetGui.Parent = CoreGui
end)
if not TargetGui.Parent then
    TargetGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

-- Quản lý danh sách Target
local targets = {} -- { [id] = { Button = Frame, Delay = number, Index = number } }
local targetCount = 0
local isTargetRunning = false
-- Hàm hỗ trợ tạo hiệu ứng UI Stroke (Aura/Viền)
local function addAura(instance, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Color3.fromRGB(80, 150, 255)
    stroke.Thickness = thickness or 2
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = instance
    return stroke
end

-- Hàm hỗ trợ tạo Bo Góc (UICorner)
local function addCorner(instance, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = instance
    return corner
end

-- -----------------------------------------------------------------
-- HÀM TẠO POPUP MENU CẤU HÌNH CỐ ĐỊNH Ở GIỮA MÀN HÌNH
-- -----------------------------------------------------------------
local currentPopup = nil

local function openTargetMenu(targetData)
    if currentPopup then
        currentPopup:Destroy()
        currentPopup = nil
    end

    -- Khung Menu Nhỏ Chính
    local menuFrame = Instance.new("Frame")
    menuFrame.Name = "TargetMenu_" .. targetData.Index
    menuFrame.Size = UDim2.new(0, 260, 0, 140)
    menuFrame.Position = UDim2.new(0.5, -130, 0.5, -70) -- Chính giữa màn hình
    menuFrame.BackgroundColor3 = Color3.fromRGB(18, 19, 23)
    menuFrame.BorderSizePixel = 0
    menuFrame.Active = true
    menuFrame.ZIndex = 100
    menuFrame.Parent = TargetGui

    addCorner(menuFrame, 10)
    addAura(menuFrame, Color3.fromRGB(80, 150, 255), 2)

    -- Tiêu đề Menu
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -40, 0, 35)
    title.Position = UDim2.new(0, 10, 0, 5)
    title.BackgroundTransparency = 1
    title.Text = "Target #" .. targetData.Index .. " Settings"
    title.TextColor3 = Color3.fromRGB(80, 150, 255)
    title.TextSize = 16
    title.Font = Enum.Font.SourceSansBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 101
    title.Parent = menuFrame

    -- Nút Đóng (X)
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 25, 0, 25)
    closeBtn.Position = UDim2.new(1, -30, 0, 8)
    closeBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 14
    closeBtn.Font = Enum.Font.SourceSansBold
    closeBtn.ZIndex = 101
    closeBtn.Parent = menuFrame
    addCorner(closeBtn, 5)

    closeBtn.MouseButton1Click:Connect(function()
        menuFrame:Destroy()
        currentPopup = nil
    end)

    -- Nhãn "Wait repeat (sec)"
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 0, 25)
    label.Position = UDim2.new(0, 10, 0, 45)
    label.BackgroundTransparency = 1
    label.Text = "Wait repeat (sec) [Target " .. targetData.Index .. "]:"
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.TextSize = 13
    label.Font = Enum.Font.SourceSans
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 101
    label.Parent = menuFrame

    -- Ô Nhập Số (TextBox)
    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(1, -20, 0, 35)
    textBox.Position = UDim2.new(0, 10, 0, 80)
    textBox.BackgroundColor3 = Color3.fromRGB(28, 30, 36)
    textBox.Text = tostring(targetData.Delay)
    textBox.TextColor3 = Color3.fromRGB(80, 150, 255)
    textBox.TextSize = 16
    textBox.Font = Enum.Font.SourceSansBold
    textBox.PlaceholderText = "Enter waiting time (sec)..."
    textBox.ZIndex = 101
    textBox.Parent = menuFrame
    addCorner(textBox, 6)
    addAura(textBox, Color3.fromRGB(50, 60, 80), 1)

    textBox.FocusLost:Connect(function()
        local val = tonumber(textBox.Text)
        if val and val >= 0 then
            targetData.Delay = val
        else
            textBox.Text = tostring(targetData.Delay)
        end
    end)

    currentPopup = menuFrame
end

-- -----------------------------------------------------------------
-- HÀM TẠO NÚT NỔI (FLOATING TARGET BUTTON)
-- -----------------------------------------------------------------
local function createTargetButton()
    targetCount = targetCount + 1
    local id = targetCount

    -- Nút tròn nổi chính
    local floatFrame = Instance.new("ImageButton")
    floatFrame.Name = "Target_" .. id
    floatFrame.Size = UDim2.new(0, 50, 0, 50)
    floatFrame.Position = UDim2.new(0.5, -25 + (id * 15), 0.4, -25) -- Vị trí mặc định
    floatFrame.BackgroundColor3 = Color3.fromRGB(18, 19, 23)
    floatFrame.Image = "rbxassetid://136330318295086"
    floatFrame.ImageColor3 = Color3.fromRGB(255, 255, 255)
    floatFrame.Active = true
    floatFrame.ZIndex = 50
    floatFrame.Parent = TargetGui

    addCorner(floatFrame, 25) -- Tạo hình tròn hoàn chỉnh
    addAura(floatFrame, Color3.fromRGB(80, 150, 255), 3)

    -- Số Thứ Tự (Xanh lá)
    local numLabel = Instance.new("TextLabel")
    numLabel.Size = UDim2.new(1, 0, 1, 0)
    numLabel.BackgroundTransparency = 1
    numLabel.Text = tostring(id)
    numLabel.TextColor3 = Color3.fromRGB(80, 150, 255) -- Số màu xanh lá
    numLabel.TextSize = 20
    numLabel.Font = Enum.Font.SourceSansBold
    numLabel.ZIndex = 51
    numLabel.Parent = floatFrame

    -- Dữ liệu Target
    local targetData = {
        Button = floatFrame,
        Delay = 2, -- Mặc định 2 giây
        Index = id
    }
    targets[id] = targetData

    -- -------------------------------------------------------------
    -- CƠ CHẾ KÉO THẢ MƯỢT MÀ (SMOOTH DRAGGING & NO CLICK CONFLICT)
    -- -------------------------------------------------------------
    local dragging = false
    local dragInput, dragStart, startPos
    local hasDragged = false

    floatFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            hasDragged = false
            dragStart = input.Position
            startPos = floatFrame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    floatFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            if delta.Magnitude > 5 then
                hasDragged = true -- Đánh dấu là đang kéo thả, không phải nhấp chuột
            end
            floatFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)

    -- Khi nhấp vào nút nổi (chỉ mở menu nếu không kéo di chuyển)
    floatFrame.MouseButton1Click:Connect(function()
        if not hasDragged then
            openTargetMenu(targetData)
        end
    end)
end

-- -----------------------------------------------------------------
-- HÀM XÓA NÚT NỔI CÓ SỐ THỨ TỰ LỚN NHẤT
-- -----------------------------------------------------------------
local function deleteHighestTarget()
    if targetCount > 0 then
        local targetToDelete = targets[targetCount]
        if targetToDelete then
            if targetToDelete.Button then
                targetToDelete.Button:Destroy()
            end
            targets[targetCount] = nil
            targetCount = targetCount - 1
        end
    end
end

-- -----------------------------------------------------------------
-- TAB 2 UI ELEMENTS (BẮT ĐẦU TẠO NÚT TẠI TAB 2)
-- -----------------------------------------------------------------

-- A. Nút CreateButton("Press target")
Tab2:CreateButton("Press target", function()
    createTargetButton()
end)

-- B. Nút CreateButton("Delete target")
Tab2:CreateButton("Delete target", function()
    deleteHighestTarget()
end)

-- C. Toggle CreateToggle("Start target")
Tab2:CreateToggle("Start target", function(state)
    isTargetRunning = state

    if isTargetRunning then
        task.spawn(function()
            while isTargetRunning do
                if targetCount == 0 then
                    task.wait(0.5)
                else
                    for i = 1, targetCount do
                        if not isTargetRunning then break end

                        local target = targets[i]
                        if target and target.Button and target.Button.Parent then
                            -- Tính toán vị trí TÂM chính xác của nút nổi trên màn hình
                            local btn = target.Button
                            local absolutePos = btn.AbsolutePosition
                            local absoluteSize = btn.AbsoluteSize
                            local centerX = absolutePos.X + (absoluteSize.X / 2)
                            local centerY = absolutePos.Y + (absoluteSize.Y / 2) + 36 -- +36px bù đắp cho TopBar của Roblox

                            -- Giả lập thao tác Click tại tâm Target
                            VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, true, game, 1)
                            task.wait(0.05)
                            VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, false, game, 1)

                            -- Chờ theo cấu hình "Wait repeat (sec)" của Target đó
                            local waitTime = target.Delay or 2
                            task.wait(waitTime)
                        end
                    end
                end
                task.wait(0.1)
            end
        end)
    end
end)

-- =================================================================
-- TAB 3: CAMERA SYSTEM & CINEMATIC FREECAM (ĐÃ FIX LỖI FOLLOW)
-- =================================================================

local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Camera = workspace.CurrentCamera

local freePart = nil
local isFollowing = false
local followConnection = nil
local freecamSpeed = 50
local pcKeyMode = "J / L"

local isCameraRecording = false
local recordedCameraFrames = {}
local cameraStartTime = 0
local isCameraReviewing = false

-- Giao diện nút nổi điều hướng độ cao (UP / DWN) cho Mobile / Touch
local cameraGui = Instance.new("ScreenGui")
cameraGui.Name = "NEMoz_CameraGui"
cameraGui.ResetOnSpawn = false
pcall(function()
    cameraGui.Parent = CoreGui
end)
if not cameraGui.Parent then
    cameraGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local heightControlFrame = Instance.new("Frame")
heightControlFrame.Size = UDim2.new(0, 120, 0, 60)
heightControlFrame.Position = UDim2.new(1, -140, 0.5, -30)
heightControlFrame.BackgroundTransparency = 1
heightControlFrame.Visible = false
heightControlFrame.Parent = cameraGui

-- Nút UP (RGB: 80, 150, 255)
local upBtn = Instance.new("TextButton")
upBtn.Size = UDim2.new(0, 50, 0, 50)
upBtn.Position = UDim2.new(0, 0, 0, 5)
upBtn.BackgroundColor3 = Color3.fromRGB(18, 19, 23 )
upBtn.Text = "UP"
upBtn.TextColor3 = Color3.fromRGB(80, 150, 255)
upBtn.TextSize = 16
upBtn.Font = Enum.Font.SourceSansBold
upBtn.Parent = heightControlFrame
addCorner(upBtn, 12)
addAura(upBtn, Color3.fromRGB(80, 150, 255), 2)

-- Nút DWN (RGB: 80, 150, 255)
local dwnBtn = Instance.new("TextButton")
dwnBtn.Size = UDim2.new(0, 50, 0, 50)
dwnBtn.Position = UDim2.new(0, 60, 0, 5)
dwnBtn.BackgroundColor3 = Color3.fromRGB(18, 19, 23 )
dwnBtn.Text = "DWN"
dwnBtn.TextColor3 = Color3.fromRGB(80, 150, 255)
dwnBtn.TextSize = 14
dwnBtn.Font = Enum.Font.SourceSansBold
dwnBtn.Parent = heightControlFrame
addCorner(dwnBtn, 12)
addAura(dwnBtn, Color3.fromRGB(80, 150, 255 ), 2)

local isMovingUp = false
local isMovingDwn = false

upBtn.MouseButton1Down:Connect(function() isMovingUp = true end)
upBtn.MouseButton1Up:Connect(function() isMovingUp = false end)
upBtn.MouseLeave:Connect(function() isMovingUp = false end)

dwnBtn.MouseButton1Down:Connect(function() isMovingDwn = true end)
dwnBtn.MouseButton1Up:Connect(function() isMovingDwn = false end)
dwnBtn.MouseLeave:Connect(function() isMovingDwn = false end)

-- -----------------------------------------------------------------
-- CÁC THÀNH PHẦN GIAO DIỆN TRONG TAB 3 (CAMERA)
-- -----------------------------------------------------------------

-- 1. Toggle "Follow" (Cơ chế Freecam Hybrid chuẩn hub1 + Hỗ trợ phím độ cao tùy chỉnh)
Tab3:CreateToggle("Follow", function(state)
    isFollowing = state
    heightControlFrame.Visible = state
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    
    if isFollowing then
        if hrp then hrp.Anchored = true end
        if hum then hum.PlatformStand = true end
        
        -- Khởi tạo khối ảo độc lập (freePart) tại tọa độ hiện tại của camera
        if not freePart then
            freePart = Instance.new("Part", workspace)
            freePart.Name = "NEMoz_FreeCamPart"
            freePart.Size = Vector3.new(1, 1, 1)
            freePart.Transparency = 1
            freePart.Anchored = true
            freePart.CanCollide = false
            freePart.CFrame = Camera.CFrame
        else
            freePart.CFrame = Camera.CFrame
        end
        
        -- Gán mục tiêu camera vào freePart để xoay 360 độ cực mượt
        Camera.CameraSubject = freePart
        
        -- Vòng lặp xử lý di chuyển chuẩn kết hợp Joystick, WASD, E/Q và nút nổi UP/DWN
        followConnection = RunService.RenderStepped:Connect(function(dt)
            if freePart and Camera then
                local currentHum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                local camSpeed = 0.8 * (freecamSpeed / 30) -- Đồng bộ tốc độ mượt mà
                
                -- Hỗ trợ Joystick trên Mobile
                if currentHum and currentHum.MoveDirection.Magnitude > 0 then
                    freePart.CFrame = freePart.CFrame + (currentHum.MoveDirection * camSpeed)
                end
                
                -- Hỗ trợ bàn phím trên PC (W, A, S, D, E, Q và các phím cấu hình riêng)
                local cframe = Camera.CFrame
                local moveVec = Vector3.new(0, 0, 0)
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveVec = moveVec + cframe.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVec = moveVec - cframe.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveVec = moveVec - cframe.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVec = moveVec + cframe.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.E) then moveVec = moveVec + Vector3.new(0, 1, 0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.Q) then moveVec = moveVec - Vector3.new(0, 1, 0) end
                
                -- Phím cấu hình từ Dropdown PC (J/L hoặc ,/.)
                if pcKeyMode == "J / L" then
                    if UserInputService:IsKeyDown(Enum.KeyCode.J) then moveVec = moveVec + Vector3.new(0, 1, 0) end
                    if UserInputService:IsKeyDown(Enum.KeyCode.L) then moveVec = moveVec - Vector3.new(0, 1, 0) end
                elseif pcKeyMode == ", / ." then
                    if UserInputService:IsKeyDown(Enum.KeyCode.Comma) then moveVec = moveVec + Vector3.new(0, 1, 0) end
                    if UserInputService:IsKeyDown(Enum.KeyCode.Period) then moveVec = moveVec - Vector3.new(0, 1, 0) end
                end
                
                -- Nút nổi UP / DWN trên màn hình cảm ứng
                if isMovingUp then moveVec = moveVec + Vector3.new(0, 1, 0) end
                if isMovingDwn then moveVec = moveVec - Vector3.new(0, 1, 0) end
                
                if moveVec.Magnitude > 0 then
                    freePart.CFrame = freePart.CFrame + (moveVec.Unit * camSpeed)
                end
            end
        end)
    else
        if followConnection then
            followConnection:Disconnect()
            followConnection = nil
        end
        
        if freePart then
            freePart:Destroy()
            freePart = nil
        end
        
        if hrp then hrp.Anchored = false end
        if hum then 
            hum.PlatformStand = false
            Camera.CameraSubject = hum
        else
            local currentHum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if currentHum then Camera.CameraSubject = currentHum end
        end
        
        Camera.CameraType = Enum.CameraType.Custom
    end
end)

-- 2. Dropdown "PC" (Cấu hình phím tắt linh hoạt)
Tab3:CreateDropdown("PC", {"J / L", ", / ."}, function(selected)
    pcKeyMode = selected
end)

-- 3. Button "Start camera" (Bắt đầu ghi hình quỹ đạo)
Tab3:CreateButton("Start camera", function()
    recordedCameraFrames = {} -- Làm sạch bộ nhớ đệm cũ
    isCameraRecording = true
    cameraStartTime = tick()
    
    task.spawn(function()
        while isCameraRecording do
            local timestamp = tick() - cameraStartTime
            table.insert(recordedCameraFrames, {
                CFrame = Camera.CFrame,
                FieldOfView = Camera.FieldOfView,
                Time = timestamp
            })
            task.wait(0.03) -- Tần suất ghi hình cao (0.03s/khung hình)
        end
    end)
end)

-- Button "End Camera" (Dừng ghi hình quỹ đạo)
Tab3:CreateButton("End Camera", function()
    isCameraRecording = false
end)

-- 4. Toggle "Review" (Phát lại Cinematic mượt mà tuyệt đối bằng nội suy Lerp)
Tab3:CreateToggle("Review", function(state)
    isCameraReviewing = state
    if isCameraReviewing and #recordedCameraFrames > 0 then
        task.spawn(function()
            Camera.CameraType = Enum.CameraType.Scriptable
            local startTime = tick()
            local totalFrames = #recordedCameraFrames
            local totalDuration = recordedCameraFrames[totalFrames].Time

            while isCameraReviewing do
                local elapsed = tick() - startTime
                if elapsed >= totalDuration then
                    break
                end

                -- Tìm mốc khung hình phù hợp để nội suy thời gian thực
                local currentFrameData = recordedCameraFrames[1]
                local nextFrameData = recordedCameraFrames[#recordedCameraFrames]

                for i = 1, totalFrames - 1 do
                    if recordedCameraFrames[i].Time <= elapsed and recordedCameraFrames[i+1].Time >= elapsed then
                        currentFrameData = recordedCameraFrames[i]
                        nextFrameData = recordedCameraFrames[i+1]
                        break
                    end
                end

                local timeDiff = nextFrameData.Time - currentFrameData.Time
                local alpha = 0
                if timeDiff > 0 then
                    alpha = (elapsed - currentFrameData.Time) / timeDiff
                end

                -- Áp dụng thuật toán nội suy Lerp mượt mà tuyệt đối
                Camera.CFrame = currentFrameData.CFrame:Lerp(nextFrameData.CFrame, math.clamp(alpha, 0, 1))
                Camera.FieldOfView = currentFrameData.FieldOfView + (nextFrameData.FieldOfView - currentFrameData.FieldOfView) * math.clamp(alpha, 0, 1)

                RunService.RenderStepped:Wait()
            end

            -- Tự động hoàn tất và trả lại quyền điều khiển tiêu chuẩn
            Camera.CameraType = Enum.CameraType.Custom
            isCameraReviewing = false
        end)
    else
        Camera.CameraType = Enum.CameraType.Custom
    end
end)

-- =================================================================
-- TAB 4: TROLL SYSTEM (TÍCH HỢP FLING, INFINITE JUMP, BANG & ORBIT)
-- =================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- Biến logic chung cho hệ thống Troll
local selectedTrollTarget = nil
local typedTargetName = ""

-- Trạng thái các tính năng
local isBangLooping = false
local isOrbitLooping = false
local isInfiniteJumpEnabled = false

-- Animation Bang
local bangAnimation = Instance.new("Animation")
bangAnimation.AnimationId = "rbxassetid://223623937"
local animator = nil
local bangTrack = nil

-- Hàm tìm kiếm người chơi theo ký tự đầu tiên (Ví dụ: gõ "abc" tìm "abcdef")
local function findPlayerByName(searchStr)
    if not searchStr or searchStr == "" then return nil end
    searchStr = searchStr:gsub("@", ""):lower()
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local username = player.Name:lower()
            local displayName = player.DisplayName:lower()
            
            if username:sub(1, #searchStr) == searchStr or displayName:sub(1, #searchStr) == searchStr then
                return player
            end
        end
    end
    return nil
end

-- Hàm lấy mục tiêu hoặc chọn ngẫu nhiên nếu để trống TextBox
local function getTargetOrRandom()
    if typedTargetName ~= "" then
        selectedTrollTarget = findPlayerByName(typedTargetName)
    end

    if not selectedTrollTarget or not selectedTrollTarget.Parent then
        local validTargets = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                table.insert(validTargets, p)
            end
        end
        if #validTargets > 0 then
            selectedTrollTarget = validTargets[math.random(1, #validTargets)]
        end
    end
    return selectedTrollTarget
end

-- =================================================================
-- 1. TÍNH NĂNG KILASIK'S FLING (HÀM GỐC TỪ ZQYDSUWX)
-- =================================================================
local function SkidFling(TargetPlayer)
    local Character = LocalPlayer.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    local RootPart = Humanoid and Humanoid.RootPart
    local TCharacter = TargetPlayer.Character
    if not TCharacter then return end
    
    local THumanoid = TCharacter:FindFirstChildOfClass("Humanoid")
    local TRootPart = THumanoid and THumanoid.RootPart
    local THead = TCharacter:FindFirstChild("Head")
    local Accessory = TCharacter:FindFirstChildOfClass("Accessory")
    local Handle = Accessory and Accessory:FindFirstChild("Handle")
    
    if Character and Humanoid and RootPart then
        if RootPart.Velocity.Magnitude < 50 then
            getgenv().OldPos = RootPart.CFrame
        end
        
        if THumanoid and THumanoid.Sit then return end
        
        if not TCharacter:FindFirstChildWhichIsA("BasePart") then return end
        
        local FPos = function(BasePart, Pos, Ang)
            RootPart.CFrame = CFrame.new(BasePart.Position) * Pos * Ang
            Character:SetPrimaryPartCFrame(CFrame.new(BasePart.Position) * Pos * Ang)
            RootPart.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
            RootPart.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
        end
        
        local SFBasePart = function(BasePart)
            local TimeToWait = 1.5
            local Time = tick()
            local Angle = 0
            repeat
                if RootPart and THumanoid then
                    Angle = Angle + 100
                    FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle),0 ,0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                    task.wait()
                end
            until Time + TimeToWait < tick()
        end
        
        local originalFPDH = workspace.FallenPartsDestroyHeight
        workspace.FallenPartsDestroyHeight = 0/0
        
        local BV = Instance.new("BodyVelocity")
        BV.Parent = RootPart
        BV.Velocity = Vector3.new(0, 0, 0)
        BV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
        
        if TRootPart then
            SFBasePart(TRootPart)
        elseif THead then
            SFBasePart(THead)
        elseif Handle then
            SFBasePart(Handle)
        end
        
        BV:Destroy()
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
        
        if getgenv().OldPos then
            repeat
                RootPart.CFrame = getgenv().OldPos * CFrame.new(0, .5, 0)
                Character:SetPrimaryPartCFrame(getgenv().OldPos * CFrame.new(0, .5, 0))
                Humanoid:ChangeState("GettingUp")
                task.wait()
            until (RootPart.Position - getgenv().OldPos.p).Magnitude < 25
            workspace.FallenPartsDestroyHeight = originalFPDH
        end
    end
end

-- =================================================================
-- 2. TÍCH HỢP GIAO DIỆN TRONG TAB 4
-- =================================================================

-- TextBox nhập tên mục tiêu (Hỗ trợ tìm kiếm thông minh)
Tab4:CreateTextBox("Target Name", "Name Matching", function(text, enterPressed)
    typedTargetName = text
    selectedTrollTarget = findPlayerByName(text)
end)

-- CreateButton "fling" kết nối trực tiếp với TextBox
Tab4:CreateButton("Fling Target", function()
    local target = getTargetOrRandom()
    if target then
        task.spawn(function()
            SkidFling(target)
        end)
    end
end)

-- CreateToggle "bang"
Tab4:CreateToggle("bang", function(state)
    isBangLooping = state

    if isBangLooping then
        local target = getTargetOrRandom()
        if target then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("Humanoid") then
                local humanoid = char.Humanoid
                animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
                bangTrack = animator:LoadAnimation(bangAnimation)
                bangTrack.Priority = Enum.AnimationPriority.Action
                bangTrack.Looped = true
                bangTrack:Play()
            end

            task.spawn(function()
                local currentTime = 0
                while isBangLooping and target and target.Character and LocalPlayer.Character do
                    local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
                    local myHRP = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if targetHRP and myHRP then
                        local baseOffset = CFrame.new(0, 0, 0.8)
                        local amplitude = 1.8
                        local frequency = 7
                        local offsetZ = amplitude * math.sin(currentTime * frequency)
                        local extraOffset = CFrame.new(0, 0, offsetZ)

                        myHRP.CFrame = targetHRP.CFrame * baseOffset * extraOffset
                    end
                    currentTime += RunService.Heartbeat:Wait()
                end
                if bangTrack and bangTrack.IsPlaying then 
                    bangTrack:Stop() 
                end
            end)
        else
            isBangLooping = false
        end
    else
        if bangTrack and bangTrack.IsPlaying then
            bangTrack:Stop()
        end
    end
end)

-- CreateToggle "Orbit" (Bay vòng tròn & hướng mặt nhìn vào player)
Tab4:CreateToggle("Orbit", function(state)
    isOrbitLooping = state

    if isOrbitLooping then
        local target = getTargetOrRandom()
        if target then
            task.spawn(function()
                local angle = 0
                local radius = 6
                local speed = 3

                while isOrbitLooping and target and target.Character and LocalPlayer.Character do
                    local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
                    local myHRP = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

                    if targetHRP and myHRP then
                        angle = angle + (RunService.Heartbeat:Wait() * speed)
                        local offsetX = math.cos(angle) * radius
                        local offsetZ = math.sin(angle) * radius
                        local targetPos = targetHRP.Position
                        local newPosition = targetPos + Vector3.new(offsetX, 2, offsetZ)
                        
                        myHRP.CFrame = CFrame.lookAt(newPosition, targetPos)
                    else
                        RunService.Heartbeat:Wait()
                    end
                end
            end)
        else
            isOrbitLooping = false
        end
    end
end)

-- CreateToggle "Infinite jump"
Tab4:CreateToggle("Infinite jump", function(state)
    isInfiniteJumpEnabled = state
end)

-- Lắng nghe sự kiện nhảy vô hạn khi bật Toggle Infinite Jump
UserInputService.JumpRequest:Connect(function()
    if isInfiniteJumpEnabled then
        local char = LocalPlayer.Character
        if char and char:FindFirstChildOfClass("Humanoid") then
            char:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- =================================================================
-- TAB 5: INFORMATION (THÔNG TIN & LIÊN KẾT)
-- =================================================================

-- 1. Nút CreateButton "Scriptblox"
Tab5:CreateButton("Scriptblox", function()
    setclipboard("https://scriptblox.com/script/Universal-Script-NEMo-Free-UI-Library-239347")
    pcall(function()
        print("The Scriptblox link has been copied to the clipboard!")
    end)
end)

-- 2. Nút CreateButton "YouTube"
Tab5:CreateButton("YouTube", function()
    setclipboard("https://www.youtube.com/@NEMo-r7b")
    pcall(function()
        print("The YouTube link has been copied to the clipboard!")
    end)
end)

-- 3. Nút CreateButton "script NEMo Hub"
Tab5:CreateButton("script NEMo Hub", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Tranhoanam/NEMo-Hub-AntiBan-script-hub-/refs/heads/main/NEMoHubAntiBan.lua.txt"))()
end)

-- 4. Nhãn CreateLabel thông báo
Tab5:CreateLabel("Why is this related and repeated?")

Tab5:CreateLabel("Because i want you know to my script")
