local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- // 1. LIMPEZA TOTAL // --
if _G.SkyL_Connections then
    for _, connection in pairs(_G.SkyL_Connections) do
        if connection then connection:Disconnect() end
    end
end
_G.SkyL_Connections = {} 

local GuiName = "SkyL_Compact_V21" 
if CoreGui:FindFirstChild(GuiName) then CoreGui[GuiName]:Destroy() end

-- // 2. VARIÁVEIS // --
local HitboxMode = false 
local LockMode = false 
local TeamCheckMode = false 
local EspMode = false        
local PlayerEspMode = false 
local TeleportMode = false 
local FarmMode = false 
local IsBoosted = false

local SpectateTarget = nil 
local SavedTarget = nil 
local IsMenuOpen = true
local IsWhitelistOpen = false
local IsTpMenuOpen = false 
local FOV_Radius = 300 

-- Otimização
local LastTPClick = 0
local TP_Cooldown = 0.25
local LastEspUpdate = 0
local EspUpdateRate = 1/20 
local MaxRenderDistance = 3000 
local LastGCCycle = 0
local GC_Interval = 10 
local ChestCache = {} 

local Whitelist = {} 

-- Cache Visual
local CachedSize = Vector3.new(10, 10, 10)
local CachedColor = Color3.new(0.5, 0.5, 0.5)
local CachedTransparency = 0.8 
local DefaultSize = Vector3.new(2, 2, 1)

local ColorRed = Color3.fromRGB(255, 40, 40)
local ColorYellow = Color3.fromRGB(255, 235, 50)
local ColorWhite = Color3.new(1, 1, 1)
local ColorGreen = Color3.fromRGB(60, 220, 100)
local ColorDarkGray = Color3.fromRGB(35, 35, 40)
local ColorBG = Color3.fromRGB(20, 20, 25)
local ColorBorder = Color3.fromRGB(60, 60, 65)

local Locations = {
    Sanctum = CFrame.new(2379.8015, 686.3657, 659.2962),
    Caverna = CFrame.new(-351.8613, 697.4421, 1903.7971),
    Wundagore = CFrame.new(-2818.6208, 1050.8438, 649.0917),
    Hospital = CFrame.new(376.6887, 649.5777, 1422.3016)
}

-- // 3. UI SETUP // --
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = GuiName
ScreenGui.Parent = CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true 

local function AddCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = parent
    return corner
end

local function AddStroke(parent, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = ColorBorder
    stroke.Thickness = thickness
    stroke.Parent = parent
    return stroke
end

-- Frame Principal (COMPACTO)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = ColorBG
MainFrame.Position = UDim2.new(0.5, -115, 0.5, -175) -- Centralizado
MainFrame.Size = UDim2.new(0, 230, 0, 350) -- Tamanho Reduzido
MainFrame.Visible = true
AddCorner(MainFrame, 8)
AddStroke(MainFrame, 1.5)

-- Título
local Title = Instance.new("TextLabel", MainFrame)
Title.BackgroundTransparency = 1; Title.Position = UDim2.new(0, 10, 0, 8); Title.Size = UDim2.new(0, 180, 0, 20)
Title.Font = Enum.Font.GothamBold; Title.Text = "Flop Omega "; Title.TextColor3 = Color3.fromRGB(255, 255, 255); Title.TextSize = 14; Title.TextXAlignment = Enum.TextXAlignment.Left

local CloseButton = Instance.new("TextButton", MainFrame)
CloseButton.BackgroundColor3 = Color3.fromRGB(180, 40, 40); CloseButton.Position = UDim2.new(1, -25, 0, 8); CloseButton.Size = UDim2.new(0, 18, 0, 18)
CloseButton.Font = Enum.Font.GothamBold; CloseButton.Text = ""; CloseButton.TextSize = 12
AddCorner(CloseButton, 4)

-- Botão Abrir
local OpenBtn = Instance.new("TextButton", ScreenGui)
OpenBtn.BackgroundColor3 = ColorBG; OpenBtn.Position = UDim2.new(0.01, 0, 0.5, 0); OpenBtn.Size = UDim2.new(0, 40, 0, 40)
OpenBtn.Font = Enum.Font.GothamBold; OpenBtn.Text = "M"; OpenBtn.TextColor3 = Color3.fromRGB(255, 255, 255); OpenBtn.TextSize = 20; OpenBtn.Visible = false
AddCorner(OpenBtn, 8); AddStroke(OpenBtn, 2)

-- === INPUTS COMPACTOS === --
local function CreateInput(parent, ph, txt, pos, w)
    local box = Instance.new("TextBox", parent)
    box.BackgroundColor3 = ColorDarkGray; box.Position = pos; box.Size = UDim2.new(0, w, 0, 25)
    box.Font = Enum.Font.Gotham; box.PlaceholderText = ph; box.Text = txt; box.TextColor3 = Color3.fromRGB(255, 255, 255); box.TextSize = 11
    AddCorner(box, 4); AddStroke(box, 1)
    return box
end

local HitboxInput = CreateInput(MainFrame, "Tam.", "35", UDim2.new(0, 10, 0, 35), 100)
local TranspInput = CreateInput(MainFrame, "Alpha", "0.8", UDim2.new(1, -110, 0, 35), 100)

local R_Input = CreateInput(MainFrame, "R", "0.5", UDim2.new(0, 10, 0, 65), 65); R_Input.TextColor3 = Color3.fromRGB(255, 100, 100)
local G_Input = CreateInput(MainFrame, "G", "0.5", UDim2.new(0.5, -32, 0, 65), 65); G_Input.TextColor3 = Color3.fromRGB(100, 255, 100)
local B_Input = CreateInput(MainFrame, "B", "0.5", UDim2.new(1, -75, 0, 65), 65); B_Input.TextColor3 = Color3.fromRGB(100, 100, 255)

local function UpdateCache()
    local s = tonumber(HitboxInput.Text) or 35; CachedSize = Vector3.new(s, s, s)
    local t = tonumber(TranspInput.Text) or 0.8; if t > 1 then t = 1 end; CachedTransparency = t
    local r = tonumber(R_Input.Text) or 0.5; local g = tonumber(G_Input.Text) or 0.5; local b = tonumber(B_Input.Text) or 0.5
    CachedColor = Color3.new(r, g, b)
end
table.insert(_G.SkyL_Connections, HitboxInput.FocusLost:Connect(UpdateCache))
table.insert(_G.SkyL_Connections, TranspInput.FocusLost:Connect(UpdateCache))
table.insert(_G.SkyL_Connections, R_Input.FocusLost:Connect(UpdateCache))
table.insert(_G.SkyL_Connections, G_Input.FocusLost:Connect(UpdateCache))
table.insert(_G.SkyL_Connections, B_Input.FocusLost:Connect(UpdateCache))

-- === FUNÇÕES DE RESET === --
local function ResetAllHitboxes()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.Size = DefaultSize; hrp.Transparency = 1; hrp.Material = Enum.Material.Plastic; hrp.CanCollide = false end
        end
    end
end

local function ClearVisuals(p)
    if p and p.Character then
        local hrp = p.Character:FindFirstChild("HumanoidRootPart"); local head = p.Character:FindFirstChild("Head")
        if hrp then
            if hrp:FindFirstChild("ArtifactBeam") then hrp.ArtifactBeam:Destroy() end
            if hrp:FindFirstChild("EspAttTarget") then hrp.EspAttTarget:Destroy() end
        end
        if head and head:FindFirstChild("ArtifactNameTag") then head.ArtifactNameTag:Destroy() end
    end
end

local function FullCleanup()
    for _, p in pairs(Players:GetPlayers()) do ClearVisuals(p) end
    SpectateTarget = nil; SavedTarget = nil
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then Camera.CameraSubject = LocalPlayer.Character.Humanoid end
    ChestCache = {}; collectgarbage("collect")
end

-- === BOTÕES DO MENU (GRID OTIMIZADO) === --
local function CreateBtn(text, pos, callback, parent)
    local p = parent or MainFrame
    local btn = Instance.new("TextButton", p)
    btn.BackgroundColor3 = ColorDarkGray; btn.Position = pos; btn.Size = UDim2.new(0, 102, 0, 28)
    btn.Font = Enum.Font.GothamBold; btn.Text = text; btn.TextColor3 = Color3.fromRGB(255, 100, 100); btn.TextSize = 11
    AddCorner(btn, 6); AddStroke(btn, 1)
    table.insert(_G.SkyL_Connections, btn.MouseButton1Click:Connect(function() callback(btn) end))
    return btn
end

-- Linha 1 (Y: 100)
CreateBtn("Hitbox: OFF", UDim2.new(0, 10, 0, 100), function(btn)
    HitboxMode = not HitboxMode
    if HitboxMode then btn.Text = "Hitbox: ON"; btn.TextColor3 = ColorGreen; btn.BackgroundColor3 = Color3.fromRGB(45, 55, 45)
    else btn.Text = "Hitbox: OFF"; btn.TextColor3 = Color3.fromRGB(255, 100, 100); btn.BackgroundColor3 = ColorDarkGray; ResetAllHitboxes() end
end)
CreateBtn("Lock: OFF", UDim2.new(1, -112, 0, 100), function(btn)
    LockMode = not LockMode
    if LockMode then btn.Text = "Lock: ON"; btn.TextColor3 = ColorGreen; btn.BackgroundColor3 = Color3.fromRGB(45, 55, 45)
    else btn.Text = "Lock: OFF"; btn.TextColor3 = Color3.fromRGB(255, 100, 100); btn.BackgroundColor3 = ColorDarkGray; SavedTarget = nil end
end)

-- Linha 2 (Y: 135)
CreateBtn("Team: OFF", UDim2.new(0, 10, 0, 135), function(btn)
    TeamCheckMode = not TeamCheckMode
    if TeamCheckMode then btn.Text = "Team: ON"; btn.TextColor3 = ColorGreen; btn.BackgroundColor3 = Color3.fromRGB(45, 55, 45)
    else btn.Text = "Team: OFF"; btn.TextColor3 = Color3.fromRGB(255, 100, 100); btn.BackgroundColor3 = ColorDarkGray end
end)
local WL_Btn = CreateBtn("White List >", UDim2.new(1, -112, 0, 135), function(btn)
    IsWhitelistOpen = not IsWhitelistOpen; IsTpMenuOpen = false
    local tpFrame = ScreenGui:FindFirstChild("TeleportFrame"); if tpFrame then tpFrame.Visible = false end -- Fecha TP se abrir WL (Opcional, mantive logica antiga p/ WL)
    -- WL Frame atualiza em UpdateWhitelistUI
    local WL_F = ScreenGui:FindFirstChild("WL_Frame_Unique")
    if WL_F then WL_F.Visible = IsWhitelistOpen end
end); WL_Btn.BackgroundColor3 = Color3.fromRGB(50, 50, 60); WL_Btn.TextColor3 = Color3.fromRGB(200, 200, 255)

-- Linha 3 (Y: 170)
CreateBtn("ESP Art: OFF", UDim2.new(0, 10, 0, 170), function(btn)
    EspMode = not EspMode
    if EspMode then btn.Text = "ESP Art: ON"; btn.TextColor3 = ColorGreen; btn.BackgroundColor3 = Color3.fromRGB(45, 55, 45)
    else btn.Text = "ESP Art: OFF"; btn.TextColor3 = Color3.fromRGB(255, 100, 100); btn.BackgroundColor3 = ColorDarkGray; FullCleanup() end
end)
CreateBtn("ESP Play: OFF", UDim2.new(1, -112, 0, 170), function(btn)
    PlayerEspMode = not PlayerEspMode
    if PlayerEspMode then btn.Text = "ESP Play: ON"; btn.TextColor3 = ColorGreen; btn.BackgroundColor3 = Color3.fromRGB(45, 55, 45)
    else btn.Text = "ESP Play: OFF"; btn.TextColor3 = Color3.fromRGB(255, 100, 100); btn.BackgroundColor3 = ColorDarkGray; FullCleanup() end
end)

-- Linha 4 (Y: 205)
CreateBtn("TP Click: OFF", UDim2.new(0, 10, 0, 205), function(btn) 
    TeleportMode = not TeleportMode
    if TeleportMode then btn.Text = "TP Click: ON"; btn.TextColor3 = ColorGreen; btn.BackgroundColor3 = Color3.fromRGB(45, 55, 45)
    else btn.Text = "TP Click: OFF"; btn.TextColor3 = Color3.fromRGB(255, 100, 100); btn.BackgroundColor3 = ColorDarkGray end
end)
local ArtTP_Btn = CreateBtn("Art TP >", UDim2.new(1, -112, 0, 205), function(btn)
    IsTpMenuOpen = not IsTpMenuOpen; 
    local TP_F = ScreenGui:FindFirstChild("TeleportFrame"); if TP_F then TP_F.Visible = IsTpMenuOpen end
end); ArtTP_Btn.BackgroundColor3 = Color3.fromRGB(50, 50, 60); ArtTP_Btn.TextColor3 = Color3.fromRGB(255, 220, 100)

-- Linha 5 (Y: 240)
local SpecBtn = CreateBtn("Watch [V]: OFF", UDim2.new(0, 10, 0, 240), function(btn) 
    SpectateTarget = nil
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then Camera.CameraSubject = LocalPlayer.Character.Humanoid end
    btn.Text = "Watch [V]: OFF"; btn.TextColor3 = Color3.fromRGB(255, 100, 100); btn.BackgroundColor3 = ColorDarkGray
end)
local BoostBtn = CreateBtn("FPS Boost", UDim2.new(1, -112, 0, 240), function(btn)
    if not IsBoosted then
        IsBoosted = true; btn.Text = "Boost: ON"; btn.TextColor3 = ColorGreen; btn.BackgroundColor3 = Color3.fromRGB(45, 55, 45)
        task.spawn(function()
            local l = game:GetService("Lighting"); l.GlobalShadows = false; l.FogEnd = 9e9; l.Brightness = 2
            for _,v in pairs(l:GetChildren()) do if v:IsA("PostEffect") then v.Enabled=false end end
            workspace.Terrain.WaterWaveSize=0; workspace.Terrain.WaterWaveSpeed=0
            for _,v in pairs(workspace:GetDescendants()) do if v:IsA("BasePart") or v:IsA("MeshPart") then v.Material=Enum.Material.SmoothPlastic; v.CastShadow=false elseif v:IsA("Texture") or v:IsA("Decal") then v.Transparency=1 elseif v:IsA("ParticleEmitter") then v.Enabled=false end end
        end)
    else btn.Text = "Relogue!"; btn.TextColor3 = Color3.fromRGB(255, 150, 0) end
end)

-- Linha 6 (Y: 275)
local CleanBtn = CreateBtn("Anti-Lag", UDim2.new(0, 10, 0, 275), function(btn)
    task.spawn(function() btn.Text="Limpando..."; FullCleanup(); task.wait(0.5); btn.Text="Anti-Lag" end)
end)
local FarmBtn = CreateBtn("Baú TP: OFF", UDim2.new(1, -112, 0, 275), function(btn)
    FarmMode = not FarmMode
    if FarmMode then 
        btn.Text = "Baú TP: ON"; btn.TextColor3 = ColorGreen; btn.BackgroundColor3 = Color3.fromRGB(45, 55, 45)
        task.spawn(function()
            if #ChestCache == 0 then for _, v in pairs(workspace:GetDescendants()) do if v.Name == "Inside" and v:IsA("UnionOperation") then table.insert(ChestCache, v) end end end
            while FarmMode do
                if #ChestCache == 0 then task.wait(3); for _, v in pairs(workspace:GetDescendants()) do if v.Name == "Inside" and v:IsA("UnionOperation") then table.insert(ChestCache, v) end end; if #ChestCache == 0 then task.wait(2) end end
                for i = #ChestCache, 1, -1 do
                    if not FarmMode then break end
                    local v = ChestCache[i]
                    if v and v.Parent then
                        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                            local hrp = LocalPlayer.Character.HumanoidRootPart
                            if (hrp.Position - v.Position).Magnitude > 5 then hrp.CFrame = v.CFrame; task.wait(0.6) end
                        end
                    else table.remove(ChestCache, i) end
                end
                task.wait(0.2)
            end
        end)
    else 
        btn.Text = "Baú TP: OFF"; btn.TextColor3 = Color3.fromRGB(255, 100, 100); btn.BackgroundColor3 = ColorDarkGray; ChestCache = {}
    end
end)

local CreditsLabel = Instance.new("TextLabel", MainFrame)
CreditsLabel.BackgroundTransparency = 1; CreditsLabel.Position = UDim2.new(0, 0, 1, -15); CreditsLabel.Size = UDim2.new(1, 0, 0, 15)
CreditsLabel.Font = Enum.Font.Gotham; CreditsLabel.Text = "Tecla 'K' Minimiza"; CreditsLabel.TextColor3 = Color3.fromRGB(100, 100, 100); CreditsLabel.TextSize = 9

-- === FRAMES SECUNDÁRIOS (WL & TP) === --
local WL_Frame = Instance.new("Frame", ScreenGui); WL_Frame.Name="WL_Frame_Unique"; WL_Frame.Visible=false; WL_Frame.BackgroundColor3 = ColorBG
WL_Frame.Position = UDim2.new(0.5, 120, 0.5, -175); WL_Frame.Size = UDim2.new(0, 180, 0, 250); AddCorner(WL_Frame, 8); AddStroke(WL_Frame, 1.5)
local WL_Scroll = Instance.new("ScrollingFrame", WL_Frame); WL_Scroll.BackgroundTransparency=1; WL_Scroll.Position=UDim2.new(0,10,0,35); WL_Scroll.Size=UDim2.new(1,-20,1,-75); WL_Scroll.ScrollBarThickness=4
local WL_Layout = Instance.new("UIListLayout", WL_Scroll); WL_Layout.Padding=UDim.new(0,4)

local function UpdateWhitelistUI()
    for _,c in pairs(WL_Scroll:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local b = Instance.new("TextButton", WL_Scroll); b.Size = UDim2.new(1, 0, 0, 25); b.Font = Enum.Font.GothamSemibold; b.Text = "  " .. p.DisplayName; b.TextSize = 11; b.TextXAlignment = Enum.TextXAlignment.Left; AddCorner(b, 4)
            if Whitelist[p.Name] then b.BackgroundColor3 = Color3.fromRGB(40, 120, 60); b.TextColor3 = Color3.new(1,1,1) else b.BackgroundColor3 = ColorDarkGray; b.TextColor3 = Color3.fromRGB(200,200,200) end
            table.insert(_G.SkyL_Connections, b.MouseButton1Click:Connect(function() if Whitelist[p.Name] then Whitelist[p.Name]=nil else Whitelist[p.Name]=true end; UpdateWhitelistUI() end))
        end
    end
    WL_Scroll.CanvasSize = UDim2.new(0,0,0, WL_Layout.AbsoluteContentSize.Y)
end
-- Configura o botão WL para chamar a função de update corretamente
WL_Btn.MouseButton1Click:Connect(function() UpdateWhitelistUI() end)

local WL_Title = Instance.new("TextLabel", WL_Frame); WL_Title.BackgroundTransparency=1; WL_Title.Position=UDim2.new(0,10,0,5); WL_Title.Size=UDim2.new(0,100,0,25); WL_Title.Text="Whitelist"; WL_Title.Font=Enum.Font.GothamBold; WL_Title.TextColor3=Color3.new(1,1,1); WL_Title.TextSize=14; WL_Title.TextXAlignment=Enum.TextXAlignment.Left
local InvertBtn = Instance.new("TextButton", WL_Frame); InvertBtn.Text = "Inverter"; InvertBtn.Size = UDim2.new(1,-20,0,25); InvertBtn.Position = UDim2.new(0,10,1,-35); InvertBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80); InvertBtn.TextColor3 = Color3.fromRGB(255, 220, 150); InvertBtn.Font = Enum.Font.GothamBold; InvertBtn.TextSize = 11; AddCorner(InvertBtn, 6)
table.insert(_G.SkyL_Connections, InvertBtn.MouseButton1Click:Connect(function() for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then if Whitelist[p.Name] then Whitelist[p.Name]=nil else Whitelist[p.Name]=true end end end; UpdateWhitelistUI() end))

local TP_Frame = Instance.new("Frame", ScreenGui); TP_Frame.Name="TeleportFrame"; TP_Frame.Visible=false; TP_Frame.BackgroundColor3 = ColorBG
TP_Frame.Position = UDim2.new(0.5, 120, 0.5, -175); TP_Frame.Size = UDim2.new(0, 150, 0, 200); AddCorner(TP_Frame, 8); AddStroke(TP_Frame, 1.5)
local TP_Title = Instance.new("TextLabel", TP_Frame); TP_Title.BackgroundTransparency=1; TP_Title.Position=UDim2.new(0,10,0,5); TP_Title.Size=UDim2.new(0,100,0,25); TP_Title.Text="Artefatos"; TP_Title.Font=Enum.Font.GothamBold; TP_Title.TextColor3=Color3.new(1,1,1); TP_Title.TextSize=14; TP_Title.TextXAlignment=Enum.TextXAlignment.Left
local TP_CloseBtn = Instance.new("TextButton", TP_Frame); TP_CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50); TP_CloseBtn.Position = UDim2.new(1, -25, 0, 5); TP_CloseBtn.Size = UDim2.new(0, 18, 0, 18); TP_CloseBtn.Font = Enum.Font.GothamBold; TP_CloseBtn.Text = "X"; TP_CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255); TP_CloseBtn.TextSize = 11; AddCorner(TP_CloseBtn, 4)
table.insert(_G.SkyL_Connections, TP_CloseBtn.MouseButton1Click:Connect(function() IsTpMenuOpen=false; TP_Frame.Visible=false end))

local function TeleportTo(cf) if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then LocalPlayer.Character.HumanoidRootPart.CFrame = cf end end
local function CreateTP(txt, pos, cf)
    local b = Instance.new("TextButton", TP_Frame); b.Text=txt; b.Size=UDim2.new(1,-20,0,28); b.Font=Enum.Font.GothamBold; b.TextSize=11; b.BackgroundColor3=ColorDarkGray; b.TextColor3=Color3.fromRGB(200,200,255); AddCorner(b,6); AddStroke(b, 1); b.Position=UDim2.new(0,10,0,pos)
    table.insert(_G.SkyL_Connections, b.MouseButton1Click:Connect(function() TeleportTo(cf) end))
end
CreateTP("Wundagore", 40, Locations.Wundagore); CreateTP("Sanctum", 75, Locations.Sanctum); CreateTP("Caverna", 110, Locations.Caverna); CreateTP("Hospital", 145, Locations.Hospital)

-- Tooltip
local Tooltip = Instance.new("TextLabel", ScreenGui); Tooltip.BackgroundColor3=Color3.fromRGB(10,10,10); Tooltip.BackgroundTransparency=0.2; Tooltip.Size=UDim2.new(0,160,0,30); Tooltip.Font=Enum.Font.GothamBlack; Tooltip.TextColor3=Color3.fromRGB(255,255,255); Tooltip.TextSize=12; Tooltip.Visible=false; AddCorner(Tooltip,6)

-- Drag Logic
local function MakeDraggable(frame)
    local dragging, dragInput, dragStart, startPos
    local function update(input) local delta = input.Position - dragStart; frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end
    table.insert(_G.SkyL_Connections, frame.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true; dragStart = input.Position; startPos = frame.Position; input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end) end end))
    table.insert(_G.SkyL_Connections, frame.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end end))
    table.insert(_G.SkyL_Connections, UserInputService.InputChanged:Connect(function(input) if input == dragInput and dragging then update(input) end end))
end
MakeDraggable(TP_Frame)

local dragging, dragInput, dragStart, startPos
local function updateMain(input)
    local delta = input.Position - dragStart
    MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    WL_Frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X + 235, startPos.Y.Scale, startPos.Y.Offset + delta.Y) -- WL segue o main
end
table.insert(_G.SkyL_Connections, MainFrame.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true; dragStart = input.Position; startPos = MainFrame.Position; input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end) end end))
table.insert(_G.SkyL_Connections, MainFrame.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end end))
table.insert(_G.SkyL_Connections, UserInputService.InputChanged:Connect(function(input) if input == dragInput and dragging then updateMain(input) end end))

local function ToggleMenu(state)
    if state == nil then IsMenuOpen = not IsMenuOpen else IsMenuOpen = state end
    MainFrame.Visible = IsMenuOpen; OpenBtn.Visible = not IsMenuOpen
    if not IsMenuOpen then WL_Frame.Visible=false; FullCleanup() end
end
table.insert(_G.SkyL_Connections, CloseButton.MouseButton1Click:Connect(function() ToggleMenu(false) end))
table.insert(_G.SkyL_Connections, OpenBtn.MouseButton1Click:Connect(function() ToggleMenu(true) end))
table.insert(_G.SkyL_Connections, UserInputService.InputBegan:Connect(function(io, gp) if io.KeyCode == Enum.KeyCode.K and not gp then ToggleMenu() end end))

-- Logic
local function GetLocalAttachment()
    if not LocalPlayer.Character then return nil end
    local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    local att = root:FindFirstChild("MyEspAtt"); if not att then att = Instance.new("Attachment", root); att.Name = "MyEspAtt" end
    return att
end

local function getClosestPlayerToMouse()
    local closest, shortest = nil, FOV_Radius; local mouse = UserInputService:GetMouseLocation()
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= LocalPlayer and v.Character and not Whitelist[v.Name] then
            if not TeamCheckMode or v.Team ~= LocalPlayer.Team then
                local hrp = v.Character:FindFirstChild("HumanoidRootPart")
                local hum = v.Character:FindFirstChild("Humanoid")
                if hrp and hum and hum.Health > 0 then
                    local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                    if onScreen then
                        local dist = (Vector2.new(pos.X, pos.Y) - mouse).Magnitude
                        if dist < shortest then shortest = dist; closest = v end
                    end
                end
            end
        end
    end
    return closest
end

table.insert(_G.SkyL_Connections, UserInputService.InputBegan:Connect(function(io, gp)
    if io.KeyCode == Enum.KeyCode.V and not UserInputService:GetFocusedTextBox() then
        if SpectateTarget then
            SpectateTarget = nil; if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then Camera.CameraSubject = LocalPlayer.Character.Humanoid end
            SpecBtn.Text = "Watch [V]: OFF"; SpecBtn.TextColor3 = Color3.fromRGB(255, 100, 100); SpecBtn.BackgroundColor3 = ColorDarkGray
        else
            local t = getClosestPlayerToMouse()
            if t and t.Character and t.Character:FindFirstChild("Humanoid") then
                SpectateTarget = t; Camera.CameraSubject = t.Character.Humanoid
                SpecBtn.Text = "Watch: " .. t.Name; SpecBtn.TextColor3 = Color3.fromRGB(100, 255, 100); SpecBtn.BackgroundColor3 = Color3.fromRGB(55, 65, 55)
            end
        end
    end
end))

table.insert(_G.SkyL_Connections, UserInputService.InputBegan:Connect(function(io, gp)
    if io.UserInputType == Enum.UserInputType.MouseButton1 and TeleportMode and not gp then
        local now = tick(); if (now - LastTPClick) < TP_Cooldown then return end; LastTPClick = now
        local mouse = UserInputService:GetMouseLocation(); local closest, maxDst = nil, 60
        local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not myRoot then return end
        for _, v in pairs(Players:GetPlayers()) do
            if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("Head") and v.Character:FindFirstChild("HumanoidRootPart") then
                local sPos, vis = Camera:WorldToViewportPoint(v.Character.Head.Position)
                if vis then
                    local d = (Vector2.new(sPos.X, sPos.Y) - mouse).Magnitude
                    if d < maxDst then maxDst = d; closest = v end
                end
            end
        end
        if closest and closest.Character and closest.Character:FindFirstChild("HumanoidRootPart") then
            myRoot.CFrame = closest.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
        end
    end
end))

local function ManageESP(v, col, line, name)
    if not v.Character then return end
    local hrp = v.Character:FindFirstChild("HumanoidRootPart"); local head = v.Character:FindFirstChild("Head"); local hum = v.Character:FindFirstChild("Humanoid")
    if not hrp or not head then return end
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        if (hrp.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude > MaxRenderDistance then ClearVisuals(v); return end
    end
    if line then
        local myAtt = GetLocalAttachment(); local beam = hrp:FindFirstChild("ArtifactBeam")
        if not beam then local att = Instance.new("Attachment", hrp); att.Name="EspAttTarget"; beam = Instance.new("Beam", hrp); beam.Name="ArtifactBeam"; beam.Attachment1=att; beam.FaceCamera=true; beam.Width0=0.1; beam.Width1=0.1 end
        if beam and myAtt then beam.Attachment0=myAtt; beam.Color=ColorSequence.new(col); beam.Enabled=true end
    else if hrp:FindFirstChild("ArtifactBeam") then hrp.ArtifactBeam:Destroy() end end
    if name then
        local tag = head:FindFirstChild("ArtifactNameTag")
        if not tag then tag = Instance.new("BillboardGui", head); tag.Name="ArtifactNameTag"; tag.AlwaysOnTop=true; tag.Size=UDim2.new(0,200,0,50); tag.StudsOffset=Vector3.new(0,3,0); local t = Instance.new("TextLabel", tag); t.Name="L"; t.Size=UDim2.new(1,0,1,0); t.BackgroundTransparency=1; t.Font=Enum.Font.Nunito; t.TextSize=16; t.TextStrokeTransparency=0; t.TextStrokeColor3=Color3.new(0,0,0) end
        local l = tag:FindFirstChild("L")
        if l then
            local hp = hum and math.floor(hum.Health) or 0; local max = hum and math.floor(hum.MaxHealth) or 100
            local t = v.DisplayName .. " [" .. hp .. "/" .. max .. "]"; if l.Text ~= t then l.Text = t end; l.TextColor3 = col
        end
    else if head:FindFirstChild("ArtifactNameTag") then head.ArtifactNameTag:Destroy() end end
end

local function UpdateTooltip(target)
    if not target or not target.Character then Tooltip.Visible=false; return end
    local char = target.Character
    local isDark = CollectionService:HasTag(char, "DarkholdOwner"); local isArt = not isDark and CollectionService:HasTag(char, "HasArtifact")
    if isDark then Tooltip.Text="POSSUI DARKHOLD"; Tooltip.TextColor3=ColorRed; Tooltip.Visible=true
    elseif isArt then Tooltip.Text="POSSUI JOIA"; Tooltip.TextColor3=ColorYellow; Tooltip.Visible=true
    else Tooltip.Visible=false; return end
    local m = UserInputService:GetMouseLocation(); Tooltip.Position = UDim2.new(0, m.X+20, 0, m.Y+20)
end

table.insert(_G.SkyL_Connections, RunService.RenderStepped:Connect(function()
    local now = tick()
    if (now - LastGCCycle) > GC_Interval then LastGCCycle = now; if not HitboxMode and not EspMode then FullCleanup() end end
    if not HitboxMode and not EspMode and not PlayerEspMode and not LockMode and not SpectateTarget then Tooltip.Visible=false; return end
    if not LocalPlayer.Character then return end
    
    local target = nil
    if SpectateTarget or LockMode or HitboxMode or (now % 0.2 < 0.05) then target = getClosestPlayerToMouse() end
    local finalTarget = target
    if LockMode then if target then SavedTarget = target end; if SavedTarget and SavedTarget.Character and SavedTarget.Character:FindFirstChild("Humanoid") and SavedTarget.Character.Humanoid.Health > 0 then finalTarget = SavedTarget else SavedTarget = nil end end
    
    if SpectateTarget then
        if SpectateTarget.Character and SpectateTarget.Character:FindFirstChild("Humanoid") then Camera.CameraSubject = SpectateTarget.Character.Humanoid
        else SpectateTarget = nil; Camera.CameraSubject = LocalPlayer.Character.Humanoid; SpecBtn.Text="Spec [V]: OFF" end
    end
    UpdateTooltip(finalTarget)

    local shouldUpdateEsp = (now - LastEspUpdate) > EspUpdateRate
    if shouldUpdateEsp then LastEspUpdate = now end

    for _, v in pairs(Players:GetPlayers()) do
        if v ~= LocalPlayer and v.Character then
            local hrp = v.Character:FindFirstChild("HumanoidRootPart")
            if hrp and HitboxMode then
                local isTeam = (v.Team == LocalPlayer.Team); local isWL = Whitelist[v.Name]; local shouldIgnore = (TeamCheckMode and isTeam) or isWL
                if not shouldIgnore and v == finalTarget then
                    if hrp.Size ~= CachedSize then hrp.Size=CachedSize; hrp.Transparency=CachedTransparency; hrp.Color=CachedColor; hrp.Material=Enum.Material.Neon; hrp.CanCollide=false end
                else
                    if hrp.Size ~= DefaultSize then hrp.Size=DefaultSize; hrp.Transparency=1; hrp.Material=Enum.Material.Plastic; hrp.CanCollide=false end
                end
            end
            if shouldUpdateEsp then
                if EspMode or PlayerEspMode then
                    local isDark = CollectionService:HasTag(v.Character, "DarkholdOwner"); local isArt = not isDark and CollectionService:HasTag(v.Character, "HasArtifact")
                    local col, line, name = ColorWhite, false, false
                    if EspMode then if isDark then col=ColorRed; line=true; name=true elseif isArt then col=ColorYellow; line=true; name=true end end
                    if PlayerEspMode and not line then name=true; col=ColorWhite end
                    if line or name then ManageESP(v, col, line, name) else ClearVisuals(v) end
                end
            end
        end
    end
end))
