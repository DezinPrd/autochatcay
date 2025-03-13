local VirtualInputManager = game:GetService("VirtualInputManager")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local root = char:WaitForChild("HumanoidRootPart")
local TreesFolder = workspace:FindFirstChild("Jobs"):FindFirstChild("Trees")

-- 🔘 Biến kiểm soát auto farm
local autoFarm = false

-- 📌 Hàm bật/tắt auto farm
local function ToggleAutoFarm()
    autoFarm = not autoFarm
    print(autoFarm and "✅ Auto Farm BẬT" or "❌ Auto Farm TẮT")
end

-- 📌 Fix lỗi kẹt trên cây
local function FixStuck()
    local humanoid = char:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.Sit = true
        task.wait(0.2)
        humanoid.Jump = true
        task.wait(0.2)
        humanoid.Sit = false
    end
    root.CFrame = root.CFrame + Vector3.new(0, 5, 0)
    task.wait(0.1)
    root.CFrame = root.CFrame - Vector3.new(0, 5, 0)
end

-- 📌 Hàm teleport nhanh
local function TeleportTo(targetPosition)
    if root then
        -- Tính toán hướng từ nhân vật đến cây
        local direction = (targetPosition - root.Position).Unit
        -- Teleport cách cây 5 stud và nâng cao 5 stud
        local safePosition = targetPosition + (direction * -5) + Vector3.new(0, 5, 0)
        
        -- Đảm bảo không teleport vào vật thể
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
        raycastParams.FilterDescendantsInstances = {char}
        
        local raycastResult = workspace:Raycast(safePosition, Vector3.new(0, -10, 0), raycastParams)
        if raycastResult then
            safePosition = raycastResult.Position + Vector3.new(0, 3, 0)
        end
        
        root.CFrame = CFrame.new(safePosition)
        task.wait(0.2)
        FixStuck()
    end
end

-- 📌 Giữ nút E tự động
local function AutoHoldE(duration)
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, nil)
    task.wait(duration)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, nil)
end

-- 📌 Kiểm tra cây đã bị chặt chưa
local function IsTreeChopped(tree)
    return not tree:FindFirstChild("Trunk") -- Nếu không còn Trunk thì cây đã bị chặt
end

-- 📌 Tìm cây gần nhất chưa bị chặt
local function FindNearestTree()
    local closestTree = nil
    local minDist = math.huge

    for _, tree in pairs(TreesFolder:GetChildren()) do
        if tree:IsA("Model") and tree.Name == "Tree" and not IsTreeChopped(tree) then
            local trunk = tree:FindFirstChild("Trunk")
            if trunk then
                local dist = (trunk.Position - root.Position).Magnitude
                if dist < minDist then
                    minDist = dist
                    closestTree = tree
                end
            end
        end
    end

    return closestTree
end

-- 📌 Chặt cây
local function CutTree(tree)
    if not tree or not tree:FindFirstChild("Trunk") then return end
    
    local attempts = 0
    while attempts < 3 and autoFarm do
        print("🌲 Tele đến cây để chặt...")
        TeleportTo(tree.Trunk.Position)
        task.wait(1)
        
        print("🪓 Chặt cây...")
        AutoHoldE(5) -- Tăng thời gian chặt
        task.wait(5)
        
        if not tree:FindFirstChild("Trunk") then
            print("✔️ Đã chặt cây thành công")
            return true
        else
            warn("❌ Cây chưa chặt xong, thử lại...")
            attempts += 1
        end
    end
    return false
end

-- 📌 Kiểm tra và lấy danh sách 2 mảnh gỗ gần cây
local function GetLogsFromTree(tree)
    local logs = {}
    for _, obj in pairs(workspace:GetChildren()) do
        if obj:IsA("Model") and (obj.Name == "Log1" or obj.Name == "Log2") then
            local dist = (obj:GetPivot().Position - tree:GetPivot().Position).Magnitude
            if dist < 10 then -- Chỉ lấy gỗ trong phạm vi 10 stud xung quanh cây
                table.insert(logs, obj)
            end
        end
    end
    return logs
end

-- 📌 Nhặt tất cả các mảnh gỗ chính xác
local function CollectWood(tree)
    task.wait(2) -- Chờ 2s cho gỗ rơi xuống
    local logs = GetLogsFromTree(tree)
    
    if #logs >= 2 then
        for _, log in pairs(logs) do
            TeleportTo(log:GetPivot().Position)
            AutoHoldE(2)
            task.wait(0.5)
        end
        return true
    else
        warn("❌ Không đủ 2 mảnh gỗ")
        return false
    end
end


-- 📌 Nhặt tất cả các mảnh gỗ
local function CollectWood(tree)
    local logs = GetLogsFromTree(tree)

    if logs and #logs == 2 then
        for _, log in pairs(logs) do
            if log then
                TeleportTo(log:GetPivot().Position + Vector3.new(0, 1, 0)) -- Dịch lên 1 stud để tránh lệch
                task.wait(0.2)
                AutoHoldE(1.5)
                task.wait(0.5)
            end
        end
    else
        warn("❌ Không đủ 2 mảnh gỗ, thử lại...")
    end
end

-- 📌 Bán gỗ (tele chính xác)
local function SellWood()
    local SellPart = TreesFolder:FindFirstChild("Sell")
    if SellPart then
        print("💰 Tele đến điểm bán gỗ")
        TeleportTo(SellPart.Position + Vector3.new(0, 0, 0)) -- Tele đúng vị trí NPC bán gỗ
        task.wait(0.2)
        print("🔘 Giữ E 3 giây để bán gỗ")
        AutoHoldE(3)
        print("✔️ Đã bán xong, tiếp tục chặt cây")
        task.wait(1)
    else
        warn("❌ Không tìm thấy điểm bán gỗ")
    end
end

-- 📌 Auto farm loop
spawn(function()
    while true do
        if autoFarm then
            local tree = FindNearestTree()
            if tree then
                if CutTree(tree) then
                    if CollectWood(tree) then
                        SellWood()
                    end
                end
            else
                print("🔄 Không tìm thấy cây, quét lại sau 5s...")
                task.wait(5)
            end
        end
        task.wait(1)
    end
end)

-- 📌 Gán nút bật/tắt auto farm (Phím X)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.X then
        ToggleAutoFarm()
    end
end)

print("🚀 Script auto farm đã chạy! Nhấn X để bật/tắt.")
