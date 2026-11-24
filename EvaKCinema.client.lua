-- ============================================================
--  EvaKCinema  (LocalScript в StarterPlayerScripts)
--  «Кинематографичный» слой реализма и страха, всё кодом, без чужих ассетов:
--   1) тряска камеры по системе trauma (удар, дверь, монстр рядом) + живое дрожание «ручной камеры» и дыхание
--   2) страх от близости монстров (атрибут EvaKFear) -> усиливает виньетку/пульс в EvaKAtmosphere
--   3) неисправные лампы мерцают, остальные «дышат»; у игрока в руке свет не трогаем
--   4) пылинки в воздухе вокруг камеры
--   5) тёмная экспозиция только во время забега, размытие/глубина резкости при низком HP и после ударов
--  Технологию освещения Future выставь вручную: Lighting -> Technology = Future (скрипт сделать это не может).
-- ============================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local CollectionService = game:GetService("CollectionService")

local player = Players.LocalPlayer
local cam = workspace.CurrentCamera

local function set(o, p, v) pcall(function() o[p] = v end) end
local function low() return player:GetAttribute("EvaKLowEnd") == true end
local function inRun() return player:GetAttribute("IntroDone") == true end

-- ---------- 1. trauma-тряска ----------
local trauma = 0
local function kick(v: number) trauma = math.clamp(trauma + v, 0, 1) end

player:GetAttributeChangedSignal("EvaKHpNow"):Connect(function()
	local hp = player:GetAttribute("EvaKHpNow") or 100
	local prev = player:GetAttribute("EvaKCinemaHp") or 100
	if hp < prev then kick(0.35 + (prev - hp) / 60) end
	player:SetAttribute("EvaKCinemaHp", hp)
end)
player:GetAttributeChangedSignal("EvaKDoorsNow"):Connect(function() kick(0.22) end)
player:GetAttributeChangedSignal("EvaKTraumaKick"):Connect(function()   -- любой скрипт: player:SetAttribute("EvaKTraumaKick", число 0..1)
	kick(tonumber(player:GetAttribute("EvaKTraumaKick")) or 0.3)
end)

local fear = 0
local walkK, walkPh = 0, 0
local t0 = os.clock()
RunService:BindToRenderStep("EvaKCinemaShake", Enum.RenderPriority.Camera.Value + 2, function(dt)
	cam = workspace.CurrentCamera
	if not cam or not inRun() then trauma = 0; return end
	local t = os.clock() - t0
	local hp = player:GetAttribute("EvaKHpNow") or 100
	local lowHp = math.clamp((55 - hp) / 55, 0, 1)
	trauma = math.max(0, trauma - dt * 0.9)
	local sh = trauma * trauma
	local hand = 0.12 + fear * 0.5 + lowHp * 0.35          -- постоянная дрожь рук, растёт от страха и слабого HP (в градусах)
	local breath = math.sin(t * (1.1 + lowHp * 1.6)) * (0.05 + lowHp * 0.18)
	local n1, n2, n3 = math.noise(t * 2.1, 0.3), math.noise(0.7, t * 2.3), math.noise(t * 1.7, 5.1)
	local amp = hand + sh * 5.5
	local pitch = math.rad((n1 * amp + breath))
	local yaw = math.rad(n2 * amp)
	local roll = math.rad(n3 * amp * 0.8 + sh * math.noise(t * 14, 2.2) * 4)
	-- шаги: покачивание синхронно с ходьбой
	local ch = player.Character
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	local root = ch and ch:FindFirstChild("HumanoidRootPart")
	local spd = 0
	if hum and root and hum.Health > 0 then
		local v = root.AssemblyLinearVelocity
		spd = Vector3.new(v.X, 0, v.Z).Magnitude
	end
	walkK = walkK + (math.clamp(spd / 16, 0, 1.4) - walkK) * math.min(1, dt * 8)
	if game:GetService("Players").LocalPlayer:GetAttribute("EvaKReduceMotion") == true then walkK = 0 end
	walkPh = walkPh + dt * spd * 0.62
	local shk = (game:GetService("Players").LocalPlayer:GetAttribute("EvaKShake") or 0.5) * 2   -- ползунок Camera Shake в настройках
	local bobY = math.sin(walkPh * 2) * 0.028 * walkK * shk
	local bobX = math.cos(walkPh) * 0.02 * walkK * shk
	local wRoll = math.cos(walkPh) * math.rad(0.35) * walkK * shk
	local wPitch = math.abs(math.sin(walkPh)) * math.rad(0.28) * walkK * shk
	cam.CFrame = cam.CFrame * CFrame.new(bobX, bobY, 0) * CFrame.Angles(pitch + wPitch, yaw, roll + wRoll)
end)

-- ---------- 2. страх от монстров ----------
local monsters: {[Instance]: boolean} = {}
local function consider(i: Instance)
	if i:IsA("Model") and (i:GetAttribute("EvaKMonster") or CollectionService:HasTag(i, "EvaKEye") or CollectionService:HasTag(i, "EvaKEyesEntity")) then monsters[i] = true end
end
-- ---------- жуткий слой для монстров: красный мигающий свет, чёрная капель, дёрганые «сбои» ----------
local CREEPY = { Crawler = true, Slime = true, ZombieGirl = true, EyesEntity = true, Eye = true }
local creeped: {[Instance]: boolean} = {}
local function creep(m: Instance)
	if creeped[m] or not m:IsA("Model") or not CREEPY[m.Name] then return end
	creeped[m] = true
	monsters[m] = true
	task.defer(function()
		local root = m:FindFirstChildWhichIsA("BasePart", true)
		if not root then return end
		local l = Instance.new("PointLight"); l.Color = Color3.fromRGB(255, 25, 15); l.Range = 22; l.Brightness = 1.6; l.Shadows = false; l.Parent = root
		local pe = Instance.new("ParticleEmitter")
		pe.Texture = "rbxasset://textures/particles/smoke_main.dds"; pe.Color = ColorSequence.new(Color3.fromRGB(8, 0, 0))
		pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 3.2) })
		pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 1) })
		pe.Lifetime = NumberRange.new(1.2, 2.2); pe.Rate = 14; pe.Speed = NumberRange.new(0.5, 2); pe.Acceleration = Vector3.new(0, -2, 0)
		pe.SpreadAngle = Vector2.new(180, 180); pe.LightEmission = 0; pe.Parent = root
		task.spawn(function()
			while m.Parent do
				task.wait(0.05 + math.random() * 0.12)
				-- красная вспышка + дрожь света, как будто оно «глючит»
				l.Brightness = (math.random() < 0.25) and (3 + math.random() * 3) or (0.4 + math.random() * 1.4)
				if math.random() < 0.04 then
					l.Color = Color3.fromRGB(255, 255, 255); task.wait(0.06); l.Color = Color3.fromRGB(255, 25, 15)
				end
				if math.random() < 0.03 then   -- мгновенное исчезновение и возврат
					for _, d in m:GetDescendants() do if d:IsA("BasePart") then d.LocalTransparencyModifier = 1 end end
					task.wait(0.07)
					for _, d in m:GetDescendants() do if d:IsA("BasePart") then d.LocalTransparencyModifier = 0 end end
				end
			end
		end)
	end)
end
workspace.DescendantAdded:Connect(function(i) if i:IsA("Model") and CREEPY[i.Name] then creep(i) end end)
for _, d in workspace:GetDescendants() do if d:IsA("Model") and CREEPY[d.Name] then creep(d) end end
for _, c in workspace:GetChildren() do consider(c) end
workspace.ChildAdded:Connect(function(c) task.defer(consider, c) end)
for _, tag in { "EvaKEye", "EvaKEyesEntity" } do
	for _, i in CollectionService:GetTagged(tag) do consider(i) end
	CollectionService:GetInstanceAddedSignal(tag):Connect(consider)
end
task.spawn(function()
	while true do
		task.wait(0.25)
		local best = 0
		if inRun() and cam then
			local p = cam.CFrame.Position
			for m in monsters do
				if not m.Parent then monsters[m] = nil
				else
					local ok, pos = pcall(function() return m:GetPivot().Position end)
					if ok then
						local d = (pos - p).Magnitude
						best = math.max(best, math.clamp(1 - d / 50, 0, 1))
					end
				end
			end
		end
		fear += (best - fear) * 0.6
		player:SetAttribute("EvaKFear", math.floor(fear * 100) / 100)
		if best > 0.75 then kick(0.04) end   -- совсем близко: лёгкая дрожь
	end
end)

-- ---------- 3. мерцание ламп ----------
local lamps: {[Light]: {base: number, faulty: boolean, seed: number}} = {}
local function trackLamp(l: Instance)
	if (l:IsA("PointLight") or l:IsA("SpotLight") or l:IsA("SurfaceLight")) and not l:FindFirstAncestorOfClass("Humanoid") then
		if l:FindFirstAncestorWhichIsA("Model") and Players:GetPlayerFromCharacter(l:FindFirstAncestorWhichIsA("Model")) then return end
		if l:GetAttribute("EvaKNoFlicker") then return end
		lamps[l] = { base = l.Brightness, faulty = math.random() < 0.18, seed = math.random() * 100 }
	end
end
for _, d in workspace:GetDescendants() do trackLamp(d) end
workspace.DescendantAdded:Connect(function(d) task.defer(trackLamp, d) end)
workspace.DescendantRemoving:Connect(function(d) lamps[d :: any] = nil end)

local acc = 0
RunService.Heartbeat:Connect(function(dt)
	acc += dt
	if acc < 0.08 or not cam then return end
	acc = 0
	if not inRun() or low() then return end
	local p = cam.CFrame.Position
	local t = os.clock()
	for l, info in lamps do
		local par = l.Parent
		if not par or not par:IsA("BasePart") then continue end
		if (par.Position - p).Magnitude > 70 then continue end
		local b = info.base * (1 + math.noise(t * 0.7, info.seed) * 0.06)    -- лёгкое «дыхание»
		if info.faulty then
			local n = math.noise(t * 3.3, info.seed + 9)
			if n > 0.32 then b *= 0.1 + math.random() * 0.4      -- провал света
			elseif n < -0.55 then b *= 1.35 end                  -- всплеск
		end
		set(l, "Brightness", b)
	end
end)

-- ---------- 4. пылинки ----------
local dust = Instance.new("Part")
dust.Name = "EvaKDust"; dust.Anchored = true; dust.CanCollide = false; dust.CanQuery = false; dust.CanTouch = false
dust.Transparency = 1; dust.Size = Vector3.new(44, 16, 44); dust.Parent = workspace
local em = Instance.new("ParticleEmitter")
em.Texture = "rbxasset://textures/particles/sparkles_main.dds"
em.Rate = 22; em.Lifetime = NumberRange.new(7, 11); em.Speed = NumberRange.new(0.05, 0.3)
em.SpreadAngle = Vector2.new(180, 180); em.Rotation = NumberRange.new(0, 360); em.RotSpeed = NumberRange.new(-20, 20)
em.Size = NumberSequence.new(0.07, 0.12); em.LightEmission = 0.5; em.LightInfluence = 0.4
em.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, 0.55), NumberSequenceKeypoint.new(0.8, 0.55), NumberSequenceKeypoint.new(1, 1) })
em.Color = ColorSequence.new(Color3.fromRGB(200, 170, 130))
em.Shape = Enum.ParticleEmitterShape.Box; em.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
em.Enabled = false; em.Parent = dust
RunService.Heartbeat:Connect(function()
	if cam then dust.CFrame = CFrame.new(cam.CFrame.Position) end
	em.Enabled = inRun() and not low()
end)

-- ---------- 5. экспозиция, размытие, фокус ----------
local function fx(class: string, name: string)
	local e = Lighting:FindFirstChild(name)
	if not e then e = Instance.new(class); e.Name = name; (e :: any).Enabled = false; e.Parent = Lighting end
	return e :: any
end
local blur = fx("BlurEffect", "EvaKCinemaBlur"); blur.Size = 0
local dof = fx("DepthOfFieldEffect", "EvaKCinemaDoF")
local baseExposure = Lighting.ExposureCompensation
RunService.RenderStepped:Connect(function(dt)
	if not inRun() then
		blur.Enabled = false; dof.Enabled = false
		Lighting.ExposureCompensation = baseExposure
		return
	end
	local hp = player:GetAttribute("EvaKHpNow") or 100
	local lowHp = math.clamp((50 - hp) / 50, 0, 1)
	Lighting.ExposureCompensation += ((baseExposure - 0.05 - fear * 0.15) - Lighting.ExposureCompensation) * math.min(1, dt * 2)
	blur.Enabled = not low()
	blur.Size = trauma * 10 + lowHp * 4 + fear * 2
	dof.Enabled = not low() and (lowHp > 0 or fear > 0.4)
	dof.FarIntensity = 0.25 + lowHp * 0.5
	dof.NearIntensity = lowHp * 0.2
	dof.FocusDistance = 18 - lowHp * 10
	dof.InFocusRadius = 20 - lowHp * 12
end)
