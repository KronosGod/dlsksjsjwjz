-- ============================================================
--  EvaKHotelIntro  (LocalScript в StarterPlayerScripts)
--  3D-сцена перед вступительным текстом: ночь, отель «EvaK Hotel» весь в паутине,
--  персонаж идёт по дорожке (камера сбоку), открывает дверь, заходит, дверь за ним захлопывается.
--  Всё собирается кодом внутри ViewportFrame, ассеты не нужны.
--  Запуск: GraceIntro ставит атрибут игрока EvaKPlayHotel, по окончании этот скрипт ставит EvaKHotelDone.
--  Пропуск: кнопка SKIP или Пробел.
-- ============================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local CFG = {
	DoorOpenSoundId = "rbxassetid://4842621355",   -- скрип двери (необязательно)
	DoorSlamSoundId = "rbxassetid://138186576",   -- хлопок двери (необязательно)
	WindSoundId = "rbxassetid://2662419014",       -- ветер на фоне (необязательно)
	Volume = 0.8,
}

local C3 = Color3.fromRGB
local M = Enum.Material
local X, Y, Z = Vector3.xAxis, Vector3.yAxis, Vector3.zAxis

local built = 0
local function part(parent: Instance, size: Vector3, cf: CFrame, color: Color3, mat: Enum.Material?, tr: number?)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = mat or M.Concrete
	p.Transparency = tr or 0
	p.Parent = parent
	built += 1
	if built % 220 == 0 then task.wait() end
	return p
end

local function seg(parent: Instance, a: Vector3, b: Vector3, th: number, color: Color3, tr: number?, mat: Enum.Material?)
	local d = (b - a).Magnitude
	if d < 0.05 then return nil end
	return part(parent, Vector3.new(th, th, d), CFrame.lookAt((a + b) / 2, b), color, mat or M.Neon, tr)
end

local function sstep(a: number, b: number, t: number): number
	local u = math.clamp((t - a) / (b - a), 0, 1)
	return u * u * (3 - 2 * u)
end

local function snd(id: string, vol: number?)
	if id == nil or id == "" then return end
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = (vol or 1) * CFG.Volume
	s.Parent = SoundService
	s:Play()
	task.delay(8, function() s:Destroy() end)
end

-- ===== паутина: веер (угол) или полная «колесом» =====
local WEBC = C3(196, 200, 212)
local function web(parent: Instance, o: Vector3, u: Vector3, v: Vector3, r: number, spokes: number, rings: number, full: boolean)
	local rnd = Random.new(math.floor(o.X * 7 + o.Y * 13 + o.Z * 17) + spokes)
	local a1 = full and math.pi * 2 or math.pi / 2
	local count = full and spokes or (spokes - 1)
	local pts = {}
	for k = 0, rings do
		pts[k] = {}
		for i = 0, spokes - 1 do
			local ang = a1 * i / (full and spokes or count)
			local rad = r * k / rings * (k == 0 and 0 or (0.82 + rnd:NextNumber() * 0.3))
			pts[k][i] = o + (u * math.cos(ang) + v * math.sin(ang)) * rad + Vector3.new(0, -0.05 * rad * rad / r, 0)
		end
	end
	for k = 1, rings do
		for i = 0, spokes - 1 do
			seg(parent, pts[k - 1][i], pts[k][i], 0.07, WEBC, 0.4)
			local nxt = i + 1
			if nxt >= spokes then nxt = full and 0 or nil end
			if nxt then seg(parent, pts[k][i], pts[k][nxt], 0.05, WEBC, 0.5) end
		end
	end
end

local function tree(parent: Instance, x: number, z: number, h: number, lean: number)
	local rnd = Random.new(math.floor(x * 31 + z * 17))
	local base = CFrame.new(x, 0, z) * CFrame.Angles(0, 0, math.rad(lean))
	local wood = C3(22, 17, 14)
	part(parent, Vector3.new(1.5, h, 1.5), base * CFrame.new(0, h / 2, 0), wood, M.Wood)
	for i = 1, 7 do
		local a = base:PointToWorldSpace(Vector3.new(0, h * (0.3 + 0.1 * i), 0))
		local ang = rnd:NextNumber() * math.pi * 2
		local len = 3 + rnd:NextNumber() * 4
		local b = a + Vector3.new(math.cos(ang), 0.8, math.sin(ang)).Unit * len
		seg(parent, a, b, 0.4, wood, 0, M.Wood)
		local c = b + Vector3.new(math.cos(ang + 0.9), 0.7, math.sin(ang + 0.9)).Unit * (len * 0.6)
		seg(parent, b, c, 0.22, wood, 0, M.Wood)
	end
end

-- ===== сборка всей сцены =====
local function buildHotel(root: Instance)
	local S = { glow = {}, lamps = {}, bats = {}, doorWebs = {} }
	local brick, trim, slate = C3(76, 61, 57), C3(40, 32, 32), C3(28, 25, 30)
	local rnd = Random.new(7)

	part(root, Vector3.new(1800, 1, 1800), CFrame.new(0, -0.5, 0), C3(26, 34, 27), M.Grass)
	part(root, Vector3.new(7, 0.2, 80), CFrame.new(0, 0.1, 38), C3(54, 52, 50), M.Cobblestone)
	for i = 1, 30 do
		part(root, Vector3.new(1.6 + rnd:NextNumber(), 0.3, 1 + rnd:NextNumber() * 0.7), CFrame.new((rnd:NextNumber() - 0.5) * 5.5, 0.18, 4 + i * 2.4) * CFrame.Angles(0, rnd:NextNumber(), 0), C3(70 + rnd:NextInteger(0, 20), 68, 64), M.Slate)
	end

	-- фасад: левая и правая части + перемычка над дверным проёмом
	part(root, Vector3.new(23.5, 26, 20), CFrame.new(-14.25, 13, -10), brick, M.Brick)
	part(root, Vector3.new(23.5, 26, 20), CFrame.new(14.25, 13, -10), brick, M.Brick)
	part(root, Vector3.new(5, 16.5, 20), CFrame.new(0, 17.75, -10), brick, M.Brick)
	part(root, Vector3.new(5, 9.5, 0.4), CFrame.new(0, 4.75, -6.2), C3(16, 11, 11), M.Brick)
	local hall = part(root, Vector3.new(3.6, 7, 0.1), CFrame.new(0, 5, -5.95), C3(255, 170, 80), M.Neon, 0.35)
	S.hall = hall
	part(root, Vector3.new(54, 1.2, 2.2), CFrame.new(0, 26.4, 0.9), trim, M.Concrete)
	part(root, Vector3.new(54, 1.5, 1.4), CFrame.new(0, 0.75, 0.3), trim, M.Concrete)

	-- двускатная крыша
	local ang = math.atan2(6, 10)
	part(root, Vector3.new(56, 1, 12), CFrame.new(0, 29.2, -4.6) * CFrame.Angles(ang, 0, 0), slate, M.Slate)
	part(root, Vector3.new(56, 1, 12), CFrame.new(0, 29.2, -15.4) * CFrame.Angles(-ang, 0, 0), slate, M.Slate)
	part(root, Vector3.new(2.6, 3.2, 2.6), CFrame.new(-15, 31, -12), brick, M.Brick)
	part(root, Vector3.new(2.6, 3.2, 2.6), CFrame.new(16, 30.5, -9), brick, M.Brick)

	-- часовая башня
	part(root, Vector3.new(12, 22, 12), CFrame.new(0, 38, -13), brick, M.Brick)
	part(root, Vector3.new(14, 1, 14), CFrame.new(0, 49.5, -13), trim, M.Concrete)
	part(root, Vector3.new(10, 2.4, 10), CFrame.new(0, 51, -13), slate, M.Slate)
	part(root, Vector3.new(6.5, 2.4, 6.5), CFrame.new(0, 53.4, -13), slate, M.Slate)
	part(root, Vector3.new(3, 2.6, 3), CFrame.new(0, 55.8, -13), slate, M.Slate)
	part(root, Vector3.new(0.5, 4, 0.5), CFrame.new(0, 59, -13), C3(30, 30, 34), M.Metal)
	local clock = part(root, Vector3.new(0.4, 7, 7), CFrame.new(0, 42, -6.9) * CFrame.Angles(0, 0, 0), C3(205, 196, 168), M.SmoothPlastic)
	clock.Shape = Enum.PartType.Cylinder
	clock.CFrame = CFrame.new(0, 42, -6.9) * CFrame.Angles(0, math.pi / 2, 0)
	part(root, Vector3.new(0.3, 2.8, 0.3), CFrame.new(0, 43.3, -6.7), C3(20, 20, 20), M.Metal)
	part(root, Vector3.new(2.4, 0.3, 0.3), CFrame.new(1.1, 42, -6.7), C3(20, 20, 20), M.Metal)
	for _, wx in { -2.6, 2.6 } do
		part(root, Vector3.new(1.6, 4, 0.3), CFrame.new(wx, 34, -6.9), C3(12, 14, 20), M.SmoothPlastic)
	end
	local tg = part(root, Vector3.new(1.2, 3.4, 0.2), CFrame.new(0, 34, -6.85), C3(255, 196, 100), M.Neon, 0.3)
	table.insert(S.glow, { p = tg, base = 0.3, seed = 91 })

	-- окна
	local lit = { [3] = true, [9] = true, [14] = true, [18] = true, [23] = true }
	local idx = 0
	local function window(wx: number, wy: number)
		idx += 1
		part(root, Vector3.new(4.1, 5.3, 0.5), CFrame.new(wx, wy, 0.2), trim, M.Wood)
		local isLit = lit[idx] == true
		local glass = part(root, Vector3.new(3.3, 4.5, 0.3), CFrame.new(wx, wy, 0.35), isLit and C3(255, 196, 100) or C3(11, 15, 22), isLit and M.Neon or M.SmoothPlastic, isLit and 0.25 or 0)
		if isLit then table.insert(S.glow, { p = glass, base = 0.25, seed = idx }) end
		part(root, Vector3.new(3.3, 0.25, 0.2), CFrame.new(wx, wy, 0.5), trim, M.Wood)
		part(root, Vector3.new(0.25, 4.5, 0.2), CFrame.new(wx, wy, 0.5), trim, M.Wood)
		if idx % 5 == 2 then   -- заколочено досками
			part(root, Vector3.new(5, 0.5, 0.25), CFrame.new(wx, wy + 0.4, 0.62) * CFrame.Angles(0, 0, 0.35), C3(60, 44, 30), M.WoodPlanks)
			part(root, Vector3.new(5, 0.5, 0.25), CFrame.new(wx, wy - 0.5, 0.68) * CFrame.Angles(0, 0, -0.3), C3(54, 40, 28), M.WoodPlanks)
		end
		if idx % 2 == 1 then web(root, Vector3.new(wx, wy, 0.8), X, Y, 2.5, 8, 3, true) end
	end
	for _, wy in { 6, 13.5 } do for _, wx in { -21, -15, 15, 21 } do window(wx, wy) end end
	for _, wx in { -21, -15, -9, 0, 9, 15, 21 } do window(wx, 22.2) end

	-- крыльцо, колонны, ступени
	part(root, Vector3.new(16, 1, 14), CFrame.new(0, 0.5, 1), C3(60, 58, 56), M.Concrete)
	part(root, Vector3.new(14, 0.5, 2.2), CFrame.new(0, 0.25, 9.6), C3(56, 54, 52), M.Concrete)
	part(root, Vector3.new(18, 1, 10), CFrame.new(0, 14.5, 3.5), slate, M.Slate)
	part(root, Vector3.new(18.6, 0.6, 10.6), CFrame.new(0, 13.8, 3.5), trim, M.Concrete)
	for _, px in { -7, 7 } do
		local col = part(root, Vector3.new(13, 1.7, 1.7), CFrame.new(px, 7.5, 7.5), C3(98, 92, 84), M.Concrete)
		col.Shape = Enum.PartType.Cylinder
		col.CFrame = CFrame.new(px, 7.5, 7.5) * CFrame.Angles(0, 0, math.pi / 2)
		part(root, Vector3.new(2.6, 0.6, 2.6), CFrame.new(px, 1.3, 7.5), C3(84, 80, 74), M.Concrete)
		part(root, Vector3.new(2.6, 0.6, 2.6), CFrame.new(px, 14, 7.5), C3(84, 80, 74), M.Concrete)
	end
	web(root, Vector3.new(-7, 13.6, 8.1), X, -Y, 4, 6, 3, false)
	web(root, Vector3.new(7, 13.6, 8.1), -X, -Y, 4, 6, 3, false)
	for i = 1, 5 do
		local sx = -6 + i * 2
		seg(root, Vector3.new(sx, 13.6, 8.2), Vector3.new(sx + (rnd:NextNumber() - 0.5), 13.6 - 2 - rnd:NextNumber() * 3, 8.2), 0.05, WEBC, 0.45)
	end

	-- дверь (створка вращается вокруг петли)
	S.hinge = CFrame.new(-2.5, 5.25, 0.1)
	S.doorParts = {}
	local function dp(size: Vector3, off: CFrame, color: Color3, mat: Enum.Material)
		local p = part(root, size, S.hinge, color, mat)
		table.insert(S.doorParts, { p = p, off = off })
		return p
	end
	dp(Vector3.new(5, 8.5, 0.4), CFrame.new(2.5, 0, 0), C3(66, 40, 28), M.WoodPlanks)
	dp(Vector3.new(1.9, 3.2, 0.12), CFrame.new(1.3, 1.9, 0.24), C3(46, 28, 20), M.Wood)
	dp(Vector3.new(1.9, 3.2, 0.12), CFrame.new(3.7, 1.9, 0.24), C3(46, 28, 20), M.Wood)
	dp(Vector3.new(1.9, 3.2, 0.12), CFrame.new(1.3, -2, 0.24), C3(46, 28, 20), M.Wood)
	dp(Vector3.new(1.9, 3.2, 0.12), CFrame.new(3.7, -2, 0.24), C3(46, 28, 20), M.Wood)
	local knob = dp(Vector3.new(0.5, 0.5, 0.5), CFrame.new(4.3, -0.4, 0.4), C3(190, 150, 60), M.Metal)
	knob.Shape = Enum.PartType.Ball
	part(root, Vector3.new(0.5, 9.5, 0.7), CFrame.new(-2.75, 5.25, 0.2), trim, M.Wood)
	part(root, Vector3.new(0.5, 9.5, 0.7), CFrame.new(2.75, 5.25, 0.2), trim, M.Wood)
	part(root, Vector3.new(6, 0.5, 0.7), CFrame.new(0, 9.75, 0.2), trim, M.Wood)
	local dwb = { { Vector3.new(-2.3, 9.4, 0.55), X }, { Vector3.new(2.3, 9.4, 0.55), -X } }
	for _, w in dwb do
		local before = #root:GetChildren()
		web(root, w[1], w[2], -Y, 2.6, 6, 3, false)
		local kids = root:GetChildren()
		for i = before + 1, #kids do table.insert(S.doorWebs, kids[i]) end
	end

	-- вывеска
	local signCF = CFrame.new(0, 19, 0.8) * CFrame.Angles(0, 0, math.rad(-2.5))
	S.signCF = signCF
	part(root, Vector3.new(14.5, 3.8, 0.6), signCF, C3(36, 24, 18), M.WoodPlanks)
	for _, e in { { 14.9, 0.3, 0, 1.95 }, { 14.9, 0.3, 0, -1.95 }, { 0.3, 4.1, 7.3, 0 }, { 0.3, 4.1, -7.3, 0 } } do
		part(root, Vector3.new(e[1], e[2], 0.8), signCF * CFrame.new(e[3], e[4], 0.05), C3(150, 120, 52), M.Metal)
	end
	web(root, signCF:PointToWorldSpace(Vector3.new(-7.2, 1.9, 0.5)), X, -Y, 3.2, 6, 3, false)
	web(root, signCF:PointToWorldSpace(Vector3.new(7.2, 1.9, 0.5)), -X, -Y, 3.2, 6, 3, false)

	-- паутина по фасаду и свисающие нити
	web(root, Vector3.new(-26, 26, 0.5), X, -Y, 9, 7, 4, false)
	web(root, Vector3.new(26, 26, 0.5), -X, -Y, 9, 7, 4, false)
	web(root, Vector3.new(-26, 0.8, 0.5), X, Y, 6, 6, 3, false)
	web(root, Vector3.new(26, 0.8, 0.5), -X, Y, 6, 6, 3, false)
	for i = 1, 16 do
		local sx = -25 + i * 3.1
		local top = Vector3.new(sx, 26, 1.5)
		seg(root, top, top + Vector3.new((rnd:NextNumber() - 0.5) * 1.5, -(2 + rnd:NextNumber() * 6), 0.3), 0.06, WEBC, 0.45)
	end
	web(root, Vector3.new(0, 52, -13), X, -Y, 5, 6, 3, false)

	-- забор, ворота, лампы, деревья
	local iron = C3(20, 20, 22)
	for fx = -40, 40, 2 do
		if math.abs(fx) > 5 then
			part(root, Vector3.new(0.3, 4, 0.3), CFrame.new(fx, 2, 22), iron, M.Metal)
			part(root, Vector3.new(0.5, 0.5, 0.5), CFrame.new(fx, 4.1, 22) * CFrame.Angles(0.8, 0.8, 0), iron, M.Metal)
		end
	end
	for _, side in { { -40, -5.5 }, { 5.5, 40 } } do
		local mid, len = (side[1] + side[2]) / 2, side[2] - side[1]
		part(root, Vector3.new(len, 0.2, 0.2), CFrame.new(mid, 1.1, 22), iron, M.Metal)
		part(root, Vector3.new(len, 0.2, 0.2), CFrame.new(mid, 3.2, 22), iron, M.Metal)
	end
	for _, gx in { -5, 5 } do
		part(root, Vector3.new(0.9, 6.5, 0.9), CFrame.new(gx, 3.25, 22), C3(60, 58, 58), M.Concrete)
		local ball = part(root, Vector3.new(1.2, 1.2, 1.2), CFrame.new(gx, 7, 22), C3(60, 58, 58), M.Concrete)
		ball.Shape = Enum.PartType.Ball
	end
	web(root, Vector3.new(-5, 6.3, 22.2), X, -Y, 3.4, 6, 3, false)
	web(root, Vector3.new(5, 6.3, 22.2), -X, -Y, 3.4, 6, 3, false)
	for _, lp in { { -5.5, 16 }, { 5.5, 16 }, { -5.5, 31 }, { 5.5, 31 } } do
		part(root, Vector3.new(0.4, 7.5, 0.4), CFrame.new(lp[1], 3.75, lp[2]), iron, M.Metal)
		local bulb = part(root, Vector3.new(1, 1.2, 1), CFrame.new(lp[1], 7.9, lp[2]), C3(255, 205, 120), M.Neon, 0.2)
		bulb.Shape = Enum.PartType.Ball
		local lt = Instance.new("PointLight")
		lt.Color = C3(255, 190, 110)
		lt.Brightness = 1.6
		lt.Range = 20
		lt.Parent = bulb
		table.insert(S.lamps, { light = lt, bulb = bulb, seed = lp[1] * 3 + lp[2] })
	end
	tree(root, -32, 34, 15, 4)
	tree(root, 36, 16, 17, -5)
	tree(root, -24, 56, 13, 7)
	tree(root, 28, 48, 16, -3)
	tree(root, -40, 8, 18, 3)
	web(root, Vector3.new(-32, 9, 34.6), X, Y, 3.6, 8, 3, true)
	web(root, Vector3.new(36, 10, 16.6), X, Y, 3.6, 8, 3, true)

	-- свет в холле (включается, когда открывается дверь)
	local hl = Instance.new("PointLight")
	hl.Color = C3(255, 170, 90)
	hl.Brightness = 0
	hl.Range = 26
	hl.Parent = part(root, Vector3.new(0.5, 0.5, 0.5), CFrame.new(0, 6, -2.5), C3(255, 170, 90), M.Neon, 1)
	S.hallLight = hl

	-- луна и звёзды
	local moon = part(root, Vector3.new(26, 26, 26), CFrame.new(-110, 120, -240), C3(226, 230, 255), M.Neon)
	moon.Shape = Enum.PartType.Ball
	local halo = part(root, Vector3.new(42, 42, 42), CFrame.new(-110, 120, -240), C3(160, 175, 230), M.Neon, 0.88)
	halo.Shape = Enum.PartType.Ball
	for _ = 1, 110 do
		local d = Vector3.new(rnd:NextNumber() * 2 - 1, rnd:NextNumber() * 0.9 + 0.12, rnd:NextNumber() * -1 - 0.1).Unit * 700
		local s = part(root, Vector3.new(1.6, 1.6, 1.6), CFrame.new(d), C3(230, 235, 255), M.Neon, rnd:NextNumber() * 0.4)
		s.Shape = Enum.PartType.Ball
	end

	-- летучие мыши вокруг башни
	for i = 1, 4 do
		local body = part(root, Vector3.new(0.5, 0.5, 0.9), CFrame.new(0, 60, 0), C3(10, 10, 12), M.SmoothPlastic)
		local wl = part(root, Vector3.new(1.6, 0.08, 0.9), CFrame.new(0, 60, 0), C3(14, 12, 16), M.SmoothPlastic)
		local wr = part(root, Vector3.new(1.6, 0.08, 0.9), CFrame.new(0, 60, 0), C3(14, 12, 16), M.SmoothPlastic)
		table.insert(S.bats, { body = body, wl = wl, wr = wr, r = 11 + i * 3, h = 40 + i * 3.5, spd = 0.5 + i * 0.12, ph = i * 1.6 })
	end
	return S
end

-- ===== персонаж из простых частей =====
local function buildFigure(root: Instance)
	local skin, jacket, pants = C3(226, 186, 152), C3(112, 34, 34), C3(36, 38, 50)
	pcall(function()
		local ch = player.Character
		local hum = ch and ch:FindFirstChildOfClass("Humanoid")
		if hum then
			local hd = hum:GetAppliedDescription()
			skin = hd.HeadColor
			pants = hd.LeftLegColor:Lerp(C3(30, 32, 44), 0.5)
		end
	end)
	local F = {}
	F.torso = part(root, Vector3.new(2, 2, 1), CFrame.new(), jacket, M.Fabric)
	F.head = part(root, Vector3.new(1.2, 1.2, 1.2), CFrame.new(), skin, M.SmoothPlastic)
	F.hair = part(root, Vector3.new(1.3, 0.5, 1.3), CFrame.new(), C3(40, 28, 22), M.Fabric)
	F.armL = part(root, Vector3.new(1, 2, 1), CFrame.new(), jacket, M.Fabric)
	F.armR = part(root, Vector3.new(1, 2, 1), CFrame.new(), jacket, M.Fabric)
	F.legL = part(root, Vector3.new(1, 2, 1), CFrame.new(), pants, M.Fabric)
	F.legR = part(root, Vector3.new(1, 2, 1), CFrame.new(), pants, M.Fabric)
	F.pack = part(root, Vector3.new(1.4, 1.6, 0.7), CFrame.new(), C3(60, 48, 34), M.Fabric)
	F.torch = part(root, Vector3.new(0.35, 0.35, 1.2), CFrame.new(), C3(30, 30, 34), M.Metal)
	F.lens = part(root, Vector3.new(0.3, 0.3, 0.1), CFrame.new(), C3(255, 240, 190), M.Neon)
	local face = Instance.new("Decal")
	face.Texture = "rbxasset://textures/face.png"
	face.Face = Enum.NormalId.Front
	face.Parent = F.head
	local spot = Instance.new("SpotLight")
	spot.Face = Enum.NormalId.Front
	spot.Angle = 50
	spot.Range = 30
	spot.Brightness = 3
	spot.Color = C3(255, 238, 190)
	spot.Parent = F.lens

	function F.pose(rootCF: CFrame, ph: number, amt: number, headUp: number, reach: number)
		local bob = math.abs(math.sin(ph)) * 0.18 * amt
		local t = rootCF * CFrame.new(0, 3 + bob, 0)
		F.torso.CFrame = t
		F.head.CFrame = t * CFrame.new(0, 1.65, 0) * CFrame.Angles(headUp, 0, 0)
		F.hair.CFrame = F.head.CFrame * CFrame.new(0, 0.55, 0.03)
		F.pack.CFrame = t * CFrame.new(0, 0.1, 0.85)
		local s = math.sin(ph) * amt
		local function limb(part0: Part, hx: number, hy: number, ang: number, drop: number)
			part0.CFrame = t * CFrame.new(hx, hy, 0) * CFrame.Angles(ang, 0, 0) * CFrame.new(0, -drop, 0)
		end
		limb(F.legL, -0.5, -1, s * 0.75, 1)
		limb(F.legR, 0.5, -1, -s * 0.75, 1)
		limb(F.armL, -1.5, 1, -s * 0.6 - 0.05, 0.9)
		local ar = (-s * 0.6) * (1 - reach) + 1.45 * reach
		limb(F.armR, 1.5, 1, ar, 0.9)
		F.torch.CFrame = F.armL.CFrame * CFrame.new(0, -1.0, -0.55)
		F.lens.CFrame = F.torch.CFrame * CFrame.new(0, 0, -0.65)
	end
	return F
end

-- ===== показ =====
local playing = false
local function play()
	if playing then return end
	playing = true

	local gui = Instance.new("ScreenGui")
	gui.Name = "EvaKHotelIntro"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 900
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = playerGui

	local function frame(parent: Instance, props: { [string]: any })
		local f = Instance.new("Frame")
		f.BorderSizePixel = 0
		for k, v in props do (f :: any)[k] = v end
		f.Parent = parent
		return f
	end
	local cover = frame(gui, { Size = UDim2.fromScale(1, 1), BackgroundColor3 = C3(0, 0, 0), ZIndex = 50 })
	local sky = frame(gui, { Size = UDim2.fromScale(1, 1), BackgroundColor3 = C3(255, 255, 255), ZIndex = 1 })
	local sg = Instance.new("UIGradient")
	sg.Rotation = 90
	sg.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, C3(3, 5, 14)), ColorSequenceKeypoint.new(0.6, C3(14, 16, 34)), ColorSequenceKeypoint.new(1, C3(48, 36, 50)) })
	sg.Parent = sky

	local vp = Instance.new("ViewportFrame")
	vp.Size = UDim2.fromScale(1, 1)
	vp.BackgroundTransparency = 1
	vp.BorderSizePixel = 0
	vp.Ambient = C3(66, 72, 100)
	vp.LightColor = C3(150, 165, 220)
	vp.LightDirection = Vector3.new(0.35, -0.5, 0.8)
	vp.ZIndex = 2
	vp.Parent = gui
	local cam = Instance.new("Camera")
	cam.FieldOfView = 52
	cam.Parent = vp
	vp.CurrentCamera = cam
	local root = Instance.new("Model")
	root.Name = "Scene"
	root.Parent = vp

	local label = Instance.new("TextLabel")
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.BackgroundTransparency = 1
	label.Text = "EvaK Hotel"
	label.Font = Enum.Font.Antique
	label.TextScaled = true
	label.TextColor3 = C3(222, 182, 84)
	label.ZIndex = 5
	label.Visible = false
	local ls = Instance.new("UIStroke")
	ls.Color = C3(40, 20, 6)
	ls.Thickness = 2
	ls.Parent = label
	label.Parent = gui

	for i = 1, 2 do   -- чёрные полосы «кино»
		frame(gui, { Size = UDim2.new(1, 0, 0.1, 0), Position = UDim2.fromScale(0, i == 1 and 0 or 0.9), BackgroundColor3 = C3(0, 0, 0), ZIndex = 20 })
	end
	local skipped = false
	local skipBtn = Instance.new("TextButton")
	skipBtn.AnchorPoint = Vector2.new(1, 1)
	skipBtn.Position = UDim2.new(1, -16, 1, -16)
	skipBtn.Size = UDim2.fromOffset(150, 34)
	skipBtn.BackgroundColor3 = C3(0, 0, 0)
	skipBtn.BackgroundTransparency = 0.45
	skipBtn.TextColor3 = C3(220, 210, 190)
	skipBtn.Font = Enum.Font.Arcade
	skipBtn.TextSize = 16
	skipBtn.Text = "SKIP  [SPACE]"
	skipBtn.ZIndex = 60
	skipBtn.Parent = gui
	skipBtn.MouseButton1Click:Connect(function() skipped = true end)
	local inputConn = UserInputService.InputBegan:Connect(function(inp, gp)
		if inp.KeyCode == Enum.KeyCode.Space or inp.KeyCode == Enum.KeyCode.Return then skipped = true end
	end)

	local function finish()
		inputConn:Disconnect()
		gui:Destroy()
		playing = false
		player:SetAttribute("EvaKHotelDone", os.clock())
	end

	local ok, err = pcall(function()
		local S = buildHotel(root)
		local F = buildFigure(root)
		snd(CFG.WindSoundId, 0.5)

		local TWALK0, TWALK1 = 3.4, 9.3
		local TDOOR0, TDOOR1 = 9.3, 10.7
		local TIN0, TIN1 = 10.7, 12.5
		local TCL0, TCL1 = 12.7, 14.4
		local TEND = 16.2
		local OPEN = math.rad(105)

		local K = {
			{ 0, Vector3.new(36, 3.5, 62), Vector3.new(0, 10, 24), 52 },
			{ 3.4, Vector3.new(32, 5.5, 56), Vector3.new(0, 9, 26), 50 },
			{ 9.3, Vector3.new(15, 2.8, 19), Vector3.new(0, 5, 3), 46 },
			{ 10.7, Vector3.new(12, 2.8, 14), Vector3.new(0, 5, 0), 44 },
			{ 14.4, Vector3.new(9, 2.5, 11), Vector3.new(0, 5.5, 0), 40 },
			{ 16.2, Vector3.new(8.5, 2.5, 10.5), Vector3.new(0, 5.5, 0), 38 },
		}
		local function charZ(t: number): number
			if t < TWALK0 then return 40 end
			if t < TWALK1 then return 40 + (6.5 - 40) * (t - TWALK0) / (TWALK1 - TWALK0) end
			if t < TIN0 then return 6.5 end
			if t < TIN1 then return 6.5 + (-3.6 - 6.5) * (t - TIN0) / (TIN1 - TIN0) end
			return -3.6
		end
		local function doorAng(t: number): number
			if t < TDOOR0 then return 0 end
			if t < TDOOR1 then local u = (t - TDOOR0) / (TDOOR1 - TDOOR0) return OPEN * (1 - (1 - u) ^ 2) end
			if t < TCL0 then return OPEN end
			if t < TCL1 then local u = (t - TCL0) / (TCL1 - TCL0) return OPEN * (1 - u ^ 3) end
			return 0
		end

		local dust = {}
		local slammed = false
		local opened = false
		local ph = 0
		local last = os.clock()
		local t0 = last
		-- плавное появление
		task.spawn(function()
			for i = 1, 20 do cover.BackgroundTransparency = 1 - i / 20; task.wait(0.04) end
		end)
		cover.BackgroundTransparency = 0
		task.wait(0.1)
		t0 = os.clock()
		last = t0

		while true do
			local now = os.clock()
			local dt = math.min(now - last, 0.1)
			last = now
			local t = now - t0
			if skipped or t >= TEND then break end

			-- камера: позиция по ключам
			local i = 1
			while i < #K - 1 and t >= K[i + 1][1] do i += 1 end
			local a, b = K[i], K[i + 1]
			local u = sstep(a[1], b[1], t)
			local pos = a[2]:Lerp(b[2], u)
			local look = a[3]:Lerp(b[3], u)
			local fov = a[4] + (b[4] - a[4]) * u
			local cz = charZ(t)
			local w = sstep(3.4, 5.0, t) * (1 - sstep(8.0, 9.3, t))
			look = look:Lerp(Vector3.new(0, 3.4, cz - 5), w)
			local amp = 0.035
			if t > TCL1 then amp += 0.9 * math.exp(-5 * (t - TCL1)) end
			local sh = Vector3.new(math.noise(t * 9, 1.1), math.noise(t * 9, 2.2), math.noise(t * 9, 3.3)) * amp
			cam.FieldOfView = fov
			cam.CFrame = CFrame.lookAt(pos + sh, look + sh * 0.5)

			-- персонаж
			local amt = math.clamp(sstep(TWALK0, TWALK0 + 0.5, t) - sstep(TWALK1 - 0.5, TWALK1, t) + sstep(TIN0, TIN0 + 0.3, t) - sstep(TIN1 - 0.3, TIN1, t), 0, 1)
			ph += dt * amt * 8.5
			local gy = 0.5 * sstep(11.2, 9.8, cz) + 0.5 * sstep(9.0, 7.8, cz)
			local headUp = 0.5 * sstep(0.6, 1.5, t) * (1 - sstep(3.0, 3.8, t))
			local reach = sstep(TWALK1 - 0.5, TWALK1, t) * (1 - sstep(TDOOR1, TDOOR1 + 0.5, t))
			F.pose(CFrame.new(0, gy, cz), ph, amt, headUp, reach)

			-- дверь, свет, паутина
			local da = doorAng(t)
			local hingeRot = S.hinge * CFrame.Angles(0, da, 0)
			for _, d in S.doorParts do d.p.CFrame = hingeRot * d.off end
			if t >= TDOOR0 and not opened then
				opened = true
				snd(CFG.DoorOpenSoundId, 0.9)
			end
			if opened and t < TDOOR1 + 0.6 then
				for _, wp in S.doorWebs do wp.Transparency = math.min(1, wp.Transparency + dt * 2) end
			end
			local lightK = sstep(TDOOR0, TDOOR1, t) * (1 - sstep(TCL0 + 0.6, TCL1, t))
			S.hallLight.Brightness = 3 * lightK
			S.hall.Transparency = 0.35 + 0.5 * (1 - lightK)
			if t >= TCL1 and not slammed then
				slammed = true
				snd(CFG.DoorSlamSoundId, 1)
				for _ = 1, 22 do
					local dpart = part(root, Vector3.new(0.18, 0.18, 0.18), CFrame.new(math.random() * 5 - 2.5, 9.6, 1 + math.random()), C3(120, 112, 100), M.Sand)
					table.insert(dust, { p = dpart, v = Vector3.new((math.random() - 0.5) * 3, -math.random() * 2, math.random() * 2) })
				end
			end
			for _, d in dust do
				d.v += Vector3.new(0, -14 * dt, 0)
				d.p.CFrame = d.p.CFrame + d.v * dt
			end

			-- мерцание окон и ламп
			for _, g in S.glow do
				g.p.Transparency = math.clamp(g.base + math.noise(t * 2.5, g.seed) * 0.5, 0.05, 0.95)
			end
			for _, l in S.lamps do
				local n = math.noise(t * 3, l.seed)
				l.light.Brightness = 1.6 + n * 1.2
				l.bulb.Transparency = 0.2 + math.max(0, -n) * 0.5
			end

			-- летучие мыши
			for _, bt in S.bats do
				local ang = t * bt.spd + bt.ph
				local p = Vector3.new(math.cos(ang) * bt.r, bt.h + math.sin(t * 1.3 + bt.ph) * 2, -13 + math.sin(ang) * bt.r)
				local tangent = Vector3.new(-math.sin(ang), 0, math.cos(ang))
				local cf = CFrame.lookAt(p, p + tangent)
				local flap = math.sin(t * 16 + bt.ph) * 0.8
				bt.body.CFrame = cf
				bt.wl.CFrame = cf * CFrame.new(-0.7, 0, 0) * CFrame.Angles(0, 0, -flap) * CFrame.new(-0.7, 0, 0)
				bt.wr.CFrame = cf * CFrame.new(0.7, 0, 0) * CFrame.Angles(0, 0, flap) * CFrame.new(0.7, 0, 0)
			end

			-- вывеска: плоская надпись, привязанная к 3D-доске
			local size = vp.AbsoluteSize
			local fovTan = math.tan(math.rad(cam.FieldOfView) / 2)
			local function proj(p: Vector3): Vector2?
				local v = cam.CFrame:PointToObjectSpace(p)
				if v.Z >= -0.5 then return nil end
				return Vector2.new(size.X / 2 + (v.X / -v.Z) / fovTan * size.Y / 2, size.Y / 2 - (v.Y / -v.Z) / fovTan * size.Y / 2)
			end
			local sc = S.signCF
			local pl, pr = proj(sc:PointToWorldSpace(Vector3.new(-6.6, 0, 0.35))), proj(sc:PointToWorldSpace(Vector3.new(6.6, 0, 0.35)))
			local pt, pb = proj(sc:PointToWorldSpace(Vector3.new(0, 1.5, 0.35))), proj(sc:PointToWorldSpace(Vector3.new(0, -1.5, 0.35)))
			if pl and pr and pt and pb then
				label.Visible = true
				label.Position = UDim2.fromOffset((pl.X + pr.X) / 2, (pl.Y + pr.Y) / 2)
				label.Size = UDim2.fromOffset((pl - pr).Magnitude, (pt - pb).Magnitude)
				label.Rotation = math.deg(math.atan2(pr.Y - pl.Y, pr.X - pl.X))
				local fl = math.noise(t * 6, 7.7)
				label.TextTransparency = fl > 0.45 and 0.6 or 0
				ls.Transparency = label.TextTransparency
			else
				label.Visible = false
			end

			-- затемнение в конце
			if t > TEND - 1.2 then cover.BackgroundTransparency = 1 - sstep(TEND - 1.2, TEND, t) end
			RunService.RenderStepped:Wait()
		end
		if skipped then
			cover.BackgroundTransparency = 0
			task.wait(0.25)
		end
	end)
	if not ok then warn("[EvaKHotelIntro] " .. tostring(err)) end
	cover.BackgroundTransparency = 0
	finish()
end

player:SetAttribute("EvaKHotelReady", true)
player:GetAttributeChangedSignal("EvaKPlayHotel"):Connect(function()
	if player:GetAttribute("EvaKPlayHotel") then task.spawn(play) end
end)
