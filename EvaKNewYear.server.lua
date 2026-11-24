-- ============================================================
--  EvaK NEW YEAR  (Script)  -  ServerScriptService > Script
--  Новогодний ивент: ёлки с игрушками, гирлянды в коридорах и ёлки в лобби.
--  Включается админ-панелью (Workspace attribute EvaKNewYear). Снег рисует клиент (EvaKNewYear.client).
--  Нужен обновлённый EvaKMap.server.lua (он сообщает о новых сегментах через EvaKSegmentBuilt).
-- ============================================================
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")

-- ============================================================
--  ЗВУКИ НОВОГО ГОДА: впиши ID (rbxassetid://...). Пусто = звука нет.
--  Music   - Jingle Bells, играет фоном на сложности NEW YEAR (и в меню NEW YEAR)
--  HoHoHo  - смех Санты, когда вылетает тёмный Санта-монстр
--  Bells   - тихие бубенцы саней (зацикленно, фон)
--  Chime   - звон при сборе шара
--  Wind    - метель/ветер (зацикленно, фон)
-- ============================================================
local SOUNDS = {
	Music = "rbxassetid://1836605892",    -- Jingle Bells
	HoHoHo = "rbxassetid://19259975",     -- Санта «Ho-ho-ho»
	Bells = "rbxassetid://9038470580",    -- Santa's Sleigh (сани)
	Chime = "rbxassetid://7128958209",    -- звон колокольчика
	Wind = "rbxassetid://6670282148",     -- сильная метель / ветер
}
for k, v in SOUNDS do workspace:SetAttribute("NYSnd" .. k, v) end

local rng = Random.new(os.time())
local function C(r, g, b) return Color3.fromRGB(r, g, b) end

local function add(parent: Instance, name: string, size: Vector3, cf: CFrame, col: Color3, mat: Enum.Material, shape: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Name = name; p.Size = size; p.CFrame = cf
	if shape then p.Shape = shape end
	p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.CastShadow = false
	p.Color = col; p.Material = mat
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local ORN = { C(210, 30, 40), C(240, 190, 50), C(50, 110, 230), C(230, 230, 240), C(60, 190, 90), C(200, 60, 200) }

-- красивая ёлка: слоистые ярусы из дисков, снег на лапах, шары, гирлянда по спирали, звезда, подарки
local function makeTree(parent: Instance, base: CFrame, scale: number)
	local m = Instance.new("Model")
	m.Name = "XmasTree"
	local s = scale
	add(m, "Trunk", Vector3.new(3 * s, 1.6 * s, 1.6 * s), base * CFrame.new(0, 1.5 * s, 0) * CFrame.Angles(0, 0, math.pi / 2), C(76, 48, 28), Enum.Material.Wood, Enum.PartType.Cylinder).CastShadow = true
	add(m, "Pot", Vector3.new(2.2 * s, 3.2 * s, 3.2 * s), base * CFrame.new(0, 0.5 * s, 0) * CFrame.Angles(0, 0, math.pi / 2), C(150, 40, 36), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
	local tiers = 5
	local y = 2.6 * s
	local levels = {}   -- для размещения украшений: {y, r}
	for t = 0, tiers - 1 do
		local R = (6.4 - t * 1.05) * s
		local steps = 4
		for k = 0, steps - 1 do
			local f = k / steps
			local r = R * (1 - f * 0.68)
			local h = 0.95 * s
			local col = (k % 2 == 0) and C(22, 92, 46) or C(30, 116, 58)
			if t % 2 == 1 then col = col:Lerp(C(14, 70, 40), 0.35) end
			local d = add(m, "Needles", Vector3.new(h, r * 2, r * 2), base * CFrame.new(0, y, 0) * CFrame.Angles(0, rng:NextNumber(0, 3), math.pi / 2), col, Enum.Material.Grass, Enum.PartType.Cylinder)
			table.insert(levels, { y = y, r = r })
			y += h * 0.82
		end
		local rTop = R * (1 - 0.68 * 0.75)
		add(m, "Snow", Vector3.new(0.22 * s, rTop * 1.7, rTop * 1.7), base * CFrame.new(0, y - 0.1 * s, 0) * CFrame.Angles(0, 0, math.pi / 2), C(240, 246, 255), Enum.Material.Snow, Enum.PartType.Cylinder)
		for _ = 1, 5 do   -- комочки снега на краях
			local a = rng:NextNumber(0, math.pi * 2)
			local rr = rTop * rng:NextNumber(0.6, 1)
			add(m, "SnowBall", Vector3.one * (0.5 * s), base * CFrame.new(math.cos(a) * rr, y - 0.05 * s, math.sin(a) * rr), C(246, 250, 255), Enum.Material.Snow, Enum.PartType.Ball)
		end
		y -= 0.45 * s
	end
	local top = y + 0.9 * s
	-- шары
	for i = 1, 16 do
		local lv = levels[rng:NextInteger(1, #levels)]
		local a = rng:NextNumber(0, math.pi * 2)
		local rr = lv.r * 0.92
		local neon = (i % 3 == 0)
		local ball = add(m, neon and "Bulb" or "Ornament", Vector3.one * (0.62 * s), base * CFrame.new(math.cos(a) * rr, lv.y - 0.15 * s, math.sin(a) * rr), ORN[rng:NextInteger(1, #ORN)], neon and Enum.Material.Neon or Enum.Material.SmoothPlastic, Enum.PartType.Ball)
		if neon then
			CollectionService:AddTag(ball, "XmasBulb")
			ball:SetAttribute("Phase", rng:NextInteger(0, 2))
		else
			ball.Reflectance = 0.35
		end
	end
	-- гирлянда по спирали
	local n = 44
	for i = 0, n do
		local f = i / n
		local yy = 2.8 * s + f * (top - 3.6 * s)
		local rr = (6.1 * (1 - f * 0.92)) * s
		local a = f * math.pi * 2 * 4.5
		local b = add(m, "Bulb", Vector3.one * (0.3 * s), base * CFrame.new(math.cos(a) * rr, yy, math.sin(a) * rr), ORN[(i % #ORN) + 1], Enum.Material.Neon, Enum.PartType.Ball)
		CollectionService:AddTag(b, "XmasBulb")
		b:SetAttribute("Phase", i % 3)
	end
	-- звезда
	local st = add(m, "Star", Vector3.one * (1.3 * s), base * CFrame.new(0, top + 0.5 * s, 0), C(255, 220, 90), Enum.Material.Neon, Enum.PartType.Ball)
	for k = 0, 3 do
		add(m, "StarRay", Vector3.new(0.35 * s, 2.3 * s, 0.35 * s), base * CFrame.new(0, top + 0.5 * s, 0) * CFrame.Angles(0, 0, k * math.pi / 4), C(255, 226, 110), Enum.Material.Neon)
	end
	local pl = Instance.new("PointLight")
	pl.Color = C(255, 206, 130); pl.Range = 22 * s; pl.Brightness = 1.4; pl.Shadows = false; pl.Parent = st
	-- подарки
	for _ = 1, 3 do
		local a = rng:NextNumber(0, math.pi * 2)
		local r0 = rng:NextNumber(3.2, 4.6) * s
		local w, h = rng:NextNumber(1, 1.7) * s, rng:NextNumber(0.9, 1.6) * s
		local col = ORN[rng:NextInteger(1, #ORN)]
		local cf = base * CFrame.new(math.cos(a) * r0, h / 2, math.sin(a) * r0) * CFrame.Angles(0, rng:NextNumber(0, 3), 0)
		add(m, "Gift", Vector3.new(w, h, w), cf, col, Enum.Material.SmoothPlastic)
		add(m, "RibbonA", Vector3.new(w + 0.06, h + 0.06, 0.22 * s), cf, C(250, 240, 200), Enum.Material.SmoothPlastic)
		add(m, "RibbonB", Vector3.new(0.22 * s, h + 0.06, w + 0.06), cf, C(250, 240, 200), Enum.Material.SmoothPlastic)
		add(m, "Bow", Vector3.one * (0.5 * s), cf * CFrame.new(0, h / 2 + 0.2 * s, 0), C(250, 240, 200), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	end
	m.Parent = parent
	return m
end

-- гирлянда поперёк коридора
local function makeGarland(parent: Instance, O: Vector3, z: number, w: number, H: number)
	local n = 14
	local sag = 1.6
	local prev
	for i = 0, n do
		local f = i / n
		local x = (f - 0.5) * (w - 1)
		local y = H - 0.5 - sag * (1 - (2 * f - 1) ^ 2)
		local pos = O + Vector3.new(x, y, z)
		if prev then
			local d = (pos - prev).Magnitude
			add(parent, "Wire", Vector3.new(0.07, 0.07, d), CFrame.lookAt(prev, pos) * CFrame.new(0, 0, -d / 2), C(20, 40, 24), Enum.Material.SmoothPlastic)
		end
		if i % 2 == 0 then
			local b = add(parent, "Bulb", Vector3.one * 0.5, CFrame.new(pos - Vector3.new(0, 0.3, 0)), ORN[math.floor(i / 2) % #ORN + 1], Enum.Material.Neon, Enum.PartType.Ball)
			CollectionService:AddTag(b, "XmasBulb")
			b:SetAttribute("Phase", math.floor(i / 2) % 3)
		end
		prev = pos
	end
	local lp = add(parent, "GarlandLight", Vector3.one * 0.4, CFrame.new(O + Vector3.new(0, H - 2, z)), C(255, 200, 120), Enum.Material.SmoothPlastic)
	lp.Transparency = 1
	local pl = Instance.new("PointLight"); pl.Color = C(255, 190, 140); pl.Range = 24; pl.Brightness = 0.9; pl.Shadows = false; pl.Parent = lp
end

local function active(): boolean
	return workspace:GetAttribute("EvaKNewYear") == true
end

-- ---------- сегменты карты ----------
local function decorateSegment(folder: Instance, O: Vector3, zS: number, zE: number, w: number, diff: string?)
	if not folder.Parent or not (active() or diff == "newyear") then return end
	local room = w > 20
	local H = room and 26 or 14
	local side = (rng:NextInteger(0, 1) == 0) and -1 or 1
	local z = zS + rng:NextNumber(14, 22)
	while z < zE - 10 do
		local scale = room and 1.0 or 0.62
		local x = side * (w / 2 - (room and 5 or 2.6))
		makeTree(folder, CFrame.new(O + Vector3.new(x, 0, z)) * CFrame.Angles(0, rng:NextNumber(0, 6), 0), scale)
		side = -side
		z += rng:NextNumber(26, 36)
	end
	local gz = zS + 10
	while gz < zE - 6 do
		makeGarland(folder, O, gz, w, H)
		gz += room and 24 or 18
	end
end

local function hookMap()
	local ev = ServerStorage:WaitForChild("EvaKSegmentBuilt", 60)
	if not ev then warn("[EvaKNewYear] нет EvaKSegmentBuilt (обнови EvaKMap)") return end
	ev.Event:Connect(function(folder: Instance, O: Vector3, zS: number, zE: number, w: number, diff: string?)
		local ok, err = pcall(decorateSegment, folder, O, zS, zE, w, diff)
		if not ok then warn("[EvaKNewYear]", err) end
	end)
end
task.spawn(hookMap)

-- ---------- лобби ----------
local lobbyFolder: Folder? = nil
local function buildLobby()
	if lobbyFolder then return end
	local f = Instance.new("Folder")
	f.Name = "XmasLobby"
	f.Parent = workspace
	lobbyFolder = f
	local n = 0
	for _, d in workspace:GetDescendants() do
		if d:IsA("SpawnLocation") and n < 2 then
			n += 1
			for k = 0, 4 do
				local a = k / 5 * math.pi * 2 + n
				local origin = d.Position + Vector3.new(math.cos(a) * 17, 40, math.sin(a) * 17)
				local rp = RaycastParams.new()
				rp.FilterType = Enum.RaycastFilterType.Exclude
				rp.FilterDescendantsInstances = { f }
				local hit = workspace:Raycast(origin, Vector3.new(0, -120, 0), rp)
				if hit then
					makeTree(f, CFrame.new(hit.Position) * CFrame.Angles(0, rng:NextNumber(0, 6), 0), 1.1)
				end
			end
		end
	end
end
local function clearLobby()
	if lobbyFolder then lobbyFolder:Destroy(); lobbyFolder = nil end
end
workspace:GetAttributeChangedSignal("EvaKNewYear"):Connect(function()
	if active() then task.defer(buildLobby) else clearLobby() end
end)
if active() then task.defer(buildLobby) end
print("[EvaKNewYear] готово")
