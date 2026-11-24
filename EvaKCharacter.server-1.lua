-- ============================================================
--  EvaK CHARACTER  (Script)
--  Куда положить: ServerScriptService > Script
--  Делает: чёрный квадратный скин у всех, отключает стандартные анимации
--  (их заменяет EvaKGameplay на клиенте), движение с разгоном, присед, батончик.
--  ВАЖНО: Game Settings > Avatar > Avatar Type = R15.
-- ============================================================

local CONFIG = {
	Walk = 6,               -- медленный старт шага
	Sprint = 21,            -- быстрый бег (включается сам)
	RunDelay = 0.8,         -- через сколько секунд ходьбы начинается ускорение
	Crouch = 5,             -- присед (C / Ctrl)
	Accel = 14,             -- разгон, studs/s за секунду (шаг -> бег ~1.4 c)
	Decel = 28,             -- торможение
	OverdriveAfter = 3,     -- через сколько секунд непрерывного бега начинается "второе дыхание"
	OverdriveMax = 2,       -- максимум добавки к скорости
	OverdriveRate = 2,      -- добавка за секунду
	JumpHeight = 7.5,
	CrouchDrop = 1.0,       -- насколько ниже тело в приседе (studs)
	BarMult = 1.6,          -- батончик: множитель скорости
	BarSeconds = 12,
}

local BLACK = Color3.fromRGB(14, 12, 14)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

-- ------------------------------------------------------------
-- 1) Пустой "Animate": стандартные анимации не запускаются
-- ------------------------------------------------------------
local scs = StarterPlayer:FindFirstChild("StarterCharacterScripts")
if scs and not scs:FindFirstChild("Animate") then
	local stub = Instance.new("LocalScript")
	stub.Name = "Animate"
	stub.Parent = scs
end

-- ------------------------------------------------------------
-- 2) Чёрный скин (скруглённая голова, блочное тело)
-- ------------------------------------------------------------
local DECOR = { Collar = true, ZipLine = true, PocketL = true, PocketR = true, Belt = true, Buckle = true, Sole = true, Cuff = true }
local function paintPart(p: BasePart)
	p.Color = BLACK
	p.Material = Enum.Material.SmoothPlastic
	if p:IsA("MeshPart") then pcall(function() p.TextureID = "" end) end
end

local function applySkin(char: Model)
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None end

	for _, d in char:GetDescendants() do
		if d:IsA("Accessory") or d:IsA("Shirt") or d:IsA("Pants") or d:IsA("ShirtGraphic") or d:IsA("CharacterMesh") then
			d:Destroy()
		elseif d:IsA("BodyColors") then
			d.HeadColor3, d.TorsoColor3, d.LeftArmColor3, d.RightArmColor3, d.LeftLegColor3, d.RightLegColor3 =
				BLACK, BLACK, BLACK, BLACK, BLACK, BLACK
		elseif d:IsA("BasePart") and not DECOR[d.Name] then
			paintPart(d)
		end
	end

	-- реалистичнее: тканевая куртка, джинсовые ноги, кожаные ботинки, ремень, воротник, перчатки (видно, когда смотришь вниз)
	do
		local function weld(a: BasePart, b: BasePart, cf: CFrame)
			b.CFrame = a.CFrame * cf; b.Anchored = false; b.CanCollide = false; b.CanQuery = false; b.CanTouch = false; b.Massless = true
			local w = Instance.new("WeldConstraint"); w.Part0 = a; w.Part1 = b; w.Parent = b
		end
		local function bit(name: string, size: Vector3, color: Color3, mat: Enum.Material, parent: BasePart, cf: CFrame)
			if parent:FindFirstChild(name) then return end
			local p = Instance.new("Part"); p.Name = name; p.Size = size; p.Color = color; p.Material = mat
			p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth; p.Parent = parent
			weld(parent, p, cf)
		end
		local JACKET, DENIM, LEATHER = Color3.fromRGB(34, 28, 26), Color3.fromRGB(26, 30, 42), Color3.fromRGB(16, 11, 9)
		local function tone(n: string, c: Color3, m: Enum.Material)
			local bp = char:FindFirstChild(n)
			if bp and bp:IsA("BasePart") then bp.Color = c; bp.Material = m end
		end
		tone("UpperTorso", JACKET, Enum.Material.Fabric)
		tone("LowerTorso", DENIM, Enum.Material.Fabric)
		for _, sd in { "Left", "Right" } do
			tone(sd .. "UpperArm", JACKET, Enum.Material.Fabric); tone(sd .. "LowerArm", JACKET, Enum.Material.Fabric)
			tone(sd .. "Hand", LEATHER, Enum.Material.Fabric)
			tone(sd .. "UpperLeg", DENIM, Enum.Material.Fabric); tone(sd .. "LowerLeg", DENIM, Enum.Material.Fabric)
			tone(sd .. "Foot", LEATHER, Enum.Material.Fabric)
		end
		local ut, lt = char:FindFirstChild("UpperTorso") :: BasePart?, char:FindFirstChild("LowerTorso") :: BasePart?
		if ut then
			bit("Collar", Vector3.new(ut.Size.X + 0.1, 0.35, ut.Size.Z + 0.1), Color3.fromRGB(20, 16, 15), Enum.Material.Fabric, ut, CFrame.new(0, ut.Size.Y / 2 - 0.1, 0))
			bit("ZipLine", Vector3.new(0.08, ut.Size.Y * 0.95, 0.06), Color3.fromRGB(110, 100, 90), Enum.Material.Metal, ut, CFrame.new(0, 0, -(ut.Size.Z / 2 + 0.02)))
			for _, dx in { -0.45, 0.45 } do
				bit("Pocket" .. (dx < 0 and "L" or "R"), Vector3.new(0.5, 0.5, 0.06), Color3.fromRGB(24, 19, 18), Enum.Material.Fabric, ut, CFrame.new(dx, -ut.Size.Y * 0.18, -(ut.Size.Z / 2 + 0.02)))
			end
		end
		if lt then
			bit("Belt", Vector3.new(lt.Size.X + 0.08, 0.28, lt.Size.Z + 0.08), LEATHER, Enum.Material.Fabric, lt, CFrame.new(0, lt.Size.Y / 2 - 0.18, 0))
			bit("Buckle", Vector3.new(0.32, 0.24, 0.07), Color3.fromRGB(190, 160, 70), Enum.Material.Metal, lt, CFrame.new(0, lt.Size.Y / 2 - 0.18, -(lt.Size.Z / 2 + 0.06)))
		end
		for _, sd in { "Left", "Right" } do
			local ft = char:FindFirstChild(sd .. "Foot") :: BasePart?
			if ft then bit("Sole", Vector3.new(ft.Size.X + 0.06, 0.16, ft.Size.Z + 0.12), Color3.fromRGB(8, 7, 7), Enum.Material.SmoothPlastic, ft, CFrame.new(0, -ft.Size.Y / 2 + 0.04, -0.04)) end
			local ll = char:FindFirstChild(sd .. "LowerLeg") :: BasePart?
			if ll then bit("Cuff", Vector3.new(ll.Size.X + 0.08, 0.22, ll.Size.Z + 0.08), Color3.fromRGB(16, 20, 30), Enum.Material.Fabric, ll, CFrame.new(0, -ll.Size.Y / 2 + 0.12, 0)) end
			local la = char:FindFirstChild(sd .. "LowerArm") :: BasePart?
			if la then bit("Cuff", Vector3.new(la.Size.X + 0.08, 0.2, la.Size.Z + 0.08), Color3.fromRGB(14, 11, 10), Enum.Material.Fabric, la, CFrame.new(0, -la.Size.Y / 2 + 0.1, 0)) end
		end
	end

	local head = char:FindFirstChild("Head")
	if head then
		local face = head:FindFirstChildOfClass("Decal")
		if face then face:Destroy() end   -- голова остаётся скруглённой, просто чёрная
	end
end

-- ------------------------------------------------------------
-- 3) Движение: разгон, бег, присед, батончик
-- ------------------------------------------------------------
local states: {[Player]: any} = {}

local remote = Instance.new("RemoteEvent")
remote.Name = "EvaKMove"
remote.Parent = ReplicatedStorage

remote.OnServerEvent:Connect(function(plr: Player, kind: any, value: any)
	local st = states[plr]
	if not st then return end
	if kind == "Sprint" then
		st.sprint = (value == true)
	elseif kind == "Crouch" then
		st.crouch = (value == true)
		if plr.Character then plr.Character:SetAttribute("Crouch", st.crouch) end
	elseif kind == "Bar" then
		local items = "," .. (plr:GetAttribute("RunItems") or "") .. ","
		if string.find(items, ",BAR,", 1, true) and not st.barUsed then
			st.barUsed = true
			st.boostUntil = os.clock() + CONFIG.BarSeconds
		end
	end
end)

local function setupPlayer(plr: Player)
	states[plr] = { sprint = false, crouch = false, speed = CONFIG.Walk, sprintT = 0, barUsed = false, boostUntil = 0, ck = 0, baseHip = nil }
	plr:GetAttributeChangedSignal("RunItems"):Connect(function()
		local st = states[plr]
		if st then st.barUsed = false; st.boostUntil = 0 end
	end)

	plr.CharacterAdded:Connect(function(char)
		local st = states[plr]
		if st then st.sprint, st.crouch, st.speed, st.sprintT, st.ck, st.baseHip = false, false, CONFIG.Walk, 0, 0, nil end
		char:SetAttribute("Crouch", false)
		char:WaitForChild("Humanoid")
		local anim = char:FindFirstChild("Animate")
		if anim then anim:Destroy() end
		applySkin(char)
		char.DescendantAdded:Connect(function(d)
			if d:IsA("Accessory") or d:IsA("Shirt") or d:IsA("Pants") or d:IsA("ShirtGraphic") then
				task.defer(function() d:Destroy() end)
			end
		end)
	end)
	plr.CharacterAppearanceLoaded:Connect(function(char) applySkin(char) end)
end

Players.PlayerAdded:Connect(setupPlayer)
for _, p in Players:GetPlayers() do setupPlayer(p) end
Players.PlayerRemoving:Connect(function(p) states[p] = nil end)

local function approach(cur: number, target: number, step: number): number
	if cur < target then return math.min(target, cur + step) end
	return math.max(target, cur - step)
end

RunService.Heartbeat:Connect(function(dt)
	for plr, st in states do
		local char = plr.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hum and hrp and hum.Health > 0 then
			local v = hrp.AssemblyLinearVelocity
			local moving = Vector3.new(v.X, 0, v.Z).Magnitude > 1.5 or hum.MoveDirection.Magnitude > 0.1

			local target
			if st.crouch then
				st.sprintT = 0
				target = CONFIG.Crouch
			elseif moving then
				st.sprintT += dt
				if st.sprintT < CONFIG.RunDelay then
					target = CONFIG.Walk
				else
					local over = math.clamp((st.sprintT - CONFIG.RunDelay - CONFIG.OverdriveAfter) * CONFIG.OverdriveRate, 0, CONFIG.OverdriveMax)
					target = CONFIG.Sprint + over
				end
			else
				st.sprintT = 0
				target = CONFIG.Walk
			end
			local parkour = plr:GetAttribute("EvaKParkour") == true
			if parkour and not st.crouch then target = 15 end   -- паркур: без разгона, скорость сразу ровная
			local stunned = (char:GetAttribute("StunUntil") or 0) > os.clock()
			if stunned then target = 0 end
			target *= (plr:GetAttribute("SpeedMult") or 1)
			if os.clock() < st.boostUntil then target *= CONFIG.BarMult end

			-- разгон медленный, торможение быстрое
			st.speed = parkour and target or approach(st.speed, target, (target > st.speed and CONFIG.Accel or CONFIG.Decel) * dt)
			hum.WalkSpeed = st.speed
			hum.UseJumpPower = false
			hum.JumpHeight = (st.crouch or stunned) and 0 or CONFIG.JumpHeight

			-- присед: тело реально ниже (можно пролезть под низким потолком)
			if not st.baseHip and hum.HipHeight > 0.5 then st.baseHip = hum.HipHeight end
			if st.baseHip then
				st.ck += ((st.crouch and 1 or 0) - st.ck) * math.min(1, 10 * dt)
				hum.HipHeight = st.baseHip - CONFIG.CrouchDrop * st.ck
			end
		end
	end
end)
