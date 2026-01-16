--[[
    SKY_OMEGA_V62_UNBREAKABLE
    Status: CRITICAL FIX APPLIED
    Fixes: 
    1. "Exceeded limit 200 local registers" (Removed Upvalue Cache Bloat)
    2. "Attempt to call nil value" (Restored Standard Library Calls)
    3. Admin System Fully Integrated via Morse Code
]]

-- // [1] SISTEMA DE SEGURANÇA ADMIN (RODA ANTES DE TUDO) // --
local ADMIN_HWID = "8144C117-7B30-488D-BAF0-46C9DDC217FD"
local BAN_LIST_URL = "https://gist.githubusercontent.com/Murilo847/8c700abc8505df923984b9779b63b31d/raw/ListaBanidos.json"
local ADMIN_PASS = "sky2506"

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RbxAnalyticsService = game:GetService("RbxAnalyticsService")
local LocalPlayer = Players.LocalPlayer

local function GetHWID()
    local success, id = pcall(function() return RbxAnalyticsService:GetClientId() end)
    return success and id or "Unknown"
end

local MyHWID = GetHWID()
local IsAdmin = (MyHWID == ADMIN_HWID)

task.spawn(function()
    if IsAdmin then return end
    local success, result = pcall(function() return HttpService:GetAsync(BAN_LIST_URL) end)
    if success and result and result:find(MyHWID) then
        LocalPlayer:Kick("\n⛔ HWID BANIDO GLOBALMENTE ⛔")
        task.wait(9e9)
    end
end)

-- // [2] SCRIPT ORIGINAL (CORRIGIDO PARA NÃO DAR ERRO DE REGISTRO) // --

local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Stats = game:GetService("Stats")
local Camera = workspace.CurrentCamera

-- Compatibilidade
local writefile = writefile or function(...) end
local readfile = readfile or function(...) end
local isfile = isfile or function(...) return false end
local delfile = delfile or function(...) end
local setclipboard = setclipboard or toclipboard or function(...) end

-- Strings Cacheadas
local STR_HRP = "HumanoidRootPart"
local STR_HUM = "Humanoid"
local STR_HEAD = "Head"

-- Telemetria
local Debug_Metrics = { CoreLoopTime = 0, HeroHunterTime = 0, TotalConnections = 0 }

-- Limpeza
local GuiName = "SkyL_Omega_V62_Final"
if CoreGui:FindFirstChild(GuiName) then CoreGui[GuiName]:Destroy() end
if _G.SkyL_Connections then for _, c in pairs(_G.SkyL_Connections) do if c then c:Disconnect() end end end
_G.SkyL_Connections = {}
if _G.HeroHunter_Connections then for _, c in pairs(_G.HeroHunter_Connections) do if c then c:Disconnect() end end end
_G.HeroHunter_Connections = {}
if CoreGui:FindFirstChild("NexusTacticalV9") then CoreGui.NexusTacticalV9:Destroy() end

for _, v in pairs(Lighting:GetChildren()) do if v.Name == "SkyL_Blur" then v:Destroy() end end

-- Variáveis de Estado
local HitboxMode = false; local HitboxStrategy = "Aim"
local LockMode = false; local EspMode = false; local PlayerEspMode = false
local TeleportMode = false
local HeroHunterMode = false
local IsMenuOpen = false; local isAntiGripActive = false
local HasUsedAntiVoid = false

local TP_Mobile_Mode = false
local TP_PC_Mode = false
local TP_Aim_Mode = false
local TP_Target_Selected = nil
local TP_Click_Radius = 300
local TP_Aim_Radius = 150

local FlyMode = false; local NoclipMode = false
local CustomSpeed = 0; local CustomJump = 0
local FlyKey = nil; local NoclipKey = nil

local LastInteraction = tick(); local IdleThreshold = 10; local IsIdle = false
local SavedTarget = nil; local FOV_Radius = 300
local CoreLoopConnection = nil; local LogicLoopConnection = nil
local LastTPClick = 0; local TP_DoubleTapSpeed = 0.3
local LastTPPos = Vector2.new(0, 0); local TP_Tap_Threshold = 100 

local MaxRenderDistance = 2500
local Whitelist = {}; local TargetCache = nil; local Blacklist = {}

-- Cache Visual (Substituído V3_new por V3.new para evitar erro 200)
local CachedSize = Vector3.new(10, 10, 10)
local CachedColor = Color3.new(0.5, 0.5, 0.5)
local CachedTransparency = 0.8
local DefaultSize = Vector3.new(2, 2, 1)

-- Cores
local ColorGlassDark = Color3.fromRGB(10, 10, 15)
local ColorGlassLight = Color3.fromRGB(30, 30, 40)
local ColorStroke = Color3.fromRGB(60, 60, 80)
local ColorGreen = Color3.fromRGB(100, 255, 120)
local ColorRed = Color3.fromRGB(255, 80, 80)
local ColorBlue = Color3.fromRGB(80, 180, 255)
local ColorPurple = Color3.fromRGB(180, 100, 255)
local ColorWhite = Color3.new(1, 1, 1)
local ColorTextDim = Color3.fromRGB(160, 160, 180)
local ColorYellow = Color3.fromRGB(255, 220, 50)
local ColorBlack = Color3.new(0,0,0)
local ColorAdmin = Color3.fromRGB(255, 50, 50)

local Locations = {
    Sanctum = CFrame.new(2379.8015, 686.3657, 659.2962),
    Caverna = CFrame.new(-351.8613, 697.4421, 1903.7971),
    Wundagore = CFrame.new(-2818.6208, 1050.8438, 649.0917),
    Hospital = CFrame.new(376.6887, 649.5777, 1422.3016),
    Bruxas = CFrame.new(-946.3616, 813.6406, -1337.4160),
    Campo = CFrame.new(1408.5571, 650.3133, 544.6354),
    Arena = CFrame.new(-184.3240, 924.8199, 1723.2778)
}

local UserSavedPosition = UDim2.new(0.5, -95, 0.5, -22)
Settings = {}
local ConfigFileName = "MeuScript_Config.json"

-- // UTILS // --
local function SetProp(instance, prop, value)
    if instance[prop] ~= value then
        instance[prop] = value
    end
end

local function UpdateConnectionCount() Debug_Metrics.TotalConnections = #_G.SkyL_Connections + #_G.HeroHunter_Connections end

table.insert(_G.SkyL_Connections, LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new())
end))

local function ActivatePotatoMode()
    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 9e9
    Lighting.Brightness = 2
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("BasePart") then
            SetProp(v, "Material", Enum.Material.Plastic)
            SetProp(v, "Reflectance", 0)
            SetProp(v, "CastShadow", false)
        elseif v:IsA("Decal") or v:IsA("Texture") then
            SetProp(v, "Transparency", 1)
        elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
            v.Lifetime = NumberRange.new(0)
        end
    end
    for _, v in ipairs(Lighting:GetChildren()) do
        if v:IsA("PostEffect") then SetProp(v, "Enabled", false) end
    end
end

local function GetSmartPosition(currentPos, width, height)
    local vp = Camera.ViewportSize
    local padding = 5 
    local absCenterX = (currentPos.X.Scale * vp.X) + currentPos.X.Offset
    local absCenterY = (currentPos.Y.Scale * vp.Y) + currentPos.Y.Offset
    local safeCenterX = math.clamp(absCenterX, width/2 + padding, vp.X - width/2 - padding)
    local safeCenterY = math.clamp(absCenterY, height/2 + padding, vp.Y - height/2 - padding)
    return UDim2.new(0, safeCenterX, 0, safeCenterY)
end

local function MakeDraggable(trigger, target, isMainHub)
    local dragging, dragInput, dragStart, startPos
    table.insert(_G.SkyL_Connections, trigger.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = target.Position
            LastInteraction = tick()
            local con; con = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then 
                    dragging = false; con:Disconnect()
                    if isMainHub then
                        UserSavedPosition = target.Position
                        local finalPos = GetSmartPosition(target.Position, target.AbsoluteSize.X, target.AbsoluteSize.Y)
                        if finalPos ~= target.Position then
                            TweenService:Create(target, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = finalPos}):Play()
                            UserSavedPosition = finalPos
                        end
                    end
                end
            end)
        end
    end))
    table.insert(_G.SkyL_Connections, trigger.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end))
    table.insert(_G.SkyL_Connections, UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            LastInteraction = tick()
        end
    end))
end

local ScreenGui, LogFrame 
local function AddLog(msg, color)
    if not LogFrame then return end
    local l = Instance.new("TextLabel", LogFrame)
    l.Text = msg; l.TextColor3 = color or ColorWhite; l.Font = Enum.Font.GothamBold; l.TextSize = 14; l.Size = UDim2.new(1, 0, 0, 20); l.BackgroundTransparency = 1; l.TextTransparency = 1; l.ZIndex = 200
    TweenService:Create(l, TweenInfo.new(0.5), {TextTransparency = 0}):Play()
    task.delay(3, function() TweenService:Create(l, TweenInfo.new(1), {TextTransparency = 1}):Play(); task.wait(1); l:Destroy() end)
    for _, c in ipairs(LogFrame:GetChildren()) do if c:IsA("TextLabel") and c ~= l then TweenService:Create(c, TweenInfo.new(0.3), {Position = c.Position - UDim2.new(0, 0, 0, 20)}):Play() end end
end

local function AddCorner(parent, radius) local c = Instance.new("UICorner", parent); c.CornerRadius = UDim.new(0, radius); return c end
local function AddStroke(parent, color, thickness) local s = Instance.new("UIStroke", parent); s.Color = color or ColorStroke; s.Thickness = thickness or 1.2; s.Transparency = 0.5; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; return s end

local function ShowiOSAlert()
    if not ScreenGui then return end
    local NotifFrame = Instance.new("Frame", ScreenGui); NotifFrame.Name = "iOS_Alert"; NotifFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30); NotifFrame.BackgroundTransparency = 0.1; NotifFrame.Size = UDim2.new(0, 320, 0, 60); NotifFrame.Position = UDim2.new(0.5, -160, 0, -100); NotifFrame.ZIndex = 200
    AddCorner(NotifFrame, 14); AddStroke(NotifFrame, Color3.fromRGB(80, 80, 100), 1)
    local Msg = Instance.new("TextLabel", NotifFrame); Msg.Text = "ATIVE O ANTI-VOID AO RESETAR/MORRER!"; Msg.Font = Enum.Font.GothamBlack; Msg.TextColor3 = ColorWhite; Msg.TextSize = 12; Msg.BackgroundTransparency = 1; Msg.Size = UDim2.new(1, 0, 1, 0)
    TweenService:Create(NotifFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, -160, 0, 20)}):Play()
    task.delay(5, function() TweenService:Create(NotifFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Position = UDim2.new(0.5, -160, 0, -100)}):Play(); task.wait(0.5); NotifFrame:Destroy() end)
end

-- // HERO HUNTER (RESTAURADO) // --
local HH_HERO_DB = { ["Agatha"]=90, ["CaptainMarvel"]=100, ["DemonQueen"]=100, ["DrStrange"]=90, ["HumanTorch"]=130, ["InvisibleWoman"]=90, ["Susan"]=90, ["Ironman"]=120, ["JeanGrey"]=100, ["Phoenix"]=100, ["Monica"]=100, ["Quicksilver"]=80, ["Speed"]=80, ["Storm"]=110, ["Thor"]=130, ["Vision"]=100, ["Wanda"]=100, ["ScarletWitch"]=90, ["Wiccan"]=120 }
local HH_SETTINGS = { GlobalMax = 145, VoidSpeed = 500, UpdateRate = 0.1, AutoHideTime = 10, HoverZoneWidth = 50 }
local HH_Tracked, HH_Pinned, HH_CriticalMap = {}, {}, {}

local function StartHeroHunter()
    if CoreGui:FindFirstChild("NexusTacticalV9") then return end 
    local IsMenuVisible = true; local LastInteraction = tick()
    local HH_ScreenGui = Instance.new("ScreenGui", CoreGui); HH_ScreenGui.Name = "NexusTacticalV9"
    local MainFrame = Instance.new("Frame", HH_ScreenGui); MainFrame.Name = "Container"; MainFrame.Size = UDim2.new(0, 220, 0, 50); MainFrame.Position = UDim2.new(0.85, 0, 0.2, 0); MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10); MainFrame.BackgroundTransparency = 0.6; MainFrame.Active = true; MainFrame.Draggable = true; MainFrame.AutomaticSize = Enum.AutomaticSize.Y
    
    local UIListLayout = Instance.new("UIListLayout", MainFrame); UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder; UIListLayout.Padding = UDim.new(0, 2)
    local UIPadding = Instance.new("UIPadding", MainFrame); UIPadding.PaddingTop = UDim.new(0, 5); UIPadding.PaddingLeft = UDim.new(0, 5); UIPadding.PaddingRight = UDim.new(0, 5); UIPadding.PaddingBottom = UDim.new(0, 5)
    local Separator = Instance.new("Frame", MainFrame); Separator.Name = "Separator"; Separator.LayoutOrder = 2; Separator.Size = UDim2.new(1, -10, 0, 2); Separator.BackgroundColor3 = Color3.fromRGB(255, 105, 180); Separator.Visible = false

    MainFrame.MouseEnter:Connect(function() LastInteraction = tick() end); MainFrame.MouseMoved:Connect(function() LastInteraction = tick() end)
    local function ToggleMenu(forceState)
        local targetState = (forceState ~= nil) and forceState or not IsMenuVisible; if targetState == IsMenuVisible then return end 
        IsMenuVisible = targetState; if IsMenuVisible then LastInteraction = tick() end
        local targetPos = IsMenuVisible and UDim2.new(0.85, 0, MainFrame.Position.Y.Scale, MainFrame.Position.Y.Offset) or UDim2.new(1.1, 0, MainFrame.Position.Y.Scale, MainFrame.Position.Y.Offset)
        TweenService:Create(MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = targetPos}):Play()
    end
    
    table.insert(_G.HeroHunter_Connections, RunService.Heartbeat:Connect(function()
        local mouseLoc = UserInputService:GetMouseLocation(); local screenWidth = Camera.ViewportSize.X
        if mouseLoc.X >= (screenWidth - HH_SETTINGS.HoverZoneWidth) then if not IsMenuVisible then ToggleMenu(true) end; LastInteraction = tick() end
        if IsMenuVisible and (tick() - LastInteraction > HH_SETTINGS.AutoHideTime) then ToggleMenu(false) end
    end))
    
    local function UpdateCriticalCount() local count = 0; for _, isCrit in pairs(HH_CriticalMap) do if isCrit then count = count + 1 end end; CriticalPlayersCount = count end
    local function CheckSeparator() local hasPinned = false; for _ in pairs(HH_Pinned) do hasPinned = true; break end; Separator.Visible = hasPinned end
    
    local function CreateESP(player)
        if not player.Character then return end; local root = player.Character:FindFirstChild(STR_HRP); if not root then return end
        local bb = Instance.new("BillboardGui", root); bb.Name = "NexusESP_Text"; bb.Size = UDim2.new(0, 200, 0, 50); bb.StudsOffset = Vector3.new(0, 3, 0); bb.AlwaysOnTop = true
        local txt = Instance.new("TextLabel", bb); txt.Size = UDim2.new(1,0,1,0); txt.BackgroundTransparency = 1; txt.Text = player.DisplayName; txt.TextColor3 = Color3.fromRGB(255, 105, 180); txt.Font = Enum.Font.GothamBold; txt.TextSize = 14
        local attach0 = Instance.new("Attachment", LocalPlayer.Character:WaitForChild(STR_HRP)); attach0.Name = "NexusAtt0"; local attach1 = Instance.new("Attachment", root); attach1.Name = "NexusAtt1"
        local beam = Instance.new("Beam", root); beam.Name = "NexusESP_Line"; beam.Attachment0 = attach0; beam.Attachment1 = attach1; beam.Color = ColorSequence.new(Color3.fromRGB(255, 105, 180)); beam.FaceCamera = true; beam.Width0 = 0.1; beam.Width1 = 0.1
    end
    
    local function RemoveESP(player) if player.Character then local root = player.Character:FindFirstChild(STR_HRP); if root then if root:FindFirstChild("NexusESP_Text") then root.NexusESP_Text:Destroy() end; if root:FindFirstChild("NexusESP_Line") then root.NexusESP_Line:Destroy() end; if root:FindFirstChild("NexusAtt1") then root.NexusAtt1:Destroy() end end end end
    
    local function UpdateESP(player) 
        if not HH_Pinned[player] or not player.Character then return end; 
        local root = player.Character:FindFirstChild(STR_HRP); 
        local bb = root and root:FindFirstChild("NexusESP_Text"); 
        if bb then 
            local dist = (LocalPlayer.Character.HumanoidRootPart.Position - root.Position).Magnitude; 
            bb.TextLabel.Text = string.format("%s\n[%.0f studs]", player.DisplayName, dist) 
        else 
            CreateESP(player) 
        end 
    end
    
    local function GetLimit(char) if not char then return HH_SETTINGS.GlobalMax end; local cName = char.Name; for key, spd in pairs(HH_HERO_DB) do if cName:match(key) then return spd end end; return HH_SETTINGS.GlobalMax end
    
    local function CreateRow(player)
        local btn = Instance.new("TextButton", MainFrame); btn.Name = "99_" .. player.DisplayName; 
        btn.LayoutOrder = 3 
        btn.Size = UDim2.new(1, 0, 0, 18); btn.BackgroundTransparency = 1; btn.Font = Enum.Font.Code; btn.TextSize = 13; btn.TextXAlignment = Enum.TextXAlignment.Left; btn.AutoButtonColor = false; btn.Text = ""
        
        local lastClick = 0; 
        btn.MouseButton1Click:Connect(function() 
            LastInteraction = tick(); 
            if tick() - lastClick < 0.4 then 
                if not HH_Pinned[player] then 
                    HH_Pinned[player] = true; 
                    btn.LayoutOrder = 1 
                    CheckSeparator(); 
                    CreateESP(player) 
                end 
            end; 
            lastClick = tick() 
        end)
        
        btn.MouseButton2Click:Connect(function() 
            LastInteraction = tick(); 
            if HH_Pinned[player] then 
                HH_Pinned[player] = nil; 
                btn.LayoutOrder = 3 
                CheckSeparator(); 
                RemoveESP(player) 
            end 
        end); 
        btn.MouseEnter:Connect(function() LastInteraction = tick() end); return btn
    end
    
    local function AddToMonitor(player) if player == LocalPlayer then return end; local btn = CreateRow(player); HH_Tracked[player] = { LastPos = nil, LastTick = tick(), UI = btn }; HH_CriticalMap[player] = false end
    local function RemoveFromMonitor(player) if HH_Tracked[player] then if HH_Tracked[player].UI then HH_Tracked[player].UI:Destroy() end; HH_Tracked[player] = nil end; HH_Pinned[player] = nil; HH_CriticalMap[player] = nil; UpdateCriticalCount(); CheckSeparator() end

    local LastCheckTime = 0
    local HH_MainConnection = RunService.Heartbeat:Connect(function()
        local startTime = os.clock()
        if (tick() - LastCheckTime) < HH_SETTINGS.UpdateRate then return end
        LastCheckTime = tick()

        for player, data in pairs(HH_Tracked) do
            if not player.Parent then 
                RemoveFromMonitor(player) 
            else
                if HH_Pinned[player] then UpdateESP(player) end
                local char = player.Character; local uiBtn = data.UI
                
                if not char or not char:FindFirstChild(STR_HRP) then
                    if uiBtn then uiBtn.Text = "💤 " .. player.DisplayName .. " [MENU]"; uiBtn.TextColor3 = Color3.fromRGB(100, 150, 255) end; data.LastPos = nil
                else
                    local hrp = char.HumanoidRootPart; local now = tick(); local delta = now - data.LastTick
                    
                    if not data.LastPos then 
                        data.LastPos = hrp.Position; data.LastTick = now 
                    else
                        local distance = (hrp.Position - data.LastPos).Magnitude
                        local speed = 0
                        if delta > 0 then speed = distance / delta end

                        if distance > 1000 and delta < 1 then 
                            data.LastPos = hrp.Position; data.LastTick = now 
                        else
                            local limit = GetLimit(char) + 15; local isCurrentlyCritical = (speed > HH_SETTINGS.VoidSpeed)
                            if HH_CriticalMap[player] ~= isCurrentlyCritical then HH_CriticalMap[player] = isCurrentlyCritical; UpdateCriticalCount() end
                            local floorSpeed = math.floor(speed)
                            if uiBtn then
                                if isCurrentlyCritical then uiBtn.Text = string.format("🔴 %s [%d] 🔴", player.DisplayName, floorSpeed); uiBtn.TextColor3 = Color3.fromRGB(255, 60, 60)
                                elseif speed > limit then uiBtn.Text = string.format("⚠️ %s [%d] ⚠️", player.DisplayName, floorSpeed); uiBtn.TextColor3 = Color3.fromRGB(255, 220, 0)
                                else uiBtn.Text = string.format("%s [%d]", player.DisplayName, floorSpeed); uiBtn.TextColor3 = Color3.fromRGB(200, 200, 200) end
                            end
                            data.LastPos = hrp.Position; data.LastTick = now
                        end
                    end
                end
            end
        end
        Debug_Metrics.HeroHunterTime = (os.clock() - startTime) * 1000
    end)
    table.insert(_G.HeroHunter_Connections, HH_MainConnection)
    for _, p in ipairs(Players:GetPlayers()) do AddToMonitor(p) end; table.insert(_G.HeroHunter_Connections, Players.PlayerAdded:Connect(AddToMonitor)); table.insert(_G.HeroHunter_Connections, Players.PlayerRemoving:Connect(RemoveFromMonitor))
    UpdateConnectionCount()
end

local function StopHeroHunter()
    if _G.HeroHunter_Connections then for _, conn in pairs(_G.HeroHunter_Connections) do if conn then conn:Disconnect() end end end
    _G.HeroHunter_Connections = {}; HH_Tracked = {}; HH_Pinned = {}; HH_CriticalMap = {}
    if CoreGui:FindFirstChild("NexusTacticalV9") then CoreGui.NexusTacticalV9:Destroy() end
    UpdateConnectionCount()
end

-- // ANTI HIJACK OTIMIZADO // --
local NexusChar, NexusHRP
local function AntiHijack()
    if not NexusChar or not NexusHRP then return end
    if not isAntiGripActive then return end 
    local children = NexusHRP:GetChildren()
    for i = 1, #children do
        local child = children[i]
        if child:IsA("BodyVelocity") or child:IsA("BodyGyro") then
            -- Safe
        elseif child:IsA("BodyPosition") 
            or child:IsA("AlignPosition") 
            or child:IsA("VectorForce") 
            or child:IsA("AlignOrientation") 
            or child:IsA("Attachment") 
            or child:IsA("Constraint")
            or child:IsA("Weld") then
            child:Destroy()
        end
    end
end

-- // MOVEMENT OTIMIZADO // --
local function UpdateMovement()
    if not LocalPlayer.Character then return end
    local hum = LocalPlayer.Character:FindFirstChild(STR_HUM); local hrp = LocalPlayer.Character:FindFirstChild(STR_HRP)
    if hum and not FlyMode then if CustomSpeed > 0 then SetProp(hum, "WalkSpeed", CustomSpeed) end; if CustomJump > 0 then SetProp(hum, "JumpPower", CustomJump) end end
    if FlyMode and hrp and hum then
        SetProp(hum, "PlatformStand", true); hrp.Velocity = Vector3.zero; hrp.AssemblyLinearVelocity = Vector3.zero; hrp.AssemblyAngularVelocity = Vector3.zero
        local camCF = Camera.CFrame; local speed = (CustomSpeed > 0 and CustomSpeed) or 50; local moveStep = speed * 0.05; local moveDir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + camCF.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - camCF.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - camCF.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + camCF.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir - Vector3.new(0, 1, 0) end
        if moveDir.Magnitude > 0 then hrp.CFrame = hrp.CFrame + (moveDir * moveStep) end
        hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + camCF.LookVector)
    else if hum and not FlyMode then SetProp(hum, "PlatformStand", false) end end
    if NoclipMode and LocalPlayer.Character then for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end end end
end
table.insert(_G.SkyL_Connections, RunService.Heartbeat:Connect(UpdateMovement))

-- // CORE LOGIC OTIMIZADO // --
local function ValidateTarget(target)
    if not target or not target.Parent then return false end
    local hum = target:FindFirstChild(STR_HUM); 
    if not hum or hum.Health <= 0 then return false end
    local hrp = target:FindFirstChild(STR_HRP)
    if not hrp then return false end
    if Players:GetPlayerFromCharacter(target) then return false end
    if target.Name == "SkyL_SafeSpot" then return false end; if hrp.Anchored == true then return false end 
    return true
end

local function GetTarget()
    local closest, dist = nil, 999999; local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild(STR_HRP)
    if not myRoot then return nil end
    local children = Workspace:GetChildren() 
    local myPos = myRoot.Position
    for i = 1, #children do
        local v = children[i]
        if v:IsA("Model") and v ~= LocalPlayer.Character and not table.find(Blacklist, v) and ValidateTarget(v) then
            local hrp = v:FindFirstChild(STR_HRP); 
            if hrp then 
                local d = (hrp.Position - myPos).Magnitude; 
                if d < dist then dist = d; closest = v end 
            end
        end
    end
    return closest
end

local function ResetAllHitboxes() 
    for _, p in ipairs(Players:GetPlayers()) do 
        if p ~= LocalPlayer and p.Character then 
            local hrp = p.Character:FindFirstChild(STR_HRP); 
            if hrp then 
                SetProp(hrp, "Size", DefaultSize)
                SetProp(hrp, "Transparency", 1)
                SetProp(hrp, "Material", Enum.Material.Plastic)
                SetProp(hrp, "CanCollide", true)
            end 
        end 
    end 
end

local function ClearVisuals(p)
    if p and p.Character then
        local hrp = p.Character:FindFirstChild(STR_HRP); local head = p.Character:FindFirstChild(STR_HEAD)
        if hrp then 
            local beam = hrp:FindFirstChild("ArtifactBeam"); if beam then SetProp(beam, "Enabled", false) end
        end
        if head then 
            local tag = head:FindFirstChild("ArtifactNameTag"); if tag then SetProp(tag, "Enabled", false) end 
        end
    end
end
local function FullCleanup() for _, p in ipairs(Players:GetPlayers()) do ClearVisuals(p) end; SavedTarget = nil end

local function GetLocalAttachment() 
    if not LocalPlayer.Character then return nil; end
    local root = LocalPlayer.Character:FindFirstChild(STR_HRP); if not root then return nil end
    local att = root:FindFirstChild("MyEspAtt"); 
    if not att then 
        att = Instance.new("Attachment", root); att.Name = "MyEspAtt" 
    end
    return att 
end

-- // MANAGE ESP V2 // --
local function ManageESP(v, col, line, name)
    if not v.Character then return end
    local hrp = v.Character:FindFirstChild(STR_HRP); local head = v.Character:FindFirstChild(STR_HEAD); local hum = v.Character:FindFirstChild(STR_HUM)
    if not hrp or not head then return end
    
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild(STR_HRP) then 
        if (hrp.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude > MaxRenderDistance then 
            ClearVisuals(v); return 
        end 
    end
    
    local beam = hrp:FindFirstChild("ArtifactBeam")
    if line then
        local myAtt = GetLocalAttachment()
        if not beam then 
            local att = hrp:FindFirstChild("EspAttTarget") or Instance.new("Attachment", hrp); att.Name="EspAttTarget"
            beam = Instance.new("Beam", hrp); beam.Name="ArtifactBeam"; beam.Attachment1=att; beam.FaceCamera=true; beam.Width0=0.1; beam.Width1=0.1 
        end
        if beam and myAtt then 
            SetProp(beam, "Attachment0", myAtt)
            beam.Color = ColorSequence.new(col)
            SetProp(beam, "Enabled", true)
        end
    else 
        if beam then SetProp(beam, "Enabled", false) end 
    end
    
    local tag = head:FindFirstChild("ArtifactNameTag")
    if name then
        local l
        if not tag then 
            tag = Instance.new("BillboardGui", head); tag.Name="ArtifactNameTag"; tag.AlwaysOnTop=true; tag.Size=UDim2.new(0,200,0,50); tag.StudsOffset=Vector3.new(0,3,0)
            l = Instance.new("TextLabel", tag); l.Name="L"; l.Size=UDim2.new(1,0,1,0); l.BackgroundTransparency=1; l.Font=Enum.Font.Nunito; l.TextSize=16; l.TextStrokeTransparency=0; l.TextStrokeColor3=ColorBlack
        else
            l = tag:FindFirstChild("L")
            SetProp(tag, "Enabled", true)
        end
        
        if l then 
            local hp = hum and math.floor(hum.Health) or 0; local max = hum and math.floor(hum.MaxHealth) or 100
            local newText = v.DisplayName.." ["..hp.."/"..max.."]"
            SetProp(l, "Text", newText)
            SetProp(l, "TextColor3", col)
        end
    else 
        if tag then SetProp(tag, "Enabled", false) end 
    end
end

local function getClosestPlayerToMouse()
    local closest, shortest = nil, FOV_Radius; local mouse = UserInputService:GetMouseLocation(); local players = Players:GetPlayers()
    for i=1, #players do
        local v = players[i]
        local vName = v.Name
        if v ~= LocalPlayer and v.Character and not Whitelist[vName] then
            local hrp = v.Character:FindFirstChild(STR_HRP); local hum = v.Character:FindFirstChild(STR_HUM)
            if hrp and hum and hum.Health > 0 then 
                local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position); 
                if onScreen then 
                    local dist = (Vector2.new(pos.X, pos.Y) - mouse).Magnitude; 
                    if dist < shortest then shortest = dist; closest = v end 
                end 
            end
        end
    end
    return closest
end

local function getClosestPlayerToCenter()
    local closest, shortest = nil, TP_Aim_Radius; local center = Camera.ViewportSize / 2; local players = Players:GetPlayers()
    for i=1, #players do
        local v = players[i]
        local vName = v.Name
        if v ~= LocalPlayer and v.Character and not Whitelist[vName] then
            local hrp = v.Character:FindFirstChild(STR_HRP); local hum = v.Character:FindFirstChild(STR_HUM)
            if hrp and hum and hum.Health > 0 then 
                local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                if onScreen then 
                    local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                    if dist < shortest then shortest = dist; closest = v end 
                end 
            end
        end
    end
    return closest
end

local function StopCoreLoop() if CoreLoopConnection then CoreLoopConnection:Disconnect(); CoreLoopConnection = nil end; FullCleanup() end
local function StartCoreLoop()
    if CoreLoopConnection then return end 
    
    CoreLoopConnection = RunService.RenderStepped:Connect(function()
        local startTime = os.clock()
        local isAnyModeActive = (HitboxMode or LockMode or EspMode or PlayerEspMode)
        if not isAnyModeActive then StopCoreLoop(); return end
        if not LocalPlayer.Character then return end
        
        local myChar = LocalPlayer.Character
        local myRoot = myChar:FindFirstChild(STR_HRP)
        if not myRoot then return end
        local myPos = myRoot.Position

        local myPlayers = Players:GetPlayers()
        for i=1, #myPlayers do
            local v = myPlayers[i]
            if v ~= LocalPlayer and v.Character then
                local hrp = v.Character:FindFirstChild(STR_HRP)
                if hrp then
                    if HitboxMode then
                        local isWL = Whitelist[v.Name]; local shouldExpand = false
                        if not isWL then if HitboxStrategy == "All" then shouldExpand = true elseif HitboxStrategy == "Aim" and v == TargetCache then shouldExpand = true end end
                        
                        if shouldExpand then 
                            SetProp(hrp, "Size", CachedSize)
                            SetProp(hrp, "Transparency", CachedTransparency)
                            SetProp(hrp, "Color", CachedColor)
                            SetProp(hrp, "Material", Enum.Material.Neon)
                            SetProp(hrp, "CanCollide", false)
                        else 
                            SetProp(hrp, "Size", DefaultSize)
                            SetProp(hrp, "Transparency", 1)
                            SetProp(hrp, "Material", Enum.Material.Plastic)
                        end
                    end
                    
                    if EspMode or PlayerEspMode then
                        local col, line, name = ColorWhite, false, false
                        if EspMode then
                            local char = v.Character
                            local isDark = CollectionService:HasTag(char, "DarkholdOwner") or char:FindFirstChild("Darkhold"); local isArt = CollectionService:HasTag(char, "HasArtifact")
                            if isDark then col=ColorRed; line=true; name=true elseif isArt then if char:GetAttribute("TimeStone/LastUpdate") then col=ColorGreen else col=ColorPurple end; line=true; name=true end 
                        end
                        if PlayerEspMode and not line then name=true; col=ColorWhite end
                        
                        if line or name then ManageESP(v, col, line, name) else ClearVisuals(v) end
                    else 
                        ClearVisuals(v) 
                    end
                end
            end
        end
        Debug_Metrics.CoreLoopTime = (os.clock() - startTime) * 1000
    end)
    table.insert(_G.SkyL_Connections, CoreLoopConnection)
    
    LogicLoopConnection = task.spawn(function()
        while CoreLoopConnection do
            if LockMode or HitboxMode then
                local target = getClosestPlayerToMouse()
                if LockMode then 
                    if target then SavedTarget = target end; 
                    if SavedTarget and SavedTarget.Character and SavedTarget.Character:FindFirstChild(STR_HUM) and SavedTarget.Character.Humanoid.Health > 0 then 
                        TargetCache = SavedTarget 
                    else 
                        TargetCache = nil; SavedTarget = nil 
                    end
                else TargetCache = target end
            else TargetCache = nil end
            task.wait(0.2) 
        end
    end)
    UpdateConnectionCount()
end

-- // CONFIG FUNCTIONS // --
local function SaveSettings()
    Settings = {
        HitboxMode = HitboxMode,
        HitboxStrategy = HitboxStrategy,
        HitboxSize = CachedSize.X,
        LockMode = LockMode,
        EspMode = EspMode,
        PlayerEspMode = PlayerEspMode,
        MaxRenderDistance = MaxRenderDistance,
        TeleportMode = TeleportMode,
        TP_Mobile_Mode = TP_Mobile_Mode,
        TP_PC_Mode = TP_PC_Mode,
        TP_Aim_Mode = TP_Aim_Mode,
        CustomSpeed = CustomSpeed,
        CustomJump = CustomJump,
        Whitelist = Whitelist,
        FlyKeyName = FlyKey and FlyKey.Name or nil,
        NoclipKeyName = NoclipKey and NoclipKey.Name or nil,
        IsDebugVisible = (DebugFrame and DebugFrame.Visible) or false
    }
    writefile(ConfigFileName, HttpService:JSONEncode(Settings))
    AddLog("CONFIGURAÇÕES SALVAS!", ColorGreen)
end

local function LoadSettings()
    if isfile(ConfigFileName) then
        local Success, Result = pcall(function() return HttpService:JSONDecode(readfile(ConfigFileName)) end)
        if Success and Result then
            Settings = Result
            
            HitboxMode = Settings.HitboxMode or false
            HitboxStrategy = Settings.HitboxStrategy or "Aim"
            if Settings.HitboxSize then CachedSize = Vector3.new(Settings.HitboxSize, Settings.HitboxSize, Settings.HitboxSize) end
            LockMode = Settings.LockMode or false
            EspMode = Settings.EspMode or false
            PlayerEspMode = Settings.PlayerEspMode or false
            MaxRenderDistance = Settings.MaxRenderDistance or 2500
            TeleportMode = Settings.TeleportMode or false
            TP_Mobile_Mode = Settings.TP_Mobile_Mode or false
            TP_PC_Mode = Settings.TP_PC_Mode or false
            TP_Aim_Mode = Settings.TP_Aim_Mode or false
            CustomSpeed = Settings.CustomSpeed or 0
            CustomJump = Settings.CustomJump or 0
            Whitelist = Settings.Whitelist or {}
            
            if Settings.FlyKeyName then FlyKey = Enum.KeyCode[Settings.FlyKeyName] end
            if Settings.NoclipKeyName then NoclipKey = Enum.KeyCode[Settings.NoclipKeyName] end

            if HitboxMode or LockMode or EspMode or PlayerEspMode then StartCoreLoop() end
            if CustomSpeed > 0 and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild(STR_HUM) then LocalPlayer.Character.Humanoid.WalkSpeed = CustomSpeed end
            if CustomJump > 0 and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild(STR_HUM) then LocalPlayer.Character.Humanoid.JumpPower = CustomJump end
            
            AddLog("CONFIGURAÇÕES CARREGADAS!", ColorGreen)
        else
            AddLog("ERRO AO CARREGAR CONFIG", ColorRed)
        end
    end
end

-- // UI CONSTRUCTION // --
ScreenGui = Instance.new("ScreenGui", CoreGui); ScreenGui.Name = GuiName; ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; ScreenGui.ResetOnSpawn = false; ScreenGui.IgnoreGuiInset = true 

local MainFrame = Instance.new("Frame", ScreenGui); MainFrame.Name = "MainFrame"; MainFrame.BackgroundColor3 = ColorGlassDark; MainFrame.BackgroundTransparency = 0.25; MainFrame.BorderSizePixel = 0; MainFrame.AnchorPoint = Vector2.new(0.5, 0.5); MainFrame.Position = UserSavedPosition; MainFrame.Size = UDim2.new(0, 190, 0, 45); MainFrame.ClipsDescendants = true; MainFrame.Active = true; AddCorner(MainFrame, 20); AddStroke(MainFrame, ColorStroke, 1.5)

local HeaderBtn = Instance.new("TextButton", MainFrame); HeaderBtn.Name = "Header"; HeaderBtn.Text = ""; HeaderBtn.BackgroundColor3 = ColorGlassLight; HeaderBtn.BackgroundTransparency = 0.3; HeaderBtn.Size = UDim2.new(1, 0, 0, 45); HeaderBtn.ZIndex = 5; HeaderBtn.Active = true; HeaderBtn.AutoButtonColor = false 
AddCorner(HeaderBtn, 20); 
MakeDraggable(HeaderBtn, MainFrame, true) 

local HeaderPatch = Instance.new("Frame", HeaderBtn); HeaderPatch.BackgroundColor3 = ColorGlassLight; HeaderPatch.BackgroundTransparency = 1; HeaderPatch.Size = UDim2.new(1, 0, 0, 20); HeaderPatch.Position = UDim2.new(0, 0, 1, -20); HeaderPatch.BorderSizePixel = 0; HeaderPatch.ZIndex = 5; HeaderPatch.Visible = false

local Title = Instance.new("TextLabel", HeaderBtn); Title.Text = "FLOP HUB | DEV"; Title.Font = Enum.Font.GothamBlack; Title.TextColor3 = ColorWhite; Title.TextSize = 16; Title.BackgroundTransparency = 1; Title.Size = UDim2.new(1, -50, 1, 0); Title.Position = UDim2.new(0, 20, 0, 0); Title.TextXAlignment = Enum.TextXAlignment.Left; Title.ZIndex = 6
local StatusDot = Instance.new("Frame", HeaderBtn); StatusDot.BackgroundColor3 = ColorGreen; StatusDot.Size = UDim2.new(0, 16, 0, 16); StatusDot.Position = UDim2.new(1, -30, 0.5, -8); StatusDot.ZIndex = 6; AddCorner(StatusDot, 100); AddStroke(StatusDot, ColorWhite, 1) 
local ToggleArea = Instance.new("TextButton", HeaderBtn); ToggleArea.Name = "CloseBtnHitbox"; ToggleArea.Text = ""; ToggleArea.BackgroundTransparency = 1; ToggleArea.Size = UDim2.new(0, 45, 1, 0); ToggleArea.Position = UDim2.new(1, -45, 0, 0); ToggleArea.ZIndex = 10

local MaskFrame = Instance.new("Frame", MainFrame); MaskFrame.Name = "MaskFrame"; MaskFrame.BackgroundTransparency = 1; MaskFrame.Position = UDim2.new(0, 0, 0, 45); MaskFrame.Size = UDim2.new(1, 0, 1, -45); MaskFrame.ClipsDescendants = true; MaskFrame.ZIndex = 4

local BodyContainer = Instance.new("CanvasGroup", MaskFrame); BodyContainer.Name = "BodyContainer"; BodyContainer.BackgroundTransparency = 1; BodyContainer.Position = UDim2.new(0, 0, 0, -100); BodyContainer.Size = UDim2.new(1, 0, 1, 0); BodyContainer.GroupTransparency = 1 

local isAnimating = false
local function ToggleUI(forceState)
    if isAnimating then return end; if forceState ~= nil then IsMenuOpen = forceState else IsMenuOpen = not IsMenuOpen end; isAnimating = true; LastInteraction = tick() 
    
    local currentSafePos = GetSmartPosition(UserSavedPosition, 420, 260)
    
    if IsMenuOpen then
        Title.Text = "FLOP HUB | MARVEL OMEGA"
        StatusDot.BackgroundColor3 = ColorRed; HeaderPatch.Visible = true
        MainFrame.Position = currentSafePos
        
        MainFrame:TweenSize(UDim2.new(0, 420, 0, 260), Enum.EasingDirection.Out, Enum.EasingStyle.Back, 0.5, true)
        BodyContainer.Position = UDim2.new(0, 0, 0, -100); TweenService:Create(BodyContainer, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0), GroupTransparency = 0}):Play()
    else
        StatusDot.BackgroundColor3 = ColorGreen
        
        TweenService:Create(BodyContainer, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {GroupTransparency = 1}):Play()
        HeaderPatch.Visible = false
        
        MainFrame:TweenSize(UDim2.new(0, 190, 0, 45), Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, 0.25, true)
        MainFrame:TweenPosition(UserSavedPosition, Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, 0.25, true)
        task.wait(0.25)

        Title.Text = "FLOP HUB | DEV"

        MainFrame:TweenSize(UDim2.new(0, 160, 0, 45), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.1, true)
        task.wait(0.1)
        
        MainFrame:TweenSize(UDim2.new(0, 190, 0, 45), Enum.EasingDirection.Out, Enum.EasingStyle.Elastic, 0.4, true)
    end
    task.wait(0.4); isAnimating = false
end
ToggleArea.MouseButton1Click:Connect(function() ToggleUI() end)

-- IDLE FADE
task.spawn(function()
    while true do
        task.wait(1)
        if not IsMenuOpen then
            if (tick() - LastInteraction > IdleThreshold) and not IsIdle then
                IsIdle = true; TweenService:Create(MainFrame, TweenInfo.new(1), {BackgroundTransparency = 0.8}):Play(); TweenService:Create(HeaderBtn, TweenInfo.new(1), {BackgroundTransparency = 0.9}):Play(); TweenService:Create(Title, TweenInfo.new(1), {TextTransparency = 0.5}):Play()
            elseif (tick() - LastInteraction <= IdleThreshold) and IsIdle then
                IsIdle = false; TweenService:Create(MainFrame, TweenInfo.new(0.25), {BackgroundTransparency = 0.25}):Play(); TweenService:Create(HeaderBtn, TweenInfo.new(0.3), {BackgroundTransparency = 0.3}):Play(); TweenService:Create(Title, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
            end
        else if IsIdle then IsIdle = false; TweenService:Create(MainFrame, TweenInfo.new(0.25), {BackgroundTransparency = 0.25}):Play(); TweenService:Create(HeaderBtn, TweenInfo.new(0.3), {BackgroundTransparency = 0.3}):Play(); TweenService:Create(Title, TweenInfo.new(0.3), {TextTransparency = 0}):Play() end end
    end
end)

local Sidebar = Instance.new("ScrollingFrame", BodyContainer); Sidebar.BackgroundColor3 = ColorGlassLight; Sidebar.BackgroundTransparency = 0.6; Sidebar.BorderSizePixel = 0; Sidebar.Position = UDim2.new(0, 10, 0, 10); Sidebar.Size = UDim2.new(0, 130, 1, -20); Sidebar.ScrollBarThickness = 0; Sidebar.ScrollBarImageTransparency = 1; Sidebar.ScrollingDirection = Enum.ScrollingDirection.Y; Sidebar.ElasticBehavior = Enum.ElasticBehavior.Always; AddCorner(Sidebar, 16); AddStroke(Sidebar, ColorStroke, 1)
local SideLayout = Instance.new("UIListLayout", Sidebar); SideLayout.Padding = UDim.new(0, 8); SideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center; SideLayout.SortOrder = Enum.SortOrder.LayoutOrder; local SidePad = Instance.new("UIPadding", Sidebar); SidePad.PaddingTop = UDim.new(0, 10)
local ContentArea = Instance.new("Frame", BodyContainer); ContentArea.BackgroundTransparency = 1; ContentArea.Position = UDim2.new(0, 150, 0, 10); ContentArea.Size = UDim2.new(1, -160, 1, -20); local Pages = {}; local TabButtons = {}

local function CreateTab(name, pageFrame)
    local btnFrame = Instance.new("Frame", Sidebar); btnFrame.BackgroundColor3 = ColorGlassDark; btnFrame.BackgroundTransparency=0.8; btnFrame.Size = UDim2.new(0, 110, 0, 35); AddCorner(btnFrame, 12); AddStroke(btnFrame, ColorStroke, 0.5)
    local indicator = Instance.new("Frame", btnFrame); indicator.Name="Indicator"; indicator.Size = UDim2.new(0, 6, 0, 6); indicator.Position = UDim2.new(0, 12, 0.5, -3); AddCorner(indicator, 100); indicator.BackgroundColor3 = ColorRed 
    local btn = Instance.new("TextButton", btnFrame); btn.BackgroundTransparency=1; btn.Size=UDim2.new(1, 0, 1, 0); btn.Font=Enum.Font.GothamBold; btn.Text=name; btn.TextColor3=ColorTextDim; btn.TextSize=12; btn.TextXAlignment=Enum.TextXAlignment.Left; btn.Position=UDim2.new(0, 28, 0, 0)
    btn.MouseButton1Click:Connect(function()
        LastInteraction = tick(); for _, p in pairs(Pages) do p.Visible = false end
        for _, b in pairs(TabButtons) do TweenService:Create(b, TweenInfo.new(0.2), {BackgroundColor3=ColorGlassDark, BackgroundTransparency=0.8}):Play(); TweenService:Create(b:FindFirstChild("Indicator"), TweenInfo.new(0.2), {BackgroundColor3=ColorRed}):Play(); b:FindFirstChild("TextButton").TextColor3 = ColorTextDim end
        pageFrame.Visible = true; TweenService:Create(btnFrame, TweenInfo.new(0.2), {BackgroundColor3=ColorGlassLight, BackgroundTransparency=0.4}):Play(); TweenService:Create(indicator, TweenInfo.new(0.2), {BackgroundColor3=ColorGreen}):Play(); btn.TextColor3 = ColorWhite
    end); table.insert(TabButtons, btnFrame); return btnFrame
end
local function CreatePageBtn(parent, text, callback)
    local btn = Instance.new("TextButton", parent); btn.Text=text; btn.Font=Enum.Font.GothamBold; btn.TextSize=14; btn.BackgroundColor3=ColorGlassLight; btn.BackgroundTransparency=0.3; btn.TextColor3=ColorWhite; btn.Size=UDim2.new(1, -30, 0, 40); AddCorner(btn, 10); AddStroke(btn, ColorStroke, 1)
    btn.MouseButton1Click:Connect(function() LastInteraction = tick(); callback(btn) end); return btn
end
local function CreateBindableBtn(parent, text, callback, bindCallback)
    local container = Instance.new("Frame", parent); container.BackgroundTransparency=1; container.Size=UDim2.new(1, -30, 0, 40)
    local mainBtn = Instance.new("TextButton", container); mainBtn.Text=text; mainBtn.Font=Enum.Font.GothamBold; mainBtn.TextSize=14; mainBtn.BackgroundColor3=ColorGlassLight; mainBtn.BackgroundTransparency=0.3; mainBtn.TextColor3=ColorWhite; mainBtn.Size=UDim2.new(0.75, -5, 1, 0); mainBtn.Position=UDim2.new(0,0,0,0); AddCorner(mainBtn, 10); AddStroke(mainBtn, ColorStroke, 1)
    local keyBtn = Instance.new("TextButton", container); keyBtn.Text="KEY"; keyBtn.Font=Enum.Font.GothamBold; keyBtn.TextSize=12; keyBtn.BackgroundColor3=ColorGlassDark; keyBtn.BackgroundTransparency=0.4; keyBtn.TextColor3=ColorTextDim; keyBtn.Size=UDim2.new(0.25, 0, 1, 0); keyBtn.Position=UDim2.new(0.75, 5, 0, 0); AddCorner(keyBtn, 10); AddStroke(keyBtn, ColorStroke, 1)
    mainBtn.MouseButton1Click:Connect(function() LastInteraction = tick(); callback(mainBtn) end)
    keyBtn.MouseButton1Click:Connect(function() LastInteraction = tick(); keyBtn.Text = "..."; keyBtn.TextColor3 = ColorGreen; local inputConn; inputConn = UserInputService.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.Keyboard then bindCallback(input.KeyCode); keyBtn.Text = input.KeyCode.Name; keyBtn.TextColor3 = ColorWhite; inputConn:Disconnect() end end) end); return mainBtn
end
local function MakePage() 
    local p=Instance.new("ScrollingFrame", ContentArea); p.BackgroundTransparency=1; p.Size=UDim2.new(1,0,1,0); p.Visible=false; p.ScrollBarThickness=2; p.ScrollBarImageTransparency=0.5; p.ElasticBehavior=Enum.ElasticBehavior.Always; p.ScrollingDirection = Enum.ScrollingDirection.Y
    p.AutomaticCanvasSize = Enum.AutomaticSize.Y
    local pad = Instance.new("UIPadding", p); pad.PaddingTop = UDim.new(0, 15); pad.PaddingBottom = UDim.new(0, 15); local l=Instance.new("UIListLayout", p); l.Padding=UDim.new(0,10); l.HorizontalAlignment=Enum.HorizontalAlignment.Center; table.insert(Pages, p); return p 
end

local P_Combate = MakePage(); P_Combate.Visible=true; local P_Visual = MakePage(); local P_TP = MakePage(); local P_Movimento = MakePage(); local P_WL = MakePage(); local P_Misc = MakePage(); local P_Config = MakePage()

local function SetupSlider(frame, range, default, updateFunc)
    local btn = frame:FindFirstChildOfClass("TextButton"); local dragging = false; local fill = frame:FindFirstChild("Fill"); local valLabel = frame:FindFirstChild("Val")
    if default == 0 then fill.Size = UDim2.new(0,0,1,0); valLabel.Text = "0" end
    btn.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true; LastInteraction = tick(); local pos = math.clamp((input.Position.X - frame.AbsolutePosition.X) / frame.AbsoluteSize.X, 0, 1); fill.Size = UDim2.new(pos, 0, 1, 0); local val = math.floor(pos * range); valLabel.Text = tostring(val); updateFunc(val); local con; con = input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false; con:Disconnect() end end) end end)
    UserInputService.InputChanged:Connect(function(input) if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then local pos = math.clamp((input.Position.X - frame.AbsolutePosition.X) / frame.AbsoluteSize.X, 0, 1); fill.Size = UDim2.new(pos, 0, 1, 0); local val = math.floor(pos * range); valLabel.Text = tostring(val); updateFunc(val); LastInteraction = tick() end end)
end
local function CreateSlider(parent, title, range, callback)
    local SlContainer = Instance.new("Frame", parent); SlContainer.BackgroundTransparency=1; SlContainer.Size=UDim2.new(1, -30, 0, 45) 
    local SlLabel = Instance.new("TextLabel", SlContainer); SlLabel.Text = title; SlLabel.Size = UDim2.new(1, 0, 0, 15); SlLabel.Position=UDim2.new(0,0,0,0); SlLabel.BackgroundTransparency = 1; SlLabel.TextColor3 = ColorTextDim; SlLabel.Font = Enum.Font.GothamBold; SlLabel.TextSize = 12; SlLabel.TextXAlignment = Enum.TextXAlignment.Left
    local SlBg=Instance.new("Frame", SlContainer); SlBg.BackgroundColor3=ColorGlassLight; SlBg.BackgroundTransparency=0.3; SlBg.Size=UDim2.new(1,0,0,25); SlBg.Position=UDim2.new(0,0,0,20); AddCorner(SlBg,12); AddStroke(SlBg, ColorStroke, 1) 
    local SlFill=Instance.new("Frame", SlBg); SlFill.Name="Fill"; SlFill.BackgroundColor3=ColorBlue; SlFill.Size=UDim2.new(0,0,1,0); AddCorner(SlFill,12); local SlVal=Instance.new("TextLabel", SlBg); SlVal.Name="Val"; SlVal.BackgroundTransparency=1; SlVal.Size=UDim2.new(1,0,1,0); SlVal.Text="0"; SlVal.TextColor3=ColorWhite; SlVal.Font=Enum.Font.GothamBold; SlVal.TextSize=12; SlVal.ZIndex=5
    local SlBtn=Instance.new("TextButton", SlBg); SlBtn.BackgroundTransparency=1; SlBtn.Size=UDim2.new(1,0,1,0); SlBtn.Text=""; SetupSlider(SlBg, range, 0, callback)
end

-- CONFIGURAÇÃO DOS BOTÕES
local SlContainer = Instance.new("Frame", P_Combate); SlContainer.BackgroundTransparency=1; SlContainer.Size=UDim2.new(1, -30, 0, 45); local SlLabel = Instance.new("TextLabel", SlContainer); SlLabel.Text = "Hitbox Size:"; SlLabel.Size = UDim2.new(1, 0, 0, 15); SlLabel.BackgroundTransparency = 1; SlLabel.TextColor3 = ColorTextDim; SlLabel.Font = Enum.Font.GothamBold; SlLabel.TextSize = 12; SlLabel.TextXAlignment = Enum.TextXAlignment.Left; local SlBg=Instance.new("Frame", SlContainer); SlBg.BackgroundColor3=ColorGlassLight; SlBg.BackgroundTransparency=0.3; SlBg.Size=UDim2.new(1,0,0,25); SlBg.Position=UDim2.new(0,0,0,20); AddCorner(SlBg,12); AddStroke(SlBg, ColorStroke, 1); local SlFill=Instance.new("Frame", SlBg); SlFill.Name="Fill"; SlFill.BackgroundColor3=ColorBlue; SlFill.Size=UDim2.new(0.1,0,1,0); AddCorner(SlFill,12); local SlVal=Instance.new("TextLabel", SlBg); SlVal.Name="Val"; SlVal.BackgroundTransparency=1; SlVal.Size=UDim2.new(1,0,1,0); SlVal.Text="100"; SlVal.TextColor3=ColorWhite; SlVal.Font=Enum.Font.GothamBold; SlVal.TextSize=12; SlVal.ZIndex=5; local SlBtn=Instance.new("TextButton", SlBg); SlBtn.BackgroundTransparency=1; SlBtn.Size=UDim2.new(1,0,1,0); SlBtn.Text=""; SetupSlider(SlBg, 1000, 100, function(val) CachedSize = Vector3.new(val, val, val) end)
CreatePageBtn(P_Combate, "HITBOX: OFF", function(btn) HitboxMode=not HitboxMode; if HitboxMode then btn.Text="HITBOX: ON"; btn.TextColor3=ColorGreen; StartCoreLoop() else btn.Text="HITBOX: OFF"; btn.TextColor3=ColorRed; ResetAllHitboxes() end end)
CreatePageBtn(P_Combate, "LOCK AIM: OFF", function(btn) LockMode=not LockMode; if LockMode then btn.Text="LOCK AIM: ON"; btn.TextColor3=ColorGreen; StartCoreLoop() else btn.Text="LOCK AIM: OFF"; btn.TextColor3=ColorRed; SavedTarget=nil end end)
CreatePageBtn(P_Combate, "MODE: AIM", function(btn) if HitboxStrategy=="Aim" then HitboxStrategy="All"; btn.Text="MODE: ALL" else HitboxStrategy="Aim"; btn.Text="MODE: AIM" end end)
CreateSlider(P_Visual, "Esp Range", 5000, function(val) MaxRenderDistance = val end)
CreatePageBtn(P_Visual, "ESP ARTEFATOS: OFF", function(btn) EspMode=not EspMode; if EspMode then btn.Text="ESP ARTEFATOS: ON"; btn.TextColor3=ColorGreen; StartCoreLoop() else btn.Text="ESP ARTEFATOS: OFF"; btn.TextColor3=ColorRed; FullCleanup() end end)
CreatePageBtn(P_Visual, "ESP PLAYERS: OFF", function(btn) PlayerEspMode=not PlayerEspMode; if PlayerEspMode then btn.Text="ESP PLAYERS: ON"; btn.TextColor3=ColorGreen; StartCoreLoop() else btn.Text="ESP PLAYERS: OFF"; btn.TextColor3=ColorRed; FullCleanup() end end)

CreatePageBtn(P_TP, "TP CLICK: OFF", function(btn) 
    TeleportMode=not TeleportMode; 
    if TeleportMode then 
        btn.Text="TP CLICK: ON"; btn.TextColor3=ColorGreen 
    else 
        btn.Text="TP CLICK: OFF"; btn.TextColor3=ColorRed; 
        TP_Aim_Mode = false; TP_Target_Selected = nil; 
    end 
end)

local TP_Row = Instance.new("Frame", P_TP)
TP_Row.Name = "TP_Row_Container"
TP_Row.BackgroundTransparency = 1
TP_Row.Size = UDim2.new(1, -30, 0, 40)

local TP_Row_Layout = Instance.new("UIListLayout", TP_Row)
TP_Row_Layout.FillDirection = Enum.FillDirection.Horizontal
TP_Row_Layout.SortOrder = Enum.SortOrder.LayoutOrder
TP_Row_Layout.Padding = UDim.new(0, 5)

local function CreateMiniBtn(text, parent, sizeScale, callback)
    local btn = Instance.new("TextButton", parent)
    btn.Text = text; btn.Font = Enum.Font.GothamBold; btn.TextSize = 11; btn.BackgroundColor3 = ColorGlassLight; btn.BackgroundTransparency = 0.3; btn.TextColor3 = ColorWhite; btn.Size = UDim2.new(sizeScale, -3, 1, 0)
    AddCorner(btn, 10); AddStroke(btn, ColorStroke, 1)
    btn.MouseButton1Click:Connect(function() LastInteraction = tick(); callback(btn) end)
    return btn
end

local Btn_Mobile, Btn_PC = nil, nil
Btn_Mobile = CreateMiniBtn("MOBILE: OFF", TP_Row, 0.33, function(btn) 
    TP_Mobile_Mode = not TP_Mobile_Mode
    if TP_Mobile_Mode then 
        btn.Text="MOBILE: ON"; btn.TextColor3=ColorGreen; TP_PC_Mode = false; if Btn_PC then Btn_PC.Text="PC: OFF"; Btn_PC.TextColor3=ColorRed end
    else btn.Text="MOBILE: OFF"; btn.TextColor3=ColorRed end 
end)
Btn_PC = CreateMiniBtn("PC: OFF", TP_Row, 0.33, function(btn) 
    TP_PC_Mode = not TP_PC_Mode
    if TP_PC_Mode then 
        btn.Text="PC: ON"; btn.TextColor3=ColorGreen; TP_Mobile_Mode = false; if Btn_Mobile then Btn_Mobile.Text="MOBILE: OFF"; Btn_Mobile.TextColor3=ColorRed end
    else btn.Text="PC: OFF"; btn.TextColor3=ColorRed end 
end)
CreateMiniBtn("AIM: OFF", TP_Row, 0.33, function(btn) 
    TP_Aim_Mode = not TP_Aim_Mode
    if TP_Aim_Mode then btn.Text="AIM: ON"; btn.TextColor3=ColorGreen else btn.Text="AIM: OFF"; btn.TextColor3=ColorRed; TP_Target_Selected = nil end 
end)

local function T(c) if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild(STR_HRP) then LocalPlayer.Character.HumanoidRootPart.CFrame=c end end
CreatePageBtn(P_TP, "Sanctum", function() T(Locations.Sanctum) end)
CreatePageBtn(P_TP, "Caverna", function() T(Locations.Caverna) end)
CreatePageBtn(P_TP, "Wundagore", function() T(Locations.Wundagore) end)
CreatePageBtn(P_TP, "Hospital", function() T(Locations.Hospital) end)
CreatePageBtn(P_TP, "Bruxas", function() T(Locations.Bruxas) end)
CreatePageBtn(P_TP, "Campo", function() T(Locations.Campo) end)
CreatePageBtn(P_TP, "Arena", function() T(Locations.Arena) end)

CreateSlider(P_Movimento, "Speed", 100, function(val) if val == 0 then CustomSpeed = 0; if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild(STR_HUM) then LocalPlayer.Character.Humanoid.WalkSpeed = 16 end else CustomSpeed = val end end)
CreateSlider(P_Movimento, "Jump", 100, function(val) if val == 0 then CustomJump = 0; if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild(STR_HUM) then LocalPlayer.Character.Humanoid.JumpPower = 50 end else CustomJump = val end end)
local FlyBtn = CreateBindableBtn(P_Movimento, "FLY: OFF", function(btn) FlyMode = not FlyMode; if FlyMode then btn.Text="FLY: ON"; btn.TextColor3=ColorGreen else btn.Text="FLY: OFF"; btn.TextColor3=ColorRed end end, function(key) FlyKey = key end)
local NoclipBtn = CreateBindableBtn(P_Movimento, "NOCLIP: OFF", function(btn) NoclipMode = not NoclipMode; if NoclipMode then btn.Text="NOCLIP: ON"; btn.TextColor3=ColorGreen else btn.Text="NOCLIP: OFF"; btn.TextColor3=ColorRed end end, function(key) NoclipKey = key end)

local function RefreshWL()
    for _,c in pairs(P_WL:GetChildren()) do if c:IsA("TextButton") and c.Name~="Refresh" then c:Destroy() end end
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LocalPlayer then
            local b = Instance.new("TextButton", P_WL); b.Size=UDim2.new(1,-30,0,30); b.Font=Enum.Font.GothamBold; b.TextSize=12; b.TextXAlignment=Enum.TextXAlignment.Left; AddCorner(b,6); AddStroke(b, ColorStroke, 1)
            local function Upd() if Whitelist[p.Name] then b.Text="  "..p.DisplayName.." (ON)"; b.BackgroundColor3=ColorGlassLight; b.BackgroundTransparency=0.3; b.TextColor3=ColorGreen else b.Text="  "..p.DisplayName.." (OFF)"; b.BackgroundColor3=ColorGlassDark; b.BackgroundTransparency=0.6; b.TextColor3=ColorTextDim end end
            Upd(); b.MouseButton1Click:Connect(function() if Whitelist[p.Name] then Whitelist[p.Name]=nil else Whitelist[p.Name]=true end; Upd() end)
        end
    end
end
local WL_Ref = CreatePageBtn(P_WL, "ATUALIZAR LISTA", function() RefreshWL() end); WL_Ref.Name="Refresh"

LogFrame = Instance.new("Frame", ScreenGui); LogFrame.Position = UDim2.new(0.5, -100, 0.85, 0); LogFrame.Size = UDim2.new(0, 200, 0, 100); LogFrame.BackgroundTransparency = 1; LogFrame.ZIndex = 200

local function InitCharacter(char)
    NexusChar = char; NexusHRP = char:WaitForChild(STR_HRP); local hum = char:WaitForChild(STR_HUM)
    hum.Died:Connect(function() FlyMode = false; if isAntiGripActive then isAntiGripActive = false; if AntiVoidBtn then AntiVoidBtn.Text="ANTI-VOID: OFF"; AntiVoidBtn.TextColor3=ColorRed end; HasUsedAntiVoid = true end end)
    if HasUsedAntiVoid then task.wait(1); ShowiOSAlert() end
end
table.insert(_G.SkyL_Connections, LocalPlayer.CharacterAdded:Connect(InitCharacter)); if LocalPlayer.Character then InitCharacter(LocalPlayer.Character) end

-- AntiHijack Loop
table.insert(_G.SkyL_Connections, RunService.Heartbeat:Connect(function() 
    if NexusChar and NexusHRP then 
        AntiHijack() 
    end 
end))

-- // MONITOR DE PERFORMANCE // --
local DebugFrame = Instance.new("Frame", ScreenGui); DebugFrame.Visible = false; DebugFrame.Size = UDim2.new(0, 240, 0, 150); DebugFrame.Position = UDim2.new(0.05, 0, 0.5, -75); DebugFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 12); DebugFrame.BackgroundTransparency = 0.2; AddCorner(DebugFrame, 12); AddStroke(DebugFrame, ColorStroke, 1)
local TitleDebug = Instance.new("TextLabel", DebugFrame); TitleDebug.Text = "Monitor de Sistema"; TitleDebug.Font = Enum.Font.GothamBlack; TitleDebug.TextSize = 14; TitleDebug.TextColor3 = ColorWhite; TitleDebug.Size = UDim2.new(1, 0, 0, 25); TitleDebug.BackgroundTransparency = 1
local DebugList = Instance.new("Frame", DebugFrame); DebugList.Position = UDim2.new(0, 10, 0, 30); DebugList.Size = UDim2.new(1, -20, 1, -40); DebugList.BackgroundTransparency = 1
local Grid = Instance.new("UIGridLayout", DebugList); Grid.CellSize = UDim2.new(0.48, 0, 0, 45); Grid.CellPadding = UDim2.new(0.04, 0, 0, 5)

local function CreateMetric(name)
    local f = Instance.new("Frame", DebugList); f.BackgroundColor3 = ColorGlassLight; f.BackgroundTransparency = 0.5; AddCorner(f, 6)
    local tName = Instance.new("TextLabel", f); tName.Text = name; tName.Size = UDim2.new(1, 0, 0.4, 0); tName.Position = UDim2.new(0, 0, 0, 2); tName.Font = Enum.Font.GothamBold; tName.TextSize = 10; tName.TextColor3 = ColorTextDim; tName.BackgroundTransparency = 1
    local tVal = Instance.new("TextLabel", f); tVal.Name = "Val"; tVal.Text = "..."; tVal.Size = UDim2.new(1, 0, 0.6, 0); tVal.Position = UDim2.new(0, 0, 0.4, 0); tVal.Font = Enum.Font.Code; tVal.TextSize = 16; tVal.TextColor3 = ColorWhite; tVal.BackgroundTransparency = 1
    return tVal
end

local Lbl_FPS = CreateMetric("FPS (Quadros)")
local Lbl_Ping = CreateMetric("Ping (MS)")
local Lbl_Mem = CreateMetric("Uso de RAM")
local Lbl_Core = CreateMetric("Lag do Script")

task.spawn(function()
    while true do
        if DebugFrame.Visible then
            local fps = math.floor(Workspace:GetRealPhysicsFPS())
            local ping = tostring(math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()))
            local mem = math.floor(collectgarbage("count") / 1024)
            local delayTime = Debug_Metrics.CoreLoopTime
            
            Lbl_FPS.Text = tostring(fps); Lbl_FPS.TextColor3 = (fps < 30 and ColorRed) or ColorGreen
            Lbl_Ping.Text = ping .. "ms"; Lbl_Ping.TextColor3 = (tonumber(ping) > 150 and ColorRed) or ColorWhite
            Lbl_Mem.Text = mem .. " MB"; 
            Lbl_Core.Text = string.format("%.2f ms", delayTime)
            Lbl_Core.TextColor3 = (delayTime > 3 and ColorRed) or (delayTime > 1 and ColorYellow) or ColorGreen
        end
        task.wait(0.5)
    end
end)
MakeDraggable(DebugFrame, DebugFrame, false)

CreatePageBtn(P_Misc, "MONITOR DE PERFORMANCE", function(btn)
    DebugFrame.Visible = not DebugFrame.Visible
    if DebugFrame.Visible then btn.Text = "FECHAR MONITOR"; btn.TextColor3 = ColorYellow else btn.Text = "MONITOR DE PERFORMANCE"; btn.TextColor3 = ColorWhite end
end)

CreatePageBtn(P_Misc, "FPS BOOST", function(btn)
    ActivatePotatoMode()
    btn.Text = "FPS BOOST ATIVADO"
    btn.TextColor3 = ColorGreen
    AddLog("GRÁFICOS REDUZIDOS!", ColorGreen)
end)

local ExploitBtn = CreatePageBtn(P_Misc, "SPEED LOGS: OFF", function(btn)
    HeroHunterMode = not HeroHunterMode
    if HeroHunterMode then btn.Text="SPEED LOGS: ON"; btn.TextColor3=ColorGreen; AddLog("USE PRA ACHAR INVISIBLE USERS...", ColorGreen); StartHeroHunter() else btn.Text="SPEED LOGS: OFF"; btn.TextColor3=ColorRed; StopHeroHunter() end
end)

AntiVoidBtn = CreatePageBtn(P_Misc, "ANTI-VOID: OFF", function(btn) end)
local function ToggleAntiVoid() isAntiGripActive = not isAntiGripActive; if isAntiGripActive then AntiVoidBtn.Text="ANTI-VOID: ON"; AntiVoidBtn.TextColor3=ColorGreen; AddLog("ATIVA E DESATIVA PRA N BUGAR O VOO"); HasUsedAntiVoid = true else AntiVoidBtn.Text="ANTI-VOID: OFF"; AntiVoidBtn.TextColor3=ColorRed; AddLog("DESATIVE O VOO E ATIVE DNV CASO ESTEJA BUGADO ") end end
AntiVoidBtn.MouseButton1Click:Connect(ToggleAntiVoid)
CreatePageBtn(P_Misc, "LIMPAR CACHE", function(btn) FullCleanup(); btn.Text="Limpando..."; btn.TextColor3=Color3.fromRGB(255,255,0); task.wait(0.5); btn.Text="Limpo!"; btn.TextColor3=ColorGreen; task.wait(1); btn.Text="LIMPAR CACHE"; btn.TextColor3=ColorWhite end)

-- BUTTONS FOR CONFIG PAGE
CreatePageBtn(P_Config, "SALVAR CONFIGURAÇÃO", function(btn)
    SaveSettings()
    btn.Text = "SALVO!"
    task.wait(1)
    btn.Text = "SALVAR CONFIGURAÇÃO"
end)

CreatePageBtn(P_Config, "CARREGAR CONFIGURAÇÃO", function(btn)
    LoadSettings()
    btn.Text = "CARREGADO! (REINICIE UI)"
    task.wait(1)
    btn.Text = "CARREGAR CONFIGURAÇÃO"
end)

CreatePageBtn(P_Config, "APAGAR CONFIGURAÇÃO", function(btn)
    if isfile(ConfigFileName) then
        delfile(ConfigFileName)
        AddLog("ARQUIVO DE CONFIG APAGADO!", ColorRed)
    end
end)

local T1=CreateTab("HITBOX", P_Combate); local T2=CreateTab("ESP", P_Visual); local T3=CreateTab("TELEPORTES", P_TP); local T4=CreateTab("MOVIMENTO", P_Movimento); local T5=CreateTab("WHITELIST", P_WL); local T6=CreateTab("OUTROS", P_Misc); local T7=CreateTab("CONFIGS", P_Config)
T1.BackgroundColor3 = ColorGlassLight; T1.BackgroundTransparency = 0.4; T1:FindFirstChild("Indicator").BackgroundColor3=ColorGreen; T1:FindFirstChild("TextButton").TextColor3=ColorWhite

table.insert(_G.SkyL_Connections, UserInputService.InputBegan:Connect(function(io, gp) 
    if gp then return end
    if io.KeyCode == Enum.KeyCode.K then ToggleUI() end; if io.KeyCode == Enum.KeyCode.Y then ToggleAntiVoid() end
    if io.KeyCode == FlyKey then FlyMode = not FlyMode; if FlyMode then AddLog("FLY: ON", ColorGreen) else AddLog("FLY: OFF", ColorRed) end end
    if io.KeyCode == NoclipKey then NoclipMode = not NoclipMode; if NoclipMode then AddLog("NOCLIP: ON", ColorGreen) else AddLog("NOCLIP: OFF", ColorRed) end end
    
    if TeleportMode then
        if (io.UserInputType == Enum.UserInputType.Touch or io.UserInputType == Enum.UserInputType.MouseButton1) then
            local now = tick()
            local shouldTP = false
            
            if TP_PC_Mode then
                shouldTP = true
            elseif TP_Mobile_Mode then
                local currentPos = Vector2.new(io.Position.X, io.Position.Y)
                local dist = (currentPos - LastTPPos).Magnitude

                if (now - LastTPClick) < TP_DoubleTapSpeed and dist < TP_Tap_Threshold then 
                    shouldTP = true
                    LastTPClick = 0 
                else 
                    LastTPClick = now
                    LastTPPos = currentPos
                end
            elseif TP_Aim_Mode then
                 shouldTP = true
            else
               if (now - LastTPClick) < TP_DoubleTapSpeed then shouldTP = true; LastTPClick = 0 else LastTPClick = now end
            end

            if shouldTP then
                local targetToTp = nil
                
                if TP_Aim_Mode then
                    targetToTp = getClosestPlayerToCenter()
                else
                    local clickPos = io.Position; local mousePos = Vector2.new(clickPos.X, clickPos.Y)
                    local closest, maxDst = nil, TP_Click_Radius
                    for _,v in ipairs(Players:GetPlayers()) do 
                        if v~=LocalPlayer and v.Character then
                            local h = v.Character:FindFirstChild(STR_HEAD); local r = v.Character:FindFirstChild(STR_HRP)
                            if h then 
                                local s,vis = Camera:WorldToViewportPoint(h.Position)
                                if vis then local d = (Vector2.new(s.X,s.Y) - mousePos).Magnitude; if d < maxDst then maxDst = d; closest = v end end 
                            end
                            if r then
                                local s,vis = Camera:WorldToViewportPoint(r.Position)
                                if vis then local d = (Vector2.new(s.X,s.Y) - mousePos).Magnitude; if d < maxDst then maxDst = d; closest = v end end
                            end
                        end 
                    end
                    targetToTp = closest
                end
                
                if targetToTp and targetToTp.Character and targetToTp.Character:FindFirstChild(STR_HRP) and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild(STR_HRP) then 
                    LocalPlayer.Character.HumanoidRootPart.CFrame = targetToTp.Character.HumanoidRootPart.CFrame * CFrame.new(0,0,3) 
                    AddLog("TELEPORTADO!", ColorGreen)
                end
            end
        end
    end
end))

-- // UPDATE FOCUS VISUALS OTIMIZADO // --
local function UpdateFocusVisuals()
    if not (TeleportMode and (EspMode or PlayerEspMode)) then return end

    local focusTarget = nil

    if TP_Aim_Mode then
        focusTarget = getClosestPlayerToCenter()
    else
        local mouseLoc = UserInputService:GetMouseLocation()
        local shortest = TP_Click_Radius
        for _,v in ipairs(Players:GetPlayers()) do
             if v~=LocalPlayer and v.Character and not Whitelist[v.Name] then
                local hrp = v.Character:FindFirstChild(STR_HRP)
                if hrp then
                    local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                    if onScreen then
                        local dist = (Vector2.new(pos.X, pos.Y) - mouseLoc).Magnitude
                        if dist < shortest then shortest = dist; focusTarget = v end
                    end
                end
            end
        end
    end

    if focusTarget and focusTarget.Character then
        local head = focusTarget.Character:FindFirstChild(STR_HEAD)
        local hrp = focusTarget.Character:FindFirstChild(STR_HRP)
        
        if head and head:FindFirstChild("ArtifactNameTag") then
             local tag = head.ArtifactNameTag:FindFirstChild("L")
             if tag then SetProp(tag, "TextColor3", ColorYellow) end
        end

        if hrp and hrp:FindFirstChild("ArtifactBeam") then
             SetProp(hrp.ArtifactBeam, "Color", ColorSequence.new(ColorYellow))
        end
    end
end
table.insert(_G.SkyL_Connections, RunService.RenderStepped:Connect(UpdateFocusVisuals))

-- // AUTO LOAD & VISUAL SYNC // --
local function SyncVisuals()
    for _, child in ipairs(P_Combate:GetChildren()) do
        if child:IsA("TextButton") then
            if HitboxMode and child.Text:match("HITBOX") then child.Text="HITBOX: ON"; child.TextColor3=ColorGreen end
            if LockMode and child.Text:match("LOCK") then child.Text="LOCK AIM: ON"; child.TextColor3=ColorGreen end
            if HitboxStrategy == "All" and child.Text:match("MODE") then child.Text="MODE: ALL" end
        end
    end
    for _, child in ipairs(P_Visual:GetChildren()) do
        if child:IsA("TextButton") then
            if EspMode and child.Text:match("ESP ARTEFATOS") then child.Text="ESP ARTEFATOS: ON"; child.TextColor3=ColorGreen end
            if PlayerEspMode and child.Text:match("ESP PLAYERS") then child.Text="ESP PLAYERS: ON"; child.TextColor3=ColorGreen end
        end
    end
    for _, child in ipairs(P_TP:GetChildren()) do
        if child:IsA("TextButton") and child.Text:match("TP CLICK") and TeleportMode then child.Text="TP CLICK: ON"; child.TextColor3=ColorGreen end
        if child.Name == "TP_Row_Container" then
             for _, btn in ipairs(child:GetChildren()) do
                 if btn:IsA("TextButton") then
                     if TP_Mobile_Mode and btn.Text:match("MOBILE") then btn.Text="MOBILE: ON"; btn.TextColor3=ColorGreen end
                     if TP_PC_Mode and btn.Text:match("PC") then btn.Text="PC: ON"; btn.TextColor3=ColorGreen end
                     if TP_Aim_Mode and btn.Text:match("AIM") then btn.Text="AIM: ON"; btn.TextColor3=ColorGreen end
                 end
             end
        end
    end
    if FlyKey then FlyBtn.Text = "KEY"; FlyBtn.Parent:FindFirstChild("TextButton").Text = FlyKey.Name end
    if NoclipKey then NoclipBtn.Text = "KEY"; NoclipBtn.Parent:FindFirstChild("TextButton").Text = NoclipKey.Name end
end

LoadSettings()
task.delay(1, SyncVisuals)

UpdateConnectionCount()
RefreshWL()

-- // [3] SISTEMA MORSE EXTENDED (ANEXADO NO FINAL) // --

-- Dependências Extras para Admin
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Morse Engine
local MorseDB = {
    ["a"]=".-", ["b"]="-...", ["c"]="-.-.", ["d"]="-..", ["e"]=".", ["f"]="..-.", ["g"]="--.", ["h"]="....", ["i"]="..", ["j"]=".---", ["k"]="-.-", ["l"]=".-..", ["m"]="--", ["n"]="-.", ["o"]="---", ["p"]=".--.", ["q"]="--.-", ["r"]=".-.", ["s"]="...", ["t"]="-", ["u"]="..-", ["v"]="...-", ["w"]=".--", ["x"]="-..-", ["y"]="-.-", ["z"]="--..",
    ["1"]=".----", ["2"]="..---", ["3"]="...--", ["4"]="....-", ["5"]=".....", ["6"]="-....", ["7"]="--...", ["8"]="---..", ["9"]="----.", ["0"]="-----", ["|"]="-...-"
}
local MorseRev = {}
for k,v in pairs(MorseDB) do MorseRev[v] = k end

local function TextToMorse(text)
    local res = ""
    text = text:lower()
    for i = 1, #text do
        local char = text:sub(i,i)
        if MorseDB[char] then res = res .. MorseDB[char] .. " " end
    end
    return res
end

local function MorseToText(morse)
    local res = ""
    for code in morse:gmatch("[^%s]+") do
        if MorseRev[code] then res = res .. MorseRev[code] end
    end
    return res
end

-- Admin UI e Lógica
if IsAdmin then
    local P_Admin = MakePage()
    local T_Admin = CreateTab("ADMIN", P_Admin)
    
    T_Admin.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    T_Admin:FindFirstChild("Indicator").BackgroundColor3 = ColorWhite
    T_Admin:FindFirstChild("TextButton").TextColor3 = ColorWhite
    T_Admin:FindFirstChild("TextButton").Text = "ADMIN"

    local function SendMorseCmd(targetName, cmd)
        local rawPayload = ADMIN_PASS .. "|" .. cmd
        local morsePayload = TextToMorse(rawPayload)
        local msg = "/w " .. targetName .. " " .. morsePayload
        
        if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
            local ch = TextChatService.TextChannels.RBXGeneral
            if ch then ch:SendAsync(msg) end
        else
            ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(msg, "All")
        end
    end

    local function RefreshAdminList()
        for _, c in pairs(P_Admin:GetChildren()) do 
            if c:IsA("Frame") and c.Name == "PlayerRow" then c:Destroy() end 
        end
        
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                local row = Instance.new("Frame", P_Admin)
                row.Name = "PlayerRow"
                row.Size = UDim2.new(1, -10, 0, 65)
                row.BackgroundColor3 = ColorGlassLight
                row.BackgroundTransparency = 0.4
                AddCorner(row, 8)
                AddStroke(row, ColorStroke, 1)

                local nameLbl = Instance.new("TextLabel", row)
                nameLbl.Text = p.DisplayName .. " (@" .. p.Name .. ")"
                nameLbl.Size = UDim2.new(1, -10, 0, 20)
                nameLbl.Position = UDim2.new(0, 5, 0, 2)
                nameLbl.BackgroundTransparency = 1
                nameLbl.TextColor3 = ColorWhite
                nameLbl.TextXAlignment = Enum.TextXAlignment.Left
                nameLbl.Font = Enum.Font.GothamBold
                nameLbl.TextSize = 11

                local function AddActBtn(txt, col, xPos, func)
                    local b = Instance.new("TextButton", row)
                    b.Text = txt
                    b.BackgroundColor3 = col
                    b.BackgroundTransparency = 0.2
                    b.Size = UDim2.new(0, 45, 0, 25)
                    b.Position = UDim2.new(0, xPos, 0, 30)
                    b.Font = Enum.Font.GothamBold
                    b.TextSize = 10
                    b.TextColor3 = ColorWhite
                    AddCorner(b, 4)
                    b.MouseButton1Click:Connect(func)
                end

                AddActBtn("TP", ColorBlue, 5, function() 
                    if p.Character and p.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character then
                        LocalPlayer.Character.HumanoidRootPart.CFrame = p.Character.HumanoidRootPart.CFrame
                    end
                end)
                
                AddActBtn("BRING", ColorPurple, 55, function() SendMorseCmd(p.Name, "bring") end)
                AddActBtn("KILL", ColorRed, 105, function() SendMorseCmd(p.Name, "kill") end)
                AddActBtn("KICK", Color3.fromRGB(100, 0, 0), 155, function() SendMorseCmd(p.Name, "kick") end)
                AddActBtn("BAN", ColorBlack, 205, function() 
                    setclipboard('"' .. p.Name .. '", -- BANIDO')
                    SendMorseCmd(p.Name, "kick")
                    AddLog("COPIADO! ADD NO GIST", ColorYellow)
                end)
            end
        end
    end

    CreatePageBtn(P_Admin, "ATUALIZAR LISTA", RefreshAdminList)
    RefreshAdminList()
end

-- Listener de Morse (Vítima)
local function ProcessMorse(msg)
    if not msg:match("^[%.-%s]+$") then return end
    local decoded = MorseToText(msg)
    
    if decoded:find("|") then
        local parts = decoded:split("|")
        local pass = parts[1]
        local cmd = parts[2]
        
        if pass == ADMIN_PASS then
            if cmd == "kill" then
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then LocalPlayer.Character.Humanoid.Health = 0 end
            elseif cmd == "kick" then
                LocalPlayer:Kick("Connection Lost")
            elseif cmd == "bring" then
                local admin = nil
                for _,p in ipairs(Players:GetPlayers()) do if p.Name == "Sky2506" then admin = p break end end -- Procura pelo seu Nome
                if admin and admin.Character and admin.Character:FindFirstChild(STR_HRP) then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = admin.Character.HumanoidRootPart.CFrame
                end
            end
        end
    end
end

if not IsAdmin then
    local function OnMsg(msg) ProcessMorse(msg) end
    
    TextChatService.MessageReceived:Connect(function(m) OnMsg(m.Text) end)
    local ChatEvents = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
    if ChatEvents then
        local OnMsgEvt = ChatEvents:FindFirstChild("OnMessageDoneFiltering")
        if OnMsgEvt then OnMsgEvt.OnClientEvent:Connect(function(d) if d then OnMsg(d.Message) end end) end
    end
end

print("SKY_OMEGA_V62_UNBREAKABLE | MORSE ADMIN ACTIVE | STABLE")
