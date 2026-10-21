--[[
    Mini Stretch — отдельный скрипт для Sniper Arena
    Очень маленькое ГУИ (150x42) с ползунком силы растяга экрана.
    Заголовок «РАСТЯГ» — клик вкл/выкл. Крестик — выгрузка.
]]

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

-- =============================================================================
-- STATE
-- =============================================================================
local state = { enabled = true, power = 1.30 }
local MIN, MAX, STEP = 1, 2, 0.05

-- =============================================================================
-- SCREEN STRETCH
-- =============================================================================
local BIND = "MiniStretchBind"
local BIND_LATE = "MiniStretchLate"
local lastApplied = nil
local applying = false
local camHook = nil
local hookedCam = nil
local camChangedConn = nil

local function stretch(cam)
    local power = math.clamp(state.power, MIN, MAX)
    if power <= 1.001 then return end

    local cf = cam.CFrame
    local stretched = CFrame.fromMatrix(cf.Position, cf.XVector, cf.YVector / power, cf.ZVector)
    applying = true
    cam.CFrame = stretched
    applying = false
    lastApplied = stretched
end

local function apply()
    if not state.enabled then return end
    local cam = workspace.CurrentCamera
    if cam then stretch(cam) end
end

local function hookCamera()
    local cam = workspace.CurrentCamera
    if hookedCam == cam then return end

    if camHook then
        camHook:Disconnect()
        camHook = nil
    end

    hookedCam = cam
    if cam then
        -- обход для игр (Sniper Arena), которые перезаписывают Camera.CFrame каждый кадр
        camHook = cam:GetPropertyChangedSignal("CFrame"):Connect(function()
            if applying or not state.enabled then return end
            if not hookedCam or hookedCam ~= workspace.CurrentCamera then return end
            if lastApplied and hookedCam.CFrame == lastApplied then return end
            stretch(hookedCam)
        end)
    end
end

hookCamera()
camChangedConn = workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(hookCamera)

pcall(function()
    RunService:UnbindFromRenderStep(BIND)
    RunService:UnbindFromRenderStep(BIND_LATE)
end)

local bound = pcall(function()
    RunService:BindToRenderStep(BIND, Enum.RenderPriority.Camera.Value + 1, apply)
end)

if not bound then
    RunService.RenderStepped:Connect(apply)
end

pcall(function()
    RunService:BindToRenderStep(BIND_LATE, Enum.RenderPriority.Last.Value, function()
        if not state.enabled then return end
        local cam = workspace.CurrentCamera
        if not cam then return end
        if lastApplied and cam.CFrame == lastApplied then return end
        stretch(cam)
    end)
end)

-- =============================================================================
-- GUI (tiny)
-- =============================================================================
local function getParent()
    local ok, hui = pcall(function() return gethui and gethui() end)
    if ok and hui then return hui end

    local ok2, core = pcall(function() return game:GetService("CoreGui") end)
    if ok2 and core then return core end

    return Players.LocalPlayer:WaitForChild("PlayerGui")
end

local old = getParent():FindFirstChild("MiniStretchGui")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "MiniStretchGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = getParent()

local frame = Instance.new("Frame")
frame.Name = "Window"
frame.Size = UDim2.new(0, 150, 0, 42)
frame.Position = UDim2.new(0, 20, 0, 80)
frame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
frame.BorderSizePixel = 0
frame.Active = true
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 6)
corner.Parent = frame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(0, 255, 140)
stroke.Transparency = 0.4
stroke.Thickness = 1
stroke.Parent = frame

-- header
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 16)
header.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
header.BorderSizePixel = 0
header.Parent = frame

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 6)
headerCorner.Parent = header

local title = Instance.new("TextButton")
title.Size = UDim2.new(1, -56, 1, 0)
title.Position = UDim2.new(0, 6, 0, 0)
title.BackgroundTransparency = 1
title.Text = "РАСТЯГ"
title.Font = Enum.Font.GothamBold
title.TextSize = 9
title.TextColor3 = Color3.fromRGB(0, 255, 140)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local valueLabel = Instance.new("TextLabel")
valueLabel.Size = UDim2.new(0, 38, 1, 0)
valueLabel.Position = UDim2.new(1, -50, 0, 0)
valueLabel.BackgroundTransparency = 1
valueLabel.Text = "1.30x"
valueLabel.Font = Enum.Font.GothamBold
valueLabel.TextSize = 9
valueLabel.TextColor3 = Color3.fromRGB(0, 255, 140)
valueLabel.TextXAlignment = Enum.TextXAlignment.Right
valueLabel.Parent = header

local close = Instance.new("TextButton")
close.Size = UDim2.new(0, 12, 0, 12)
close.Position = UDim2.new(1, -14, 0, 2)
close.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
close.BorderSizePixel = 0
close.Text = "X"
close.Font = Enum.Font.GothamBold
close.TextSize = 8
close.TextColor3 = Color3.fromRGB(255, 90, 90)
close.Parent = header

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 4)
closeCorner.Parent = close

-- slider
local track = Instance.new("Frame")
track.Size = UDim2.new(1, -12, 0, 6)
track.Position = UDim2.new(0, 6, 0, 26)
track.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
track.BorderSizePixel = 0
track.Parent = frame

local trackCorner = Instance.new("UICorner")
trackCorner.CornerRadius = UDim.new(1, 0)
trackCorner.Parent = track

local fill = Instance.new("Frame")
fill.Size = UDim2.new(0.3, 0, 1, 0)
fill.BackgroundColor3 = Color3.fromRGB(0, 255, 140)
fill.BorderSizePixel = 0
fill.Parent = track

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(1, 0)
fillCorner.Parent = fill

local knob = Instance.new("Frame")
knob.Size = UDim2.new(0, 12, 0, 12)
knob.AnchorPoint = Vector2.new(0.5, 0.5)
knob.Position = UDim2.new(0.3, 0, 0.5, 0)
knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
knob.BorderSizePixel = 0
knob.Parent = track

local knobCorner = Instance.new("UICorner")
knobCorner.CornerRadius = UDim.new(1, 0)
knobCorner.Parent = knob

-- =============================================================================
-- GUI LOGIC
-- =============================================================================
local dragging = false
local dragStart = nil
local startPos = nil
local sliderDragging = false

local function setPower(value)
    state.power = math.clamp(value, MIN, MAX)
    local t = (state.power - MIN) / (MAX - MIN)
    fill.Size = UDim2.new(t, 0, 1, 0)
    knob.Position = UDim2.new(t, 0, 0.5, 0)
    valueLabel.Text = string.format("%.2fx", state.power)
end

local function powerFromX(x)
    local rel = (x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1)
    rel = math.clamp(rel, 0, 1)
    local raw = MIN + (MAX - MIN) * rel
    return math.floor(raw / STEP + 0.5) * STEP
end

local function updateToggle()
    if state.enabled then
        title.Text = "РАСТЯГ"
        title.TextColor3 = Color3.fromRGB(0, 255, 140)
        valueLabel.TextColor3 = Color3.fromRGB(0, 255, 140)
        stroke.Color = Color3.fromRGB(0, 255, 140)
        stroke.Transparency = 0.4
    else
        title.Text = "ВЫКЛ"
        title.TextColor3 = Color3.fromRGB(120, 120, 130)
        valueLabel.TextColor3 = Color3.fromRGB(120, 120, 130)
        stroke.Color = Color3.fromRGB(70, 70, 80)
        stroke.Transparency = 0.6
    end
end

title.MouseButton1Click:Connect(function()
    state.enabled = not state.enabled
    updateToggle()
end)

close.MouseButton1Click:Connect(function()
    if _G.MiniStretchUnload then
        _G.MiniStretchUnload()
    else
        state.enabled = false
        lastApplied = nil
        gui:Destroy()
    end
end)

header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
    end
end)

local function startSlider(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        sliderDragging = true
        setPower(powerFromX(input.Position.X))
    end
end

track.InputBegan:Connect(startSlider)
knob.InputBegan:Connect(startSlider)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end

    if sliderDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        setPower(powerFromX(input.Position.X))
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
        sliderDragging = false
    end
end)

updateToggle()
setPower(state.power)

-- =============================================================================
-- UNLOAD
-- =============================================================================
_G.MiniStretchUnload = function()
    state.enabled = false
    lastApplied = nil
    pcall(function() RunService:UnbindFromRenderStep(BIND) end)
    pcall(function() RunService:UnbindFromRenderStep(BIND_LATE) end)
    if camHook then camHook:Disconnect() end
    if camChangedConn then camChangedConn:Disconnect() end
    pcall(function() gui:Destroy() end)
    _G.MiniStretchUnload = nil
end

print("[Mini Stretch] loaded. Click title to toggle, X to close. _G.MiniStretchUnload() to unload.")
