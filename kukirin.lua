--[[ KUKIRIN LIFE — Speed / Jump / 360 Spin ]]
-- Работает, когда сидишь на любом самокате.
-- Если не сидишь — эффекты применяются к персонажу.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

local CONFIG = {
	speed = 180,
	speedRampTime = 4,
	speedBrake = 120,
	jumpPower = 30,
	jumpHold = 0.12,
	spinSpeed = 30,
}

local speedOn = false
local spinning = false
local autoSpinOn = false
local autoSpinRunning = false
local autoWheelieOn = false
local autoWheelieRunning = false

local speedRampCurrent = 0
local speedRampPart = nil
local speedRampActive = false
local scriptWDown = false

-- ========== ЯЗЫК ==========
local currentLang = "ru"

local L = {
	ru = {
		title = "KUKIRIN",
		speedOff = "SPEED: ВЫКЛ",
		speedOn = "SPEED: ВКЛ",
		jump = "ПРЫЖОК С САМОКАТОМ",
		spin = "КРУТКА + ПРЫЖОК",
		spinActive = "КРУТКА...",
		autoSpinOff = "АВТО-КРУТКА: ВЫКЛ",
		autoSpinOn = "АВТО-КРУТКА: ВКЛ",
		wheelieOff = "ВИЛЛИ: ВЫКЛ",
		wheelieOn = "ВИЛЛИ: ВКЛ",
		sliderSpeed = "Скорость",
		sliderJump = "Сила прыжка",
		hint = "K — клавиши.\nSpeed: W.",
		keysTitle = "КЛАВИШИ",
		keysHint = "Жми на действие, потом клавишу",
		pressKey = "жми клавишу...",
		langBtn = "ЯЗЫК: РУССКИЙ",
		keyJump = "Прыжок",
		keySpin = "Крутка",
		keyAutoSpin = "Авто-крутка",
		keyWheelie = "Вилли",
		keySpeed = "SPEED",
	},
	en = {
		title = "KUKIRIN",
		speedOff = "SPEED: OFF",
		speedOn = "SPEED: ON",
		jump = "JUMP WITH SCOOTER",
		spin = "SPIN + JUMP",
		spinActive = "SPINNING...",
		autoSpinOff = "AUTO-SPIN: OFF",
		autoSpinOn = "AUTO-SPIN: ON",
		wheelieOff = "WHEELIE: OFF",
		wheelieOn = "WHEELIE: ON",
		sliderSpeed = "Speed",
		sliderJump = "Jump Power",
		hint = "K — keybinds.\nSpeed: W.",
		keysTitle = "KEYBINDS",
		keysHint = "Click action, then press a key",
		pressKey = "press a key...",
		langBtn = "LANG: ENGLISH",
		keyJump = "Jump",
		keySpin = "Spin",
		keyAutoSpin = "Auto-Spin",
		keyWheelie = "Wheelie",
		keySpeed = "SPEED",
	},
}

local function t(key)
	return L[currentLang][key] or L["ru"][key] or key
end

-- ================= ПОИСК САМОКАТА =================
local function getRide()
	local char = LocalPlayer.Character
	if not char then return nil, nil end

	local hum = char:FindFirstChildOfClass("Humanoid")
	local seat = hum and hum.SeatPart

	if seat then
		return seat, seat.AssemblyRootPart or seat
	end

	local hrp = char:FindFirstChild("HumanoidRootPart")

	if hrp then
		for _, obj in ipairs(hrp:GetChildren()) do
			if obj:IsA("Weld") or obj:IsA("WeldConstraint") or obj:IsA("Motor6D") then
				local other = nil
				if obj.Part0 == hrp then
					other = obj.Part1
				elseif obj.Part1 == hrp then
					other = obj.Part0
				end
				if other and not other:IsDescendantOf(char) then
					return nil, other.AssemblyRootPart or other
				end
			end
		end
	end

	local tool = char:FindFirstChildOfClass("Tool")
	local handle = tool and tool:FindFirstChild("Handle")
	if handle then
		return nil, handle.AssemblyRootPart or handle
	end

	if hrp then
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { char }

		local hit = workspace:Raycast(hrp.Position, Vector3.new(0, -12, 0), params)
		if hit and hit.Instance and hit.Instance:IsA("BasePart") then
			local hitPart = hit.Instance
			local model = hitPart:FindFirstAncestorOfClass("Model")
			local root = hitPart.AssemblyRootPart or hitPart
			local isVehicle = (not hitPart.Anchored) or (not root.Anchored)

			if isVehicle and model and model ~= workspace and model ~= char then
				local seatPart = model:FindFirstChildOfClass("VehicleSeat") or model:FindFirstChildOfClass("Seat")
				if seatPart then
					return seatPart, seatPart.AssemblyRootPart or seatPart
				end
				return nil, root
			end
		end
	end

	return nil, hrp
end

-- ================= SPEED =================
local function hasSpeedInput(seat)
	local okFocused, focused = pcall(function()
		return UserInputService:GetFocusedTextBox()
	end)
	if okFocused and focused then return false end

	if scriptWDown then return true end

	local okW, wDown = pcall(function()
		return UserInputService:IsKeyDown(Enum.KeyCode.W)
	end)
	if okW and wDown then return true end

	local okUp, upDown = pcall(function()
		return UserInputService:IsKeyDown(Enum.KeyCode.Up)
	end)
	if okUp and upDown then return true end

	if seat and seat:IsA("VehicleSeat") then
		local okThrottle, throttle = pcall(function()
			return seat.Throttle
		end)
		if okThrottle and type(throttle) == "number" and throttle > 0.05 then
			return true
		end
	end

	return false
end

local function applySpeed(dt)
	local seat, part = getRide()
	if not part or not part.Parent then
		speedRampActive = false
		speedRampPart = nil
		return
	end

	if not hasSpeedInput(seat) then
		speedRampActive = false
		speedRampPart = nil
		return
	end

	local look = (seat or part).CFrame.LookVector
	local dir = Vector3.new(look.X, 0, look.Z)
	if dir.Magnitude < 0.01 then
		speedRampActive = false
		speedRampPart = nil
		return
	end
	dir = dir.Unit

	local v = part.AssemblyLinearVelocity
	local forward = v:Dot(dir)
	local target = CONFIG.speed

	if not speedRampActive or speedRampPart ~= part then
		speedRampCurrent = forward
		speedRampPart = part
		speedRampActive = true
	end

	dt = math.min(dt or (1 / 60), 0.1)
	local ramp = math.max(1, CONFIG.speedRampTime or 4)
	local accel = math.max(25, target / ramp)
	local step = accel * dt

	if speedRampCurrent < target then
		speedRampCurrent = math.min(target, speedRampCurrent + step)
	else
		speedRampCurrent = math.max(target, speedRampCurrent - (CONFIG.speedBrake or 120) * dt)
	end

	local newSpeed = speedRampCurrent
	part.AssemblyLinearVelocity = Vector3.new(dir.X * newSpeed, v.Y, dir.Z * newSpeed)
end

RunService.Heartbeat:Connect(function(dt)
	if speedOn then
		pcall(applySpeed, dt)
	else
		speedRampActive = false
		speedRampPart = nil
	end
end)

-- ================= JUMP =================
local function doJump()
	local seat, part = getRide()
	if not part or not part.Parent then return end

	local v = part.AssemblyLinearVelocity
	part.AssemblyLinearVelocity = Vector3.new(v.X, CONFIG.jumpPower, v.Z)

	local bv = Instance.new("BodyVelocity")
	bv.MaxForce = Vector3.new(0, 1e6, 0)
	bv.Velocity = Vector3.new(v.X, CONFIG.jumpPower, v.Z)
	bv.Parent = part

	task.delay(CONFIG.jumpHold, function()
		if bv then bv:Destroy() end
	end)

	local char = LocalPlayer.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		pcall(function()
			hum.Jump = true
		end)
	end
end

-- ================= КРУТКА =================
local spinMode = "physics"
local spinTimer = 0
local spinLastYaw = nil
local spinYawAccum = 0
local spinAutoRotateWas = nil
local spinStartClock = 0
local spinStartY = 0
local spinFreezePos = nil

local function spinStop()
	spinning = false
	spinMode = "physics"
	spinTimer = 0
	spinLastYaw = nil
	spinYawAccum = 0
	spinFreezePos = nil

	local seat, part = getRide()
	if part and part.Parent then
		pcall(function()
			part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
		end)
	end

	local char = LocalPlayer.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum and spinAutoRotateWas ~= nil then
		pcall(function()
			hum.AutoRotate = spinAutoRotateWas
		end)
	end
	spinAutoRotateWas = nil
end

local function spinStart()
	local seat, part = getRide()
	if not part or not part.Parent then return false end

	local char = LocalPlayer.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		spinAutoRotateWas = hum.AutoRotate
		pcall(function()
			hum.AutoRotate = false
		end)
	end

	spinning = true
	spinMode = "physics"
	spinTimer = 0
	spinLastYaw = nil
	spinYawAccum = 0
	spinStartClock = os.clock()
	spinStartY = part.Position.Y
	spinFreezePos = Vector3.new(part.Position.X, part.Position.Y, part.Position.Z)

	local root = part.AssemblyRootPart or part
	if root.Anchored then
		spinMode = "cframe"
	end

	return true
end

RunService.Heartbeat:Connect(function(dt)
	if not spinning then return end

	local seat, part = getRide()
	if not part or not part.Parent then return end

	local elapsed = os.clock() - spinStartClock
	if elapsed > 0.25 then
		local vy = 0
		pcall(function()
			vy = part.AssemblyLinearVelocity.Y
		end)

		if (vy <= 0 and part.Position.Y <= spinStartY + 0.4) or elapsed > 8 then
			spinStop()
			return
		end
	end

	if spinMode == "physics" then
		pcall(function()
			part.AssemblyAngularVelocity = Vector3.new(0, CONFIG.spinSpeed, 0)
		end)

		spinTimer = spinTimer + dt

		local look = part.CFrame.LookVector
		local nowYaw = math.atan2(look.X, look.Z)
		if spinLastYaw then
			local d = nowYaw - spinLastYaw
			d = (d + math.pi) % (2 * math.pi) - math.pi
			spinYawAccum = spinYawAccum + math.abs(d)
		end
		spinLastYaw = nowYaw

		if spinTimer > 0.3 and spinYawAccum < 1 then
			spinMode = "cframe"
			pcall(function()
				part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
			end)
		end
	end

	if spinMode == "cframe" then
		pcall(function()
			part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
			local step = CONFIG.spinSpeed * dt
			local cf = part.CFrame
			part.CFrame = CFrame.new(cf.Position) * CFrame.Angles(0, step, 0) * (cf - cf.Position)
		end)
	end

	-- Заморозка позиции: при крутке не двигаемся по X/Z
	if spinFreezePos then
		pcall(function()
			local v = part.AssemblyLinearVelocity
			part.AssemblyLinearVelocity = Vector3.new(0, v.Y, 0)
			local cf = part.CFrame
			local pos = cf.Position
			if math.abs(pos.X - spinFreezePos.X) > 0.1 or math.abs(pos.Z - spinFreezePos.Z) > 0.1 then
				part.CFrame = CFrame.new(spinFreezePos.X, pos.Y, spinFreezePos.Z) * (cf - cf.Position)
			end
		end)
	end
end)

-- ================= GUI =================
local parent
pcall(function()
	if type(gethui) == "function" then
		parent = gethui()
	end
end)

if not parent then
	pcall(function()
		parent = game:GetService("CoreGui")
	end)
end

if not parent then
	parent = LocalPlayer:WaitForChild("PlayerGui")
end

local old = parent:FindFirstChild("KukirinGui")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "KukirinGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999
gui.Parent = parent

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.new(0, 220, 0, 480)
main.Position = UDim2.new(0, 20, 0.5, -240)
main.BackgroundColor3 = Color3.fromRGB(18, 20, 24)
main.BorderSizePixel = 0
main.Active = true
main.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = main

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(55, 60, 70)
stroke.Thickness = 1
stroke.Parent = main

-- ---- заголовок ----
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 30)
header.BackgroundTransparency = 1
header.Parent = main

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -62, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.Text = "KUKIRIN"
title.TextSize = 13
title.TextColor3 = Color3.fromRGB(235, 238, 245)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local close = Instance.new("TextButton")
close.Size = UDim2.new(0, 22, 0, 22)
close.Position = UDim2.new(1, -28, 0, 4)
close.BackgroundColor3 = Color3.fromRGB(235, 70, 70)
close.Text = "×"
close.TextSize = 16
close.Font = Enum.Font.GothamBold
close.TextColor3 = Color3.new(1, 1, 1)
close.BorderSizePixel = 0
close.AutoButtonColor = true
close.Parent = header

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = close

local keyBtn = Instance.new("TextButton")
keyBtn.Size = UDim2.new(0, 22, 0, 22)
keyBtn.Position = UDim2.new(1, -56, 0, 4)
keyBtn.BackgroundColor3 = Color3.fromRGB(60, 65, 80)
keyBtn.Text = "K"
keyBtn.TextSize = 12
keyBtn.Font = Enum.Font.GothamBold
keyBtn.TextColor3 = Color3.new(1, 1, 1)
keyBtn.BorderSizePixel = 0
keyBtn.AutoButtonColor = true
keyBtn.Parent = header

local keyCorner = Instance.new("UICorner")
keyCorner.CornerRadius = UDim.new(0, 6)
keyCorner.Parent = keyBtn

-- ---- перетаскивание ----
local dragging = false
local dragStart, startPos

header.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = main.Position
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		main.Position = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y
		)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

-- ---- кнопка ----
local function makeButton(text, y, color, x, width)
	local btn = Instance.new("TextButton")
	if width then
		btn.Size = UDim2.new(0, width, 0, 34)
		btn.Position = UDim2.new(0, x or 10, 0, y)
		btn.TextSize = 11
	else
		btn.Size = UDim2.new(1, -20, 0, 34)
		btn.Position = UDim2.new(0, 10, 0, y)
		btn.TextSize = 13
	end
	btn.BackgroundColor3 = color
	btn.Text = text
	btn.Font = Enum.Font.GothamBold
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.BorderSizePixel = 0
	btn.AutoButtonColor = true
	btn.Parent = main

	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = btn

	return btn
end

local speedBtn = makeButton(t("speedOff"), 38, Color3.fromRGB(50, 55, 65))
local jumpBtn = makeButton(t("jump"), 78, Color3.fromRGB(45, 110, 220))
local spinBtn = makeButton(t("spin"), 118, Color3.fromRGB(230, 150, 40))
local autoSpinBtn = makeButton(t("autoSpinOff"), 158, Color3.fromRGB(200, 100, 50))
local wheelieBtn = makeButton(t("wheelieOff"), 198, Color3.fromRGB(60, 140, 200))

-- ---- слайдер ----
local allSliders = {}

local function makeSlider(titleKey, y, minValue, maxValue, initial, onChange)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -20, 0, 16)
	label.Position = UDim2.new(0, 10, 0, y)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.Gotham
	label.Text = t(titleKey) .. ": " .. initial
	label.TextSize = 12
	label.TextColor3 = Color3.fromRGB(190, 195, 205)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = main

	local track = Instance.new("Frame")
	track.Size = UDim2.new(1, -20, 0, 8)
	track.Position = UDim2.new(0, 10, 0, y + 22)
	track.BackgroundColor3 = Color3.fromRGB(45, 48, 56)
	track.BorderSizePixel = 0
	track.Parent = main

	local trackCorner = Instance.new("UICorner")
	trackCorner.CornerRadius = UDim.new(1, 0)
	trackCorner.Parent = track

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new((initial - minValue) / (maxValue - minValue), 0, 1, 0)
	fill.BackgroundColor3 = Color3.fromRGB(0, 200, 120)
	fill.BorderSizePixel = 0
	fill.Parent = track

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = fill

	local currentValue = initial
	local sliding = false

	local function setFromX(x)
		local absX = track.AbsolutePosition.X
		local width = track.AbsoluteSize.X
		if width <= 0 then return end

		local alpha = math.clamp((x - absX) / width, 0, 1)
		local value = math.floor(minValue + (maxValue - minValue) * alpha + 0.5)
		currentValue = value

		fill.Size = UDim2.new(alpha, 0, 1, 0)
		label.Text = t(titleKey) .. ": " .. value
		onChange(value)
	end

	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			sliding = true
			setFromX(input.Position.X)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			setFromX(input.Position.X)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			sliding = false
		end
	end)

	table.insert(allSliders, {label = label, titleKey = titleKey, getValue = function() return currentValue end})
end

makeSlider("sliderSpeed", 240, 50, 500, CONFIG.speed, function(v)
	CONFIG.speed = v
end)

makeSlider("sliderJump", 284, 10, 150, CONFIG.jumpPower, function(v)
	CONFIG.jumpPower = v
end)

-- ---- подсказка ----
local hint = Instance.new("TextLabel")
hint.Size = UDim2.new(1, -20, 0, 26)
hint.Position = UDim2.new(0, 10, 0, 330)
hint.BackgroundTransparency = 1
hint.Font = Enum.Font.Gotham
hint.Text = t("hint")
hint.TextSize = 11
hint.TextColor3 = Color3.fromRGB(130, 135, 145)
hint.TextXAlignment = Enum.TextXAlignment.Left
hint.TextWrapped = true
hint.Parent = main

-- ---- разделитель ----
local sep = Instance.new("Frame")
sep.Size = UDim2.new(1, -20, 0, 1)
sep.Position = UDim2.new(0, 10, 0, 362)
sep.BackgroundColor3 = Color3.fromRGB(55, 60, 70)
sep.BackgroundTransparency = 0.5
sep.BorderSizePixel = 0
sep.Parent = main

-- ---- кнопка языка ----
local langBtn = Instance.new("TextButton")
langBtn.Size = UDim2.new(1, -20, 0, 30)
langBtn.Position = UDim2.new(0, 10, 0, 372)
langBtn.BackgroundColor3 = Color3.fromRGB(40, 42, 52)
langBtn.Text = t("langBtn")
langBtn.Font = Enum.Font.GothamBold
langBtn.TextSize = 12
langBtn.TextColor3 = Color3.fromRGB(170, 175, 190)
langBtn.BorderSizePixel = 0
langBtn.AutoButtonColor = true
langBtn.Parent = main

local langCorner = Instance.new("UICorner")
langCorner.CornerRadius = UDim.new(0, 8)
langCorner.Parent = langBtn

-- пересчитаем высоту
main.Size = UDim2.new(0, 220, 0, 414)
main.Position = UDim2.new(0, 20, 0.5, -207)

-- ---- обновление языка ----
local function refreshLang()
	speedBtn.Text = speedOn and t("speedOn") or t("speedOff")
	jumpBtn.Text = t("jump")
	spinBtn.Text = spinning and t("spinActive") or t("spin")
	autoSpinBtn.Text = autoSpinOn and t("autoSpinOn") or t("autoSpinOff")
	wheelieBtn.Text = autoWheelieOn and t("wheelieOn") or t("wheelieOff")
	hint.Text = t("hint")
	langBtn.Text = t("langBtn")

	for _, info in ipairs(allSliders) do
		info.label.Text = t(info.titleKey) .. ": " .. info.getValue()
	end
end

-- ---- действия ----
local function toggleSpeed()
	speedOn = not speedOn
	speedRampActive = false
	speedRampPart = nil
	if speedOn then
		speedBtn.Text = t("speedOn")
		speedBtn.BackgroundColor3 = Color3.fromRGB(0, 190, 110)
	else
		speedBtn.Text = t("speedOff")
		speedBtn.BackgroundColor3 = Color3.fromRGB(50, 55, 65)
	end
end

local function startSpin()
	if spinning then return false end
	if not spinStart() then return false end

	pcall(doJump)
	spinBtn.Text = t("spinActive")
	return true
end

local function toggleSpin()
	if spinning then
		pcall(spinStop)
		spinBtn.Text = t("spin")
		return
	end
	startSpin()
end

-- ---- вилли ----
local WHEELIE_ANGLE = 30

local vim = nil
pcall(function()
	vim = game:GetService("VirtualInputManager")
end)

local function rawKey(keyCode, down)
	if vim then
		local ok = pcall(function()
			vim:SendKeyEvent(down, keyCode, false, game)
		end)
		if ok then return end
	end

	if down then
		if type(keypress) == "function" then
			pcall(keypress, keyCode.Value)
		end
	else
		if type(keyrelease) == "function" then
			pcall(keyrelease, keyCode.Value)
		end
	end
end

local ctrlHeld = false
local sHeld = false
local wHeld = false

local function holdCtrl(down)
	if ctrlHeld == down then return end
	ctrlHeld = down
	rawKey(Enum.KeyCode.LeftControl, down)
end

local function holdS(down)
	if sHeld == down then return end
	sHeld = down
	rawKey(Enum.KeyCode.S, down)
end

local function holdW(down)
	if wHeld == down then return end
	wHeld = down
	scriptWDown = down
	rawKey(Enum.KeyCode.W, down)
end

local function releaseRideKeys()
	holdW(false)
	holdS(false)
	holdCtrl(false)
end

local function ridePitch()
	local seat, part = getRide()
	if not part or not part.Parent then return nil end

	local ok, y = pcall(function()
		return part.CFrame.LookVector.Y
	end)
	if not ok or not y then return nil end

	return math.asin(math.clamp(y, -1, 1))
end

local function rideSpeed()
	local seat, part = getRide()
	if not part or not part.Parent then return 0 end

	local ok, vel = pcall(function()
		return part.AssemblyLinearVelocity
	end)
	if ok and vel then return vel.Magnitude end

	ok, vel = pcall(function()
		return part.Velocity
	end)
	if ok and vel then return vel.Magnitude end

	return 0
end

-- ---- авто-крутка ----
local toggleAutoSpin
local toggleWheelie

local function autoSpinLoop()
	if autoSpinRunning then return end
	autoSpinRunning = true

	while autoSpinOn do
		if not gui or not gui.Parent then
			autoSpinRunning = false
			return
		end

		if autoWheelieOn then
			task.wait(0.5)
		else
			if not spinning then
				startSpin()
			end

			while autoSpinOn and spinning do
				task.wait(0.1)
			end

			if autoSpinOn then
				task.wait(2)
			end
		end
	end

	autoSpinRunning = false
end

local function autoWheelieLoop()
	if autoWheelieRunning then return end
	autoWheelieRunning = true

	while autoWheelieOn do
		if not gui or not gui.Parent then
			releaseRideKeys()
			autoWheelieRunning = false
			return
		end

		local seat, part = getRide()
		local rideOk = part and part.Parent and not part:IsDescendantOf(LocalPlayer.Character)

		if rideOk and not autoSpinOn then
			break
		end

		releaseRideKeys()
		task.wait(0.3)
	end

	if autoWheelieOn then
		holdW(true)

		local t0 = os.clock()
		while autoWheelieOn and gui and gui.Parent and os.clock() - t0 < 3 do
			local seat, part = getRide()
			local rideOk = part and part.Parent and not part:IsDescendantOf(LocalPlayer.Character)
			if not rideOk then break end
			if rideSpeed() > 10 then break end
			task.wait(0.1)
		end

		if not autoWheelieOn or not gui or not gui.Parent then
			releaseRideKeys()
			autoWheelieRunning = false
			return
		end

		local sUp = nil
		local seat, part = getRide()
		local rideOk = part and part.Parent and not part:IsDescendantOf(LocalPlayer.Character)

		if rideOk then
			holdCtrl(true)
			holdS(true)
			task.wait(0.3)

			if not autoWheelieOn or not gui or not gui.Parent then
				releaseRideKeys()
				autoWheelieRunning = false
				return
			end

			local p0 = ridePitch()
			holdS(false)
			task.wait(0.15)

			if not autoWheelieOn or not gui or not gui.Parent then
				releaseRideKeys()
				autoWheelieRunning = false
				return
			end

			local p1 = ridePitch()

			if p0 and p1 then
				if p1 > p0 + math.rad(3) then
					sUp = false
				elseif p1 < p0 - math.rad(3) then
					sUp = true
				end
			end

			if sUp == nil then
				sUp = false
			end

			if sUp == false then
				holdS(true)
			end
		else
			releaseRideKeys()
		end

		local target = math.rad(WHEELIE_ANGLE)

		while autoWheelieOn do
			if not gui or not gui.Parent then
				releaseRideKeys()
				autoWheelieRunning = false
				return
			end

			local seat, part = getRide()
			local rideOk = part and part.Parent and not part:IsDescendantOf(LocalPlayer.Character)

			if not rideOk or autoSpinOn then
				releaseRideKeys()
				task.wait(0.3)
			else
				holdW(true)
				holdCtrl(true)

				local pitch = ridePitch()
				if pitch then
					if sUp == true then
						holdS(pitch < target and (os.clock() % 0.9) < 0.4)
					elseif sUp == false then
						holdS(pitch > target + math.rad(8))
					else
						holdS(false)
					end
				end

				task.wait(0.05)
			end
		end
	end

	releaseRideKeys()
	autoWheelieRunning = false
end

toggleAutoSpin = function()
	autoSpinOn = not autoSpinOn

	if autoSpinOn then
		if autoWheelieOn then toggleWheelie() end

		autoSpinBtn.Text = t("autoSpinOn")
		autoSpinBtn.BackgroundColor3 = Color3.fromRGB(0, 190, 110)
		task.spawn(autoSpinLoop)
	else
		autoSpinBtn.Text = t("autoSpinOff")
		autoSpinBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 50)

		if spinning then
			pcall(spinStop)
		end
	end
end

toggleWheelie = function()
	autoWheelieOn = not autoWheelieOn

	if autoWheelieOn then
		if autoSpinOn then toggleAutoSpin() end

		wheelieBtn.Text = t("wheelieOn")
		wheelieBtn.BackgroundColor3 = Color3.fromRGB(0, 190, 110)
		task.spawn(autoWheelieLoop)
	else
		wheelieBtn.Text = t("wheelieOff")
		wheelieBtn.BackgroundColor3 = Color3.fromRGB(60, 140, 200)
		releaseRideKeys()
	end
end

speedBtn.MouseButton1Click:Connect(toggleSpeed)

jumpBtn.MouseButton1Click:Connect(function()
	pcall(doJump)
end)

spinBtn.MouseButton1Click:Connect(toggleSpin)
autoSpinBtn.MouseButton1Click:Connect(toggleAutoSpin)
wheelieBtn.MouseButton1Click:Connect(toggleWheelie)

RunService.Heartbeat:Connect(function()
	if not gui or not gui.Parent then return end
	if spinBtn.Text == t("spinActive") and not spinning then
		spinBtn.Text = t("spin")
	end
end)

-- ---- кнопка языка ----
langBtn.MouseButton1Click:Connect(function()
	if currentLang == "ru" then
		currentLang = "en"
	else
		currentLang = "ru"
	end
	refreshLang()

	-- обновить окно клавиш
	pcall(function()
		if keyTitle then keyTitle.Text = t("keysTitle") end
		if keyHint then keyHint.Text = t("keysHint") end
		for action, info in pairs(bindButtons) do
			if listening == action then
				info.button.Text = t(info.row.titleKey) .. ": " .. t("pressKey")
			else
				info.button.Text = bindText(info.row, binds[action])
			end
		end
	end)
end)

-- ---- окно клавиш ----
local keyFrame = Instance.new("Frame")
keyFrame.Size = UDim2.new(0, 190, 0, 250)
keyFrame.Position = UDim2.new(0, 250, 0.5, -125)
keyFrame.BackgroundColor3 = Color3.fromRGB(18, 20, 24)
keyFrame.BorderSizePixel = 0
keyFrame.Visible = false
keyFrame.Parent = gui

local keyFrameCorner = Instance.new("UICorner")
keyFrameCorner.CornerRadius = UDim.new(0, 10)
keyFrameCorner.Parent = keyFrame

local keyFrameStroke = Instance.new("UIStroke")
keyFrameStroke.Color = Color3.fromRGB(55, 60, 70)
keyFrameStroke.Thickness = 1
keyFrameStroke.Parent = keyFrame

local keyTitle = Instance.new("TextLabel")
keyTitle.Size = UDim2.new(1, -20, 0, 26)
keyTitle.Position = UDim2.new(0, 10, 0, 4)
keyTitle.BackgroundTransparency = 1
keyTitle.Font = Enum.Font.GothamBold
keyTitle.Text = t("keysTitle")
keyTitle.TextSize = 12
keyTitle.TextColor3 = Color3.fromRGB(235, 238, 245)
keyTitle.TextXAlignment = Enum.TextXAlignment.Left
keyTitle.Parent = keyFrame

local keyHint = Instance.new("TextLabel")
keyHint.Size = UDim2.new(1, -20, 0, 16)
keyHint.Position = UDim2.new(0, 10, 0, 226)
keyHint.BackgroundTransparency = 1
keyHint.Font = Enum.Font.Gotham
keyHint.Text = t("keysHint")
keyHint.TextSize = 10
keyHint.TextColor3 = Color3.fromRGB(130, 135, 145)
keyHint.TextXAlignment = Enum.TextXAlignment.Left
keyHint.Parent = keyFrame

local keyRows = {
	{ action = "jump", titleKey = "keyJump" },
	{ action = "spin", titleKey = "keySpin" },
	{ action = "autospin", titleKey = "keyAutoSpin" },
	{ action = "wheelie", titleKey = "keyWheelie" },
	{ action = "speed", titleKey = "keySpeed" },
}

local binds = {
	jump = nil,
	spin = nil,
	autospin = nil,
	wheelie = nil,
	speed = nil,
}

local bindButtons = {}
local listening = nil

local function bindText(row, key)
	return t(row.titleKey) .. ": " .. (key and key.Name or "—")
end

local rowY = 30
for _, row in ipairs(keyRows) do
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1, -16, 0, 30)
	b.Position = UDim2.new(0, 8, 0, rowY)
	b.BackgroundColor3 = Color3.fromRGB(45, 48, 56)
	b.Text = bindText(row, binds[row.action])
	b.TextSize = 11
	b.Font = Enum.Font.GothamBold
	b.TextColor3 = Color3.new(1, 1, 1)
	b.BorderSizePixel = 0
	b.Parent = keyFrame

	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 6)
	c.Parent = b

	b.MouseButton1Click:Connect(function()
		listening = row.action
		b.Text = t(row.titleKey) .. ": " .. t("pressKey")
	end)

	bindButtons[row.action] = { button = b, row = row }
	rowY = rowY + 34
end

keyBtn.MouseButton1Click:Connect(function()
	keyFrame.Visible = not keyFrame.Visible
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

	if listening and input.KeyCode == Enum.KeyCode.Escape then
		local info = bindButtons[listening]
		if info then
			info.button.Text = bindText(info.row, binds[listening])
		end
		listening = nil
		return
	end

	if gameProcessed then return end

	if listening then
		local action = listening
		listening = nil
		binds[action] = input.KeyCode

		local info = bindButtons[action]
		if info then
			info.button.Text = bindText(info.row, input.KeyCode)
		end
		return
	end

	if autoWheelieOn and (input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.W or input.KeyCode == Enum.KeyCode.S) then
		return
	end

	for action, key in pairs(binds) do
		if key and key == input.KeyCode then
			if action == "jump" then
				pcall(doJump)
			elseif action == "spin" then
				toggleSpin()
			elseif action == "autospin" then
				toggleAutoSpin()
			elseif action == "wheelie" then
				toggleWheelie()
			elseif action == "speed" then
				toggleSpeed()
			end
			break
		end
	end
end)

close.MouseButton1Click:Connect(function()
	speedOn = false
	autoSpinOn = false
	autoWheelieOn = false
	releaseRideKeys()
	if spinning then
		pcall(spinStop)
	end
	gui:Destroy()
end)

print("[kukirin] loaded: SPEED / JUMP / SPIN / AUTOSPIN / WHEELIE / BINDS / RU-EN")
