-- ============================================================
--  EvaK MAP  (Script)   v4
--  Куда положить: ServerScriptService > Script
--  Делает: КАЖДУЮ катку генерирует НОВУЮ карту (случайный порядок обрывов, комнат,
--  каменных платформ, коридоров). Всего нужно выломать 100 деревянных дверей (E x3).
--  На стенах глаза, которые следят за тобой; чем дальше, тем их больше.
--  Монстр летит сзади (его надо перепрыгнуть). Команда (party) играет на ОДНОЙ карте.
--  Карта строится кодом далеко от лобби (CONFIG.Origin), ничего рисовать не нужно.
-- ============================================================

local CONFIG = {
	Origin = Vector3.new(2000, 0, 0),
	SlotSpacing = 170,                      -- расстояние между картами разных команд (по X)
	TotalDoors = 100,                       -- сколько дверей надо выломать до выхода
	BuildAhead = 320,                       -- на сколько studs вперёд строится карта
	KeepBehind = 330,                       -- сколько studs позади держим (потом удаляем)
	HallW = 16, HallH = 14,                 -- коридор
	RoomW = 60, RoomH = 26,                 -- комнаты
	ShaftSize = 48, ShaftHeight = 230,      -- пещера-шахта, куда ты падаешь в начале
	DropHeight = 215,
	FallSpeed = 52,                         -- предельная скорость падения
	StunAfterLand = 1.4,                    -- пауза после приземления
	PitDepth = 70,                          -- глубина обрыва (упал = конец забега)
	DoorOpenTime = 0.9,
	DoorBreakSoundId = "rbxassetid://9120804993",   -- звук выламывания двери

	-- монстр по сложности: пауза между появлениями (сек) и скорость (studs/s)
	Monster = {
		easy   = { count = 2, speed = 19 },
		normal = { count = 2, speed = 23 },
		hard   = { count = 3, speed = 27 },
		insane = { count = 3, speed = 31 },
		newyear = { count = 3, speed = 29 },
		endless = { count = 3, speed = 29 },
	},
	MonsterHeight = 3.4,    -- ниже этой высоты ноги = смерть (надо прыгать)
	MonsterWidth = 11,
}
local DIFF_INDEX = { easy = 1, normal = 2, hard = 3, insane = 4, newyear = 4, endless = 4 }

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local segBuilt = Instance.new("BindableEvent")   -- сообщает ивентам (Новый год) о новом сегменте
segBuilt.Name = "EvaKSegmentBuilt"
segBuilt.Parent = ServerStorage
local Debris = game:GetService("Debris")
local CollectionService = game:GetService("CollectionService")

local world = Instance.new("RemoteEvent")
world.Name = "EvaKWorld"
world.Parent = ReplicatedStorage

-- текущая "стройка" (переключается на нужный уровень перед постройкой сегмента)
local O = CONFIG.Origin
local curParent: Instance = workspace
local S, SH = CONFIG.ShaftSize, CONFIG.ShaftHeight
local HW, HH, RW, RH = CONFIG.HallW, CONFIG.HallH, CONFIG.RoomW, CONFIG.RoomH
local PIT = CONFIG.PitDepth
local z0 = S / 2                      -- здесь шахта переходит в уровень
local finishZ = nil
local rng = Random.new(os.time())

local function C(r, g, b) return Color3.fromRGB(r, g, b) end

local partCount = 0
local noYield = false      -- true внутри dpart (рантайм): там нельзя прерываться
local function part(name: string, size: Vector3, pos: Vector3, color: Color3, mat: Enum.Material?)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Position = O + pos
	p.Anchored = true
	local m0 = mat or Enum.Material.Concrete
	if m0 ~= Enum.Material.Neon and m0 ~= Enum.Material.Glass and m0 ~= Enum.Material.ForceField then
		-- как в Doors: всё темнее, грязнее и чуть приглушено по цвету (убираем «дешёвую» яркость пластика)
		local k = 0.56 + (partCount % 7) * 0.012
		local gray = (color.R + color.G + color.B) / 3
		color = Color3.new((color.R * 0.8 + gray * 0.2) * k, (color.G * 0.8 + gray * 0.2) * k * 0.97, (color.B * 0.8 + gray * 0.2) * k * 0.92)
	end
	p.Color = color
	p.Material = m0
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = curParent
	partCount += 1
	if partCount % 140 == 0 and not noYield then task.wait() end   -- не вешаем сервер при постройке
	return p
end

local function pipeZ(length: number, d: number, pos: Vector3, color: Color3)
	local p = Instance.new("Part")
	p.Name = "Pipe"
	p.Shape = Enum.PartType.Cylinder
	p.Size = Vector3.new(length, d, d)
	p.CFrame = CFrame.new(O + pos) * CFrame.Angles(0, math.pi / 2, 0)
	p.Anchored = true
	p.Color = color
	p.Material = Enum.Material.Metal
	p.Parent = curParent
	return p
end

-- ------------------------------------------------------------
-- Освещение: тёмно, но читаемо; тёплые тусклые лампы
-- ------------------------------------------------------------
Lighting.Brightness = 1.3
Lighting.ClockTime = 0
Lighting.Ambient = C(112, 92, 82)
Lighting.OutdoorAmbient = C(112, 92, 82)
Lighting.FogColor = C(42, 22, 16)
Lighting.FogStart = 120
Lighting.FogEnd = 420
pcall(function() Lighting.Technology = Enum.Technology.Future end)
Lighting.GlobalShadows = true
pcall(function() Lighting.ExposureCompensation = 0.3 end)
pcall(function() Lighting.ShadowSoftness = 0.2 end)
pcall(function() Lighting.EnvironmentDiffuseScale = 0.7; Lighting.EnvironmentSpecularScale = 0.6 end)
local LAMP_SHADOWS = false                       -- тени от ламп (если лагает: поставьте false)
local atm = Instance.new("Atmosphere")
atm.Density = 0.28; atm.Offset = 0.1; atm.Color = C(120, 72, 52); atm.Decay = C(70, 36, 26); atm.Glare = 0; atm.Haze = 2.3
atm.Parent = Lighting
local dof = Instance.new("DepthOfFieldEffect")
dof.FarIntensity = 0.22; dof.FocusDistance = 55; dof.InFocusRadius = 45; dof.NearIntensity = 0
dof.Parent = Lighting
local cc = Instance.new("ColorCorrectionEffect")
cc.Saturation = 0.14; cc.Contrast = 0.14; cc.Brightness = 0.04; cc.TintColor = C(255, 206, 180)
cc.Parent = Lighting
local bloom = Instance.new("BloomEffect")
bloom.Intensity = 0.5; bloom.Size = 30; bloom.Threshold = 1.15
bloom.Enabled = true
bloom.Parent = Lighting

-- ------------------------------------------------------------
-- Палитры стен: разные кирпичи, бетон, булыжник, металл (чтобы стены не были однотипными)
-- ------------------------------------------------------------
local function jitter(c: Color3, a: number): Color3
	local k = 1 + rng:NextNumber(-a, a)
	return Color3.new(math.clamp(c.R * k, 0, 1), math.clamp(c.G * k, 0, 1), math.clamp(c.B * k, 0, 1))
end
-- несколько цветовых тем кирпича: в каждой катке выбирается случайная
local THEMES = {
	{ C(34, 42, 84), C(30, 38, 76), C(40, 50, 94), C(24, 30, 62), C(150, 138, 112), C(80, 76, 80) },
	{ C(34, 44, 38), C(30, 40, 34), C(40, 52, 44), C(22, 30, 26), C(150, 140, 118), C(70, 72, 66) },
	{ C(30, 50, 66), C(26, 44, 60), C(36, 58, 76), C(20, 34, 48), C(146, 136, 116), C(70, 76, 80) },
	{ C(52, 40, 82), C(46, 34, 72), C(60, 48, 94), C(36, 26, 58), C(148, 136, 116), C(80, 72, 84) },
	{ C(86, 24, 32), C(76, 20, 28), C(98, 30, 38), C(54, 14, 20), C(150, 136, 112), C(84, 70, 66) },   -- бордовые обои
	{ C(28, 62, 48), C(24, 54, 42), C(34, 72, 56), C(16, 38, 30), C(146, 134, 112), C(70, 78, 70) },   -- тёмно-зелёные обои
	{ C(74, 58, 36), C(64, 50, 30), C(86, 68, 42), C(46, 34, 20), C(150, 138, 116), C(86, 76, 62) },   -- старый золотистый узор
}
local BRICKS = THEMES[1]
local function wallStyle(style: string?): (Color3, Enum.Material)
	if style == "cave" then
		return jitter(C(62, 58, 56), 0.18), Enum.Material.Rock
	end
	if rng:NextNumber() < 0.88 then
		return jitter(BRICKS[rng:NextInteger(1, 3)], 0.06), Enum.Material.Fabric
	end
	return jitter(BRICKS[5], 0.08), Enum.Material.Concrete
end

-- ------------------------------------------------------------
-- Лампы (мерцают, часть сломана)
-- ------------------------------------------------------------
local lamps = {}
local function lamp(x: number, y: number, z: number, cave: boolean?)
	if cave then
		local g = part("Crystal", Vector3.new(1, 2.2, 1), Vector3.new(x, y, z), C(90, 150, 255), Enum.Material.Neon)
		g.CanCollide = false
		local pl = Instance.new("PointLight")
		pl.Range = 12; pl.Brightness = 0.4; pl.Color = C(110, 170, 255); pl.Parent = g
		return
	end
	part("LampBase", Vector3.new(3.2, 0.4, 1.4), Vector3.new(x, y + 0.2, z), C(28, 26, 26), Enum.Material.Metal)
	local red = rng:NextNumber() < 0.16   -- аварийная красная лампа
	local lc = red and C(255, 40, 30) or C(255, 190, 125)
	local bulb = part("Lamp", Vector3.new(2.6, 0.2, 1), Vector3.new(x, y - 0.1, z), lc, Enum.Material.Neon)
	bulb.CanCollide = false
	local pl = Instance.new("PointLight")
	pl.Range = red and 18 or 24; pl.Brightness = 1.15; pl.Color = lc; pl.Shadows = LAMP_SHADOWS or rng:NextNumber() < 0.35; pl.Parent = bulb
	-- «отрубленный свет»: участки коридора, где лампы мёртвы, жива лишь одна еле мигающая
	local blk = math.floor(z / 110)
	local dead = (math.abs(math.sin(blk * 12.9898) * 43758.5453) % 1) < 0.17
	if dead then
		if (math.floor(z / 22) + blk) % 4 ~= 0 then
			pl.Enabled = false; bulb.Material = Enum.Material.SmoothPlastic; bulb.Color = C(40, 34, 30)
			return
		end
		pl.Brightness = 0.5; pl.Range = 14
		table.insert(lamps, { part = bulb, light = pl, base = 0.5, seed = rng:NextNumber(0, 100), bad = false, dead = true })
		return
	end
	table.insert(lamps, { part = bulb, light = pl, base = 1.3, seed = rng:NextNumber(0, 100), bad = rng:NextNumber() < 0.18 })
end
local function sconce(sx: number, w: number, z: number)
	local y = 8.5
	part("SconceBase", Vector3.new(0.5, 1.6, 0.9), Vector3.new(sx * (w / 2 - 0.25), y, z), C(120, 90, 40), Enum.Material.Metal)
	local lc = C(255, 205, 140)
	local b = part("Sconce", Vector3.new(0.5, 1, 0.6), Vector3.new(sx * (w / 2 - 0.7), y + 1, z), lc, Enum.Material.Neon)
	b.CanCollide = false
	local pl = Instance.new("PointLight")
	pl.Range = 24; pl.Brightness = 1.1; pl.Color = lc; pl.Shadows = false; pl.Parent = b
	table.insert(lamps, { part = b, light = pl, base = 1.1, seed = rng:NextNumber(0, 100), bad = rng:NextNumber() < 0.2 })
end
local lampClean = 0
RunService.Heartbeat:Connect(function()
	local t = os.clock()
	if t - lampClean > 2 then   -- убираем лампы удалённых сегментов
		lampClean = t
		for i = #lamps, 1, -1 do
			if not lamps[i].part:IsDescendantOf(workspace) then table.remove(lamps, i) end
		end
	end
	for _, l in lamps do
		local f
		if l.dead then
			f = (math.noise(t * 3.1, l.seed) > 0.55) and 0.7 or 0.04
		elseif l.bad then
			f = (math.noise(t * 7, l.seed) > 0.25) and 0.12 or 1
		else
			f = 0.9 + 0.1 * math.noise(t * 2, l.seed)
		end
		l.light.Brightness = l.base * f
		l.part.Transparency = 0.6 * (1 - f)
	end
end)

local ROCK = C(58, 54, 52)
local function buildShaft()
part("ShaftFloor", Vector3.new(S, 1, S), Vector3.new(0, -0.5, 0), C(50, 47, 45), Enum.Material.Slate)
local side = (S - HW) / 2
part("ShaftBack", Vector3.new(S + 4, SH, 2), Vector3.new(0, SH / 2, -S / 2 - 1), ROCK, Enum.Material.Rock)
part("ShaftLeft", Vector3.new(2, SH, S + 4), Vector3.new(-S / 2 - 1, SH / 2, 0), ROCK, Enum.Material.Rock)
part("ShaftRight", Vector3.new(2, SH, S + 4), Vector3.new(S / 2 + 1, SH / 2, 0), ROCK, Enum.Material.Rock)
part("ShaftFrontL", Vector3.new(side, SH, 2), Vector3.new(-(HW / 2 + side / 2), SH / 2, S / 2 + 1), ROCK, Enum.Material.Rock)
part("ShaftFrontR", Vector3.new(side, SH, 2), Vector3.new(HW / 2 + side / 2, SH / 2, S / 2 + 1), ROCK, Enum.Material.Rock)
part("ShaftFrontTop", Vector3.new(HW, SH - HH, 2), Vector3.new(0, HH + (SH - HH) / 2, S / 2 + 1), ROCK, Enum.Material.Rock)
part("ShaftRoof", Vector3.new(S + 4, 2, S + 4), Vector3.new(0, SH + 1, 0), C(30, 28, 28), Enum.Material.Rock)

-- выступы скал внутрь шахты (4 стены)
for face = 1, 4 do
	local y = 6
	while y < SH - 4 do
		local x = -S / 2 + 4
		while x < S / 2 - 2 do
			local w, h, d = rng:NextNumber(8, 13), rng:NextNumber(14, 22), rng:NextNumber(1.5, 5)
			local lat = x + rng:NextNumber(-2, 2)
			local skip = (face == 2 and math.abs(lat) < HW / 2 + 4 and y < HH + 6)
			if not skip then
				local inward = d / 2
				local cf
				if face == 1 then cf = CFrame.new(lat, y, -S / 2 + inward)
				elseif face == 2 then cf = CFrame.new(lat, y, S / 2 - inward)
				elseif face == 3 then cf = CFrame.new(-S / 2 + inward, y, lat) * CFrame.Angles(0, math.pi / 2, 0)
				else cf = CFrame.new(S / 2 - inward, y, lat) * CFrame.Angles(0, math.pi / 2, 0) end
				local b = part("Rock", Vector3.new(w, h, d), Vector3.zero, jitter(ROCK, 0.25), Enum.Material.Rock)
				b.CFrame = CFrame.new(O) * cf * CFrame.Angles(rng:NextNumber(-0.12, 0.12), rng:NextNumber(-0.12, 0.12), rng:NextNumber(-0.12, 0.12))
			end
			x += rng:NextNumber(12, 16)
		end
		y += rng:NextNumber(20, 28)
	end
end
-- светящиеся кристаллы по стенам (видно, как ты летишь вниз)
for i = 1, 10 do
	local y = rng:NextNumber(14, SH - 14)
	local sx = (rng:NextInteger(0, 1) == 0) and -1 or 1
	lamp(sx * (S / 2 - 1.2), y, rng:NextNumber(-S / 2 + 6, S / 2 - 6), true)
end
-- слабый свет сверху
local topLight = part("ShaftLight", Vector3.new(14, 1, 14), Vector3.new(0, SH - 1, 0), C(255, 214, 160), Enum.Material.Neon)
topLight.CanCollide = false
local tl = Instance.new("PointLight")
tl.Range = 70; tl.Brightness = 0.8; tl.Color = C(255, 205, 140); tl.Parent = topLight
end

-- ------------------------------------------------------------
-- Строительные блоки уровня
-- ------------------------------------------------------------
-- ------------------------------------------------------------
-- Декор: царапины когтей, кровь, деревянные панели, ковёр, картины, обломки дверей
-- ------------------------------------------------------------
local function mark(p: Part): Part
	p.CanCollide = false; p.CanQuery = false; p.CastShadow = false
	return p
end

local function claw(sx: number, w: number, z: number, y: number)   -- царапины когтей на стене
	local ang = rng:NextNumber(-0.7, 0.7)
	local col = (rng:NextNumber() < 0.7) and C(165, 150, 135) or C(10, 6, 6)
	local n = rng:NextInteger(2, 3)
	for i = 1, n do
		local len = rng:NextNumber(2.2, 5.2)
		local p = mark(part("Scratch", Vector3.new(0.05, len, 0.1), Vector3.new(sx * (w / 2 - 0.03), y, z + (i - (n + 1) / 2) * 0.42), col, Enum.Material.SmoothPlastic))
		p.CFrame = p.CFrame * CFrame.Angles(ang + rng:NextNumber(-0.08, 0.08), 0, 0)
	end
end

local function handprint(sx: number, w: number, z: number, y: number)   -- кровавый отпечаток руки
	local c = C(86, 8, 8)
	mark(part("Hand", Vector3.new(0.05, 0.9, 0.75), Vector3.new(sx * (w / 2 - 0.03), y, z), c, Enum.Material.SmoothPlastic))
	for i = -1, 1 do
		local f = mark(part("Finger", Vector3.new(0.05, 0.6, 0.14), Vector3.new(sx * (w / 2 - 0.03), y + 0.7, z + i * 0.25), c, Enum.Material.SmoothPlastic))
		f.CFrame = f.CFrame * CFrame.Angles(i * 0.15, 0, 0)
	end
	local drip = mark(part("Drip", Vector3.new(0.05, rng:NextNumber(1.5, 3.5), 0.12), Vector3.new(sx * (w / 2 - 0.03), y - 1.6, z), C(70, 6, 6), Enum.Material.SmoothPlastic))
end

local function blood(w: number, z: number)   -- лужа и след волочения
	local x = rng:NextNumber(-w / 2 + 2.5, w / 2 - 2.5)
	local s = rng:NextNumber(1.5, 4)
	local p = mark(part("Blood", Vector3.new(s, 0.05, s * rng:NextNumber(0.6, 1.4)), Vector3.new(x, 0.13, z), C(62, 5, 7), Enum.Material.SmoothPlastic))
	p.CFrame = p.CFrame * CFrame.Angles(0, rng:NextNumber(0, 3), 0)
	p.Reflectance = 0.15
	for _ = 1, rng:NextInteger(2, 5) do
		local d = mark(part("BloodDrop", Vector3.new(0.4, 0.05, 0.4), Vector3.new(x + rng:NextNumber(-3, 3), 0.13, z + rng:NextNumber(-3, 3)), C(58, 4, 6), Enum.Material.SmoothPlastic))
		d.CFrame = d.CFrame * CFrame.Angles(0, rng:NextNumber(0, 3), 0)
	end
	if rng:NextNumber() < 0.5 then
		local len = rng:NextNumber(6, 14)
		mark(part("Drag", Vector3.new(0.9, 0.05, len), Vector3.new(x, 0.13, z + len / 2), C(52, 4, 6), Enum.Material.SmoothPlastic))
	end
end

local sideGap, skipSide = nil, nil   -- проём в боковой стене комнаты (для бокового коридора)
local function wainscot(zA: number, len: number, w: number)   -- деревянные панели снизу стен
	if sideGap and not skipSide and zA <= sideGap.z0 and zA + len >= sideGap.z1 then
		local g = sideGap; sideGap = nil
		wainscot(zA, g.z0 - zA, w); wainscot(g.z1, zA + len - g.z1, w)
		skipSide = g.sx; wainscot(g.z0, g.z1 - g.z0, w); skipSide = nil
		sideGap = g
		return
	end
	for _, sx in { -1, 1 } do
		if sx == skipSide then continue end
		part("Wainscot", Vector3.new(0.45, 4, len), Vector3.new(sx * (w / 2 - 0.22), 2, zA + len / 2), jitter(C(54, 36, 26), 0.1), Enum.Material.WoodPlanks)
		part("WainscotRail", Vector3.new(0.7, 0.35, len), Vector3.new(sx * (w / 2 - 0.35), 4.1, zA + len / 2), C(78, 52, 36), Enum.Material.Wood)
		part("Baseboard", Vector3.new(0.6, 0.5, len), Vector3.new(sx * (w / 2 - 0.3), 0.25, zA + len / 2), C(30, 20, 15), Enum.Material.Wood)
	end
end

local function carpet(zA: number, len: number, w: number)   -- потёртая ковровая дорожка
	local cw = math.min(w - 6, 7)
	local z = zA
	while z < zA + len - 0.01 do
		local l = math.min(24, zA + len - z)
		mark(part("Carpet", Vector3.new(cw, 0.12, l), Vector3.new(0, 0.06, z + l / 2), jitter(C(78, 14, 18), 0.18), Enum.Material.Fabric))
		mark(part("CarpetInner", Vector3.new(cw - 2.2, 0.14, l), Vector3.new(0, 0.07, z + l / 2), C(46, 10, 14), Enum.Material.Fabric))
for _, sx in { -1, 1 } do
mark(part("CarpetEdge", Vector3.new(0.25, 0.14, l), Vector3.new(sx * (cw / 2 - 0.4), 0.07, z + l / 2), C(150, 118, 52), Enum.Material.Fabric))
		end
		z += l
	end
end

local function paint(canvas: Part, face: Enum.NormalId, kind: number)
	local sg = Instance.new("SurfaceGui")
	sg.Face = face; sg.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize; sg.CanvasSize = Vector2.new(260, 340); sg.LightInfluence = 0.3
	sg.Parent = canvas
	local function fr(parent: Instance, x: number, y: number, w: number, h: number, col: Color3, tr: number?, round: number?, rot: number?): Frame
		local f = Instance.new("Frame")
		f.AnchorPoint = Vector2.new(0.5, 0.5); f.Position = UDim2.fromScale(x, y); f.Size = UDim2.fromScale(w, h)
		f.BackgroundColor3 = col; f.BackgroundTransparency = tr or 0; f.BorderSizePixel = 0; f.Rotation = rot or 0
		if round then local uc = Instance.new("UICorner"); uc.CornerRadius = UDim.new(round, 0); uc.Parent = f end
		f.Parent = parent
		return f
	end
	local function grad(f: Frame, c0: Color3, c1: Color3, rot: number?)
		local g = Instance.new("UIGradient"); g.Color = ColorSequence.new(c0, c1); g.Rotation = rot or 90; g.Parent = f
	end
	local bg = fr(sg, 0.5, 0.5, 1, 1, C(30, 22, 16))
	bg.ClipsDescendants = true
	local R = 260 / 340    -- чтобы круги были круглыми
	if kind == 1 then          -- портрет
		grad(bg, C(74, 58, 40), C(14, 10, 8))
		local skin = C(rng:NextInteger(190, 226), rng:NextInteger(168, 196), rng:NextInteger(140, 170))
		local hair = jitter(C(40, 28, 20), 0.5)
		fr(bg, 0.5, 0.98, 0.96, 0.56, C(20, 18, 22), 0, 0.5)
		fr(bg, 0.5, 0.74, 0.2, 0.16, skin:Lerp(C(0, 0, 0), 0.25), 0, 0.3)
		fr(bg, 0.5, 0.74, 0.26, 0.05, C(226, 220, 206), 0, 0.4)
		fr(bg, 0.5, 0.37, 0.4, 0.38, hair, 0, 0.5)
		fr(bg, 0.5, 0.41, 0.33, 0.34, skin, 0, 0.5)
		local voids = rng:NextNumber() < 0.5
		for _, ex in { 0.43, 0.57 } do
			fr(bg, ex, 0.4, 0.085, 0.04, voids and C(4, 4, 4) or C(238, 236, 226), 0, 0.5)
			fr(bg, ex, 0.4, 0.035, 0.035 * R, voids and C(200, 20, 20) or C(30, 22, 16), 0, 0.5)
		end
		fr(bg, 0.5, 0.52, 0.11, 0.008, C(60, 20, 20), 0, 0.5)
		fr(bg, 0.5, 0.46, 0.03, 0.05, skin:Lerp(C(0, 0, 0), 0.15), 0, 0.5)
		for _ = 1, 6 do fr(bg, rng:NextNumber(0.1, 0.9), rng:NextNumber(0.1, 0.9), rng:NextNumber(0.1, 0.35), 0.003, C(0, 0, 0), 0.6, nil, rng:NextNumber(-60, 60)) end
	elseif kind == 2 then      -- пейзаж
		grad(bg, C(36, 28, 74), C(232, 142, 84))
		local sun = fr(bg, 0.68, 0.36, 0.2, 0.2 * R, C(250, 226, 170), 0, 0.5)
		fr(bg, 0.68, 0.36, 0.3, 0.3 * R, C(250, 190, 120), 0.7, 0.5)
		fr(bg, 0.3, 0.8, 0.62, 0.62 * R, C(44, 48, 78), 0, nil, 45)
		fr(bg, 0.78, 0.86, 0.8, 0.8 * R, C(30, 34, 60), 0, nil, 45)
		local ground = fr(bg, 0.5, 0.95, 1, 0.22, C(18, 28, 20))
		grad(ground, C(34, 52, 30), C(8, 12, 8))
		for k = 1, 6 do
			local tx = rng:NextNumber(0.05, 0.95)
			fr(bg, tx, 0.82, 0.012, 0.1, C(8, 8, 8)); fr(bg, tx, 0.77, 0.05, 0.08, C(12, 24, 14), 0, nil, 45)
		end
		if rng:NextNumber() < 0.6 then   -- далёкая фигура
			fr(bg, 0.4, 0.8, 0.02, 0.07, C(0, 0, 0), 0, 0.5)
			fr(bg, 0.4, 0.775, 0.012, 0.012 * R, C(255, 255, 255), 0, 0.5)
		end
	elseif kind == 3 then      -- фигура в дверном проёме
		grad(bg, C(36, 24, 20), C(6, 4, 4))
		local door = fr(bg, 0.5, 0.55, 0.46, 0.8, C(210, 176, 120), 0.05)
		grad(door, C(255, 230, 170), C(120, 80, 40))
		fr(bg, 0.5, 0.64, 0.13, 0.6, C(2, 2, 2), 0, 0.5)
		fr(bg, 0.5, 0.38, 0.12, 0.12 * R * 1.3, C(2, 2, 2), 0, 0.5)
		for _, ex in { 0.47, 0.53 } do fr(bg, ex, 0.38, 0.016, 0.016 * R, C(255, 250, 240), 0, 0.5) end
	else                       -- натюрморт
		grad(bg, C(60, 40, 30), C(10, 8, 8))
		fr(bg, 0.5, 0.84, 0.92, 0.24, C(86, 56, 32))
		fr(bg, 0.5, 0.72, 0.2, 0.3, C(54, 84, 104), 0, 0.45)
		fr(bg, 0.5, 0.55, 0.07, 0.07, C(54, 84, 104), 0, 0.3)
		for k = 1, 5 do fr(bg, 0.5 + math.cos(k * 1.3) * 0.12, 0.45 + math.sin(k * 1.3) * 0.06, 0.07, 0.07 * R, jitter(C(160, 30, 36), 0.25), 0, 0.5) end
		fr(bg, 0.22, 0.74, 0.12, 0.12 * R, C(190, 40, 30), 0, 0.5); fr(bg, 0.78, 0.75, 0.1, 0.1 * R, C(220, 190, 70), 0, 0.5)
	end
	local vig = fr(bg, 0.5, 0.5, 1, 1, C(0, 0, 0), 0)   -- виньетка и потёртость
	local vg = Instance.new("UIGradient")
	vg.Rotation = 90; vg.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(0.5, 1), NumberSequenceKeypoint.new(1, 0.35) })
	vg.Parent = vig
end

local function picture(sx: number, w: number, z: number)   -- картины в позолоченных рамах (рисуются кодом)
	local big = rng:NextNumber() < 0.3
	local ph, pw2 = big and 5.4 or 4.0, big and 4.2 or 3.1
	local y = rng:NextNumber(7.5, 9.3)
	local fx = sx * (w / 2 - 0.14)
	local tilt = (rng:NextNumber() < 0.35) and rng:NextNumber(-0.12, 0.12) or 0
	local function add(sz: Vector3, off: number, col: Color3, mat: Enum.Material): Part
		local p = mark(part("Pic", sz, Vector3.new(fx - sx * off, y, z), col, mat))
		p.CFrame = p.CFrame * CFrame.Angles(tilt, 0, 0)
		return p
	end
	add(Vector3.new(0.2, ph + 1.2, pw2 + 1.2), 0, C(176, 138, 58), Enum.Material.Metal)
	add(Vector3.new(0.2, ph + 0.55, pw2 + 0.55), 0.06, C(52, 34, 18), Enum.Material.Wood)
	local cv = add(Vector3.new(0.1, ph, pw2), 0.17, C(30, 24, 18), Enum.Material.SmoothPlastic)
	local kind = rng:NextInteger(1, 4)
	paint(cv, (sx == -1) and Enum.NormalId.Right or Enum.NormalId.Left, kind)
	local gl = add(Vector3.new(0.14, 0.14, pw2 * 0.7), 0.3, C(255, 214, 150), Enum.Material.Neon)   -- подсветка картины
	gl.CFrame = gl.CFrame * CFrame.new(0, ph / 2 + 0.85, 0)
end

local function planksPile(w: number, z: number)   -- обломки выломанной двери
	local x0 = rng:NextNumber(-w / 2 + 3, w / 2 - 3)
	for _ = 1, rng:NextInteger(4, 8) do
		local p = mark(part("BrokenPlank", Vector3.new(rng:NextNumber(0.3, 0.6), 0.18, rng:NextNumber(2, 5.5)), Vector3.new(x0 + rng:NextNumber(-1.8, 1.8), 0.2 + rng:NextNumber(0, 0.5), z + rng:NextNumber(-1.8, 1.8)), jitter(C(88, 58, 36), 0.2), Enum.Material.Wood))
		p.CFrame = p.CFrame * CFrame.Angles(rng:NextNumber(-0.4, 0.4), rng:NextNumber(0, 3.1), rng:NextNumber(-0.4, 0.4))
	end
	-- расколотая рама, прислонённая к стене
	local sx = (rng:NextInteger(0, 1) == 0) and -1 or 1
	local post = mark(part("BrokenFrame", Vector3.new(0.7, rng:NextNumber(5, 9), 0.7), Vector3.new(sx * (w / 2 - 1.5), 3.2, z), C(70, 46, 28), Enum.Material.Wood))
	post.CFrame = post.CFrame * CFrame.Angles(0, 0, sx * 0.28)
end

-- общий декор отрезка (z локальный, w ширина)
local function dress(zA: number, len: number, w: number, step: number)
	local z = zA + step * 0.6
	while z < zA + len - 6 do
		local r = rng:NextNumber()
		if r < 0.35 then blood(w, z)
		elseif r < 0.6 then picture((rng:NextInteger(0, 1) == 0) and -1 or 1, w, z)
		elseif r < 0.8 then planksPile(w, z) end
		z += step + rng:NextNumber(0, step * 0.5)
	end
end

local cur = z0                     -- текущий конец построенной части (локальный z)
local lastW, lastH = HW, HH
local curIdx = 0                 -- номер текущего сегмента (= номер двери)
local curLevel: any = nil
local onDoorBroken: (any, any) -> () = function() end
local onHide: (Player, any) -> () = function() end
local onLoot: (Player, any) -> () = function() end

-- ------------------------------------------------------------
-- Глаза на стенах: клиент поворачивает зрачки на игрока. Чем дальше, тем их больше.
-- ------------------------------------------------------------
-- ------------------------------------------------------------
-- Детальный глаз: глазница, веки, белок, радужка, зрачок, блик, прожилки
-- (клиент двигает радужку по орбите и тянет за ней части с атрибутом Follow)
-- ------------------------------------------------------------
local IRIS = { C(120, 24, 20), C(70, 130, 46), C(210, 150, 30), C(46, 90, 160), C(130, 40, 160), C(190, 190, 180) }
local function makeEye(parent: Instance, center: Vector3, nrm: Vector3, d: number, o)
	o = o or {}
	nrm = nrm.Unit
	local up = (math.abs(nrm.Y) > 0.9) and Vector3.xAxis or Vector3.yAxis
	local base = CFrame.lookAt(center, center + nrm, up)
	local function blob(name: string, size: Vector3, off: Vector3, col: Color3, mat: Enum.Material, refl: number?, rot: number?, shape: Enum.MeshType?): Part
		local p = Instance.new("Part")
		p.Name = name; p.Size = size
		p.CFrame = base * CFrame.new(off) * CFrame.Angles(0, 0, rot or 0)
		p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.CastShadow = false
		p.Color = col; p.Material = mat; p.Reflectance = refl or 0
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = shape or Enum.MeshType.Sphere
		mesh.Parent = p
		p.Parent = parent
		return p
	end
	local flesh = C(10, 10, 10)   -- минимализм: чёрно-белый глаз
	local tilt = rng:NextNumber(-0.25, 0.25)
	blob("Socket", Vector3.new(d * 1.6, d * 1.45, d * 0.5), Vector3.new(0, 0, d * 0.12), C(14, 14, 14), Enum.Material.SmoothPlastic, 0)
	local sc = blob("Sclera", Vector3.new(d, d * 0.9, d * 0.55), Vector3.zero, C(246, 246, 246), Enum.Material.SmoothPlastic, 0, tilt)
	local iris = C(6, 6, 6)
	local pu = blob("Pupil", Vector3.new(d * 0.5, d * 0.5, d * 0.2), Vector3.new(0, 0, -d * 0.22), iris, Enum.Material.SmoothPlastic, 0)
	local slit = o.slit or rng:NextNumber() < 0.25
	local core = blob("PupilCore", slit and Vector3.new(d * 0.1, d * 0.4, d * 0.1) or Vector3.new(d * 0.22, d * 0.22, d * 0.1), Vector3.new(0, 0, -d * 0.27), C(4, 2, 2), Enum.Material.SmoothPlastic, 0)
	local gl = blob("Glint", Vector3.new(d * 0.09, d * 0.09, d * 0.06), Vector3.new(d * 0.09, d * 0.09, -d * 0.3), C(255, 255, 255), Enum.Material.Neon, 0)
	for _, f in { core, gl } do f:SetAttribute("Follow", true) end
	-- веки: полуприкрытый тяжёлый взгляд
	blob("LidU", Vector3.new(d * 1.2, d * 0.5, d * 0.6), Vector3.new(0, d * 0.5, -d * 0.06), flesh, Enum.Material.SmoothPlastic, 0.04, tilt)
	blob("LidL", Vector3.new(d * 1.12, d * 0.36, d * 0.55), Vector3.new(0, -d * 0.5, -d * 0.04), flesh, Enum.Material.SmoothPlastic, 0.04, tilt)
	-- кровавые прожилки на белке
	for _ = 1, 0 do   -- жилки убраны ради минимализма
		local sx = (rng:NextInteger(0, 1) == 0) and -1 or 1
		blob("Vein", Vector3.new(d * 0.03, d * rng:NextNumber(0.18, 0.3), d * 0.02), Vector3.new(sx * d * rng:NextNumber(0.28, 0.4), rng:NextNumber(-0.12, 0.12) * d, -d * 0.255), o.vein or C(170, 28, 28), o.vein and Enum.Material.Neon or Enum.Material.SmoothPlastic, 0, rng:NextNumber(0.4, 1.2) * sx, Enum.MeshType.Brick)
	end
	sc:SetAttribute("Nrm", nrm)
	sc:SetAttribute("Depth", d * 0.22)
	sc:SetAttribute("Orbit", d * 0.2)
	return sc
end

local function eye(x: number, y: number, z: number, nx: number, ny: number)
	local m = Instance.new("Model")
	m.Name = "Eye"
	local nrm = Vector3.new(nx, ny, 0)
	if nrm.Magnitude < 0.01 then nrm = Vector3.new(0, 0, -1) end
	local sc = makeEye(m, O + Vector3.new(x, y, z) + nrm.Unit * 0.15, nrm, rng:NextNumber(1.7, 2.3))
	if rng:NextNumber() < 0.04 then
		local pl = Instance.new("PointLight")
		pl.Range = 7; pl.Brightness = 0.3; pl.Color = C(235, 235, 245); pl.Parent = sc
	end
	m.Parent = curParent
	CollectionService:AddTag(m, "EvaKEye")
end

local function eyes(zA: number, len: number, w: number, h: number)
	local n = math.min(16, 1 + curIdx // 6 + (DIFF_INDEX[curLevel.diff] or 1))
	for _ = 1, n do
		local z = zA + rng:NextNumber(2, math.max(3, len - 2))
		if rng:NextNumber() < 0.8 then
			local sx = (rng:NextInteger(0, 1) == 0) and -1 or 1
			eye(sx * (w / 2 - 0.3), rng:NextNumber(5, h - 2), z, -sx, 0)
		else
			eye(rng:NextNumber(-w / 2 + 2, w / 2 - 2), h - 0.3, z, 0, -1)
		end
	end
end

local function walls(zA: number, len: number, w: number, h: number, bottom: number, style: string?)
	if sideGap and not skipSide and zA <= sideGap.z0 and zA + len >= sideGap.z1 then
		local g = sideGap; sideGap = nil
		walls(zA, g.z0 - zA, w, h, bottom, style); walls(g.z1, zA + len - g.z1, w, h, bottom, style)
		skipSide = g.sx; walls(g.z0, g.z1 - g.z0, w, h, bottom, style); skipSide = nil
		part("WallOverGap", Vector3.new(1, h - 9.5, g.z1 - g.z0), Vector3.new(g.sx * (w / 2 + 0.5), 9.5 + (h - 9.5) / 2, (g.z0 + g.z1) / 2), C(60, 44, 36), Enum.Material.Fabric)
		sideGap = g
		return
	end
	local zc = zA
	while zc < zA + len - 0.01 do
		local pl = math.min(rng:NextNumber(16, 22), zA + len - zc)
		for _, sx in { -1, 1 } do
			if sx == skipSide then continue end
			local col, mat = wallStyle(style)
			local wp = part("Wall", Vector3.new(1, h - bottom, pl), Vector3.new(sx * (w / 2 + 0.5), (h + bottom) / 2, zc + pl / 2), col, mat)
			if style ~= "cave" and bottom >= 0 and mat == Enum.Material.Fabric then
				pcall(function()   -- ромбовые обои (решётка из косых линий)
					local pps = 8
					local cw, ch = pl * pps, (h - bottom) * pps
					local sg = Instance.new("SurfaceGui")
					sg.Face = (sx < 0) and Enum.NormalId.Right or Enum.NormalId.Left
					sg.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
					sg.CanvasSize = Vector2.new(cw, ch); sg.LightInfluence = 0.5; sg.Parent = wp
					local box = Instance.new("Frame")
					box.Size = UDim2.fromScale(1, 1); box.BackgroundTransparency = 1; box.ClipsDescendants = true; box.Parent = sg
					local lc = col:Lerp(Color3.new(1, 1, 1), 0.16)
					local step = 24
					local ext = math.tan(math.rad(32)) * ch
					local x = -ext
					while x < cw + ext do
						for _, rot in { 32, -32 } do
							local ln = Instance.new("Frame")
							ln.AnchorPoint = Vector2.new(0.5, 0.5); ln.Position = UDim2.fromOffset(x, ch / 2)
							ln.Size = UDim2.fromOffset(2, ch * 2); ln.Rotation = rot
							ln.BackgroundColor3 = lc; ln.BackgroundTransparency = 0.5; ln.BorderSizePixel = 0
							ln.Parent = box
						end
						x += step
					end
				end)
			end
			if style ~= "cave" and bottom >= 0 and h >= 9 then
			pcall(function()
				-- лепнина: карниз под потолком, золотой молдинг, пилястры с базой и капителью
				local wd = (h - bottom)
				local ix = sx * (w / 2 - 0.2)
				part("Crown", Vector3.new(0.6, 0.7, pl), Vector3.new(sx * (w / 2 - 0.3), h - 0.35, zc + pl / 2), C(92, 70, 52), Enum.Material.Wood)
				part("CrownLip", Vector3.new(0.9, 0.2, pl), Vector3.new(sx * (w / 2 - 0.45), h - 0.8, zc + pl / 2), C(70, 50, 36), Enum.Material.Wood)
				part("GoldLine", Vector3.new(0.15, 0.12, pl), Vector3.new(sx * (w / 2 - 0.12), h - 1.4, zc + pl / 2), C(190, 150, 70), Enum.Material.Metal)
				local pz = zc + 5
				while pz < zc + pl - 3 do
					part("PilasterBase", Vector3.new(0.9, 0.7, 1.7), Vector3.new(ix - sx * 0.1, 4.35, pz), C(60, 42, 30), Enum.Material.Wood)
					part("Pilaster", Vector3.new(0.55, h - 5.6, 1.2), Vector3.new(ix, 4.7 + (h - 5.6) / 2, pz), C(86, 62, 44), Enum.Material.Wood)
					part("PilasterCap", Vector3.new(0.9, 0.5, 1.7), Vector3.new(ix - sx * 0.1, h - 1.0, pz), C(104, 76, 52), Enum.Material.Wood)
					pz += rng:NextNumber(10, 13)
				end
			end)
			end
			local r = rng:NextNumber()
			if r < 0.34 then
				claw(sx, w, zc + rng:NextNumber(1, math.max(1.5, pl - 1)), rng:NextNumber(5, math.max(6, h - 3)))
			elseif r < 0.72 and style ~= "cave" then
				handprint(sx, w, zc + pl / 2, rng:NextNumber(5, 8))
			end
		end
		zc += pl
	end
end

local function floorTiles(zA: number, len: number, w: number, style: string?)
	local zc = zA
	while zc < zA + len - 0.01 do
		local pl = math.min(20, zA + len - zc)
		local col = (style == "cave") and jitter(C(54, 51, 49), 0.12) or jitter(C(136, 82, 48), 0.08)
		local fl = part("Floor", Vector3.new(w, 1, pl), Vector3.new(0, -0.5, zc + pl / 2), col, (style == "cave") and Enum.Material.Slate or Enum.Material.WoodPlanks)
		if style ~= "cave" then
			fl.Reflectance = 0.14
			-- паркет: чередующиеся полосы разного тона + золотая инкрустация у стен
			pcall(function()
			local n = math.max(2, math.floor(w / 1.6))
			local sw = w / n
			for i = 1, n do
				local sp = part("Parquet", Vector3.new(sw - 0.06, 0.05, pl), Vector3.new(-w / 2 + sw * (i - 0.5), 0.025, zc + pl / 2),
					(i % 2 == 0) and jitter(C(112, 66, 38), 0.07) or jitter(C(150, 94, 56), 0.07), Enum.Material.WoodPlanks)
				sp.Reflectance = 0.16
			end
			for _, sx in { -1, 1 } do
				part("FloorInlay", Vector3.new(0.18, 0.07, pl), Vector3.new(sx * (w / 2 - 1.3), 0.035, zc + pl / 2), C(190, 150, 70), Enum.Material.Metal)
			end
			end)
		end
		zc += pl
	end
end

-- переход между сегментами разной ширины/высоты
local function joint(z: number, wB: number, hB: number)
	local wide, narrow = math.max(lastW, wB), math.min(lastW, wB)
	local tall, short = math.max(lastH, hB), math.min(lastH, hB)
	if wide > narrow then
		local sw = (wide - narrow) / 2
		for _, sx in { -1, 1 } do
			part("Joint", Vector3.new(sw, tall, 1.5), Vector3.new(sx * (narrow / 2 + sw / 2), tall / 2, z), jitter(BRICKS[1], 0.1), Enum.Material.Fabric)
		end
	end
	if tall > short then
		part("JointTop", Vector3.new(narrow, tall - short, 1.5), Vector3.new(0, short + (tall - short) / 2, z), jitter(BRICKS[2], 0.1), Enum.Material.Fabric)
	end
	lastW, lastH = wB, hB
end

local function ribs(zA: number, len: number, w: number, h: number, pits)
	local z = zA + 8
	while z < zA + len - 2 do
		local inPit = false
		for _, g in pits do if z > zA + g[1] - 1 and z < zA + g[2] + 1 then inPit = true end end
		if not inPit then
			for _, sx in { -1, 1 } do
				part("Rib", Vector3.new(1.2, h, 2), Vector3.new(sx * (w / 2 - 0.6), h / 2, z), jitter(C(88, 52, 42), 0.1), Enum.Material.Fabric)
			end
		end
		z += 24
	end
	for _, sx in { -1, 1 } do   -- карниз
		part("Cornice", Vector3.new(0.8, 0.8, len), Vector3.new(sx * (w / 2 - 0.4), h - 0.4, zA + len / 2), C(44, 36, 32), Enum.Material.Concrete)
	end
end

-- ----- препятствия коридора -----
local function barrier(z: number)
	part("Barrier", Vector3.new(HW, 3.2, 2), Vector3.new(0, 1.6, z), C(52, 46, 42), Enum.Material.Metal)
	part("BarrierStripe", Vector3.new(HW, 0.4, 0.1), Vector3.new(0, 2.5, z - 1.05), C(255, 190, 40), Enum.Material.Neon)
end
local function pillars(z: number)
	for _, x in { -5, 5 } do
		part("Pillar", Vector3.new(3, HH, 3), Vector3.new(x, HH / 2, z), jitter(C(96, 56, 44), 0.1), Enum.Material.Fabric)
	end
end
local function crates(z: number)
	for _ = 1, 3 do
		local c = part("Crate", Vector3.new(4, 4, 4), Vector3.new(rng:NextNumber(-5.5, 5.5), 2, z + rng:NextNumber(-6, 6)), C(92, 66, 40), Enum.Material.Wood)
		c.CFrame = c.CFrame * CFrame.Angles(0, rng:NextNumber(0, 1.5), 0)
	end
end
local function vent(z: number)   -- низкий потолок: надо пригнуться (C / Ctrl)
	part("Vent", Vector3.new(HW, HH - 4.6, 14), Vector3.new(0, 4.6 + (HH - 4.6) / 2, z), C(32, 30, 30), Enum.Material.Metal)
	part("VentSign", Vector3.new(HW, 0.4, 0.1), Vector3.new(0, 4.9, z - 7.05), C(255, 190, 40), Enum.Material.Neon)
end
local obstacleKinds = { barrier, pillars, crates, barrier, vent }

-- ----- шкаф-укрытие (E: спрятаться / выйти). Монстр не трогает спрятавшегося -----
-- ------------------------------------------------------------
-- Окна с дождём, ящики с бейджами, сущность Eyes
-- ------------------------------------------------------------
local function ufr(parent: Instance, x: number, y: number, w: number, h: number, col: Color3, tr: number?, round: number?, rot: number?): Frame
	local f = Instance.new("Frame")
	f.AnchorPoint = Vector2.new(0.5, 0.5); f.Position = UDim2.fromScale(x, y); f.Size = UDim2.fromScale(w, h)
	f.BackgroundColor3 = col; f.BackgroundTransparency = tr or 0; f.BorderSizePixel = 0; f.Rotation = rot or 0
	if round then local uc = Instance.new("UICorner"); uc.CornerRadius = UDim.new(round, 0); uc.Parent = f end
	f.Parent = parent
	return f
end

local windows = {}
task.spawn(function()   -- молнии за окнами
	while true do
		task.wait(rng:NextNumber(5, 11))
		for i = #windows, 1, -1 do
			if not windows[i].part:IsDescendantOf(workspace) then table.remove(windows, i) end
		end
		if #windows > 0 then
			local wv = windows[rng:NextInteger(1, #windows)]
			for _ = 1, 2 do
				wv.flash.BackgroundTransparency = 0.08
				wv.light.Brightness = 3.5
				TweenService:Create(wv.flash, TweenInfo.new(0.35), { BackgroundTransparency = 1 }):Play()
				TweenService:Create(wv.light, TweenInfo.new(0.35), { Brightness = 0.6 }):Play()
				task.wait(rng:NextNumber(0.2, 0.45))
			end
		end
	end
end)

local function windowView(sx: number, w: number, z: number, H: number)
	local WW = 6
	local yc = 4.8 + H / 2
	local px = sx * (w / 2 - 0.12)
	local face = (sx == -1) and Enum.NormalId.Right or Enum.NormalId.Left
	local sky = mark(part("WinSky", Vector3.new(0.1, H, WW), Vector3.new(px, yc, z), C(8, 12, 22), Enum.Material.SmoothPlastic))
	local sg = Instance.new("SurfaceGui")
	sg.Face = face; sg.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize; sg.CanvasSize = Vector2.new(240, math.floor(240 * H / WW)); sg.LightInfluence = 0
	sg.Parent = sky
	local R = WW / H
	local bg = ufr(sg, 0.5, 0.5, 1, 1, C(10, 14, 26))
	bg.ClipsDescendants = true
	local g = Instance.new("UIGradient"); g.Color = ColorSequence.new(C(4, 6, 16), C(44, 54, 78)); g.Rotation = 90; g.Parent = bg
	ufr(bg, 0.7, 0.2, 0.46, 0.46 * R, C(150, 170, 220), 0.82, 0.5)
	ufr(bg, 0.7, 0.2, 0.28, 0.28 * R, C(232, 238, 255), 0, 0.5)
	for _ = 1, 5 do   -- тучи
		ufr(bg, rng:NextNumber(0.1, 0.9), rng:NextNumber(0.08, 0.5), rng:NextNumber(0.5, 0.95), rng:NextNumber(0.05, 0.1), C(14, 18, 28), rng:NextNumber(0.1, 0.45), 0.5)
	end
	for i = 0, 5 do   -- силуэты деревьев
		local th = rng:NextNumber(0.07, 0.17)
		ufr(bg, i / 5 + rng:NextNumber(-0.05, 0.05), 1 - th / 2 + 0.01, rng:NextNumber(0.22, 0.4), th, C(3, 5, 6), 0, 0.5)
	end
	local hx = rng:NextNumber(0.25, 0.7)   -- далёкий дом с одним окном
	ufr(bg, hx, 0.86, 0.22, 0.12, C(5, 6, 9)); ufr(bg, hx, 0.8, 0.15, 0.06, C(5, 6, 9), 0, nil, 0)
	ufr(bg, hx + 0.02, 0.86, 0.03, 0.025, C(255, 200, 110), 0.1)
	local flash = ufr(bg, 0.5, 0.5, 1, 1, C(210, 226, 255), 1)
	flash.ZIndex = 5
	local glass = mark(part("WinGlass", Vector3.new(0.08, H - 0.8, WW - 0.8), Vector3.new(px - sx * 0.12, yc, z), C(150, 180, 210), Enum.Material.Glass))
	glass.Transparency = 0.8; glass.Reflectance = 0.1
	local dg = Instance.new("SurfaceGui")
	dg.Face = face; dg.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize; dg.CanvasSize = Vector2.new(240, math.floor(240 * H / WW)); dg.LightInfluence = 0.2
	dg.Parent = glass
	for _ = 1, 22 do   -- капли и потёки на стекле
		local streak = rng:NextNumber() < 0.35
		ufr(dg, rng:NextNumber(0.05, 0.95), rng:NextNumber(0.05, 0.95), 0.012 + (streak and 0 or 0.01), streak and rng:NextNumber(0.06, 0.16) or 0.016, C(190, 210, 235), rng:NextNumber(0.45, 0.8), 0.5)
	end
	local wood, gold = C(44, 28, 18), C(176, 138, 58)
	local fxp = px - sx * 0.2
	part("WinFrame", Vector3.new(0.4, 0.55, WW + 0.8), Vector3.new(fxp, yc + H / 2 + 0.1, z), wood, Enum.Material.Wood)
	part("WinFrame", Vector3.new(0.4, 0.55, WW + 0.8), Vector3.new(fxp, yc - H / 2 - 0.1, z), wood, Enum.Material.Wood)
	for _, dz in { -1, 1 } do part("WinFrame", Vector3.new(0.4, H + 0.6, 0.5), Vector3.new(fxp, yc, z + dz * (WW / 2 + 0.1)), wood, Enum.Material.Wood) end
	part("WinMullion", Vector3.new(0.3, H, 0.25), Vector3.new(fxp, yc, z), wood, Enum.Material.Wood)
	for k = 1, 2 do part("WinMullion", Vector3.new(0.3, 0.25, WW), Vector3.new(fxp, yc - H / 2 + H * k / 3, z), wood, Enum.Material.Wood) end
	part("WinSill", Vector3.new(0.9, 0.3, WW + 1.4), Vector3.new(px - sx * 0.45, yc - H / 2 - 0.45, z), C(60, 40, 26), Enum.Material.Wood)
	part("CurtainRod", Vector3.new(0.2, 0.2, WW + 4), Vector3.new(px - sx * 0.6, yc + H / 2 + 1.1, z), gold, Enum.Material.Metal)
	for _, dz in { -1, 1 } do
		local cp = mark(part("Curtain", Vector3.new(0.45, H + 1.5, 1.9), Vector3.new(px - sx * 0.55, yc + 0.2, z + dz * (WW / 2 + 1.0)), jitter(C(78, 16, 24), 0.2), Enum.Material.Fabric))
		cp.CFrame = cp.CFrame * CFrame.Angles(0, dz * 0.08, 0)
	end
	local rp = mark(part("RainEmit", Vector3.new(0.1, 0.1, WW - 0.6), Vector3.new(px - sx * 0.08, yc + H / 2 - 0.4, z), C(0, 0, 0), Enum.Material.SmoothPlastic))
	rp.Transparency = 1
	local pe = Instance.new("ParticleEmitter")
	pe.Rate = 45; pe.Lifetime = NumberRange.new(0.22, 0.3); pe.Speed = NumberRange.new(34, 42)
	pe.EmitterDirection = Enum.NormalId.Bottom; pe.SpreadAngle = Vector2.new(0, 0)
	pe.Size = NumberSequence.new(0.1); pe.Transparency = NumberSequence.new(0.5)
	pe.Color = ColorSequence.new(C(190, 210, 240)); pe.LightEmission = 0.5
	pe.Orientation = Enum.ParticleOrientation.VelocityParallel
	pe.Squash = NumberSequence.new(-3)
	pe.Parent = rp
	local pl = Instance.new("PointLight")
	pl.Color = C(130, 160, 255); pl.Range = 28; pl.Brightness = 0.6; pl.Shadows = false; pl.Parent = sky
	local rs = Instance.new("Sound")   -- шум дождя слышен рядом с окном
	rs.SoundId = ""; rs.Looped = true; rs.Volume = 0   -- шум дождя у окон отключён
	rs.RollOffMode = Enum.RollOffMode.Linear; rs.RollOffMinDistance = 10; rs.RollOffMaxDistance = 75
	rs.Parent = sky; rs.Playing = true
	table.insert(windows, { part = sky, flash = flash, light = pl })
end

local function lootBox(sx: number, w: number, z: number)
	local trunk = rng:NextNumber() < 0.45
	local box = { looted = false, amount = rng:NextInteger(5, 11) + curIdx // 8 }
	local myParent = curParent
	local wood, dwood, gold = C(88, 56, 34), C(52, 32, 20), C(204, 164, 72)
	local openFn: () -> ()
	local trigPos: Vector3
	local trigSize: Vector3
	if not trunk then
		local D, W, H = 2.4, 5.2, 4.2
		local x = sx * (w / 2 - D / 2 - 0.1)
		part("DrBody", Vector3.new(D, H, W), Vector3.new(x, H / 2, z), wood, Enum.Material.Wood)
		part("DrTop", Vector3.new(D + 0.4, 0.3, W + 0.4), Vector3.new(x, H + 0.15, z), dwood, Enum.Material.Wood)
		part("DrPlinth", Vector3.new(D + 0.2, 0.5, W + 0.2), Vector3.new(x, 0.25, z), dwood, Enum.Material.Wood)
		local drawers = {}
		for k = 1, 3 do
			local y = 1.15 + (k - 1) * 1.1
			local f = part("DrFront", Vector3.new(0.2, 0.95, W - 0.5), Vector3.new(sx * (w / 2 - D - 0.1), y, z), jitter(wood, 0.08), Enum.Material.Wood)
			local kn = part("DrKnob", Vector3.new(0.3, 0.3, 0.3), Vector3.new(sx * (w / 2 - D - 0.35), y, z), gold, Enum.Material.Metal)
			kn.Shape = Enum.PartType.Ball
			table.insert(drawers, { f, kn })
		end
		openFn = function()
			local d = drawers[rng:NextInteger(1, 3)]
			for _, p in d do
				TweenService:Create(p, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = p.Position + Vector3.new(-sx * 1.5, 0, 0) }):Play()
			end
		end
		trigPos = Vector3.new(sx * (w / 2 - D - 1.0), 2.1, z); trigSize = Vector3.new(1.2, 4.2, W)
	else
		local D, W, H = 2.8, 4.8, 2.4
		local x = sx * (w / 2 - D / 2 - 0.1)
		local bh = H * 0.62
		part("TrBody", Vector3.new(D, bh, W), Vector3.new(x, bh / 2, z), wood, Enum.Material.Wood)
		for _, dz in { -1.5, 0, 1.5 } do part("TrStrap", Vector3.new(D + 0.12, bh, 0.28), Vector3.new(x, bh / 2, z + dz), gold, Enum.Material.Metal) end
		local hingePos = O + Vector3.new(sx * (w / 2 - 0.15), bh, z)
		local hinge = CFrame.new(hingePos)
		local lidParts, lidBase = {}, {}
		local function lp(name: string, size: Vector3, pos: Vector3, col: Color3, mat: Enum.Material)
			local p = part(name, size, pos, col, mat)
			table.insert(lidParts, p); table.insert(lidBase, p.CFrame)
			return p
		end
		lp("TrLid", Vector3.new(D, 0.7, W), Vector3.new(x, bh + 0.35, z), jitter(wood, 0.06), Enum.Material.Wood)
		for _, dz in { -1.5, 0, 1.5 } do lp("TrLidStrap", Vector3.new(D + 0.12, 0.78, 0.28), Vector3.new(x, bh + 0.35, z + dz), gold, Enum.Material.Metal) end
		local lock = lp("TrLock", Vector3.new(0.3, 0.7, 0.6), Vector3.new(sx * (w / 2 - D - 0.05), bh, z), gold, Enum.Material.Metal)
		openFn = function()
			task.spawn(function()
				local t0 = os.clock()
				while true do
					local k = math.clamp((os.clock() - t0) / 0.55, 0, 1)
					local e = 1 - (1 - k) ^ 3
					local rot = hinge * CFrame.Angles(0, 0, -sx * 1.3 * e) * hinge:Inverse()
					for i, p in lidParts do p.CFrame = rot * lidBase[i]; p.CanCollide = false end
					if k >= 1 then break end
					RunService.Heartbeat:Wait()
				end
			end)
		end
		trigPos = Vector3.new(sx * (w / 2 - D - 1.0), 1.4, z); trigSize = Vector3.new(1.4, 2.8, W)
	end
	local tp = mark(part("LootTrigger", trigSize, trigPos, C(0, 0, 0), Enum.Material.SmoothPlastic))
	tp.Transparency = 1
	local pp = Instance.new("ProximityPrompt")
	pp.ActionText = "Search"; pp.ObjectText = trunk and "Chest" or "Drawer"; pp.HoldDuration = 0
	pp.MaxActivationDistance = 9; pp.RequiresLineOfSight = false; pp.KeyboardKeyCode = Enum.KeyCode.E; pp.Style = Enum.ProximityPromptStyle.Custom   -- без окошка с «E», клавиша работает
	pp.Parent = tp
	local hint = Instance.new("ParticleEmitter")   -- золотая пыль над неоткрытым ящиком
	hint.Rate = 3; hint.Lifetime = NumberRange.new(1.5, 2.5); hint.Speed = NumberRange.new(0.5, 1.2); hint.SpreadAngle = Vector2.new(30, 30)
	hint.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0) })
	hint.Color = ColorSequence.new(C(255, 214, 120)); hint.LightEmission = 1; hint.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	hint.Parent = tp
	local myO = O
	pp.Triggered:Connect(function(plr)
		if box.looted then return end
		box.looted = true
		pp:Destroy(); hint:Destroy()
		openFn()
		-- вспышка золота и монетки
		local a = Instance.new("Part")
		a.Anchored = true; a.CanCollide = false; a.CanQuery = false; a.Transparency = 1; a.Size = Vector3.one
		a.Position = myO + trigPos + Vector3.new(sx * 1.2, 0.4, 0); a.Parent = myParent
		local pe = Instance.new("ParticleEmitter")
		pe.Rate = 0; pe.Lifetime = NumberRange.new(0.6, 1.2); pe.Speed = NumberRange.new(6, 14); pe.SpreadAngle = Vector2.new(70, 70)
		pe.EmitterDirection = Enum.NormalId.Top
		pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 0) })
		pe.Color = ColorSequence.new(C(255, 214, 110)); pe.LightEmission = 1; pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		pe.Parent = a; pe:Emit(36)
		local pl = Instance.new("PointLight"); pl.Color = C(255, 210, 120); pl.Range = 18; pl.Brightness = 2.5; pl.Parent = a
		TweenService:Create(pl, TweenInfo.new(0.9), { Brightness = 0 }):Play()
		Debris:AddItem(a, 2.5)
		for _ = 1, 7 do
			local c = Instance.new("Part")
			c.Shape = Enum.PartType.Ball; c.Size = Vector3.new(0.4, 0.4, 0.4); c.Color = C(255, 205, 80); c.Material = Enum.Material.Neon
			c.CanCollide = false; c.CanQuery = false; c.Position = a.Position; c.Parent = myParent
			c.AssemblyLinearVelocity = Vector3.new(rng:NextNumber(-6, 6) - sx * 2, rng:NextNumber(10, 18), rng:NextNumber(-6, 6))
			Debris:AddItem(c, 1.4)
		end
		onLoot(plr, box)
	end)
end

local function eyesEntity(zA: number)
	-- ГИГАНТСКИЙ ЧЁРНО-КРАСНЫЙ ГЛАЗ, висящий на верёвочной петле под потолком
	local cx, cz = 0, zA + 20
	local d = 11
	local cy = RH - 5 - d / 2 - 1.5
	local top = RH - 0.4
	local m = Instance.new("Model")
	m.Name = "EyesEntity"
	local pivot = Instance.new("Part")
	pivot.Name = "Pivot"; pivot.Size = Vector3.one; pivot.Transparency = 1
	pivot.Anchored = true; pivot.CanCollide = false; pivot.CanQuery = false; pivot.CanTouch = false
	pivot.CFrame = CFrame.new(O + Vector3.new(cx, cy, cz))
	pivot.Parent = m
	m.PrimaryPart = pivot
	local BLK, RED = C(14, 14, 14), C(235, 235, 235)
	local xm = curLevel.diff == "newyear"
	local function mk(name: string, size: Vector3, cf: CFrame, col: Color3, mat: Enum.Material, shape: Enum.PartType?): Part
		local p = Instance.new("Part")
		p.Name = name; p.Size = size; p.CFrame = cf
		if shape then p.Shape = shape end
		p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.CastShadow = false
		p.Color = col; p.Material = mat; p.Parent = m
		return p
	end
	local c0 = O + Vector3.new(cx, cy, cz)
	-- красная аура за глазом
	local aura = mk("Aura", Vector3.one * (d * 1.5), CFrame.new(c0 + Vector3.new(0, 0, 0.8)), RED, Enum.Material.Neon, Enum.PartType.Ball)
	aura.Transparency = 0.9
	TweenService:Create(aura, TweenInfo.new(1.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Transparency = 0.78 }):Play()
	local pl = Instance.new("PointLight")
	pl.Color = C(235, 235, 245); pl.Range = 60; pl.Brightness = 1.6; pl.Shadows = false; pl.Parent = aura
	-- сам глаз: чёрный белок с красными жилами, красная радужка
	local em = Instance.new("Model")
	em.Name = "Eye"
	local sc = makeEye(em, c0 + Vector3.new(0, 0, 0), Vector3.new(0, 0, -1), d, {
		iris = xm and C(60, 235, 90) or C(255, 22, 22), neon = true, slit = true, sclera = (not xm) and C(16, 8, 10) or nil, vein = C(255, 30, 30), veins = 9,
	})
	em.Parent = m
	CollectionService:AddTag(em, "EvaKEye")
	-- верёвка от потолка и петля (удавка) вокруг верха глаза
	local rope = xm and C(230, 190, 70) or C(150, 118, 70)
	if xm then   -- глаз внутри огромного ёлочного шара
		local gl = mk("Bauble", Vector3.one * (d * 1.32), CFrame.new(c0 + Vector3.new(0, 0, d * 0.1)), C(200, 20, 30), Enum.Material.Glass, Enum.PartType.Ball)
		gl.Transparency = 0.55; gl.Reflectance = 0.35
		mk("BaubleCap", Vector3.new(1.4, 4.4, 4.4), CFrame.new(c0 + Vector3.new(0, d * 0.66 + 0.5, d * 0.1)) * CFrame.Angles(0, 0, math.pi / 2), C(235, 190, 70), Enum.Material.Metal, Enum.PartType.Cylinder)
	end
	local ropeLen = top - (cy + d * 0.42)
	mk("RopeUp", Vector3.new(0.45, ropeLen, 0.45), CFrame.new(O + Vector3.new(cx, top - ropeLen / 2, cz + d * 0.12)), rope, Enum.Material.Fabric)
	local rr = d * 0.5 + 0.5
	for k = 0, 15 do   -- петля: кольцо из звеньев вокруг глаза
		local a = k / 16 * math.pi * 2
		mk("Loop", Vector3.new(0.6, rr * 2 * math.pi / 16 + 0.3, 0.6), CFrame.new(c0 + Vector3.new(math.cos(a) * rr, math.sin(a) * rr, d * 0.12)) * CFrame.Angles(0, 0, a), jitter(rope, 0.08), Enum.Material.Fabric)
	end
	for _, sx in { -1, 1 } do   -- две ветви петли сходятся в узел
		local br = mk("LoopBranch", Vector3.new(0.4, 3.2, 0.4), CFrame.new(c0 + Vector3.new(sx * 1.1, d * 0.5 + 1.2, d * 0.12)) * CFrame.Angles(0, 0, -sx * 0.35), rope, Enum.Material.Fabric)
	end
	mk("Knot", Vector3.new(1.4, 1.8, 1.4), CFrame.new(O + Vector3.new(cx, cy + d * 0.5 + 1.8, cz + d * 0.12)), jitter(rope, 0.1), Enum.Material.Fabric, Enum.PartType.Ball)
	m.Parent = curParent
	CollectionService:AddTag(m, "EvaKEyesEntity")
	curLevel.eyeEnts = curLevel.eyeEnts or {}
	table.insert(curLevel.eyeEnts, m)
	-- покачивание на верёвке
	local anchor = CFrame.new(O + Vector3.new(cx, top, cz))
	local base = pivot.CFrame
	task.spawn(function()
		local t0, ph = os.clock(), rng:NextNumber(0, 6)
		while m.Parent do
			local t = os.clock() - t0 + ph
			local a = math.sin(t * 0.7) * 0.05
			m:PivotTo(anchor * CFrame.Angles(a * 0.4, 0, a) * anchor:Inverse() * base)
			task.wait(0.08)
		end
	end)
end

local function safe(f: any, ...)
	local ok, e = pcall(f, ...)
	if not ok then warn("[EvaKMap] декор:", e) end
end
local BOOKCOL = { C(110, 30, 30), C(30, 60, 90), C(40, 80, 50), C(120, 90, 40), C(70, 40, 80), C(90, 60, 40) }
local function bookshelf(sx: number, w: number, z: number)
	local D, W, H = 1.8, 6.4, 10
	local x = sx * (w / 2 - D / 2 - 0.05)
	local dw = C(58, 37, 22)
	part("BsBack", Vector3.new(0.2, H, W), Vector3.new(sx * (w / 2 - 0.15), H / 2, z), dw, Enum.Material.Wood)
	for _, dz in { -1, 1 } do part("BsSide", Vector3.new(D, H, 0.3), Vector3.new(x, H / 2, z + dz * (W / 2 - 0.15)), dw, Enum.Material.Wood) end
	part("BsTop", Vector3.new(D + 0.3, 0.45, W + 0.3), Vector3.new(x, H + 0.22, z), C(44, 28, 17), Enum.Material.Wood)
	local rows = 4
	local step = (H - 0.6) / rows
	for r = 0, rows do
		local yy = 0.4 + r * step
		part("BsShelf", Vector3.new(D - 0.1, 0.25, W - 0.4), Vector3.new(x, yy, z), dw, Enum.Material.Wood)
		if r < rows then
			local zz = z - W / 2 + 0.7
			while zz < z + W / 2 - 0.7 do
				local bw, bh = rng:NextNumber(0.28, 0.65), rng:NextNumber(1.4, step - 0.4)
				if rng:NextNumber() < 0.88 then
					mark(part("Book", Vector3.new(D - 0.7, bh, bw), Vector3.new(x, yy + 0.125 + bh / 2, zz), jitter(BOOKCOL[rng:NextInteger(1, #BOOKCOL)], 0.12), Enum.Material.Fabric))
				end
				zz += bw + 0.03
			end
		end
	end
end

local function armchair(sx: number, w: number, z: number)
	local x = sx * (w / 2 - 3.2)
	local col = jitter(C(100, 36, 42), 0.14)
	part("ChairBase", Vector3.new(3.4, 1.4, 3.6), Vector3.new(x, 0.9, z), col, Enum.Material.Fabric)
	part("ChairSeat", Vector3.new(2.8, 0.7, 3.0), Vector3.new(x - sx * 0.2, 1.8, z), col:Lerp(C(255, 255, 255), 0.1), Enum.Material.Fabric)
	part("ChairBack", Vector3.new(0.9, 3.4, 3.6), Vector3.new(x + sx * 1.3, 2.8, z), col, Enum.Material.Fabric)
	for _, dz in { -1, 1 } do part("ChairArm", Vector3.new(3.0, 1.6, 0.7), Vector3.new(x, 2.1, z + dz * 1.55), col:Lerp(C(0, 0, 0), 0.15), Enum.Material.Fabric) end
	for _, dx in { -1.4, 1.4 } do for _, dz in { -1.5, 1.5 } do part("ChairLeg", Vector3.new(0.3, 0.4, 0.3), Vector3.new(x + dx, 0.2, z + dz), C(40, 26, 16), Enum.Material.Wood) end end
	local tz = z + 4.6   -- столик с лампой
	part("TableTop", Vector3.new(2.2, 0.25, 2.2), Vector3.new(x + sx * 0.8, 2.6, tz), C(70, 44, 26), Enum.Material.Wood)
	part("TableLeg", Vector3.new(0.35, 2.5, 0.35), Vector3.new(x + sx * 0.8, 1.25, tz), C(50, 32, 20), Enum.Material.Wood)
	part("LampFoot", Vector3.new(0.5, 0.8, 0.5), Vector3.new(x + sx * 0.8, 3.1, tz), C(176, 138, 58), Enum.Material.Metal)
	local sh = part("LampShade", Vector3.new(1.1, 1.0, 1.1), Vector3.new(x + sx * 0.8, 3.9, tz), C(255, 210, 140), Enum.Material.Neon)
	sh.CanCollide = false
	local pl = Instance.new("PointLight")
	pl.Range = 22; pl.Brightness = 0.9; pl.Color = C(255, 200, 130); pl.Shadows = false; pl.Parent = sh
	table.insert(lamps, { part = sh, light = pl, base = 0.9, seed = rng:NextNumber(0, 100), bad = false })
end

local function chandelier(x: number, z: number)
	local y = RH - 6
	part("ChChain", Vector3.new(0.18, 6, 0.18), Vector3.new(x, RH - 3, z), C(60, 48, 30), Enum.Material.Metal)
	local hub = part("ChHub", Vector3.new(1.3, 1.3, 1.3), Vector3.new(x, y, z), C(255, 224, 170), Enum.Material.Neon)
	hub.Shape = Enum.PartType.Ball; hub.CanCollide = false
	part("ChRing", Vector3.new(0.3, 0.3, 4.8), Vector3.new(x, y - 0.6, z), C(176, 138, 58), Enum.Material.Metal)
	part("ChRing", Vector3.new(4.8, 0.3, 0.3), Vector3.new(x, y - 0.6, z), C(176, 138, 58), Enum.Material.Metal)
	for k = 0, 5 do
		local a = k * math.pi / 3
		local b = part("ChBulb", Vector3.new(0.55, 0.55, 0.55), Vector3.new(x + math.cos(a) * 2.2, y - 0.1, z + math.sin(a) * 2.2), C(255, 214, 150), Enum.Material.Neon)
		b.Shape = Enum.PartType.Ball; b.CanCollide = false
	end
	local pl = Instance.new("PointLight")
	pl.Range = 48; pl.Brightness = 1.9; pl.Color = C(255, 206, 150); pl.Shadows = true; pl.Parent = hub
	table.insert(lamps, { part = hub, light = pl, base = 1.9, seed = rng:NextNumber(0, 100), bad = rng:NextNumber() < 0.15 })
end

-- ----- шкаф-укрытие: E -> створки открываются, ты заходишь, створки закрываются, наблюдаешь в щели -----
local function wardrobe(w: number, zA: number, len: number, fsx: number?, fz: number?)
	local sx = fsx or ((rng:NextInteger(0, 1) == 0) and -1 or 1)
	local z = fz or (zA + rng:NextNumber(16, math.max(17, len - 16)))
	local D, W, H = 3.4, 5.2, 7.6
	local xc = sx * (w / 2 - D / 2 - 0.1)
	local wood, dwood, gold = C(176, 112, 66), C(132, 80, 46), C(238, 222, 190)
	local function box(name: string, sz: Vector3, x: number, y: number, zz: number, col: Color3, mat: Enum.Material?): Part
		return part(name, sz, Vector3.new(x, y, zz), col, mat or Enum.Material.Wood)
	end
	box("WdBack", Vector3.new(0.4, H, W), sx * (w / 2 - 0.25), H / 2, z, wood)
	for _, dz in { -1, 1 } do
		box("WdSide", Vector3.new(D, H, 0.4), xc, H / 2, z + dz * (W / 2 - 0.2), wood)
		mark(box("WdSidePanel", Vector3.new(D - 1.4, H - 3.2, 0.14), xc, H / 2, z + dz * (W / 2 + 0.05), jitter(wood, 0.1)))
		mark(box("WdSideTrim", Vector3.new(D - 1.0, 0.16, 0.18), xc, H / 2 + (H - 3.2) / 2, z + dz * (W / 2 + 0.07), gold, Enum.Material.Metal))
		mark(box("WdSideTrim", Vector3.new(D - 1.0, 0.16, 0.18), xc, H / 2 - (H - 3.2) / 2, z + dz * (W / 2 + 0.07), gold, Enum.Material.Metal))
	end
	box("WdTop", Vector3.new(D + 0.5, 0.6, W + 0.5), xc, H + 0.3, z, dwood)
	box("WdCrown", Vector3.new(D + 0.9, 0.35, W + 0.9), xc, H + 0.78, z, dwood)
	box("WdCrown", Vector3.new(D + 1.3, 0.25, W + 1.3), xc, H + 1.08, z, wood)
	box("WdPlinth", Vector3.new(D + 0.4, 0.9, W + 0.4), xc, 0.45, z, dwood)
	-- внутри: перекладина и одежда
	local railX = sx * (w / 2 - 1.4)
	mark(box("WdRail", Vector3.new(0.2, 0.2, W - 0.8), railX, H - 1.6, z, C(160, 138, 90), Enum.Material.Metal))
	for k = 1, 5 do
		local ch = rng:NextNumber(3.5, 5)
		mark(box("WdCoat", Vector3.new(0.5, ch, 0.9), railX, H - 1.7 - ch / 2, z + (k - 3) * 1.3, jitter(C(40, 32, 32), 0.5), Enum.Material.Fabric))
	end
	-- створки на шарнирах
	local fx = sx * (w / 2 - D + 0.15)
	local LW, y0, y1 = (W - 0.9) / 2, 0.9, H - 0.02
	local yc = (y0 + y1) / 2
	local leaves = {}
	for _, sz in { -1, 1 } do
		local hz = z + sz * (W / 2 - 0.45)
		local lf = { parts = {}, base = {}, hinge = CFrame.new(O + Vector3.new(fx, 0, hz)) }
		local function lp(name: string, size: Vector3, dz: number, y: number, col: Color3, mat: Enum.Material, tilt: number?, ox: number?): Part
			local p = part(name, size, Vector3.new(fx + (ox or 0), y, hz - sz * dz), col, mat)
			if tilt then p.CFrame = p.CFrame * CFrame.Angles(0, 0, tilt) end
			table.insert(lf.parts, p); table.insert(lf.base, p.CFrame)
			return p
		end
		lp("LfBack", Vector3.new(0.1, y1 - y0, LW + 0.04), LW / 2, yc, dwood, Enum.Material.Wood, nil, sx * 0.12)
		lp("LfStile", Vector3.new(0.45, y1 - y0, 0.4), 0.2, yc, dwood, Enum.Material.Wood)
		lp("LfStile", Vector3.new(0.45, y1 - y0, 0.4), LW - 0.2, yc, dwood, Enum.Material.Wood)
		for _, ry in { y0 + 0.25, yc, y1 - 0.25 } do lp("LfRail", Vector3.new(0.45, 0.5, LW), LW / 2, ry, dwood, Enum.Material.Wood) end
		for _, band in { { y0 + 0.7, yc - 0.4 }, { yc + 0.4, y1 - 0.7 } } do
			local ph, pm = band[2] - band[1], (band[1] + band[2]) / 2
			lp("LfPanel", Vector3.new(0.14, ph, LW - 0.9), LW / 2, pm, wood, Enum.Material.Wood, nil, -sx * 0.16)
			lp("LfPanelIn", Vector3.new(0.14, ph - 0.9, LW - 1.8), LW / 2, pm, jitter(wood, 0.06), Enum.Material.Wood, nil, -sx * 0.27)
		end
		local kn = lp("LfKnob", Vector3.new(0.55, 0.55, 0.55), LW - 0.55, yc - 0.1, gold, Enum.Material.SmoothPlastic, nil, -sx * 0.35)
		kn.Shape = Enum.PartType.Ball
		table.insert(leaves, { sz = sz, parts = lf.parts, base = lf.base, hinge = lf.hinge })
	end
	local function applyAngle(a: number)
		for _, lf in leaves do
			local rot = lf.hinge * CFrame.Angles(0, sx * lf.sz * a, 0) * lf.hinge:Inverse()
			for i, p in lf.parts do
				p.CFrame = rot * lf.base[i]
				p.CanCollide = a < 0.02
			end
		end
	end
	local function swing(a0: number, a1: number, dur: number)
		local t0 = os.clock()
		while true do
			local k = math.clamp((os.clock() - t0) / dur, 0, 1)
			applyAngle(a0 + (a1 - a0) * (k * k * (3 - 2 * k)))
			if k >= 1 then break end
			RunService.Heartbeat:Wait()
		end
	end
	local pp0 = part("WdPrompt", Vector3.new(1, 6, W), Vector3.new(sx * (w / 2 - D - 1.1), 3.2, z), C(0, 0, 0))
	pp0.Transparency = 1; pp0.CanCollide = false
	local pp = Instance.new("ProximityPrompt")
	pp.ActionText = "Hide"; pp.ObjectText = "Wardrobe"; pp.HoldDuration = 0
	pp.MaxActivationDistance = 9; pp.RequiresLineOfSight = false; pp.KeyboardKeyCode = Enum.KeyCode.E; pp.Style = Enum.ProximityPromptStyle.Custom   -- без окошка с «E», клавиша работает
	pp.Parent = pp0
	local wd = {
		sx = sx, O = O, prompt = pp, swing = swing,
		pos = Vector3.new(xc, 4.0, z),
		door = Vector3.new(fx - sx * 1.8, 3.6, z),
		out = Vector3.new(sx * (w / 2 - D - 4.4), 3.6, z),
	}
	pp.Triggered:Connect(function(plr) onHide(plr, wd) end)
end

-- ----- коридор -----
-- ------------------------------------------------------------
-- Комнаты как в Doors: коробовый свод, колонны, комод
-- ------------------------------------------------------------
local VRISE = 5
local VR = ((RW / 2) ^ 2 + VRISE ^ 2) / (2 * VRISE)
local VCY = RH - VR
local function vaultIn(x: number): number   -- высота нижней поверхности свода над точкой x
	local xx = math.clamp(x, -(VR - 1.5), VR - 1.5)
	return VCY + math.sqrt((VR - 1) ^ 2 - xx ^ 2)
end
local function vault(zA: number, len: number)
	local n = 12
	local tm = math.asin((RW / 2 + 0.5) / VR)
	local wood, dark = C(120, 72, 42), C(70, 40, 24)
	local sw = 2 * VR * math.sin(tm / n) + 0.4
	for i = 1, n do
		local th = -tm + (i - 0.5) * (2 * tm / n)
		local p = part("VaultSlab", Vector3.new(sw, 1, len), Vector3.new((VR - 0.5) * math.sin(th), VCY + (VR - 0.5) * math.cos(th), zA + len / 2), jitter(wood, 0.05), Enum.Material.WoodPlanks)
		p.CFrame = p.CFrame * CFrame.Angles(0, 0, -th)
	end
	local rz = zA + 7.5
	while rz < zA + len - 2 do   -- поперечные балки
		for i = 1, n do
			local th = -tm + (i - 0.5) * (2 * tm / n)
			local p = mark(part("VaultRib", Vector3.new(sw, 0.8, 1.6), Vector3.new((VR - 1.3) * math.sin(th), VCY + (VR - 1.3) * math.cos(th), rz), dark, Enum.Material.Wood))
			p.CFrame = p.CFrame * CFrame.Angles(0, 0, -th)
		end
		rz += 15
	end
end
local function column(x: number, z: number)
	local top = vaultIn(x)
	local wood, dk = jitter(C(128, 76, 44), 0.06), C(88, 50, 28)
	part("ColPlinth", Vector3.new(4.2, 1.2, 4.2), Vector3.new(x, 0.6, z), dk, Enum.Material.Wood)
	part("ColBase", Vector3.new(3.4, 0.6, 3.4), Vector3.new(x, 1.5, z), wood, Enum.Material.Wood)
	local sh = top - 4.6
	part("ColShaft", Vector3.new(2.6, sh, 2.6), Vector3.new(x, 1.8 + sh / 2, z), wood, Enum.Material.Wood)
	for _, a in { { 1.35, 0 }, { -1.35, 0 }, { 0, 1.35 }, { 0, -1.35 } } do   -- желобки
		mark(part("ColFlute", Vector3.new(a[1] ~= 0 and 0.08 or 1.4, sh - 1, a[2] ~= 0 and 0.08 or 1.4), Vector3.new(x + a[1], 1.8 + sh / 2, z + a[2]), dk, Enum.Material.Wood))
	end
	part("ColNeck", Vector3.new(3.4, 0.6, 3.4), Vector3.new(x, top - 2.5, z), dk, Enum.Material.Wood)
	part("ColCap", Vector3.new(4.2, 0.8, 4.2), Vector3.new(x, top - 1.8, z), wood, Enum.Material.Wood)
	part("ColCap", Vector3.new(4.8, 0.9, 4.8), Vector3.new(x, top - 0.95, z), dk, Enum.Material.Wood)
	part("ColCap", Vector3.new(5.4, 0.5, 5.4), Vector3.new(x, top - 0.25, z), wood, Enum.Material.Wood)
end
local function dresser(sx: number, w: number, z: number)   -- комод: ящики выдвигаются (E), иногда в них есть бейджи
	local D, W, H = 3.0, 6.4, 4.6
	local x = sx * (w / 2 - D / 2 - 0.1)
	local wood, dk, knob = C(104, 46, 34), C(70, 30, 22), C(238, 222, 190)
	part("DrPlinth", Vector3.new(D, 0.5, W), Vector3.new(x, 0.25, z), dk, Enum.Material.Wood)
	local body = part("DrBody", Vector3.new(D, H - 0.9, W), Vector3.new(x, 0.5 + (H - 0.9) / 2, z), wood, Enum.Material.Wood)
	part("DrTop", Vector3.new(D + 0.4, 0.4, W + 0.4), Vector3.new(x, H - 0.2, z), dk, Enum.Material.Wood)
	local fx = x - sx * (D / 2 + 0.06)
	local dh = (H - 1.3) / 3
	local drawers = {}
	local tray = C(160, 110, 66)
	for k = 1, 3 do
		local yy = 0.7 + dh * (k - 0.5)
		local grp = {}
		local function add(p: Part): Part
			p.CanCollide = false
			table.insert(grp, { part = p, base = p.CFrame })
			return p
		end
		add(part("DrDrawer", Vector3.new(0.14, dh - 0.22, W - 0.6), Vector3.new(fx, yy, z), jitter(C(118, 52, 38), 0.05), Enum.Material.Wood))
		add(mark(part("DrDrawerTrim", Vector3.new(0.1, dh - 0.6, W - 1.3), Vector3.new(fx - sx * 0.08, yy, z), jitter(C(96, 40, 30), 0.05), Enum.Material.Wood)))
		for _, dz in { -1.5, 1.5 } do
			local b = add(mark(part("DrKnob", Vector3.new(0.5, 0.5, 0.5), Vector3.new(fx - sx * 0.3, yy, z + dz), knob, Enum.Material.SmoothPlastic)))
			b.Shape = Enum.PartType.Ball
		end
		-- внутренности ящика (выезжают вместе с фасадом)
		local tw, iw = 2.4, W - 1.0
		add(mark(part("DrTrayBottom", Vector3.new(tw, 0.12, iw), Vector3.new(fx + sx * (tw / 2 + 0.05), yy - dh / 2 + 0.28, z), tray, Enum.Material.Wood)))
		for _, dz in { -1, 1 } do
			add(mark(part("DrTraySide", Vector3.new(tw, dh - 0.45, 0.12), Vector3.new(fx + sx * (tw / 2 + 0.05), yy, z + dz * iw / 2), tray, Enum.Material.Wood)))
		end
		add(mark(part("DrTrayBack", Vector3.new(0.12, dh - 0.45, iw), Vector3.new(fx + sx * (tw + 0.05), yy, z), tray, Enum.Material.Wood)))
		if k == 2 and rng:NextNumber() < 0.13 and curIdx >= 4 then   -- редко: деревянный крест в ящике
			local cm = Instance.new("Model")
			cm.Name = "DresserCross"
			local cy0 = yy - dh / 2 + 0.28 + 0.2
			local cxx = fx + sx * (tw / 2 + 0.05)
			local post = add(part("CrossPost", Vector3.new(0.3, 0.26, 3.0), Vector3.new(cxx, cy0, z), C(88, 56, 34), Enum.Material.Wood))
			local arm = add(part("CrossArm", Vector3.new(1.7, 0.26, 0.3), Vector3.new(cxx, cy0, z - 0.7), C(96, 62, 38), Enum.Material.Wood))
			post.Parent = cm; arm.Parent = cm
			cm.PrimaryPart = post
			cm.Parent = curParent
			CollectionService:AddTag(cm, "EvaKCross")
			local gl = Instance.new("PointLight"); gl.Color = C(255, 210, 150); gl.Range = 6; gl.Brightness = 0.7; gl.Shadows = false; gl.Parent = post
		end
		drawers[k] = grp
	end
	local looted = false
	for k = 1, 3 do   -- у каждого ящика своя кнопка: открывается один ящик за раз
		local yy = 0.7 + dh * (k - 0.5)
		local pp0 = mark(part("DrPrompt", Vector3.new(1, dh - 0.1, W - 0.6), Vector3.new(fx - sx * 0.8, yy, z), C(0, 0, 0), Enum.Material.SmoothPlastic))
		pp0.Transparency = 1
		local pp = Instance.new("ProximityPrompt")
		pp.ActionText = "Open"; pp.ObjectText = "Drawer " .. k; pp.HoldDuration = 0
		pp.MaxActivationDistance = 7; pp.RequiresLineOfSight = false; pp.KeyboardKeyCode = Enum.KeyCode.E; pp.Style = Enum.ProximityPromptStyle.Custom
		pp.Parent = pp0
		local isOpen, busyD = false, false
		pp.Triggered:Connect(function(plr)
			if busyD then return end
			busyD = true; task.delay(0.45, function() busyD = false end)
			isOpen = not isOpen
			pp.ActionText = isOpen and "Close" or "Open"
			for _, r in drawers[k] do
				if r.part.Parent then
					TweenService:Create(r.part, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = r.base + Vector3.new(isOpen and -sx * 1.9 or 0, 0, 0) }):Play()
				end
			end
			if isOpen and not looted and rng:NextNumber() < 0.25 then
				looted = true
				task.delay(0.5, function() onLoot(plr, { amount = rng:NextInteger(2, 6) }) end)
			end
		end)
	end
end

-- пыль в лучах света и стелющийся туман: атмосфера
local function ambience(zA: number, len: number, w: number, h: number)
	local zc = zA + 14
	while zc < zA + len - 4 do
		local vol = mark(part("AirVolume", Vector3.new(w - 2, h - 2, 30), Vector3.new(0, h / 2, zc), C(0, 0, 0), Enum.Material.SmoothPlastic))
		vol.Transparency = 1
		local dust = Instance.new("ParticleEmitter")
		dust.Rate = 6; dust.Lifetime = NumberRange.new(6, 10); dust.Speed = NumberRange.new(0.1, 0.5)
		dust.Size = NumberSequence.new(0.14)
		dust.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, 0.5), NumberSequenceKeypoint.new(0.8, 0.5), NumberSequenceKeypoint.new(1, 1) })
		dust.LightEmission = 0.6; dust.Color = ColorSequence.new(C(255, 226, 180))
		dust.Shape = Enum.ParticleEmitterShape.Box; dust.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
		dust.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		dust.Parent = vol
		local mist = mark(part("MistVolume", Vector3.new(w - 3, 2.4, 30), Vector3.new(0, 1.3, zc), C(0, 0, 0), Enum.Material.SmoothPlastic))
		mist.Transparency = 1
		local fog = Instance.new("ParticleEmitter")
		fog.Rate = 0.7; fog.Lifetime = NumberRange.new(14, 18); fog.Speed = NumberRange.new(0.3, 0.9)
		fog.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 9), NumberSequenceKeypoint.new(1, 16) })
		fog.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.25, 0.88), NumberSequenceKeypoint.new(0.75, 0.9), NumberSequenceKeypoint.new(1, 1) })
		fog.Color = ColorSequence.new(C(130, 138, 160)); fog.LightInfluence = 0.8; fog.RotSpeed = NumberRange.new(-8, 8)
		fog.Shape = Enum.ParticleEmitterShape.Box; fog.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
		fog.Texture = "rbxasset://textures/particles/smoke_main.dds"
		fog.Parent = mist
		zc += 30
	end
end

-- ------------------------------------------------------------
-- Пещера: неровная порода, сталактиты, лужи, корни, грибы, кристаллы, крепи шахты, рельсы
-- ------------------------------------------------------------
local ROCKMAT = { Enum.Material.Rock, Enum.Material.Slate, Enum.Material.Basalt, Enum.Material.Rock }
local function rockCol(): Color3
	return jitter(C(66, 62, 60), 0.28)
end
local function spike(x: number, y0: number, z: number, w: number, h: number, down: boolean)
	-- ступенчатый конус: 4 блока, каждый уже и со случайным поворотом
	local yaw = rng:NextNumber(0, 3)
	local col = rockCol()
	for k = 0, 3 do
		local f = 1 - k * 0.24
		local sh = h / 4
		local cy = down and (y0 - sh * (k + 0.5)) or (y0 + sh * (k + 0.5))
		local p = mark(part("Spike", Vector3.new(w * f, sh + 0.15, w * f * rng:NextNumber(0.8, 1.1)), Vector3.new(x + rng:NextNumber(-0.08, 0.08) * w, cy, z), col, ROCKMAT[rng:NextInteger(1, 4)]))
		p.CFrame = p.CFrame * CFrame.Angles(rng:NextNumber(-0.08, 0.08), yaw + k * 0.4, rng:NextNumber(-0.08, 0.08))
	end
end
local function caveDress(zA: number, len: number)
	-- неровные глыбы по стенам и потолку
	local z = zA + 2
	while z < zA + len - 2 do
		for _, sx in { -1, 1 } do
			local s = Vector3.new(rng:NextNumber(2, 5), rng:NextNumber(3, 7), rng:NextNumber(2.5, 5.5))
			local p = mark(part("Chunk", s, Vector3.new(sx * (HW / 2 - rng:NextNumber(0.2, 1.1)), rng:NextNumber(0.5, HH - 1), z + rng:NextNumber(-1.5, 1.5)), rockCol(), ROCKMAT[rng:NextInteger(1, 4)]))
			p.CFrame = p.CFrame * CFrame.Angles(rng:NextNumber(-0.7, 0.7), rng:NextNumber(-0.7, 0.7), rng:NextNumber(-0.7, 0.7))
		end
		local c = mark(part("CeilChunk", Vector3.new(rng:NextNumber(3, 6), rng:NextNumber(1.5, 3), rng:NextNumber(3, 6)), Vector3.new(rng:NextNumber(-HW / 2 + 1, HW / 2 - 1), HH - rng:NextNumber(0.1, 0.9), z), rockCol(), ROCKMAT[rng:NextInteger(1, 4)]))
		c.CFrame = c.CFrame * CFrame.Angles(rng:NextNumber(-0.5, 0.5), rng:NextNumber(0, 3), rng:NextNumber(-0.5, 0.5))
		z += rng:NextNumber(2.6, 4.2)
	end
	-- сталактиты и сталагмиты
	for _ = 1, math.floor(len / 6) do
		spike(rng:NextNumber(-HW / 2 + 1.5, HW / 2 - 1.5), HH, zA + rng:NextNumber(3, len - 3), rng:NextNumber(0.9, 2), rng:NextNumber(2.5, 6), true)
	end
	for _ = 1, math.floor(len / 9) do
		spike(rng:NextNumber(-HW / 2 + 1.2, HW / 2 - 1.2), 0, zA + rng:NextNumber(3, len - 3), rng:NextNumber(0.8, 1.7), rng:NextNumber(1.5, 3.5), false)
	end
	-- щебень на полу
	for _ = 1, math.floor(len * 0.7) do
		local sz = rng:NextNumber(0.3, 1.1)
		local p = mark(part("Rubble", Vector3.new(sz, sz * rng:NextNumber(0.5, 0.9), sz * rng:NextNumber(0.8, 1.4)), Vector3.new(rng:NextNumber(-HW / 2 + 0.8, HW / 2 - 0.8), sz * 0.3, zA + rng:NextNumber(1, len - 1)), rockCol(), ROCKMAT[rng:NextInteger(1, 4)]))
		p.CFrame = p.CFrame * CFrame.Angles(rng:NextNumber(0, 3), rng:NextNumber(0, 3), rng:NextNumber(0, 3))
	end
	-- лужи с отражением
	for _ = 1, math.floor(len / 14) do
		local d = rng:NextNumber(2.5, 5.5)
		local p = mark(part("Puddle", Vector3.new(0.06, d, d * rng:NextNumber(0.6, 1.2)), Vector3.new(rng:NextNumber(-HW / 2 + 3, HW / 2 - 3), 0.1, zA + rng:NextNumber(6, len - 6)), C(18, 26, 34), Enum.Material.SmoothPlastic))
		p.Shape = Enum.PartType.Cylinder
		p.CFrame = CFrame.new(p.Position) * CFrame.Angles(0, rng:NextNumber(0, 3), math.pi / 2)
		p.Reflectance = 0.55; p.Transparency = 0.12
	end
	-- корни с потолка
	for _ = 1, math.floor(len / 8) do
		local rx, rz = rng:NextNumber(-HW / 2 + 1, HW / 2 - 1), zA + rng:NextNumber(2, len - 2)
		local l = rng:NextNumber(3, 7)
		local r = mark(part("Root", Vector3.new(l, 0.22, 0.22), Vector3.new(rx, HH - l / 2, rz), C(58, 40, 26), Enum.Material.Wood))
		r.CFrame = CFrame.new(r.Position) * CFrame.Angles(0, rng:NextNumber(0, 3), math.pi / 2 + rng:NextNumber(-0.25, 0.25))
		for _ = 1, 2 do
			local tw = mark(part("RootTwig", Vector3.new(l * 0.35, 0.12, 0.12), Vector3.new(rx, HH - l * rng:NextNumber(0.2, 0.8), rz), C(64, 44, 28), Enum.Material.Wood))
			tw.CFrame = CFrame.new(tw.Position) * CFrame.Angles(rng:NextNumber(0, 3), rng:NextNumber(0, 3), rng:NextNumber(0.3, 1.3))
		end
	end
	-- светящиеся грибы и кристаллы
	for i = 1, math.floor(len / 12) do
		local sx = (rng:NextInteger(0, 1) == 0) and -1 or 1
		local cz = zA + rng:NextNumber(4, len - 4)
		if i % 2 == 0 then
			for k = 1, rng:NextInteger(3, 5) do   -- кристаллы кучкой
				local h = rng:NextNumber(1.2, 3.2)
				local cr = part("Crystal", Vector3.new(0.5, h, 0.5), Vector3.new(sx * (HW / 2 - 1.1) + rng:NextNumber(-0.7, 0.7), h / 2 * 0.8, cz + rng:NextNumber(-0.8, 0.8)), C(90, 150, 255), Enum.Material.Neon)
				cr.CanCollide = false; cr.CastShadow = false; cr.Transparency = 0.15
				cr.CFrame = cr.CFrame * CFrame.Angles(rng:NextNumber(-0.4, 0.4), rng:NextNumber(0, 3), rng:NextNumber(-0.4, 0.4))
				if k == 1 then
					local pl = Instance.new("PointLight"); pl.Range = 16; pl.Brightness = 0.9; pl.Color = C(110, 170, 255); pl.Shadows = false; pl.Parent = cr
				end
			end
		else
			for k = 1, rng:NextInteger(3, 6) do   -- грибы
				local gx, gz = sx * (HW / 2 - 1.2) + rng:NextNumber(-0.9, 0.9), cz + rng:NextNumber(-1, 1)
				local gy = 0.5 + rng:NextNumber(0, 0.4)
				local g = part("Shroom", Vector3.new(0.5, 0.35, 0.5), Vector3.new(gx, gy, gz), C(110, 255, 170), Enum.Material.Neon)
				g.Shape = Enum.PartType.Ball; g.CanCollide = false; g.CastShadow = false
				mark(part("ShroomStem", Vector3.new(0.12, gy, 0.12), Vector3.new(gx, gy / 2, gz), C(190, 200, 180), Enum.Material.SmoothPlastic))
				if k == 1 then
					local pl = Instance.new("PointLight"); pl.Range = 11; pl.Brightness = 0.7; pl.Color = C(110, 255, 170); pl.Shadows = false; pl.Parent = g
				end
			end
		end
	end
	-- деревянные крепи шахты с фонарями
	local sz = zA + 14
	while sz < zA + len - 6 do
		local wood = C(76, 50, 30)
		for _, sx in { -1, 1 } do
			mark(part("MinePost", Vector3.new(0.9, HH - 0.6, 0.9), Vector3.new(sx * (HW / 2 - 0.7), (HH - 0.6) / 2, sz), jitter(wood, 0.12), Enum.Material.Wood))
			local br = mark(part("MineBrace", Vector3.new(0.5, 3.6, 0.5), Vector3.new(sx * (HW / 2 - 2.1), HH - 2.2, sz), jitter(wood, 0.12), Enum.Material.Wood))
			br.CFrame = br.CFrame * CFrame.Angles(0, 0, sx * 0.7)
		end
		mark(part("MineBeam", Vector3.new(HW, 0.9, 1), Vector3.new(0, HH - 0.7, sz), jitter(wood, 0.1), Enum.Material.Wood))
		local lx = rng:NextNumber(-3, 3)
		local lb = part("MineLantern", Vector3.new(0.5, 0.7, 0.5), Vector3.new(lx, HH - 2.2, sz - 0.8), C(255, 170, 80), Enum.Material.Neon)
		lb.CanCollide = false; lb.CastShadow = false
		mark(part("LanternChain", Vector3.new(0.08, 1.0, 0.08), Vector3.new(lx, HH - 1.2, sz - 0.8), C(30, 28, 26), Enum.Material.Metal))
		local pl = Instance.new("PointLight"); pl.Range = 24; pl.Brightness = 1.2; pl.Color = C(255, 170, 90); pl.Shadows = false; pl.Parent = lb
		table.insert(lamps, { part = lb, light = pl, base = 1.2, seed = rng:NextNumber(0, 100), bad = rng:NextNumber() < 0.3 })
		sz += rng:NextNumber(16, 22)
	end
	-- рельсы со шпалами
	for _, rx in { -1.1, 1.1 } do
		mark(part("Rail", Vector3.new(0.25, 0.25, len), Vector3.new(rx, 0.28, zA + len / 2), C(92, 86, 80), Enum.Material.Metal))
	end
	local tz = zA + 1
	while tz < zA + len do
		mark(part("Sleeper", Vector3.new(3.4, 0.2, 0.55), Vector3.new(0, 0.14, tz), jitter(C(60, 40, 26), 0.15), Enum.Material.Wood))
		tz += 3
	end
end

-- ------------------------------------------------------------
-- Финал: лаборатория с деревянным крестом (дверь 100)
-- ------------------------------------------------------------
local function labRoom(len: number): (number, number)
	joint(cur, RW, RH)
	local zA = cur
	local W, H = RW, RH
	local WHITE, TEAL = C(206, 214, 214), C(48, 108, 110)
	part("LabFloor", Vector3.new(W, 1, len), Vector3.new(0, -0.5, zA + len / 2), C(186, 196, 198), Enum.Material.Marble)
	for i = 0, math.floor(len / 6) do
		mark(part("TileLine", Vector3.new(W, 0.04, 0.12), Vector3.new(0, 0.03, zA + i * 6), C(118, 130, 132), Enum.Material.SmoothPlastic))
	end
	for x = -W / 2 + 6, W / 2 - 6, 6 do
		mark(part("TileLine", Vector3.new(0.12, 0.04, len), Vector3.new(x, 0.03, zA + len / 2), C(118, 130, 132), Enum.Material.SmoothPlastic))
	end
	for _, sx in { -1, 1 } do
		part("LabWall", Vector3.new(1, H + 2, len), Vector3.new(sx * (W / 2 + 0.5), H / 2, zA + len / 2), WHITE, Enum.Material.Concrete)
		part("LabDado", Vector3.new(0.3, 5, len), Vector3.new(sx * (W / 2 - 0.15), 2.5, zA + len / 2), TEAL, Enum.Material.Marble)
		mark(part("LabStripe", Vector3.new(0.2, 0.6, len), Vector3.new(sx * (W / 2 - 0.1), 5.3, zA + len / 2), C(210, 40, 40), Enum.Material.SmoothPlastic))
	end
	part("LabCeiling", Vector3.new(W + 2, 1, len), Vector3.new(0, H + 0.5, zA + len / 2), C(176, 184, 186), Enum.Material.Concrete)
	part("LabEndWall", Vector3.new(W + 2, H + 2, 2), Vector3.new(0, H / 2, zA + len + 1), C(196, 204, 204), Enum.Material.Concrete)
	-- холодные люминесцентные панели
	local lz = zA + 8
	while lz < zA + len - 4 do
		for _, lx in { -14, 14 } do
			local pn = part("Fluor", Vector3.new(3, 0.3, 10), Vector3.new(lx, H - 0.2, lz), C(220, 245, 255), Enum.Material.Neon)
			pn.CanCollide = false; pn.CastShadow = false
			local pl = Instance.new("PointLight"); pl.Range = 38; pl.Brightness = 1.1; pl.Color = C(200, 235, 255); pl.Shadows = false; pl.Parent = pn
			table.insert(lamps, { part = pn, light = pl, base = 1.1, seed = rng:NextNumber(0, 100), bad = rng:NextNumber() < 0.3 })
		end
		lz += 16
	end
	-- лабораторные столы с колбами и мониторами, ёмкости с глазами
	local function flask(x: number, y: number, z: number, col: Color3)
		local g = part("Flask", Vector3.new(1.3, 1.3, 1.3), Vector3.new(x, y + 0.65, z), C(190, 220, 230), Enum.Material.Glass)
		g.Shape = Enum.PartType.Ball; g.Transparency = 0.5; g.CanCollide = false; g.CastShadow = false
		local l = part("Liquid", Vector3.new(0.95, 0.95, 0.95), Vector3.new(x, y + 0.55, z), col, Enum.Material.Neon)
		l.Shape = Enum.PartType.Ball; l.Transparency = 0.3; l.CanCollide = false; l.CastShadow = false
		mark(part("FlaskNeck", Vector3.new(0.3, 0.7, 0.3), Vector3.new(x, y + 1.5, z), C(190, 220, 230), Enum.Material.Glass)).Transparency = 0.5
	end
	local az = zA + 14
	local n = 0
	while az < zA + len - 30 do
		n += 1
		for _, sx in { -1, 1 } do
			local x = sx * (W / 2 - 3)
			if (n + (sx > 0 and 1 or 0)) % 2 == 0 then
				part("Bench", Vector3.new(3.6, 3.2, 11), Vector3.new(x, 1.6, az), C(150, 158, 160), Enum.Material.Metal)
				part("BenchTop", Vector3.new(4, 0.3, 11.4), Vector3.new(x, 3.35, az), C(36, 40, 42), Enum.Material.Slate)
				for k = -1, 1 do
					flask(x + rng:NextNumber(-0.6, 0.6), 3.5, az + k * 3, (rng:NextInteger(0, 1) == 0) and C(80, 255, 140) or C(255, 70, 90))
				end
				local mon = part("Monitor", Vector3.new(0.3, 1.8, 2.6), Vector3.new(x - sx * 1.2, 4.5, az + 4), C(20, 22, 24), Enum.Material.Metal)
				mon.CanCollide = false
				local scr = part("MonitorScreen", Vector3.new(0.1, 1.4, 2.2), Vector3.new(x - sx * 1.4, 4.5, az + 4), C(60, 230, 160), Enum.Material.Neon)
				scr.CanCollide = false; scr.CastShadow = false
			else
				part("TankBase", Vector3.new(6, 0.8, 6), Vector3.new(x, 0.4, az), C(60, 66, 68), Enum.Material.Metal)
				local gl = part("TankGlass", Vector3.new(5.2, 10, 5.2), Vector3.new(x, 5.8, az), C(110, 200, 150), Enum.Material.Glass)
				gl.Transparency = 0.55; gl.CanCollide = false; gl.CastShadow = false
				local liq = part("TankLiquid", Vector3.new(4.8, 9, 4.8), Vector3.new(x, 5.8, az), C(60, 200, 120), Enum.Material.Neon)
				liq.Transparency = 0.85; liq.CanCollide = false; liq.CastShadow = false
				part("TankCap", Vector3.new(6, 0.8, 6), Vector3.new(x, 11, az), C(60, 66, 68), Enum.Material.Metal)
				local em = Instance.new("Model")
				em.Name = "Eye"
				makeEye(em, O + Vector3.new(x, 6.2, az), Vector3.new(-sx, 0, -0.3), 3.2, { iris = C(210, 170, 40), slit = true })
				em.Parent = curParent
				CollectionService:AddTag(em, "EvaKEye")
				local pl = Instance.new("PointLight"); pl.Range = 16; pl.Brightness = 0.8; pl.Color = C(90, 255, 160); pl.Shadows = false; pl.Parent = liq
			end
		end
		az += 18
	end
	-- кровь и след волочения к кресту
	for _ = 1, 7 do blood(W, zA + rng:NextNumber(10, len - 22)) end
	local zc = zA + len - 16
	mark(part("DragTrail", Vector3.new(1.3, 0.05, zc - zA - 8), Vector3.new(0, 0.12, zA + (zc - zA - 8) / 2 + 4), C(54, 4, 6), Enum.Material.SmoothPlastic)).Reflectance = 0.15
	-- помост
	part("DaisStep", Vector3.new(28, 0.6, 24), Vector3.new(0, 0.3, zc), C(66, 62, 60), Enum.Material.Slate)
	part("Dais", Vector3.new(26, 0.6, 22), Vector3.new(0, 0.9, zc), C(48, 44, 42), Enum.Material.Slate)
	-- деревянный крест
	local wood = C(72, 46, 28)
	local post = part("CrossPost", Vector3.new(1.5, 17, 1.5), Vector3.new(0, 1.2 + 8.5, zc), wood, Enum.Material.Wood)
	local arm = part("CrossArm", Vector3.new(13, 1.5, 1.5), Vector3.new(0, 14.4, zc), jitter(wood, 0.08), Enum.Material.Wood)
	post.CFrame = post.CFrame * CFrame.Angles(0, 0, 0.02)
	arm.CFrame = arm.CFrame * CFrame.Angles(0, 0, -0.015)
	mark(part("CrossGrain", Vector3.new(0.18, 14, 0.06), Vector3.new(0, 9.5, zc - 0.78), C(40, 24, 14), Enum.Material.Wood))
	mark(part("CrossGrain", Vector3.new(10, 0.18, 0.06), Vector3.new(0, 14.4, zc - 0.78), C(40, 24, 14), Enum.Material.Wood))
	-- верёвки: обмотки ствола, концов перекладины и перекрёст в центре
	local rope = C(178, 150, 98)
	for _, y in { 3.2, 4.4, 5.6, 6.8 } do
		local r = mark(part("Rope", Vector3.new(1.95, 0.3, 1.95), Vector3.new(0, y, zc), jitter(rope, 0.08), Enum.Material.Fabric))
		r.CFrame = r.CFrame * CFrame.Angles(rng:NextNumber(-0.1, 0.1), rng:NextNumber(0, 1), rng:NextNumber(-0.1, 0.1))
	end
	for _, x in { -5.6, -4.4, 4.4, 5.6, -1.9, 1.9 } do
		local r = mark(part("Rope", Vector3.new(0.3, 1.95, 1.95), Vector3.new(x, 14.4, zc), jitter(rope, 0.08), Enum.Material.Fabric))
		r.CFrame = r.CFrame * CFrame.Angles(rng:NextNumber(-0.1, 0.1), 0, rng:NextNumber(-0.1, 0.1))
	end
	for _, a in { 0.78, -0.78 } do
		local r = mark(part("RopeX", Vector3.new(3.2, 0.32, 1.95), Vector3.new(0, 14.4, zc), jitter(rope, 0.08), Enum.Material.Fabric))
		r.CFrame = r.CFrame * CFrame.Angles(0, 0, a)
	end
	for _, x in { -6, 6 } do   -- свисающие концы верёвок
		local r = mark(part("RopeEnd", Vector3.new(0.18, 2.4, 0.18), Vector3.new(x, 13.2, zc - 0.9), jitter(rope, 0.08), Enum.Material.Fabric))
		r.CFrame = r.CFrame * CFrame.Angles(0.1, 0, x * 0.02)
	end
	-- свет на кресте: холодный сверху и красный снизу
	local lp = part("CrossLight", Vector3.new(0.5, 0.5, 0.5), Vector3.new(0, 19.5, zc - 6), C(255, 255, 255), Enum.Material.SmoothPlastic)
	lp.Transparency = 1; lp.CanCollide = false
	local sl = Instance.new("SpotLight"); sl.Angle = 60; sl.Range = 40; sl.Brightness = 5; sl.Color = C(255, 230, 210); sl.Face = Enum.NormalId.Front; sl.Shadows = false; sl.Parent = lp
	lp.CFrame = CFrame.lookAt(lp.Position, O + Vector3.new(0, 10, zc))
	local rl = part("CrossRed", Vector3.new(0.5, 0.5, 0.5), Vector3.new(0, 3, zc - 7), C(255, 40, 30), Enum.Material.SmoothPlastic)
	rl.Transparency = 1; rl.CanCollide = false
	local pr = Instance.new("PointLight"); pr.Range = 30; pr.Brightness = 1.6; pr.Color = C(255, 50, 40); pr.Shadows = false; pr.Parent = rl
	cur += len
	return zA + 40, zc
end

local function hall(len: number, o)
	o = o or {}
	joint(cur, HW, HH)
	local zA, style = cur, o.style
	if o.obst and curLevel then curLevel.obst = curLevel.obst or {}; table.insert(curLevel.obst, { zA, zA + len }) end   -- зоны паркура: там нет разгона
	local gaps = o.gaps or {}
	local secs, pos = {}, 0
	for _, g in gaps do
		table.insert(secs, { pos, g[1], false })
		table.insert(secs, { g[1], g[2], true })
		pos = g[2]
	end
	table.insert(secs, { pos, len, false })
	for _, sc in secs do
		local a, b, pit = sc[1], sc[2], sc[3]
		if pit then
			part("PitBottom", Vector3.new(HW, 1, b - a), Vector3.new(0, -PIT - 0.5, zA + (a + b) / 2), C(10, 8, 8), Enum.Material.Slate)
			walls(zA + a, b - a, HW, HH, -PIT, style)
for _, ez in { a + 0.3, b - 0.3 } do
mark(part("PitEdge", Vector3.new(HW, 0.14, 0.6), Vector3.new(0, 0.07, zA + ez), C(255, 190, 40), Enum.Material.Neon))
end
		else
			floorTiles(zA + a, b - a, HW, style)
			walls(zA + a, b - a, HW, HH, 0, style)
			if style ~= "cave" then
				if curLevel.deco.wainscot then wainscot(zA + a, b - a, HW) end
				if curLevel.deco.carpet then carpet(zA + a, b - a, HW) end
			end
		end
	end
	part("Ceiling", Vector3.new(HW + 2, 1, len), Vector3.new(0, HH + 0.5, zA + len / 2), (style == "cave") and C(40, 38, 37) or C(92, 52, 34), (style == "cave") and Enum.Material.Rock or Enum.Material.Wood)
	if style ~= "cave" and HH >= 9 then
	pcall(function()
		-- сводчатый потолок как в DOORS: скошенные дощатые грани по бокам + поперечные балки
		for _, sx in { -1, 1 } do
			local vp = part("Vault", Vector3.new(6, 0.5, len), Vector3.new(sx * (HW / 2 - 2.2), HH - 1.1, zA + len / 2), C(104, 58, 38), Enum.Material.Wood)
			vp.CFrame = vp.CFrame * CFrame.Angles(0, 0, sx * 0.5)
			local vp2 = part("Vault", Vector3.new(0.5, 0.35, len), Vector3.new(sx * (HW / 2 - 5.1), HH - 0.2, zA + len / 2), C(60, 34, 22), Enum.Material.Wood)
		end
		local bz = zA + 6
		while bz < zA + len - 3 do
			part("CeilBeam", Vector3.new(HW - 1, 0.7, 0.9), Vector3.new(0, HH - 0.25, bz), C(70, 40, 26), Enum.Material.Wood)
			bz += 13
		end
	end)
	end

	if style ~= "cave" then
		ribs(zA, len, HW, HH, gaps)
		do
			local bz = zA + 6
			while bz < zA + len - 2 do
				local inPit = false
				for _, g in gaps do if bz > zA + g[1] - 1 and bz < zA + g[2] + 1 then inPit = true end end
				if not inPit then
					mark(part("Beam", Vector3.new(HW, 0.9, 1.2), Vector3.new(0, HH - 0.45, bz), C(48, 30, 20), Enum.Material.Wood))
				end
				bz += 16
			end
		end
		for _, sx in { -1, 1 } do   -- трубы под потолком
			pipeZ(len, 0.9, Vector3.new(sx * (HW / 2 - 1.3), HH - 1.8, zA + len / 2), jitter(C(86, 58, 44), 0.15))
		end
	end

	-- лампы / кристаллы
	local lz = zA + 10
	while lz < zA + len - 4 do
		local inPit = false
		for _, g in gaps do if lz > zA + g[1] - 2 and lz < zA + g[2] + 2 then inPit = true end end
		if style == "cave" then
			lamp((rng:NextInteger(0, 1) == 0 and -1 or 1) * (HW / 2 - 1.2), rng:NextNumber(2, HH - 3), lz, true)
		elseif not inPit and rng:NextNumber() > 0.15 then
lamp(0, HH - 0.5, lz)
if rng:NextNumber() < 0.3 then sconce((rng:NextInteger(0, 1) == 0) and -1 or 1, HW, lz + 11) end
end
lz += (style == "cave") and 26 or 30
	end

	-- препятствия
	if o.obst then
		local oz = 34
		while oz < len - 24 do
			local ok = true
			for _, g in gaps do if oz > g[1] - 18 and oz < g[2] + 18 then ok = false end end
			if ok then obstacleKinds[rng:NextInteger(1, #obstacleKinds)](zA + oz) end
			oz += 48 + rng:NextInteger(0, 18)
		end
	end
	if o.vent then vent(zA + len / 2) end
		if o.obst and style ~= "cave" and curIdx >= 3 and rng:NextNumber() < 0.2 then safe(wardrobe, HW, zA, len) end
		if o.obst and style ~= "cave" and rng:NextNumber() < 0.3 then safe(lootBox, (rng:NextInteger(0, 1) == 0) and -1 or 1, HW, zA + rng:NextNumber(24, math.max(25, len - 24))) end
		if o.obst and style ~= "cave" and rng:NextNumber() < 0.3 then safe(dresser, (rng:NextInteger(0, 1) == 0) and -1 or 1, HW, zA + rng:NextNumber(20, math.max(21, len - 20))) end
		if o.obst and style ~= "cave" and rng:NextNumber() < 0.35 then safe(windowView, (rng:NextInteger(0, 1) == 0) and -1 or 1, HW, zA + len * rng:NextNumber(0.35, 0.65), 7) end
	if style ~= "cave" and #gaps == 0 then dress(zA, len, HW, 36) end
	safe(ambience, zA, len, HW, HH)
	eyes(zA, len, HW, HH)
	if style == "cave" then
		for _ = 1, 3 do blood(HW, zA + rng:NextNumber(8, len - 8)) end
	end
	-- детальная пещера
	if style == "cave" then safe(caveDress, zA, len) end
	cur += len
end

-- ----- деревянная дверь: E x3 -> трескается, трескается, выламывается -----
local nextDoorLabel: string? = nil   -- особая надпись на двери (?, ??, ???)
local function door(arch: boolean?)
	joint(cur, HW, HH)
	local zA = cur
	local len = 4
	floorTiles(zA, len, HW)
	walls(zA, len, HW, HH, 0)
	part("Ceiling", Vector3.new(HW + 2, 1, len), Vector3.new(0, HH + 0.5, zA + len / 2), C(58, 50, 46))
	local DW, DH = 5.2, 8.4                       -- дверь по росту игрока
	local zMid = zA + len / 2
	local fr, frDark = C(98, 42, 28), C(84, 34, 22)
	for _, sx in { -1, 1 } do
		part("DoorFrame", Vector3.new(0.9, DH, 1.7), Vector3.new(sx * (DW / 2 + 0.45), DH / 2, zMid), fr, Enum.Material.WoodPlanks)
		local fw = HW / 2 - (DW / 2 + 0.9)         -- стена по бокам от двери
		local wc, wm = jitter(BRICKS[1], 0.05), Enum.Material.Fabric
		part("DoorWall", Vector3.new(fw - 0.06, HH - 0.05, len - 0.1), Vector3.new(sx * (DW / 2 + 0.9 + (fw - 0.06) / 2), (HH - 0.05) / 2, zMid), wc, wm)
		part("DoorWainscot", Vector3.new(fw, 4, 0.3), Vector3.new(sx * (DW / 2 + 0.9 + fw / 2), 2, zMid - len / 2 + 0.15), C(54, 36, 26), Enum.Material.WoodPlanks)
	end
	part("DoorWallTop", Vector3.new(DW + 1.8, HH - DH - 0.95, len - 0.1), Vector3.new(0, DH + 0.9 + (HH - DH - 0.95) / 2, zMid), jitter(BRICKS[1], 0.05), Enum.Material.Fabric)
	part("DoorLintel", Vector3.new(DW + 1.8, 0.9, 1.9), Vector3.new(0, DH + 0.45, zMid), fr, Enum.Material.WoodPlanks)
	part("DoorLintelCap", Vector3.new(DW + 2.8, 0.4, 2.3), Vector3.new(0, DH + 1.1, zMid), frDark, Enum.Material.WoodPlanks)
	local zM = zA + len / 2
	local rec = { z = zM, open = false }
	rec.idx = curIdx
	rec.label = nextDoorLabel; nextDoorLabel = nil
	table.insert(curLevel.doors, rec)
	if arch then
		rec.arch = true; rec.open = true
		cur += len
		return
	end
	local lvRef, myO, myParent = curLevel, O, curParent
	local function dpart(name: string, size: Vector3, pos: Vector3, color: Color3, mat: Enum.Material?)
		local pO, pP = O, curParent
		O, curParent = myO, myParent
		noYield = true
		local p = part(name, size, pos, color, mat)
		noYield = false
		O, curParent = pO, pP
		return p
	end
	local live = {}

	local function build()
		for _, p in live do p:Destroy() end
		table.clear(live)
		rec.open = false
		local hits = 0
		local cracks = {}
		local pieces = {}
					local cols = 4
			local pw = DW / cols
			local base = C(122, 52, 32)
			for i = 1, cols do
				local x = -DW / 2 + pw * (i - 0.5)
				local p = dpart("DoorPlank", Vector3.new(pw + 0.02, DH, 0.9), Vector3.new(x, DH / 2, zM), jitter(base, 0.03), Enum.Material.Wood)
				table.insert(pieces, p); table.insert(live, p)
			end
			for _, py in { DH * 0.3, DH * 0.13 } do   -- неглубокие горизонтальные пазы
				local pn = dpart("DoorGroove", Vector3.new(DW * 0.7, 0.14, 0.1), Vector3.new(0, py, zM - 0.46), C(72, 26, 16), Enum.Material.Wood)
				table.insert(pieces, pn); table.insert(live, pn)
			end
			local function oval(name: string, th: number, hgt: number, wid: number, py: number, dz: number, col: Color3, mat: Enum.Material)
				local o = dpart(name, Vector3.new(th, hgt, wid), Vector3.new(0, py, zM + dz), col, mat)
				o.Shape = Enum.PartType.Cylinder
				o.CFrame = CFrame.new(o.Position) * CFrame.Angles(0, math.pi / 2, 0)
				table.insert(pieces, o); table.insert(live, o)
			end
			oval("DoorPlaque", 0.2, 1.7, 3.7, DH * 0.7, -0.55, C(150, 72, 46), Enum.Material.Wood)
			oval("DoorPlaqueIn", 0.26, 1.4, 3.3, DH * 0.7, -0.58, C(124, 52, 33), Enum.Material.Wood)
			do   -- рычажная ручка
				local hx, hy = DW / 2 - 0.85, DH * 0.42
				local rose = dpart("DoorRose", Vector3.new(0.15, 0.6, 0.6), Vector3.new(hx, hy, zM - 0.55), C(150, 76, 50), Enum.Material.Metal)
				rose.Shape = Enum.PartType.Cylinder
				rose.CFrame = CFrame.new(rose.Position) * CFrame.Angles(0, math.pi / 2, 0)
				local stem = dpart("DoorStem", Vector3.new(0.2, 0.2, 0.4), Vector3.new(hx, hy, zM - 0.75), C(150, 76, 50), Enum.Material.Metal)
				local lev = dpart("DoorLever", Vector3.new(1.2, 0.22, 0.22), Vector3.new(hx - 0.45, hy, zM - 0.95), C(156, 80, 52), Enum.Material.Metal)
				for _, q in { rose, stem, lev } do table.insert(pieces, q); table.insert(live, q) end
			end
			do
				local np = dpart("DoorNum", Vector3.new(3.0, 1.3, 0.1), Vector3.new(0, DH * 0.7, zM - 0.73), C(0, 0, 0))
				np.Transparency = 1; np.CanCollide = false
				local sg = Instance.new("SurfaceGui")
				sg.Face = Enum.NormalId.Front; sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; sg.PixelsPerStud = 50
				sg.LightInfluence = 0.15; sg.Parent = np
				local tl = Instance.new("TextLabel")
				tl.Size = UDim2.fromScale(1, 1); tl.BackgroundTransparency = 1; tl.Text = rec.label or string.format("%04d", rec.idx)
				tl.Font = Enum.Font.Antique; tl.TextScaled = true; tl.TextColor3 = C(78, 26, 18)
				local us = Instance.new("UIStroke"); us.Thickness = 1.5; us.Color = C(176, 92, 60); us.Transparency = 0.2; us.Parent = tl
				tl.Parent = sg
				table.insert(pieces, np); table.insert(live, np)
			end
			local hit = dpart("DoorHit", Vector3.new(DW, DH, 1.6), Vector3.new(0, DH / 2, zM), C(0, 0, 0))
		hit.Transparency = 1; hit.CanCollide = false
		table.insert(live, hit)

		local pp = Instance.new("ProximityPrompt")
		pp.ActionText = "Break  (1/3)"; pp.ObjectText = "Door"
		pp.HoldDuration = 0; pp.MaxActivationDistance = 11; pp.RequiresLineOfSight = false
		pp.KeyboardKeyCode = Enum.KeyCode.E; pp.Style = Enum.ProximityPromptStyle.Custom   -- без окошка с «E», клавиша работает
		pp.Style = Enum.ProximityPromptStyle.Custom   -- без окошка с «E», клавиша E работает
		pp.Parent = hit

		local function chips(n: number, power: number)
			for _ = 1, n do
				local c = dpart("Chip", Vector3.new(0.22, 0.22, rng:NextNumber(0.5, 1.5)), Vector3.new(rng:NextNumber(-DW / 2, DW / 2), rng:NextNumber(1, DH - 1), zM - 0.7), C(120, 82, 50), Enum.Material.Wood)
				c.Anchored = false; c.CanCollide = false; c.CanQuery = false
				c.AssemblyLinearVelocity = Vector3.new(rng:NextNumber(-8, 8), rng:NextNumber(3, 10), -rng:NextNumber(4, power))
				c.AssemblyAngularVelocity = Vector3.new(rng:NextNumber(-10, 10), rng:NextNumber(-10, 10), rng:NextNumber(-10, 10))
				Debris:AddItem(c, 2.2)
			end
		end

		local function dustBurst(n: number)
			local dp = dpart("DustBurst", Vector3.new(DW, DH * 0.6, 1), Vector3.new(0, DH * 0.4, zM - 0.8), C(0, 0, 0))
			dp.Transparency = 1; dp.CanCollide = false; dp.CanQuery = false
			local pe = Instance.new("ParticleEmitter")
			pe.Rate = 0; pe.Lifetime = NumberRange.new(1.4, 2.8); pe.Speed = NumberRange.new(6, 20); pe.SpreadAngle = Vector2.new(180, 180)
			pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 3), NumberSequenceKeypoint.new(1, 10) })
			pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1) })
			pe.Color = ColorSequence.new(C(150, 128, 104)); pe.Acceleration = Vector3.new(0, -3, 0); pe.Drag = 2
			pe.RotSpeed = NumberRange.new(-60, 60); pe.LightInfluence = 0.6
			pe.Texture = "rbxasset://textures/particles/smoke_main.dds"; pe.Parent = dp
			pe:Emit(n)
			Debris:AddItem(dp, 5)
		end
		local function flash()
			local fp = dpart("DoorFlash", Vector3.new(1, 1, 1), Vector3.new(0, DH * 0.5, zM - 1.5), C(0, 0, 0))
			fp.Transparency = 1; fp.CanCollide = false; fp.CanQuery = false
			local fl = Instance.new("PointLight")
			fl.Range = 34; fl.Brightness = 3.5; fl.Color = C(255, 214, 160); fl.Parent = fp
			TweenService:Create(fl, TweenInfo.new(0.7), { Brightness = 0 }):Play()
			Debris:AddItem(fp, 1.5)
		end
		local function shake(a: number)
			for pl in lvRef.players do
				if pl.Parent then world:FireClient(pl, "Shake", a) end
			end
		end

		local lastHit = 0
		local function onHit()
			if rec.open then return end
			if os.clock() - lastHit < 0.4 then return end
			lastHit = os.clock()
			hits += 1
			if hits < 3 then
				pp.ActionText = string.format("Break  (%d/3)", hits + 1)
				pp.Enabled = false
				task.delay(0.35, function() if pp.Parent then pp.Enabled = true end end)
				-- удар: дверь вздрагивает, летят щепки, появляются трещины, дерево темнеет
				for _, p in pieces do
					TweenService:Create(p, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true), { Position = p.Position + Vector3.new(rng:NextNumber(-0.25, 0.25), rng:NextNumber(-0.1, 0.1), rng:NextNumber(0.1, 0.35)) }):Play()
					if p.Name == "DoorPlank" then p.Color = p.Color:Lerp(C(30, 18, 10), 0.22) end
				end
				for k = 1, 1 + hits do   -- повреждения: рваные трещины с светлой кромкой, пробоины, торчащие щепки
					local cx, cy = rng:NextNumber(-DW / 2 + 0.9, DW / 2 - 0.9), rng:NextNumber(2.0, DH - 2.0)
					local px, py = cx, cy
					for j = 1, 5 + hits do
						local r = rng:NextNumber(-0.7, 0.7)
						local L = rng:NextNumber(0.45, 0.95)
						local mx, my = px - math.sin(r) * L / 2, py + math.cos(r) * L / 2
						local edge = mark(dpart("Crack", Vector3.new(0.24, L, 0.03), Vector3.new(mx, my, zM - 0.47), C(196, 146, 94), Enum.Material.Wood))
						edge.CFrame = edge.CFrame * CFrame.Angles(0, 0, r)
						local dk = mark(dpart("Crack", Vector3.new(0.08, L, 0.04), Vector3.new(mx, my, zM - 0.485), C(8, 5, 3), Enum.Material.SmoothPlastic))
						dk.CFrame = dk.CFrame * CFrame.Angles(0, 0, r)
						table.insert(cracks, edge); table.insert(live, edge)
						table.insert(cracks, dk); table.insert(live, dk)
						px, py = px - math.sin(r) * L, py + math.cos(r) * L
					end
					-- пробоина: тёмная дыра, за ней тёплый свет
					local hw, hh = rng:NextNumber(0.35, 0.7) * (0.8 + hits * 0.4), rng:NextNumber(0.6, 1.1) * (0.8 + hits * 0.4)
					local glow = mark(dpart("Crack", Vector3.new(hw + 0.16, hh + 0.16, 0.03), Vector3.new(cx, cy, zM - 0.47), C(255, 150, 70), Enum.Material.Neon))
					glow.Transparency = 0.35
					local hole = mark(dpart("Crack", Vector3.new(hw, hh, 0.05), Vector3.new(cx, cy, zM - 0.49), C(6, 4, 3), Enum.Material.SmoothPlastic))
					local rz = rng:NextNumber(-0.5, 0.5)
					glow.CFrame = glow.CFrame * CFrame.Angles(0, 0, rz); hole.CFrame = hole.CFrame * CFrame.Angles(0, 0, rz)
					table.insert(cracks, glow); table.insert(live, glow)
					table.insert(cracks, hole); table.insert(live, hole)
					-- торчащие щепки вокруг пробоины
					for _ = 1, 5 + hits * 2 do
						local a = rng:NextNumber(0, math.pi * 2)
						local sp = mark(dpart("Crack", Vector3.new(0.09, 0.09, rng:NextNumber(0.45, 1.3)), Vector3.new(cx + math.cos(a) * hw * 0.55, cy + math.sin(a) * hh * 0.55, zM - 0.75), C(170, 122, 72), Enum.Material.Wood))
						sp.CFrame = sp.CFrame * CFrame.Angles(rng:NextNumber(-0.7, 0.7), rng:NextNumber(-0.7, 0.7), a)
						table.insert(cracks, sp); table.insert(live, sp)
					end
				end
				chips(6 + hits * 3, 16)
				dustBurst(10 + hits * 8)
				shake(0.35 + hits * 0.25)
			else
				-- ВЫЛОМАНА
					rec.open = true
					do   -- звук выламывания (слышат все рядом)
						local sp = dpart("DoorSnd", Vector3.new(1, 1, 1), Vector3.new(0, 6, zM), C(0, 0, 0))
						sp.Transparency = 1; sp.CanCollide = false; sp.CanQuery = false
						local snd = Instance.new("Sound")
						snd.SoundId = CONFIG.DoorBreakSoundId; snd.Volume = 1.4; snd.RollOffMaxDistance = 160
						snd.Parent = sp; snd:Play()
						Debris:AddItem(sp, 6)
					end
					onDoorBroken(lvRef, rec)
					pp:Destroy(); hit:Destroy()
					for _, cr in cracks do cr:Destroy() end
					shake(1.6)
					task.spawn(function()
						-- 1) дверь прогибается под ударом
						for _, p in pieces do
							if p.Parent then
								local bulge = 0.25 + 1.3 * math.max(0, 1 - math.abs(p.Position.X - myO.X) / (DW / 2))
								TweenService:Create(p, TweenInfo.new(0.17, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = p.Position + Vector3.new(0, 0, bulge) }):Play()
							end
						end
						task.wait(0.17)
						-- 2) хруст: каждая доска ломается пополам, обломки летят
						dustBurst(80); flash(); chips(26, 34)
						local flying = {}
						local function launch(p: BasePart, vel: Vector3, ang: Vector3)
							p.Anchored = false
							p.AssemblyLinearVelocity = vel
							p.AssemblyAngularVelocity = ang
							table.insert(flying, p)
						end
						for _, p in pieces do
							if p.Parent then
								local lp = p.Position - myO
								local xd = lp.X / (DW / 2)
								if p.Name == "DoorPlank" then
									local col = p.Color
									local split = rng:NextNumber(0.3, 0.7) * DH
									p:Destroy()
									local lo = dpart("DoorPlank", Vector3.new(pw + 0.02, split, 0.9), Vector3.new(lp.X, split / 2, lp.Z), col, Enum.Material.Wood)
									local hi = dpart("DoorPlank", Vector3.new(pw + 0.02, DH - split, 0.9), Vector3.new(lp.X, split + (DH - split) / 2, lp.Z), col, Enum.Material.Wood)
									lo.CFrame = lo.CFrame * CFrame.Angles(0, 0, rng:NextNumber(-0.05, 0.05))
									hi.CFrame = hi.CFrame * CFrame.Angles(rng:NextNumber(-0.06, 0.06), 0, rng:NextNumber(-0.14, 0.14))
									table.insert(live, lo); table.insert(live, hi)
									launch(lo, Vector3.new(xd * 5 + rng:NextNumber(-2, 2), rng:NextNumber(1, 5), rng:NextNumber(9, 17)), Vector3.new(rng:NextNumber(-3, 3), rng:NextNumber(-2, 2), rng:NextNumber(-3, 3)))
									launch(hi, Vector3.new(xd * 9 + rng:NextNumber(-3, 3), rng:NextNumber(7, 15), rng:NextNumber(18, 32)), Vector3.new(rng:NextNumber(-7, 7), rng:NextNumber(-5, 5), rng:NextNumber(-7, 7)))
								else
									launch(p, Vector3.new(xd * 8 + rng:NextNumber(-3, 3), rng:NextNumber(5, 12), rng:NextNumber(16, 28)), Vector3.new(rng:NextNumber(-6, 6), rng:NextNumber(-6, 6), rng:NextNumber(-6, 6)))
								end
							end
						end
						-- ===== мощное продолжение: ударная волна, искры, глыбы, дым, повторный толчок =====
						do
							local ring = dpart("DoorRing", Vector3.new(0.3, 5, 5), Vector3.new(0, DH / 2, zM), C(255, 214, 150), Enum.Material.Neon)
							ring.Shape = Enum.PartType.Cylinder
							ring.CFrame = ring.CFrame * CFrame.Angles(0, math.pi / 2, 0)
							ring.CanCollide = false; ring.CanQuery = false; ring.Transparency = 0.2
							TweenService:Create(ring, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.new(0.3, 46, 46), Transparency = 1 }):Play()
							Debris:AddItem(ring, 0.7)
							local ring2 = dpart("DoorRing", Vector3.new(0.3, 3, 3), Vector3.new(0, DH / 2, zM), C(255, 120, 60), Enum.Material.Neon)
							ring2.Shape = Enum.PartType.Cylinder
							ring2.CFrame = ring2.CFrame * CFrame.Angles(0, math.pi / 2, 0)
							ring2.CanCollide = false; ring2.CanQuery = false; ring2.Transparency = 0.4
							TweenService:Create(ring2, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.new(0.3, 30, 30), Transparency = 1 }):Play()
							Debris:AddItem(ring2, 1)
						end
						do   -- облако пыли и щепок
							local dp = dpart("DoorDust", Vector3.new(DW, DH * 0.8, 1), Vector3.new(0, DH / 2, zM), C(0, 0, 0))
							dp.Transparency = 1; dp.CanCollide = false; dp.CanQuery = false
							local em = Instance.new("ParticleEmitter")
							em.Texture = "rbxasset://textures/particles/smoke_main.dng"
							em.Color = ColorSequence.new(C(150, 124, 96), C(70, 58, 46))
							em.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 3), NumberSequenceKeypoint.new(1, 14) })
							em.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 1) })
							em.Lifetime = NumberRange.new(1.6, 3.0)
							em.Speed = NumberRange.new(14, 34)
							em.SpreadAngle = Vector2.new(70, 70)
							em.Rotation = NumberRange.new(0, 360); em.RotSpeed = NumberRange.new(-60, 60)
							em.Drag = 2; em.Rate = 0; em.EmissionDirection = Enum.NormalId.Front
							em.Parent = dp
							em:Emit(70)
							Debris:AddItem(dp, 4)
						end
						for _ = 1, 14 do   -- тяжёлые глыбы
							local sz = rng:NextNumber(0.5, 1.3)
							local ch = dpart("DoorChunk", Vector3.new(sz, sz * rng:NextNumber(0.6, 1.4), sz), Vector3.new(rng:NextNumber(-DW / 2, DW / 2), rng:NextNumber(1, DH - 1), zM), jitter(C(110, 70, 40), 0.2), Enum.Material.Wood)
							ch.CFrame = ch.CFrame * CFrame.Angles(rng:NextNumber(0, 6), rng:NextNumber(0, 6), rng:NextNumber(0, 6))
							ch.CanQuery = false
							table.insert(live, ch)
							launch(ch, Vector3.new(rng:NextNumber(-16, 16), rng:NextNumber(6, 20), rng:NextNumber(14, 44)), Vector3.new(rng:NextNumber(-10, 10), rng:NextNumber(-10, 10), rng:NextNumber(-10, 10)))
						end
						for _ = 1, 36 do   -- раскалённые искры
							local sk = dpart("DoorSpark", Vector3.new(0.12, 0.12, rng:NextNumber(0.25, 0.6)), Vector3.new(rng:NextNumber(-DW / 2, DW / 2), rng:NextNumber(0.5, DH), zM), (rng:NextNumber() < 0.5) and C(255, 200, 90) or C(255, 110, 40), Enum.Material.Neon)
							sk.CanCollide = false; sk.CanQuery = false
							sk.CFrame = CFrame.lookAt(sk.Position, sk.Position + Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(0, 1), rng:NextNumber(0.5, 2)))
							table.insert(live, sk)
							launch(sk, Vector3.new(rng:NextNumber(-22, 22), rng:NextNumber(4, 24), rng:NextNumber(10, 50)), Vector3.new(rng:NextNumber(-8, 8), rng:NextNumber(-8, 8), rng:NextNumber(-8, 8)))
						end
						do   -- светящиеся угли, лучи света и вспышка-фонарь
							local ep = dpart("DoorEmbers", Vector3.new(DW, DH * 0.7, 1), Vector3.new(0, DH / 2, zM), C(0, 0, 0))
							ep.Transparency = 1; ep.CanCollide = false; ep.CanQuery = false
							local em = Instance.new("ParticleEmitter")
							em.Texture = "rbxasset://textures/particles/sparkles_main.dds"
							em.Color = ColorSequence.new(C(255, 220, 130), C(255, 90, 30))
							em.LightEmission = 1
							em.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) })
							em.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
							em.Lifetime = NumberRange.new(1.2, 2.6)
							em.Speed = NumberRange.new(6, 26)
							em.SpreadAngle = Vector2.new(90, 90)
							em.Acceleration = Vector3.new(0, 6, 0)
							em.Rate = 0; em.EmissionDirection = Enum.NormalId.Front
							em.Parent = ep
							em:Emit(90)
							Debris:AddItem(ep, 4)
							local fl = Instance.new("PointLight")
							fl.Range = 60; fl.Brightness = 8; fl.Color = C(255, 190, 120); fl.Shadows = true; fl.Parent = ep
							TweenService:Create(fl, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Brightness = 0, Range = 20 }):Play()
							for k = 1, 5 do   -- лучи света сквозь проём
								local beam = dpart("DoorBeam", Vector3.new(0.5 + k * 0.15, 0.2, 22), Vector3.new((k - 3) * 1.6, DH * 0.55 + (k % 2) * 1.5, zM + 8), C(255, 220, 170), Enum.Material.Neon)
								beam.CanCollide = false; beam.CanQuery = false; beam.Transparency = 0.82
								beam.CFrame = beam.CFrame * CFrame.Angles(0, (k - 3) * 0.05, 0)
								TweenService:Create(beam, TweenInfo.new(1.1, Enum.EasingStyle.Sine), { Transparency = 1 }):Play()
								Debris:AddItem(beam, 1.3)
							end
						end
						task.delay(0.35, function() shake(0.8) end)   -- повторный толчок
						task.delay(0.7, function() shake(0.35) end)
						for _ = 1, 16 do   -- плоские осколки
							local sh = dpart("Shard", Vector3.new(rng:NextNumber(0.5, 1.4), rng:NextNumber(1.2, 3.4), 0.18), Vector3.new(rng:NextNumber(-DW / 2, DW / 2), rng:NextNumber(1.5, DH - 1.5), zM), jitter(C(118, 80, 46), 0.15), Enum.Material.Wood)
							sh.CFrame = sh.CFrame * CFrame.Angles(rng:NextNumber(-1.2, 1.2), rng:NextNumber(-1.2, 1.2), rng:NextNumber(-1.2, 1.2))
							sh.CanCollide = false; sh.CanQuery = false
							table.insert(live, sh)
							launch(sh, Vector3.new(rng:NextNumber(-12, 12), rng:NextNumber(3, 16), rng:NextNumber(10, 34)), Vector3.new(rng:NextNumber(-12, 12), rng:NextNumber(-12, 12), rng:NextNumber(-12, 12)))
						end
						for _ = 1, 40 do   -- длинные щепки
							local sp = dpart("Splinter", Vector3.new(0.16, 0.16, rng:NextNumber(1.2, 4)), Vector3.new(rng:NextNumber(-DW / 2, DW / 2), rng:NextNumber(1, DH - 1), zM), C(124, 86, 52), Enum.Material.Wood)
							sp.CFrame = sp.CFrame * CFrame.Angles(rng:NextNumber(-1, 1), rng:NextNumber(-1, 1), rng:NextNumber(-1, 1))
							sp.CanCollide = false; sp.CanQuery = false
							table.insert(live, sp)
							launch(sp, Vector3.new(rng:NextNumber(-14, 14), rng:NextNumber(4, 18), rng:NextNumber(8, 38)), Vector3.new(rng:NextNumber(-16, 16), rng:NextNumber(-16, 16), rng:NextNumber(-16, 16)))
						end
						-- остаются рваные зубья досок
						for i = 1, cols do
							local sh = rng:NextNumber(0.3, 1.3)
							local x = -DW / 2 + pw * (i - 0.5)
							local stub = mark(dpart("DoorStub", Vector3.new(pw - 0.1, sh, 0.5), Vector3.new(x, sh / 2, zM + rng:NextNumber(-0.2, 0.2)), C(70, 46, 28), Enum.Material.Wood))
							stub.CFrame = stub.CFrame * CFrame.Angles(0, rng:NextNumber(-0.2, 0.2), rng:NextNumber(-0.15, 0.15))
							table.insert(live, stub)
						end
						task.delay(1.2, function() for _, p in flying do if p.Parent then p.CanCollide = false end end end)
						task.delay(2.4, function()
							for _, p in flying do
								if p.Parent then
									local g = p:FindFirstChildOfClass("SurfaceGui")
									if g then g.Enabled = false end
									TweenService:Create(p, TweenInfo.new(1.2), { Transparency = 1 }):Play()
								end
							end
						end)
						for _, p in flying do Debris:AddItem(p, 4) end
					end)
				end
			end
		pp.Triggered:Connect(onHit)
		local cd = Instance.new("ClickDetector")   -- можно и просто кликнуть по двери
		cd.MaxActivationDistance = 16
		cd.Parent = hit
		cd.MouseClick:Connect(onHit)
	end
	rec.reset = build
	build()
	cur += len
end

-- ----- комната: перегородки с проёмами, колонны, ящики, лампы -----
local function sideHall(sx: number, zc: number, gl: number)   -- отдельная комната-кладовая за проёмом: сундук, комод, шкаф (иногда с тайной комнатой)
	local x0 = sx * (RW / 2 + 1)
	local D, H, Wc = 26, 11, 24
	local xc = x0 + sx * D / 2
	local xe = x0 + sx * D                      -- внутренняя плоскость дальней стены
	local wEnd = 2 * (math.abs(xe) - 0.5)       -- «ширина» для мебели, стоящей у дальней стены
	local floorC = C(46, 33, 26)
	part("SideFloor", Vector3.new(D, 1, Wc), Vector3.new(xc, -0.5, zc), floorC, Enum.Material.WoodPlanks)
	part("SideRug", Vector3.new(D - 8, 0.12, 8), Vector3.new(xc, 0.06, zc), C(92, 18, 24), Enum.Material.Fabric)
	part("SideCeil", Vector3.new(D, 1, Wc), Vector3.new(xc, H + 0.5, zc), C(38, 28, 24), Enum.Material.Wood)
	local secret = rng:NextNumber() < 0.3   -- пасхалка: за стеной тайная комната
	local dzs = (rng:NextInteger(0, 1) == 0) and -1 or 1
	local hx = xc + sx * 4
	for _, dz in { -1, 1 } do
		local c, m = wallStyle()
		local wz = zc + dz * (Wc / 2 + 0.5)
		if secret and dz == dzs then   -- стена с проёмом 7 шириной под потайную дверь
			local xa, xb = xc - D / 2, hx - 3.5
			local xa2, xb2 = hx + 3.5, xc + D / 2
			if xb < xa then xa, xb = hx + 3.5, xc + D / 2; xa2, xb2 = xc - D / 2, hx - 3.5 end
			part("SideWall", Vector3.new(xb - xa, H, 1), Vector3.new((xa + xb) / 2, H / 2, wz), c, m)
			part("SideWall", Vector3.new(xb2 - xa2, H, 1), Vector3.new((xa2 + xb2) / 2, H / 2, wz), c, m)
			part("SideWallTop", Vector3.new(7, H - 9, 1), Vector3.new(hx, 9 + (H - 9) / 2, wz), c, m)
		else
			part("SideWall", Vector3.new(D, H, 1), Vector3.new(xc, H / 2, wz), c, m)
			part("SideWainscot", Vector3.new(D - 0.4, 3.6, 0.4), Vector3.new(xc, 1.8, zc + dz * (Wc / 2 - 0.2)), C(54, 36, 26), Enum.Material.WoodPlanks)
		end
	end
	local ec, em = wallStyle()
	part("SideEnd", Vector3.new(1, H, Wc + 2), Vector3.new(xe + sx * 0.5, H / 2, zc), ec, em)
	-- свет: одна лампа + свечи на комоде
	safe(lamp, xc, H - 0.6, zc)
	-- мебель: у дальней стены
	safe(lootBox, sx, wEnd, zc - 6)
	safe(dresser, sx, wEnd, zc + 6)
	if curIdx >= 3 then safe(wardrobe, wEnd, zc - 40, 100, sx, zc + 0) end
	local cd = part("SideCandle", Vector3.new(0.4, 1, 0.4), Vector3.new(xe - sx * 2.5, 5.6, zc + 6), C(230, 220, 190), Enum.Material.SmoothPlastic)
	local cl = Instance.new("PointLight"); cl.Color = C(255, 170, 80); cl.Range = 16; cl.Brightness = 1.1; cl.Shadows = false; cl.Parent = cd
	table.insert(lamps, { part = cd, light = cl, base = 1.1, seed = rng:NextNumber(0, 100), bad = true })
	if secret then
		-- ПАСХАЛКА: потайная дверь в боковой стене кладовой -> комната с сердцем из мела и надписью "Love Doors"
		local zs = zc + dzs * (Wc / 2 + 0.5)
		local pc, pm = wallStyle()
		local panel = part("SecretPanel", Vector3.new(7, 9, 1), Vector3.new(hx, 4.5, zs), pc, pm)
		local R = 18   -- комната: за боковой стеной
		local zr = zs + dzs * (R / 2 + 0.6)
		part("LoveFloor", Vector3.new(16, 1, R), Vector3.new(xc + sx * 4, -0.5, zr), C(30, 22, 22), Enum.Material.WoodPlanks)
		part("LoveCeil", Vector3.new(16, 1, R), Vector3.new(xc + sx * 4, 9.5, zr), C(26, 20, 20), Enum.Material.Wood)
		for _, dx in { -1, 1 } do part("LoveWall", Vector3.new(1, 9, R), Vector3.new(xc + sx * 4 + dx * 8.5, 4.5, zr), C(28, 24, 26), Enum.Material.Concrete) end
		local back = part("LoveBack", Vector3.new(18, 9, 1), Vector3.new(xc + sx * 4, 4.5, zs + dzs * (R + 1.1)), C(20, 18, 20), Enum.Material.Slate)
		local sg = Instance.new("SurfaceGui"); sg.Face = (dzs == 1) and Enum.NormalId.Front or Enum.NormalId.Back; sg.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize; sg.CanvasSize = Vector2.new(900, 500); sg.LightInfluence = 0.4; sg.Parent = back
		local heart = Instance.new("TextLabel"); heart.BackgroundTransparency = 1; heart.Size = UDim2.fromScale(1, 0.62); heart.Font = Enum.Font.SourceSansBold; heart.TextScaled = true
		heart.Text = "♥"; heart.TextColor3 = Color3.fromRGB(240, 238, 232); heart.TextTransparency = 0.12; heart.Parent = sg
		local words = Instance.new("TextLabel"); words.BackgroundTransparency = 1; words.Position = UDim2.fromScale(0, 0.6); words.Size = UDim2.fromScale(1, 0.34)
		words.Font = Enum.Font.PatrickHand; words.TextScaled = true; words.Text = "Love Doors"; words.TextColor3 = Color3.fromRGB(240, 238, 232); words.TextTransparency = 0.1; words.Parent = sg
		local cdl = part("LoveCandle", Vector3.new(0.5, 1.2, 0.5), Vector3.new(xc + sx * 4, 0.6, zs + dzs * (R - 2)), C(240, 225, 220), Enum.Material.SmoothPlastic)
		local pl = Instance.new("PointLight"); pl.Color = C(255, 150, 170); pl.Range = 22; pl.Brightness = 1.6; pl.Shadows = false; pl.Parent = cdl
		table.insert(lamps, { part = cdl, light = pl, base = 1.6, seed = rng:NextNumber(0, 100), bad = true })
		local pp = Instance.new("ProximityPrompt"); pp.ActionText = "Push"; pp.ObjectText = "Wall"; pp.HoldDuration = 0.6; pp.MaxActivationDistance = 8
		pp.RequiresLineOfSight = false; pp.KeyboardKeyCode = Enum.KeyCode.E; pp.Parent = panel
		pp.Triggered:Connect(function(plr)
			pp:Destroy()
			panel.CanCollide = false
			TweenService:Create(panel, TweenInfo.new(1.2), { Transparency = 1 }):Play()
			world:FireClient(plr, "LootNote", "<3  Love Doors")
		end)
	end
end

-- декор отеля: кустарник в горшке, тележка с чемоданами, настенные часы
local function topiary(sx: number, w: number, z: number)
	local x = sx * (w / 2 - 2.4)
	local pot = part("TopiaryPot", Vector3.new(2.4, 1.8, 2.4), Vector3.new(x, 0.9, z), C(150, 40, 36), Enum.Material.SmoothPlastic)
	pot.CanCollide = true
	part("TopiaryDirt", Vector3.new(2.0, 0.2, 2.0), Vector3.new(x, 1.85, z), C(58, 40, 28), Enum.Material.Ground).CanCollide = false
	part("TopiaryTrunk", Vector3.new(0.3, 1.4, 0.3), Vector3.new(x, 2.5, z), C(70, 48, 30), Enum.Material.Wood).CanCollide = false
	for i, d in { 2.4, 2.0, 1.5, 1.0 } do
		local b = mark(part("TopiaryLeaf", Vector3.new(d, 1.5, d), Vector3.new(x, 2.8 + i * 1.05, z), jitter(C(52, 82, 36), 0.12), Enum.Material.LeafyGrass))
		b.Shape = Enum.PartType.Ball
		b.CanCollide = false
	end
end
local function luggageCart(sx: number, w: number, z: number)
	local x = sx * (w / 2 - 3.2)
	local brass = C(112, 82, 40)
	part("CartBase", Vector3.new(3.4, 0.3, 5.2), Vector3.new(x, 1.1, z), C(120, 80, 50), Enum.Material.Wood)
	for _, dx in { -1.6, 1.6 } do
		for _, dz in { -2.4, 2.4 } do
			part("CartPost", Vector3.new(0.22, 5.4, 0.22), Vector3.new(x + dx, 3.5, z + dz), brass, Enum.Material.Metal).CanCollide = false
			local wh = part("CartWheel", Vector3.new(0.7, 0.7, 0.7), Vector3.new(x + dx, 0.35, z + dz), C(30, 28, 28), Enum.Material.Metal)
			wh.Shape = Enum.PartType.Ball; wh.CanCollide = false
		end
		part("CartRail", Vector3.new(0.22, 0.22, 5.0), Vector3.new(x + dx, 6.2, z), brass, Enum.Material.Metal).CanCollide = false
	end
	part("CartTop", Vector3.new(3.4, 0.22, 0.22), Vector3.new(x, 6.2, z - 2.4), brass, Enum.Material.Metal).CanCollide = false
	for i = 1, rng:NextInteger(2, 4) do
		local sz = Vector3.new(rng:NextNumber(2.0, 2.8), rng:NextNumber(1.1, 1.6), rng:NextNumber(1.6, 2.2))
		local cz = z + rng:NextNumber(-1.2, 1.2)
		local c = part("Suitcase", sz, Vector3.new(x + rng:NextNumber(-0.3, 0.3), 1.25 + sz.Y / 2 + (i - 1) * 1.45, cz), jitter(C(176, 132, 84), 0.1), Enum.Material.Fabric)
		c.CanCollide = false
		part("SuitcaseStrap", Vector3.new(sz.X + 0.05, sz.Y + 0.05, 0.18), c.Position - O + Vector3.new(0, 0, 0), C(80, 52, 30), Enum.Material.Fabric).CanCollide = false
	end
end
local function wallClock(sx: number, w: number, z: number)
	local x = sx * (w / 2 - 0.25)
	local face = part("ClockFace", Vector3.new(0.3, 2.8, 2.8), Vector3.new(x, 9.5, z), C(238, 226, 196), Enum.Material.SmoothPlastic)
	face.Shape = Enum.PartType.Cylinder; face.CanCollide = false
	local rim = part("ClockRim", Vector3.new(0.45, 3.2, 3.2), Vector3.new(sx * (w / 2 - 0.15), 9.5, z), C(120, 82, 40), Enum.Material.Metal)
	rim.Shape = Enum.PartType.Cylinder; rim.CanCollide = false
	local ix = sx * (w / 2 - 0.5)
	part("ClockHourHand", Vector3.new(0.1, 0.9, 0.16), Vector3.new(ix, 9.95, z), C(30, 20, 18), Enum.Material.SmoothPlastic).CanCollide = false
	part("ClockMinuteHand", Vector3.new(0.1, 0.16, 1.15), Vector3.new(ix, 9.5, z + 0.55), C(30, 20, 18), Enum.Material.SmoothPlastic).CanCollide = false
end

local function room(len: number, o)
	o = o or {}
	joint(cur, RW, RH)
	local zA = cur
	floorTiles(zA, len, RW)
	local sgSide, sgZ
	if len >= 70 and curIdx >= 3 and rng:NextNumber() < 0.45 then
		sgSide = (rng:NextInteger(0, 1) == 0) and -1 or 1
		sgZ = zA + rng:NextNumber(len * 0.3, len * 0.6)
		sideGap = { sx = sgSide, z0 = sgZ - 5, z1 = sgZ + 5 }
	end
	walls(zA, len, RW, RH, 0)
	safe(vault, zA, len)
	wainscot(zA, len, RW)
	if sgSide then
		sideGap = nil
		safe(sideHall, sgSide, sgZ, 10)
	end
	dress(zA, len, RW, 26)
		if curIdx >= 3 and rng:NextNumber() < 0.16 then safe(wardrobe, RW, zA, len) end
		local fz = zA + 14   -- мебель
		while fz < zA + len - 14 do
			local sxf = (rng:NextInteger(0, 1) == 0) and -1 or 1
			local rr = rng:NextNumber()
			if rr < 0.22 then safe(bookshelf, sxf, RW, fz)
			elseif rr < 0.42 then safe(armchair, sxf, RW, fz)
			elseif rr < 0.66 then safe(dresser, sxf, RW, fz)
			elseif rr < 0.78 then safe(topiary, -1, RW, fz); safe(topiary, 1, RW, fz)
			elseif rr < 0.88 then safe(luggageCart, sxf, RW, fz)
			elseif rr < 0.96 then safe(wallClock, sxf, RW, fz) end
			fz += rng:NextNumber(20, 32)
		end
		local cz = zA + 16   -- люстры
		while cz < zA + len - 8 do
			safe(chandelier, 0, cz)
			cz += 34
		end
		local wz = zA + 12   -- окна с дождём
		while wz < zA + len - 10 do
			if rng:NextNumber() < 0.5 then safe(windowView, (rng:NextInteger(0, 1) == 0) and -1 or 1, RW, wz, 11) end
			wz += rng:NextNumber(26, 38)
		end
		if rng:NextNumber() < 0.65 then safe(lootBox, (rng:NextInteger(0, 1) == 0) and -1 or 1, RW, zA + rng:NextNumber(12, len - 12)) end
		if curIdx >= 6 and rng:NextNumber() < 0.14 then safe(eyesEntity, zA) end
	safe(ambience, zA, len, RW, RH)
	eyes(zA, len, RW, RH)
	ribs(zA, len, RW, RH, {})
	-- лампы
	local lz = zA + 8
	while lz < zA + len - 3 do
		for _, x in { -20, -7, 7, 20 } do
			if rng:NextNumber() > 0.2 then lamp(x, vaultIn(x) - 0.35, lz) end
		end
		lz += 24
	end
	-- перегородки (комнаты в комнате) с проёмом
	local pz = zA + 32
	while false and pz < zA + len - 30 do
		local gapX = rng:NextNumber(-14, 14)
			local gapW = 16
		local lw = (gapX - gapW / 2) - (-RW / 2)
		local rw = (RW / 2) - (gapX + gapW / 2)
		local c1, m1 = wallStyle()
		part("Partition", Vector3.new(lw, RH, 2), Vector3.new(-RW / 2 + lw / 2, RH / 2, pz), c1, m1)
		part("Partition", Vector3.new(rw, RH, 2), Vector3.new(RW / 2 - rw / 2, RH / 2, pz), c1, m1)
		part("PartitionTop", Vector3.new(gapW, RH - 9, 2), Vector3.new(gapX, 9 + (RH - 9) / 2, pz), c1, m1)
		pz += rng:NextNumber(34, 46)
	end
	-- колонны и ящики
	local oz = zA + 10
	while oz < zA + len - 10 do
		if rng:NextNumber() > 0.45 then
			safe(column, rng:NextNumber(-24, 24), oz + rng:NextNumber(-3, 3))
		else
			for _ = 1, 2 do
				local c = part("Crate", Vector3.new(4, 4, 4), Vector3.new(rng:NextNumber(-26, 26), 2, oz + rng:NextNumber(-4, 4)), C(92, 66, 40), Enum.Material.Wood)
				c.CFrame = c.CFrame * CFrame.Angles(0, rng:NextNumber(0, 1.5), 0)
			end
		end
		oz += 30
	end
	cur += len
end

-- ----- платформы над пропастью (надо прыгать с камня на камень) -----
local function stones(n: number)
	joint(cur, RW, RH)
	local zA = cur
	local len = 28 + 16 * n
	walls(zA, len, RW, RH, -PIT)
	part("PitBottom", Vector3.new(RW, 1, len), Vector3.new(0, -PIT - 0.5, zA + len / 2), C(10, 8, 8), Enum.Material.Slate)
	part("Ceiling", Vector3.new(RW + 2, 1, len), Vector3.new(0, RH + 0.5, zA + len / 2), C(52, 46, 42))
	part("StartPad", Vector3.new(RW, 1, 10), Vector3.new(0, -0.5, zA + 5), C(80, 72, 66), Enum.Material.Concrete)
	part("EndPad", Vector3.new(RW, 1, 10), Vector3.new(0, -0.5, zA + len - 5), C(80, 72, 66), Enum.Material.Concrete)
	local x = 0
	for i = 1, n do
		x = math.clamp(x + rng:NextNumber(-4, 4), -9, 9)
		local st = part("Stone", Vector3.new(8, 2, 8), Vector3.new(x, -1, zA + 18 + (i - 1) * 16 + 4), jitter(C(96, 88, 80), 0.1), Enum.Material.Cobblestone)
		part("StoneRim", Vector3.new(8.4, 0.3, 8.4), Vector3.new(x, 0.1, zA + 18 + (i - 1) * 16 + 4), C(200, 150, 60), Enum.Material.Neon).CanCollide = false
	end
	eyes(zA, len, RW, RH)
	local lz = zA + 6
	while lz < zA + len - 3 do
		for _, lx in { -14, 14 } do lamp(lx, RH - 0.5, lz) end
		lz += 18
	end
	cur += len
end

-- ----- финальная комната с выходом -----
local function finalRoom(len: number)
	room(len)
	local zE = cur
	part("EndWall", Vector3.new(RW + 2, RH + 2, 2), Vector3.new(0, RH / 2, zE + 1), C(40, 34, 30), Enum.Material.Fabric)
	local ex = part("ExitLight", Vector3.new(14, 11, 0.6), Vector3.new(0, 5.5, zE - 0.4), C(255, 232, 170), Enum.Material.Neon)
	ex.CanCollide = false
	local dl = Instance.new("PointLight")
	dl.Range = 60; dl.Brightness = 2.6; dl.Color = C(255, 220, 150); dl.Parent = ex
	finishZ = zE - 12
end

-- Room 666 - The Owner: огромный зал с адским троном EvaK (самого EvaK там нет)
local function throneRoom(len: number): (number, number)
	joint(cur, RW, RH)
	local zA = cur
	local W, H = RW, RH
	local BLOOD, DARK = C(120, 10, 18), C(18, 12, 14)
	part("ThroneFloor", Vector3.new(W, 1, len), Vector3.new(0, -0.5, zA + len / 2), C(16, 12, 14), Enum.Material.Marble)
	part("ThroneCarpet", Vector3.new(12, 0.12, len - 4), Vector3.new(0, 0.06, zA + len / 2 - 2), BLOOD, Enum.Material.Fabric)
	for _, sx in { -1, 1 } do
		part("ThroneWall", Vector3.new(1, H + 2, len), Vector3.new(sx * (W / 2 + 0.5), H / 2, zA + len / 2), DARK, Enum.Material.Concrete)
		local cz = zA + 8
		while cz < zA + len - 6 do
			part("ThroneCurtain", Vector3.new(0.6, H - 3, 6), Vector3.new(sx * (W / 2 - 0.6), H / 2 - 0.5, cz), jitter(BLOOD, 0.08), Enum.Material.Fabric)
			local col = part("ThroneColumn", Vector3.new(H, 2.2, 2.2), Vector3.new(sx * 16, H / 2, cz + 7), C(26, 20, 22), Enum.Material.Marble)
			col.Shape = Enum.PartType.Cylinder; col.CFrame = CFrame.new(col.Position) * CFrame.Angles(0, 0, math.pi / 2)
			part("ThroneCandle", Vector3.new(0.5, 1.2, 0.5), Vector3.new(sx * 14.5, 4, cz + 7), C(230, 220, 200), Enum.Material.SmoothPlastic)
			local fl = part("ThroneFlame", Vector3.new(0.35, 0.6, 0.35), Vector3.new(sx * 14.5, 5.1, cz + 7), C(255, 50, 30), Enum.Material.Neon)
			fl.CanCollide = false
			local pl = Instance.new("PointLight"); pl.Range = 26; pl.Brightness = 1.4; pl.Color = C(255, 60, 40); pl.Parent = fl
			table.insert(lamps, { part = fl, light = pl, base = 1.4, seed = rng:NextNumber(0, 100), bad = false })
			cz += 14
		end
	end
	part("ThroneCeiling", Vector3.new(W + 2, 1, len), Vector3.new(0, H + 0.5, zA + len / 2), C(12, 8, 10), Enum.Material.Concrete)
	part("ThroneEndWall", Vector3.new(W + 2, H + 2, 2), Vector3.new(0, H / 2, zA + len + 1), DARK, Enum.Material.Concrete)
	local cz2 = zA + 18
	while cz2 < zA + len - 20 do safe(chandelier, 0, cz2); cz2 += 24 end
	-- помост и трон
	local zT = zA + len - 14
	for i = 1, 3 do
		part("ThroneStep", Vector3.new(26 - i * 4, i * 0.7, 18 - i * 2), Vector3.new(0, i * 0.35, zT + 4 - i), C(30, 22, 24), Enum.Material.Marble)
	end
	local base = 2.1
	part("ThroneSeat", Vector3.new(6, 2, 5), Vector3.new(0, base + 1, zT + 2), C(22, 14, 16), Enum.Material.Metal)
	part("ThroneCushion", Vector3.new(5, 0.6, 4), Vector3.new(0, base + 2.2, zT + 1.8), BLOOD, Enum.Material.Fabric)
	part("ThroneBack", Vector3.new(6.5, 15, 1.2), Vector3.new(0, base + 7.5, zT + 4.4), C(20, 12, 14), Enum.Material.Metal)
	for _, sx in { -1, 1 } do
		part("ThroneArm", Vector3.new(1, 2.2, 5), Vector3.new(sx * 3.5, base + 2.1, zT + 2), C(26, 16, 18), Enum.Material.Metal)
		part("ThroneSpike", Vector3.new(0.7, 11, 0.7), Vector3.new(sx * 5, base + 9, zT + 4.2), C(24, 14, 16), Enum.Material.Metal)
		local tip = part("ThroneHorn", Vector3.new(0.9, 5, 0.9), Vector3.new(sx * 6, base + 16, zT + 4.2), C(30, 18, 18), Enum.Material.Metal)
		tip.CFrame = tip.CFrame * CFrame.Angles(0, 0, sx * -0.35)
	end
	local gem = part("ThroneGem", Vector3.new(1.6, 2.4, 0.6), Vector3.new(0, base + 11, zT + 3.7), C(255, 20, 20), Enum.Material.Neon)
	gem.CanCollide = false
	local gl = Instance.new("PointLight"); gl.Range = 36; gl.Brightness = 2.4; gl.Color = C(255, 30, 30); gl.Parent = gem
	-- надпись на дальней стене
	local sign = part("ThroneSign", Vector3.new(30, 4, 0.2), Vector3.new(0, H - 3, zA + len - 0.1), C(0, 0, 0), Enum.Material.SmoothPlastic)
	sign.Transparency = 1; sign.CanCollide = false
	local sg = Instance.new("SurfaceGui"); sg.Face = Enum.NormalId.Back; sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; sg.PixelsPerStud = 40; sg.Parent = sign
	local tl = Instance.new("TextLabel"); tl.Size = UDim2.fromScale(1, 1); tl.BackgroundTransparency = 1; tl.Text = "ROOM 666 - THE OWNER"
	tl.Font = Enum.Font.Antique; tl.TextScaled = true; tl.TextColor3 = C(200, 20, 24); tl.Parent = sg
	cur += len
	return zT - 20, zT
end


-- Room 66 - The Ballroom: огромный зал, манекены медленно поворачиваются вслед за игроком
local mannequinSets = {}
local function ballroom(len: number)
	local zA = cur
	room(len)
	local cz = zA + 14
	while cz < zA + len - 10 do safe(chandelier, 0, cz); cz += 20 end
	local set = {}
	local pale, dark = C(214, 208, 198), C(30, 24, 26)
	local function mannequin(x: number, z: number)
		local center = O + Vector3.new(x, 0, z)
		local parts = {}
		local function bp(size: Vector3, off: Vector3, col: Color3, shape: Enum.PartType?)
			local p = part("Mannequin", size, Vector3.new(x, 0, z), col, Enum.Material.SmoothPlastic)
			if shape then p.Shape = shape end
			p.CanCollide = false
			table.insert(parts, { p = p, off = off })
		end
		bp(Vector3.new(0.9, 3.4, 0.9), Vector3.new(-0.6, 1.7, 0), pale)
		bp(Vector3.new(0.9, 3.4, 0.9), Vector3.new(0.6, 1.7, 0), pale)
		bp(Vector3.new(2.4, 3.2, 1.2), Vector3.new(0, 5, 0), dark)
		bp(Vector3.new(0.7, 3.2, 0.7), Vector3.new(-1.6, 5, 0), pale)
		bp(Vector3.new(0.7, 3.2, 0.7), Vector3.new(1.6, 5, 0), pale)
		bp(Vector3.new(1.5, 1.5, 1.5), Vector3.new(0, 7.3, 0), pale, Enum.PartType.Ball)
		bp(Vector3.new(0.18, 0.18, 0.1), Vector3.new(-0.3, 7.4, -0.74), C(10, 10, 10))
		bp(Vector3.new(0.18, 0.18, 0.1), Vector3.new(0.3, 7.4, -0.74), C(10, 10, 10))
		table.insert(set, { center = center, parts = parts, yaw = math.rad(rng:NextInteger(0, 359)) })
	end
	local z = zA + 16
	while z < zA + len - 12 do
		mannequin(-20 + rng:NextNumber(-2, 2), z)
		mannequin(20 + rng:NextNumber(-2, 2), z + 6)
		z += 14
	end
	-- рояль в углу
	part("PianoBody", Vector3.new(6, 3, 8), Vector3.new(-23, 2.5, zA + len - 14), C(12, 10, 12), Enum.Material.SmoothPlastic)
	part("PianoLid", Vector3.new(5.6, 0.2, 7), Vector3.new(-23, 4.2, zA + len - 14), C(18, 14, 16), Enum.Material.SmoothPlastic)
	for _, dx in { -2.6, 2.6 } do part("PianoLeg", Vector3.new(0.6, 1.8, 0.6), Vector3.new(-23 + dx, 0.9, zA + len - 17), C(12, 10, 12), Enum.Material.Wood) end
	curLevel.mannequins = curLevel.mannequins or {}
	for _, m in set do table.insert(curLevel.mannequins, m) end
	mannequinSets[curLevel] = curLevel.mannequins
end

-- Room 100 - The Flood: затопленный зал
local function floodRoom(len: number)
	local zA = cur
	room(len)
	local w = part("FloodWater", Vector3.new(RW - 1, 3.2, len), Vector3.new(0, 1.6, zA + len / 2), C(24, 62, 78), Enum.Material.Glass)
	w.Transparency = 0.45; w.CanCollide = false; w.CanQuery = false
	local wl = part("FloodGlow", Vector3.new(RW - 1, 0.1, len), Vector3.new(0, 3.2, zA + len / 2), C(40, 110, 130), Enum.Material.SmoothPlastic)
	wl.Transparency = 0.8; wl.CanCollide = false; wl.CanQuery = false
	local d = zA + 10
	while d < zA + len - 8 do
		local crate = part("FloodDebris", Vector3.new(rng:NextNumber(2, 4), rng:NextNumber(1, 2), rng:NextNumber(2, 4)), Vector3.new(rng:NextNumber(-22, 22), 3.1, d), jitter(C(70, 50, 36), 0.1), Enum.Material.Wood)
		crate.CFrame = crate.CFrame * CFrame.Angles(0, rng:NextNumber(0, 3), rng:NextNumber(-0.2, 0.2))
		d += rng:NextNumber(8, 14)
	end
end


-- ---------- новые типы комнат ----------
-- фальшивая комната (без номера): закуток у стены с сундуком
local function fakeRoom(sx: number, zc: number)
	local W, depth, wid, hh = RW, 16, 14, 12
	local wallC = C(40, 26, 24)
	local xi = sx * (W / 2 - depth)                       -- внутренняя стена
	for _, dz in { -1, 1 } do
		part("FakeSide", Vector3.new(depth, hh, 0.8), Vector3.new(sx * (W / 2 - depth / 2), hh / 2, zc + dz * wid / 2), wallC, Enum.Material.Wood)
	end
	for _, dz in { -1, 1 } do   -- передняя стена с проёмом 6 шириной
		part("FakeFront", Vector3.new(0.8, hh, (wid - 6) / 2), Vector3.new(xi, hh / 2, zc + dz * (3 + (wid - 6) / 4)), wallC, Enum.Material.Wood)
	end
	part("FakeLintel", Vector3.new(0.8, hh - 9, 6), Vector3.new(xi, 9 + (hh - 9) / 2, zc), wallC, Enum.Material.Wood)
	part("FakeCeiling", Vector3.new(depth, 0.8, wid), Vector3.new(sx * (W / 2 - depth / 2), hh + 0.4, zc), C(30, 20, 18), Enum.Material.Wood)
	part("FakeRug", Vector3.new(depth - 2, 0.1, wid - 2), Vector3.new(sx * (W / 2 - depth / 2), 0.06, zc), jitter(C(90, 20, 26), 0.1), Enum.Material.Fabric)
	local lamp = part("FakeLamp", Vector3.new(0.6, 0.6, 0.6), Vector3.new(sx * (W / 2 - 6), 9, zc), C(255, 70, 40), Enum.Material.Neon)
	lamp.CanCollide = false
	local pl = Instance.new("PointLight"); pl.Range = 18; pl.Brightness = 1.2; pl.Color = C(255, 80, 50); pl.Parent = lamp
	table.insert(lamps, { part = lamp, light = pl, base = 1.2, seed = rng:NextNumber(0, 100), bad = rng:NextNumber() < 0.5 })
	safe(lootBox, sx, W, zc)
end

local function bedroom(len: number)
	local zA = cur
	room(len)
	local z = zA + 16
	local side = (rng:NextInteger(0, 1) == 0) and -1 or 1
	while z < zA + len - 14 do
		local x = side * (RW / 2 - 5)
		part("BedFrame", Vector3.new(6, 1.4, 8.4), Vector3.new(x, 0.7, z), C(60, 38, 24), Enum.Material.Wood)
		part("BedMattress", Vector3.new(5.6, 0.9, 7.8), Vector3.new(x, 1.8, z), C(196, 188, 170), Enum.Material.Fabric)
		part("BedBlanket", Vector3.new(5.7, 0.4, 5), Vector3.new(x, 2.3, z - 1.4), jitter(C(100, 24, 30), 0.1), Enum.Material.Fabric)
		part("BedPillow", Vector3.new(4, 0.6, 1.4), Vector3.new(x, 2.4, z + 3.2), C(220, 214, 200), Enum.Material.Fabric)
		part("BedHead", Vector3.new(0.5, 5, 6.6), Vector3.new(side * (RW / 2 - 0.9), 2.5, z), C(52, 32, 20), Enum.Material.Wood)
		part("Nightstand", Vector3.new(2, 2.4, 2), Vector3.new(x, 1.2, z + 6), C(70, 44, 26), Enum.Material.Wood)
		z += rng:NextNumber(24, 32)
		side = -side
	end
	local cz = zA + 18
	while cz < zA + len - 10 do safe(chandelier, 0, cz); cz += 26 end
	if rng:NextNumber() < 0.5 then fakeRoom(-side, zA + len / 2) end
end

-- круглый зал с огромной центральной стеной и 4 «дверями»
local function roundHub(len: number)
	local zA = cur
	room(len)
	local zc = zA + len / 2
	local hub = part("HubWall", Vector3.new(RH, 26, 26), Vector3.new(0, RH / 2, zc), C(46, 20, 22), Enum.Material.Concrete)
	hub.Shape = Enum.PartType.Cylinder
	hub.CFrame = CFrame.new(hub.Position) * CFrame.Angles(0, 0, math.pi / 2)
	local ring = part("HubRing", Vector3.new(0.6, 30, 30), Vector3.new(0, 0.3, zc), C(90, 20, 26), Enum.Material.Marble)
	ring.Shape = Enum.PartType.Cylinder
	ring.CFrame = CFrame.new(ring.Position) * CFrame.Angles(0, 0, math.pi / 2)
	ring.CanCollide = false
	for i = 0, 3 do
		local a = i * math.pi / 2
		local dir = Vector3.new(math.sin(a), 0, math.cos(a))
		local base = Vector3.new(0, 0, zc) + dir * 13.2
		local d = part("HubDoor", Vector3.new(5.4, 9, 0.5), base + Vector3.new(0, 4.5, 0), C(24, 12, 10), Enum.Material.Wood)
		d.CFrame = CFrame.lookAt(d.Position, d.Position + dir)
		local fr = part("HubFrame", Vector3.new(6.4, 9.8, 0.3), base + dir * -0.05 + Vector3.new(0, 4.9, 0), C(120, 84, 40), Enum.Material.Metal)
		fr.CFrame = CFrame.lookAt(fr.Position, fr.Position + dir); fr.CanCollide = false
		local lamp = part("HubLamp", Vector3.new(0.7, 0.7, 0.7), base + dir * 1.2 + Vector3.new(0, 11, 0), C(255, 70, 40), Enum.Material.Neon)
		lamp.CanCollide = false
		local pl = Instance.new("PointLight"); pl.Range = 30; pl.Brightness = 1.4; pl.Color = C(255, 90, 60); pl.Parent = lamp
		table.insert(lamps, { part = lamp, light = pl, base = 1.4, seed = rng:NextNumber(0, 100), bad = rng:NextNumber() < 0.25 })
	end
	fakeRoom(-1, zA + 18)
	fakeRoom(1, zA + len - 18)
end

-- зал с лестницами вверх и вниз через помост
local function stairsHall(len: number)
	local zA = cur
	room(len)
	local zS = zA + len / 2 - 20
	local sx = -22   -- лестница у стены, центр зала свободен
	for i = 1, 10 do
		part("StairUp", Vector3.new(10, i * 0.6, 2), Vector3.new(sx, i * 0.3, zS + i * 2 - 1), C(58, 40, 30), Enum.Material.Wood)
	end
	part("StairPlatform", Vector3.new(10, 6, 14), Vector3.new(sx, 3, zS + 27), C(48, 32, 26), Enum.Material.Wood)
	part("StairRug", Vector3.new(6, 0.1, 14), Vector3.new(sx, 6.05, zS + 27), jitter(C(100, 22, 28), 0.1), Enum.Material.Fabric)
	for i = 1, 10 do
		part("StairDown", Vector3.new(10, (11 - i) * 0.6, 2), Vector3.new(sx, (11 - i) * 0.3, zS + 34 + i * 2 - 1), C(58, 40, 30), Enum.Material.Wood)
	end
	if rng:NextNumber() < 0.6 then safe(chandelier, 0, zS + 27) end
end

-- склад: стопки ящиков
local function warehouse(len: number)
	local zA = cur
	room(len)
	local z = zA + 12
	while z < zA + len - 10 do
		for _ = 1, rng:NextInteger(2, 4) do
			local x = rng:NextNumber(-24, 24)
			if math.abs(x) < 4 then x += 8 end
			local sz = rng:NextNumber(3.5, 5.5)
			part("Crate", Vector3.new(sz, sz, sz), Vector3.new(x, sz / 2, z + rng:NextNumber(-4, 4)), jitter(C(96, 66, 38), 0.1), Enum.Material.Wood)
			if rng:NextNumber() < 0.5 then part("Crate", Vector3.new(sz * 0.8, sz * 0.8, sz * 0.8), Vector3.new(x, sz + sz * 0.4, z + rng:NextNumber(-4, 4) * 0.2), jitter(C(86, 58, 34), 0.1), Enum.Material.Wood) end
		end
		z += rng:NextNumber(14, 20)
	end
	if rng:NextNumber() < 0.5 then fakeRoom((rng:NextInteger(0, 1) == 0) and -1 or 1, zA + len / 2) end
end

-- после 100-й двери: три двери ?, ??, ??? и затем комната 666
local function postHundred(): (number, number)
	for _, lab in { "?", "??", "???" } do
		hall(34, {})
		nextDoorLabel = lab
		door(false)
	end
	return throneRoom(96)
end


-- ------------------------------------------------------------
-- Монстр: чёрный глитч-краулер
-- ------------------------------------------------------------
-- Rush-подобный монстр: чёрная чернильная клякса, серое лицо, белая зубастая улыбка
local function buildRush()
	local model = Instance.new("Model")
	model.Name = "Crawler"
	local INK = Color3.fromRGB(6, 7, 14)
	local INK2 = Color3.fromRGB(14, 16, 30)
	local FACE = Color3.fromRGB(150, 152, 160)
	local recs = {}
	local function add(shape: string, size: Vector3, cf: CFrame, color: Color3, mat: Enum.Material?, jit: number?)
		local p = Instance.new("Part")
		p.Size = size; p.Anchored = true
		p.CanCollide, p.CanTouch, p.CanQuery = false, false, false
		p.CastShadow = shape == "ball" and size.X > 3
		p.Color = color; p.Material = mat or Enum.Material.SmoothPlastic
		if shape == "ball" then
			local m = Instance.new("SpecialMesh"); m.MeshType = Enum.MeshType.Sphere; m.Parent = p
		end
		p.Parent = model
		local r = { part = p, cf = cf, jit = jit or 0 }
		table.insert(recs, r)
		return r
	end
	local CY = 3.4
	-- тело-клякса из нескольких пересекающихся шаров
	add("ball", Vector3.new(6.2, 5.4, 4.2), CFrame.new(0, CY, 0), INK, nil, 0.02)
	add("ball", Vector3.new(5.0, 6.2, 3.4), CFrame.new(0.2, CY + 0.2, 0.2), INK2, nil, 0.03)
	for i = 1, 9 do
		local a = rng:NextNumber(0, math.pi * 2)
		local d = rng:NextNumber(1.6, 2.8)
		local s = rng:NextNumber(1.2, 2.4)
		add("ball", Vector3.new(s, s, s), CFrame.new(math.cos(a) * d, CY + math.sin(a) * d * 0.9, rng:NextNumber(-0.4, 1.2)), (i % 2 == 0) and INK or INK2, nil, 0.05)
	end
	-- лучи-брызги во все стороны (в основном в плоскости XY)
	local spikes = {}
	for i = 1, 34 do
		local a = (i / 34) * math.pi * 2 + rng:NextNumber(-0.12, 0.12)
		local len = rng:NextNumber(1.6, 4.4)
		local th = rng:NextNumber(0.25, 0.7)
		local r0 = 2.6
		local cf = CFrame.new(math.cos(a) * (r0 + len / 2), CY + math.sin(a) * (r0 + len / 2) * 0.95, rng:NextNumber(-0.3, 0.5))
			* CFrame.Angles(0, 0, a + math.pi / 2) * CFrame.Angles(rng:NextNumber(-0.2, 0.2), 0, 0)
		local sp = add("block", Vector3.new(th, len, th * 0.8), cf, INK, nil, 0.06)
		sp.a = a; sp.len = len; sp.r0 = r0; sp.ph = rng:NextNumber(0, 6.28)
		table.insert(spikes, sp)
		-- шарик-капля на конце
		if i % 3 == 0 then
			local dr = add("ball", Vector3.new(th * 1.6, th * 1.6, th * 1.6), cf * CFrame.new(0, len / 2 + 0.5, 0), INK, nil, 0.1)
		end
	end
	-- лицо: серый диск спереди (лицо смотрит на -Z)
	add("ball", Vector3.new(3.6, 3.1, 0.9), CFrame.new(0, CY + 0.15, -2.0), FACE, Enum.Material.Slate, 0.01)
	add("ball", Vector3.new(3.3, 2.8, 0.5), CFrame.new(0, CY + 0.15, -2.35), Color3.fromRGB(176, 178, 186), Enum.Material.Slate, 0.01)
	-- глазницы и глаза
	for _, sx in { -1, 1 } do
		add("ball", Vector3.new(0.85, 0.95, 0.3), CFrame.new(sx * 0.8, CY + 0.7, -2.55), Color3.fromRGB(8, 8, 10), nil, 0.01)
		add("ball", Vector3.new(0.32, 0.32, 0.12), CFrame.new(sx * 0.8, CY + 0.78, -2.66), Color3.fromRGB(240, 240, 255), Enum.Material.Neon, 0.01)
		add("block", Vector3.new(1.0, 0.18, 0.12), CFrame.new(sx * 0.8, CY + 1.35, -2.55) * CFrame.Angles(0, 0, sx * -0.35), Color3.fromRGB(10, 10, 12), nil, 0.01)
	end
	-- рот: тёмный полумесяц + белые зубы
	add("ball", Vector3.new(2.5, 1.15, 0.3), CFrame.new(0, CY - 0.75, -2.55), Color3.fromRGB(6, 6, 8), nil, 0.01)
	for i = -4, 4 do
		local w = 0.26
		local h = 0.42 - math.abs(i) * 0.02
		add("block", Vector3.new(w, h, 0.14), CFrame.new(i * 0.28, CY - 0.45 - math.abs(i) * 0.05, -2.68), Color3.fromRGB(248, 248, 252), Enum.Material.SmoothPlastic, 0.01)
		add("block", Vector3.new(w, h * 0.9, 0.14), CFrame.new(i * 0.28, CY - 1.05 - math.abs(i) * 0.1, -2.68), Color3.fromRGB(244, 244, 250), Enum.Material.SmoothPlastic, 0.01)
	end
	-- дымка/капли позади
	local blobs = {}
	for i = 1, 14 do
		local s = rng:NextNumber(0.8, 2.2)
		table.insert(blobs, add("ball", Vector3.new(s, s, s), CFrame.new(), INK, Enum.Material.SmoothPlastic, 0))
	end
	local lightPart = Instance.new("Part")
	lightPart.Size = Vector3.new(0.2, 0.2, 0.2); lightPart.Transparency = 1
	lightPart.Anchored, lightPart.CanCollide, lightPart.CanTouch, lightPart.CanQuery = true, false, false, false
	lightPart.Parent = model
	local pl = Instance.new("PointLight")
	pl.Range = 18; pl.Brightness = 1.0; pl.Color = Color3.fromRGB(200, 210, 255); pl.Shadows = true
	pl.Parent = lightPart
	local frame = 0
	local jit = {}
	local function render(pivot: CFrame, t: number)
		frame += 1
		local hover = 0.5 + math.sin(t * 2.6) * 0.4
		local base = pivot * CFrame.new(0, hover, 0) * CFrame.Angles(0.06, 0, math.sin(t * 2) * 0.04)
		if frame % 2 == 0 then
			for i, r in recs do
				local j = r.jit
				jit[i] = j > 0 and CFrame.new(rng:NextNumber(-j, j), rng:NextNumber(-j, j), rng:NextNumber(-j, j) * 0.5) or CFrame.identity
			end
		end
		for i, r in recs do
			r.part.CFrame = base * r.cf * (jit[i] or CFrame.identity)
		end
		-- лучи пульсируют
		for _, sp in spikes do
			local k = 1 + math.sin(t * 7 + sp.ph) * 0.18
			sp.part.Size = Vector3.new(sp.part.Size.X, sp.len * k, sp.part.Size.Z)
			local mid = sp.r0 + sp.len * k / 2
			sp.part.CFrame = base * CFrame.new(math.cos(sp.a) * mid, CY + math.sin(sp.a) * mid * 0.95, sp.cf.Position.Z) * CFrame.Angles(0, 0, sp.a + math.pi / 2)
		end
		for i, b in blobs do
			local z = 1.8 + ((t * 5 + i * 1.7) % 8)
			local fade = z / 9.8
			b.part.CFrame = base * CFrame.new(math.sin(t * 3 + i) * 2.4 * (1 - fade * 0.3), CY + math.cos(t * 2.4 + i * 1.3) * 2.0, z)
			b.part.Transparency = 0.25 + fade * 0.7
		end
		lightPart.CFrame = base * CFrame.new(0, CY + 1, -5)
		pl.Brightness = 0.6 + rng:NextNumber() * 0.8
	end
	render(CFrame.new(), 0)
	return { model = model, render = render }
end

local function buildMonster(xmas: boolean?)
	if not xmas then return buildRush() end
	-- тонкий «плоский» гуманоид: чёрный силуэт почти без толщины, парит над полом
	local model = Instance.new("Model")
	model.Name = "Crawler"
	local BLK = Color3.fromRGB(5, 5, 7)
	local BODY = xmas and Color3.fromRGB(178, 20, 26) or BLK
	local SKINC = xmas and Color3.fromRGB(226, 190, 170) or BLK
	local WHITE = Color3.fromRGB(246, 246, 250)
	local recs = {}
	local function add(shape: string, size: Vector3, cf: CFrame, color: Color3, mat: Enum.Material?, jit: number?)
		local p = Instance.new("Part")
		p.Size = size; p.Anchored = true
		p.CanCollide, p.CanTouch, p.CanQuery, p.CastShadow = false, false, false, false
		p.Color = color; p.Material = mat or Enum.Material.SmoothPlastic
		if shape == "ball" then
			local m = Instance.new("SpecialMesh"); m.MeshType = Enum.MeshType.Sphere; m.Parent = p
		end
		p.Parent = model
		local r = { part = p, cf = cf, jit = jit or 0 }
		table.insert(recs, r)
		return r
	end
	local T = 0.22   -- толщина (почти 2D)
	add("block", Vector3.new(1.3, 3.4, T), CFrame.new(0, 4.6, 0), BODY, nil, 0.03)          -- торс
	add("ball", Vector3.new(1.5, 1.9, T), CFrame.new(0, 7.0, 0), SKINC, nil, 0.03)           -- голова
	add("block", Vector3.new(0.4, 0.8, T), CFrame.new(0, 6.0, 0), BLK, nil, 0.03)          -- шея
	-- вытянутые руки вперёд-вверх (плоские)
	for _, sx in { -1, 1 } do
		add("block", Vector3.new(0.28, 4.2, T), CFrame.new(sx * 1.6, 6.2, 0) * CFrame.Angles(0, 0, sx * 0.55), BODY, nil, 0.08)
		for f = -1, 1 do
			add("block", Vector3.new(0.08, 1.1, T), CFrame.new(sx * 2.9 + f * 0.18, 8.1 + math.abs(f) * -0.1, 0) * CFrame.Angles(0, 0, sx * 0.55 + f * 0.25), xmas and WHITE or BLK, nil, 0.08)
		end
	end
	-- длинные тонкие ноги, свисают
	for _, sx in { -1, 1 } do
		add("block", Vector3.new(0.34, 4.6, T), CFrame.new(sx * 0.4, 1.9, 0) * CFrame.Angles(0, 0, sx * 0.07), BLK, nil, 0.05)
	end
	-- лицо: белые щели глаз и рваный рот
	add("block", Vector3.new(0.5, 0.14, 0.1), CFrame.new(-0.36, 7.2, -0.16) * CFrame.Angles(0, 0, 0.25), (xmas and Color3.fromRGB(255, 40, 40) or Color3.fromRGB(245, 245, 250)), Enum.Material.Neon, 0.02)
	add("block", Vector3.new(0.5, 0.14, 0.1), CFrame.new(0.36, 7.2, -0.16) * CFrame.Angles(0, 0, -0.25), (xmas and Color3.fromRGB(255, 40, 40) or Color3.fromRGB(245, 245, 250)), Enum.Material.Neon, 0.02)
	for i = 1, 6 do
		add("block", Vector3.new(0.08, rng:NextNumber(0.25, 0.5), 0.08), CFrame.new(-0.4 + i * 0.13, 6.6, -0.16), (xmas and Color3.fromRGB(70, 0, 0) or Color3.fromRGB(235, 235, 240)), xmas and Enum.Material.SmoothPlastic or Enum.Material.Neon, 0.03)
	end
	if xmas then   -- ТЁМНЫЙ САНТА: мех, пояс, шапка, борода
		add("block", Vector3.new(1.6, 0.4, T + 0.05), CFrame.new(0, 6.1, 0), WHITE, Enum.Material.Fabric, 0.02)
		add("block", Vector3.new(1.5, 0.45, T + 0.05), CFrame.new(0, 3.05, 0), WHITE, Enum.Material.Fabric, 0.02)
		add("block", Vector3.new(0.12, 3.0, T + 0.05), CFrame.new(0, 4.6, -0.01), WHITE, Enum.Material.Fabric, 0)
		add("block", Vector3.new(1.45, 0.45, T + 0.06), CFrame.new(0, 4.15, 0), Color3.fromRGB(14, 12, 12), nil, 0)
		add("block", Vector3.new(0.55, 0.5, T + 0.1), CFrame.new(0, 4.15, 0), Color3.fromRGB(255, 210, 70), Enum.Material.Neon, 0)
		add("block", Vector3.new(1.35, 0.7, T + 0.04), CFrame.new(0, 6.45, 0), WHITE, Enum.Material.Fabric, 0.02)   -- борода
		add("block", Vector3.new(0.95, 1.0, T + 0.04), CFrame.new(0, 5.7, 0), WHITE, Enum.Material.Fabric, 0.04)
		add("block", Vector3.new(2.0, 0.4, T + 0.05), CFrame.new(0, 7.85, 0), WHITE, Enum.Material.Fabric, 0.02)   -- шапка
		add("block", Vector3.new(1.6, 0.7, T), CFrame.new(0.05, 8.3, 0) * CFrame.Angles(0, 0, -0.1), BODY, nil, 0.02)
		add("block", Vector3.new(1.1, 0.7, T), CFrame.new(0.3, 8.9, 0) * CFrame.Angles(0, 0, -0.35), BODY, nil, 0.02)
		add("block", Vector3.new(0.7, 0.7, T), CFrame.new(0.75, 9.35, 0) * CFrame.Angles(0, 0, -0.7), BODY, nil, 0.02)
		add("ball", Vector3.new(0.6, 0.6, 0.5), CFrame.new(1.2, 9.5, 0), WHITE, Enum.Material.Fabric, 0.02)
		add("block", Vector3.new(0.25, 3.2, 0.2), CFrame.new(2.9, 3.1, -0.2), Color3.fromRGB(240, 240, 240), nil, 0.03)   -- посох-леденец
		add("block", Vector3.new(0.9, 0.25, 0.2), CFrame.new(2.55, 4.7, -0.2), Color3.fromRGB(230, 30, 40), nil, 0.03)
	end
	-- глитч-пиксели вокруг
	local pixels = {}
	for i = 1, 22 do
		local c = Color3.fromRGB(245, 245, 250)
		if i % 9 == 0 then c = Color3.fromRGB(150, 255, 170) elseif i % 11 == 0 then c = Color3.fromRGB(255, 60, 60) end
		local s = rng:NextNumber(0.15, 0.32)
		table.insert(pixels, add("block", Vector3.new(s, s, 0.08), CFrame.new(), c, Enum.Material.Neon, 0))
	end
	local lightPart = Instance.new("Part")
	lightPart.Size = Vector3.new(0.2, 0.2, 0.2); lightPart.Transparency = 1
	lightPart.Anchored, lightPart.CanCollide, lightPart.CanTouch, lightPart.CanQuery = true, false, false, false
	lightPart.Parent = model
	local pl = Instance.new("PointLight")
	pl.Range = 16; pl.Brightness = 0.8; pl.Color = Color3.fromRGB(210, 220, 255)
	pl.Parent = lightPart
	-- тонкие ленты-щупальца позади
	local tents = {}
	for k = 1, 5 do
		local chain = { off = (k - 3) * 0.55, segs = {} }
		for j = 1, 6 do
			local sg = Instance.new("Part")
			sg.Size = Vector3.new(0.14, 0.14, 1.8)
			sg.Anchored = true
			sg.CanCollide, sg.CanTouch, sg.CanQuery, sg.CastShadow = false, false, false, false
			sg.Color = xmas and ((k % 2 == 0) and Color3.fromRGB(210, 24, 30) or WHITE) or BLK; sg.Material = Enum.Material.SmoothPlastic
			sg.Parent = model
			chain.segs[j] = sg
		end
		tents[k] = chain
	end
	local frame = 0
	local jitters = {}
	local function render(pivot: CFrame, t: number)
		frame += 1
		local hover = 0.4 + math.sin(t * 3) * 0.35
		local base = pivot * CFrame.new(0, hover, 0) * CFrame.Angles(0.12, 0, math.sin(t * 2.3) * 0.05)
		if frame % 2 == 0 then
			for i, r in recs do
				local j = r.jit
				jitters[i] = j > 0 and CFrame.new(rng:NextNumber(-j, j), rng:NextNumber(-j, j), 0) or CFrame.identity
			end
		end
		for i, r in recs do
			r.part.CFrame = base * r.cf * (jitters[i] or CFrame.identity)
		end
		for k, ch in tents do
			local prev = base * Vector3.new(ch.off, 3.2, 0.2)
			for j, sg in ch.segs do
				local sw = j / #ch.segs
				local nxt = base * Vector3.new(ch.off * (1 + j * 0.25) + math.sin(t * 6 + k + j * 0.8) * 0.8 * sw, 3.2 - j * 0.55 + math.sin(t * 5 + k * 2 + j * 0.7) * 0.5 * sw, 0.2 + 1.7 * j)
				local d = (nxt - prev).Magnitude
				sg.Size = Vector3.new(sg.Size.X, sg.Size.Y, d + 0.2)
				sg.CFrame = CFrame.lookAt(prev, nxt) * CFrame.new(0, 0, -d / 2)
				prev = nxt
			end
		end
		for _, px in pixels do
			if rng:NextNumber() < 0.35 then
				px.part.CFrame = base * CFrame.new(rng:NextNumber(-2.4, 2.4), rng:NextNumber(1, 8.4), -0.3 - rng:NextNumber(0, 0.3))
				px.part.Transparency = (rng:NextNumber() < 0.3) and 1 or 0
			end
		end
		lightPart.CFrame = base * CFrame.new(0, 6.8, -3)
		pl.Brightness = 0.4 + rng:NextNumber() * 0.8
	end
	render(CFrame.new(), 0)
	return { model = model, render = render }
end


-- ------------------------------------------------------------
-- Уровни: каждая катка (или команда) получает свою, СЛУЧАЙНО собранную карту.
-- Сегменты строятся по ходу движения и удаляются позади.
-- ------------------------------------------------------------
local TOTAL = CONFIG.TotalDoors
local function ach(plr: Player, id: string)
	local ev = ServerStorage:FindFirstChild("EvaKAchieve")
	if ev then ev:Fire(plr, id) end
end
local levels: {[string]: any} = {}
local usedSlots: {[number]: boolean} = {}

local function useLevel(lv, parent: Instance)
	O = lv.O; cur = lv.cur; lastW, lastH = lv.lastW, lv.lastH
	curLevel = lv; curParent = parent; BRICKS = lv.bricks
end
local function saveLevel(lv)
	lv.cur, lv.lastW, lv.lastH = cur, lastW, lastH
end

local function pick(w: {[string]: number}): string
	local total = 0
	for _, v in w do total += v end
	local r = rng:NextNumber() * total
	for k, v in w do
		r -= v
		if r <= 0 then return k end
	end
	return "obst"
end

onDoorBroken = function(lv, rec)
	lv.broken += 1
	local doorsEv = ServerStorage:FindFirstChild("EvaKDoors")
	for plr in lv.players do
		if doorsEv and plr.Parent then doorsEv:Fire(plr, lv.broken) end
		if plr.Parent then
			world:FireClient(plr, "Doors", lv.endless and lv.broken or math.min(lv.broken, TOTAL), lv.endless and 0 or TOTAL)
			if lv.broken == 1 then ach(plr, "d1") elseif lv.broken == 10 then ach(plr, "d10") elseif lv.broken == 30 then ach(plr, "d30")
			elseif lv.broken == 50 then ach(plr, "d50") elseif lv.broken == 75 then ach(plr, "d75") elseif lv.broken == 100 then ach(plr, "d100") end
		end
	end
end

local buildBusy = false
local function withBuild(fn: () -> ())
	while buildBusy do task.wait() end
	buildBusy = true
	local ok, err = pcall(fn)
	buildBusy = false
	if not ok then warn("[EvaKMap] ошибка постройки:", err) end
end

-- ============================================================
-- ОСОБЫЕ СЕГМЕНТЫ: побег от слизи (двери 26-30) и столовая-босс (дверь 50)
-- ============================================================
local ESC_FROM, ESC_TO = 26, 30
local BOSS_IDX = 50
local startSlimeHook: (any) -> () = function() end
local spawnBaubleHook: (any, number, number) -> () = function() end
local spawnBossHook: (any) -> () = function() end

local function addHook(lv, z: number, fn: () -> ())
	lv.hooks = lv.hooks or {}
	table.insert(lv.hooks, { z = z, fn = fn, fired = false })
end

-- упавший шкаф: пролезть можно только пригнувшись (C / Ctrl)
local function fallenWardrobe(z: number)
	local wood, dk = jitter(C(96, 58, 34), 0.1), C(52, 32, 20)
	for _, sx in { -1, 1 } do
		part("FallenSupport", Vector3.new(3, 4.6, 7.5), Vector3.new(sx * (HW / 2 - 1.5), 2.3, z), dk, Enum.Material.Wood)
	end
	local body = part("FallenWardrobe", Vector3.new(HW - 0.4, 4.4, 7), Vector3.new(0, 6.8, z), wood, Enum.Material.Wood)
	body.CFrame = body.CFrame * CFrame.Angles(0, 0, rng:NextNumber(-0.015, 0.015))
	for _, sx in { -1, 1 } do   -- створки на нижней стороне
		mark(part("FallenDoor", Vector3.new(HW / 2 - 0.8, 0.2, 6), Vector3.new(sx * (HW / 4 - 0.2), 4.55, z), jitter(wood, 0.1), Enum.Material.Wood))
		local kn = mark(part("FallenKnob", Vector3.new(0.5, 0.5, 0.5), Vector3.new(sx * 1.0, 4.35, z), C(238, 222, 190), Enum.Material.SmoothPlastic))
		kn.Shape = Enum.PartType.Ball
	end
	mark(part("FallenSign", Vector3.new(HW - 6, 0.3, 0.1), Vector3.new(0, 4.8, z - 3.55), C(255, 190, 40), Enum.Material.Neon))
	for _ = 1, 6 do   -- щепки и обломки
		local sp = mark(part("Splinter", Vector3.new(rng:NextNumber(0.3, 0.6), 0.3, rng:NextNumber(1.4, 3)), Vector3.new(rng:NextNumber(-HW / 2 + 2, HW / 2 - 2), 0.15, z + rng:NextNumber(-6, 6)), jitter(C(80, 50, 30), 0.2), Enum.Material.Wood))
		sp.CFrame = sp.CFrame * CFrame.Angles(0, rng:NextNumber(0, 3), 0)
	end
end

-- стена-барьер выезжает из боковой стены (слева или справа): надо перепрыгнуть
local function hurdle(lv, z: number, sx: number)
	local x0 = sx * (HW + 2)
	local pnl = part("Hurdle", Vector3.new(HW + 0.2, 3.4, 1.4), Vector3.new(x0, 1.7, z), C(70, 66, 62), Enum.Material.Concrete)
	local stripe = mark(part("HurdleStripe", Vector3.new(HW + 0.2, 0.5, 0.1), Vector3.new(x0, 2.7, z - 0.75), C(255, 190, 40), Enum.Material.Neon))
	local stripe2 = mark(part("HurdleStripe", Vector3.new(HW + 0.2, 0.5, 0.1), Vector3.new(x0, 1.2, z - 0.75), C(40, 40, 44), Enum.Material.SmoothPlastic))
	addHook(lv, z - 38, function()
		for _, p in { pnl, stripe, stripe2 } do
			if p.Parent then
				TweenService:Create(p, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = Vector3.new(lv.O.X, p.Position.Y, p.Position.Z) }):Play()
			end
		end
	end)
end

local function drain(z: number)   -- люк в полу, откуда лезет слизь
	local g = mark(part("Drain", Vector3.new(0.2, 6, 6), Vector3.new(0, 0.12, z), C(12, 14, 18), Enum.Material.Metal))
	g.Shape = Enum.PartType.Cylinder
	g.CFrame = CFrame.new(g.Position) * CFrame.Angles(0, 0, math.pi / 2)
	local gl = mark(part("DrainGlow", Vector3.new(0.1, 5, 5), Vector3.new(0, 0.2, z), C(80, 190, 255), Enum.Material.Neon))
	gl.Shape = Enum.PartType.Cylinder
	gl.CFrame = CFrame.new(gl.Position) * CFrame.Angles(0, 0, math.pi / 2)
	gl.Transparency = 0.45
	for k = -2, 2 do
		mark(part("DrainBar", Vector3.new(0.2, 0.2, 5.8), Vector3.new(k * 1.0, 0.3, z), C(30, 32, 36), Enum.Material.Metal))
	end
	local pl = Instance.new("PointLight"); pl.Color = C(90, 190, 255); pl.Range = 26; pl.Brightness = 1.6; pl.Shadows = false; pl.Parent = gl
	for _ = 1, 8 do   -- синие потёки вокруг
		local d = rng:NextNumber(1.5, 4)
		local s = mark(part("SlimeStain", Vector3.new(0.05, d, d * rng:NextNumber(0.6, 1.3)), Vector3.new(rng:NextNumber(-5, 5), 0.07, z + rng:NextNumber(-8, 8)), C(60, 150, 240), Enum.Material.Neon))
		s.Shape = Enum.PartType.Cylinder; s.Transparency = 0.6
		s.CFrame = CFrame.new(s.Position) * CFrame.Angles(0, rng:NextNumber(0, 3), math.pi / 2)
	end
end

local function escapeHall(len: number, idx: number)
	local lv = curLevel
	lv.escape = lv.escape or {}
	local zA = cur
	hall(len, { chase = true })
	if idx == ESC_FROM then
		lv.escape.startZ = zA
		lv.escape.drainZ = zA + 8
		drain(zA + 8)
		addHook(lv, zA + 56, function() startSlimeHook(lv) end)
	end
	local z = zA + ((idx == ESC_FROM) and 78 or 26)
	while z < zA + len - 26 do
		local kind = pick({ fallen = 3, hurdle = 3, barrier = 1, crates = 1, pillars = 1 })
		if kind == "fallen" then
			fallenWardrobe(z)
		elseif kind == "hurdle" then
			lv.hurSide = -(lv.hurSide or 1)
			hurdle(lv, z, lv.hurSide)
		elseif kind == "barrier" then
			barrier(z)
		elseif kind == "crates" then
			crates(z)
		else
			pillars(z)
		end
		z += rng:NextInteger(28, 38)
	end
end

-- столовая: босс-комната
local function canteenRoom(len: number)
	local lv = curLevel
	joint(cur, RW, RH)
	local zA = cur
	local W, H = RW, RH
	local WALL, TILE = C(172, 164, 136), C(84, 118, 94)
	part("CanteenFloor", Vector3.new(W, 1, len), Vector3.new(0, -0.5, zA + len / 2), C(150, 146, 126), Enum.Material.Slate)
	for i = 0, math.floor(len / 6) do
		mark(part("TileLine", Vector3.new(W, 0.04, 0.12), Vector3.new(0, 0.03, zA + i * 6), C(70, 66, 56), Enum.Material.SmoothPlastic))
	end
	for x = -W / 2 + 6, W / 2 - 6, 6 do
		mark(part("TileLine", Vector3.new(0.12, 0.04, len), Vector3.new(x, 0.03, zA + len / 2), C(70, 66, 56), Enum.Material.SmoothPlastic))
	end
	for _ = 1, 18 do   -- грязь и пятна
		local g = mark(part("Grime", Vector3.new(rng:NextNumber(3, 8), 0.05, rng:NextNumber(3, 8)), Vector3.new(rng:NextNumber(-W / 2 + 4, W / 2 - 4), 0.06, zA + rng:NextNumber(4, len - 4)), C(46, 40, 30), Enum.Material.SmoothPlastic))
		g.Transparency = 0.4
	end
	for _ = 1, 4 do blood(W, zA + rng:NextNumber(10, len - 14)) end
	for _, sx in { -1, 1 } do
		part("CanteenWall", Vector3.new(1, H + 2, len), Vector3.new(sx * (W / 2 + 0.5), H / 2, zA + len / 2), WALL, Enum.Material.Concrete)
		part("CanteenTile", Vector3.new(0.3, 8, len), Vector3.new(sx * (W / 2 - 0.15), 4, zA + len / 2), TILE, Enum.Material.Marble)
		mark(part("CanteenBand", Vector3.new(0.2, 0.5, len), Vector3.new(sx * (W / 2 - 0.1), 8.25, zA + len / 2), C(40, 52, 44), Enum.Material.SmoothPlastic))
	end
	part("CanteenCeiling", Vector3.new(W + 2, 1, len), Vector3.new(0, H + 0.5, zA + len / 2), C(150, 146, 132), Enum.Material.Concrete)
	for k = 0, 1 do   -- окна
		for _, sx in { -1, 1 } do
			safe(windowView, sx, W, zA + 30 + k * 40, 12)
		end
	end
	local lz = zA + 10
	while lz < zA + len - 6 do   -- мигающие лампы
		for _, lx in { -14, 14 } do
			local pn = part("Fluor", Vector3.new(3, 0.3, 9), Vector3.new(lx, H - 0.2, lz), C(232, 240, 205), Enum.Material.Neon)
			pn.CanCollide = false; pn.CastShadow = false
			local pl = Instance.new("PointLight"); pl.Range = 36; pl.Brightness = 1.0; pl.Color = C(220, 235, 190); pl.Shadows = false; pl.Parent = pn
			table.insert(lamps, { part = pn, light = pl, base = 1.0, seed = rng:NextNumber(0, 100), bad = rng:NextNumber() < 0.55 })
		end
		lz += 18
	end
	-- столы со скамьями
	local spots = {}
	local function mess(x: number, z: number, big: boolean)
		local sx2 = big and 6 or 4.2
		local sz2 = big and 10 or 12
		part("MsTop", Vector3.new(sx2, 0.35, sz2), Vector3.new(x, 3.1, z), jitter(C(176, 168, 148), 0.06), Enum.Material.SmoothPlastic)
		for _, lz2 in { -sz2 / 2 + 1, sz2 / 2 - 1 } do
			part("MsLeg", Vector3.new(sx2 - 0.8, 3, 0.5), Vector3.new(x, 1.5, z + lz2), C(76, 76, 82), Enum.Material.Metal)
		end
		if not big then
			for _, bs in { -1, 1 } do
				part("MsBench", Vector3.new(1.1, 0.3, sz2 - 0.6), Vector3.new(x + bs * 3.1, 1.9, z), C(110, 70, 40), Enum.Material.Wood)
				for _, lz2 in { -sz2 / 2 + 1, sz2 / 2 - 1 } do
					mark(part("MsBenchLeg", Vector3.new(0.4, 1.85, 0.4), Vector3.new(x + bs * 3.1, 0.92, z + lz2), C(76, 76, 82), Enum.Material.Metal))
				end
			end
		end
		for _ = 1, 3 do   -- подносы с засохшей едой
			local tr = mark(part("Tray", Vector3.new(1.6, 0.12, 1.1), Vector3.new(x + rng:NextNumber(-sx2 / 2 + 1, sx2 / 2 - 1), 3.34, z + rng:NextNumber(-sz2 / 2 + 1, sz2 / 2 - 1)), C(90, 100, 96), Enum.Material.Metal))
			tr.CFrame = tr.CFrame * CFrame.Angles(0, rng:NextNumber(0, 3), 0)
			local fd = mark(part("DryFood", Vector3.new(0.8, 0.12, 0.6), tr.Position - O + Vector3.new(0, 0.12, 0), jitter(C(96, 80, 44), 0.3), Enum.Material.SmoothPlastic))
		end
		for _ = 1, 3 do
			table.insert(spots, Vector3.new(x + rng:NextNumber(-sx2 / 2 + 0.8, sx2 / 2 - 0.8), 3.6, z + rng:NextNumber(-sz2 / 2 + 1, sz2 / 2 - 1)))
		end
	end
	local rowZ = {}
	local rz = zA + 22
	while rz < zA + len - 32 do table.insert(rowZ, rz); rz += 20 end
	local zc = zA + len * 0.5
	for _, rzz in rowZ do
		for _, cx in { -22, -10, 10, 22 } do
			if math.abs(rzz - zc) > 12 or math.abs(cx) > 12 then   -- центр свободен для главного стола
				mess(cx, rzz, false)
			end
		end
	end
	mess(0, zc, true)   -- главный стол в центре
	-- стул зомби
	part("BossChair", Vector3.new(1.6, 0.3, 1.6), Vector3.new(0, 1.8, zc - 6.6), C(110, 70, 40), Enum.Material.Wood)
	part("BossChairBack", Vector3.new(1.6, 2.2, 0.3), Vector3.new(0, 3.0, zc - 7.3), C(110, 70, 40), Enum.Material.Wood)
	for _, bx in { -0.7, 0.7 } do
		for _, bz in { -0.7, 0.7 } do
			mark(part("BossChairLeg", Vector3.new(0.25, 1.7, 0.25), Vector3.new(bx, 0.85, zc - 6.6 + bz), C(76, 76, 82), Enum.Material.Metal))
		end
	end
	for _ = 1, 5 do   -- опрокинутые стулья
		local ch = mark(part("ChairFallen", Vector3.new(1.6, 0.3, 1.6), Vector3.new(rng:NextNumber(-W / 2 + 5, W / 2 - 5), 0.9, zA + rng:NextNumber(8, len - 30)), C(110, 70, 40), Enum.Material.Wood))
		ch.CFrame = ch.CFrame * CFrame.Angles(rng:NextNumber(1, 2), rng:NextNumber(0, 3), rng:NextNumber(0, 1))
	end
	-- раздача и закрытая решётка-шторка на выходе
	part("ServingCounter", Vector3.new(W - 14, 3.6, 3), Vector3.new(0, 1.8, zA + len - 9), C(120, 124, 126), Enum.Material.Metal)
	mark(part("ServingTop", Vector3.new(W - 13, 0.3, 3.4), Vector3.new(0, 3.75, zA + len - 9), C(60, 62, 66), Enum.Material.Slate))
	for k = -3, 3 do
		local pot = mark(part("Pot", Vector3.new(1.8, 1.4, 1.8), Vector3.new(k * 6, 4.5, zA + len - 9), C(150, 150, 156), Enum.Material.Metal))
		pot.Shape = Enum.PartType.Cylinder
		pot.CFrame = CFrame.new(pot.Position) * CFrame.Angles(0, 0, math.pi / 2)
	end
	local shutter = part("CanteenShutter", Vector3.new(W, H, 0.8), Vector3.new(0, H / 2, zA + len - 1.5), C(118, 122, 128), Enum.Material.Metal)
	local sparts = { shutter }
	for k = 0, math.floor(H / 2) do
		table.insert(sparts, mark(part("ShutterSlat", Vector3.new(W, 0.12, 0.2), Vector3.new(0, 1 + k * 2, zA + len - 2.0), C(70, 74, 80), Enum.Material.Metal)))
	end
	local sign = mark(part("ShutterSign", Vector3.new(14, 3, 0.2), Vector3.new(0, H - 5, zA + len - 2.05), C(30, 10, 10), Enum.Material.SmoothPlastic))
	table.insert(sparts, sign)
	do
		local sg = Instance.new("SurfaceGui")
		sg.Face = Enum.NormalId.Front; sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; sg.PixelsPerStud = 40; sg.Parent = sign
		local tl = Instance.new("TextLabel")
		tl.Size = UDim2.fromScale(1, 1); tl.BackgroundTransparency = 1; tl.Text = "LOCKED"
		tl.TextColor3 = C(220, 40, 30); tl.Font = Enum.Font.Arcade; tl.TextScaled = true; tl.Parent = sg
	end
	lv.boss = {
		zA = zA, len = len, centerZ = zc, sitPos = Vector3.new(0, 0, zc - 6.6), spots = spots,
		shutter = shutter, shutterParts = sparts, folder = curParent, state = "idle",
	}
	addHook(lv, zA + 6, function() spawnBossHook(lv) end)
	cur += len
end


local function buildSegment(lv)
	if lv.dead then return end
	local idx = lv.nextIdx
	lv.nextIdx += 1
	curIdx = idx
	local folder = Instance.new("Folder")
	folder.Name = "Seg" .. idx
	folder.Parent = lv.model
	useLevel(lv, folder)
	finishZ = nil
	local segStartZ = cur

	local okS, errS = pcall(function()
	if idx >= ESC_FROM and idx <= ESC_TO then
		escapeHall(rng:NextInteger(150, 190), idx)
	elseif idx == BOSS_IDX then
		canteenRoom(120)
	elseif idx == 66 then
		ballroom(130)
	elseif idx == 100 then
		floodRoom(150)
	elseif idx == 1 then
		hall(rng:NextInteger(60, 80), { style = "cave" })          -- тоннель из пещеры
	else
		local kind = pick({
			obst = 26, room = 24, vent = (idx >= 3) and 9 or 0,
			gap = (idx >= 7) and (16 + idx * 0.12) or 0,
			stones = (idx >= 8) and 10 or 0,
			library = 11, colonnade = 9, lounge = 11, gallery = 8,
			bedroom = (idx >= 3) and 10 or 0, roundhub = (idx >= 5) and 7 or 0, stairs = (idx >= 4) and 8 or 0, warehouse = (idx >= 4) and 7 or 0,
		})
		if kind == "obst" then
			hall(rng:NextInteger(120, 180), { obst = true })
		elseif kind == "gap" then                                    -- обрывы: надо разбежаться и прыгнуть
			local n = rng:NextInteger(1, (idx < 12) and 1 or 3)
local gaps, pos = {}, rng:NextInteger(32, 44)
			for _ = 1, n do
				local gw = rng:NextInteger(8, 10)
				table.insert(gaps, { pos, pos + gw })
				pos += gw + rng:NextInteger(42, 58)
			end
			hall(pos, { gaps = gaps })
		elseif kind == "library" or kind == "colonnade" or kind == "lounge" or kind == "gallery" then
			local len = rng:NextInteger(90, 150)
			local zA = cur
			hall(len, {})
			pcall(function()   -- оформление коридора: разные «залы» для разнообразия
				if kind == "library" then            -- библиотека: стеллажи вдоль обеих стен
					local fz = zA + 10
					while fz < zA + len - 8 do
						for _, sx in { -1, 1 } do
							if rng:NextNumber() < 0.8 then safe(bookshelf, sx, HW, fz + rng:NextNumber(-1, 1)) end
						end
						fz += rng:NextNumber(8, 11)
					end
					local cz = zA + 16
					while cz < zA + len - 8 do safe(chandelier, 0, cz); cz += 30 end
					if rng:NextNumber() < 0.35 then safe(wardrobe, HW, zA, len) end
				elseif kind == "colonnade" then      -- колоннада: ряды колонн и люстры
					local z = zA + 12
					while z < zA + len - 8 do
						safe(column, -HW / 2 + 4.5, z); safe(column, HW / 2 - 4.5, z)
						z += rng:NextNumber(11, 14)
					end
					local cz = zA + 14
					while cz < zA + len - 8 do safe(chandelier, 0, cz); cz += 26 end
				elseif kind == "lounge" then         -- гостиная: кресла, комоды, окна
					local fz = zA + 12
					while fz < zA + len - 10 do
						local sx = (rng:NextInteger(0, 1) == 0) and -1 or 1
						if rng:NextNumber() < 0.5 then safe(armchair, sx, HW, fz) else safe(dresser, sx, HW, fz) end
						fz += rng:NextNumber(14, 22)
					end
					local wz = zA + 14
					while wz < zA + len - 10 do safe(windowView, (rng:NextInteger(0, 1) == 0) and -1 or 1, HW, wz, 11); wz += rng:NextNumber(20, 30) end
					if rng:NextNumber() < 0.4 then safe(wardrobe, HW, zA, len) end
					local cz = zA + 18
					while cz < zA + len - 8 do safe(chandelier, 0, cz); cz += 34 end
				else                                 -- галерея: окна с дождём и люстры
					local wz = zA + 10
					while wz < zA + len - 8 do
						safe(windowView, -1, HW, wz, 11)
						safe(windowView, 1, HW, wz + 9, 11)
						wz += 18
					end
					local cz = zA + 12
					while cz < zA + len - 8 do safe(chandelier, 0, cz); cz += 22 end
				end
			end)
		elseif kind == "bedroom" then
			bedroom(rng:NextInteger(100, 140))
		elseif kind == "roundhub" then
			roundHub(rng:NextInteger(90, 110))
		elseif kind == "stairs" then
			stairsHall(rng:NextInteger(90, 120))
		elseif kind == "warehouse" then
			warehouse(rng:NextInteger(100, 140))
		elseif kind == "room" then
			room(rng:NextInteger(90, 140))
		elseif kind == "stones" then                                 -- камни над пропастью
			stones(rng:NextInteger(3, 5))
		else
			hall(100, { vent = true })                                -- низкий проход (C)
		end
	end
	end)
	if not okS then warn("[EvaKMap] сегмент", idx, errS) end
	local segZ0, segZ1, segW = segStartZ, cur, lastW
	if lv.diff == "newyear" and idx > 1 and idx < TOTAL and idx ~= BOSS_IDX and rng:NextNumber() < 0.4 then   -- новогодний шар-коллекционка
		spawnBaubleHook(lv, rng:NextNumber(-(segW / 2 - 3), segW / 2 - 3), segZ0 + rng:NextNumber(14, math.max(16, segZ1 - segZ0 - 14)))
	end
	door(idx >= ESC_FROM and idx <= ESC_TO)
	if idx == ESC_TO and lv.escape then lv.escape.endZ = cur end
	if idx >= TOTAL and not lv.endless then
		local okL, fz, cz = pcall(postHundred)
		if okL then
			lv.finaleZ, lv.crossZ = fz, cz
		else
			warn("[EvaKMap] лаборатория:", fz)
			finalRoom(90)
			lv.finishZ = finishZ
		end
		lv.complete = true
	end
	saveLevel(lv)
	table.insert(lv.segs, { folder = folder, z1 = cur })
	if idx > 1 and idx < TOTAL then pcall(function() segBuilt:Fire(folder, lv.O, segZ0, segZ1, segW, lv.diff) end) end
	lv.building = false
end

local function newLevel(key: string, diff: string)
	local slot = 1
	while usedSlots[slot] do slot += 1 end
	usedSlots[slot] = true
	local lv = {
		key = key, slot = slot, diff = diff,
		O = Vector3.new(CONFIG.Origin.X + (slot - 1) * CONFIG.SlotSpacing, CONFIG.Origin.Y, CONFIG.Origin.Z),
		segs = {}, doors = {}, nextIdx = 1, cur = z0, lastW = HW, lastH = HH,
		players = {}, broken = 0, complete = false, dead = false,
		bricks = THEMES[rng:NextInteger(1, #THEMES)],
		deco = { wainscot = true, carpet = rng:NextNumber() < 0.92 },
	}
	lv.model = Instance.new("Model")
	lv.model.Name = "EvaKMap" .. slot
	lv.model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent   -- клиент получает карту целиком
	lv.model.Parent = workspace
	levels[key] = lv

	lv.shaft = Instance.new("Folder")
	lv.shaft.Name = "Shaft"
	lv.shaft.Parent = lv.model
	useLevel(lv, lv.shaft)
	local okSh, errSh = pcall(buildShaft)
	if not okSh then warn("[EvaKMap] ошибка шахты: " .. tostring(errSh)) end
	saveLevel(lv)
	for _ = 1, 2 do
		local okSeg, errSeg = pcall(buildSegment, lv)
		if not okSeg then warn("[EvaKMap] ошибка сегмента: " .. tostring(errSeg)) end
	end
	lv.ready = true
	print(string.format("[EvaKMap] новая карта #%d (%s) для %s", slot, diff, key))
	return lv
end

local function destroyLevel(lv)
	if lv.dead then return end
	lv.dead = true
	levels[lv.key] = nil
	usedSlots[lv.slot] = nil
	lv.model:Destroy()
end

-- ------------------------------------------------------------
-- Забеги игроков
-- ------------------------------------------------------------
local active: {[Player]: any} = {}
local pending: {[Player]: boolean} = {}      -- ждут выбора на экране результатов

local function releasePlayer(plr: Player)
	for _, lv in levels do
		if lv.players[plr] then
			lv.players[plr] = nil
			if next(lv.players) == nil then destroyLevel(lv) end
		end
	end
end

local revivable: {[Player]: any} = {}
local function endRun(plr: Player, success: boolean)
	local st = active[plr]
	if not st or st.ended then return end
	st.ended = true
	if st.hidden then st.hidden.occupant = nil end
	active[plr] = nil

	-- замораживаем игрока на месте (смерти нет: иначе Roblox сам возродит его в лобби)
	local char = plr.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if hrp then hrp.Anchored = true end
	local hum0 = char and char:FindFirstChildOfClass("Humanoid")
	local canRevive = (not success) and hrp ~= nil and hum0 ~= nil and hum0.Health > 0 and not st.lv.dead
	if canRevive then
		revivable[plr] = { st = st, pos = hrp.Position, items = plr:GetAttribute("RunItems") or "" }
	end

	local ev = ServerStorage:FindFirstChild(success and "RunCompleted" or "RunFailed")
	if ev then ev:Fire(plr) end
	if st.lv.endless then
		local ee = ServerStorage:FindFirstChild("EvaKEndlessResult")
		if ee then ee:Fire(plr, st.lv.broken) end
	end
	plr:SetAttribute("InMap", false)
	plr:SetAttribute("EvaKParkour", false)
	plr:SetAttribute("Difficulty", "")
	plr:SetAttribute("RunItems", "")
	pending[plr] = true
	local ending = (st.dmgTaken or 0) >= 100 and "demon" or "angel"   -- много урона за забег -> демон, мало -> ангел
	if success and st.finale then
		local ee = ServerStorage:FindFirstChild("EvaKEnding")
		if ee then ee:Fire(plr, ending) end
	end
	world:FireClient(plr, success and (st.finale and "TheEnd" or "Complete") or "Dead", success and st.finale and ending or nil)

	task.spawn(function()
		task.wait(0.7)   -- бейджи за забег начисляет EvaKServer
		if not plr.Parent then return end
		local earned = (st.diff == "newyear") and math.max(0, (plr:GetAttribute("Snow") or 0) - (st.startSnow or 0)) or math.max(0, (plr:GetAttribute("Badges") or 0) - st.startBadges)
		local t = st.runStart and (os.clock() - st.runStart) or 0
		local fin = success and st.finale == true
		world:FireClient(plr, "Results", { win = success, time = t, badges = earned, diff = st.diff, doors = st.lv.broken, total = TOTAL, canRevive = canRevive, finale = fin })
		if fin then
			task.wait(21)   -- THE END + три английские фразы, затем в лобби
			if pending[plr] and plr.Parent then
				pending[plr] = nil
				revivable[plr] = nil
				releasePlayer(plr)
				plr:LoadCharacter()
			end
			return
		end
		task.wait(180)   -- если игрок так и не нажал кнопку, возвращаем сами
		if pending[plr] and plr.Parent then
			pending[plr] = nil
			revivable[plr] = nil
			releasePlayer(plr)
			plr:LoadCharacter()
		end
	end)
end

local function startFinale(plr: Player, st)
	if st.finale then return end
	st.finale = true
	task.spawn(function()
		pcall(function()
			local r6 = ServerStorage:FindFirstChild("EvaKReached666")
			if r6 then r6:Fire(plr) end
			world:FireClient(plr, "Shake", 0.5)
			local fxr = ReplicatedStorage:FindFirstChild("EvaKExtraFx")
			if fxr then fxr:FireClient(plr, "Say", "Room 666. The throne is empty. EvaK is not here... yet.") end
			task.wait(6)
		end)
		endRun(plr, true)
	end)
end

local function spawnMonster(plr: Player, st, cfg)
	local lv = st.lv
	local hrp0 = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
	if not hrp0 or lv.dead then return false end
	local startZ = (hrp0.Position.Z - lv.O.Z) - 125     -- монстр летит СЗАДИ
	if startZ < z0 + 6 then return false end
	local mx = lv.O.X
	local z = startZ
	local m = buildMonster(lv.diff == "newyear")
	m.model.Parent = lv.model
	world:FireClient(plr, "Warn", 125 / cfg.speed)
	ach(plr, lv.diff == "newyear" and "santa" or "humanoid")
	if lv.diff == "newyear" then   -- «хо-хо-хо» тёмного Санты
		local hid = workspace:GetAttribute("NYSndHoHoHo")
		local host = m.model:FindFirstChildWhichIsA("BasePart")
		if type(hid) == "string" and hid ~= "" and host then
			local function ho()
				local sd = Instance.new("Sound")
				sd.SoundId = hid; sd.Volume = 1.8; sd.RollOffMaxDistance = 160; sd.Parent = host
				sd:Play(); Debris:AddItem(sd, 6)
			end
			ho()
			task.delay(3, function() if host.Parent then ho() end end)
		end
	end

	local t0 = os.clock()
	while active[plr] == st and not st.ended and not lv.dead and os.clock() - t0 < 24 do
		local dt = RunService.Heartbeat:Wait()
		z += cfg.speed * dt
		local tt = os.clock()
		m.render(CFrame.new(mx, lv.O.Y + 2.4 + math.sin(tt * 3) * 0.35, lv.O.Z + z) * CFrame.Angles(0, math.pi, 0), tt)

		local blocked = false
		for _, d in lv.doors do
			if not d.open and math.abs(z - d.z) < 2 then blocked = true end
		end
		if blocked then break end

		for p2, st2 in active do
			if st2.lv == lv then
				local c2 = p2.Character
				local hrp2 = c2 and c2:FindFirstChild("HumanoidRootPart")
				local hum2 = c2 and c2:FindFirstChildOfClass("Humanoid")
				if hrp2 and hum2 and hum2.Health > 0 and not st2.dropping and not st2.hidden then
					local pos = hrp2.Position
					if math.abs((pos.Z - lv.O.Z) - z) < 2.8 and math.abs(pos.X - mx) < CONFIG.MonsterWidth / 2 + 0.8 then
						local feet = pos.Y - (hum2.HipHeight + hrp2.Size.Y / 2)
						if feet < lv.O.Y + CONFIG.MonsterHeight - 0.2 then   -- коснулся = смерть (надо перепрыгнуть)
							world:FireClient(p2, "Scare")
							endRun(p2, false)
						end
					end
				end
			end
		end
		if z > lv.cur - 6 then break end
	end
	m.model:Destroy()
	return true
end

local function monsterLoop(plr: Player, st)
	local cfg = CONFIG.Monster[st.diff]
	-- монстр появляется 2-3 раза за ВЕСЬ забег (по числу выломанных дверей)
	local n = cfg.count
	local span = (TOTAL - 22) / n
	local marks = {}
	for i = 1, n do
		table.insert(marks, math.floor(8 + (i - 1) * span + rng:NextNumber(0, span * 0.7)))
	end
	local nextI = 1
	while nextI <= #marks and st.lv.broken >= marks[nextI] do nextI += 1 end   -- после возрождения старые метки пропускаем
	task.wait(6)
	while active[plr] == st and not st.ended and nextI <= #marks do
		task.wait(0.5)
		local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
		local bk = st.lv.broken
		local special = (bk >= ESC_FROM - 1 and bk < ESC_TO) or bk == BOSS_IDX - 1
		if hrp and not special and not st.dropping and not st.lv.dead and st.lv.broken >= marks[nextI] then
			local z = hrp.Position.Z - st.lv.O.Z
			if z > z0 + 140 and z < st.lv.cur - 40 then
				if spawnMonster(plr, st, cfg) then nextI += 1 end
			end
		end
	end
end

local function damagePlayer(plr: Player, st, amt: number)
	if st.ended then return end
	if plr:GetAttribute("EvaKGod") == true then return end   -- бог-режим из админки
	st.hp = math.max(0, (st.hp or 100) - amt)
	if amt < 1000 then st.dmgTaken = (st.dmgTaken or 0) + amt end   -- для концовки: демон / ангел
	world:FireClient(plr, "HP", st.hp)
	if st.hp <= 0 then
		world:FireClient(plr, "Scare")
		ach(plr, "die")
		endRun(plr, false)
	end
end

-- хуки для EvaKExtra (новые монстры/ивенты)
do
	local dmgEv = Instance.new("BindableEvent"); dmgEv.Name = "EvaKDamage"; dmgEv.Parent = ServerStorage
	dmgEv.Event:Connect(function(plr, amt)
		local st = active[plr]
		if st and not st.ended and type(amt) == "number" then damagePlayer(plr, st, amt) end
	end)
	local ar = Instance.new("BindableFunction"); ar.Name = "EvaKRunAdmin"; ar.Parent = ServerStorage   -- админ-действия над забегом
	ar.OnInvoke = function(cmd, plr)
		local st = active[plr]
		if not st or st.ended then return false end
		if cmd == "heal" then st.hp = 100; world:FireClient(plr, "HP", 100); return true
		elseif cmd == "kill" then damagePlayer(plr, st, 1e6); return true
		elseif cmd == "leave" then task.spawn(endRun, plr, false); return true end
		return false
	end
	local q = Instance.new("BindableFunction"); q.Name = "EvaKInRun"; q.Parent = ServerStorage
	q.OnInvoke = function(plr) local st = active[plr]; return st ~= nil and not st.ended end
end

-- ============================================================
-- РАНТАЙМ ОСОБЫХ СЕГМЕНТОВ: слизь-погоня, зомби-босс в столовой, еда, кресты
-- ============================================================
CONFIG.GrowlSoundId = "rbxassetid://9119864327"   -- рык зомби/слизи (замени на свой ID)
local PathfindingService = game:GetService("PathfindingService")

local function playSnd(parent: Instance, id: string, vol: number)
	local s = Instance.new("Sound")
	s.SoundId = id; s.Volume = vol; s.RollOffMaxDistance = 140
	s.Parent = parent
	s:Play()
	Debris:AddItem(s, 5)
end

-- ---------- слизь ----------
local SLIME_SPEED = { easy = 18, normal = 20, hard = 22, insane = 24, newyear = 24 }

local function buildSlime(xmas: boolean?)
	local model = Instance.new("Model")
	model.Name = "Slime"
	local recs = {}
	local function blob(name: string, size: Vector3, off: Vector3, col: Color3, mat: Enum.Material, tr: number?, refl: number?)
		local p = Instance.new("Part")
		p.Name = name; p.Size = size; p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.CastShadow = false
		p.Color = col; p.Material = mat; p.Transparency = tr or 0; p.Reflectance = refl or 0
		local m = Instance.new("SpecialMesh"); m.MeshType = Enum.MeshType.Sphere; m.Parent = p
		p.Parent = model
		table.insert(recs, { part = p, off = off, size = size, ph = rng:NextNumber(0, 6) })
		return p
	end
	local BLUE, GLOW = C(38, 120, 255), C(90, 190, 255)
	if xmas then BLUE, GLOW = C(236, 244, 255), C(150, 215, 255) end
	local body = blob("Body", Vector3.new(13, 9, 13), Vector3.new(0, 4.5, 0), BLUE, Enum.Material.SmoothPlastic, 0.2, 0.2)
	local core = blob("Core", Vector3.new(8, 5.5, 8), Vector3.new(0, 4, 0), GLOW, Enum.Material.Neon, 0.55)
	for k = 1, 7 do
		local a = k / 7 * math.pi * 2
		local sz = rng:NextNumber(4, 6.5)
		blob("Lobe", Vector3.new(sz, sz * 0.6, sz), Vector3.new(math.cos(a) * 5.6, sz * 0.3, math.sin(a) * 5.6), BLUE, Enum.Material.SmoothPlastic, 0.25, 0.15)
	end
	for _ = 1, 5 do
		local d = rng:NextNumber(1, 2.2)
		blob("Drop", Vector3.new(d, d * 1.4, d), Vector3.new(rng:NextNumber(-4.5, 4.5), rng:NextNumber(6, 9), rng:NextNumber(-3, 3)), GLOW, Enum.Material.Neon, 0.5)
	end
	-- один огромный красный глаз (смотрит вперёд, на игрока)
	blob("EyeRim", Vector3.new(7.2, 7.2, 1.8), Vector3.new(0, 5.6, 5.4), C(20, 80, 190), Enum.Material.SmoothPlastic, 0.3)
	blob("EyeWhite", Vector3.new(6.2, 6.2, 2.6), Vector3.new(0, 5.6, 6.0), C(255, 232, 226), Enum.Material.SmoothPlastic, 0, 0.1)
	blob("Iris", Vector3.new(3.8, 3.8, 1.3), Vector3.new(0, 5.6, 7.1), C(230, 12, 12), Enum.Material.Neon)
	blob("Pupil", Vector3.new(1.3, 3.0, 0.9), Vector3.new(0, 5.6, 7.75), C(0, 0, 0), Enum.Material.SmoothPlastic)
	blob("Glint", Vector3.new(0.7, 0.7, 0.5), Vector3.new(0.9, 6.5, 7.9), C(255, 255, 255), Enum.Material.Neon)
	local pl = Instance.new("PointLight"); pl.Color = C(90, 180, 255); pl.Range = 46; pl.Brightness = 2.4; pl.Shadows = false; pl.Parent = core
	local rl = Instance.new("PointLight"); rl.Color = C(255, 40, 30); rl.Range = 20; rl.Brightness = 1.2; rl.Shadows = false
	for _, r in recs do if r.part.Name == "Iris" then rl.Parent = r.part end end
	local pe = Instance.new("ParticleEmitter")
	pe.Rate = 22; pe.Lifetime = NumberRange.new(0.8, 1.5); pe.Speed = NumberRange.new(2, 6); pe.SpreadAngle = Vector2.new(180, 40)
	pe.EmissionDirection = Enum.NormalId.Top
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(1, 0) })
	pe.Color = ColorSequence.new(C(80, 170, 255)); pe.LightEmission = 0.6; pe.Acceleration = Vector3.new(0, -14, 0)
	pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"; pe.Parent = body
	local function render(pos: Vector3, t: number, rise: number)
		for _, r in recs do
			local sc = 1 + 0.05 * math.sin(t * 5 + r.ph)
			r.part.Size = r.size * sc
			r.part.Position = pos + Vector3.new(r.off.X, r.off.Y * (0.35 + 0.65 * rise) - (1 - rise) * 9, r.off.Z)
		end
	end
	return { model = model, render = render, body = body, recs = recs }
end

local function slimeLoop(lv, sl)
	local es = lv.escape
	local last = os.clock()
	local nextRoar, nextShake = 0, 0
	while lv.slime == sl and not lv.dead and sl.m.model.Parent do
		RunService.Heartbeat:Wait()
		local now = os.clock()
		local dt = math.min(0.1, now - last); last = now
		local age = now - sl.t0
		local tplr, tst, tz, tx
		for plr, st in active do
			if st.lv == lv and not st.ended and not st.dropping then
				local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
				if hrp then
					local z = hrp.Position.Z - lv.O.Z
					if not tz or z < tz then tplr, tst, tz, tx = plr, st, z, hrp.Position.X - lv.O.X end
				end
			end
		end
		if tz then
			local dist = tz - sl.z
			local sp = SLIME_SPEED[lv.diff] or 20
			if age < 1.8 then sp = 0 elseif dist > 85 then sp *= 1.5 end
			sl.z += sp * dt
			sl.x += (tx - sl.x) * math.min(1, dt * 2)
			if now > nextRoar then
				nextRoar = now + 6.5
				playSnd(sl.m.body, CONFIG.GrowlSoundId, 1.6)
			end
			if now > nextShake and dist < 60 then
				nextShake = now + 0.5
				for plr, st in active do if st.lv == lv then world:FireClient(plr, "Shake", math.clamp(1.2 - dist / 60, 0.15, 1)) end end
			end
			if age > 2.2 then   -- поймал
				for plr, st in active do
					if st.lv == lv and not st.ended and not st.hidden then
						local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
						if hrp then
							local dz = (hrp.Position.Z - lv.O.Z) - sl.z
							if dz < 6.5 and dz > -9 and math.abs((hrp.Position.X - lv.O.X) - sl.x) < 9 then
								world:FireClient(plr, "Scare")
								endRun(plr, false)
							end
						end
					end
				end
			end
			-- конец побега: слизь тонет
			if es.endZ and tz > es.endZ + 6 then
				es.done = true
				for plr, st in active do
					if st.lv == lv and not st.ended then
						local ev = ServerStorage:FindFirstChild("AwardBadges")
						if ev then ev:Fire(plr, 30) end
						world:FireClient(plr, "Loot", 30)
					end
				end
				break
			end
		end
		sl.m.render(lv.O + Vector3.new(sl.x, 0, sl.z), now, math.clamp(age / 2.4, 0, 1))
	end
	if lv.slime == sl then lv.slime = nil end
	for _, r in sl.m.recs do
		TweenService:Create(r.part, TweenInfo.new(1.2), { Transparency = 1 }):Play()
	end
	Debris:AddItem(sl.m.model, 1.4)
end

startSlimeHook = function(lv)
	if lv.slime or lv.dead then return end
	local es = lv.escape
	if not es or es.done then return end
	local m = buildSlime(lv.diff == "newyear")
	m.model.Parent = lv.model
	local sl = { m = m, z = es.drainZ, x = 0, t0 = os.clock() }
	lv.slime = sl
	es.started = true
	for plr, st in active do
		if st.lv == lv then
			world:FireClient(plr, "Warn", 4)
			world:FireClient(plr, "Shake", 1.2)
			ach(plr, "slime")
		end
	end
	task.spawn(slimeLoop, lv, sl)
end

-- ---------- зомби-босс ----------
local BOSS_SPEED = { easy = 17, normal = 20, hard = 23, insane = 26, newyear = 26 }   -- гуманоид быстрее
local BOSS_DMG = { easy = 18, normal = 24, hard = 32, insane = 42, newyear = 42 }
local BOSS_HP = { easy = 3, normal = 4, hard = 5, insane = 6, newyear = 6 }

local function buildZombie(xmas: boolean?)
	local model = Instance.new("Model")
	model.Name = "ZombieGirl"
	local SKIN, SKIN2 = C(66, 44, 34), C(84, 100, 82)
	local HAIR, DRESS = C(92, 58, 30), C(104, 112, 94)
	if xmas then DRESS = C(170, 26, 32) end
	local function mk(name: string, size: Vector3, col: Color3, mat: Enum.Material?, ball: boolean?): Part
		local p = Instance.new("Part")
		p.Name = name; p.Size = size; p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.CastShadow = false
		p.Color = col; p.Material = mat or Enum.Material.SmoothPlastic
		if ball then local m = Instance.new("SpecialMesh"); m.MeshType = Enum.MeshType.Sphere; m.Parent = p end
		p.Parent = model
		return p
	end
	local P = {}
	P.torso = mk("Torso", Vector3.new(1.9, 2.5, 1.0), DRESS, Enum.Material.Fabric)
	P.skirt = mk("Skirt", Vector3.new(2.3, 1.5, 1.4), DRESS, Enum.Material.Fabric)
	P.rag1 = mk("Rag", Vector3.new(0.5, 1.0, 0.1), DRESS, Enum.Material.Fabric)
	P.rag2 = mk("Rag", Vector3.new(0.5, 0.8, 0.1), DRESS, Enum.Material.Fabric)
	P.blood = mk("Blood", Vector3.new(1.0, 0.9, 0.1), C(110, 12, 12), Enum.Material.SmoothPlastic)
	P.neck = mk("Neck", Vector3.new(0.5, 0.6, 0.5), SKIN)
	P.head = mk("Head", Vector3.new(1.5, 1.7, 1.5), SKIN, nil, true)
	P.hair = mk("Hair", Vector3.new(1.95, 2.0, 1.95), HAIR, Enum.Material.Fabric, true)
	P.hairB = mk("HairBack", Vector3.new(1.8, 3.0, 0.5), HAIR, Enum.Material.Fabric)
	P.hairL = mk("HairSide", Vector3.new(0.4, 2.2, 0.5), HAIR, Enum.Material.Fabric)
	P.hairR = mk("HairSide", Vector3.new(0.4, 2.2, 0.5), HAIR, Enum.Material.Fabric)
	P.bangs = mk("Bangs", Vector3.new(1.6, 0.5, 0.3), HAIR, Enum.Material.Fabric)
	P.eyeL = mk("EyeL", Vector3.new(0.34, 0.26, 0.1), C(230, 250, 90), Enum.Material.Neon, true)
	P.eyeR = mk("EyeR", Vector3.new(0.34, 0.26, 0.1), C(230, 250, 90), Enum.Material.Neon, true)
	P.browL = mk("BrowL", Vector3.new(0.6, 0.12, 0.1), C(30, 18, 10))
	P.browR = mk("BrowR", Vector3.new(0.6, 0.12, 0.1), C(30, 18, 10))
	P.mouth = mk("Mouth", Vector3.new(0.8, 0.3, 0.1), C(40, 4, 4))
	P.teeth = mk("Teeth", Vector3.new(0.7, 0.12, 0.1), C(236, 230, 210))
	P.patch = mk("Patch", Vector3.new(0.55, 0.45, 0.1), SKIN2, nil, true)
	P.chin = mk("ChinBlood", Vector3.new(0.4, 0.55, 0.1), C(120, 10, 10))
	local sides = { "L", "R" }
	for _, s in sides do
		P["upArm" .. s] = mk("UpperArm", Vector3.new(0.5, 1.5, 0.5), SKIN)
		P["foreArm" .. s] = mk("Forearm", Vector3.new(0.45, 1.4, 0.45), SKIN)
		P["hand" .. s] = mk("Hand", Vector3.new(0.55, 0.55, 0.55), SKIN, nil, true)
		P["claw" .. s] = mk("Claw", Vector3.new(0.14, 0.6, 0.14), C(220, 214, 190))
		P["thigh" .. s] = mk("Thigh", Vector3.new(0.65, 1.7, 0.65), SKIN)
		P["shin" .. s] = mk("Shin", Vector3.new(0.55, 1.6, 0.55), SKIN)
		P["foot" .. s] = mk("Foot", Vector3.new(0.6, 0.3, 1.0), C(36, 26, 22))
	end
	if xmas then   -- новогодний наряд: шапка Санты и белая опушка
		P.hatBrim = mk("HatBrim", Vector3.new(2.1, 0.45, 2.1), C(246, 246, 250), Enum.Material.Fabric)
		P.hatA = mk("HatA", Vector3.new(1.7, 0.9, 1.7), C(190, 24, 30), Enum.Material.Fabric)
		P.hatB = mk("HatB", Vector3.new(1.1, 0.9, 1.1), C(190, 24, 30), Enum.Material.Fabric)
		P.pom = mk("Pom", Vector3.new(0.5, 0.5, 0.5), C(246, 246, 250), Enum.Material.Fabric, true)
		P.trim = mk("Trim", Vector3.new(2.5, 0.35, 1.55), C(246, 246, 250), Enum.Material.Fabric)
	end
	P.food = mk("FoodChunk", Vector3.new(0.5, 0.5, 0.5), C(120, 24, 20), nil, true)
	local pl = Instance.new("PointLight"); pl.Color = C(230, 250, 120); pl.Range = 9; pl.Brightness = 0.6; pl.Shadows = false; pl.Parent = P.head

	local function render(pivot: CFrame, t: number, pose: string, k: number)
		local sit, lean, hx, kx, rxL, rxR, exL, exR, hYaw, hPitch, mouth, rz = 0, 0, {0, 0}, {0, 0}, 0.2, 0.2, 0.3, 0.3, 0, 0, 0.1, 0.12
		local showFood = false
		local fall = 0
		if pose == "eat" then
			sit = 1; lean = 0.12 + math.sin(t * 3) * 0.04
			hx = { 1.5, 1.5 }; kx = { -1.5, -1.5 }
			rxR = 1.0 + 0.35 * math.sin(t * 4); exR = 2.0
			rxL = 0.8; exL = 1.0
			hPitch = 0.25 + math.sin(t * 4) * 0.12; mouth = 0.25 + 0.3 * math.abs(math.sin(t * 4))
			showFood = true
		elseif pose == "notice" then
			sit = 1 - math.min(1, k * 1.6); lean = 0.1 - 0.1 * k
			hx = { 1.5 * sit, 1.5 * sit }; kx = { -1.5 * sit, -1.5 * sit }
			rxL = 0.2 + k * 1.2; rxR = 0.2 + k * 1.2; exL = 0.4; exR = 0.4
			hYaw = 1.4 * (1 - math.min(1, k * 1.5)); mouth = 0.9
			rz = 0.12 + 0.2 * math.sin(t * 20) * k
		elseif pose == "chase" then
			local s = math.sin(t * 11)
			lean = 0.32
			hx = { 0.9 * s, -0.9 * s }; kx = { -math.max(0, -s) * 1.2, -math.max(0, s) * 1.2 }
			rxL = 1.5 + 0.35 * s; rxR = 1.5 - 0.35 * s; exL = 0.3; exR = 0.3
			hPitch = 0.3; mouth = 0.7 + 0.2 * math.sin(t * 16)
		elseif pose == "attack" then
			lean = 0.45; rxL = 1.8; rxR = 1.8; exL = 0.1; exR = 0.1; mouth = 1.0
			hx = { 0.6, -0.4 }; kx = { -0.3, -0.6 }
		elseif pose == "stagger" then
			lean = -0.35; rxL = 0.4 + math.sin(t * 14) * 0.5; rxR = 0.4 - math.sin(t * 14) * 0.5; exL = 0.8; exR = 0.8
			hPitch = -0.4; mouth = 1.0; hx = { -0.3, 0.3 }; kx = { -0.4, -0.2 }
		elseif pose == "fall" then
			fall = math.clamp(k, 0, 1)
			lean = 0; rxL = 0.3 + fall * 1.4; rxR = 0.3 + fall * 1.4; exL = 0.2; exR = 0.2
			hPitch = -0.2 * fall; mouth = 0.6 * (1 - fall); hx = { 0.2, -0.1 }; kx = { -0.2, -0.3 }
			rz = 0.2 + fall * 0.8
		end
		local drop = sit * 1.2
		local base = pivot
		if fall > 0 then   -- падает навзничь и остаётся лежать
			base = pivot * CFrame.new(0, 0.55 * fall, 0.6 * fall) * CFrame.Angles(fall * 1.5, 0, 0)
		end
		local hips = base * CFrame.new(0, 3.3 - drop, 0)
		local torso = hips * CFrame.Angles(lean, 0, 0) * CFrame.new(0, 1.3, 0)
		P.torso.CFrame = torso
		P.skirt.CFrame = hips * CFrame.new(0, -0.45, 0)
		P.rag1.CFrame = hips * CFrame.new(-0.7, -1.4, -0.65) * CFrame.Angles(0.1, 0, 0.1)
		P.rag2.CFrame = hips * CFrame.new(0.6, -1.3, -0.65) * CFrame.Angles(0.1, 0, -0.12)
		P.blood.CFrame = torso * CFrame.new(0.3, 0.1, -0.53) * CFrame.Angles(0, 0, 0.2)
		P.neck.CFrame = torso * CFrame.new(0, 1.45, 0)
		local head = torso * CFrame.new(0, 1.75, 0) * CFrame.Angles(hPitch, hYaw, 0) * CFrame.new(0, 0.7, 0)
		P.head.CFrame = head
		P.hair.CFrame = head * CFrame.new(0, 0.12, 0.15)
		P.hairB.CFrame = head * CFrame.new(0, -1.3, 0.85) * CFrame.Angles(-0.05, 0, 0)
		P.hairL.CFrame = head * CFrame.new(-0.95, -0.9, 0.3)
		P.hairR.CFrame = head * CFrame.new(0.95, -0.9, 0.3)
		P.bangs.CFrame = head * CFrame.new(0, 0.68, -0.72)
		if P.hatBrim then
			P.hatBrim.CFrame = head * CFrame.new(0, 0.95, 0.05)
			P.hatA.CFrame = head * CFrame.new(0, 1.45, 0.1) * CFrame.Angles(0, 0, -0.08)
			P.hatB.CFrame = head * CFrame.new(0.2, 2.2, 0.2) * CFrame.Angles(0, 0, -0.4)
			P.pom.CFrame = head * CFrame.new(0.75, 2.5, 0.25)
			P.trim.CFrame = hips * CFrame.new(0, -1.25, 0)
		end
		P.eyeL.CFrame = head * CFrame.new(-0.34, 0.1, -0.76); P.eyeR.CFrame = head * CFrame.new(0.34, 0.1, -0.76)
		P.browL.CFrame = head * CFrame.new(-0.36, 0.38, -0.78) * CFrame.Angles(0, 0, -0.45)
		P.browR.CFrame = head * CFrame.new(0.36, 0.38, -0.78) * CFrame.Angles(0, 0, 0.45)
		P.mouth.Size = Vector3.new(0.8, 0.15 + mouth * 0.5, 0.1)
		P.mouth.CFrame = head * CFrame.new(0, -0.35 - mouth * 0.12, -0.76)
		P.teeth.CFrame = head * CFrame.new(0, -0.22, -0.77)
		P.patch.CFrame = head * CFrame.new(0.55, -0.05, -0.74)
		P.chin.CFrame = head * CFrame.new(0.1, -0.7, -0.74)
		for i, s in sides do
			local sg = (s == "L") and -1 or 1
			local sh = torso * CFrame.new(sg * 1.2, 1.0, 0) * CFrame.Angles((s == "L") and rxL or rxR, 0, sg * rz)
			P["upArm" .. s].CFrame = sh * CFrame.new(0, -0.75, 0)
			local el = sh * CFrame.new(0, -1.5, 0) * CFrame.Angles((s == "L") and exL or exR, 0, 0)
			P["foreArm" .. s].CFrame = el * CFrame.new(0, -0.7, 0)
			P["hand" .. s].CFrame = el * CFrame.new(0, -1.45, 0)
			P["claw" .. s].CFrame = el * CFrame.new(0, -1.85, 0)
			local hj = hips * CFrame.new(sg * 0.55, -0.4, 0) * CFrame.Angles(hx[i], 0, 0)
			P["thigh" .. s].CFrame = hj * CFrame.new(0, -0.85, 0)
			local kj = hj * CFrame.new(0, -1.7, 0) * CFrame.Angles(kx[i], 0, 0)
			P["shin" .. s].CFrame = kj * CFrame.new(0, -0.8, 0)
			P["foot" .. s].CFrame = kj * CFrame.new(0, -1.65, -0.25)
		end
		P.food.Transparency = showFood and 0 or 1
		P.food.CFrame = base * CFrame.new(0.5, 3.6 - drop, -1.0)
		if showFood then
			local armR = torso * CFrame.new(1.2, 1.0, 0) * CFrame.Angles(rxR, 0, rz) * CFrame.new(0, -1.5, 0) * CFrame.Angles(exR, 0, 0) * CFrame.new(0, -1.45, 0)
			P.food.CFrame = armR
		end
	end
	render(CFrame.new(), 0, "eat", 0)
	return { model = model, render = render, head = P.head }
end

local FOODS = {
	{ "ROTTEN TOMATO", C(150, 40, 36), "ball", Vector3.new(0.9, 0.9, 0.9) },
	{ "MOLDY BREAD", C(96, 116, 70), "block", Vector3.new(1.3, 0.7, 0.8) },
	{ "SPOILED FISH", C(110, 128, 124), "block", Vector3.new(1.8, 0.35, 0.6) },
	{ "ROTTEN APPLE", C(104, 80, 28), "ball", Vector3.new(0.85, 0.85, 0.85) },
	{ "BAD CHEESE", C(176, 170, 60), "block", Vector3.new(1.0, 0.7, 0.9) },
}
local FOODS_NY = {
	{ "STALE GINGERBREAD", C(150, 96, 52), "block", Vector3.new(1.1, 0.25, 1.3) },
	{ "ROTTEN TANGERINE", C(150, 110, 30), "ball", Vector3.new(0.9, 0.9, 0.9) },
	{ "MOLDY CANDY CANE", C(130, 150, 110), "block", Vector3.new(0.35, 1.6, 0.35) },
	{ "BAD PUDDING", C(70, 40, 30), "ball", Vector3.new(1.0, 1.0, 1.0) },
	{ "SOUR EGGNOG", C(190, 184, 120), "block", Vector3.new(0.7, 1.0, 0.7) },
}
local function foodInfo(name: string)
	for _, f in FOODS do if f[1] == name then return f end end
	for _, f in FOODS_NY do if f[1] == name then return f end end
	return FOODS[1]
end

local function spawnFood(lv, spot: Vector3)
	local b = lv.boss
	if not b or not b.folder.Parent then return end
	local list = (lv.diff == "newyear") and FOODS_NY or FOODS
	local f = list[rng:NextInteger(1, #list)]
	local p = Instance.new("Part")
	p.Name = "RottenFood"; p.Size = f[4]; p.Color = f[2]; p.Material = Enum.Material.SmoothPlastic
	p.Anchored = true; p.CanCollide = false; p.CastShadow = false
	if f[3] == "ball" then p.Shape = Enum.PartType.Ball end
	p.CFrame = CFrame.new(lv.O + spot) * CFrame.Angles(rng:NextNumber(0, 3), rng:NextNumber(0, 3), 0)
	p.Parent = b.folder
	local pl = Instance.new("PointLight"); pl.Color = C(130, 220, 90); pl.Range = 9; pl.Brightness = 0.9; pl.Shadows = false; pl.Parent = p
	local pe = Instance.new("ParticleEmitter")
	pe.Rate = 4; pe.Lifetime = NumberRange.new(1.2, 2); pe.Speed = NumberRange.new(0.5, 1.2); pe.SpreadAngle = Vector2.new(30, 30)
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1.3) })
	pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(1, 1) })
	pe.Color = ColorSequence.new(C(120, 200, 80)); pe.LightEmission = 0.3
	pe.Texture = "rbxasset://textures/particles/smoke_main.dds"; pe.Parent = p
	local pp = Instance.new("ProximityPrompt")
	pp.ActionText = "Take"; pp.ObjectText = f[1]; pp.HoldDuration = 0
	pp.MaxActivationDistance = 7; pp.RequiresLineOfSight = false; pp.KeyboardKeyCode = Enum.KeyCode.E; pp.Style = Enum.ProximityPromptStyle.Custom   -- без окошка с «E», клавиша работает
	pp.Parent = p
	b.items += 1
	pp.Triggered:Connect(function(plr)
		local st = active[plr]
		if not st or st.lv ~= lv or st.food or st.ended then return end
		st.food = f[1]
		p:Destroy()
		b.items -= 1
		world:FireClient(plr, "Food", f[1])
	end)
end

local function bossRoar(b)
	if b.z and b.z.head.Parent then playSnd(b.z.head, CONFIG.GrowlSoundId, 1.8) end
end

local function bossBroadcast(lv, ...)
	for plr, st in active do
		if st.lv == lv then world:FireClient(plr, ...) end
	end
end

local function bossHit(lv)
	local b = lv.boss
	if not b or b.hp <= 0 or b.state == "dead" or b.state == "fall" then return end
	b.hp -= 1
	bossBroadcast(lv, "Boss", b.hp, b.maxhp)
	bossRoar(b)
	if b.hp <= 0 then
		b.state = "fall"; b.stateT = os.clock()
	else
		if b.state == "eat" then b.state = "notice"; b.stateT = os.clock() end
		b.stagger = os.clock() + 0.9
	end
end

local function splat(pos: Vector3, col: Color3, parent: Instance)
	local a = Instance.new("Part")
	a.Anchored = true; a.CanCollide = false; a.CanQuery = false; a.Transparency = 1; a.Size = Vector3.one; a.Position = pos; a.Parent = parent
	local pe = Instance.new("ParticleEmitter")
	pe.Rate = 0; pe.Lifetime = NumberRange.new(0.4, 0.9); pe.Speed = NumberRange.new(6, 14); pe.SpreadAngle = Vector2.new(180, 180)
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(1, 0) })
	pe.Color = ColorSequence.new(col); pe.Acceleration = Vector3.new(0, -30, 0)
	pe.Parent = a; pe:Emit(26)
	Debris:AddItem(a, 1.5)
end

local function throwFood(plr: Player, st, dir: Vector3)
	local lv = st.lv
	local char = plr.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp or not st.food then return end
	local info = foodInfo(st.food)
	st.food = nil
	world:FireClient(plr, "Food", nil)
	local b = lv.boss
	local parent = (b and b.folder.Parent) and b.folder or lv.model
	local p = Instance.new("Part")
	p.Name = "ThrownFood"; p.Size = info[4]; p.Color = info[2]; p.Material = Enum.Material.SmoothPlastic
	p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CastShadow = false
	if info[3] == "ball" then p.Shape = Enum.PartType.Ball end
	local pos = hrp.Position + Vector3.new(0, 1.4, 0) + dir * 2
	local vel = dir * 78 + Vector3.new(0, 7, 0)
	p.Position = pos; p.Parent = parent
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.FilterDescendantsInstances = { char, p }
	task.spawn(function()
		local t0 = os.clock()
		while os.clock() - t0 < 3 and p.Parent do
			local dt = RunService.Heartbeat:Wait()
			local np = pos + vel * dt
			vel += Vector3.new(0, -workspace.Gravity * 0.5 * dt, 0)
			if b and b.pos and b.state ~= "dead" and b.state ~= "fall" then
				local c = b.pos + Vector3.new(0, 3.2, 0)
				local seg = np - pos
				local tt = seg.Magnitude > 0 and math.clamp((c - pos):Dot(seg) / seg:Dot(seg), 0, 1) or 0
				if (pos + seg * tt - c).Magnitude < 3.1 then
					splat(np, info[2], parent)
					bossHit(lv)
					p:Destroy()
					return
				end
			end
			local hit = workspace:Raycast(pos, np - pos, rp)
			if hit then
				splat(hit.Position, info[2], parent)
				p:Destroy()
				return
			end
			pos = np
			p.CFrame = CFrame.new(pos) * CFrame.Angles(t0 * 3 + (os.clock() - t0) * 9, (os.clock() - t0) * 7, 0)
		end
		p:Destroy()
	end)
end

local function bossLoop(lv)
	local b = lv.boss
	local zb = b.z
	local last = os.clock()
	local pathT, itemT, lastAttack = 0, os.clock(), 0
	local waypoints, wpI = nil, 1
	local FLAT = Vector3.new(1, 0, 1)
	while lv.boss == b and not lv.dead and b.folder.Parent and zb.model.Parent do
		RunService.Heartbeat:Wait()
		local now = os.clock()
		local dt = math.min(0.1, now - last); last = now
		local tplr, tpos, tdist
		for plr, st in active do
			if st.lv == lv and not st.ended and not st.dropping then
				local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
				if hrp then
					local d = ((hrp.Position - b.pos) * FLAT).Magnitude
					if not tdist or d < tdist then tplr, tpos, tdist = plr, hrp.Position, d end
				end
			end
		end
		local pose, k = "eat", 0
		local toT = tpos and ((tpos - b.pos) * FLAT) or Vector3.zero
		if b.state == "eat" then
			b.dir = Vector3.zAxis
			if tdist and (tdist < 42 or (tpos.Z - lv.O.Z) > b.centerZ - 24) then
				b.state = "notice"; b.stateT = now
				bossRoar(b)
				bossBroadcast(lv, "Warn", 3); bossBroadcast(lv, "Shake", 1.0)
				bossBroadcast(lv, "Boss", b.hp, b.maxhp)
			end
		elseif b.state == "notice" then
			pose = "notice"; k = (now - b.stateT) / 2.2
			if toT.Magnitude > 0.5 then
				b.dir = (b.dir + (toT.Unit - b.dir) * math.min(1, dt * 3)).Unit
			end
			if k >= 1 then b.state = "chase"; b.stateT = now; bossRoar(b) end
		elseif b.state == "chase" then
			pose = "chase"
			if now < (b.stagger or 0) then
				pose = "stagger"
			elseif now < (b.attackUntil or 0) then
				pose = "attack"
			elseif tpos then
				if now - pathT > 0.5 and not b.pathBusy then
					pathT = now; b.pathBusy = true
					local from, to = b.pos + Vector3.new(0, 1, 0), Vector3.new(tpos.X, lv.O.Y + 1, tpos.Z)
					task.spawn(function()
						local ok = pcall(function()
							local path = PathfindingService:CreatePath({ AgentRadius = 2.2, AgentHeight = 6, AgentCanJump = false, WaypointSpacing = 5 })
							path:ComputeAsync(from, to)
							if path.Status == Enum.PathStatus.Success then waypoints = path:GetWaypoints(); wpI = 2 else waypoints = nil end
						end)
						if not ok then waypoints = nil end
						b.pathBusy = false
					end)
				end
				local goal = tpos
				if waypoints and waypoints[wpI] and tdist > 7 then
					goal = waypoints[wpI].Position
					if ((goal - b.pos) * FLAT).Magnitude < 2.4 then wpI += 1 end
				end
				local dv = (goal - b.pos) * FLAT
				if dv.Magnitude > 0.1 then
					local d = dv.Unit
					b.dir = (b.dir + (d - b.dir) * math.min(1, dt * 8)).Unit
					b.pos += b.dir * (BOSS_SPEED[lv.diff] or 16) * dt
				end
				if tdist < 4.8 and now - lastAttack > 1.3 then
					lastAttack = now
					b.attackUntil = now + 0.5
					local st = active[tplr]
					if st then
						damagePlayer(tplr, st, BOSS_DMG[lv.diff] or 24)
						local hrp = tplr.Character and tplr.Character:FindFirstChild("HumanoidRootPart")
						if hrp then hrp.AssemblyLinearVelocity = (b.dir * 38) + Vector3.new(0, 16, 0) end
						world:FireClient(tplr, "Shake", 1.2)
					end
					bossRoar(b)
				end
			end
			b.pos = Vector3.new(math.clamp(b.pos.X, lv.O.X - RW / 2 + 3, lv.O.X + RW / 2 - 3), lv.O.Y, math.clamp(b.pos.Z, lv.O.Z + b.zA + 3, lv.O.Z + b.zA + b.len - 5))
		elseif b.state == "fall" then
			pose = "fall"; k = (now - b.stateT) / 1.3
			if k >= 1 then
				b.state = "dead"; b.done = true
				bossBroadcast(lv, "Boss", nil)
				for plr, st in active do
					if st.lv == lv and not st.ended then
						ach(plr, "boss")
						local ev = ServerStorage:FindFirstChild("AwardBadges")
						if ev then ev:Fire(plr, 40) end
						world:FireClient(plr, "Loot", 40)
					end
				end
				for _, sp in b.shutterParts do
					if sp.Parent then
						TweenService:Create(sp, TweenInfo.new(2.4, Enum.EasingStyle.Quad), { Position = sp.Position + Vector3.new(0, RH + 6, 0) }):Play()
					end
				end
			end
		else
			pose = "fall"; k = 1
		end
		-- новые гнилые продукты (чтобы всегда хватало)
		if b.state ~= "dead" and b.state ~= "fall" and now - itemT > 4 and b.items < 3 then
			itemT = now
			for _ = 1, 2 do spawnFood(lv, b.spots[rng:NextInteger(1, #b.spots)]) end
		end
		local d = b.dir or Vector3.zAxis
		zb.render(CFrame.lookAt(b.pos, b.pos + d), now, pose, k)
	end
end

spawnBossHook = function(lv)
	local b = lv.boss
	if not b or b.spawned or lv.dead or not b.folder.Parent then return end
	b.spawned = true
	b.z = buildZombie(lv.diff == "newyear")
	b.z.model.Parent = b.folder
	b.maxhp = BOSS_HP[lv.diff] or 4
	b.hp = b.maxhp
	b.items = 0
	b.pos = lv.O + b.sitPos
	b.dir = Vector3.zAxis
	b.state = "eat"
	for _ = 1, b.maxhp + 3 do spawnFood(lv, b.spots[rng:NextInteger(1, #b.spots)]) end
	task.spawn(bossLoop, lv)
end

-- ---------- крест в комоде: взгляд = урон ----------
local function crossHit(plr: Player, inst: any)
	local st = active[plr]
	if not st or st.ended or st.dropping or st.hidden then return end
	if typeof(inst) ~= "Instance" or not CollectionService:HasTag(inst, "EvaKCross") or not inst:IsDescendantOf(workspace) then return end
	if inst:GetAttribute("Used") then return end
	local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
	if not hrp or (inst:GetPivot().Position - hrp.Position).Magnitude > 50 then return end
	inst:SetAttribute("Used", true)
	ach(plr, "cross")
	damagePlayer(plr, st, 50)
	world:FireClient(plr, "Shake", 2)
	local c = inst:GetPivot().Position
	splat(c, C(255, 80, 40), workspace)
	for _, ch in inst:GetDescendants() do
		if ch:IsA("BasePart") then ch.Color = C(30, 12, 8) end
	end
	Debris:AddItem(inst, 1.2)
end

-- ---------- новогодние шары (ивент): 10 РАЗНЫХ шаров ----------
-- 1 красный в белый горошек, 2 тёмно-зелёный с деревянным крестом, 3 синий со снежинкой, 4 золотой в полоску,
-- 5 зелёный со звездой, 6 фиолетовый с ромбами, 7 бело-красный леденцовый, 8 чёрный с красным глазом, 9 серебряный с колокольчиком, 10 бирюзовый с ёлкой
local BAUBLE_COL = {
	C(212, 28, 40), C(24, 70, 40), C(40, 100, 235), C(236, 190, 60), C(50, 170, 80),
	C(150, 60, 210), C(244, 244, 248), C(14, 12, 14), C(200, 206, 214), C(40, 190, 190),
}
local function baublePattern(kind: number, pos: Vector3, folder: Instance)
	local function put(size: Vector3, off: Vector3, col: Color3, mat: Enum.Material?, ball: boolean?, rot: number?)
		for _, sz in { -1, 1 } do   -- рисунок и спереди, и сзади
			local p = Instance.new("Part")
			p.Name = "NYBaublePat"; p.Size = size; p.Color = col; p.Material = mat or Enum.Material.SmoothPlastic
			p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.CastShadow = false
			if ball then p.Shape = Enum.PartType.Ball end
			p.CFrame = CFrame.new(pos + Vector3.new(off.X * sz, off.Y, off.Z * sz)) * CFrame.Angles(0, 0, (rot or 0))
			p.Parent = folder
		end
	end
	local W = C(250, 250, 252)
	if kind == 1 then
		for _, o in { Vector3.new(-0.4, 0.3, 0.9), Vector3.new(0.4, 0.4, 0.9), Vector3.new(0, -0.3, 0.95), Vector3.new(-0.5, -0.4, 0.8), Vector3.new(0.5, -0.4, 0.8) } do
			put(Vector3.one * 0.22, o, W, nil, true)
		end
	elseif kind == 2 then   -- деревянный крест
		put(Vector3.new(0.2, 1.1, 0.12), Vector3.new(0, 0, 0.95), C(120, 78, 44), Enum.Material.Wood)
		put(Vector3.new(0.7, 0.2, 0.12), Vector3.new(0, 0.2, 0.95), C(130, 86, 50), Enum.Material.Wood)
	elseif kind == 3 then   -- снежинка
		for _, r in { 0, 1.05, -1.05 } do put(Vector3.new(0.85, 0.1, 0.1), Vector3.new(0, 0, 0.95), W, Enum.Material.Neon, false, r) end
	elseif kind == 4 then   -- полоски
		for _, y in { -0.4, 0, 0.4 } do put(Vector3.new(1.5, 0.12, 0.14), Vector3.new(0, y, 0.78), C(200, 30, 36)) end
	elseif kind == 5 then   -- звезда
		put(Vector3.new(0.45, 0.45, 0.14), Vector3.new(0, 0, 0.95), C(255, 230, 90), Enum.Material.Neon, true)
		for _, r in { 0, 0.78 } do put(Vector3.new(0.9, 0.12, 0.12), Vector3.new(0, 0, 0.95), C(255, 230, 90), Enum.Material.Neon, false, r) end
	elseif kind == 6 then   -- ромбы
		for _, o in { Vector3.new(0, 0.35, 0.9), Vector3.new(0, -0.35, 0.9) } do put(Vector3.new(0.38, 0.38, 0.12), o, C(255, 210, 90), Enum.Material.Neon, false, 0.78) end
	elseif kind == 7 then   -- леденцовые полосы
		for _, x in { -0.5, 0, 0.5 } do put(Vector3.new(0.16, 1.5, 0.14), Vector3.new(x, 0, 0.8), C(210, 30, 40)) end
	elseif kind == 8 then   -- красный глаз
		put(Vector3.new(0.7, 0.7, 0.14), Vector3.new(0, 0, 0.95), C(255, 30, 30), Enum.Material.Neon, true)
		put(Vector3.new(0.16, 0.5, 0.1), Vector3.new(0, 0, 1.0), C(0, 0, 0), nil, true)
	elseif kind == 9 then   -- колокольчик
		put(Vector3.new(0.5, 0.5, 0.2), Vector3.new(0, -0.05, 0.95), C(240, 200, 80), Enum.Material.Metal, true)
		put(Vector3.new(0.12, 0.12, 0.1), Vector3.new(0, -0.3, 1.02), C(120, 90, 30), nil, true)
	elseif kind == 10 then   -- ёлочка
		for i, w in { 0.8, 0.55, 0.3 } do put(Vector3.new(w, 0.2, 0.12), Vector3.new(0, -0.3 + i * 0.28, 0.95), C(30, 130, 60)) end
		put(Vector3.new(0.12, 0.3, 0.1), Vector3.new(0, -0.4, 0.95), C(110, 70, 40))
	end
end

spawnBaubleHook = function(lv, x: number, z: number)
	if os.time() > (workspace:GetAttribute("EvaKNYEnd") or 0) then return end
	local folder = lv.model
	local pos = lv.O + Vector3.new(x, 3.6, z)
	local kind = rng:NextInteger(1, 10)
	local col = BAUBLE_COL[kind]
	local glow = (kind == 8) and C(255, 40, 30) or col
	local ball = Instance.new("Part")
	ball.Name = "NYBauble"; ball.Shape = Enum.PartType.Ball; ball.Size = Vector3.one * 1.9
	ball.Anchored = true; ball.CanCollide = false; ball.CanQuery = false; ball.CanTouch = false; ball.CastShadow = false
	ball.Color = col; ball.Material = Enum.Material.SmoothPlastic; ball.Reflectance = 0.35; ball.Position = pos
	ball.Parent = folder
	local cap = Instance.new("Part")
	cap.Name = "NYBaubleCap"; cap.Size = Vector3.new(0.5, 0.9, 0.9); cap.Anchored = true; cap.CanCollide = false; cap.CanQuery = false; cap.CanTouch = false
	cap.Color = C(240, 200, 90); cap.Material = Enum.Material.Metal; cap.CFrame = CFrame.new(pos + Vector3.new(0, 1.05, 0)) * CFrame.Angles(0, 0, math.pi / 2)
	cap.Shape = Enum.PartType.Cylinder; cap.Parent = folder
	baublePattern(kind, pos, folder)
	local pl = Instance.new("PointLight"); pl.Color = (kind == 8) and C(255, 40, 30) or C(255, 235, 200); pl.Range = 18; pl.Brightness = 1.8; pl.Shadows = false; pl.Parent = ball
	local pe = Instance.new("ParticleEmitter")
	pe.Rate = 8; pe.Lifetime = NumberRange.new(0.8, 1.4); pe.Speed = NumberRange.new(0.5, 1.5); pe.SpreadAngle = Vector2.new(180, 180)
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) })
	pe.Color = ColorSequence.new(glow:Lerp(C(255, 255, 255), 0.5)); pe.LightEmission = 1
	pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"; pe.Parent = ball
	local hit = Instance.new("Part")
	hit.Name = "NYBaubleHit"; hit.Size = Vector3.new(6, 7, 6); hit.Transparency = 1; hit.Anchored = true
	hit.CanCollide = false; hit.CanQuery = false; hit.CanTouch = true; hit.CastShadow = false
	hit.Position = pos; hit.Parent = folder
	local taken = false
	hit.Touched:Connect(function(o: BasePart)
		if taken then return end
		local plr = Players:GetPlayerFromCharacter(o.Parent)
		local st = plr and active[plr]
		if not st or st.lv ~= lv or st.ended or st.dropping then return end
		taken = true
		local ev = ServerStorage:FindFirstChild("EvaKBauble")
		if ev then ev:Fire(plr, kind) end
		local chime = workspace:GetAttribute("NYSndChime")
		if type(chime) == "string" and chime ~= "" then playSnd(folder, chime, 1.2) end
		splat(pos, col, folder)
		for _, ch in folder:GetChildren() do
			if ch.Name == "NYBaublePat" and (ch.Position - pos).Magnitude < 1.5 then ch:Destroy() end
		end
		ball:Destroy(); cap:Destroy(); hit:Destroy()
	end)
end

-- ---------- хуки (триггеры по Z) и счёт арок побега ----------
RunService.Heartbeat:Connect(function()
	for _, lv in levels do
		if not lv.dead then
			for plr, st in active do
				if st.lv == lv and st.curZ and not st.dropping and not st.ended then
					if lv.hooks then
						for _, h in lv.hooks do
							if not h.fired and st.curZ > h.z then
								h.fired = true
								task.spawn(h.fn)
							end
						end
					end
					for _, d in lv.doors do
						-- фантомная дверь: дверь, в которую ты вошёл, оборачиваясь, оказывается другой (≈1 из 100)
						if not d.arch and d.open and d.phantom == nil then d.phantom = (d.idx or 0) >= 8 and rng:NextNumber() < 0.01 end
						if d.phantom and not d.phFired and st.curZ > d.z + 18 then
							d.phFired = true
							local ph = Instance.new("Model"); ph.Name = "PhantomDoor"
							local function pp2(sz, pos, col, mat)
								local q = Instance.new("Part"); q.Anchored = true; q.Size = sz; q.Position = lv.O + pos; q.Color = col; q.Material = mat or Enum.Material.Wood; q.Parent = ph; return q
							end
							pp2(Vector3.new(5.2, 8.4, 1.2), Vector3.new(0, 4.2, d.z), Color3.fromRGB(26, 22, 22))
							pp2(Vector3.new(0.5, 8.6, 1.5), Vector3.new(-2.85, 4.3, d.z), Color3.fromRGB(14, 12, 12))
							pp2(Vector3.new(0.5, 8.6, 1.5), Vector3.new(2.85, 4.3, d.z), Color3.fromRGB(14, 12, 12))
							local lt = pp2(Vector3.new(6.2, 0.5, 1.5), Vector3.new(0, 8.6, d.z), Color3.fromRGB(14, 12, 12))
							local eye = pp2(Vector3.new(1.4, 1.4, 0.2), Vector3.new(0, 5.2, d.z + 0.7), Color3.fromRGB(255, 30, 20), Enum.Material.Neon)
							eye.Shape = Enum.PartType.Ball
							local gl = Instance.new("PointLight"); gl.Color = Color3.fromRGB(255, 40, 30); gl.Range = 22; gl.Brightness = 2; gl.Parent = eye
							ph.Parent = workspace
							Debris:AddItem(ph, 90)
							world:FireClient(st.plr or plr, "Shake", 0.9)
						end
						if d.arch and not d.counted and st.curZ > d.z then
							d.counted = true
							onDoorBroken(lv, d)
						end
					end
				end
			end
		end
	end
end)


local starting: {[Player]: boolean} = {}
do   -- ADMIN ABUSE: всех возвращаем в лобби (ServerStorage.EvaKRecall:Fire())
	local rcl = Instance.new("BindableEvent"); rcl.Name = "EvaKRecall"; rcl.Parent = ServerStorage
	rcl.Event:Connect(function()
		local list = {}
		for p in active do table.insert(list, p) end
		for _, p in list do task.spawn(endRun, p, false) end
	end)
end

local function startRun(plr: Player)
	if active[plr] or starting[plr] then return end
	starting[plr] = true
	local diff = plr:GetAttribute("Difficulty")
	local endless = (diff == "endless")
	if endless then diff = "insane"; plr:SetAttribute("Difficulty", "insane") end   -- таблицы урона/скорости считаем как INSANE
	plr:SetAttribute("EvaKEndless", endless)
	if type(diff) ~= "string" or not CONFIG.Monster[diff] then
		warn("[EvaKMap] у игрока нет сложности (EvaKServer не запущен?) — беру easy")
		diff = "easy"
		plr:SetAttribute("Difficulty", diff)
	end
	local char = plr.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum or hum.Health <= 0 then warn("[EvaKMap] нет персонажа") starting[plr] = nil return end
	print("[EvaKMap] старт забега:", plr.Name, diff)
	plr:SetAttribute("LastDiff", diff)

	pending[plr] = nil
	releasePlayer(plr)   -- на случай старой карты

	-- команда (party) играет на одной карте, одиночка — на своей
	local party = plr:GetAttribute("PartyId")
	local key = party and ("party" .. tostring(party)) or ("user" .. plr.UserId)
	local lv = levels[key]
	if not lv or lv.dead then
		withBuild(function()
			lv = levels[key]                      -- мог уже создать напарник
			if not lv or lv.dead then lv = newLevel(key, diff); if lv and endless then lv.endless = true end end
		end)
		lv = levels[key]   -- даже если постройка упала с ошибкой, берём то, что успело создаться
	end
	if not lv then starting[plr] = nil return end
	local waited = 0
	while not lv.ready and waited < 15 do waited += task.wait(0.1) end
	lv.players[plr] = true

	local st = { hp = 100, bandages = 3, medkits = 1, dmgTaken = 0, diff = diff, lv = lv, dropping = true, ended = false, dropT = os.clock(), startBadges = plr:GetAttribute("Badges") or 0, startSnow = plr:GetAttribute("Snow") or 0, curZ = z0 }
	active[plr] = st
	starting[plr] = nil
	plr:SetAttribute("InMap", true)

	char = plr.Character
	hrp = char and char:FindFirstChild("HumanoidRootPart")
	hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum then active[plr] = nil return end
	local pos = lv.O + Vector3.new(rng:NextNumber(-8, 8), CONFIG.DropHeight, rng:NextNumber(-8, 8))
	hrp.Anchored = false
	char:PivotTo(CFrame.lookAt(pos, pos + Vector3.new(0, 0, 1)))
	hrp.AssemblyLinearVelocity = Vector3.zero
	world:FireClient(plr, "Drop", lv.O.Z + z0, lv.endless and 0 or TOTAL)
	world:FireClient(plr, "HP", 100)
	world:FireClient(plr, "Items", 3, 1)
	world:FireClient(plr, "Doors", lv.endless and lv.broken or math.min(lv.broken, TOTAL), lv.endless and 0 or TOTAL)

	hum.Died:Once(function() endRun(plr, false) end)
	task.spawn(monsterLoop, plr, st)
end

world.OnServerEvent:Connect(function(plr: Player, kind: any, arg: any)
	if kind == "Begin" then
		startRun(plr)
	elseif kind == "Throw" then
		local st = active[plr]
		if not st or st.ended or st.dropping or st.hidden or not st.food then return end
		if typeof(arg) ~= "Vector3" or arg.Magnitude < 0.1 or arg.Magnitude ~= arg.Magnitude then return end
		local now = os.clock()
		if now - (st.lastThrow or 0) < 0.4 then return end
		st.lastThrow = now
		throwFood(plr, st, arg.Unit)
	elseif kind == "Bandage" or kind == "Medkit" then   -- лечение: бинт (+25 себе), аптечка (+60 ближайшему другу, иначе себе +45)
		local st = active[plr]
		if not st or st.ended or st.dropping or st.hidden then return end
		local now = os.clock()
		if now - (st.healCool or 0) < 1.2 then return end
		local function give(target: Player, ts, amt: number): boolean
			if ts.hp >= 100 then return false end
			ts.hp = math.min(100, ts.hp + amt)
			world:FireClient(target, "HP", ts.hp)
			world:FireClient(target, "HealFx")
			return true
		end
		if kind == "Bandage" then
			if (st.bandages or 0) <= 0 or not give(plr, st, 25) then return end
			st.bandages -= 1
		else
			if (st.medkits or 0) <= 0 then return end
			local me = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			local best, bd = nil, 16
			for other, os2 in active do
				if other ~= plr and not os2.ended and os2.hp < 100 then
					local h2 = other.Character and other.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
					if h2 and me and (h2.Position - me.Position).Magnitude < bd then best, bd = other, (h2.Position - me.Position).Magnitude end
				end
			end
			local done = false
			if best then done = give(best, active[best], 60) elseif give(plr, st, 45) then done = true end
			if not done then return end
			st.medkits -= 1
		end
		st.healCool = now
		world:FireClient(plr, "Items", st.bandages or 0, st.medkits or 0)
	elseif kind == "CrossHit" then
		crossHit(plr, arg)
	elseif kind == "EyesHit" then
		local st = active[plr]
		if not st or st.dropping or st.hidden or st.ended then return end
		local now = os.clock()
		if now - (st.lastEye or 0) < 0.3 then return end
		local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
		if not hrp then return end
		local near = false
		for _, em in (st.lv.eyeEnts or {}) do
			if em.Parent and (em:GetPivot().Position - hrp.Position).Magnitude < 140 then near = true; break end
		end
		if not near then return end
		ach(plr, "eyes")
		st.lastEye = now
		damagePlayer(plr, st, ({ easy = 5, normal = 7, hard = 10, insane = 14, newyear = 14 })[st.diff] or 7)
	elseif kind == "Revive" then
		local rv = revivable[plr]
		if not rv or not pending[plr] or active[plr] then return end
		local st = rv.st
		local lv = st.lv
		local char = plr.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if lv.dead or not hrp or not hum or hum.Health <= 0 then revivable[plr] = nil return end
		local useFn = ServerStorage:FindFirstChild("EvaKUseRevive")
		if not useFn or not useFn:Invoke(plr) then return end
		revivable[plr] = nil
		pending[plr] = nil
		local pos = rv.pos
		if st.fell then   -- упал в обрыв: ставим у последней выломанной двери
			local zBest = z0 + 8
			for _, d in lv.doors do
				if d.open and d.z > zBest and d.z < (st.curZ or 1e9) then zBest = d.z end
			end
			pos = lv.O + Vector3.new(0, 4, zBest + 3)
		else
			pos = pos + Vector3.new(0, 3, 0)
		end
		st.fell = nil; st.ended = false; st.hp = 100; st.hidden = nil; st.dropping = false; st.food = nil
		active[plr] = st
		if lv.slime then lv.slime.z = (pos.Z - lv.O.Z) - 50; lv.slime.t0 = os.clock() - 2.5 end
		hrp.Anchored = false
		hum.PlatformStand = false
		char:PivotTo(CFrame.lookAt(pos, pos + Vector3.new(0, 0, 1)))
		hrp.AssemblyLinearVelocity = Vector3.zero
		plr:SetAttribute("InMap", true)
		plr:SetAttribute("Difficulty", st.diff)
		plr:SetAttribute("RunItems", rv.items)
		local ev = ServerStorage:FindFirstChild("RunResumed")
		if ev then ev:Fire(plr) end
		world:FireClient(plr, "Revive")
		world:FireClient(plr, "HP", 100)
		world:FireClient(plr, "Doors", lv.endless and lv.broken or math.min(lv.broken, TOTAL), lv.endless and 0 or TOTAL)
		hum.Died:Once(function() endRun(plr, false) end)
		task.spawn(monsterLoop, plr, st)
	elseif kind == "Exit" then
		local st = active[plr]
		if st then
			st.ended = true
			active[plr] = nil
			local ev = ServerStorage:FindFirstChild("RunFailed")
			if ev then ev:Fire(plr) end
			plr:SetAttribute("InMap", false)
			plr:SetAttribute("Difficulty", "")
			plr:SetAttribute("RunItems", "")
		end
		pending[plr] = nil
		revivable[plr] = nil
		plr:SetAttribute("AutoPlay", false)
		releasePlayer(plr)
		plr:LoadCharacter()
	elseif (kind == "Lobby" or kind == "Again") and (pending[plr] or not active[plr]) then
		pending[plr] = nil
		revivable[plr] = nil
		plr:SetAttribute("AutoPlay", kind == "Again")
		releasePlayer(plr)
		plr:LoadCharacter()
	end
end)

local function glide(char: Model, to: CFrame, dur: number)
	local from = char:GetPivot()
	local t0 = os.clock()
	while true do
		local k = math.clamp((os.clock() - t0) / dur, 0, 1)
		char:PivotTo(from:Lerp(to, k * k * (3 - 2 * k)))
		if k >= 1 then break end
		RunService.Heartbeat:Wait()
	end
end

onHide = function(plr: Player, wd)
	local st = active[plr]
	if not st or st.dropping or st.ended or wd.busy then return end
	local char = plr.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not char or not hrp then return end
	if st.hidden and st.hidden ~= wd then return end
	if not st.hidden and wd.occupant and wd.occupant ~= plr then return end
	wd.busy = true
	local sx, Oo = wd.sx, wd.O
	local ok, err = pcall(function()
		local function look(p: Vector3, dx: number, dz: number): CFrame
			return CFrame.lookAt(p, p + Vector3.new(dx, 0, dz))
		end
		if not st.hidden then
			st.hidden = wd; wd.occupant = plr
			hrp.AssemblyLinearVelocity = Vector3.zero
			hrp.Anchored = true
			local doorP = Oo + wd.door
			glide(char, look(Vector3.new(doorP.X, hrp.Position.Y, doorP.Z), sx, 0), 0.35)   -- подходим к дверкам
			wd.swing(0, 1.8, 0.5)                                                          -- створки открываются
			glide(char, look(Oo + wd.pos, sx, 0), 0.65)                                    -- заходим
			glide(char, look(Oo + wd.pos, -sx, 0), 0.45)                                   -- разворачиваемся лицом к щели
			wd.swing(1.8, 0, 0.5)                                                          -- створки закрываются
			wd.prompt.ActionText = "Leave"
			world:FireClient(plr, "Hide", true)
			task.spawn(function()   -- сидишь в шкафу дольше 10 секунд: сердце не выдерживает
				local t0 = os.clock()
				while st.hidden == wd and not st.ended and plr.Parent do
					task.wait(1)
					if st.hidden == wd and os.clock() - t0 > 10 then damagePlayer(plr, st, 6) end
				end
			end)
		else
			world:FireClient(plr, "Hide", false)
			wd.swing(0, 1.8, 0.45)
			glide(char, look(Oo + wd.out, -sx, 0), 0.6)                                    -- выходим
			glide(char, look(Oo + wd.out, 0, 1), 0.25)
			hrp.Anchored = false
			st.hidden = nil; wd.occupant = nil
			wd.prompt.ActionText = "Hide"
			wd.swing(1.8, 0, 0.45)
		end
	end)
	if not ok then
		warn("[EvaKMap] шкаф:", err)
		if hrp then hrp.Anchored = false end
		st.hidden = nil; wd.occupant = nil
		world:FireClient(plr, "Hide", false)
	end
	wd.busy = false
end

onLoot = function(plr: Player, box)
	local st = active[plr]
	if not st or st.ended then return end
	local ev = ServerStorage:FindFirstChild("AwardBadges")
	if ev then ev:Fire(plr, box.amount) end
	world:FireClient(plr, "Loot", box.amount)
	-- бонус: аптечка из ящика
	if rng:NextNumber() < 0.35 and (st.hp or 100) < 100 then
		st.hp = math.min(100, (st.hp or 100) + 25)
		world:FireClient(plr, "HP", st.hp)
		world:FireClient(plr, "LootNote", "+25 HP")
	end
end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

RunService.Heartbeat:Connect(function()
	-- карта: достраиваем вперёд, удаляем позади
	for _, lv in levels do
		local any, maxZ, minZ = false, -1e9, 1e9
		for plr, st in active do
			if st.lv == lv then
any = true
local cz = st.dropping and z0 or (st.curZ or z0)
maxZ = math.max(maxZ, cz)
minZ = math.min(minZ, cz)
end
		end
		if any and not lv.dead then
			if not lv.complete and not lv.building and not buildBusy and lv.ready and lv.cur < maxZ + CONFIG.BuildAhead then
				lv.building = true
				task.spawn(function()
					withBuild(function() buildSegment(lv) end)
					lv.building = false
				end)
			end
			for i = #lv.segs, 1, -1 do
				local sg = lv.segs[i]
				if sg.z1 < minZ - CONFIG.KeepBehind then
					sg.folder:Destroy()
					table.remove(lv.segs, i)
				end
			end
			if lv.shaft and minZ > z0 + 330 then lv.shaft:Destroy(); lv.shaft = nil end
		end
	end

	-- игроки
	for plr, st in active do
		local lv = st.lv
		local char = plr.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hrp and hum and hum.Health > 0 and not lv.dead then
			if st.dropping then
				local v = hrp.AssemblyLinearVelocity
				if v.Y < -CONFIG.FallSpeed then
					hrp.AssemblyLinearVelocity = Vector3.new(v.X, -CONFIG.FallSpeed, v.Z)
				end
				rayParams.FilterDescendantsInstances = { char }
				if os.clock() - st.dropT > 0.6 and workspace:Raycast(hrp.Position, Vector3.new(0, -(hum.HipHeight + 3.2), 0), rayParams) then
					st.dropping = false
					st.runStart = os.clock()
					char:SetAttribute("StunUntil", os.clock() + CONFIG.StunAfterLand)
					char:SetAttribute("Crouch", true)
					world:FireClient(plr, "Landed")
					task.delay(CONFIG.StunAfterLand, function() char:SetAttribute("Crouch", false) end)
				end
			else
				local zr = hrp.Position.Z - lv.O.Z
				st.curZ = zr
				do   -- паркур: в этих коридорах скорость сразу постоянная, без разгона
					local inP = false
					for _, zz in lv.obst or {} do if zr >= zz[1] and zr <= zz[2] then inP = true; break end end
					if plr:GetAttribute("EvaKParkour") ~= inP then plr:SetAttribute("EvaKParkour", inP) end
				end
				if hrp.Position.Y < lv.O.Y - 45 then
					st.fell = true
					endRun(plr, false)            -- упал в обрыв
				elseif lv.finishZ and zr > lv.finishZ then
					endRun(plr, true)
				elseif lv.finaleZ and zr > lv.finaleZ and not st.finale and not st.hidden then
					startFinale(plr, st)
				end
			end
		end
	end
end)

task.spawn(function()   -- манекены в бальном зале поворачиваются за игроком
	while true do
		task.wait(0.1)
		for lv, set in mannequinSets do
			if lv.dead then mannequinSets[lv] = nil continue end
			local nearest: {Vector3} = {}
			for plr in lv.players do
				local h = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
				if h then table.insert(nearest, h.Position) end
			end
			if #nearest > 0 then
				for _, m in set do
					local best, bd = nearest[1], math.huge
					for _, pos in nearest do local d = (pos - m.center).Magnitude; if d < bd then best, bd = pos, d end end
					if bd < 90 then
						local dx, dz = best.X - m.center.X, best.Z - m.center.Z
						local target = math.atan2(-dx, -dz)
						local diff = (target - m.yaw + math.pi) % (math.pi * 2) - math.pi
						m.yaw += math.clamp(diff, -0.06, 0.06)
						local base = CFrame.new(m.center) * CFrame.Angles(0, m.yaw, 0)
						for _, pp in m.parts do if pp.p.Parent then pp.p.CFrame = base * CFrame.new(pp.off) end end
					end
				end
			end
		end
	end
end)

Players.PlayerRemoving:Connect(function(plr)
	local st = active[plr]
	if st then st.ended = true end
	active[plr] = nil
	pending[plr] = nil
	starting[plr] = nil
	releasePlayer(plr)
end)

print("[EvaKMap] готово: каждая катка получает новую случайную карту. Дверей до выхода:", TOTAL)
