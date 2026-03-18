local player = game.Players.LocalPlayer
local guiParent = player:WaitForChild("PlayerGui")

if guiParent:FindFirstChild("TeleportCarScanner") then
    guiParent.TeleportCarScanner:Destroy()
end

--------------------------------------------------
-- 1. تصميم واجهة الناقل الذكي
--------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TeleportCarScanner"
screenGui.Parent = guiParent

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 320, 0, 220)
mainFrame.Position = UDim2.new(0.5, -160, 0.5, -110)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 25, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 10)
uiCorner.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundTransparency = 1
title.Text = "🚀 الناقل الذكي للسيارات"
title.TextColor3 = Color3.fromRGB(0, 255, 150)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.Parent = mainFrame

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 60)
statusLabel.Position = UDim2.new(0, 10, 0, 45)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "يتم قراءة القوائم ومطابقتها مع الخريطة...\n(السعر المطلوب: +50,000 ريال)"
statusLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 14
statusLabel.TextWrapped = true
statusLabel.Parent = mainFrame

local teleportBtn = Instance.new("TextButton")
teleportBtn.Size = UDim2.new(0, 220, 0, 45)
teleportBtn.Position = UDim2.new(0.5, -110, 0, 115)
teleportBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 255)
teleportBtn.Text = "ابحث وانقلني لأغلى سيارة ⚡"
teleportBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
teleportBtn.Font = Enum.Font.GothamBold
teleportBtn.TextSize = 16
teleportBtn.Parent = mainFrame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 8)
btnCorner.Parent = teleportBtn

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 100, 0, 30)
closeBtn.Position = UDim2.new(0.5, -50, 1, -40)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.Text = "إغلاق"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.Parent = mainFrame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeBtn

closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

--------------------------------------------------
-- 2. دالة تحويل الأرقام العربية (مهمة جداً)
--------------------------------------------------
local function convertArabicNumbers(str)
    local map = {
        ["٠"]="0", ["١"]="1", ["٢"]="2", ["٣"]="3", ["٤"]="4",
        ["٥"]="5", ["٦"]="6", ["٧"]="7", ["٨"]="8", ["٩"]="9",
        [","]="", ["،"]="", [" "]="", ["\n"]=""
    }
    local res = str
    for ar, en in pairs(map) do
        res = string.gsub(res, ar, en)
    end
    return res
end

--------------------------------------------------
-- 3. منطق البحث المزدوج والنقل
--------------------------------------------------
teleportBtn.MouseButton1Click:Connect(function()
    statusLabel.Text = "جاري مسح القوائم ومطابقتها بالخريطة..."
    teleportBtn.Text = "لحظة..."
    task.wait(0.1)
    
    local potentialCars = {}
    local targetPaths = {"CarSellConfirmation", "SaleUI", "SaleUI2", "Desktop", "HarajPage"}
    
    -- الخطوة الأولى: جلب الأسعار والأسماء من القوائم
    for _, pathName in ipairs(targetPaths) do
        local uiElement = guiParent:FindFirstChild(pathName)
        if uiElement then
            for _, obj in pairs(uiElement:GetDescendants()) do
                if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
                    pcall(function()
                        local text = obj.Text
                        if text and (string.find(text, "ريال") or string.find(text, "سعر")) then
                            local cleanText = convertArabicNumbers(text)
                            -- استخراج الأرقام الكبيرة فقط لتجنب التقاط الموديلات
                            local maxNum = 0
                            for numStr in string.gmatch(cleanText, "%d+") do
                                local n = tonumber(numStr)
                                if n and n > maxNum then maxNum = n end
                            end
                            
                            -- إذا كان السعر أكبر من 50 ألف
                            if maxNum >= 50000 then
                                -- محاولة العثور على اسم السيارة في نفس القائمة
                                local parentUI = obj.Parent
                                local levels = 0
                                local carName = nil
                                
                                while parentUI and parentUI.Name ~= "CarInfo" and parentUI.Name ~= "CarSelected" and levels < 5 do
                                    parentUI = parentUI.Parent
                                    levels = levels + 1
                                end
                                
                                if parentUI then
                                    for _, child in pairs(parentUI:GetDescendants()) do
                                        if child:IsA("TextLabel") and child.Text ~= "" and child ~= obj then
                                            local cText = child.Text
                                            if not string.find(cText, "ريال") and not string.match(cText, "^%d+$") then
                                                if string.len(cText) > 2 and string.len(cText) < 25 then
                                                    carName = cText
                                                    break
                                                end
                                            end
                                        end
                                    end
                                end
                                
                                -- الخطوة الثانية: التحقق من وجود المجسم فعلياً في الخريطة
                                if carName then
                                    for _, wObj in pairs(workspace:GetDescendants()) do
                                        if wObj:IsA("Model") and wObj ~= player.Character then
                                            if string.find(string.lower(wObj.Name), string.lower(carName)) then
                                                table.insert(potentialCars, {price = maxNum, name = carName, model = wObj})
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end)
                end
            end
        end
    end
    
    -- الخطوة الثالثة: اختيار الأغلى من السيارات المؤكد وجودها
    local highestPrice = 0
    local targetCar = nil
    
    for _, carData in ipairs(potentialCars) do
        if carData.price > highestPrice then
            highestPrice = carData.price
            targetCar = carData
        end
    end
    
    -- الخطوة الرابعة: النقل
    if targetCar and targetCar.model then
        local character = player.Character or player.CharacterAdded:Wait()
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        
        if rootPart then
            -- نقل اللاعب ورفعه قليلاً لتجنب التعليق داخل السيارة
            rootPart.CFrame = targetCar.model:GetPivot() * CFrame.new(0, 8, 0)
            
            statusLabel.Text = "✅ تم العثور عليها والنقل بنجاح!\nالسيارة: " .. targetCar.name .. "\nالسعر: " .. highestPrice .. " ريال"
            teleportBtn.Text = "ابحث مجدداً ⚡"
        end
    else
        statusLabel.Text = "❌ السيارات الغالية موجودة في القوائم لكن لم أتمكن من إيجاد مجسماتها في الخريطة حولك."
        teleportBtn.Text = "حاول مجدداً"
    end
end)
