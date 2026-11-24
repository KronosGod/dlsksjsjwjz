-- ============================================================
--  EvaKPreview (LocalScript в StarterPlayerScripts)
--  Окно предпросмотра: слева вращающаяся 3D-модель (манекен с надетым предметом / кейс), справа описание и список дропа.
--  Открывается атрибутом игрока:  player:SetAttribute("EvaKPreview", "item:wings:" .. os.clock())  или  "case:rusty:" .. os.clock()
--  Рамки, титулы и значки показываются плашкой вместо 3D.
-- ============================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local GOLD, RED = Color3.fromRGB(230, 200, 140), Color3.fromRGB(215, 48, 40)
local FONT = Enum.Font.Arcade
local function C(r, g, b) return Color3.fromRGB(r, g, b) end

local function new(class: string, props: any, parent: Instance?)
	local o = Instance.new(class)
	for k, v in props do (o :: any)[k] = v end
	o.Parent = parent
	return o
end

-- ---------------- данные ----------------
local INFO: {[string]: { name: string, desc: string, kind: string? }} = {
	aura = { name = "Curse Aura", desc = "Two glowing red rings circle your body. Others see you coming." },
	vipaura = { name = "CarBon Aura", desc = "White-and-crimson rings. Only for CarBon pass owners." },
	hellaura = { name = "Hellfire Aura", desc = "Burning rings with flames rising off them. Devil shop." },
	wings = { name = "EvaK Wings", desc = "Black bone wings with blood-red membranes." },
	devwings = { name = "Devil Wings", desc = "Glowing infernal wings. The biggest flex in the lobby." },
	demoneyes = { name = "Demon Eyes", desc = "Your eyes burn pink-red in the dark." },
	vipeyes = { name = "CarBon Eyes", desc = "Pure white glowing eyes. CarBon pass only." },
	crown = { name = "Sinner's Crown", desc = "A spiked crown with a red gem. Admin gift only." },
	lantern = { name = "Cursed Lantern", desc = "Lights up dark rooms while you hold it." },
	watch = { name = "Broken Watch", desc = "Cracked watch that shows time until the next event." },
	ownerkey = { name = "Owner's Key", desc = "Opens the secret notes 6-9. Golden and heavy." },
	eyeofevak = { name = "Eye of EvaK", desc = "A rare amulet. The eye follows whoever looks at it." },
	devhorns = { name = "Devil Horns", desc = "Curved black-red horns." },
	devtail = { name = "Devil Tail", desc = "A long tail with a spade tip. It sways when you walk." },
	pentagram = { name = "Eclipse Pendant", desc = "A dark disc with a glowing golden rim." },
	frame_bronze = { name = "Bronze Frame", desc = "Frame around your avatar in the profile.", kind = "frame" },
	frame_silver = { name = "Silver Frame", desc = "Frame around your avatar in the profile.", kind = "frame" },
	frame_gold = { name = "Gold Frame", desc = "Frame around your avatar in the profile.", kind = "frame" },
	frame_blood = { name = "Blood Frame", desc = "Frame around your avatar in the profile.", kind = "frame" },
	frame_neon = { name = "Neon Frame", desc = "Frame around your avatar in the profile.", kind = "frame" },
	frame_devil = { name = "Hellfire Frame", desc = "Frame around your avatar in the profile.", kind = "frame" },
	frame_horns = { name = "Horned Frame", desc = "Red-black frame with curved devil horns on top.", kind = "frame" },
	frame_angel = { name = "Angel Frame", desc = "White frame with a golden halo and feathered wings.", kind = "frame" },
	frame_halo = { name = "Halo Frame", desc = "Gold frame with a glowing halo above your avatar.", kind = "frame" },
	frame_demon = { name = "Demon Frame", desc = "Awarded for finishing the game badly hurt (Demon ending).", kind = "frame" },
	frame_seraph = { name = "Seraph Frame", desc = "Awarded for finishing the game almost unhurt (Angel ending).", kind = "frame" },
	frame_royal = { name = "Royal Frame", desc = "Royal frame. Owner only.", kind = "frame" },
	pin_cross = { name = "Cross Pin", desc = "A pin shown in your profile.", kind = "pin" },
	pin_skull = { name = "Skull Pin", desc = "A pin shown in your profile.", kind = "pin" },
	pin_heart = { name = "Heart Pin", desc = "A pin shown in your profile.", kind = "pin" },
	pin_star = { name = "Star Pin", desc = "A pin shown in your profile.", kind = "pin" },
	pin_moon = { name = "Moon Pin", desc = "A pin shown in your profile.", kind = "pin" },
	pin_flame = { name = "Flame Pin", desc = "A pin shown in your profile.", kind = "pin" },
}
local TITLES = { sinner = "Sinner", believer = "Believer", hellspawn = "Hellspawn", advocate = "Devil's Advocate", sixsix = "666", oldgod = "Old God", hacker = "Hacker", god = "GOD",
	survivor = "Survivor", rookie = "Rookie", guest = "Hotel Guest", sleepwalker = "Sleepwalker", lurker = "Lurker", ghosty = "Ghost", nightowl = "Night Owl", runner = "Runner", hunter = "Monster Hunter", lucky = "Lucky One", legend = "Legend", cobweb = "Cobweb Lord", insomnia = "Insomniac", bellhop = "Bellhop", manager = "Hotel Manager", vipguest = "VIP Guest", endemon = "Demon", enangel = "Angel", collector = "Collector", lol = "lol", speedrun = "Speedrunner", veteran = "Veteran", vip = "CarBon", seengod = "Seen by God", chosen = "Chosen of EvaK", abuser = "Admin Abuse Survivor" }
for id, n in TITLES do INFO[id] = { name = n, desc = "A title shown above your name and in chat.", kind = "title" } end
local FRAMES = {
	frame_bronze = { C(120, 70, 30), C(230, 160, 90) }, frame_silver = { C(150, 150, 160), C(240, 240, 250) }, frame_gold = { C(190, 140, 20), C(255, 225, 100) },
	frame_blood = { C(90, 0, 0), C(230, 20, 20) }, frame_neon = { C(0, 255, 220), C(255, 0, 200) }, frame_devil = { C(255, 80, 0), C(120, 0, 0) }, frame_royal = { C(255, 215, 0), C(160, 60, 220) },
	frame_horns = { C(255, 70, 30), C(70, 0, 0) }, frame_demon = { C(255, 40, 20), C(40, 0, 0) }, frame_angel = { C(255, 255, 255), C(190, 225, 255) }, frame_halo = { C(255, 236, 140), C(255, 255, 255) }, frame_seraph = { C(255, 240, 150), C(150, 210, 255) },
}
local PINS = { pin_cross = "✝", pin_skull = "☠", pin_heart = "♥", pin_star = "★", pin_moon = "☾", pin_flame = "♨" }

local CASES = {
	rusty = { name = "Rusty Case", tier = 1, col = C(150, 90, 50), loot = { { "sinner", 20 }, { "believer", 12 }, { "pin_cross", 12 }, { "pin_heart", 10 }, { "frame_bronze", 12 }, { "frame_silver", 8 }, { "aura", 8 }, { "lantern", 6 }, { "watch", 6 }, { "demoneyes", 4 }, { "frame_gold", 2 } } },
	cursed = { name = "Cursed Case", tier = 2, col = C(110, 50, 170), loot = { { "demoneyes", 16 }, { "devhorns", 14 }, { "devtail", 12 }, { "pin_skull", 10 }, { "pin_flame", 8 }, { "frame_blood", 10 }, { "frame_neon", 6 }, { "wings", 8 }, { "hellaura", 5 }, { "pentagram", 4 }, { "hellspawn", 3 }, { "pin_moon", 4 } } },
	evak = { name = "EvaK Case", tier = 3, col = C(170, 30, 30), loot = { { "devwings", 22 }, { "hellaura", 18 }, { "pentagram", 14 }, { "eyeofevak", 14 }, { "ownerkey", 12 }, { "frame_devil", 10 }, { "wings", 6 }, { "sixsix", 4 } } },
}

-- ---------------- интерфейс ----------------
local gui = new("ScreenGui", { Name = "EvaKPreviewGui", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 950, Enabled = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, playerGui)
local dim = new("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.45, Text = "", AutoButtonColor = false }, gui)
local panel = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(780, 470), BackgroundColor3 = C(14, 9, 8), BorderSizePixel = 0, Active = true }, dim)
new("UIStroke", { Color = RED, Thickness = 2 }, panel)
do
	local us = new("UIScale", {}, panel)
	local function upd() local v = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720); us.Scale = math.clamp(math.min(v.X / 860, v.Y / 540), 0.5, 1) end
	upd(); if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(upd) end
end
local vp = new("ViewportFrame", { Position = UDim2.fromOffset(16, 16), Size = UDim2.fromOffset(360, 438), BackgroundColor3 = C(20, 12, 12), BorderSizePixel = 0, Ambient = C(120, 110, 110), LightColor = C(255, 240, 230), LightDirection = Vector3.new(-0.4, -0.6, -0.7) }, panel)
new("UIStroke", { Color = C(90, 40, 36), Thickness = 1.5 }, vp)
local flat = new("Frame", { Position = UDim2.fromOffset(16, 16), Size = UDim2.fromOffset(360, 438), BackgroundColor3 = C(20, 12, 12), BorderSizePixel = 0, Visible = false }, panel)
new("UIStroke", { Color = C(90, 40, 36), Thickness = 1.5 }, flat)
local nameL = new("TextLabel", { Position = UDim2.fromOffset(394, 16), Size = UDim2.fromOffset(370, 34), BackgroundTransparency = 1, Font = FONT, TextSize = 24, TextColor3 = GOLD, TextXAlignment = Enum.TextXAlignment.Left, Text = "" }, panel)
local descL = new("TextLabel", { Position = UDim2.fromOffset(394, 54), Size = UDim2.fromOffset(370, 70), BackgroundTransparency = 1, Font = Enum.Font.Arcade, TextSize = 14, TextWrapped = true,
	TextColor3 = C(200, 180, 160), TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Text = "" }, panel)
local listTitle = new("TextLabel", { Position = UDim2.fromOffset(394, 130), Size = UDim2.fromOffset(370, 20), BackgroundTransparency = 1, Font = FONT, TextSize = 14, TextColor3 = RED, TextXAlignment = Enum.TextXAlignment.Left, Text = "" }, panel)
local list = new("ScrollingFrame", { Position = UDim2.fromOffset(394, 154), Size = UDim2.fromOffset(370, 300), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4,
	CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y }, panel)
new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, list)
local close = new("TextButton", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 8), Size = UDim2.fromOffset(30, 30), BackgroundColor3 = C(110, 28, 22), Text = "X", Font = FONT, TextSize = 18, TextColor3 = GOLD, ZIndex = 5 }, panel)
close.MouseButton1Click:Connect(function() gui.Enabled = false end)
dim.MouseButton1Click:Connect(function() gui.Enabled = false end)

-- ---------------- 3D: манекен и предметы ----------------
local world = new("WorldModel", {}, vp)
local cam = new("Camera", { FieldOfView = 40 }, vp)
vp.CurrentCamera = cam
local current: Model? = nil
local ticks: {(number) -> ()} = {}
local spin = 0
local focus = Vector3.new(0, 3.2, 0)
local dist = 14

local function P(m: Model, size: Vector3, cf: CFrame, col: Color3, mat: Enum.Material?, shape: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Anchored = true; p.CanCollide = false; p.Size = size; p.CFrame = cf; p.Color = col; p.Material = mat or Enum.Material.SmoothPlastic
	if shape then p.Shape = shape end
	p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = m
	return p
end
local NEON = Enum.Material.Neon

local function mannequin(m: Model)
	local skin, cloth = C(150, 140, 135), C(34, 28, 30)
	P(m, Vector3.new(0.9, 2, 0.9), CFrame.new(-0.5, 1, 0), cloth); P(m, Vector3.new(0.9, 2, 0.9), CFrame.new(0.5, 1, 0), cloth)
	P(m, Vector3.new(2, 2, 1), CFrame.new(0, 3, 0), cloth)
	P(m, Vector3.new(0.9, 2, 0.9), CFrame.new(-1.5, 3, 0), skin); P(m, Vector3.new(0.9, 2, 0.9), CFrame.new(1.5, 3, 0), skin)
	P(m, Vector3.new(1.2, 1.2, 1.2), CFrame.new(0, 4.8, 0), skin, nil, Enum.PartType.Ball)
	P(m, Vector3.new(1.1, 0.3, 1.1), CFrame.new(0, 4.1, 0), skin)
end

local function ring(m: Model, y: number, d: number, col: Color3, th: number): Part
	return P(m, Vector3.new(th, d, d), CFrame.new(0, y, 0) * CFrame.Angles(0, 0, math.pi / 2), col, NEON, Enum.PartType.Cylinder)
end

local BUILD: {[string]: (Model) -> ()} = {}
BUILD.aura = function(m, hell: boolean?, white: boolean?)
	local r1 = ring(m, 3, 7.5, white and C(255, 255, 255) or (hell and C(255, 110, 10) or C(255, 30, 20)), 0.18)
	local r2 = ring(m, 2.1, 6.3, white and C(230, 20, 30) or (hell and C(255, 40, 0) or C(120, 0, 0)), 0.1)
	local flames = {}
	if hell then
		for i = 1, 14 do flames[i] = P(m, Vector3.new(0.35, 0.8, 0.35), CFrame.new(), C(255, 150 - (i % 3) * 40, 20), NEON, Enum.PartType.Ball) end
	end
	table.insert(ticks, function(t)
		local b = math.sin(t * 2) * 0.35
		r1.CFrame = CFrame.new(0, 3 + b, 0) * CFrame.Angles(0, 0, math.pi / 2); r2.CFrame = CFrame.new(0, 2.1 - b, 0) * CFrame.Angles(0, 0, math.pi / 2)
		for i, f in flames do
			local ph = (t * 0.9 + i / #flames) % 1
			local a = i * 2.4
			f.CFrame = CFrame.new(math.cos(a) * 3.6, 3 + ph * 3.2, math.sin(a) * 3.6); f.Size = Vector3.one * (0.7 * (1 - ph) + 0.1); f.Transparency = ph * 0.8
		end
	end)
end
BUILD.hellaura = function(m) BUILD.aura(m, true) end
BUILD.vipaura = function(m) BUILD.aura(m, false, true) end
BUILD.wings = function(m, dev: boolean?)
	for side = -1, 1, 2 do
		P(m, Vector3.new(0.35, 5.5, 0.35), CFrame.new(side * 2.5, 4.4, 1.1) * CFrame.Angles(0, 0, math.rad(side * -38)), C(14, 8, 8))
		for i = 1, 3 do
			local w = Instance.new("WedgePart"); w.Anchored = true; w.CanCollide = false
			w.Size = Vector3.new(0.12, 4.2 - i * 0.6, 2.2)
			w.Color = dev and C(255, 40 + i * 20, 20) or C(150 - i * 20, 12, 18); w.Material = dev and NEON or Enum.Material.SmoothPlastic
			w.CFrame = CFrame.new(side * (1.5 + i * 0.9), 3.5 + i * 0.35, 1.0) * CFrame.Angles(0, math.rad(side * 14), math.rad(side * -8))
			w.Parent = m
		end
	end
end
BUILD.devwings = function(m) BUILD.wings(m, true) end
BUILD.demoneyes = function(m, white: boolean?)
	local col = white and C(255, 255, 255) or C(255, 50, 70)
	for s = -1, 1, 2 do   -- овальный скошенный глаз + зрачок-щель + мягкое свечение
		local roll = math.rad(s * 16)
		local base = CFrame.new(s * 0.3, 4.92, -0.6)
		P(m, Vector3.new(0.05, 0.2, 0.38), base * CFrame.Angles(0, 0, roll) * CFrame.Angles(0, math.pi / 2, 0), col, NEON, Enum.PartType.Cylinder)
		P(m, Vector3.new(0.05, 0.19, 0.07), base * CFrame.new(0, 0, -0.03) * CFrame.Angles(0, 0, roll) * CFrame.Angles(0, math.pi / 2, 0), C(10, 0, 0), nil, Enum.PartType.Cylinder)
		local glow = P(m, Vector3.new(0.03, 0.42, 0.7), base * CFrame.new(0, 0, 0.02) * CFrame.Angles(0, 0, roll) * CFrame.Angles(0, math.pi / 2, 0), col, NEON, Enum.PartType.Cylinder)
		glow.Transparency = 0.8
	end
	focus = Vector3.new(0, 4.6, 0); dist = 6
end
BUILD.vipeyes = function(m) BUILD.demoneyes(m, true) end
BUILD.crown = function(m)
	local g = C(255, 205, 60)
	P(m, Vector3.new(0.3, 1.5, 1.5), CFrame.new(0, 5.55, 0) * CFrame.Angles(0, 0, math.pi / 2), C(16, 10, 12), Enum.Material.Metal, Enum.PartType.Cylinder)
	for i = 0, 6 do
		local a = i / 7 * math.pi * 2
		local sp = Instance.new("WedgePart"); sp.Anchored = true; sp.CanCollide = false; sp.Size = Vector3.new(0.2, 0.8 + (i % 2) * 0.5, 0.35); sp.Color = g; sp.Material = Enum.Material.Metal
		sp.CFrame = CFrame.new(math.cos(a) * 0.72, 6.0 + (i % 2) * 0.25, math.sin(a) * 0.72) * CFrame.Angles(0, -a, 0); sp.Parent = m
	end
	P(m, Vector3.new(0.3, 0.3, 0.12), CFrame.new(0, 5.65, -0.78), C(255, 20, 20), NEON)
	focus = Vector3.new(0, 4.6, 0); dist = 8
end
BUILD.lantern = function(m)
	local hand = Vector3.new(1.5, 1.9, -0.2)
	local core = P(m, Vector3.new(0.7, 0.8, 0.7), CFrame.new(hand), C(255, 170, 60), NEON)
	for _, c in { { 0.45, 0.45 }, { -0.45, 0.45 }, { 0.45, -0.45 }, { -0.45, -0.45 } } do P(m, Vector3.new(0.1, 1.1, 0.1), CFrame.new(hand + Vector3.new(c[1] * 0.7, 0, c[2] * 0.7)), C(20, 14, 12), Enum.Material.Metal) end
	P(m, Vector3.new(1, 0.14, 1), CFrame.new(hand + Vector3.new(0, 0.6, 0)), C(20, 14, 12), Enum.Material.Metal); P(m, Vector3.new(1, 0.14, 1), CFrame.new(hand + Vector3.new(0, -0.6, 0)), C(20, 14, 12), Enum.Material.Metal)
	P(m, Vector3.new(0.7, 0.07, 0.07), CFrame.new(hand + Vector3.new(0, 1.0, 0)), C(20, 14, 12), Enum.Material.Metal)
	table.insert(ticks, function(t) core.Transparency = 0.1 + 0.2 * math.sin(t * 9) * math.sin(t * 3.3) end)
end
BUILD.watch = function(m)
	local w = Vector3.new(-1.5, 2.2, 0)
	P(m, Vector3.new(0.35, 1.0, 1.0), CFrame.new(w), C(90, 70, 40), Enum.Material.Metal, Enum.PartType.Cylinder)
	P(m, Vector3.new(0.4, 0.8, 0.8), CFrame.new(w + Vector3.new(-0.08, 0, 0)), C(220, 215, 200), nil, Enum.PartType.Cylinder)
	P(m, Vector3.new(0.45, 0.06, 0.4), CFrame.new(w + Vector3.new(-0.3, 0.1, 0.1)) * CFrame.Angles(0.4, 0, 0), C(20, 20, 20))
	P(m, Vector3.new(0.45, 0.35, 0.05), CFrame.new(w + Vector3.new(-0.3, 0.1, -0.1)), C(20, 20, 20))
	P(m, Vector3.new(0.45, 0.05, 0.9), CFrame.new(w + Vector3.new(-0.3, 0.2, 0)) * CFrame.Angles(0.7, 0, 0), C(40, 40, 40))   -- трещина
	P(m, Vector3.new(0.3, 1.1, 1.1), CFrame.new(w), C(60, 40, 20), Enum.Material.Wood, Enum.PartType.Cylinder).Transparency = 0.6
	focus = Vector3.new(-1.2, 2.6, 0); dist = 7
end
BUILD.ownerkey = function(m)
	local g = C(255, 205, 60)
	local k = Instance.new("Model"); k.Parent = m
	local parts = { P(k, Vector3.new(0.5, 2.4, 0.5), CFrame.new(0, 0, 0), g, Enum.Material.Metal), P(k, Vector3.new(0.5, 1.4, 1.4), CFrame.new(0, 1.6, 0) * CFrame.Angles(0, 0, math.pi / 2), g, Enum.Material.Metal, Enum.PartType.Cylinder),
		P(k, Vector3.new(0.5, 0.5, 0.9), CFrame.new(0, -0.9, 0.55), g, Enum.Material.Metal), P(k, Vector3.new(0.5, 0.5, 0.6), CFrame.new(0, -0.3, 0.45), g, Enum.Material.Metal) }
	P(k, Vector3.new(0.52, 0.7, 0.7), CFrame.new(0, 1.6, 0) * CFrame.Angles(0, 0, math.pi / 2), C(20, 12, 10), nil, Enum.PartType.Cylinder)
	local gem = P(k, Vector3.new(0.3, 0.3, 0.3), CFrame.new(0, 1.6, -0.3), C(255, 20, 20), NEON)
	table.insert(ticks, function(t) k:PivotTo(CFrame.new(0, 3.4 + math.sin(t * 2) * 0.3, 0) * CFrame.Angles(0.2, t * 1.1, 0.5)) end)
	focus = Vector3.new(0, 3.4, 0); dist = 9
end
BUILD.eyeofevak = function(m)
	local c = Vector3.new(0, 3.5, -0.62)
	for i = 0, 7 do local a = i / 8 * math.pi * 2; P(m, Vector3.new(0.12, 0.12, 0.08), CFrame.new(math.cos(a) * 0.5, 3.45 + math.sin(a) * 0.5, -0.55), C(80, 70, 70), Enum.Material.Metal) end
	P(m, Vector3.new(0.9, 0.9, 0.12), CFrame.new(c.X, 3.45, -0.58), C(18, 10, 10), Enum.Material.Metal, Enum.PartType.Cylinder).CFrame = CFrame.new(0, 3.45, -0.58) * CFrame.Angles(0, math.pi / 2, 0)
	do
		local eye = P(m, Vector3.new(0.5, 0.2, 0.06), CFrame.new(0, 3.45, -0.67), C(255, 255, 255), NEON)
		local iris = P(m, Vector3.new(0.16, 0.16, 0.08), CFrame.new(0, 3.45, -0.7), C(230, 10, 10), NEON, Enum.PartType.Ball)
		table.insert(ticks, function(t) iris.CFrame = CFrame.new(math.sin(t * 1.5) * 0.13, 3.45, -0.7) end)
	end
	focus = Vector3.new(0, 3.5, 0); dist = 8
end
BUILD.pentagram = function(m)   -- кулон-затмение
	local f = CFrame.Angles(0, math.pi / 2, 0)
	P(m, Vector3.new(0.12, 1.1, 1.1), CFrame.new(0, 3.45, -0.62) * f, C(8, 8, 12), nil, Enum.PartType.Cylinder)
	P(m, Vector3.new(0.08, 1.3, 1.3), CFrame.new(0, 3.45, -0.6) * f, C(255, 190, 90), NEON, Enum.PartType.Cylinder)
	P(m, Vector3.new(0.14, 1.15, 1.15), CFrame.new(0.14, 3.45, -0.66) * f, C(8, 8, 12), nil, Enum.PartType.Cylinder)
	focus = Vector3.new(0, 3.5, 0); dist = 8
end
BUILD.devhorns = function(m)
	for s = -1, 1, 2 do
		local x, y, a = s * 0.4, 5.35, math.rad(s * -12)
		for i = 1, 4 do
			local seg = P(m, Vector3.new(0.38 - i * 0.07, 0.65, 0.38 - i * 0.07), CFrame.new(x, y, -0.05) * CFrame.Angles(0, 0, a), i < 3 and C(40, 6, 6) or C(110, 10, 10))
			x += math.sin(-a) * 0.6; y += math.cos(a) * 0.6; a -= math.rad(s * 14)
		end
	end
	focus = Vector3.new(0, 4.9, 0); dist = 8
end
BUILD.devtail = function(m)
	local segs = {}
	for i = 1, 9 do segs[i] = P(m, Vector3.new(0.3 - i * 0.015, 0.3 - i * 0.015, 0.6), CFrame.new(), C(60, 6, 8)) end
	local tip = Instance.new("WedgePart"); tip.Anchored = true; tip.CanCollide = false; tip.Size = Vector3.new(0.12, 0.7, 0.7); tip.Color = C(120, 10, 10); tip.Parent = m
	table.insert(ticks, function(t)
		for i, s in segs do
			local k = i / 9
			s.CFrame = CFrame.new(math.sin(t * 2.2 - i * 0.5) * 0.45 * k, 2.4 - k * 0.2 + math.sin(k * 3) * 0.3 - 0.0, 0.7 + i * 0.52)
		end
		tip.CFrame = CFrame.new(math.sin(t * 2.2 - 5) * 0.45, 2.4 + 0.2, 0.7 + 10 * 0.52) * CFrame.Angles(math.rad(90), 0, 0)
	end)
	spin = math.pi * 0.9; focus = Vector3.new(0, 3, 2); dist = 12
end

local function clear()
	if current then current:Destroy(); current = nil end
	table.clear(ticks)
	focus = Vector3.new(0, 3.2, 0); dist = 14
end

local TCOL = {sinner = "c8322a", believer = "8cc8ff", hellspawn = "ff7a1a", advocate = "b050e0", sixsix = "e01818", oldgod = "ffd24a", hacker = "3cff6a", god = "ffcd3c", survivor = "5cd05c", endemon = "ff3a2a", enangel = "fff0b0", collector = "34d6c0", lol = "fff04a", speedrun = "40e0ff", veteran = "d08a40", vip = "ff4646", seengod = "ffe27a", chosen = "c070ff", abuser = "ff9a3a", rookie = "b8b8b8", guest = "d8c090", sleepwalker = "b8a8ff", lurker = "4a8a4a", ghosty = "d8ecff", nightowl = "6a70ff", runner = "a8ff3a", hunter = "c05030", lucky = "7aff9a", legend = "ffc020", cobweb = "d8dce8", insomnia = "c8a0ff", bellhop = "d4a84a", manager = "ff6a3a", vipguest = "ff8ad0"}
local function decorate(av: GuiObject, id: string?, wOverride: number?)
	for _, c in av:GetChildren() do if c.Name == "Deco" then c:Destroy() end end
	if not id then return end
	local W = wOverride or (av.AbsoluteSize.X > 0 and av.AbsoluteSize.X or 170)
	local function ell(x: number, y: number, w: number, h: number, rot: number, c0: Color3, c1: Color3, z: number)
		local f = new("Frame", { Name = "Deco", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(x, 0, y, 0), Size = UDim2.fromOffset(w, h), Rotation = rot, BackgroundColor3 = c0, BorderSizePixel = 0, ZIndex = z }, av)
		new("UICorner", { CornerRadius = UDim.new(1, 0) }, f)
		new("UIGradient", { Color = ColorSequence.new(c0, c1), Rotation = 90 }, f)
		return f
	end
	if id == "frame_horns" or id == "frame_demon" then
		for _, s in { -1, 1 } do   -- рог из 3 звеньев, загибается к центру
			local x0 = 0.5 + s * 0.42
			ell(x0, -0.02, W * 0.17, W * 0.26, s * 22, Color3.fromRGB(70, 6, 8), Color3.fromRGB(160, 20, 16), 51)
			ell(x0 - s * 0.045, -0.15, W * 0.11, W * 0.22, s * 42, Color3.fromRGB(110, 10, 10), Color3.fromRGB(220, 40, 24), 51)
			ell(x0 - s * 0.11, -0.25, W * 0.06, W * 0.17, s * 62, Color3.fromRGB(190, 30, 20), Color3.fromRGB(255, 120, 60), 51)
		end
		ell(0.5, 1.04, W * 0.7, W * 0.08, 0, Color3.fromRGB(255, 70, 20), Color3.fromRGB(90, 0, 0), 51)   -- тлеющая полоса снизу
	elseif id == "frame_angel" or id == "frame_halo" or id == "frame_seraph" then
		local halo = new("Frame", { Name = "Deco", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, -0.1, 0), Size = UDim2.fromOffset(W * 0.62, W * 0.16), BackgroundTransparency = 1, ZIndex = 55 }, av)
		new("UICorner", { CornerRadius = UDim.new(1, 0) }, halo)
		local hs = new("UIStroke", { Color = Color3.fromRGB(255, 215, 70), Thickness = 5 }, halo)
		new("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(255, 245, 160), Color3.fromRGB(255, 190, 40)), Rotation = 0 }, hs)
		if id ~= "frame_halo" then
			for _, s in { -1, 1 } do   -- крылья: три пера
				for i = 0, 2 do
					ell(0.5 + s * (0.62 + i * 0.07), 0.28 + i * 0.12, W * 0.34, W * 0.1, s * (-24 + i * 14), Color3.fromRGB(235, 245, 255), Color3.fromRGB(255, 255, 255), 50)
				end
			end
		end
	end
end

local function showInfoFlat(id: string, kind: string)
	for _, c in flat:GetChildren() do if c:IsA("GuiObject") then c:Destroy() end end
	flat.Visible = true; vp.Visible = false
	if kind == "frame" then
		local fc = FRAMES[id] or { C(90, 70, 55), C(200, 180, 150) }
		local av = new("ImageLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.fromOffset(200, 200), BackgroundColor3 = C(40, 30, 30), Image = "" }, flat)
		new("UICorner", { CornerRadius = UDim.new(1, 0) }, av)
		local st = new("UIStroke", { Thickness = 9, Color = Color3.new(1, 1, 1) }, av)
		new("UIGradient", { Color = ColorSequence.new(fc[1], fc[2]), Rotation = 45 }, st)
		decorate(av, id, 200)
		task.spawn(function()
			local ok, url = pcall(function() return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.AvatarBust, Enum.ThumbnailSize.Size150x150) end)
			if ok and av.Parent then av.Image = url end
		end)
		new("TextLabel", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.78, 0), Size = UDim2.fromOffset(320, 24), BackgroundTransparency = 1, Font = FONT, TextSize = 14, TextColor3 = C(170, 150, 130), Text = "THIS IS HOW YOUR AVATAR LOOKS IN THE PROFILE" }, flat)
	elseif kind == "pin" then
		new("TextLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.fromOffset(240, 240), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 190, TextColor3 = C(255, 120, 80), Text = PINS[id] or "?" }, flat)
	else   -- титул: плашка как над головой
		local col = TCOL[id] and Color3.fromHex(TCOL[id]) or C(235, 70, 55)
		local plate = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.42), Size = UDim2.fromOffset(300, 70), BackgroundColor3 = C(10, 6, 6), BorderSizePixel = 0 }, flat)
		new("UIStroke", { Color = col, Thickness = 2 }, plate)
		new("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Font = FONT, TextSize = 26, TextColor3 = col, Text = "[" .. (INFO[id] and INFO[id].name or id):upper() .. "]" }, plate)
		new("TextLabel", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.62, 0), Size = UDim2.fromOffset(300, 24), BackgroundTransparency = 1, Font = FONT, TextSize = 14, TextColor3 = C(210, 190, 170), Text = player.DisplayName }, flat)
	end
end

local function crate(m: Model, tier: number, col: Color3)
	local wood = col
	P(m, Vector3.new(4, 2.6, 3), CFrame.new(0, 1.3, 0), wood, Enum.Material.WoodPlanks)
	for _, y in { 0.15, 2.45 } do P(m, Vector3.new(4.2, 0.3, 3.2), CFrame.new(0, y, 0), C(30, 22, 18), Enum.Material.Metal) end
	for _, x in { -1.9, 1.9 } do P(m, Vector3.new(0.3, 2.7, 3.2), CFrame.new(x, 1.3, 0), C(30, 22, 18), Enum.Material.Metal) end
	local lid = P(m, Vector3.new(4.1, 0.5, 3.1), CFrame.new(0, 2.85, 0), wood:Lerp(Color3.new(0, 0, 0), 0.15), Enum.Material.WoodPlanks)
	P(m, Vector3.new(0.6, 0.9, 0.2), CFrame.new(0, 2.1, -1.55), tier == 3 and C(255, 205, 60) or C(150, 150, 150), Enum.Material.Metal)
	if tier >= 2 then P(m, Vector3.new(1.3, 1.3, 0.12), CFrame.new(0, 1.4, -1.58), tier == 3 and C(255, 30, 20) or C(170, 70, 255), NEON, Enum.PartType.Cylinder).CFrame = CFrame.new(0, 1.4, -1.58) * CFrame.Angles(0, math.pi / 2, 0) end
	table.insert(ticks, function(t) lid.CFrame = CFrame.new(0, 2.85 + math.max(0, math.sin(t * 1.3)) * 0.25, 0) * CFrame.Angles(math.max(0, math.sin(t * 1.3)) * -0.12, 0, 0) end)
	focus = Vector3.new(0, 1.6, 0); dist = 11
end

local function showModel(id: string)
	clear()
	flat.Visible = false; vp.Visible = true
	local m = Instance.new("Model"); m.Parent = world; current = m
	if id ~= "ownerkey" then mannequin(m) end
	local b = BUILD[id]
	if b then b(m) end
	spin = id == "devtail" and math.pi * 0.9 or 0
end

local function showItem(id: string)
	local inf = INFO[id]
	nameL.Text = (inf and inf.name or id):upper()
	descL.Text = inf and inf.desc or ""
	if inf and inf.kind then clear(); showInfoFlat(id, inf.kind) else showModel(id) end
end

local selBtns: {[string]: TextButton} = {}
local function buildCase(cid: string)
	local cs = CASES[cid]
	for _, c in list:GetChildren() do if c:IsA("GuiObject") then c:Destroy() end end
	table.clear(selBtns)
	listTitle.Text = "WHAT CAN DROP  (click to preview)"
	local sorted = table.clone(cs.loot)
	table.sort(sorted, function(a, b) return a[2] > b[2] end)
	for i, e in sorted do
		local inf = INFO[e[1]]
		local rare = e[2] <= 5
		local row = new("TextButton", { Size = UDim2.new(1, -8, 0, 30), BackgroundColor3 = C(28, 18, 16), BorderSizePixel = 0, Text = "", LayoutOrder = i, AutoButtonColor = true }, list)
		new("UIStroke", { Color = rare and C(255, 190, 60) or C(70, 40, 36), Thickness = 1 }, row)
		new("TextLabel", { Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -90, 1, 0), BackgroundTransparency = 1, Font = FONT, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = rare and C(255, 200, 80) or GOLD, Text = (inf and inf.name or e[1]):upper() }, row)
		new("TextLabel", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 0), Size = UDim2.fromOffset(70, 30), BackgroundTransparency = 1, Font = FONT, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Right,
			TextColor3 = C(190, 170, 150), Text = tostring(e[2]) .. "%" }, row)
		row.MouseButton1Click:Connect(function() showItem(e[1]); descL.Text = (inf and inf.desc or "") end)
	end
end

local function open(kind: string, id: string)
	for _, c in list:GetChildren() do if c:IsA("GuiObject") then c:Destroy() end end
	listTitle.Text = ""
	if kind == "case" and CASES[id] then
		local cs = CASES[id]
		clear(); flat.Visible = false; vp.Visible = true
		local m = Instance.new("Model"); m.Parent = world; current = m
		crate(m, cs.tier, cs.col)
		nameL.Text = cs.name:upper()
		descL.Text = "Open it for a random item. A duplicate gives badges back. Click any drop on the right to see how it looks."
		buildCase(id)
		spin = 0.5
	else
		showItem(id)
		if kind == "item" then spin = 0 end
	end
	gui.Enabled = true
end

player:GetAttributeChangedSignal("EvaKPreview"):Connect(function()
	local v = player:GetAttribute("EvaKPreview")
	if type(v) ~= "string" then return end
	local kind, id = v:match("^(%a+):([%w_]+)")
	if kind and id then open(kind, id) end
end)

RunService.RenderStepped:Connect(function(dt)
	if not gui.Enabled or not current then return end
	local t = os.clock()
	spin += dt * 0.9
	for _, f in ticks do f(t) end
	local a = spin
	cam.CFrame = CFrame.lookAt(focus + Vector3.new(math.sin(a) * dist, 1.2, -math.cos(a) * dist), focus)
end)
