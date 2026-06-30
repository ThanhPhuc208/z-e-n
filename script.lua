-- (Creator = Thanh Phuc)
-- 💟 Thanh Phuc - Chroma Boombox Cầu Vồng Đeo Chéo + Nháy Theo Nhạc (Visualizer) 💟
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local RunService = game:GetService("RunService")

-- Giữ nguyên bộ phát âm thanh chuẩn của bạn
local LocalSound = Instance.new("Sound")
LocalSound.Name = "ThanhPhucLocalSound"
LocalSound.Parent = LocalPlayer:WaitForChild("PlayerWorkspace", 5) or workspace
LocalSound.Volume = 2
LocalSound.Looped = true

-- TẠO CHROMA BOOMBOX ĐEO CHÉO ẢO + SÓNG NHẠC VISUALIZER
local FakeBoombox = nil
local VisualizerBars = {}
local loopConnection = nil -- Quản lý loop hiệu ứng tránh bị chồng luồng khi reset

local function CreateFakeBoombox()
    -- [SỬA LỖI]: Dọn dẹp cũ triệt để trước khi tạo mới để tránh xung đột khi chuyển bài
    if loopConnection then 
        loopConnection:Disconnect() 
        loopConnection = nil
    end
    if FakeBoombox then 
        FakeBoombox:Destroy() 
        FakeBoombox = nil
    end
    for _, bar in pairs(VisualizerBars) do 
        if bar.Part then bar.Part:Destroy() end 
    end
    VisualizerBars = {}
    
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    if not character or not (character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")) then return end
    local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
    
    -- Tạo khối Box chuẩn chất liệu Neon phát sáng cầu vồng
    local part = Instance.new("Part")
    part.Name = "ThanhPhucChromaBoombox"
    part.Material = Enum.Material.Neon
    part.CanCollide = false
    part.Massless = true
    part.Parent = character
    FakeBoombox = part
    
    -- Kích thước gốc chuẩn (gọn gàng như trong ảnh)
    local baseSize = Vector3.new(1.8, 1.2, 0.4)
    part.Size = baseSize
    
    -- Gắn và Xoay Xéo như đeo Balo Quai Chéo sau lưng
    local weld = Instance.new("Weld")
    weld.Part0 = torso
    weld.Part1 = part
    weld.C0 = CFrame.new(0, -0.2, 0.65) * CFrame.Angles(0, math.rad(180), math.rad(25))
    weld.Parent = part
    
    -- TẠO CÁC THANH SÓNG NHẠC (VISUALIZER BARS) XẾP LIỀN KHÍT NHAU (FIX RĂNG THƯA)
    local barCount = 5 -- Số lượng thanh sóng nhạc trên đỉnh loa
    local barWidth = baseSize.X / barCount -- Chia đều theo chiều dài khối hộp
    
    for i = 1, barCount do
        local bar = Instance.new("Part")
        bar.Name = "VisualizerBar" .. i
        bar.Material = Enum.Material.Neon
        -- Giữ nguyên barWidth, không trừ bớt để các thanh khít sát vào nhau hoàn hảo
        local varSize = Vector3.new(barWidth, 0.1, 0.2)
        bar.Size = varSize
        bar.CanCollide = false
        bar.Massless = true
        bar.Parent = character
        
        local barWeld = Instance.new("Weld")
        barWeld.Part0 = part
        barWeld.Part1 = bar
        
        -- Căn chỉnh vị trí xuất phát từ cạnh trái sang cạnh phải của khối hộp
        local xOffset = -(baseSize.X / 2) + (i - 0.5) * barWidth
        barWeld.C0 = CFrame.new(xOffset, baseSize.Y / 2, 0) 
        barWeld.Parent = bar
        
        table.insert(VisualizerBars, {Part = bar, Weld = barWeld, Index = i})
    end
    
    -- Hiệu ứng chạy màu cầu vồng + KHỐI CẦU VỒNG ĐẬP THEO ÂM THANH
    local hue = 0
    loopConnection = RunService.RenderStepped:Connect(function()
        if not part or not part.Parent or not part:IsDescendantOf(workspace) then
            if loopConnection then loopConnection:Disconnect() end
            return
        end
        
        -- Lấy độ lớn âm thanh hiện tại
        local loudness = LocalSound.PlaybackLoudness
        local normLoudness = math.clamp(loudness / 320, 0, 1) -- Chuẩn hóa từ 0 đến 1
        
        -- Tốc độ chuyển màu Cầu vồng chạy theo nhịp Bass
        local speedMultiplier = 1 + (normLoudness * 3)
        hue = (hue + (0.6 * speedMultiplier)) % 360 
        local mainColor = Color3.fromHSV(hue / 360, 1, 1)
        
        -- Áp màu cầu vồng lên khối chính
        part.Color = mainColor
        
        -- ĐẬP THEO NHẠC: Khối cầu vồng co giãn mượt mà theo Bass
        local scaleFactor = 1 + (normLoudness * 0.22) -- Tỉ lệ đập nhẹ nhàng, tinh tế
        part.Size = Vector3.new(baseSize.X * scaleFactor, baseSize.Y * scaleFactor, baseSize.Z * scaleFactor)
        
        -- Cập nhật các thanh sóng nhạc nhấp nhô liên tục
        for _, item in pairs(VisualizerBars) do
            if item.Part and item.Part.Parent then
                local waveFactor = math.sin(tick() * 14 + item.Index) * 0.12
                local targetHeight = math.clamp((normLoudness * 0.65) + waveFactor, 0.05, 0.7)
                
                -- Cập nhật kích thước thanh (độ rộng tự động giãn đều theo scale khối chính)
                item.Part.Size = Vector3.new(barWidth * scaleFactor, targetHeight, item.Part.Size.Z)
                
                -- Định vị lại chân thanh luôn bám sát mặt trên khi khối hộp đập to nhỏ
                local currentTop = (baseSize.Y * scaleFactor) / 2
                local currentXOffset = (-(baseSize.X / 2) + (item.Index - 0.5) * barWidth) * scaleFactor
                item.Weld.C0 = CFrame.new(currentXOffset, currentTop + (targetHeight / 2), 0)
                
                -- Đổi màu dải cầu vồng lệch nhịp nối tiếp nhau cực đẹp
                local barHue = (hue + (item.Index * 15)) % 360
                item.Part.Color = Color3.fromHSV(barHue / 360, 1, 1)
            end
        end
    end)
end

-- TỰ ĐỘNG ĐEO LẠI KHI DIE (HỒI SINH KHÔNG MẤT LOA)
LocalPlayer.CharacterAdded:Connect(function(char)
    char:WaitForChild("Humanoid")
    task.wait(0.6) -- Tăng một chút thời gian chờ để nhân vật load hẳn các khớp xương (Torso)
    if LocalSound.IsPlaying or LocalSound.TimePosition > 0 then
        CreateFakeBoombox()
    end
end)

-- GIAO DIỆN GUI (Giữ nguyên toàn bộ cấu trúc cũ)
local ScreenGui = Instance.new("ScreenGui", PlayerGui)
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 250, 0, 220)
MainFrame.Position = UDim2.new(0.5, -125, 0.4, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.Draggable = true
MainFrame.Active = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

-- Nút ẨN MENU
local HideBtn = Instance.new("TextButton", MainFrame)
HideBtn.Size = UDim2.new(0, 30, 0, 30)
HideBtn.Position = UDim2.new(0.85, 0, 0.05, 0)
HideBtn.Text = "-"
HideBtn.TextColor3 = Color3.new(1, 1, 1)
HideBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
Instance.new("UICorner", HideBtn)
HideBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false 
end)

-- Nút MỞ MENU
local OpenBtn = Instance.new("TextButton", ScreenGui)
OpenBtn.Size = UDim2.new(0, 50, 0, 50)
OpenBtn.Position = UDim2.new(0, 10, 0.5, 0)
OpenBtn.Text = "TP 🎵"
OpenBtn.TextColor3 = Color3.new(1, 1, 1)
OpenBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
OpenBtn.Draggable = true
OpenBtn.Active = true
Instance.new("UICorner", OpenBtn)
OpenBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = true 
end)

-- Tiêu đề Menu
local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(0.8, 0, 0, 30)
Title.Position = UDim2.new(0.05, 0, 0.05, 0)
Title.Text = "🎵 THANH PHÚC MUSIC"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.BackgroundTransparency = 1
Title.TextXAlignment = Enum.TextXAlignment.Left

-- Ô nhập ID Nhạc
local InputBox = Instance.new("TextBox", MainFrame)
InputBox.Size = UDim2.new(0.9, 0, 0, 40)
InputBox.Position = UDim2.new(0.05, 0, 0.25, 0)
InputBox.PlaceholderText = "Nhập ID nhạc..."
InputBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
InputBox.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", InputBox)

-- Nút PHÁT NHẠC
local PlayBtn = Instance.new("TextButton", MainFrame)
PlayBtn.Size = UDim2.new(0.9, 0, 0, 40)
PlayBtn.Position = UDim2.new(0.05, 0, 0.55, 0)
PlayBtn.Text = "PHÁT NHẠC"
PlayBtn.TextColor3 = Color3.new(1, 1, 1)
PlayBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
Instance.new("UICorner", PlayBtn)

-- Kích hoạt phát nhạc và gọi Loa Đeo Chéo xuất hiện
PlayBtn.MouseButton1Click:Connect(function()
    local cleanID = InputBox.Text:match("%d+")
    if cleanID then
        LocalSound.SoundId = "rbxassetid://" .. cleanID
        LocalSound:Play()
        
        -- Thực hiện tạo mới / cập nhật lại loa ngay lập tức
        CreateFakeBoombox()
        print("Thanh Phuc đã cập nhật bài hát mới thành công, Boombox vẫn giữ nguyên vị trí!")
    else
        InputBox.Text = ""
        InputBox.PlaceholderText = "ID không hợp lệ!"
    end
end)
