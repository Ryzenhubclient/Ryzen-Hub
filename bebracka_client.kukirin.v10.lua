--[[ BEBRACKA CLIENT — Speed / Fly / Jump / Spin / Auto-Spin / Wheelie ]]
-- Работает, когда сидишь на любом самокате.
-- Если не сидишь — эффекты применяются к персонажу.
-- Новое: большое GUI с вкладками, переключатель RU / EN,
-- крутка на месте старта.
-- Картинка в GUI вшита в скрипт (нужен executor с writefile + getcustomasset).
-- Если картинка не грузится, можно указать свой ID: BG_ASSET_ID = "123456789".

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

-- ================= ОЧИСТКА ПРОШЛОГО ЗАПУСКА =================
pcall(function()
	if _G.__kukirinCleanup then
		_G.__kukirinCleanup()
	end
	if _G.__bebrackaCleanup then
		_G.__bebrackaCleanup()
	end
end)

local conns = {}
local function connect(signal, fn)
	local c = signal:Connect(fn)
	table.insert(conns, c)
	return c
end

local CONFIG = {
	speed = 180,
	speedRampTime = 7, -- за сколько секунд разгоняемся до полной скорости
	speedBrake = 120,
	jumpPower = 30,
	jumpHold = 0.12,

	spinSpeed = 35, -- скорость крутки (рад/сек, 35 ≈ 5,5 оборотов в сек)
	flySpeed = 100, -- скорость полёта
	spinInterval = 2, -- авто-крутка запускается каждые N секунд
}

local speedOn = false
local flyOn = false
local flyUp = false
local flyDown = false
local spinning = false
local autoSpinOn = false
local autoSpinRunning = false
local autoWheelieOn = false
local autoWheelieRunning = false

local speedRampCurrent = 0
local speedRampPart = nil
local speedRampActive = false
local speedRampStart = 0
local speedRampT = 0
local speedRampTarget = 0
local scriptWDown = false

local gui = nil
local updateUI = nil -- назначается ниже, после создания GUI

-- ========== ЯЗЫК ==========
local currentLang = "ru"

local L = {
	ru = {
		title = "BEBRACKA CLIENT",
		subtitle = "Speed • Fly • Spin • Wheelie",
		tabMain = "Управление",
		tabKeys = "Клавиши",
		secMove = "ДВИЖЕНИЕ",
		secFly = "ПОЛЁТ",
		secTricks = "ТРЮКИ",
		secSettings = "НАСТРОЙКИ",
		tgSpeed = "SPEED",
		tgFly = "ПОЛЁТ",
		tgAutoSpin = "АВТО-КРУТКА",
		tgWheelie = "ВИЛЛИ",
		stateOn = "включено",
		stateOff = "выключено",
		flyOff = "ПОЛЁТ: ВЫКЛ",
		flyOn = "ПОЛЁТ: ВКЛ",
		flyUp = "▲ ВВЕРХ",
		flyDown = "▼ ВНИЗ",
		sliderFly = "Скорость полёта",
		keyFly = "Полёт",
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
		sliderRamp = "Плавность разгона (сек)",
		sliderJump = "Сила прыжка",
		sliderSpin = "Скорость крутки",
		speedNow = "Текущая скорость",
		hint = "Speed работает, пока зажата W. Крутка идёт на месте, где ты её начал.\nПолёт: W/A/S/D по камере, Space — вверх, Shift — вниз.",
		keysTip = "Нажми на кнопку, потом на нужную клавишу.\nBackspace — очистить, Esc — отмена.",
		pressKey = "жми клавишу...",
		keyJump = "Прыжок",
		keySpin = "Крутка",
		keyAutoSpin = "Авто-крутка",
		keyWheelie = "Вилли",
		keySpeed = "Speed",
	},
	en = {
		title = "BEBRACKA CLIENT",
		subtitle = "Speed • Fly • Spin • Wheelie",
		tabMain = "Controls",
		tabKeys = "Keybinds",
		secMove = "MOVEMENT",
		secFly = "FLIGHT",
		secTricks = "TRICKS",
		secSettings = "SETTINGS",
		tgSpeed = "SPEED",
		tgFly = "FLY",
		tgAutoSpin = "AUTO-SPIN",
		tgWheelie = "WHEELIE",
		stateOn = "enabled",
		stateOff = "disabled",
		flyOff = "FLY: OFF",
		flyOn = "FLY: ON",
		flyUp = "▲ UP",
		flyDown = "▼ DOWN",
		sliderFly = "Fly Speed",
		keyFly = "Fly",
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
		sliderRamp = "Acceleration time (sec)",
		sliderJump = "Jump Power",
		sliderSpin = "Spin Speed",
		speedNow = "Current speed",
		hint = "Speed works while W is held. The spin stays where you started it.\nFly: W/A/S/D follow the camera, Space — up, Shift — down.",
		keysTip = "Click a button, then press the key you want.\nBackspace — clear, Esc — cancel.",
		pressKey = "press a key...",
		keyJump = "Jump",
		keySpin = "Spin",
		keyAutoSpin = "Auto-Spin",
		keyWheelie = "Wheelie",
		keySpeed = "Speed",
	},
}

local function t(key)
	return (L[currentLang] and L[currentLang][key]) or L.ru[key] or key
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
	if flyOn then
		speedRampActive = false
		speedRampPart = nil
		return
	end

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
		speedRampStart = forward
		speedRampT = 0
		speedRampTarget = target
	end

	-- если поменяли скорость слайдером — разгон начинается заново от текущей
	if speedRampTarget ~= target then
		speedRampStart = speedRampCurrent
		speedRampT = 0
		speedRampTarget = target
	end

	dt = math.min(dt or (1 / 60), 0.1)
	local ramp = math.max(0.5, CONFIG.speedRampTime or 7)

	if speedRampCurrent < target then
		-- плавный разгон по кривой smoothstep: мягкий старт, ровный набор, мягкий выход на максимум
		speedRampT = math.min(1, speedRampT + dt / ramp)
		local k = speedRampT * speedRampT * (3 - 2 * speedRampT)
		local eased = speedRampStart + (target - speedRampStart) * k
		speedRampCurrent = math.min(target, math.max(speedRampCurrent, eased))
	else
		speedRampCurrent = math.max(target, speedRampCurrent - (CONFIG.speedBrake or 120) * dt)
	end

	local newSpeed = speedRampCurrent
	part.AssemblyLinearVelocity = Vector3.new(dir.X * newSpeed, v.Y, dir.Z * newSpeed)
end

connect(RunService.Heartbeat, function(dt)
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
local spinBaseCF = nil
local spinPivot = nil
local spinAngle = 0

local function spinStop()
	spinning = false
	spinMode = "physics"
	spinTimer = 0
	spinLastYaw = nil
	spinYawAccum = 0
	spinFreezePos = nil
	spinBaseCF = nil
	spinPivot = nil

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

	if updateUI then pcall(updateUI) end
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

	local cf0 = part.CFrame
	-- Ось вращения — игрок (HumanoidRootPart), а не центр детали самоката.
	-- Если крутить вокруг детали, смещённой от игрока, самокат "ездит по кругу".
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local pivotPos = hrp and hrp.Position or cf0.Position

	spinning = true
	spinStartClock = os.clock()
	spinStartY = part.Position.Y
	spinFreezePos = cf0.Position
	spinBaseCF = cf0
	spinPivot = Vector3.new(pivotPos.X, 0, pivotPos.Z)
	spinAngle = 0

	return true
end

connect(RunService.Heartbeat, function(dt)
	if not spinning or not spinBaseCF then return end

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

	-- Ровная крутка: угол растёт строго равномерно, позиция X/Z жёстко = точке старта.
	spinAngle = spinAngle + CONFIG.spinSpeed * math.min(dt, 0.05)

	pcall(function()
		local v = part.AssemblyLinearVelocity
		part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
		part.AssemblyLinearVelocity = Vector3.new(0, v.Y, 0)

		-- поворачиваем весь самокат вокруг вертикальной оси игрока
		local rotated = CFrame.new(spinPivot) * CFrame.Angles(0, spinAngle, 0) * CFrame.new(-spinPivot) * spinBaseCF
		-- высоту берём из физики (прыжок), X/Z остаются на месте
		local dy = part.Position.Y - spinBaseCF.Position.Y
		part.CFrame = rotated + Vector3.new(0, dy, 0)
	end)
end)

-- ================= ПОЛЁТ =================
local function flyInputVector()
	local cam = workspace.CurrentCamera
	if not cam then return Vector3.new(0, 0, 0) end

	local typing = false
	pcall(function()
		typing = UserInputService:GetFocusedTextBox() ~= nil
	end)

	local move = Vector3.new(0, 0, 0)
	local horizontalKey = false

	if not typing then
		local look = cam.CFrame.LookVector
		local right = cam.CFrame.RightVector

		if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + look; horizontalKey = true end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - look; horizontalKey = true end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + right; horizontalKey = true end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - right; horizontalKey = true end

		if UserInputService:IsKeyDown(Enum.KeyCode.Space) or flyUp then
			move = move + Vector3.new(0, 1, 0)
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or flyDown then
			move = move - Vector3.new(0, 1, 0)
		end
	elseif flyUp or flyDown then
		if flyUp then move = move + Vector3.new(0, 1, 0) end
		if flyDown then move = move - Vector3.new(0, 1, 0) end
	end

	-- джойстик на телефоне
	if not horizontalKey then
		local char = LocalPlayer.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum and hum.MoveDirection.Magnitude > 0.05 then
			move = move + hum.MoveDirection
		end
	end

	return move, horizontalKey
end

-- Полёт через физику (BodyVelocity + BodyGyro), как у прыжка: без телепорта по CFrame.
-- Игра обычно откатывает самокат именно при телепорте, а силы она "терпит" лучше.
local flyObjs = nil

local function flyRelease()
	if flyObjs then
		local o = flyObjs
		flyObjs = nil
		pcall(function() if o.bv then o.bv:Destroy() end end)
		pcall(function() if o.bg then o.bg:Destroy() end end)
	end
end

local function flyEnsure(part)
	if flyObjs and flyObjs.part == part and flyObjs.bv and flyObjs.bv.Parent == part then
		return flyObjs
	end
	flyRelease()

	local bv = Instance.new("BodyVelocity")
	bv.Name = "BebrackaFlyVel"
	bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
	bv.P = 1e5
	bv.Velocity = Vector3.new(0, 0, 0)
	bv.Parent = part

	local cf = part.CFrame
	local bg = Instance.new("BodyGyro")
	bg.Name = "BebrackaFlyGyro"
	bg.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
	bg.P = 1e4
	bg.D = 600
	bg.CFrame = cf - cf.Position
	bg.Parent = part

	flyObjs = { part = part, bv = bv, bg = bg }
	return flyObjs
end

connect(RunService.Heartbeat, function(dt)
	if not flyOn or spinning then
		flyRelease()
		return
	end

	local seat, part = getRide()
	if not part or not part.Parent then
		flyRelease()
		return
	end

	local objs = flyEnsure(part)
	local move = flyInputVector()

	local vel = Vector3.new(0, 0, 0)
	if move.Magnitude > 0.01 then
		vel = move.Unit * CONFIG.flySpeed
	end

	pcall(function()
		objs.bv.Velocity = vel

		-- ориентация: держим текущую, а при движении плавно разворачиваем по камере
		local cf = part.CFrame
		local rot = cf - cf.Position
		local targetRot = rot

		local flatMove = Vector3.new(move.X, 0, move.Z)
		local cam = workspace.CurrentCamera
		if cam and flatMove.Magnitude > 0.01 then
			local camLook = cam.CFrame.LookVector
			local camFlat = Vector3.new(camLook.X, 0, camLook.Z)
			local ref = (seat or part).CFrame.LookVector
			local refFlat = Vector3.new(ref.X, 0, ref.Z)

			if camFlat.Magnitude > 0.01 and refFlat.Magnitude > 0.01 then
				local target = math.atan2(-camFlat.X, -camFlat.Z)
				local current = math.atan2(-refFlat.X, -refFlat.Z)
				local diff = (target - current + math.pi) % (2 * math.pi) - math.pi
				targetRot = CFrame.Angles(0, diff, 0) * rot
			end
		end

		objs.bg.CFrame = targetRot
	end)
end)

-- ================= ВИЛЛИ: клавиши и датчики =================
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

-- ================= ДЕЙСТВИЯ =================
local toggleAutoSpin
local toggleWheelie

local function toggleSpeed()
	speedOn = not speedOn
	speedRampActive = false
	speedRampPart = nil
	if updateUI then pcall(updateUI) end
end

local function toggleFly()
	flyOn = not flyOn
	flyUp = false
	flyDown = false

	if flyOn then
		if autoWheelieOn and toggleWheelie then toggleWheelie() end
		if autoSpinOn and toggleAutoSpin then toggleAutoSpin() end
	end

	if updateUI then pcall(updateUI) end
end

local function startSpin()
	if spinning then return false end
	if not spinStart() then return false end

	pcall(doJump)
	if updateUI then pcall(updateUI) end
	return true
end

local function toggleSpin()
	if spinning then
		pcall(spinStop)
		return
	end
	startSpin()
end

-- ---- авто-крутка ----
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
			local cycleStart = os.clock()

			if not spinning then
				if not startSpin() then
					task.wait(0.5)
					cycleStart = nil
				end
			end

			while autoSpinOn and spinning do
				task.wait(0.05)
			end

			-- держим период: следующая крутка ровно через spinInterval секунд после начала прошлой
			if autoSpinOn and cycleStart then
				local left = CONFIG.spinInterval - (os.clock() - cycleStart)
				if left > 0 then
					task.wait(left)
				end
			end
		end
	end

	autoSpinRunning = false
end

-- ---- авто-вилли ----
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

		local tStart = os.clock()
		while autoWheelieOn and gui and gui.Parent and os.clock() - tStart < 3 do
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

			local seat2, part2 = getRide()
			local rideOk2 = part2 and part2.Parent and not part2:IsDescendantOf(LocalPlayer.Character)

			if not rideOk2 or autoSpinOn then
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
		task.spawn(autoSpinLoop)
	else
		if spinning then
			pcall(spinStop)
		end
	end

	if updateUI then pcall(updateUI) end
end

toggleWheelie = function()
	autoWheelieOn = not autoWheelieOn

	if autoWheelieOn then
		if autoSpinOn then toggleAutoSpin() end
		task.spawn(autoWheelieLoop)
	else
		releaseRideKeys()
	end

	if updateUI then pcall(updateUI) end
end

-- ================= КАРТИНКА ДЛЯ GUI =================
-- Можно вписать свой ID картинки, загруженной на Roblox (например "123456789").
local BG_ASSET_ID = ""

local BG_B64 = [[
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
]]

local B64_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local B64_MAP = {}
for i = 1, #B64_CHARS do
	B64_MAP[B64_CHARS:byte(i)] = i - 1
end

local function b64decode(str)
	local out, n = {}, 0
	local acc, bits = 0, 0
	for i = 1, #str do
		local v = B64_MAP[str:byte(i)]
		if v then
			acc = acc * 64 + v
			bits = bits + 6
			if bits >= 8 then
				bits = bits - 8
				local byte = math.floor(acc / 2 ^ bits) % 256
				n = n + 1
				out[n] = string.char(byte)
				acc = acc % 2 ^ bits
			end
		end
	end
	return table.concat(out)
end

local function loadBgImage()
	if BG_ASSET_ID ~= "" then
		return "rbxassetid://" .. BG_ASSET_ID
	end

	local ok, result = pcall(function()
		local getAsset = getcustomasset or getsynasset
		if type(getAsset) ~= "function" or type(writefile) ~= "function" then
			return nil
		end
		writefile("bebracka_bg.jpg", b64decode(BG_B64))
		return getAsset("bebracka_bg.jpg")
	end)

	if ok and result and result ~= "" then
		return result
	end
	return nil
end

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

for _, n in ipairs({ "KukirinGui", "BebrackaClientGui" }) do
	local old = parent:FindFirstChild(n)
	if old then old:Destroy() end
end

local COL = {
	bg = Color3.fromRGB(32, 10, 22),
	panel = Color3.fromRGB(62, 22, 42),
	panel2 = Color3.fromRGB(92, 36, 64),
	stroke = Color3.fromRGB(255, 120, 165),
	text = Color3.fromRGB(255, 238, 244),
	sub = Color3.fromRGB(226, 168, 190),
	on = Color3.fromRGB(235, 55, 105),
	accent = Color3.fromRGB(255, 95, 145),
	blue = Color3.fromRGB(214, 62, 122),
	orange = Color3.fromRGB(238, 104, 96),
	pink = Color3.fromRGB(255, 112, 178),
	deepOrange = Color3.fromRGB(178, 36, 82),
	sky = Color3.fromRGB(168, 60, 150),
	neutral = Color3.fromRGB(96, 38, 68),
	red = Color3.fromRGB(225, 50, 80),
	fly = Color3.fromRGB(138, 70, 200),
}

local WIN_W, WIN_H, HEADER_H, MIN_H = 380, 640, 124, 56

local function new(class, props, parentObj)
	local o = Instance.new(class)
	for k, v in pairs(props) do
		o[k] = v
	end
	if parentObj then o.Parent = parentObj end
	return o
end

local function round(obj, r)
	return new("UICorner", { CornerRadius = UDim.new(0, r or 8) }, obj)
end

gui = new("ScreenGui", {
	Name = "BebrackaClientGui",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 999,
}, parent)

local main = new("Frame", {
	Name = "Main",
	Size = UDim2.new(0, WIN_W, 0, WIN_H),
	Position = UDim2.new(0, 24, 0.5, -WIN_H / 2),
	BackgroundColor3 = Color3.new(1, 1, 1),
	BorderSizePixel = 0,
	Active = true,
	ClipsDescendants = true,
}, gui)
round(main, 14)
new("UIStroke", { Color = COL.stroke, Thickness = 1.5, Transparency = 0.25 }, main)
new("UIGradient", {
	Rotation = 90,
	Color = ColorSequence.new(Color3.fromRGB(58, 18, 40), Color3.fromRGB(26, 8, 18)),
}, main)

-- фоновая картинка: девушка видна за всем верхом окна и плавно уходит в тёмный фон
local BG_H = 400
local bgTexture = new("ImageLabel", {
	Size = UDim2.new(1, 0, 0, BG_H),
	BackgroundTransparency = 1,
	ScaleType = Enum.ScaleType.Crop,
	ImageTransparency = 0,
	Image = "",
	BorderSizePixel = 0,
}, main)
round(bgTexture, 14)

local bgFade = new("Frame", {
	Size = UDim2.new(1, 0, 0, 220),
	Position = UDim2.new(0, 0, 0, BG_H - 220),
	BackgroundColor3 = Color3.fromRGB(38, 12, 26),
	BorderSizePixel = 0,
}, main)
new("UIGradient", {
	Rotation = 90,
	Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 0),
	}),
}, bgFade)

local bgImageContent = loadBgImage()
if bgImageContent then
	bgTexture.Image = bgImageContent
end

-- список элементов, у которых текст зависит от языка
local langItems = {}
local function bindText(obj, getter)
	table.insert(langItems, { obj = obj, get = getter })
	obj.Text = getter()
end

-- ---- заголовок ----
local banner = new("Frame", {
	Size = UDim2.new(1, 0, 0, HEADER_H),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ClipsDescendants = true,
}, main)
round(banner, 14)

-- затемнение сверху (чтобы кнопки читались) и плавный переход снизу в окно
local topShade = new("Frame", {
	Size = UDim2.new(1, 0, 0, 60),
	BackgroundColor3 = Color3.fromRGB(24, 4, 14),
	BorderSizePixel = 0,
}, banner)
round(topShade, 14)
new("UIGradient", {
	Rotation = 90,
	Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	}),
}, topShade)

local header = new("Frame", {
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundTransparency = 1,
}, banner)

local subtitle = new("TextLabel", {
	Size = UDim2.new(1, -28, 0, 18),
	Position = UDim2.new(0, 14, 1, -26),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamMedium,
	TextSize = 12,
	TextColor3 = COL.sub,
	TextStrokeTransparency = 0.6,
	TextStrokeColor3 = Color3.fromRGB(30, 4, 14),
	TextXAlignment = Enum.TextXAlignment.Left,
}, header)
bindText(subtitle, function() return t("subtitle") end)

local title = new("TextLabel", {
	Size = UDim2.new(0, 190, 0, 56),
	Position = UDim2.new(0, 14, 0, 0),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBlack,
	TextSize = 17,
	TextColor3 = COL.text,
	TextStrokeTransparency = 0.45,
	TextStrokeColor3 = Color3.fromRGB(120, 20, 60),
	TextXAlignment = Enum.TextXAlignment.Left,
}, header)
bindText(title, function() return t("title") end)

local closeBtn = new("TextButton", {
	Size = UDim2.new(0, 28, 0, 28),
	Position = UDim2.new(1, -38, 0, 8),
	BackgroundColor3 = COL.red,
	Text = "×",
	TextSize = 20,
	Font = Enum.Font.GothamBold,
	TextColor3 = Color3.new(1, 1, 1),
	BorderSizePixel = 0,
}, header)
round(closeBtn, 8)

local minBtn = new("TextButton", {
	Size = UDim2.new(0, 28, 0, 28),
	Position = UDim2.new(1, -72, 0, 8),
	BackgroundColor3 = Color3.fromRGB(30, 8, 20),
	BackgroundTransparency = 0.25,
	Text = "–",
	TextSize = 18,
	Font = Enum.Font.GothamBold,
	TextColor3 = Color3.new(1, 1, 1),
	BorderSizePixel = 0,
}, header)
round(minBtn, 8)

-- переключатель языка RU | EN
local langHolder = new("Frame", {
	Size = UDim2.new(0, 84, 0, 28),
	Position = UDim2.new(1, -164, 0, 8),
	BackgroundColor3 = Color3.fromRGB(30, 8, 20),
	BackgroundTransparency = 0.25,
	BorderSizePixel = 0,
}, header)
round(langHolder, 8)

local langRU = new("TextButton", {
	Size = UDim2.new(0, 38, 0, 24),
	Position = UDim2.new(0, 2, 0, 2),
	Text = "RU",
	TextSize = 12,
	Font = Enum.Font.GothamBold,
	TextColor3 = Color3.new(1, 1, 1),
	BorderSizePixel = 0,
}, langHolder)
round(langRU, 6)

local langEN = new("TextButton", {
	Size = UDim2.new(0, 38, 0, 24),
	Position = UDim2.new(0, 44, 0, 2),
	Text = "EN",
	TextSize = 12,
	Font = Enum.Font.GothamBold,
	TextColor3 = Color3.new(1, 1, 1),
	BorderSizePixel = 0,
}, langHolder)
round(langEN, 6)

-- ---- вкладки ----
local tabBar = new("Frame", {
	Size = UDim2.new(1, -16, 0, 34),
	Position = UDim2.new(0, 8, 0, HEADER_H + 8),
	BackgroundTransparency = 1,
}, main)

local tabMain = new("TextButton", {
	Size = UDim2.new(0.5, -4, 1, 0),
	Position = UDim2.new(0, 0, 0, 0),
	TextSize = 13,
	Font = Enum.Font.GothamBold,
	TextColor3 = Color3.new(1, 1, 1),
	BorderSizePixel = 0,
}, tabBar)
round(tabMain, 8)
bindText(tabMain, function() return t("tabMain") end)

local tabKeys = new("TextButton", {
	Size = UDim2.new(0.5, -4, 1, 0),
	Position = UDim2.new(0.5, 4, 0, 0),
	TextSize = 13,
	Font = Enum.Font.GothamBold,
	TextColor3 = Color3.new(1, 1, 1),
	BorderSizePixel = 0,
}, tabBar)
round(tabKeys, 8)
bindText(tabKeys, function() return t("tabKeys") end)

-- ---- страницы ----
local content = new("Frame", {
	Size = UDim2.new(1, -16, 1, -(HEADER_H + 54)),
	Position = UDim2.new(0, 8, 0, HEADER_H + 50),
	BackgroundTransparency = 1,
}, main)

local function makePage()
	local page = new("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = COL.stroke,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Visible = false,
	}, content)
	new("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, page)
	new("UIPadding", {
		PaddingTop = UDim.new(0, 4),
		PaddingBottom = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 6),
	}, page)
	return page
end

local mainPage = makePage()
local keysPage = makePage()

local currentTab = "main"
local function setTab(name)
	currentTab = name
	mainPage.Visible = (name == "main")
	keysPage.Visible = (name == "keys")
	tabMain.BackgroundColor3 = (name == "main") and COL.accent or COL.panel2
	tabKeys.BackgroundColor3 = (name == "keys") and COL.accent or COL.panel2
end

-- ---- элементы ----
local order = 0
local function nextOrder()
	order = order + 1
	return order
end

local function makeSection(pageObj, key)
	local lbl = new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 22),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		TextColor3 = COL.sub,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = nextOrder(),
	}, pageObj)
	bindText(lbl, function() return t(key) end)
	return lbl
end

local function makeButton(pageObj, onClick)
	local btn = new("TextButton", {
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundColor3 = COL.neutral,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		AutoButtonColor = true,
		LayoutOrder = nextOrder(),
	}, pageObj)
	round(btn, 12)
	new("UIStroke", { Color = COL.stroke, Thickness = 1, Transparency = 0.5 }, btn)
	new("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(185, 185, 185)),
	}, btn)
	btn.MouseButton1Click:Connect(onClick)
	return btn
end

-- ---- красивый переключатель (вкл / выкл) ----
local toggleRefreshers = {}
local TOGGLE_TWEEN = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local PILL_OFF = Color3.fromRGB(30, 8, 20)
local KNOB_OFF = Color3.fromRGB(220, 170, 195)

local function makeToggle(pageObj, nameKey, getState, onClick)
	local row = new("TextButton", {
		Size = UDim2.new(1, 0, 0, 52),
		BackgroundColor3 = COL.panel,
		BackgroundTransparency = 0.3,
		Text = "",
		AutoButtonColor = false,
		BorderSizePixel = 0,
		LayoutOrder = nextOrder(),
	}, pageObj)
	round(row, 14)
	local rowStroke = new("UIStroke", { Color = COL.stroke, Thickness = 1, Transparency = 0.7 }, row)

	local name = new("TextLabel", {
		Size = UDim2.new(1, -92, 0, 22),
		Position = UDim2.new(0, 14, 0, 7),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextColor3 = COL.text,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, row)

	local status = new("TextLabel", {
		Size = UDim2.new(1, -92, 0, 16),
		Position = UDim2.new(0, 14, 0, 28),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		TextSize = 11,
		TextColor3 = COL.sub,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, row)

	local pill = new("Frame", {
		Size = UDim2.new(0, 56, 0, 30),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		BackgroundColor3 = PILL_OFF,
		BorderSizePixel = 0,
	}, row)
	round(pill, 15)
	local pillStroke = new("UIStroke", { Color = COL.accent, Thickness = 1.5, Transparency = 0.8 }, pill)
	new("UIGradient", {
		Rotation = 0,
		Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 190, 215)),
	}, pill)

	local knob = new("Frame", {
		Size = UDim2.new(0, 24, 0, 24),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 3, 0.5, 0),
		BackgroundColor3 = KNOB_OFF,
		BorderSizePixel = 0,
	}, pill)
	round(knob, 12)

	row.MouseButton1Click:Connect(onClick)

	local first = true
	local function refresh()
		local on = getState()
		name.Text = t(nameKey)
		status.Text = on and t("stateOn") or t("stateOff")
		status.TextColor3 = on and COL.accent or COL.sub

		local info = first and TweenInfo.new(0) or TOGGLE_TWEEN
		first = false

		TweenService:Create(knob, info, {
			Position = on and UDim2.new(1, -27, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
			BackgroundColor3 = on and Color3.new(1, 1, 1) or KNOB_OFF,
		}):Play()
		TweenService:Create(pill, info, {
			BackgroundColor3 = on and COL.on or PILL_OFF,
		}):Play()
		TweenService:Create(pillStroke, info, { Transparency = on and 0.1 or 0.8 }):Play()
		TweenService:Create(rowStroke, info, { Transparency = on and 0.15 or 0.7 }):Play()
	end

	table.insert(toggleRefreshers, refresh)
	return row
end

local function makeSlider(pageObj, titleKey, minValue, maxValue, initial, onChange)
	local holder = new("Frame", {
		Size = UDim2.new(1, 0, 0, 52),
		BackgroundColor3 = COL.panel,
		BackgroundTransparency = 0.38,
		BorderSizePixel = 0,
		LayoutOrder = nextOrder(),
	}, pageObj)
	round(holder, 12)
	new("UIStroke", { Color = COL.stroke, Thickness = 1, Transparency = 0.75 }, holder)

	local label = new("TextLabel", {
		Size = UDim2.new(1, -24, 0, 18),
		Position = UDim2.new(0, 12, 0, 6),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		TextSize = 12,
		TextColor3 = COL.text,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, holder)

	local track = new("Frame", {
		Size = UDim2.new(1, -24, 0, 8),
		Position = UDim2.new(0, 12, 0, 34),
		BackgroundColor3 = Color3.fromRGB(30, 8, 20),
		BorderSizePixel = 0,
	}, holder)
	round(track, 8)

	local alpha0 = (initial - minValue) / (maxValue - minValue)
	local fill = new("Frame", {
		Size = UDim2.new(alpha0, 0, 1, 0),
		BackgroundColor3 = COL.accent,
		BorderSizePixel = 0,
	}, track)
	round(fill, 8)

	local knob = new("Frame", {
		Size = UDim2.new(0, 16, 0, 16),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(alpha0, 0, 0.5, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
	}, track)
	round(knob, 8)

	local currentValue = initial
	local sliding = false

	table.insert(langItems, {
		obj = label,
		get = function() return t(titleKey) .. ": " .. currentValue end,
	})
	label.Text = t(titleKey) .. ": " .. currentValue

	local function setFromX(x)
		local absX = track.AbsolutePosition.X
		local width = track.AbsoluteSize.X
		if width <= 0 then return end

		local alpha = math.clamp((x - absX) / width, 0, 1)
		local value = math.floor(minValue + (maxValue - minValue) * alpha + 0.5)
		currentValue = value

		local a = (value - minValue) / (maxValue - minValue)
		fill.Size = UDim2.new(a, 0, 1, 0)
		knob.Position = UDim2.new(a, 0, 0.5, 0)
		label.Text = t(titleKey) .. ": " .. value
		onChange(value)
	end

	-- расширенная зона нажатия (удобно на телефоне)
	local hit = new("TextButton", {
		Size = UDim2.new(1, 0, 0, 30),
		Position = UDim2.new(0, 0, 0, 22),
		BackgroundTransparency = 1,
		Text = "",
	}, holder)

	hit.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			sliding = true
			setFromX(input.Position.X)
		end
	end)

	connect(UserInputService.InputChanged, function(input)
		if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			setFromX(input.Position.X)
		end
	end)

	connect(UserInputService.InputEnded, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			sliding = false
		end
	end)
end

-- ---- главная страница ----
makeSection(mainPage, "secMove")
makeToggle(mainPage, "tgSpeed", function() return speedOn end, toggleSpeed)
makeSlider(mainPage, "sliderSpeed", 50, 500, CONFIG.speed, function(v)
	CONFIG.speed = v
end)
makeSlider(mainPage, "sliderRamp", 1, 20, CONFIG.speedRampTime, function(v)
	CONFIG.speedRampTime = v
end)

local speedReadout = new("TextLabel", {
	Size = UDim2.new(1, 0, 0, 20),
	BackgroundTransparency = 1,
	Font = Enum.Font.Gotham,
	TextSize = 12,
	TextColor3 = COL.sub,
	TextXAlignment = Enum.TextXAlignment.Left,
	LayoutOrder = nextOrder(),
}, mainPage)

makeSection(mainPage, "secFly")
makeToggle(mainPage, "tgFly", function() return flyOn end, toggleFly)
makeSlider(mainPage, "sliderFly", 20, 600, CONFIG.flySpeed, function(v)
	CONFIG.flySpeed = v
end)

local flyRow = new("Frame", {
	Size = UDim2.new(1, 0, 0, 40),
	BackgroundTransparency = 1,
	LayoutOrder = nextOrder(),
}, mainPage)

local function makeHoldButton(posX, key, onState)
	local b = new("TextButton", {
		Size = UDim2.new(0.5, -4, 1, 0),
		Position = UDim2.new(posX, posX == 0 and 0 or 4, 0, 0),
		BackgroundColor3 = COL.panel2,
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		AutoButtonColor = true,
	}, flyRow)
	round(b, 12)
	new("UIStroke", { Color = COL.stroke, Thickness = 1, Transparency = 0.65 }, b)
	bindText(b, function() return t(key) end)
	b.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			onState(true)
		end
	end)
	b.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			onState(false)
		end
	end)
	return b
end

makeHoldButton(0, "flyUp", function(v) flyUp = v end)
makeHoldButton(0.5, "flyDown", function(v) flyDown = v end)

connect(UserInputService.InputEnded, function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		flyUp = false
		flyDown = false
	end
end)

makeSection(mainPage, "secTricks")
local jumpBtn = makeButton(mainPage, function()
	pcall(doJump)
end)
local spinBtn = makeButton(mainPage, toggleSpin)
makeToggle(mainPage, "tgAutoSpin", function() return autoSpinOn end, function()
	toggleAutoSpin()
end)
makeToggle(mainPage, "tgWheelie", function() return autoWheelieOn end, function()
	toggleWheelie()
end)

makeSection(mainPage, "secSettings")
makeSlider(mainPage, "sliderJump", 10, 150, CONFIG.jumpPower, function(v)
	CONFIG.jumpPower = v
end)
makeSlider(mainPage, "sliderSpin", 5, 120, CONFIG.spinSpeed, function(v)
	CONFIG.spinSpeed = v
end)

local hint = new("TextLabel", {
	Size = UDim2.new(1, 0, 0, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundTransparency = 1,
	Font = Enum.Font.Gotham,
	TextSize = 11,
	TextColor3 = COL.sub,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	TextWrapped = true,
	LayoutOrder = nextOrder(),
}, mainPage)
bindText(hint, function() return t("hint") end)

-- ---- страница клавиш ----
order = 0
local keysTip = new("TextLabel", {
	Size = UDim2.new(1, 0, 0, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundTransparency = 1,
	Font = Enum.Font.Gotham,
	TextSize = 12,
	TextColor3 = COL.sub,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	TextWrapped = true,
	LayoutOrder = nextOrder(),
}, keysPage)
bindText(keysTip, function() return t("keysTip") end)

local keyRows = {
	{ action = "jump", titleKey = "keyJump" },
	{ action = "spin", titleKey = "keySpin" },
	{ action = "autospin", titleKey = "keyAutoSpin" },
	{ action = "wheelie", titleKey = "keyWheelie" },
	{ action = "speed", titleKey = "keySpeed" },
	{ action = "fly", titleKey = "keyFly" },
}

local binds = { jump = nil, spin = nil, autospin = nil, wheelie = nil, speed = nil, fly = nil }
local bindButtons = {}
local listening = nil

local function refreshBindButtons()
	for action, b in pairs(bindButtons) do
		if listening == action then
			b.Text = t("pressKey")
			b.BackgroundColor3 = COL.orange
		else
			local key = binds[action]
			b.Text = key and key.Name or "—"
			b.BackgroundColor3 = key and COL.blue or COL.panel2
		end
	end
end

for _, row in ipairs(keyRows) do
	local holder = new("Frame", {
		Size = UDim2.new(1, 0, 0, 42),
		BackgroundColor3 = COL.panel,
		BackgroundTransparency = 0.38,
		BorderSizePixel = 0,
		LayoutOrder = nextOrder(),
	}, keysPage)
	round(holder, 12)
	new("UIStroke", { Color = COL.stroke, Thickness = 1, Transparency = 0.75 }, holder)

	local lbl = new("TextLabel", {
		Size = UDim2.new(0.5, -12, 1, 0),
		Position = UDim2.new(0, 12, 0, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		TextColor3 = COL.text,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, holder)
	bindText(lbl, function() return t(row.titleKey) end)

	local b = new("TextButton", {
		Size = UDim2.new(0, 130, 0, 28),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		BackgroundColor3 = COL.panel2,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
	}, holder)
	round(b, 8)

	b.MouseButton1Click:Connect(function()
		listening = row.action
		refreshBindButtons()
	end)

	bindButtons[row.action] = b
end

-- ---- обновление интерфейса ----
local function setToggle(btn, on, onKey, offKey, offColor)
	btn.Text = t(on and onKey or offKey)
	btn.BackgroundColor3 = on and COL.on or offColor
end

updateUI = function()
	if not gui or not gui.Parent then return end

	for _, item in ipairs(langItems) do
		item.obj.Text = item.get()
	end

	for _, refresh in ipairs(toggleRefreshers) do
		refresh()
	end

	jumpBtn.Text = t("jump")
	jumpBtn.BackgroundColor3 = COL.blue

	if spinning then
		spinBtn.Text = t("spinActive")
		spinBtn.BackgroundColor3 = COL.on
	else
		spinBtn.Text = t("spin")
		spinBtn.BackgroundColor3 = COL.pink
	end

	langRU.BackgroundColor3 = (currentLang == "ru") and COL.accent or COL.panel2
	langEN.BackgroundColor3 = (currentLang == "en") and COL.accent or COL.panel2

	refreshBindButtons()
end

local function setLang(l)
	currentLang = l
	updateUI()
end

langRU.MouseButton1Click:Connect(function() setLang("ru") end)
langEN.MouseButton1Click:Connect(function() setLang("en") end)
tabMain.MouseButton1Click:Connect(function() setTab("main") end)
tabKeys.MouseButton1Click:Connect(function() setTab("keys") end)

-- ---- сворачивание ----
local minimized = false
minBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	tabBar.Visible = not minimized
	content.Visible = not minimized
	main.Size = UDim2.new(0, WIN_W, 0, minimized and MIN_H or WIN_H)
	minBtn.Text = minimized and "+" or "–"
end)

-- ---- плавное перетаскивание ----
local dragging = false
local dragStart, dragStartAbs
local targetPos = main.Position

banner.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		dragStartAbs = main.AbsolutePosition
		targetPos = UDim2.fromOffset(dragStartAbs.X, dragStartAbs.Y)
	end
end)

connect(UserInputService.InputChanged, function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		local vp = gui.AbsoluteSize
		local x = math.clamp(dragStartAbs.X + delta.X, -WIN_W + 90, vp.X - 90)
		local y = math.clamp(dragStartAbs.Y + delta.Y, 0, vp.Y - 40)
		targetPos = UDim2.fromOffset(x, y)
	end
end)

connect(UserInputService.InputEnded, function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

-- окно «догоняет» курсор с плавным замедлением
connect(RunService.RenderStepped, function(dt)
	if not gui or not gui.Parent then return end
	local alpha = 1 - math.exp(-dt * 16)
	main.Position = main.Position:Lerp(targetPos, alpha)
end)

-- ---- показ текущей скорости ----
local readoutTimer = 0
connect(RunService.Heartbeat, function(dt)
	if not gui or not gui.Parent then return end
	readoutTimer = readoutTimer + dt
	if readoutTimer < 0.25 then return end
	readoutTimer = 0
	if currentTab == "main" and not minimized then
		speedReadout.Text = t("speedNow") .. ": " .. math.floor(rideSpeed() + 0.5)
	end
end)

-- ---- горячие клавиши ----
connect(UserInputService.InputBegan, function(input, gameProcessed)
	if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

	if listening and input.KeyCode == Enum.KeyCode.Escape then
		listening = nil
		refreshBindButtons()
		return
	end

	if gameProcessed then return end

	if listening then
		local action = listening
		listening = nil
		if input.KeyCode == Enum.KeyCode.Backspace then
			binds[action] = nil
		else
			binds[action] = input.KeyCode
		end
		refreshBindButtons()
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
			elseif action == "fly" then
				toggleFly()
			end
			break
		end
	end
end)

-- ---- закрытие ----
local function cleanup()
	speedOn = false
	flyOn = false
	pcall(flyRelease)
	autoSpinOn = false
	autoWheelieOn = false
	pcall(releaseRideKeys)
	if spinning then
		pcall(spinStop)
	end
	for _, c in ipairs(conns) do
		pcall(function() c:Disconnect() end)
	end
	conns = {}
	if gui then
		pcall(function() gui:Destroy() end)
	end
end

_G.__bebrackaCleanup = cleanup
closeBtn.MouseButton1Click:Connect(cleanup)

setTab("main")
updateUI()

print("[bebracka client] loaded: SPEED / FLY / JUMP / SPIN / AUTOSPIN / WHEELIE / BINDS / RU-EN")
