-- ============================================================
--  EvaK GAMEPLAY  (LocalScript)
--  Куда положить: StarterPlayer > StarterPlayerScripts > LocalScript
--  Делает: вид от первого лица (видно тело, если глянуть вниз), свои анимации
--  ходьбы/бега/прыжка/приседа для ВСЕХ персонажей, покачивание камеры,
--  управление (бег включается сам, C/Ctrl = присед) и щупальца по краям экрана.
--  Включается, когда закрывается меню (атрибут IntroDone).
-- ============================================================

local CFG = {
	BaseFov = 75,
	SprintFovAdd = 14,

	-- ВСТАВЬ СВОИ ID звуков (rbxassetid://...). Пусто = без звука (виньетка дыхания всё равно работает)
	BreathSoundId = "rbxassetid://9125852506",     -- дыхание на фоне (зацикленное, громче и быстрее на бегу)
	BreathVolume = 0.5,
	LandSoundId = "rbxassetid://131513516",     -- запасной: rbxassetid://18358956642       -- удар при приземлении
	WarnSoundId = "rbxassetid://9119864327",       -- монстр приближается
	ScareSoundId = "rbxassetid://1835326487",      -- скример

	-- щупальца: пауза между появлениями (сек) по сложности
	TentacleEvery = {
		easy   = { 12, 20 },
		normal = { 9, 15 },
		hard   = { 6, 11 },
		insane = { 4, 8 },
		newyear = { 4, 8 },
	},
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera
local rng = Random.new()
local move = ReplicatedStorage:WaitForChild("EvaKMove", 8)   -- nil = нет серверного скрипта (тестовый режим)

-- ============================================================
-- АНИМАЦИИ (процедурные, R15). Работают для всех персонажей на каждом клиенте.
-- ============================================================
local states = setmetatable({}, { __mode = "k" })
local fpOn = false
local heldOn = false   -- в руке предмет (фонарь/батончик) -> правая рука поднята вперёд
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function joint(char: Model, part: string, name: string): Motor6D?
	local p = char:FindFirstChild(part)
	local m = p and p:FindFirstChild(name)
	return m and m:IsA("Motor6D") and m or nil
end

local function getState(char: Model)
	local st = states[char]
	if st then return st end
	local j = {
		Root = joint(char, "LowerTorso", "Root"), Waist = joint(char, "UpperTorso", "Waist"), Neck = joint(char, "Head", "Neck"),
		RS = joint(char, "RightUpperArm", "RightShoulder"), LS = joint(char, "LeftUpperArm", "LeftShoulder"),
		RE = joint(char, "RightLowerArm", "RightElbow"), LE = joint(char, "LeftLowerArm", "LeftElbow"),
		RH = joint(char, "RightUpperLeg", "RightHip"), LH = joint(char, "LeftUpperLeg", "LeftHip"),
		RK = joint(char, "RightLowerLeg", "RightKnee"), LK = joint(char, "LeftLowerLeg", "LeftKnee"),
	}
	if not j.Root or not j.Waist then return nil end   -- не R15
	st = { j = j, phase = 0, air = 0, crouch = 0, land = 0, hs = 0, sprintK = 0, wasAir = false, lastVy = 0, roll = 0 }
	states[char] = st
	return st
end

local function setT(m: Motor6D?, cf: CFrame)
	if m then m.Transform = cf end
end

local function pose(char: Model, st, dt: number, t: number)
	local hrp = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum or hum.Health <= 0 then return end

	local v = hrp.AssemblyLinearVelocity
	local hs = Vector3.new(v.X, 0, v.Z).Magnitude
	rayParams.FilterDescendantsInstances = { char }
	local airborne = workspace:Raycast(hrp.Position, Vector3.new(0, -(hum.HipHeight + 3.2), 0), rayParams) == nil

	st.air += ((airborne and 1 or 0) - st.air) * (1 - math.exp(-14 * dt))
	local crouching = char:GetAttribute("Crouch") == true
	st.crouch += ((crouching and 1 or 0) - st.crouch) * (1 - math.exp(-10 * dt))
	if st.wasAir and not airborne and st.lastVy < -14 then
		st.land = math.clamp(-st.lastVy / 50, 0.3, 1)
	end
	st.land = math.max(0, st.land - dt * 3.2)
	st.wasAir, st.lastVy = airborne, v.Y
	st.hs += (hs - st.hs) * (1 - math.exp(-10 * dt))

	local sp = st.hs
	local amp = math.clamp(sp / 10, 0, 1)
	local sprintK = math.clamp((sp - 12) / 14, 0, 1)
	st.sprintK = sprintK
	st.phase += dt * sp * 0.62
	local ph = st.phase
	local a, c, land, gnd = st.air, st.crouch, st.land, 1 - st.air
	local riseK, fallK = math.clamp(v.Y / 30, 0, 1), math.clamp(-v.Y / 40, 0, 1)
	local s = math.sin(ph)

	-- ноги (hip: + вперёд; knee: - сгибает назад)
	local legAmp = (0.15 + 0.75 * amp + 0.45 * sprintK) * (1 - 0.55 * c) * gnd
	local bendAmp = 0.7 * amp + 0.5 * sprintK
	local hipL, hipR = s * legAmp, -s * legAmp
	local kneeL = -(0.08 + math.max(0, math.cos(ph)) * bendAmp) * gnd
	local kneeR = -(0.08 + math.max(0, -math.cos(ph)) * bendAmp) * gnd
	-- руки (противоход ногам)
	local isMe0 = (char == player.Character)
	local fp = isMe0 and fpOn
	local armAmp = (0.1 + 0.8 * amp + 0.4 * sprintK) * (1 - 0.4 * c) * gnd
	if fp then armAmp = (0.25 + 0.5 * amp + 0.3 * sprintK) * gnd end
	local shL, shR = -s * armAmp, s * armAmp
	local elbow = 0.25 + 0.2 * amp + 1.2 * sprintK
	local spread = 0.05
	if fp then
		-- руки выставлены вперёд-вниз, чтобы быть видны у нижних углов экрана и качаться при ходьбе
		shL, shR = shL + 0.62 * gnd + math.sin(t * 1.25) * 0.035, shR + 0.62 * gnd + math.sin(t * 1.25 + 1.3) * 0.035   -- дыхание рук
		elbow = elbow + 0.85 * gnd
		spread = spread + 0.12 + math.sin(t * 0.9) * 0.02
	end

	-- воздух: прыжок / падение
	hipL = hipL + (0.2 + 0.6 * riseK - hipL) * a
	hipR = hipR + (-0.15 - 0.2 * fallK - hipR) * a
	kneeL = kneeL + (-1.0 - kneeL) * a
	kneeR = kneeR + (-0.35 - kneeR) * a
	shL = shL + (0.35 + 2.2 * riseK - shL) * a
	shR = shR + (0.35 + 2.2 * riseK - shR) * a
	elbow = elbow + (0.4 - elbow) * a
	spread = spread + (0.3 + fallK * 1.0) * a

	-- присед
	local rootY = -0.12 * c - 0.45 * land - (0.5 - 0.5 * math.cos(ph * 2)) * 0.06 * amp * gnd
	hipL, hipR = hipL + 1.25 * c + 0.55 * land, hipR + 1.25 * c + 0.55 * land
	kneeL, kneeR = kneeL - 1.85 * c - 0.9 * land, kneeR - 1.85 * c - 0.9 * land
	shL, shR = shL + 0.3 * c, shR + 0.3 * c

	-- корпус
	local lean = -(0.1 * amp + 0.28 * sprintK) * gnd - 0.4 * c - 0.2 * land
	local twist = s * 0.12 * amp * gnd
	local breathe = math.sin(t * 1.6) * 0.015

	-- предмет в руке: правая рука плавно поднимается вперёд (видна от первого лица)
	local isMe = (char == player.Character)
	local holding = (isMe and heldOn) or char:FindFirstChildOfClass("Tool") ~= nil
	st.tool = (st.tool or 0) + ((holding and 1 or 0) - (st.tool or 0)) * (1 - math.exp(-9 * dt))
	local tk = st.tool
	local elbowR, spreadR = elbow, spread
	if tk > 0.01 then
		shR = shR + (1.25 + math.sin(t * 1.4) * 0.025 + s * 0.04 * amp - shR) * tk
		elbowR = elbow + (0.75 - elbow) * tk
		spreadR = spread * (1 - tk) - 0.1 * tk
	end

	local j = st.j
	setT(j.Root, CFrame.new(0, rootY, 0))
	setT(j.Waist, CFrame.Angles(lean + breathe, twist, 0))
	setT(j.Neck, CFrame.Angles(-lean * 0.7, -twist * 0.6, 0))
	setT(j.LH, CFrame.Angles(hipL, 0, -0.02))
	setT(j.RH, CFrame.Angles(hipR, 0, 0.02))
	setT(j.LK, CFrame.Angles(kneeL, 0, 0))
	setT(j.RK, CFrame.Angles(kneeR, 0, 0))
	setT(j.LS, CFrame.Angles(shL, 0, -spread))
	setT(j.RS, CFrame.Angles(shR, 0, spreadR))
	setT(j.LE, CFrame.Angles(elbow, 0, 0))
	setT(j.RE, CFrame.Angles(elbowR, 0, 0))
end

RunService.RenderStepped:Connect(function(dt)
	local t = os.clock()
	for _, plr in Players:GetPlayers() do
		local char = plr.Character
		if char then
			local st = getState(char)
			if st then pose(char, st, dt, t) end
		end
	end
end)

-- ============================================================
-- УПРАВЛЕНИЕ: бег сам, C / Ctrl = присед (удержание)
-- ============================================================
local sprintHeld, crouchHeld = false, false
local fbMoveT = 0
local fbSpeed = 7   -- запасной разгон, если нет серверного скрипта

local function setSprint(v: boolean)
	if sprintHeld == v then return end
	sprintHeld = v
	if move then move:FireServer("Sprint", v) end
end
local function setCrouch(v: boolean)
	if crouchHeld == v then return end
	crouchHeld = v
	if move then
		move:FireServer("Crouch", v)
	elseif player.Character then
		player.Character:SetAttribute("Crouch", v)
	end
end

UIS.InputBegan:Connect(function(input, processed)
	if processed then return end
	local k = input.KeyCode
	if k == Enum.KeyCode.LeftShift or k == Enum.KeyCode.ButtonL3 then setSprint(true)
	elseif k == Enum.KeyCode.C or k == Enum.KeyCode.LeftControl or k == Enum.KeyCode.RightControl or k == Enum.KeyCode.ButtonB then
		if player:GetAttribute("EvaKToggleCrouch") == true then setCrouch(not crouchHeld) else setCrouch(true) end
	end
end)
UIS.InputEnded:Connect(function(input)
	local k = input.KeyCode
	if k == Enum.KeyCode.LeftShift or k == Enum.KeyCode.ButtonL3 then setSprint(false)
	elseif k == Enum.KeyCode.C or k == Enum.KeyCode.LeftControl or k == Enum.KeyCode.RightControl or k == Enum.KeyCode.ButtonB then
		if player:GetAttribute("EvaKToggleCrouch") ~= true then setCrouch(false) end
	end
end)

player.CharacterAdded:Connect(function()
	sprintHeld, crouchHeld = false, false
	fbSpeed = 10
end)

-- запасное движение (без сервера): тот же разгон
RunService.Heartbeat:Connect(function(dt)
	if move then return end
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return end
	local moving = hum.MoveDirection.Magnitude > 0.1
	fbMoveT = moving and fbMoveT + dt or 0
	local target = crouchHeld and 5 or ((moving and fbMoveT > 0.8) and 26 or 7)
	local step = (target > fbSpeed and 18 or 40) * dt
	fbSpeed = fbSpeed < target and math.min(target, fbSpeed + step) or math.max(target, fbSpeed - step)
	hum.WalkSpeed = fbSpeed * (player:GetAttribute("SpeedMult") or 1)
	if player:GetAttribute("EvaKAdminSpeed") then hum.WalkSpeed = player:GetAttribute("EvaKAdminSpeed") end   -- скорость из админки
	hum.UseJumpPower = false
	hum.JumpHeight = crouchHeld and 0 or 7.5
end)

local touchGui: ScreenGui? = nil
-- кнопки для телефона
local function touchButtons()
	if not UIS.TouchEnabled then return end
	local g = Instance.new("ScreenGui")
	g.Name = "EvaKTouch"; g.ResetOnSpawn = false; g.DisplayOrder = 40
	g.Parent = playerGui
	touchGui = g
	local function mk(label: string, y: number, onDown: () -> (), onUp: () -> ())
		local b = Instance.new("TextButton")
		b.AnchorPoint = Vector2.new(1, 1)
		b.Position = UDim2.new(1, -150, 1, y)
		b.Size = UDim2.fromOffset(78, 78)
		b.BackgroundColor3 = Color3.fromRGB(20, 14, 10)
		b.BackgroundTransparency = 0.25
		b.Text = label; b.TextSize = 14; b.Font = Enum.Font.Arcade
		b.TextColor3 = Color3.fromRGB(246, 226, 182)
		b.AutoButtonColor = false
		b.Parent = g
		local st = Instance.new("UIStroke"); st.Color = Color3.fromRGB(150, 112, 62); st.Thickness = 1.5; st.Parent = b
		b.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch then onDown() end end)
		b.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch then onUp() end end)
	end
	mk("RUN", -110, function() setSprint(true) end, function() setSprint(false) end)
	mk("SNEAK", -20, function() setCrouch(true) end, function() setCrouch(false) end)
end

-- ============================================================
-- КАМЕРА ОТ ПЕРВОГО ЛИЦА
-- ============================================================
local active = false
local dropping, shakeAmt = false, 0
local chaseUntil = 0   -- пока монстр летит сзади, щупальца лезут чаще
local tentGui: ScreenGui? = nil

-- до камеры: покачивание (CameraOffset)
RunService:BindToRenderStep("EvaKCamPre", Enum.RenderPriority.Camera.Value - 1, function(dt)
	fpOn = active
	if not active then return end
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local st = char and states[char]
	if not hum or not st then return end
	if not st.sleeves then   -- рукава тёмной куртки + кожаные перчатки (руки от первого лица)
		st.sleeves = true
		for _, side in { "Left", "Right" } do
			for _, nm in { "UpperArm", "LowerArm" } do
				local bp = char:FindFirstChild(side .. nm)
				if bp and bp:IsA("BasePart") then bp.Color = Color3.fromRGB(38, 30, 28); bp.Material = Enum.Material.Fabric end
			end
			local h = char:FindFirstChild(side .. "Hand")
			if h and h:IsA("BasePart") then h.Color = Color3.fromRGB(22, 18, 16); h.Material = Enum.Material.Fabric end
		end
	end
	local amp = math.clamp(st.hs / 10, 0, 1)
	local y = -0.38 * st.crouch - 0.5 * st.land + (0.5 - 0.5 * math.cos(st.phase * 2)) * 0.07 * amp * (1 + st.sprintK * 0.8) * (1 - st.air)
	local x = math.sin(st.phase) * 0.045 * amp
	-- взгляд вниз: камера сдвигается вперёд и вверх, чтобы были видны ноги
	local down = math.clamp(-camera.CFrame.LookVector.Y, 0, 1)
	y += 0.25 * down
	hum.CameraOffset = hum.CameraOffset:Lerp(Vector3.new(x, y, -1.6 * down * down), 1 - math.exp(-11 * dt))
end)

-- после камеры: FOV, наклон на стрейфе, тряска на бегу, видимость тела
RunService:BindToRenderStep("EvaKCamPost", Enum.RenderPriority.Camera.Value + 1, function(dt)
	local _ = dt
	if not active then return end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local st = char and states[char]
	if not char or not hrp or not st then return end

	camera.FieldOfView += ((player:GetAttribute("EvaKFov") and (60 + player:GetAttribute("EvaKFov") * 40) or CFG.BaseFov) + CFG.SprintFovAdd * st.sprintK + (dropping and 22 or 0) - camera.FieldOfView) * (1 - math.exp(-6 * dt))

	local strafe = hrp.AssemblyLinearVelocity:Dot(camera.CFrame.RightVector) / 24
	st.roll += (-strafe * 0.05 - st.roll) * (1 - math.exp(-8 * dt))
	local t = os.clock()
	local shake = st.sprintK * 0.004
	local sh = shake + shakeAmt * 0.05
	local dropRoll = dropping and math.sin(t * 2.2) * 0.14 or 0
	camera.CFrame = camera.CFrame * CFrame.Angles(math.noise(t * 9, 0) * sh, math.noise(0, t * 9) * sh, st.roll + dropRoll)

end)

-- голова скрыта, всё остальное (руки, ноги, торс) видно; после всех камерных скриптов
RunService:BindToRenderStep("EvaKBodyVis", Enum.RenderPriority.Last.Value + 1, function()
	if not active then return end
	local char = player.Character
	if not char then return end
	for _, d in char:GetDescendants() do
		if d:IsA("BasePart") then
			local hide = d.Name == "Head" or d.Name == "BlockHead" or d.Name == "EvaKSkinPart" or d.Name == "HumanoidRootPart"
				or d:FindFirstAncestorOfClass("Accessory") ~= nil   -- волосы, шапки и прочие аксессуары скрыты
			if d:FindFirstAncestor("EvaKHeld") ~= nil then
				hide = false
			elseif not hide and d:FindFirstAncestorOfClass("Tool") == nil then
				-- видны только руки/кисти; торс и ноги скрыты (неудобно закрывают экран)
				local n = d.Name
				hide = not (n:find("Arm") or n:find("Hand"))
			end
			d.LocalTransparencyModifier = hide and 1 or 0
		end
	end
end)

-- ПРИЦЕЛ-ТОЧКА вместо курсора
do
	local cg = Instance.new("ScreenGui")
	cg.Name = "EvaKCrosshair"; cg.IgnoreGuiInset = true; cg.ResetOnSpawn = false
	cg.DisplayOrder = 40; cg.Parent = playerGui
	local dot = Instance.new("Frame")
	dot.AnchorPoint = Vector2.new(0.5, 0.5); dot.Position = UDim2.fromScale(0.5, 0.5)
	dot.Size = UDim2.fromOffset(5, 5); dot.BackgroundColor3 = Color3.new(1, 1, 1)
	dot.BackgroundTransparency = 0.1; dot.BorderSizePixel = 0; dot.Visible = false; dot.Parent = cg
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1, 0); c.Parent = dot
	local st = Instance.new("UIStroke"); st.Color = Color3.new(0, 0, 0); st.Transparency = 0.4; st.Parent = dot
	local PPS = game:GetService("ProximityPromptService")
	local shown = 0
	PPS.PromptShown:Connect(function() shown += 1 end)
	PPS.PromptHidden:Connect(function() shown = math.max(0, shown - 1) end)
	local size = 5
	RunService.RenderStepped:Connect(function(dt)
		local on = active and UIS.MouseBehavior == Enum.MouseBehavior.LockCenter
		dot.Visible = on
		if on then UIS.MouseIconEnabled = false end
		local target = shown > 0 and 10 or 5   -- рядом можно нажать E: точка чуть увеличивается
		size += (target - size) * (1 - math.exp(-14 * dt))
		dot.Size = UDim2.fromOffset(size, size)
		dot.BackgroundTransparency = shown > 0 and 0 or 0.1
		dot.BackgroundColor3 = shown > 0 and Color3.fromRGB(255, 236, 190) or Color3.new(1, 1, 1)
	end)
end

-- ============================================================
-- ПРЕДМЕТ В РУКЕ (от первого лица): фонарь / батончик из RunItems
-- ============================================================
do
	local curKind: string? = nil
	local model: Model? = nil
	local function clear()
		if model then model:Destroy(); model = nil end
	end
	local function weldTo(hand: BasePart, p: BasePart, cf: CFrame)
		p.Anchored = false; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.Massless = true
		p.CFrame = hand.CFrame * cf
		local w = Instance.new("WeldConstraint"); w.Part0 = hand; w.Part1 = p; w.Parent = p
	end
	local function mk(m: Model, size: Vector3, color: Color3, mat: Enum.Material): Part
		local p = Instance.new("Part"); p.Size = size; p.Color = color; p.Material = mat; p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = m
		return p
	end
	local function build(kind: string, hand: BasePart)
		local m = Instance.new("Model"); m.Name = "EvaKHeld"
		if kind == "LANTERN" then
			local body = mk(m, Vector3.new(0.7, 1.0, 0.7), Color3.fromRGB(255, 150, 70), Enum.Material.Neon)
			weldTo(hand, body, CFrame.new(0, -0.9, -0.9))
			local top = mk(m, Vector3.new(0.9, 0.2, 0.9), Color3.fromRGB(30, 22, 18), Enum.Material.Metal)
			weldTo(hand, top, CFrame.new(0, -0.3, -0.9))
			local bot = mk(m, Vector3.new(0.9, 0.2, 0.9), Color3.fromRGB(30, 22, 18), Enum.Material.Metal)
			weldTo(hand, bot, CFrame.new(0, -1.5, -0.9))
			local ring = mk(m, Vector3.new(0.12, 0.12, 0.7), Color3.fromRGB(30, 22, 18), Enum.Material.Metal)
			weldTo(hand, ring, CFrame.new(0, -0.15, -0.9))
		else   -- BAR
			local bar = mk(m, Vector3.new(0.5, 0.35, 1.5), Color3.fromRGB(120, 70, 36), Enum.Material.SmoothPlastic)
			weldTo(hand, bar, CFrame.new(0, -0.5, -0.9))
			local wrap = mk(m, Vector3.new(0.56, 0.2, 0.9), Color3.fromRGB(200, 40, 36), Enum.Material.SmoothPlastic)
			weldTo(hand, wrap, CFrame.new(0, -0.5, -0.9))
		end
		m.Parent = player.Character
		return m
	end
	local function barEaten() return player:GetAttribute("EvaKBarUsed") == true end
	local function refresh()
		local char = player.Character
		local hand = char and (char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm"))
		local items = "," .. tostring(player:GetAttribute("RunItems") or "") .. ","
		local want: string? = nil
		if active and hand then
			if string.find(items, ",LANTERN,", 1, true) then want = "LANTERN"
			elseif string.find(items, ",BAR,", 1, true) and not barEaten() then want = "BAR" end
		end
		heldOn = want ~= nil
		if want == "LANTERN" and model then   -- фонарь тускнеет, если его выключили (клавиша из HUD)
			local hrp0 = char and char:FindFirstChild("HumanoidRootPart")
			local l = hrp0 and hrp0:FindFirstChild("EvaKLantern")
			local body = model:FindFirstChildWhichIsA("Part")
			if body and l then body.Material = l.Enabled and Enum.Material.Neon or Enum.Material.SmoothPlastic end
		end
		if want ~= curKind or (want and (not model or not model.Parent)) then
			clear(); curKind = want
			if want and hand then model = build(want, hand :: BasePart) end
		end
	end
	player:GetAttributeChangedSignal("RunItems"):Connect(function() player:SetAttribute("EvaKBarUsed", false); refresh() end)
	player:GetAttributeChangedSignal("EvaKBarUsed"):Connect(refresh)
	player.CharacterAdded:Connect(function() curKind = nil; model = nil end)
	task.spawn(function()
		while true do task.wait(0.5); pcall(refresh) end
	end)
end

-- ============================================================
-- ЩУПАЛЬЦА по краям экрана (справа, слева, сверху, снизу)
-- ============================================================
local function startTentacles()
	local g = Instance.new("ScreenGui")
	g.Name = "EvaKTentacles"; g.IgnoreGuiInset = true; g.ResetOnSpawn = false
	g.DisplayOrder = 30; g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	g.Parent = playerGui
	tentGui = g

	local N = 22
	local function spawnTentacle(edge: number)
		local vp = g.AbsoluteSize
		local along = rng:NextNumber(0.15, 0.85)
		local base, dir
		if edge == 1 then base, dir = Vector2.new(-50, vp.Y * along), Vector2.new(1, 0)
		elseif edge == 2 then base, dir = Vector2.new(vp.X + 50, vp.Y * along), Vector2.new(-1, 0)
		elseif edge == 3 then base, dir = Vector2.new(vp.X * along, -50), Vector2.new(0, 1)
		else base, dir = Vector2.new(vp.X * along, vp.Y + 50), Vector2.new(0, -1) end
		local perp = Vector2.new(-dir.Y, dir.X)
		local span = (edge <= 2) and vp.X or vp.Y
		local reach = rng:NextNumber(0.24, 0.42) * span
		local bend = rng:NextNumber(-0.25, 0.25) * reach
		local thickBase = math.clamp(span * 0.035, 22, 46)
		local life = rng:NextNumber(2.4, 3.8)
		local seed = rng:NextNumber(0, 6.28)

		local frames, dots = {}, {}
		for i = 1, N do
			local f = Instance.new("Frame")
			f.AnchorPoint = Vector2.new(0.5, 0.5)
			f.BackgroundColor3 = Color3.fromRGB(9, 6, 13)
			f.BorderSizePixel = 0
			f.ZIndex = N - i
			f.Parent = g
			local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1, 0); c.Parent = f
			local st = Instance.new("UIStroke"); st.Color = Color3.fromRGB(88, 52, 140); st.Thickness = 1; st.Transparency = 0.4; st.Parent = f
			if i % 3 == 0 then   -- светящиеся присоски
				local d = Instance.new("Frame")
				d.AnchorPoint = Vector2.new(0.5, 0.5); d.Position = UDim2.fromScale(0.5, 0.5)
				d.Size = UDim2.fromOffset(4, 4); d.BorderSizePixel = 0
				d.BackgroundColor3 = Color3.fromRGB(205, 140, 255)
				d.Parent = f
				local dc = Instance.new("UICorner"); dc.CornerRadius = UDim.new(1, 0); dc.Parent = d
				table.insert(dots, d)
			end
			frames[i] = f
		end

		local t0 = os.clock()
		local conn: RBXScriptConnection
		conn = RunService.RenderStepped:Connect(function()
			local age = os.clock() - t0
			if age >= life then
				conn:Disconnect()
				for _, f in frames do f:Destroy() end
				return
			end
			local ext
			if age < 0.7 then
				ext = TweenService:GetValue(age / 0.7, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			elseif age < life - 0.8 then
				ext = 1 + 0.04 * math.sin(age * 6)
			else
				ext = 1 - TweenService:GetValue((age - (life - 0.8)) / 0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			end

			local pts = {}
			for i = 0, N do
				local s = i / N
				local sway = math.sin(age * 3 + s * 5 + seed) * reach * 0.12 * s * (0.5 + ext * 0.5)
				local curl = math.sin(age * 4 + seed) * reach * 0.08 * s * s * s
				pts[i] = base + dir * (reach * ext * s) + perp * (sway + curl + bend * s * s)
			end
			for i = 1, N do
				local a, b = pts[i - 1], pts[i]
				local mid, diff = (a + b) / 2, b - a
				local s = i / N
				local thick = thickBase + (7 - thickBase) * s
				local f = frames[i]
				f.Position = UDim2.fromOffset(mid.X, mid.Y)
				f.Size = UDim2.fromOffset(diff.Magnitude + thick * 0.7, thick)
				f.Rotation = math.deg(math.atan2(diff.Y, diff.X))
			end
			for k, d in dots do
				d.BackgroundTransparency = 0.25 + 0.5 * math.abs(math.sin(age * 5 + k))
			end
		end)
	end

	task.spawn(function()
		local last = 0
		while g.Parent do
			local range = CFG.TentacleEvery[player:GetAttribute("Difficulty") or "easy"] or CFG.TentacleEvery.easy
			if os.clock() < chaseUntil then
				task.wait(rng:NextNumber(0.25, 0.7))
			else
				task.wait(rng:NextNumber(range[1], range[2]))
			end
			if not g.Parent then break end
			local edge = rng:NextInteger(1, 4)
			if edge == last then edge = edge % 4 + 1 end
			last = edge
			spawnTentacle(edge)
			if rng:NextNumber() < 0.3 then   -- иногда сразу два с разных сторон
				task.wait(rng:NextNumber(0.3, 0.9))
				spawnTentacle(edge % 4 + 1)
			end
		end
	end)
end

-- ============================================================
-- Подсказка управления
-- ============================================================
local function showHint()
	local g = Instance.new("ScreenGui")
	g.Name = "EvaKHint"; g.ResetOnSpawn = false; g.DisplayOrder = 25
	g.Parent = playerGui
	local l = Instance.new("TextLabel")
	l.AnchorPoint = Vector2.new(0, 1); l.Position = UDim2.new(0, 16, 1, -16); l.Size = UDim2.fromOffset(560, 22)
	l.BackgroundTransparency = 1; l.Font = Enum.Font.Arcade; l.TextSize = 13
	l.TextColor3 = Color3.fromRGB(246, 226, 182); l.TextXAlignment = Enum.TextXAlignment.Left
	l.Text = "[W] RUN   [C] CROUCH   [SPACE] JUMP   [E] DOOR / SEARCH / HIDE   [TAB] MENU"
	l.Parent = g
	task.delay(10, function()
		TweenService:Create(l, TweenInfo.new(1), { TextTransparency = 1 }):Play()
		task.delay(1.2, function() g:Destroy() end)
	end)
end

-- ============================================================
-- ЭФФЕКТЫ: дыхание, виньетка, падение, монстр, клик
-- ============================================================
local SoundService = game:GetService("SoundService")
local GuiService = game:GetService("GuiService")
local world = ReplicatedStorage:WaitForChild("EvaKWorld", 8)   -- nil = нет EvaKMap

local fxGui = Instance.new("ScreenGui")
fxGui.Name = "EvaKFx"; fxGui.IgnoreGuiInset = true; fxGui.ResetOnSpawn = false
fxGui.DisplayOrder = 35; fxGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
fxGui.Parent = playerGui

local function sfxPlay(id: string, vol: number?)
	if id == "" then return end
	local snd = Instance.new("Sound")
	snd.SoundId = id; snd.Volume = vol or 0.8
	snd.Parent = SoundService
	snd:Play()
	snd.Ended:Once(function() snd:Destroy() end)
end

-- виньетка (пульсирует в такт дыханию)
local vig = {}
local function edge(pos: UDim2, size: UDim2, anchor: Vector2, rot: number)
	local f = Instance.new("Frame")
	f.Position, f.Size, f.AnchorPoint = pos, size, anchor
	f.BackgroundColor3 = Color3.new(0, 0, 0); f.BorderSizePixel = 0; f.BackgroundTransparency = 1; f.ZIndex = 1
	f.Parent = fxGui
	local gr = Instance.new("UIGradient")
	gr.Rotation = rot; gr.Transparency = NumberSequence.new(0, 1)
	gr.Parent = f
	table.insert(vig, f)
end
edge(UDim2.fromScale(0, 0), UDim2.new(1, 0, 0.35, 0), Vector2.new(0, 0), 90)
edge(UDim2.fromScale(0, 1), UDim2.new(1, 0, 0.35, 0), Vector2.new(0, 1), -90)
edge(UDim2.fromScale(0, 0), UDim2.new(0.25, 0, 1, 0), Vector2.new(0, 0), 0)
edge(UDim2.fromScale(1, 0), UDim2.new(0.25, 0, 1, 0), Vector2.new(1, 0), 180)

-- дыхание на фоне
local breathSound: Sound? = nil
if CFG.BreathSoundId ~= "" then
	breathSound = Instance.new("Sound")
	breathSound.Name = "EvaKBreath"
	breathSound.SoundId = CFG.BreathSoundId
	breathSound.Looped = true
	breathSound.Volume = 0
	breathSound.Parent = SoundService
	breathSound:Play()
end

-- помехи по краям (когда близко монстр)
local noise = {}
for i = 1, 40 do
	local f = Instance.new("Frame")
	f.BorderSizePixel = 0; f.BackgroundTransparency = 1; f.ZIndex = 5
	f.BackgroundColor3 = (i % 9 == 0) and Color3.fromRGB(150, 255, 170) or Color3.fromRGB(245, 245, 250)
	f.Parent = fxGui
	noise[i] = f
end

-- прогресс по коридору
local barTrack = Instance.new("Frame")
barTrack.AnchorPoint = Vector2.new(0.5, 0); barTrack.Position = UDim2.new(0.5, 0, 0, 16); barTrack.Size = UDim2.fromOffset(260, 6)
barTrack.BackgroundColor3 = Color3.fromRGB(40, 30, 20); barTrack.BackgroundTransparency = 0.3; barTrack.BorderSizePixel = 0
barTrack.Visible = false; barTrack.ZIndex = 6; barTrack.Parent = fxGui
local barFill = Instance.new("Frame")
barFill.Size = UDim2.fromScale(0, 1); barFill.BackgroundColor3 = Color3.fromRGB(255, 214, 140); barFill.BorderSizePixel = 0; barFill.ZIndex = 7
barFill.Parent = barTrack

local runStartZ, runLen = 0, 0
local doorTotal, doorsBroken = 0, 0
local doorLbl = Instance.new("TextLabel")
doorLbl.AnchorPoint = Vector2.new(0.5, 0); doorLbl.Position = UDim2.new(0.5, 0, 0, 26); doorLbl.Size = UDim2.fromOffset(260, 20)
doorLbl.BackgroundTransparency = 1; doorLbl.Font = Enum.Font.Arcade; doorLbl.TextSize = 15
doorLbl.TextColor3 = Color3.fromRGB(246, 226, 182); doorLbl.Visible = false; doorLbl.ZIndex = 7; doorLbl.Parent = fxGui
local dls = Instance.new("UIStroke"); dls.Thickness = 2; dls.Parent = doorLbl
local warnUntil, warnTotal = 0, 1
local warnLbl = Instance.new("TextLabel")
warnLbl.AnchorPoint = Vector2.new(0.5, 1); warnLbl.Position = UDim2.new(0.5, 0, 1, -34); warnLbl.Size = UDim2.fromOffset(420, 18)
warnLbl.BackgroundTransparency = 1; warnLbl.Font = Enum.Font.Arcade; warnLbl.TextSize = 14
warnLbl.TextColor3 = Color3.fromRGB(255, 36, 36); warnLbl.Text = "! IT IS COMING FROM BEHIND - JUMP !"
warnLbl.Visible = false; warnLbl.ZIndex = 9; warnLbl.Parent = fxGui
local hiding = false
local hideLbl = Instance.new("TextLabel")
hideLbl.AnchorPoint = Vector2.new(0.5, 1); hideLbl.Position = UDim2.new(0.5, 0, 1, -64); hideLbl.Size = UDim2.fromOffset(420, 18)
hideLbl.BackgroundTransparency = 1; hideLbl.Font = Enum.Font.Arcade; hideLbl.TextSize = 14
hideLbl.TextColor3 = Color3.fromRGB(246, 226, 182); hideLbl.Text = "HIDING...   [E] LEAVE WARDROBE"
hideLbl.Visible = false; hideLbl.ZIndex = 9; hideLbl.Parent = fxGui
local hls = Instance.new("UIStroke"); hls.Thickness = 1.5; hls.Color = Color3.fromRGB(20, 10, 0); hls.Parent = hideLbl
local hpVal = 100
local hpRoot = Instance.new("Frame")
hpRoot.AnchorPoint = Vector2.new(0.5, 1); hpRoot.Position = UDim2.new(0.5, 0, 1, -150); hpRoot.Size = UDim2.fromOffset(340, 34)
hpRoot.BackgroundTransparency = 1; hpRoot.Visible = false; hpRoot.ZIndex = 9; hpRoot.Parent = fxGui
local function hpFrame(parent: Instance, x: number, y: number, w: number, h: number, col: Color3, rot: number?, round: number?): Frame
	local f = Instance.new("Frame")
	f.AnchorPoint = Vector2.new(0.5, 0.5); f.Position = UDim2.fromOffset(x, y); f.Size = UDim2.fromOffset(w, h)
	f.BackgroundColor3 = col; f.BorderSizePixel = 0; f.Rotation = rot or 0; f.ZIndex = 9
	if round then local uc = Instance.new("UICorner"); uc.CornerRadius = UDim.new(round, 0); uc.Parent = f end
	f.Parent = parent
	return f
end
do   -- сердце из двух кругов и ромба
	local red = Color3.fromRGB(214, 36, 48)
	hpFrame(hpRoot, 13, 13, 16, 16, red, 0, 0.5); hpFrame(hpRoot, 27, 13, 16, 16, red, 0, 0.5); hpFrame(hpRoot, 20, 21, 18, 18, red, 45)
	hpFrame(hpRoot, 9, 10, 4, 4, Color3.fromRGB(255, 200, 200), 0, 0.5)
end
local GOLDHP = Color3.fromRGB(214, 168, 78)
hpFrame(hpRoot, 42, 17, 13, 13, GOLDHP, 45); hpFrame(hpRoot, 332, 17, 13, 13, GOLDHP, 45)
local hpPlate = hpFrame(hpRoot, 187, 17, 280, 20, Color3.fromRGB(16, 9, 8))
local hps = Instance.new("UIStroke"); hps.Color = GOLDHP; hps.Thickness = 1.5; hps.Parent = hpPlate
local hpHold = Instance.new("Frame")
hpHold.BackgroundTransparency = 1; hpHold.Position = UDim2.fromOffset(2, 2); hpHold.Size = UDim2.new(1, -4, 1, -4); hpHold.ClipsDescendants = true; hpHold.ZIndex = 9; hpHold.Parent = hpPlate
local hpFill = Instance.new("Frame")
hpFill.Size = UDim2.fromScale(1, 1); hpFill.BackgroundColor3 = Color3.fromRGB(240, 60, 60); hpFill.BorderSizePixel = 0; hpFill.ZIndex = 9; hpFill.Parent = hpHold
local hpg = Instance.new("UIGradient"); hpg.Color = ColorSequence.new(Color3.fromRGB(255, 96, 90), Color3.fromRGB(150, 14, 22)); hpg.Rotation = 90; hpg.Parent = hpFill
for _, k in { 0.25, 0.5, 0.75 } do
	local tk = Instance.new("Frame"); tk.AnchorPoint = Vector2.new(0.5, 0); tk.Position = UDim2.fromScale(k, 0); tk.Size = UDim2.new(0, 1, 1, 0)
	tk.BackgroundColor3 = Color3.fromRGB(10, 4, 4); tk.BorderSizePixel = 0; tk.ZIndex = 10; tk.Parent = hpHold
end
local hpLbl = Instance.new("TextLabel")
hpLbl.Size = UDim2.fromScale(1, 1); hpLbl.BackgroundTransparency = 1; hpLbl.Font = Enum.Font.Arcade; hpLbl.TextSize = 13
hpLbl.TextColor3 = Color3.new(1, 1, 1); hpLbl.Text = "100"; hpLbl.ZIndex = 11; hpLbl.Parent = hpPlate
local hls2 = Instance.new("UIStroke"); hls2.Thickness = 1.5; hls2.Color = Color3.new(0, 0, 0); hls2.Parent = hpLbl
local dmgFx = Instance.new("Frame")
dmgFx.Size = UDim2.fromScale(1, 1); dmgFx.BackgroundColor3 = Color3.fromRGB(150, 0, 0); dmgFx.BackgroundTransparency = 1; dmgFx.BorderSizePixel = 0; dmgFx.ZIndex = 5; dmgFx.Parent = fxGui
local eyeFx = Instance.new("Frame")
eyeFx.Size = UDim2.fromScale(1, 1); eyeFx.BackgroundColor3 = Color3.fromRGB(92, 28, 170); eyeFx.BackgroundTransparency = 1; eyeFx.BorderSizePixel = 0; eyeFx.ZIndex = 5; eyeFx.Parent = fxGui
local eyesLbl = Instance.new("TextLabel")
eyesLbl.AnchorPoint = Vector2.new(0.5, 1); eyesLbl.Position = UDim2.new(0.5, 0, 1, -176); eyesLbl.Size = UDim2.fromOffset(420, 18)
eyesLbl.BackgroundTransparency = 1; eyesLbl.Font = Enum.Font.Arcade; eyesLbl.TextSize = 14; eyesLbl.TextColor3 = Color3.fromRGB(255, 36, 36)
eyesLbl.Text = "! EYES - DON'T LOOK AT THEM !"; eyesLbl.Visible = false; eyesLbl.ZIndex = 9; eyesLbl.Parent = fxGui
local els = Instance.new("UIStroke"); els.Thickness = 1.5; els.Color = Color3.fromRGB(30, 0, 0); els.Parent = eyesLbl
local lootLbl = Instance.new("TextLabel")
lootLbl.AnchorPoint = Vector2.new(0.5, 1); lootLbl.Position = UDim2.new(0.5, 0, 1, -150); lootLbl.Size = UDim2.fromOffset(300, 22)
lootLbl.BackgroundTransparency = 1; lootLbl.Font = Enum.Font.Arcade; lootLbl.TextSize = 18; lootLbl.TextColor3 = Color3.fromRGB(255, 214, 120)
lootLbl.Text = ""; lootLbl.Visible = false; lootLbl.ZIndex = 9; lootLbl.Parent = fxGui
local lls = Instance.new("UIStroke"); lls.Thickness = 2; lls.Color = Color3.fromRGB(40, 24, 0); lls.Parent = lootLbl
local eyeK, lastEyeSend = 0, 0
local heldFood: string? = nil
local lastCrossSend = 0
local foodBtn = Instance.new("TextButton")
foodBtn.AnchorPoint = Vector2.new(0.5, 1); foodBtn.Position = UDim2.new(0.5, 0, 1, -200); foodBtn.Size = UDim2.fromOffset(340, 30)
foodBtn.BackgroundColor3 = Color3.fromRGB(30, 22, 14); foodBtn.BackgroundTransparency = 0.25; foodBtn.AutoButtonColor = false
foodBtn.Font = Enum.Font.Arcade; foodBtn.TextSize = 16; foodBtn.TextColor3 = Color3.fromRGB(170, 240, 120)
foodBtn.Text = ""; foodBtn.Visible = false; foodBtn.ZIndex = 9; foodBtn.Parent = fxGui
local fbs = Instance.new("UIStroke"); fbs.Thickness = 1.5; fbs.Color = Color3.fromRGB(10, 30, 8); fbs.Parent = foodBtn
local bossBar = Instance.new("Frame")
bossBar.AnchorPoint = Vector2.new(0.5, 0); bossBar.Position = UDim2.new(0.5, 0, 0, 54); bossBar.Size = UDim2.fromOffset(360, 16)
bossBar.BackgroundColor3 = Color3.fromRGB(20, 8, 8); bossBar.BorderSizePixel = 0; bossBar.Visible = false; bossBar.ZIndex = 9; bossBar.Parent = fxGui
local bossFill = Instance.new("Frame")
bossFill.Size = UDim2.fromScale(1, 1); bossFill.BackgroundColor3 = Color3.fromRGB(190, 30, 30); bossFill.BorderSizePixel = 0; bossFill.ZIndex = 10; bossFill.Parent = bossBar
local bossLbl = Instance.new("TextLabel")
bossLbl.Size = UDim2.fromScale(1, 1); bossLbl.BackgroundTransparency = 1; bossLbl.Font = Enum.Font.Arcade; bossLbl.TextSize = 12
bossLbl.TextColor3 = Color3.new(1, 1, 1); bossLbl.Text = "HUNGRY GIRL - THROW ROTTEN FOOD!"; bossLbl.ZIndex = 11; bossLbl.Parent = bossBar
local bls = Instance.new("UIStroke"); bls.Thickness = 1.5; bls.Color = Color3.new(0, 0, 0); bls.Parent = bossLbl
local function throwHeld()
	if not heldFood or not world then return end
	local cam = workspace.CurrentCamera
	world:FireServer("Throw", cam.CFrame.LookVector + Vector3.new(0, 0.04, 0))
end
foodBtn.MouseButton1Click:Connect(throwHeld)
local eyeRay = RaycastParams.new()
eyeRay.FilterType = Enum.RaycastFilterType.Exclude
local function setHp(v: number)
	local old = hpVal
	hpVal = math.clamp(v, 0, 100)
	player:SetAttribute("EvaKHpNow", hpVal)
	TweenService:Create(hpFill, TweenInfo.new(0.25), { Size = UDim2.fromScale(hpVal / 100, 1) }):Play()
	hpLbl.Text = tostring(math.floor(hpVal + 0.5))
	if hpVal < old then
		dmgFx.BackgroundTransparency = 0.55
		TweenService:Create(dmgFx, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
		shakeAmt = math.max(shakeAmt, 0.5)
	end
end
-- новогодний звук на сложности NEW YEAR (ID задаются в EvaKNewYear.server)
local SoundService = game:GetService("SoundService")
local nySounds: {Sound} = {}
local function nyAudio(on: boolean)
	for _, sd in nySounds do sd:Destroy() end
	table.clear(nySounds)
	if not on then return end
	local function loop(key: string, vol: number)
		local id = workspace:GetAttribute("NYSnd" .. key)
		if type(id) == "string" and id ~= "" then
			local sd = Instance.new("Sound")
			sd.Name = "EvaKNY" .. key; sd.SoundId = id; sd.Volume = vol; sd.Looped = true
			sd.Parent = SoundService
			sd:Play()
			table.insert(nySounds, sd)
		end
	end
	loop("Music", 0.45); loop("Bells", 0.25)   -- Jingle Bells и бубенцы саней (метель убрана)
end
local function showNote(txt: string, col: Color3)
	lootLbl.Text = txt
	local old = lootLbl.TextColor3
	lootLbl.TextColor3 = col
	lootLbl.TextTransparency = 0; lls.Transparency = 0
	lootLbl.Position = UDim2.new(0.5, 0, 1, -150); lootLbl.Visible = true
	TweenService:Create(lootLbl, TweenInfo.new(2.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = UDim2.new(0.5, 0, 1, -200), TextTransparency = 1 }):Play()
	TweenService:Create(lls, TweenInfo.new(2.6), { Transparency = 1 }):Play()
	task.delay(2.7, function() lootLbl.TextColor3 = old end)
end
local lastBaubles = player:GetAttribute("NYBaubles") or 0
local baubleReady = false
task.delay(8, function() baubleReady = true end)
player:GetAttributeChangedSignal("NYBaubles"):Connect(function()
	local n = player:GetAttribute("NYBaubles") or 0
	if baubleReady and n > lastBaubles then
		if n >= 10 then
			showNote("NEW YEAR TOY UNLOCKED!", Color3.fromRGB(255, 220, 90))
		else
			showNote("BAUBLE " .. n .. " / 10", Color3.fromRGB(255, 120, 120))
		end
	end
	lastBaubles = n
end)
local function showLoot(n: number)
	lootLbl.Text = "+" .. tostring(n) .. ((player:GetAttribute("Difficulty") == "newyear") and " SNOWFLAKES" or " BADGES")
	lootLbl.TextTransparency = 0; lls.Transparency = 0
	lootLbl.Position = UDim2.new(0.5, 0, 0.62, 0); lootLbl.Visible = true
	TweenService:Create(lootLbl, TweenInfo.new(1.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = UDim2.new(0.5, 0, 0.56, 0), TextTransparency = 1 }):Play()
	TweenService:Create(lls, TweenInfo.new(1.8), { Transparency = 1 }):Play()
end
-- шкаф: мягкая виньетка по краям + лёгкое размытие (вместо чёрных полос)
local hideEdges = {}
do
	local defs = {
		{ UDim2.fromScale(0, 0), UDim2.fromScale(0.3, 1), 0, Vector2.new(0, 0) },
		{ UDim2.fromScale(1, 0), UDim2.fromScale(0.3, 1), 180, Vector2.new(1, 0) },
		{ UDim2.fromScale(0, 0), UDim2.fromScale(1, 0.3), 90, Vector2.new(0, 0) },
		{ UDim2.fromScale(0, 1), UDim2.fromScale(1, 0.3), 270, Vector2.new(0, 1) },
	}
	for _, d in defs do
		local f = Instance.new("Frame")
		f.BackgroundColor3 = Color3.new(0, 0, 0); f.BorderSizePixel = 0; f.ZIndex = 8; f.BackgroundTransparency = 1
		f.Position = d[1]; f.Size = d[2]; f.AnchorPoint = d[4]
		local g = Instance.new("UIGradient")
		g.Rotation = d[3]; g.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.55, 0.45), NumberSequenceKeypoint.new(1, 1) })
		g.Parent = f
		f.Parent = fxGui
		table.insert(hideEdges, f)
	end
end
-- щели шкафа: вертикальные тёмные планки в центре (как в DOORS)
local hideSlats = {}
for i = 1, 6 do
	local f = Instance.new("Frame")
	f.BackgroundColor3 = Color3.fromRGB(8, 4, 3); f.BorderSizePixel = 0; f.ZIndex = 8; f.BackgroundTransparency = 1
	f.AnchorPoint = Vector2.new(0.5, 0.5); f.Position = UDim2.fromScale(0.34 + i * 0.05, 0.5); f.Size = UDim2.new(0, 10, 0.62, 0)
	f.Parent = fxGui
	table.insert(hideSlats, f)
end
local hideBlur = Instance.new("BlurEffect")
hideBlur.Name = "EvaKHideBlur"; hideBlur.Size = 0; hideBlur.Parent = game:GetService("Lighting")
local hideT = 0
local hideK = 0
local wls = Instance.new("UIStroke"); wls.Thickness = 1.5; wls.Color = Color3.fromRGB(30, 0, 0); wls.Parent = warnLbl
local breathPhase = 0

RunService.RenderStepped:Connect(function(dt)
	local now = os.clock()
	hideK += (((active and hiding) and 1 or 0) - hideK) * math.min(1, dt * 4)
	hideT = (active and hiding) and (hideT + dt) or 0
	local suff = math.clamp((hideT - 10) / 3, 0, 1)   -- после 10 секунд в шкафу: удушье
	local pulse = suff > 0 and (0.5 + 0.5 * math.sin(os.clock() * (6 + suff * 6))) or 0
	for _, f in hideEdges do
		f.BackgroundColor3 = Color3.new(suff * (0.55 + 0.35 * pulse), 0, 0)
		f.BackgroundTransparency = 1 - math.clamp(hideK * (0.75 + suff * 0.25), 0, 1)
	end
	for _, f in hideSlats do f.BackgroundTransparency = 1 end   -- «клетка» убрана
	hideBlur.Size = 7 * hideK + suff * 5 * pulse
	hpRoot.Visible = active
	hideLbl.Visible = active and hiding
	if suff > 0 then
		hideLbl.Text = "YOUR HEART CAN'T TAKE IT..."
		hideLbl.TextColor3 = Color3.fromRGB(255, 70 + 90 * (1 - pulse), 60)
	else
		hideLbl.Text = "HIDING...   [E] LEAVE WARDROBE"
		hideLbl.TextColor3 = Color3.fromRGB(246, 226, 182)
	end
	warnLbl.Visible = active and os.clock() < warnUntil and (math.floor(os.clock() * 5) % 2 == 0)
	if not active then
		for _, f in vig do f.BackgroundTransparency = 1 end
		for _, f in noise do f.BackgroundTransparency = 1 end
		if breathSound then breathSound.Volume = 0 end
		barTrack.Visible = false
		return
	end
	local char = player.Character
	local st = char and states[char]
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local sprintK = st and st.sprintK or 0
	local warnK = (now < warnUntil) and math.clamp(1 - (warnUntil - now) / warnTotal, 0, 1) or 0
	shakeAmt = math.max(0, shakeAmt - dt * 1.2)
	-- Eyes: взгляд на сущность = урон
	do
		local looking, near = false, false
		if not hiding and not dropping then
			local cp = camera.CFrame.Position
			for _, ent in game:GetService("CollectionService"):GetTagged("EvaKEyesEntity") do
				local v = ent:GetPivot().Position - cp
				local d = v.Magnitude
				if d < 160 and d > 0.5 then
					near = true
					if d < 130 and camera.CFrame.LookVector:Dot(v.Unit) > 0.8 then
						local fl = { ent }
						if char then table.insert(fl, char) end
						eyeRay.FilterDescendantsInstances = fl
						if not workspace:Raycast(cp, v, eyeRay) then looking = true end
					end
				end
			end
		end
		eyeK += ((looking and 1 or 0) - eyeK) * math.min(1, dt * 6)
		eyeFx.BackgroundTransparency = 1 - 0.5 * eyeK
		if looking then
			shakeAmt = math.max(shakeAmt, 0.3)
			if world and now - lastEyeSend > 0.35 then
				lastEyeSend = now
				world:FireServer("EyesHit")
			end
		end
		eyesLbl.Visible = near and (math.floor(now * 5) % 2 == 0)
		-- деревянный крест в ящике: взгляд на него = урон
		if not hiding and not dropping and now - lastCrossSend > 0.6 then
			local cp = camera.CFrame.Position
			for _, cr in game:GetService("CollectionService"):GetTagged("EvaKCross") do
				if cr:IsA("Model") and not cr:GetAttribute("Used") then
					local v = cr:GetPivot().Position - cp
					local d = v.Magnitude
					if d < 26 and d > 0.5 and camera.CFrame.LookVector:Dot(v.Unit) > 0.94 then
						local fl = { cr }
						if char then table.insert(fl, char) end
						eyeRay.FilterDescendantsInstances = fl
						if not workspace:Raycast(cp, v, eyeRay) then
							lastCrossSend = now
							shakeAmt = math.max(shakeAmt, 1)
							if world then world:FireServer("CrossHit", cr) end
							break
						end
					end
				end
			end
		end
	end


	local rate = 1.1 + sprintK * 2.4 + warnK * 1.6 + (dropping and 2 or 0)
	breathPhase += dt * rate * math.pi
	local pulse = 0.5 + 0.5 * math.sin(breathPhase)
	local base = 0.78 - 0.12 * sprintK - 0.18 * warnK
	local t = math.clamp(base - 0.22 * pulse * (0.5 + sprintK + warnK), 0, 1)
	for _, f in vig do f.BackgroundTransparency = t end
	if breathSound then
		breathSound.Volume = CFG.BreathVolume * (0.35 + 0.65 * math.min(1, sprintK * 1.2 + warnK * 0.6))
		breathSound.PlaybackSpeed = 0.85 + 0.5 * sprintK + 0.25 * warnK
	end

	-- помехи
	for _, f in noise do
		if warnK > 0.05 and rng:NextNumber() < 0.25 * warnK + 0.05 then
			local x = rng:NextNumber()
			if rng:NextNumber() < 0.5 then x = (rng:NextNumber() < 0.5) and x * 0.18 or 1 - x * 0.18 end
			f.Position = UDim2.fromScale(x, rng:NextNumber())
			f.Size = UDim2.fromOffset(rng:NextInteger(2, 30), rng:NextInteger(2, 6))
			f.BackgroundTransparency = rng:NextNumber(0.3, 0.8)
		else
			f.BackgroundTransparency = 1
		end
	end

	-- прогресс
	if doorTotal > 0 and active then
		barTrack.Visible = true
		doorLbl.Visible = true
		barFill.Size = UDim2.fromScale(math.clamp(doorsBroken / doorTotal, 0, 1), 1)
		doorLbl.Text = string.format("DOORS %d / %d", doorsBroken, doorTotal)
	elseif active and player:GetAttribute("EvaKEndless") then
		barTrack.Visible = false
		doorLbl.Visible = true
		doorLbl.Text = string.format("ENDLESS  -  DOOR %d", doorsBroken)
	else
		doorLbl.Visible = false
	end
end)

-- вспышка / клик-эффект
local function flash(color: Color3, alpha: number, dur: number)
	local f = Instance.new("Frame")
	f.Name = "Overlay"; f.Size = UDim2.fromScale(1, 1); f.BorderSizePixel = 0; f.ZIndex = 20
	f.BackgroundColor3 = color; f.BackgroundTransparency = alpha
	f.Parent = fxGui
	local tw = TweenService:Create(f, TweenInfo.new(dur), { BackgroundTransparency = 1 })
	tw:Play()
	tw.Completed:Once(function() f:Destroy() end)
end

local function clickFx(pos: Vector2)
	local ring = Instance.new("Frame")
	ring.AnchorPoint = Vector2.new(0.5, 0.5); ring.Position = UDim2.fromOffset(pos.X, pos.Y)
	ring.Size = UDim2.fromOffset(14, 14); ring.BackgroundTransparency = 1; ring.ZIndex = 30
	ring.Parent = fxGui
	local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(1, 0); rc.Parent = ring
	local rs = Instance.new("UIStroke"); rs.Color = Color3.fromRGB(255, 214, 140); rs.Thickness = 2.5; rs.Parent = ring
	TweenService:Create(ring, TweenInfo.new(0.45), { Size = UDim2.fromOffset(96, 96) }):Play()
	local ts = TweenService:Create(rs, TweenInfo.new(0.45), { Transparency = 1, Thickness = 0.5 })
	ts:Play(); ts.Completed:Once(function() ring:Destroy() end)
	-- чернильные шипы-щупальца
	for i = 1, 8 do
		local ang = (i / 8) * math.pi * 2 + rng:NextNumber(-0.2, 0.2)
		local spike = Instance.new("Frame")
		spike.AnchorPoint = Vector2.new(0.5, 0.5); spike.Position = UDim2.fromOffset(pos.X + math.cos(ang) * 8, pos.Y + math.sin(ang) * 8)
		spike.Size = UDim2.fromOffset(6, 20); spike.Rotation = math.deg(ang) + 90
		spike.BackgroundColor3 = Color3.fromRGB(10, 7, 14); spike.BorderSizePixel = 0; spike.ZIndex = 31
		spike.Parent = fxGui
		local sc = Instance.new("UICorner"); sc.CornerRadius = UDim.new(1, 0); sc.Parent = spike
		local ss = Instance.new("UIStroke"); ss.Color = Color3.fromRGB(140, 80, 210); ss.Thickness = 1; ss.Parent = spike
		local d = rng:NextNumber(34, 52)
		local t1 = TweenService:Create(spike, TweenInfo.new(0.4), {
			Position = UDim2.fromOffset(pos.X + math.cos(ang) * d, pos.Y + math.sin(ang) * d),
			Size = UDim2.fromOffset(2, 6), BackgroundTransparency = 1 })
		t1:Play(); t1.Completed:Once(function() spike:Destroy() end)
		TweenService:Create(ss, TweenInfo.new(0.4), { Transparency = 1 }):Play()
	end
	for _ = 1, 6 do   -- искры
		local a = rng:NextNumber(0, math.pi * 2)
		local sp = Instance.new("Frame")
		sp.AnchorPoint = Vector2.new(0.5, 0.5); sp.Position = UDim2.fromOffset(pos.X, pos.Y); sp.Size = UDim2.fromOffset(5, 5)
		sp.Rotation = 45; sp.BackgroundColor3 = Color3.fromRGB(255, 214, 140); sp.BorderSizePixel = 0; sp.ZIndex = 32
		sp.Parent = fxGui
		local d = rng:NextNumber(30, 80)
		local t2 = TweenService:Create(sp, TweenInfo.new(0.5), { Position = UDim2.fromOffset(pos.X + math.cos(a) * d, pos.Y + math.sin(a) * d), BackgroundTransparency = 1 })
		t2:Play(); t2.Completed:Once(function() sp:Destroy() end)
	end
end

UIS.InputBegan:Connect(function(input)
	if not active then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		if heldFood then throwHeld() end
		clickFx(UIS:GetMouseLocation())
	elseif input.UserInputType == Enum.UserInputType.Touch then
		local inset = GuiService:GetGuiInset()
		clickFx(Vector2.new(input.Position.X + inset.X, input.Position.Y + inset.Y))
	end
end)

-- ветер при падении
local function startWind()
	task.spawn(function()
		while dropping and active do
			local x = rng:NextNumber()
			local f = Instance.new("Frame")
			f.Name = "Wind"; f.AnchorPoint = Vector2.new(0.5, 0.5); f.Position = UDim2.fromScale(x, 1.15)
			f.Size = UDim2.fromOffset(rng:NextInteger(2, 5), rng:NextInteger(80, 220)); f.BorderSizePixel = 0
			f.BackgroundColor3 = Color3.fromRGB(255, 235, 200); f.BackgroundTransparency = rng:NextNumber(0.55, 0.85); f.ZIndex = 4
			f.Parent = fxGui
			local t = TweenService:Create(f, TweenInfo.new(rng:NextNumber(0.25, 0.45), Enum.EasingStyle.Linear), { Position = UDim2.fromScale(x, -0.2) })
			t:Play(); t.Completed:Once(function() f:Destroy() end)
			task.wait(0.025)
		end
	end)
end

-- приземление: удар, вспышка, пыль
local function landedFx()
	shakeAmt = 1
	flash(Color3.fromRGB(255, 240, 210), 0.35, 0.6)
	sfxPlay(CFG.LandSoundId, 0.9)
	for _ = 1, 14 do
		local puff = Instance.new("Frame")
		puff.Name = "Overlay"; puff.AnchorPoint = Vector2.new(0.5, 0.5)
		local x = rng:NextNumber(0.05, 0.95)
		puff.Position = UDim2.fromScale(x, 1.02); puff.Size = UDim2.fromOffset(30, 30)
		puff.BackgroundColor3 = Color3.fromRGB(170, 155, 135); puff.BackgroundTransparency = 0.45; puff.BorderSizePixel = 0; puff.ZIndex = 8
		puff.Parent = fxGui
		local pc = Instance.new("UICorner"); pc.CornerRadius = UDim.new(1, 0); pc.Parent = puff
		local sz = rng:NextInteger(120, 260)
		local t = TweenService:Create(puff, TweenInfo.new(rng:NextNumber(0.8, 1.4)), {
			Size = UDim2.fromOffset(sz, sz), Position = UDim2.fromScale(x + rng:NextNumber(-0.1, 0.1), rng:NextNumber(0.6, 0.9)), BackgroundTransparency = 1 })
		t:Play(); t.Completed:Once(function() puff:Destroy() end)
	end
end

-- скример: глитч-лицо из шума
local function jumpscare()
	shakeAmt = 1.6
	sfxPlay(CFG.ScareSoundId, 1)
	local root = Instance.new("Frame")
	root.Name = "Overlay"; root.Size = UDim2.fromScale(1, 1); root.BackgroundColor3 = Color3.fromRGB(6, 6, 8)
	root.BorderSizePixel = 0; root.ZIndex = 40
	root.Parent = fxGui
	local px = {}
	local clusters = {   -- глаза и рот, как в лице монстра
		{ 0.34, 0.36, 0.13, 0.10 }, { 0.66, 0.36, 0.13, 0.10 }, { 0.5, 0.68, 0.2, 0.2 }, { 0.5, 0.5, 0.42, 0.45 },
	}
	for i = 1, 220 do
		local f = Instance.new("Frame")
		f.BorderSizePixel = 0; f.ZIndex = 41
		f.BackgroundColor3 = (i % 12 == 0) and Color3.fromRGB(150, 255, 170) or (i % 17 == 0) and Color3.fromRGB(255, 60, 60) or Color3.fromRGB(245, 245, 250)
		f.Parent = root
		px[i] = f
	end
	task.spawn(function()
		local t0 = os.clock()
		while os.clock() - t0 < 1.3 and root.Parent do
			for i, f in px do
				local c = clusters[(i % #clusters) + 1]
				f.Position = UDim2.fromScale(c[1] + rng:NextNumber(-c[3], c[3]), c[2] + rng:NextNumber(-c[4], c[4]))
				f.Size = UDim2.fromOffset(rng:NextInteger(3, 26), rng:NextInteger(3, 10))
				f.BackgroundTransparency = rng:NextNumber(0, 0.7)
			end
			task.wait(0.045)
		end
		if root.Parent then
			local tw = TweenService:Create(root, TweenInfo.new(0.5), { BackgroundTransparency = 1 })
			tw:Play()
			for _, f in px do f:Destroy() end
			tw.Completed:Once(function() root:Destroy() end)
		end
	end)
end

-- очень плавное появление: чёрный экран и размытие медленно уходят
local function smoothFadeIn(dur: number)
	local f = Instance.new("Frame")
	f.Name = "SmoothIn"; f.Size = UDim2.fromScale(1, 1); f.BackgroundColor3 = Color3.new(0, 0, 0); f.BorderSizePixel = 0
	f.BackgroundTransparency = 0; f.ZIndex = 80
	f.Parent = fxGui
	local blur = Instance.new("BlurEffect")
	blur.Name = "EvaKSmoothBlur"; blur.Size = 28; blur.Parent = game:GetService("Lighting")
	local ti = TweenInfo.new(dur, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	TweenService:Create(f, TweenInfo.new(dur, Enum.EasingStyle.Sine, Enum.EasingDirection.In), { BackgroundTransparency = 1 }):Play()
	TweenService:Create(blur, ti, { Size = 0 }):Play()
	task.delay(dur + 0.2, function() f:Destroy(); blur:Destroy() end)
end
local firstSpawn = true
player.CharacterAdded:Connect(function()
	if firstSpawn then firstSpawn = false return end
	if not player:GetAttribute("InMap") then smoothFadeIn(2.2) end   -- возврат в лобби
end)

local function bigText(msg: string, color: Color3)
	local l = Instance.new("TextLabel")
	l.Name = "Overlay"; l.AnchorPoint = Vector2.new(0.5, 0.5); l.Position = UDim2.fromScale(0.5, 0.45); l.Size = UDim2.fromOffset(700, 60)
	l.BackgroundTransparency = 1; l.Font = Enum.Font.Arcade; l.TextSize = 44; l.TextColor3 = color; l.Text = msg
	l.TextTransparency = 1; l.ZIndex = 60
	l.Parent = fxGui
	local st = Instance.new("UIStroke"); st.Color = Color3.fromRGB(0, 0, 0); st.Thickness = 3; st.Parent = l
	TweenService:Create(l, TweenInfo.new(0.6), { TextTransparency = 0 }):Play()
end

local function deadFx()
	local f = Instance.new("Frame")
	f.Name = "Overlay"; f.Size = UDim2.fromScale(1, 1); f.BackgroundColor3 = Color3.new(0, 0, 0); f.BorderSizePixel = 0
	f.BackgroundTransparency = 1; f.ZIndex = 50
	f.BackgroundColor3 = Color3.fromRGB(28, 4, 6)
	f.Parent = fxGui
	TweenService:Create(f, TweenInfo.new(1.2), { BackgroundTransparency = 0 }):Play()
	-- горизонтальные "царапины" и череп по центру
	for i = 1, 26 do
		local line = Instance.new("Frame")
		line.Name = "Overlay"; line.BorderSizePixel = 0; line.ZIndex = 51
		line.BackgroundColor3 = Color3.fromRGB(120, 20, 24); line.BackgroundTransparency = 0.7 + math.random() * 0.25
		line.Position = UDim2.fromScale(math.random() * 0.4, math.random()); line.Size = UDim2.fromScale(0.3 + math.random() * 0.6, 0.0025 + math.random() * 0.004)
		line.Parent = fxGui
	end
	local skull = Instance.new("Frame")
	skull.Name = "Overlay"; skull.AnchorPoint = Vector2.new(0.5, 0.5); skull.Position = UDim2.fromScale(0.5, 0.27); skull.Size = UDim2.fromOffset(150, 150)
	skull.BackgroundTransparency = 1; skull.ZIndex = 60; skull.Parent = fxGui
	local sk = Instance.new("Frame")
	sk.Size = UDim2.fromOffset(150, 120); sk.BackgroundColor3 = Color3.fromRGB(232, 228, 222); sk.BorderSizePixel = 0; sk.ZIndex = 61; sk.Parent = skull
	local skc = Instance.new("UICorner"); skc.CornerRadius = UDim.new(0, 40); skc.Parent = sk
	local jaw = Instance.new("Frame")
	jaw.Position = UDim2.fromOffset(34, 100); jaw.Size = UDim2.fromOffset(82, 46); jaw.BackgroundColor3 = Color3.fromRGB(232, 228, 222); jaw.BorderSizePixel = 0; jaw.ZIndex = 61; jaw.Parent = skull
	for i = 1, 3 do
		local g = Instance.new("Frame")
		g.Position = UDim2.fromOffset(18 + i * 16, 100); g.Size = UDim2.fromOffset(4, 46); g.BackgroundColor3 = Color3.fromRGB(28, 4, 6); g.BorderSizePixel = 0; g.ZIndex = 62; g.Parent = skull
	end
	local ex = Instance.new("TextLabel")
	ex.BackgroundTransparency = 1; ex.Position = UDim2.fromOffset(24, 26); ex.Size = UDim2.fromOffset(50, 50); ex.Font = Enum.Font.GothamBlack; ex.TextSize = 54
	ex.TextColor3 = Color3.fromRGB(28, 4, 6); ex.Text = "✕"; ex.ZIndex = 62; ex.Parent = skull
	local ey = Instance.new("Frame")
	ey.Position = UDim2.fromOffset(88, 36); ey.Size = UDim2.fromOffset(40, 36); ey.BackgroundColor3 = Color3.fromRGB(28, 4, 6); ey.BorderSizePixel = 0; ey.ZIndex = 62; ey.Parent = skull
	local eyc = Instance.new("UICorner"); eyc.CornerRadius = UDim.new(0, 12); eyc.Parent = ey
	skull.Rotation = -6
	TweenService:Create(skull, TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Rotation = 6 }):Play()
	bigText("CAUGHT", Color3.fromRGB(246, 226, 182))
	-- кнопка выхода сразу после смерти (не ждём экран результатов)
	local eb = Instance.new("TextButton")
	eb.Name = "Overlay"; eb.AnchorPoint = Vector2.new(0.5, 1); eb.Position = UDim2.new(0.5, 0, 1, -40)
	eb.Size = UDim2.fromOffset(300, 48); eb.BackgroundColor3 = Color3.fromRGB(80, 24, 20)
	eb.Font = Enum.Font.Arcade; eb.TextSize = 18; eb.TextColor3 = Color3.fromRGB(246, 226, 182)
	eb.Text = "EXIT TO LOBBY"; eb.ZIndex = 80; eb.Modal = true; eb.Parent = fxGui
	local ec = Instance.new("UICorner"); ec.CornerRadius = UDim.new(0, 8); ec.Parent = eb
	UIS.MouseIconEnabled = true
	eb.MouseButton1Click:Connect(function()
		eb.Text = "..."
		if world then world:FireServer("Exit") end
	end)
end

local function completeFx()
	flash(Color3.fromRGB(255, 230, 170), 0.1, 1.6)
	bigText("RUN COMPLETE", Color3.fromRGB(255, 214, 140))
end


-- ============================================================
-- ЭКРАН РЕЗУЛЬТАТОВ: время, бейджи, 2 кнопки (в лобби / новая игра)
-- ============================================================
local resultsGui: ScreenGui? = nil
local function fmtTime(t: number): string
	local m = math.floor(t / 60)
	return string.format("%02d:%04.1f", m, t - m * 60)
end

local function showResults(data)
	if resultsGui then resultsGui:Destroy() end
	local win = data.win == true
	local g = Instance.new("ScreenGui")
	g.Name = "EvaKResults"; g.IgnoreGuiInset = true; g.ResetOnSpawn = false
	g.DisplayOrder = 600; g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	g.Parent = playerGui
	resultsGui = g
	UIS.MouseIconEnabled = true

	local dim = Instance.new("TextButton")   -- Modal: освобождает мышь в режиме от первого лица
	dim.Size = UDim2.fromScale(1, 1); dim.BackgroundColor3 = Color3.new(0, 0, 0); dim.BackgroundTransparency = 1
	dim.Text = ""; dim.AutoButtonColor = false; dim.Modal = true; dim.Parent = g
	TweenService:Create(dim, TweenInfo.new(0.6), { BackgroundTransparency = 0.35 }):Play()

	local GOLDC = Color3.fromRGB(255, 214, 140)
	local accent = win and GOLDC or Color3.fromRGB(220, 80, 70)

	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0.5, 0.5); panel.Position = UDim2.fromScale(0.5, 0.56)
	panel.Size = UDim2.fromOffset(520, (data.canRevive and not win) and 490 or 420); panel.BackgroundColor3 = Color3.fromRGB(18, 13, 10)
	panel.BorderSizePixel = 0; panel.Parent = g
	local uis = Instance.new("UIScale"); uis.Parent = panel
	local function fit() uis.Scale = math.clamp(math.min(g.AbsoluteSize.X / 700, g.AbsoluteSize.Y / 520), 0.5, 1.4) end
	fit(); g:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
	local pc = Instance.new("UICorner"); pc.CornerRadius = UDim.new(0, 10); pc.Parent = panel
	local ps = Instance.new("UIStroke"); ps.Color = accent; ps.Thickness = 2; ps.Parent = panel

	local function label(text, size, y, color, h, align)
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1; l.Font = Enum.Font.Arcade; l.TextSize = size; l.TextColor3 = color
		l.Text = text; l.Position = UDim2.fromOffset(30, y); l.Size = UDim2.new(1, -60, 0, h or size + 6)
		l.TextXAlignment = align or Enum.TextXAlignment.Left; l.Parent = panel
		return l
	end
	label(win and "RUN COMPLETE" or "CAUGHT", 38, 24, accent, 50, Enum.TextXAlignment.Center)
	label(string.upper(tostring(data.diff or "")) .. " MODE", 16, 76, Color3.fromRGB(170, 140, 100), 22, Enum.TextXAlignment.Center)

	local rows = {
		{ "TIME", fmtTime(data.time or 0) },
		{ (data.diff == "newyear") and "SNOWFLAKES EARNED" or "BADGES EARNED", "+" .. tostring(math.floor(data.badges or 0)) },
		{ "DOORS BROKEN", string.format("%d / %d", data.doors or 0, data.total or 100) },
		{ "RESULT", win and "ESCAPED" or "FAILED" },
	}
	for i, r in rows do
		local y = 124 + (i - 1) * 50
		local line = Instance.new("Frame")
		line.Position = UDim2.fromOffset(30, y + 38); line.Size = UDim2.new(1, -60, 0, 1)
		line.BackgroundColor3 = Color3.fromRGB(90, 66, 40); line.BorderSizePixel = 0; line.Parent = panel
		label(r[1], 18, y + 6, Color3.fromRGB(246, 226, 182), 26)
		local v = label(r[2], 22, y + 4, (i == 2) and GOLDC or Color3.fromRGB(255, 255, 255), 30, Enum.TextXAlignment.Right)
		v.TextTransparency = 1
		task.delay(0.35 + i * 0.25, function() if v.Parent then TweenService:Create(v, TweenInfo.new(0.3), { TextTransparency = 0 }):Play() end end)
	end

	local clicked = false
	local function button(text, x, kind, primary)
		local b = Instance.new("TextButton")
		b.Position = UDim2.new(0, x, 1, -78); b.Size = UDim2.fromOffset(220, 52)
		b.BackgroundColor3 = primary and Color3.fromRGB(70, 46, 20) or Color3.fromRGB(28, 20, 14)
		b.Font = Enum.Font.Arcade; b.TextSize = 17; b.TextColor3 = Color3.fromRGB(246, 226, 182)
		b.Text = text; b.AutoButtonColor = false; b.Parent = panel
		local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = b
		local st = Instance.new("UIStroke"); st.Color = Color3.fromRGB(150, 112, 62); st.Thickness = 1.5; st.Parent = b
		b.MouseEnter:Connect(function() TweenService:Create(b, TweenInfo.new(0.12), { BackgroundColor3 = Color3.fromRGB(90, 60, 28) }):Play(); st.Color = GOLDC end)
		b.MouseLeave:Connect(function() TweenService:Create(b, TweenInfo.new(0.12), { BackgroundColor3 = primary and Color3.fromRGB(70, 46, 20) or Color3.fromRGB(28, 20, 14) }):Play(); st.Color = Color3.fromRGB(150, 112, 62) end)
		b.MouseButton1Click:Connect(function()
			if clicked then return end
			clicked = true
			b.Text = "..."
			if world then world:FireServer(kind) end
			TweenService:Create(dim, TweenInfo.new(0.5), { BackgroundTransparency = 0 }):Play()
		end)
	end
	button("RETURN TO LOBBY", 30, "Lobby", false)
	button("NEW GAME", 270, "Again", true)

	if data.canRevive and not win then
		local REVIVE_ID = 2089588137
		local MarketplaceService = game:GetService("MarketplaceService")
		local reviving, wantRevive = false, false
		local rb = Instance.new("TextButton")
		rb.Position = UDim2.new(0, 30, 1, -146); rb.Size = UDim2.new(1, -60, 0, 52)
		rb.BackgroundColor3 = Color3.fromRGB(90, 62, 20); rb.Font = Enum.Font.Arcade; rb.TextSize = 19
		rb.TextColor3 = Color3.fromRGB(255, 226, 150); rb.AutoButtonColor = true; rb.Parent = panel
		local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(0, 8); rc.Parent = rb
		local rs = Instance.new("UIStroke"); rs.Color = GOLDC; rs.Thickness = 2; rs.Parent = rb
		local function label2()
			rb.Text = ((player:GetAttribute("ReviveTokens") or 0) > 0) and "REVIVE  (YOU HAVE ONE)" or "REVIVE  -  29 R$"
		end
		label2()
		local function doRevive()
			if reviving or clicked then return end
			reviving = true; rb.Text = "..."
			if world then world:FireServer("Revive") end
			task.delay(4, function()   -- сервер не возродил (нет токена и т.п.) - даём нажать снова
				if rb.Parent then reviving = false; label2() end
			end)
		end
		local conn = player:GetAttributeChangedSignal("ReviveTokens"):Connect(function()
			if rb.Parent and (player:GetAttribute("ReviveTokens") or 0) > 0 then
				if wantRevive then doRevive() else label2() end
			end
		end)
		g.Destroying:Once(function() conn:Disconnect() end)
		rb.MouseButton1Click:Connect(function()
			if (player:GetAttribute("ReviveTokens") or 0) > 0 then doRevive(); return end
			wantRevive = true
			local isPass = false
			local okP = pcall(function() return MarketplaceService:GetProductInfo(REVIVE_ID, Enum.InfoType.Product) end)
			if not okP then isPass = pcall(function() return MarketplaceService:GetProductInfo(REVIVE_ID, Enum.InfoType.GamePass) end) end
			local ok, err = pcall(function()
				if isPass then MarketplaceService:PromptGamePassPurchase(player, REVIVE_ID)
				else MarketplaceService:PromptProductPurchase(player, REVIVE_ID) end
			end)
			if not ok then warn("[EvaK] покупка возрождения не открылась: " .. tostring(err)) end
		end)
	end

	panel.Position = UDim2.fromScale(0.5, 0.62)
	TweenService:Create(panel, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = UDim2.fromScale(0.5, 0.5) }):Play()
end


-- ============================================================
-- TAB-МЕНЮ: купить предметы / докупить бейджи / выйти из игры
-- ============================================================
local MarketplaceService = game:GetService("MarketplaceService")
local StarterGui = game:GetService("StarterGui")
local shopRF = ReplicatedStorage:FindFirstChild("EvaKShop")
local TAB_TOYS = {
	{ "DUCK", "RUBBER DUCK", "Common", 50 }, { "TOP", "SPINNING TOP", "Common", 80 },
	{ "ROBOT", "TIN ROBOT", "Rare", 250 }, { "BEAR", "OLD TEDDY", "Rare", 300 },
	{ "JACK", "JACK IN THE BOX", "Super Rare", 900 }, { "MUSIC", "MUSIC BOX", "Super Rare", 1100 },
	{ "DRAGON", "GILDED DRAGON", "Legendary", 3000 }, { "ROCKET", "STAR ROCKET", "Legendary", 5000 },
	{ "SANTA", "SANTA CLAUS", "Mythic", 10000 },
}
local RARITY_COL = {
	Common = Color3.fromRGB(190, 190, 190), Rare = Color3.fromRGB(90, 160, 255),
	["Super Rare"] = Color3.fromRGB(190, 100, 255), Legendary = Color3.fromRGB(255, 200, 60), Mythic = Color3.fromRGB(255, 80, 80),
}
local tabGui: ScreenGui? = nil
local tabConns: {RBXScriptConnection} = {}

local function closeTabMenu()
	for _, c in tabConns do c:Disconnect() end
	table.clear(tabConns)
	if tabGui then tabGui:Destroy(); tabGui = nil end
end

local function openTabMenu()
	if tabGui or resultsGui then return end
	local g = Instance.new("ScreenGui")
	g.Name = "EvaKTabMenu"; g.IgnoreGuiInset = true; g.ResetOnSpawn = false
	g.DisplayOrder = 550; g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	g.Parent = playerGui
	tabGui = g
	UIS.MouseIconEnabled = true

	local dim = Instance.new("TextButton")   -- Modal освобождает мышь в режиме от первого лица
	dim.Size = UDim2.fromScale(1, 1); dim.BackgroundColor3 = Color3.new(0, 0, 0); dim.BackgroundTransparency = 0.45
	dim.Text = ""; dim.AutoButtonColor = false; dim.Modal = true; dim.Parent = g

	local GOLDC, TXT = Color3.fromRGB(255, 214, 140), Color3.fromRGB(246, 226, 182)
	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0.5, 0.5); panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.fromOffset(640, 480); panel.BackgroundColor3 = Color3.fromRGB(16, 12, 9); panel.BorderSizePixel = 0
	panel.Parent = g
	local sc = Instance.new("UIScale"); sc.Parent = panel
	local function fit() sc.Scale = math.clamp(math.min(g.AbsoluteSize.X / 760, g.AbsoluteSize.Y / 560), 0.5, 1.4) end
	fit(); table.insert(tabConns, g:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit))
	local pc = Instance.new("UICorner"); pc.CornerRadius = UDim.new(0, 10); pc.Parent = panel
	local ps = Instance.new("UIStroke"); ps.Color = Color3.fromRGB(150, 112, 62); ps.Thickness = 2; ps.Parent = panel

	local function lbl(parent, text, size, x, y, w, color, align)
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1; l.Font = Enum.Font.Arcade; l.TextSize = size; l.TextColor3 = color or TXT
		l.Text = text; l.Position = UDim2.fromOffset(x, y); l.Size = UDim2.fromOffset(w, size + 6)
		l.TextXAlignment = align or Enum.TextXAlignment.Left; l.Parent = parent
		return l
	end
	local function btn(parent, text, x, y, w, h, bg)
		local b = Instance.new("TextButton")
		b.Position = UDim2.fromOffset(x, y); b.Size = UDim2.fromOffset(w, h); b.BackgroundColor3 = bg or Color3.fromRGB(36, 26, 16)
		b.Font = Enum.Font.Arcade; b.TextSize = 15; b.TextColor3 = TXT; b.Text = text; b.AutoButtonColor = false; b.Parent = parent
		local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 6); c.Parent = b
		local st = Instance.new("UIStroke"); st.Color = Color3.fromRGB(150, 112, 62); st.Thickness = 1.2; st.Parent = b
		b.MouseEnter:Connect(function() st.Color = GOLDC end)
		b.MouseLeave:Connect(function() st.Color = Color3.fromRGB(150, 112, 62) end)
		return b
	end

	lbl(panel, "MENU", 30, 24, 14, 200, GOLDC)
	local badgeLbl = lbl(panel, "", 20, 250, 20, 250, GOLDC, Enum.TextXAlignment.Right)
	local plus = btn(panel, "+", 512, 14, 40, 36)
	plus.TextSize = 24

	local packs = Instance.new("Frame")   -- покупка бейджей за Robux
	packs.Position = UDim2.fromOffset(300, 56); packs.Size = UDim2.fromOffset(310, 92); packs.BackgroundColor3 = Color3.fromRGB(26, 19, 12)
	packs.Visible = false; packs.ZIndex = 5; packs.Parent = panel
	local pcc = Instance.new("UICorner"); pcc.CornerRadius = UDim.new(0, 8); pcc.Parent = packs
	local pst = Instance.new("UIStroke"); pst.Color = GOLDC; pst.Thickness = 1.5; pst.Parent = packs
	local b1 = btn(packs, "100 BADGES - 59 R$", 10, 10, 290, 34); b1.ZIndex = 6
	local b2 = btn(packs, "500 BADGES - 249 R$", 10, 50, 290, 34); b2.ZIndex = 6
	local function buyPack(id: number)
		local isPass = false
		local okP = pcall(function() return MarketplaceService:GetProductInfo(id, Enum.InfoType.Product) end)
		if not okP then
			isPass = pcall(function() return MarketplaceService:GetProductInfo(id, Enum.InfoType.GamePass) end)
		end
		local ok, err = pcall(function()
			if isPass then MarketplaceService:PromptGamePassPurchase(player, id)
			else MarketplaceService:PromptProductPurchase(player, id) end
		end)
		if not ok then warn("[EvaK] покупка не открылась: " .. tostring(err)) end
	end
	b1.MouseButton1Click:Connect(function() buyPack(2081810443) end)
	b2.MouseButton1Click:Connect(function() buyPack(2082098430) end)
	plus.MouseButton1Click:Connect(function() packs.Visible = not packs.Visible end)

	local list = Instance.new("ScrollingFrame")
	list.Position = UDim2.fromOffset(24, 62); list.Size = UDim2.fromOffset(592, 310); list.BackgroundTransparency = 1
	list.BorderSizePixel = 0; list.ScrollBarThickness = 5; list.CanvasSize = UDim2.fromOffset(0, #TAB_TOYS * 44)
	list.Parent = panel

	local msg = lbl(panel, "", 14, 24, 378, 592, Color3.fromRGB(255, 120, 100), Enum.TextXAlignment.Center)
	local rows = {}
	local function owned(id: string): boolean
		return string.find("," .. (player:GetAttribute("OwnedToys") or "") .. ",", "," .. id .. ",", 1, true) ~= nil
	end
	local function teamN(id: string): number
		local n = 0
		for t in string.gmatch(player:GetAttribute("EquippedToy") or "", "[^,]+") do if t == id then n += 1 end end
		return n
	end
	local function cntOf(id: string): number
		for k, n in string.gmatch(player:GetAttribute("ToyCounts") or "", "([^,:]+):(%d+)") do if k == id then return tonumber(n) or 0 end end
		return owned(id) and 1 or 0
	end
	local function teamSize(): number
		local n = 0
		for _ in string.gmatch(player:GetAttribute("EquippedToy") or "", "[^,]+") do n += 1 end
		return n
	end
	local function refresh()
		badgeLbl.Text = "BADGES: " .. tostring(player:GetAttribute("Badges") or 0)
		for id, r in rows do
			if teamN(id) > 0 then r.b.Text = "EQUIPPED " .. teamN(id) .. "/" .. cntOf(id); r.b.BackgroundColor3 = Color3.fromRGB(50, 70, 36)
			elseif owned(id) then r.b.Text = "EQUIP"; r.b.BackgroundColor3 = Color3.fromRGB(36, 26, 16)
			else r.b.Text = "BUY"; r.b.BackgroundColor3 = Color3.fromRGB(70, 46, 20) end
		end
	end
	local function act(action: string, id: string)
		if not shopRF then msg.Text = "Shop offline (no EvaKServer)"; return end
		local ok, res = pcall(function() return shopRF:InvokeServer(action, id) end)
		if ok and type(res) == "table" and res.ok then msg.Text = "" else
			local m = ok and type(res) == "table" and tostring(res.msg) or "error"
			msg.Text = (m == "not enough badges") and "NOT ENOUGH BADGES" or string.upper(m)
		end
	end
	for i, t in TAB_TOYS do
		local id, name, rar, cost = t[1], t[2], t[3], t[4]
		local row = Instance.new("Frame")
		row.Position = UDim2.fromOffset(0, (i - 1) * 44); row.Size = UDim2.fromOffset(580, 38)
		row.BackgroundColor3 = Color3.fromRGB(24, 18, 12); row.BorderSizePixel = 0; row.Parent = list
		local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(0, 6); rc.Parent = row
		lbl(row, name, 16, 12, 9, 210, TXT)
		lbl(row, string.upper(rar), 12, 230, 12, 110, RARITY_COL[rar])
		lbl(row, tostring(cost) .. " B", 16, 350, 9, 80, GOLDC)
		local b = btn(row, "BUY", 450, 4, 120, 30)
		rows[id] = { b = b }
		b.MouseButton1Click:Connect(function()
			if not owned(id) then act("BuyToy", id)
			elseif teamN(id) > 0 and (teamN(id) >= cntOf(id) or teamSize() >= 3) then act("Unequip", id)
			else act("EquipToy", id) end
		end)
	end
	for _, n in { "Badges", "OwnedToys", "EquippedToy", "ToyCounts" } do
		table.insert(tabConns, player:GetAttributeChangedSignal(n):Connect(refresh))
	end
	refresh()

	local resume = btn(panel, "RESUME  [TAB]", 24, 424, 280, 42)
	local exit = btn(panel, "EXIT GAME", 336, 424, 280, 42, Color3.fromRGB(80, 24, 20))
	resume.MouseButton1Click:Connect(closeTabMenu)
	local sure = false
	exit.MouseButton1Click:Connect(function()
		if not sure then
			sure = true; exit.Text = "CLICK AGAIN TO EXIT"
			task.delay(2.5, function() if exit.Parent then sure = false; exit.Text = "EXIT GAME" end end)
			return
		end
		if world then world:FireServer("Exit") end
		closeTabMenu()
	end)
end

UIS.InputBegan:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.Tab and (active or fxGui:FindFirstChild("Overlay")) then
		if tabGui then closeTabMenu() else openTabMenu() end
	end
end)

local gotDrop = false
if world then
	world.OnClientEvent:Connect(function(kind, a, b)
		if kind == "Drop" then
			gotDrop = true
			smoothFadeIn(4.5)
				runStartZ, doorTotal, doorsBroken = a, b or 100, 0
			dropping = true
			startWind()
			nyAudio(player:GetAttribute("Difficulty") == "newyear")
		elseif kind == "HP" then
				setHp(a or 100)
			elseif kind == "Loot" then
				showLoot(a or 0)
			elseif kind == "LootNote" then
				task.delay(0.6, function() lootLbl.Text = tostring(a); lootLbl.TextTransparency = 0; lls.Transparency = 0; lootLbl.Position = UDim2.new(0.5, 0, 1, -150); lootLbl.Visible = true
					TweenService:Create(lootLbl, TweenInfo.new(1.8), { Position = UDim2.new(0.5, 0, 1, -196), TextTransparency = 1 }):Play()
					TweenService:Create(lls, TweenInfo.new(1.8), { Transparency = 1 }):Play() end)
			elseif kind == "Food" then
				heldFood = a
				foodBtn.Visible = a ~= nil
				foodBtn.Text = a and (a .. "  -  CLICK TO THROW") or ""
			elseif kind == "Boss" then
				if a == nil then
					bossBar.Visible = false
				else
					bossBar.Visible = true
					bossFill:TweenSize(UDim2.fromScale(math.clamp(a / math.max(1, b or 1), 0, 1), 1), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.25, true)
				end
			elseif kind == "Shake" then
				shakeAmt = math.max(shakeAmt, a or 0.5)
			elseif kind == "Hide" then
				hiding = (a == true)
			elseif kind == "Doors" then
			doorsBroken, doorTotal = a or 0, b or doorTotal
			player:SetAttribute("EvaKDoorsNow", doorsBroken)
		elseif kind == "Landed" then
			dropping = false
			landedFx()
		elseif kind == "Warn" then
			warnTotal = (a or 3) + 1.5
			warnUntil = os.clock() + warnTotal
			chaseUntil = os.clock() + warnTotal + 1.5
			shakeAmt = math.max(shakeAmt, 0.3)
			sfxPlay(CFG.WarnSoundId, 0.9)
		elseif kind == "Scare" then
			jumpscare()
		elseif kind == "Dead" then
			heldFood = nil; foodBtn.Visible = false; bossBar.Visible = false
			deadFx()
		elseif kind == "Complete" then
			heldFood = nil; foodBtn.Visible = false; bossBar.Visible = false
			completeFx()
		elseif kind == "TheEnd" then
			local f = Instance.new("Frame")
			f.Name = "Overlay"; f.Size = UDim2.fromScale(1, 1); f.BackgroundColor3 = Color3.new(0, 0, 0); f.BorderSizePixel = 0
			f.BackgroundTransparency = 1; f.ZIndex = 50
			f.Parent = fxGui
			TweenService:Create(f, TweenInfo.new(1.6), { BackgroundTransparency = 0 }):Play()
			bigText("THE END", Color3.fromRGB(246, 226, 182))
			task.spawn(function()
				task.wait(3.5)
				for _, ch in fxGui:GetChildren() do
					if ch:IsA("TextLabel") and ch.Name == "Overlay" then
						TweenService:Create(ch, TweenInfo.new(0.8), { TextTransparency = 1 }):Play()
						task.delay(0.9, function() ch:Destroy() end)
					end
				end
				task.wait(1.2)
				local lines = {
					{ "Are you satisfied?", Color3.fromRGB(230, 225, 215), 3.2 },
					{ "This is only the beginning", Color3.fromRGB(200, 60, 50), 3.6 },
					{ "You... are the one who stayed!", Color3.fromRGB(255, 20, 20), 4.0 },
				}
				if a == "angel" then
					lines = { { "You endured it all", Color3.fromRGB(240, 232, 210), 3.0 }, { "and stayed clean", Color3.fromRGB(255, 225, 130), 3.0 }, { "Something above is watching...", Color3.fromRGB(255, 240, 170), 3.0 } }
				elseif a == "demon" then
					lines = { { "So much blood...", Color3.fromRGB(230, 225, 215), 3.0 }, { "It is on your hands now", Color3.fromRGB(200, 60, 50), 3.0 }, { "Something inside you woke up...", Color3.fromRGB(255, 20, 20), 3.0 } }
				end
				for _, ln in lines do
					local l = Instance.new("TextLabel")
					l.Name = "EndLine"; l.AnchorPoint = Vector2.new(0.5, 0.5); l.Position = UDim2.fromScale(0.5, 0.5)
					l.Size = UDim2.fromOffset(900, 80); l.BackgroundTransparency = 1; l.Font = Enum.Font.Arcade
					l.TextSize = 42; l.TextColor3 = ln[2]; l.Text = ln[1]; l.TextTransparency = 1; l.ZIndex = 70
					l.Parent = fxGui
					TweenService:Create(l, TweenInfo.new(0.9), { TextTransparency = 0 }):Play()
					task.wait(ln[3])
					TweenService:Create(l, TweenInfo.new(0.7), { TextTransparency = 1 }):Play()
					task.delay(0.8, function() l:Destroy() end)
					task.wait(0.9)
				end
			end)
		elseif kind == "Revive" then
			if resultsGui then resultsGui:Destroy(); resultsGui = nil end
			for _, ch in fxGui:GetChildren() do
				if ch.Name == "Overlay" then ch:Destroy() end
			end
			UIS.MouseIconEnabled = false
			hiding = false; dropping = false
			shakeAmt = 0
			nyAudio(player:GetAttribute("Difficulty") == "newyear")
		elseif kind == "Results" and type(a) == "table" then
			nyAudio(false)
			if a.finale then return end   -- после финала сразу в лобби, без экрана результатов
			task.delay(a.win and 2.2 or 1.6, function() showResults(a) end)
		end
	end)
end


-- ============================================================
-- ГЛАЗА НА СТЕНАХ: зрачки поворачиваются на игрока (локально, сервер ничего не шлёт)
-- ============================================================
do
	local CollectionService = game:GetService("CollectionService")
	local eyeList: {any} = {}
	local function addEye(m: Instance)
		local sc, pu = m:WaitForChild("Sclera", 5), m:WaitForChild("Pupil", 5)
		if sc and pu then
			local fol = {}
			for _, ch in m:GetChildren() do
				if ch:IsA("BasePart") and ch:GetAttribute("Follow") then
					table.insert(fol, { p = ch, off = ch.Position - pu.Position })
				end
			end
			table.insert(eyeList, { m = m, sc = sc, pu = pu, fol = fol, n = sc:GetAttribute("Nrm"), orbit = sc:GetAttribute("Orbit"), base = pu.Position })
		end
	end
	CollectionService:GetInstanceAddedSignal("EvaKEye"):Connect(function(m) task.spawn(addEye, m) end)
	for _, m in CollectionService:GetTagged("EvaKEye") do task.spawn(addEye, m) end

	local acc = 0
	RunService.RenderStepped:Connect(function(dt)
		acc += dt
		if acc < 0.03 then return end   -- ~30 раз в секунду
		acc = 0
		local cam = camera.CFrame.Position
		for i = #eyeList, 1, -1 do
			local e = eyeList[i]
			if not e.m:IsDescendantOf(workspace) then
				table.remove(eyeList, i)
			else
				local c = e.sc.Position
				local v = cam - c
				local d = v.Magnitude
				if d < 110 and d > 0.5 then
					local dir = v / d
					if e.n and e.orbit then
						local lat = dir - e.n * dir:Dot(e.n)
						local np = e.base + lat * e.orbit
						e.pu.Position = np
						for _, f in e.fol do f.p.Position = np + f.off end
					else
						e.pu.Position = c + dir * (e.sc.Size.X * 0.37)
					end
				end
			end
		end
	end)
end

-- ============================================================
-- Запуск после меню / выключение при возврате в лобби
-- ============================================================
local function activate()
	if active then return end
	active = true
	pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false) end)
	player.CameraMode = Enum.CameraMode.LockFirstPerson
	if false and not playerGui:FindFirstChild("EvaKRain") then   -- фоновый дождь отключён (странные звуки на фоне)
		local rn = Instance.new("Sound")
		rn.Name = "EvaKRain"; rn.SoundId = "rbxassetid://125355642447331"; rn.Looped = true; rn.Volume = 0.15
		rn.Parent = playerGui; rn:Play()
	end
	camera.FieldOfView = (player:GetAttribute("EvaKFov") and (60 + player:GetAttribute("EvaKFov") * 40) or CFG.BaseFov)
	touchButtons()
	startTentacles()
	showHint()
	-- сервер создаёт карту и роняет в шахту; повторяем запрос, пока не придёт "Drop"
	gotDrop = false
	task.spawn(function()
		for _ = 1, 8 do
			if not active or gotDrop then return end
			if world then world:FireServer("Begin") end
			task.wait(1)
		end
		if not active or gotDrop then return end
		warn("[EvaK] сервер не ответил на старт забега: положи EvaKMap.server.lua в ServerScriptService (Script)")
		local g = Instance.new("ScreenGui"); g.Name = "EvaKErr"; g.ResetOnSpawn = false; g.Parent = playerGui
		local l = Instance.new("TextLabel")
		l.Size = UDim2.fromScale(1, 0.1); l.BackgroundColor3 = Color3.fromRGB(120, 20, 20)
		l.TextColor3 = Color3.new(1, 1, 1); l.Font = Enum.Font.Arcade; l.TextScaled = true
		l.Text = "EvaK: сервер карты не ответил (EvaKMap.server.lua в ServerScriptService?)"
		l.Parent = g
		task.delay(8, function() g:Destroy() end)
	end)
end

local function deactivate()
	if not active then return end
	active = false
	pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, true) end)
	closeTabMenu()
	dropping, shakeAmt, runLen, warnUntil, chaseUntil = false, 0, 0, 0, 0
	hiding = false
	hpVal = 100; hpFill.Size = UDim2.fromScale(1, 1); hpLbl.Text = "100"
	doorTotal, doorsBroken = 0, 0
	player.CameraMode = Enum.CameraMode.Classic
	UIS.MouseBehavior = Enum.MouseBehavior.Default   -- мышь сразу свободна в лобби
	task.spawn(function()
		for _ = 1, 30 do
			if active then return end
			UIS.MouseBehavior = Enum.MouseBehavior.Default
			task.wait(0.05)
		end
	end)
	local rn0 = playerGui:FindFirstChild("EvaKRain")
	if rn0 then rn0:Destroy() end
	if tentGui then tentGui:Destroy(); tentGui = nil end
	if touchGui then touchGui:Destroy(); touchGui = nil end
	if resultsGui then resultsGui:Destroy(); resultsGui = nil end
	for _, c in fxGui:GetChildren() do
		if c.Name == "Overlay" or c.Name == "Wind" then c:Destroy() end
	end
end

local function onIntro()
	if player:GetAttribute("IntroDone") then activate() else deactivate() end
end
player:GetAttributeChangedSignal("IntroDone"):Connect(onIntro)
onIntro()

-- ============================================================
-- Всплывающее окно достижения (BADGES)
-- ============================================================
task.spawn(function()
	local ev = ReplicatedStorage:WaitForChild("EvaKAchNotify", 30)
	if not ev then return end
	local gui = Instance.new("ScreenGui")
	gui.Name = "EvaKAchToast"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 700
	gui.Parent = playerGui
	local achEv: RemoteEvent = ev :: RemoteEvent
	achEv.OnClientEvent:Connect(function(name: string, desc: string, reward: number)
		local CREAM = Color3.fromRGB(255, 229, 200)
		local root = Instance.new("Frame")
		root.AnchorPoint = Vector2.new(1, 0); root.Position = UDim2.new(1, 460, 0, 150); root.Size = UDim2.fromOffset(430, 118)
		root.BackgroundTransparency = 1; root.Parent = gui
		local hd = Instance.new("TextLabel")
		hd.BackgroundTransparency = 1; hd.Size = UDim2.fromOffset(430, 24); hd.Font = Enum.Font.GothamBlack; hd.TextSize = 17; hd.TextColor3 = CREAM
		hd.TextXAlignment = Enum.TextXAlignment.Left; hd.Text = "UNLOCKED ACHIEVEMENT"; hd.Parent = root
		local f = Instance.new("Frame")
		f.Position = UDim2.fromOffset(0, 28); f.Size = UDim2.fromOffset(430, 86); f.BackgroundColor3 = Color3.fromRGB(34, 22, 22); f.BorderSizePixel = 0; f.Parent = root
		local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 16); c.Parent = f
		local st = Instance.new("UIStroke"); st.Color = CREAM; st.Thickness = 3; st.Parent = f
		local ic = Instance.new("Frame")
		ic.Position = UDim2.fromOffset(10, 10); ic.Size = UDim2.fromOffset(66, 66); ic.BackgroundColor3 = Color3.fromRGB(150, 36, 40); ic.BorderSizePixel = 0; ic.Parent = f
		local ic2 = Instance.new("UICorner"); ic2.CornerRadius = UDim.new(1, 0); ic2.Parent = ic
		local ig = Instance.new("TextLabel")
		ig.BackgroundTransparency = 1; ig.Size = UDim2.fromScale(1, 1); ig.Font = Enum.Font.GothamBlack; ig.TextSize = 34; ig.TextColor3 = CREAM; ig.Text = "★"; ig.Parent = ic
		local function lab(t, y, h, sz, col)
			local l = Instance.new("TextLabel")
			l.BackgroundTransparency = 1; l.Position = UDim2.fromOffset(88, y); l.Size = UDim2.new(1, -140, 0, h)
			l.Font = Enum.Font.Oswald; l.TextSize = sz; l.TextColor3 = col; l.TextXAlignment = Enum.TextXAlignment.Left; l.TextYAlignment = Enum.TextYAlignment.Top
			l.TextWrapped = true; l.Text = t; l.Parent = f
		end
		lab(name, 6, 34, 30, CREAM)
		lab(desc, 40, 40, 19, Color3.fromRGB(226, 196, 170))
		local rw = Instance.new("TextLabel")
		rw.BackgroundTransparency = 1; rw.AnchorPoint = Vector2.new(1, 0); rw.Position = UDim2.new(1, -12, 0, 8); rw.Size = UDim2.fromOffset(60, 26)
		rw.Font = Enum.Font.Oswald; rw.TextSize = 24; rw.TextColor3 = Color3.fromRGB(255, 214, 120); rw.TextXAlignment = Enum.TextXAlignment.Right; rw.Text = "+" .. tostring(reward); rw.Parent = f
		TweenService:Create(root, TweenInfo.new(0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Position = UDim2.new(1, -24, 0, 150) }):Play()
		task.delay(4.5, function()
			TweenService:Create(root, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.In), { Position = UDim2.new(1, 460, 0, 150) }):Play()
			task.delay(0.6, function() root:Destroy() end)
		end)
	end)
end)
