local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- // COORDENADAS (LOCAIS) // --
local Locations = {
    Sanctum = CFrame.new(2379.8015, 686.3657, 659.2962),
    Caverna = CFrame.new(-351.8613, 697.4421, 1903.7971),
    Wundagore = CFrame.new(-2818.6208, 1050.8438, 649.0917),
    Hospital = CFrame.new(376.6887, 649.5777, 1422.3016)
}

-- // LIMPEZA // --
if _G.SkyL_Connection then _G.SkyL_Connection:Disconnect() end
if CoreGui:FindFirstChild("SkyL_Hitbox_Tactical_CameraFix") then CoreGui.SkyL_Hitbox_Tactical_CameraFix:Destroy() end

-- // VARIÁVEIS // --
local HitboxMode = false 
local LockMode = false 
local TeamCheckMode = false 
local EspMode = false       
local PlayerEspMode = false 
local TeleportMode = false 
local SavedTarget = nil 
local IsMenuOpen = true
local IsWhitelistOpen = false
local IsTpMenuOpen = false 
local FOV_Radius = 150 
local MyEspAtt_Cache = nil 
local LastClickTime = 0 

local Whitelist = {} 

-- Cache Visual
local CachedSize = Vector3.new(10, 10, 10)
local CachedColor = Color3.new(0.5, 0.5, 0.5)
local CachedTransparency = 0.5 
local DefaultSize = Vector3.new(2, 2, 1)

local ColorRed = Color3.fromRGB(255, 30, 30)
local ColorYellow = Color3.fromRGB(255, 255, 0)
local ColorWhite = Color3.new(1, 1, 1)

-- // UI SETUP // --
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SkyL_Hitbox_Tactical_CameraFix"
ScreenGui.Parent = CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true 

local EspContainer = Instance.new("Folder")
EspContainer.Name = "EspContainer"
EspContainer.Parent = ScreenGui

local function AddCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = parent
    return corner
end

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
MainFrame.Position = UDim2.new(0.5, -125, 0.5, -100)
MainFrame.Size = UDim2.new(0, 260, 0, 340)
MainFrame.Visible = true
AddCorner(MainFrame, 10)

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(60, 60, 65)
UIStroke.Thickness = 1
UIStroke.Parent = MainFrame

-- Header
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Parent = MainFrame
TitleLabel.BackgroundTransparency = 1
TitleLabel.Position = UDim2.new(0, 15, 0, 10)
TitleLabel.Size = UDim2.new(0, 200, 0, 30)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Text = "Hitbox V4 (Marvel Omega)"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 16
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

local CloseButton = Instance.new("TextButton")
CloseButton.Parent = MainFrame
CloseButton.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
CloseButton.Position = UDim2.new(1, -35, 0, 10)
CloseButton.Size = UDim2.new(0, 25, 0, 25)
CloseButton.Font = Enum.Font.GothamBold
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.TextSize = 14
AddCorner(CloseButton, 6)

local OpenButton = Instance.new("TextButton")
OpenButton.Parent = ScreenGui
OpenButton.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
OpenButton.Position = UDim2.new(0.01, 0, 0.5, 0)
OpenButton.Size = UDim2.new(0, 50, 0, 50)
OpenButton.Font = Enum.Font.GothamBold
OpenButton.Text = "H"
OpenButton.TextColor3 = Color3.fromRGB(255, 255, 255)
OpenButton.TextSize = 24
OpenButton.Visible = false
AddCorner(OpenButton, 50)

local CreditsLabel = Instance.new("TextLabel")
CreditsLabel.Parent = MainFrame
CreditsLabel.BackgroundTransparency = 1
CreditsLabel.Position = UDim2.new(0, 0, 1, -20)
CreditsLabel.Size = UDim2.new(1, 0, 0, 15)
CreditsLabel.Font = Enum.Font.Gotham
CreditsLabel.Text = "Tecla 'K' para Esconder ou Dois cliques na tela"
CreditsLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
CreditsLabel.TextSize = 10

-- === INPUTS === --
local function CreateInput(parent, ph, txt, pos, size)
    local box = Instance.new("TextBox")
    box.Parent = parent
    box.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    box.Position = pos
    box.Size = size
    box.Font = Enum.Font.Gotham
    box.PlaceholderText = ph
    box.Text = txt
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.TextSize = 14
    AddCorner(box, 8)
    return box
end

local HitboxInput = CreateInput(MainFrame, "Tam.", "10", UDim2.new(0, 10, 0, 50), UDim2.new(0, 115, 0, 35))
local TransInput = CreateInput(MainFrame, "Transp.", "0.5", UDim2.new(1, -125, 0, 50), UDim2.new(0, 115, 0, 35))

local LabelCor = Instance.new("TextLabel")
LabelCor.Parent = MainFrame
LabelCor.BackgroundTransparency = 1
LabelCor.Position = UDim2.new(0, 10, 0, 90)
LabelCor.Text = "Cores (RGB):"
LabelCor.TextColor3 = Color3.fromRGB(200, 200, 200)
LabelCor.Font = Enum.Font.GothamBold
LabelCor.TextSize = 14
LabelCor.TextXAlignment = Enum.TextXAlignment.Left

local R_Input = CreateInput(MainFrame, "R", "0.5", UDim2.new(0, 10, 0, 110), UDim2.new(0, 75, 0, 30))
local G_Input = CreateInput(MainFrame, "G", "0.5", UDim2.new(0.5, -37, 0, 110), UDim2.new(0, 75, 0, 30))
local B_Input = CreateInput(MainFrame, "B", "0.5", UDim2.new(1, -85, 0, 110), UDim2.new(0, 75, 0, 30))

R_Input.TextColor3 = Color3.fromRGB(255, 100, 100)
G_Input.TextColor3 = Color3.fromRGB(100, 255, 100)
B_Input.TextColor3 = Color3.fromRGB(100, 100, 255)

local function UpdateCache()
    local s = tonumber(HitboxInput.Text) or 35
    CachedSize = Vector3.new(s, s, s)
    local t = tonumber(TransInput.Text) or 0.8
    if t > 1 then t = 1 end if t < 0 then t = 0 end
    CachedTransparency = t
    local r = tonumber(R_Input.Text) or 0.5
    local g = tonumber(G_Input.Text) or 0.5
    local b = tonumber(B_Input.Text) or 0.5
    CachedColor = Color3.new(r, g, b)
end

HitboxInput.FocusLost:Connect(UpdateCache)
TransInput.FocusLost:Connect(UpdateCache) 
R_Input.FocusLost:Connect(UpdateCache)
G_Input.FocusLost:Connect(UpdateCache)
B_Input.FocusLost:Connect(UpdateCache)

-- === BOTÕES === --
local function CreateBtn(text, pos, callback, parent)
    local p = parent or MainFrame
    local btn = Instance.new("TextButton")
    btn.Parent = p
    btn.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    btn.Position = pos
    btn.Size = UDim2.new(0, 115, 0, 35)
    btn.Font = Enum.Font.GothamBold
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 100, 100)
    btn.TextSize = 12
    AddCorner(btn, 8)
    btn.MouseButton1Click:Connect(function() callback(btn) end)
    return btn
end

CreateBtn("Hitbox: OFF", UDim2.new(0, 10, 0, 155), function(btn)
    HitboxMode = not HitboxMode
    if HitboxMode then
        btn.Text = "Hitbox: ON"; btn.TextColor3 = Color3.fromRGB(100, 255, 100); btn.BackgroundColor3 = Color3.fromRGB(55, 65, 55)
    else
        btn.Text = "Hitbox: OFF"; btn.TextColor3 = Color3.fromRGB(255, 100, 100); btn.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    end
end)

CreateBtn("Lock: OFF", UDim2.new(1, -125, 0, 155), function(btn)
    LockMode = not LockMode
    if LockMode then
        btn.Text = "Lock: ON"; btn.TextColor3 = Color3.fromRGB(100, 255, 100); btn.BackgroundColor3 = Color3.fromRGB(55, 65, 55)
    else
        btn.Text = "Lock: OFF"; btn.TextColor3 = Color3.fromRGB(255, 100, 100); btn.BackgroundColor3 = Color3.fromRGB(45, 45, 50); SavedTarget = nil
    end
end)

CreateBtn("Team Check: OFF", UDim2.new(0, 10, 0, 195), function(btn)
    TeamCheckMode = not TeamCheckMode
    if TeamCheckMode then
        btn.Text = "Team Check: ON"; btn.TextColor3 = Color3.fromRGB(100, 255, 100); btn.BackgroundColor3 = Color3.fromRGB(55, 65, 55)
    else
        btn.Text = "Team Check: OFF"; btn.TextColor3 = Color3.fromRGB(255, 100, 100); btn.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    end
end)

-- === WHITE LIST FRAME & LÓGICA === --
local WL_Frame = Instance.new("Frame")
WL_Frame.Name = "WhitelistFrame"
WL_Frame.Parent = ScreenGui
WL_Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
WL_Frame.Position = UDim2.new(0.5, 150, 0.5, -100)
WL_Frame.Size = UDim2.new(0, 180, 0, 260)
WL_Frame.Visible = false
AddCorner(WL_Frame, 10)

local WL_Title = Instance.new("TextLabel", WL_Frame)
WL_Title.BackgroundTransparency = 1; WL_Title.Size = UDim2.new(1,0,0,30); WL_Title.Text = "Jogadores"; WL_Title.Font = Enum.Font.GothamBold; WL_Title.TextColor3 = Color3.new(1,1,1); WL_Title.TextSize = 14

local WL_Scroll = Instance.new("ScrollingFrame", WL_Frame)
WL_Scroll.Name = "Scroll"; WL_Scroll.BackgroundTransparency = 1; WL_Scroll.Position = UDim2.new(0,5,0,35)
WL_Scroll.Size = UDim2.new(1,-10,1,-75) 
WL_Scroll.ScrollBarThickness = 4
local WL_Layout = Instance.new("UIListLayout", WL_Scroll); WL_Layout.Padding = UDim.new(0,5); WL_Layout.SortOrder = Enum.SortOrder.Name

local function UpdateWhitelistUI()
    local scroll = WL_Frame:FindFirstChild("Scroll")
    if not scroll then return end
    for _,c in pairs(scroll:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
    local layout = scroll:FindFirstChild("UIListLayout")
    
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local b = Instance.new("TextButton", scroll)
            b.Size = UDim2.new(1,0,0,30); b.Font = Enum.Font.Gotham; b.Text = p.Name; b.TextSize = 12
            AddCorner(b,6)
            if Whitelist[p.Name] then b.BackgroundColor3 = Color3.fromRGB(50,150,50); b.TextColor3 = Color3.new(1,1,1)
            else b.BackgroundColor3 = Color3.fromRGB(60,60,65); b.TextColor3 = Color3.new(0.8,0.8,0.8) end
            b.MouseButton1Click:Connect(function()
                if Whitelist[p.Name] then Whitelist[p.Name] = nil else Whitelist[p.Name] = true end
                UpdateWhitelistUI() 
            end)
        end
    end
    scroll.CanvasSize = UDim2.new(0,0,0, layout.AbsoluteContentSize.Y)
end

local InvertBtn = CreateBtn("Inverter Seleção", UDim2.new(0, 5, 1, -35), function()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            if Whitelist[p.Name] then Whitelist[p.Name] = nil else Whitelist[p.Name] = true end
        end
    end
    UpdateWhitelistUI() 
end, WL_Frame)
InvertBtn.Size = UDim2.new(1, -10, 0, 30)
InvertBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
InvertBtn.TextColor3 = Color3.fromRGB(255, 200, 100)

local WL_Btn = CreateBtn("White List >", UDim2.new(1, -125, 0, 195), function(btn)
    IsWhitelistOpen = not IsWhitelistOpen
    IsTpMenuOpen = false 
    local tpFrame = ScreenGui:FindFirstChild("TeleportFrame")
    if tpFrame then tpFrame.Visible = false end
    
    WL_Frame.Visible = IsWhitelistOpen
    if IsWhitelistOpen then UpdateWhitelistUI() end
end)
WL_Btn.TextColor3 = Color3.fromRGB(200, 200, 255); WL_Btn.BackgroundColor3 = Color3.fromRGB(60, 60, 75)

CreateBtn("ESP Art: OFF", UDim2.new(0, 10, 0, 235), function(btn)
    EspMode = not EspMode
    if EspMode then
        btn.Text = "ESP Art: ON"; btn.TextColor3 = Color3.fromRGB(100, 255, 100); btn.BackgroundColor3 = Color3.fromRGB(55, 65, 55)
    else
        btn.Text = "ESP Art: OFF"; btn.TextColor3 = Color3.fromRGB(255, 100, 100); btn.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    end
end)

CreateBtn("ESP Play: OFF", UDim2.new(1, -125, 0, 235), function(btn)
    PlayerEspMode = not PlayerEspMode
    if PlayerEspMode then
        btn.Text = "ESP Play: ON"; btn.TextColor3 = Color3.fromRGB(100, 255, 100); btn.BackgroundColor3 = Color3.fromRGB(55, 65, 55)
    else
        btn.Text = "ESP Play: OFF"; btn.TextColor3 = Color3.fromRGB(255, 100, 100); btn.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    end
end)

-- MENU DE TELEPORTE DE ARTEFATOS
local TP_Frame = Instance.new("Frame")
TP_Frame.Name = "TeleportFrame"
TP_Frame.Parent = ScreenGui
TP_Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
TP_Frame.Position = UDim2.new(0.5, 150, 0.5, -100)
TP_Frame.Size = UDim2.new(0, 180, 0, 200) 
TP_Frame.Visible = false
AddCorner(TP_Frame, 10)

local TP_Title = Instance.new("TextLabel", TP_Frame)
TP_Title.BackgroundTransparency = 1; TP_Title.Size = UDim2.new(1,0,0,30); TP_Title.Text = "Locais de Artefato"; TP_Title.Font = Enum.Font.GothamBold; TP_Title.TextColor3 = Color3.new(1,1,1); TP_Title.TextSize = 14

local function TeleportTo(cframe)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = cframe
    end
end

local btnWunda = CreateBtn("Wundagore", UDim2.new(0.5, -65, 0, 40), function() TeleportTo(Locations.Wundagore) end, TP_Frame)
btnWunda.Size = UDim2.new(0, 130, 0, 30)
local btnSanc = CreateBtn("Sanctum", UDim2.new(0.5, -65, 0, 80), function() TeleportTo(Locations.Sanctum) end, TP_Frame)
btnSanc.Size = UDim2.new(0, 130, 0, 30)
local btnCave = CreateBtn("Caverna", UDim2.new(0.5, -65, 0, 120), function() TeleportTo(Locations.Caverna) end, TP_Frame)
btnCave.Size = UDim2.new(0, 130, 0, 30)
local btnHosp = CreateBtn("Hospital", UDim2.new(0.5, -65, 0, 160), function() TeleportTo(Locations.Hospital) end, TP_Frame)
btnHosp.Size = UDim2.new(0, 130, 0, 30)

-- BOTÕES LADO A LADO
local TpBtn = CreateBtn("TP Click: OFF", UDim2.new(0, 10, 0, 275), function(btn) 
    TeleportMode = not TeleportMode
    if TeleportMode then
        btn.Text = "TP Click: ON"; btn.TextColor3 = Color3.fromRGB(100, 255, 100); btn.BackgroundColor3 = Color3.fromRGB(55, 65, 55)
    else
        btn.Text = "TP Click: OFF"; btn.TextColor3 = Color3.fromRGB(255, 100, 100); btn.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    end
end)
TpBtn.Size = UDim2.new(0, 115, 0, 35)

local ArtTP_Btn = CreateBtn("Art TP >", UDim2.new(1, -125, 0, 275), function(btn)
    IsTpMenuOpen = not IsTpMenuOpen
    TP_Frame.Visible = IsTpMenuOpen
    if IsTpMenuOpen then
        IsWhitelistOpen = false
        WL_Frame.Visible = false
    end
end)
ArtTP_Btn.Size = UDim2.new(0, 115, 0, 35)
ArtTP_Btn.TextColor3 = Color3.fromRGB(255, 200, 100)
ArtTP_Btn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)

-- Tooltip
local TooltipLabel = Instance.new("TextLabel", ScreenGui)
TooltipLabel.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
TooltipLabel.BackgroundTransparency = 0.2
TooltipLabel.Size = UDim2.new(0, 160, 0, 30)
TooltipLabel.Font = Enum.Font.GothamBlack
TooltipLabel.Text = ""
TooltipLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TooltipLabel.TextSize = 12
TooltipLabel.TextStrokeTransparency = 0
TooltipLabel.TextStrokeColor3 = Color3.new(0,0,0)
TooltipLabel.Visible = false
AddCorner(TooltipLabel, 6)

-- === LÓGICA UI (COM DUPLO CLIQUE) === --
local function ToggleMenu(state)
    if state == nil then IsMenuOpen = not IsMenuOpen else IsMenuOpen = state end
    MainFrame.Visible = IsMenuOpen
    OpenButton.Visible = not IsMenuOpen
    if not IsMenuOpen then 
        WL_Frame.Visible = false; IsWhitelistOpen = false
        TP_Frame.Visible = false; IsTpMenuOpen = false
    end
end

CloseButton.MouseButton1Click:Connect(function() ToggleMenu(false) end)
OpenButton.MouseButton1Click:Connect(function() ToggleMenu(true) end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if IsMenuOpen and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        local m = input.Position
        local f = MainFrame.AbsolutePosition; local s = MainFrame.AbsoluteSize
        local w = WL_Frame.AbsolutePosition; local ws = WL_Frame.AbsoluteSize
        local t = TP_Frame.AbsolutePosition; local ts = TP_Frame.AbsoluteSize
        
        local inM = m.X >= f.X and m.X <= f.X+s.X and m.Y >= f.Y and m.Y <= f.Y+s.Y
        local inW = m.X >= w.X and m.X <= w.X+ws.X and m.Y >= w.Y and m.Y <= w.Y+ws.Y
        local inT = m.X >= t.X and m.X <= t.X+ts.X and m.Y >= t.Y and m.Y <= t.Y+ts.Y
        
        local safe = inM or (IsWhitelistOpen and inW) or (IsTpMenuOpen and inT)
        
        if not safe then 
            local now = tick()
            if (now - LastClickTime) < 0.4 then
                ToggleMenu(false)
                LastClickTime = 0
            else
                LastClickTime = now
            end
        end
    end
    if input.KeyCode == Enum.KeyCode.K and not gameProcessed then ToggleMenu() end
end)

local dragging, dragInput, dragStart, startPos
local function update(input)
    local delta = input.Position - dragStart
    MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    WL_Frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X + 270, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    TP_Frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X + 270, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true; dragStart = input.Position; startPos = MainFrame.Position; input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end) end
end)
MainFrame.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end end)
UserInputService.InputChanged:Connect(function(input) if input == dragInput and dragging then update(input) end end)

-- Teleport Click (FUNCIONA SEMPRE)
UserInputService.InputBegan:Connect(function(input, processed)
    if input.UserInputType == Enum.UserInputType.MouseButton1 and TeleportMode and not processed then
        local mousePos = UserInputService:GetMouseLocation()
        local closest = nil
        local minDst = 60 

        for _, v in pairs(Players:GetPlayers()) do
            if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("Head") and v.Character:FindFirstChild("HumanoidRootPart") then
                local head = v.Character.Head
                local tagPos3D = head.Position
                local tagScreenPos, onScreen = Camera:WorldToViewportPoint(tagPos3D)
                
                if onScreen then
                    local dist = (Vector2.new(tagScreenPos.X, tagScreenPos.Y) - mousePos).Magnitude
                    if dist < minDst then 
                        minDst = dist
                        closest = v 
                    end
                end
            end
        end
        
        if closest and closest.Character and closest.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character then
            LocalPlayer.Character.HumanoidRootPart.CFrame = closest.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
        end
    end
end)

-- === FUNÇÕES === --

local function GetLocalAttachment()
    if MyEspAtt_Cache and MyEspAtt_Cache.Parent and LocalPlayer.Character and MyEspAtt_Cache.Parent == LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then 
        return MyEspAtt_Cache 
    end
    local char = LocalPlayer.Character
    if not char then return nil end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    local att = root:FindFirstChild("MyEspAtt")
    if not att then att = Instance.new("Attachment", root); att.Name = "MyEspAtt" end
    MyEspAtt_Cache = att
    return att
end

local function getClosestPlayerToMouse()
    local closest = nil; local shortest = FOV_Radius; local mouse = UserInputService:GetMouseLocation()
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

local function ManageESP(target, showLine, showName, color)
    if not target or not target.Character then return end
    local root = target.Character:FindFirstChild("HumanoidRootPart")
    local head = target.Character:FindFirstChild("Head")
    if not root or not head then return end
    
    local beam = root:FindFirstChild("ArtifactBeam")
    local tag = head:FindFirstChild("ArtifactNameTag")
    local c = color or ColorWhite

    if showLine then
        local myAtt = GetLocalAttachment()
        if not beam then
            local att1 = root:FindFirstChild("EspAttTarget") or Instance.new("Attachment", root); att1.Name = "EspAttTarget"
            beam = Instance.new("Beam", root); beam.Name = "ArtifactBeam"; beam.Attachment1 = att1; beam.FaceCamera = true; beam.Width0 = 0.1; beam.Width1 = 0.1
        end
        if beam then 
            if myAtt then beam.Attachment0 = myAtt end
            beam.Color = ColorSequence.new(c) 
            if not beam.Enabled then beam.Enabled = true end
        end
    else
        if beam then beam.Enabled = false end
    end

    if showName then
        if not tag or tag.Adornee ~= head then
            if tag then tag:Destroy() end
            tag = Instance.new("BillboardGui", head); tag.Name = "ArtifactNameTag"; tag.AlwaysOnTop = true; tag.Size = UDim2.new(0,200,0,50); tag.StudsOffset = Vector3.new(0,3,0)
            tag.Active = false 
            local t = Instance.new("TextLabel", tag); t.Name="L"; t.Size=UDim2.new(1,0,1,0); t.BackgroundTransparency=1
            t.Text = target.Name
            t.Font = Enum.Font.Nunito
            t.TextSize = 16
            t.TextStrokeTransparency = 0
            t.TextStrokeColor3 = Color3.new(0,0,0)
        end
        if tag then 
            if not tag.Enabled then tag.Enabled = true end
            local txt = tag:FindFirstChild("L")
            if txt then txt.TextColor3 = c end
        end
    else
        if tag then tag.Enabled = false end
    end
end

local function UpdateTooltip(target)
    if not target or not target.Character then
        if TooltipLabel.Visible then TooltipLabel.Visible = false end
        return
    end
    local char = target.Character
    local hasDark = CollectionService:HasTag(char, "DarkholdOwner")
    local hasArt = CollectionService:HasTag(char, "HasArtifact")

    if hasDark then
        TooltipLabel.Text = "📕 POSSUI DARKHOLD"
        TooltipLabel.TextColor3 = ColorRed
        if not TooltipLabel.Visible then TooltipLabel.Visible = true end
        local m = UserInputService:GetMouseLocation()
        TooltipLabel.Position = UDim2.new(0, m.X + 20, 0, m.Y + 20)
        return
    end
    if hasArt then
        TooltipLabel.Text = "💎 POSSUI JOIA"
        TooltipLabel.TextColor3 = ColorYellow
        if not TooltipLabel.Visible then TooltipLabel.Visible = true end
        local m = UserInputService:GetMouseLocation()
        TooltipLabel.Position = UDim2.new(0, m.X + 20, 0, m.Y + 20)
        return
    end
    if TooltipLabel.Visible then TooltipLabel.Visible = false end
end

_G.SkyL_Connection = RunService.RenderStepped:Connect(function()
    local mouseTarget = getClosestPlayerToMouse()
    local finalTarget = mouseTarget
    
    if LockMode then
        if mouseTarget then SavedTarget = mouseTarget end
        if SavedTarget and SavedTarget.Parent and SavedTarget.Character and SavedTarget.Character:FindFirstChild("Humanoid") and SavedTarget.Character.Humanoid.Health > 0 then 
            finalTarget = SavedTarget 
        else 
            SavedTarget = nil 
        end
    end

    UpdateTooltip(finalTarget)

    for _, v in pairs(Players:GetPlayers()) do
        if v ~= LocalPlayer and v.Character then
            local hrp = v.Character:FindFirstChild("HumanoidRootPart")
            
            if hrp and HitboxMode then
                local isTeam = (v.Team == LocalPlayer.Team); local isWL = Whitelist[v.Name]
                local shouldIgnore = (TeamCheckMode and isTeam) or isWL
                
                if not shouldIgnore and v == finalTarget then
                    if hrp.Size ~= CachedSize then
                        hrp.Size = CachedSize; hrp.Transparency = CachedTransparency; hrp.Color = CachedColor; hrp.Material = Enum.Material.Neon; hrp.CanCollide = false
                    end
                else
                    if hrp.Size ~= DefaultSize then
                        hrp.Size = DefaultSize; hrp.Transparency = 1; hrp.Material = Enum.Material.Plastic; hrp.CanCollide = false
                    end
                end
            end

            local isDarkhold = CollectionService:HasTag(v.Character, "DarkholdOwner")
            local isArtifact = CollectionService:HasTag(v.Character, "HasArtifact")
            
            local showLine = false
            local showName = false
            local finalColor = ColorWhite

            if EspMode and (isDarkhold or isArtifact) then
                showLine = true
                showName = true
                if isDarkhold then finalColor = ColorRed else finalColor = ColorYellow end
            elseif PlayerEspMode then
                showLine = false 
                showName = true
                finalColor = ColorWhite
            end

            ManageESP(v, showLine, showName, finalColor)
        end
    end
end)
